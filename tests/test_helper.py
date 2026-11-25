import importlib.machinery
import importlib.util
import os
import stat
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
sys.path.insert(0, ROOT)

import desktops
import userconf


def load():
    path = os.path.join(ROOT, "weka-helper")
    loader = importlib.machinery.SourceFileLoader("weka_helper", path)
    spec = importlib.util.spec_from_loader("weka_helper", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


helper = load()


class Parse(unittest.TestCase):
    def ok(self, *argv):
        return helper.parse(list(argv))

    def bad(self, *argv):
        with self.assertRaises(ValueError):
            helper.parse(list(argv))

    def test_valid(self):
        keep, default, apps, dry = self.ok("--keep", "plasma", "--keep", "hyprland:crest", "--default", "plasma",
                                           "--remove-apps", "--dry-run")
        self.assertEqual(keep, {"plasma": None, "hyprland": "crest"})
        self.assertEqual(default, "plasma")
        self.assertTrue(apps and dry)

    def test_trailing_colon_means_no_shell(self):
        keep, _, _, _ = self.ok("--keep", "plasma:", "--default", "plasma")
        self.assertEqual(keep, {"plasma": None})

    def test_unknown_flag(self):
        self.bad("--keep", "plasma", "--default", "plasma", "--shell", "sh")
        self.bad("--keep", "plasma", "--default", "plasma", "plasma")
        self.bad("--keep", "plasma", "--default", "plasma", "--exec=/bin/sh")

    def test_missing_values(self):
        self.bad("--keep")
        self.bad("--keep", "plasma", "--default")
        self.bad("--keep", "plasma")
        self.bad("--default", "plasma")
        self.bad()

    def test_path_traversal(self):
        for evil in ("../etc/passwd", "..", "plasma/../gnome", "/etc/shadow", "plasma/x", ".", "a b", "plasma;id",
                     "$(id)", "`id`", "plasma|x", "pla\0sma", "plasma\n", "PLASMA", "plasmá"):
            self.bad("--keep", evil, "--default", "plasma")
            self.bad("--keep", "plasma", "--default", evil)
            self.bad("--keep", f"hyprland:{evil}", "--default", "hyprland")

    def test_newline_not_tolerated(self):
        self.bad("--keep", "plasma\n", "--default", "plasma")
        self.bad("--keep", "plasma", "--default", "plasma\n")

    def test_length_limit(self):
        self.bad("--keep", "a" * 33, "--default", "a" * 33)

    def test_unknown_desktop_and_shell(self):
        self.bad("--keep", "bogus", "--default", "bogus")
        self.bad("--keep", "hyprland:nope", "--default", "hyprland")
        self.bad("--keep", "plasma:crest", "--default", "plasma")
        self.bad("--keep", "niri:crest", "--default", "niri")

    def test_default_must_be_kept(self):
        self.bad("--keep", "plasma", "--default", "gnome")

    def test_duplicates(self):
        self.bad("--keep", "plasma", "--keep", "plasma", "--default", "plasma")
        self.bad("--keep", "plasma", "--default", "plasma", "--default", "plasma")

    def test_too_many_args(self):
        argv = ["--remove-apps"] * 100
        self.bad(*argv)

    def test_every_catalogue_entry_accepted(self):
        for d in desktops.DESKTOPS:
            shells = d.get("shells", [None])
            for s in shells:
                arg = d["id"] + (f":{s}" if s else "")
                self.ok("--keep", arg, "--default", d["id"])


class User(unittest.TestCase):
    def test_pkexec_uid_ignored_without_root(self):
        import pwd
        me = os.getuid()
        if me < helper.MIN_UID:
            self.skipTest("needs a regular user")
        pw = helper.resolve_user({"PKEXEC_UID": "0"}, me, me)
        self.assertEqual(pw.pw_uid, me)

    def test_root_is_refused(self):
        with self.assertRaises(ValueError):
            helper.resolve_user({}, 0, 0)
        with self.assertRaises(ValueError):
            helper.resolve_user({"PKEXEC_UID": "0"}, 0, 0)

    def test_bad_pkexec_uid(self):
        for raw in ("", "-1", "1e3", "1000 ", "1000\n", "99999999999", "１０００"):
            with self.assertRaises(ValueError):
                helper.resolve_user({"PKEXEC_UID": raw}, 0, 0)

    def test_system_uid_refused(self):
        with self.assertRaises(ValueError):
            helper.resolve_user({"PKEXEC_UID": "1"}, 0, 0)

    def test_login_manager_rejects_unsafe_names(self):
        with tempfile.TemporaryDirectory() as root:
            old = helper.ROOT
            helper.ROOT = root
            try:
                for name in ("a\nb", "root\n[Autologin]", "A", "-x", "a b", "", "x" * 40):
                    with self.assertRaises(RuntimeError):
                        helper.login_manager(desktops.find("plasma"), name, True)
            finally:
                helper.ROOT = old


class Write(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.old = helper.ROOT
        helper.ROOT = self.tmp.name
        self.quiet = helper.out
        helper.out = lambda *a, **k: None

    def tearDown(self):
        helper.ROOT = self.old
        helper.out = self.quiet
        self.tmp.cleanup()

    def path(self, p):
        return self.tmp.name + p

    def test_write_creates_and_is_not_world_writable(self):
        helper.write("/etc/sddm.conf.d/10-fiordland.conf", "x\n")
        mode = stat.S_IMODE(os.stat(self.path("/etc/sddm.conf.d/10-fiordland.conf")).st_mode)
        self.assertEqual(mode, 0o644)
        self.assertEqual(open(self.path("/etc/sddm.conf.d/10-fiordland.conf")).read(), "x\n")

    def test_backup_made_once(self):
        os.makedirs(self.path("/etc/gdm"))
        with open(self.path("/etc/gdm/custom.conf"), "w") as f:
            f.write("old\n")
        helper.write("/etc/gdm/custom.conf", "one\n")
        helper.write("/etc/gdm/custom.conf", "two\n")
        self.assertEqual(open(self.path("/etc/gdm/custom.conf.weka-bak")).read(), "old\n")
        self.assertEqual(open(self.path("/etc/gdm/custom.conf")).read(), "two\n")

    def test_no_leftover_temp_files(self):
        helper.write("/etc/gdm/custom.conf", "a\n")
        self.assertEqual(sorted(os.listdir(self.path("/etc/gdm"))), ["custom.conf"])

    def test_symlinked_destination_is_replaced_not_followed(self):
        victim = self.path("/victim")
        with open(victim, "w") as f:
            f.write("keep\n")
        os.makedirs(self.path("/etc/gdm"))
        os.symlink(victim, self.path("/etc/gdm/custom.conf"))
        helper.write("/etc/gdm/custom.conf", "new\n")
        self.assertEqual(open(victim).read(), "keep\n")
        self.assertFalse(os.path.islink(self.path("/etc/gdm/custom.conf")))
        self.assertFalse(os.path.exists(self.path("/etc/gdm/custom.conf.weka-bak")))

    def test_predictable_tmp_symlink_not_followed(self):
        victim = self.path("/victim")
        with open(victim, "w") as f:
            f.write("keep\n")
        os.makedirs(self.path("/etc/gdm"))
        os.symlink(victim, self.path("/etc/gdm/custom.conf.weka-tmp"))
        helper.write("/etc/gdm/custom.conf", "new\n")
        self.assertEqual(open(victim).read(), "keep\n")

    def test_bak_symlink_not_followed(self):
        victim = self.path("/victim")
        with open(victim, "w") as f:
            f.write("keep\n")
        os.makedirs(self.path("/etc/gdm"))
        with open(self.path("/etc/gdm/custom.conf"), "w") as f:
            f.write("old\n")
        os.symlink(victim, self.path("/etc/gdm/custom.conf.weka-bak"))
        helper.write("/etc/gdm/custom.conf", "new\n")
        self.assertEqual(open(victim).read(), "keep\n")

    def test_login_manager_output(self):
        helper.login_manager(desktops.find("plasma"), "alice", True)
        text = open(self.path("/etc/sddm.conf.d/10-fiordland.conf")).read()
        self.assertIn("User=alice\n", text)
        self.assertIn("Session=plasma.desktop", text)
        helper.login_manager(desktops.find("hyprland"), "alice", True)
        text = open(self.path("/etc/greetd/config.toml")).read()
        self.assertIn('user = "alice"', text)
        self.assertIn("start-hyprland", text)

    def test_autologin_detected_with_regex_metachars_escaped(self):
        os.makedirs(self.path("/etc/sddm.conf.d"))
        with open(self.path("/etc/sddm.conf.d/10-fiordland.conf"), "w") as f:
            f.write("[Autologin]\nUser=alice\n")
        self.assertTrue(helper.autologin("alice"))
        self.assertFalse(helper.autologin("al.ce"))
        self.assertFalse(helper.autologin("bob"))


class Main(unittest.TestCase):
    def run_main(self, *argv):
        old = helper.sys.stderr
        helper.sys.stderr = open(os.devnull, "w")
        try:
            return helper.main(["weka-helper", *argv])
        finally:
            helper.sys.stderr.close()
            helper.sys.stderr = old

    def test_usage(self):
        self.assertEqual(self.run_main(), 2)
        self.assertEqual(self.run_main("shell"), 2)
        self.assertEqual(self.run_main("--keep", "plasma"), 2)

    def test_rejects_bad_argv_before_anything_else(self):
        self.assertEqual(self.run_main("apply", "--keep", "../x", "--default", "../x"), 2)
        self.assertEqual(self.run_main("plan", "--keep", "plasma", "--default", "gnome"), 2)


class Userconf(unittest.TestCase):
    def test_write_keeps_symlinked_dotfiles(self):
        with tempfile.TemporaryDirectory() as d:
            real = os.path.join(d, "repo", "config")
            os.makedirs(os.path.dirname(real))
            with open(real, "w") as f:
                f.write("one\n")
            os.makedirs(os.path.join(d, "home"))
            link = os.path.join(d, "home", "config")
            os.symlink(real, link)
            userconf.write(link, "two\n", lambda *_: None)
            self.assertTrue(os.path.islink(link))
            self.assertEqual(open(real).read(), "two\n")

    def test_write_leaves_no_temp(self):
        with tempfile.TemporaryDirectory() as d:
            userconf.write(os.path.join(d, "a", "b"), "x\n", lambda *_: None)
            self.assertEqual(os.listdir(os.path.join(d, "a")), ["b"])


class Policy(unittest.TestCase):
    def setUp(self):
        tree = ET.parse(os.path.join(ROOT, "dist", "lat.apollo44.weka.policy"))
        self.actions = tree.getroot().findall("action")

    def test_single_action(self):
        self.assertEqual([a.get("id") for a in self.actions], ["lat.apollo44.weka.apply"])

    def test_requires_admin_never_free(self):
        for a in self.actions:
            for tag in ("allow_any", "allow_inactive", "allow_active"):
                self.assertIn(a.find(f"defaults/{tag}").text, ("auth_admin", "auth_admin_keep"))

    def test_exec_path_and_argv1_pinned(self):
        a = self.actions[0]
        ann = {x.get("key"): x.text for x in a.findall("annotate")}
        self.assertEqual(ann["org.freedesktop.policykit.exec.path"], "/usr/lib/weka/weka-helper")
        self.assertEqual(ann["org.freedesktop.policykit.exec.argv1"], "apply")
        self.assertNotIn("org.freedesktop.policykit.imply", ann)


if __name__ == "__main__":
    unittest.main()
