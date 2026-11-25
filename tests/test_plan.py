import fnmatch
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

import desktops
import plan
import userconf


class Fake(plan.Sys):
    def __init__(self, pkgs, files=None, dm="sddm", groups=None, cascade_extra=()):
        self.pkgs = set(pkgs)
        self.fs = files or {}
        self.dm = dm
        self.groups = groups or {}
        self.extra = set(cascade_extra)

    def installed(self):
        return set(self.pkgs)

    def group(self, name, sync=False):
        return set(self.groups.get(name, ()))

    def depends(self, pkgs):
        return set()

    def cascade(self, pkgs):
        return set(pkgs) | (self.extra if pkgs else set())

    def files(self, pkgs):
        return {p: [f for f, v in self.fs.items() if isinstance(v, tuple) and v[0] == p] for p in pkgs}

    def read(self, path):
        v = self.fs.get(path, "")
        return v[1] if isinstance(v, tuple) else v

    def exists(self, path):
        return path in self.fs

    def current_dm(self):
        return self.dm

    def nonempty(self, pattern):
        return [f for f in self.fs if fnmatch.fnmatch(f, pattern) and self.fs[f]]


PLASMA = desktops.packages("plasma", None)
GNOME = desktops.packages("gnome", None)


def sessions(*names):
    return {f"/usr/share/wayland-sessions/{n}.desktop": "" for n in names}


class Plan(unittest.TestCase):
    def test_validate(self):
        with self.assertRaises(ValueError):
            plan.validate({}, "")
        with self.assertRaises(ValueError):
            plan.validate({"plasma": None}, "gnome")
        with self.assertRaises(ValueError):
            plan.validate({"hyprland": "nope"}, "hyprland")
        with self.assertRaises(ValueError):
            plan.validate({"plasma": "crest"}, "plasma")
        with self.assertRaises(ValueError):
            plan.validate({"bogus": None}, "bogus")
        plan.validate({"hyprland": "crest", "plasma": None}, "plasma")

    def test_swap_removes_old_keeps_core(self):
        s = Fake(PLASMA + ["firefox", "sddm"], sessions("plasma"), cascade_extra={"firefox"})
        p = plan.build(s, {"plasma": None}, {"gnome": None}, "gnome")
        self.assertIn("plasma-meta", p["remove"])
        self.assertNotIn("firefox", p["remove"])
        self.assertIn("gnome", p["install"])
        self.assertTrue(p["switch_dm"])
        self.assertEqual(p["dm"], "gdm")
        self.assertEqual(p["dropped"], ["plasma"])

    def test_launchers_protected(self):
        files = sessions("plasma")
        files["/usr/share/applications/org.kde.dolphin.desktop"] = ("dolphin", "[Desktop Entry]\nName=Dolphin\n")
        files["/usr/share/applications/org.kde.kded.desktop"] = ("plasma-meta", "[Desktop Entry]\nNoDisplay=true\n")
        s = Fake(PLASMA + ["sddm"], files)
        p = plan.build(s, {"plasma": None}, {"gnome": None}, "gnome")
        self.assertIn("dolphin", p["kept_apps"])
        self.assertNotIn("dolphin", p["remove"])
        self.assertIn("plasma-meta", p["remove"])
        p = plan.build(s, {"plasma": None}, {"gnome": None}, "gnome", True)
        self.assertIn("dolphin", p["remove"])

    def test_secret_stores_never_removed(self):
        vaults = ["kwallet", "kwallet-pam", "gnome-keyring", "keepassxc"]
        s = Fake(PLASMA + ["sddm"] + vaults, sessions("plasma"), cascade_extra=vaults)
        p = plan.build(s, {"plasma": None}, {"hyprland": "none"}, "hyprland", True)
        for v in vaults:
            self.assertNotIn(v, p["remove"])
        self.assertIn("plasma-meta", p["remove"])

    def test_kwallet_warning(self):
        files = sessions("plasma")
        files["/home/u/.local/share/kwalletd/kdewallet.kwl"] = "data"
        s = Fake(PLASMA + ["sddm", "kwallet"], files)
        p = plan.build(s, {"plasma": None}, {"hyprland": "none"}, "hyprland", home="/home/u")
        self.assertEqual(len(p["warnings"]), 1)
        self.assertIn("kwalletmanager", p["install"])
        p = plan.build(s, {"plasma": None}, {"plasma": None, "hyprland": "none"}, "hyprland", home="/home/u")
        self.assertEqual(p["warnings"], [])
        self.assertNotIn("kwalletmanager", p["install"])
        files["/home/u/.local/share/kwalletd/kdewallet.kwl"] = ""
        p = plan.build(s, {"plasma": None}, {"hyprland": "none"}, "hyprland", home="/home/u")
        self.assertEqual(p["warnings"], [])
        p = plan.build(s, {"plasma": None}, {"hyprland": "none"}, "hyprland")
        self.assertEqual(p["warnings"], [])

    def test_shared_dm_kept(self):
        s = Fake(PLASMA + desktops.packages("lxqt", None), sessions("plasma", "lxqt"))
        p = plan.build(s, {"plasma": None, "lxqt": None}, {"lxqt": None}, "lxqt")
        self.assertNotIn("sddm", p["remove"])
        self.assertFalse(p["switch_dm"])

    def test_shell_swap(self):
        crest = desktops.SHELLS["crest"]["pkgs"]
        hypr = desktops.packages("hyprland", "crest")
        s = Fake(hypr + ["greetd"], sessions("hyprland"), dm="greetd")
        p = plan.build(s, {"hyprland": "crest"}, {"hyprland": "noctalia"}, "hyprland")
        self.assertIn("crest", p["remove"])
        self.assertNotIn("hyprland", p["remove"])
        self.assertIn("noctalia", p["install"])
        self.assertEqual(p["reshelled"], ["hyprland"])
        self.assertTrue(set(crest) - {"crest"} - set(p["remove"]) <= set(crest))

    def test_nothing_changes(self):
        s = Fake(PLASMA + ["sddm"], sessions("plasma"))
        p = plan.build(s, {"plasma": None}, {"plasma": None}, "plasma")
        self.assertEqual(p["remove"], [])
        self.assertEqual(p["install"], [])
        self.assertFalse(p["switch_dm"])

    def test_detect(self):
        s = Fake(PLASMA, sessions("plasma"))
        self.assertEqual(plan.detect(s, "/home/x"), {"plasma": None})

    def test_detect_dots_by_marker(self):
        files = sessions("hyprland")
        files["/home/x/.config/hypr/hyprland.lua"] = "require(\"hyprland.lib\")\n"
        files["/home/x/.config/quickshell/ii"] = "dir"
        s = Fake(desktops.packages("hyprland", "crest"), files, dm="greetd")
        self.assertEqual(plan.detect(s, "/home/x"), {"hyprland": "illogical-impulse"})
        del files["/home/x/.config/quickshell/ii"]
        self.assertEqual(plan.detect(Fake(desktops.packages("hyprland", "crest"), files), "/home/x"), {"hyprland": "crest"})


class UserConf(unittest.TestCase):
    def test_dots_and_hypr(self):
        with tempfile.TemporaryDirectory() as home:
            base = 'local shell = "crest"\nrest\n'
            sys_read = lambda p: base if p.endswith("hyprland.lua") else ""
            userconf.apply_all(home, {"hyprland": "hyde"}, lambda *_: None, sys_read)
            self.assertEqual(open(f"{home}/.config/fiordland/dots").read(), "hyde\n")
            self.assertIn('local shell = "dots"', open(f"{home}/.config/hypr/hyprland.lua").read())
            userconf.apply_all(home, {"hyprland": "noctalia"}, lambda *_: None, sys_read)
            self.assertFalse(os.path.exists(f"{home}/.config/fiordland/dots"))
            self.assertIn('local shell = "noctalia"', open(f"{home}/.config/hypr/hyprland.lua").read())

    def test_unchanged_dots_left_alone(self):
        with tempfile.TemporaryDirectory() as home:
            os.makedirs(f"{home}/.config/hypr")
            theirs = 'require("hyprland.lib")\n'
            with open(f"{home}/.config/hypr/hyprland.lua", "w") as f:
                f.write(theirs)
            sys_read = lambda p: 'local shell = "crest"\n' if p.endswith("hyprland.lua") else ""
            cur = {"hyprland": "illogical-impulse"}
            userconf.apply_all(home, {"hyprland": "illogical-impulse"}, lambda *_: None, sys_read, current=cur)
            self.assertEqual(open(f"{home}/.config/hypr/hyprland.lua").read(), theirs)
            self.assertFalse(os.path.exists(f"{home}/.config/fiordland/dots"))
            userconf.apply_all(home, {"hyprland": "crest"}, lambda *_: None, sys_read, current=cur)
            self.assertEqual(open(f"{home}/.config/hypr/hyprland.lua").read(), 'local shell = "crest"\n')
            self.assertTrue(any(n.startswith("hyprland.lua.weka-") for n in os.listdir(f"{home}/.config/hypr")))

    def test_sway_swap(self):
        with tempfile.TemporaryDirectory() as home:
            os.makedirs(f"{home}/.config/sway")
            with open(f"{home}/.config/sway/config", "w") as f:
                f.write("set $mod Mod4\nexec dms run\n")
            userconf.apply_all(home, {"sway": "none"}, lambda *_: None)
            userconf.apply_all(home, {"niri": "noctalia", "sway": "dux"}, lambda *_: None,
                               lambda p: "input {}\n")
            self.assertIn('spawn-at-startup "noctalia"', open(f"{home}/.config/niri/config.kdl").read())
            self.assertEqual(open(f"{home}/.config/sway/config").read().count("exec dms run"), 1)


if __name__ == "__main__":
    unittest.main()
