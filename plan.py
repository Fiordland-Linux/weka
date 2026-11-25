import fnmatch
import glob
import os
import re
import subprocess

import desktops

SESSION_DIRS = ["/usr/share/wayland-sessions", "/usr/share/xsessions"]
CORE = {"fiordland-base", "fiordland-desktop", "base", "linux", "linux-firmware", "sudo", "networkmanager",
        "pipewire", "wireplumber", "polkit", "systemd", "kuaka", "weka", "tawaki", "firefox", "git", "base-devel"}
SECRETS = {"kwallet", "kwallet-pam", "kwalletmanager", "ksshaskpass", "gnome-keyring", "seahorse", "libsecret",
           "keepassxc", "keepassxc-browser", "pass", "qtpass"}
KWALLET_HOSTS = {"plasma"}
DM_UNITS = {"sddm": "sddm", "gdm": "gdm", "lightdm": "lightdm", "greetd": "greetd", "cosmic": "cosmic-greeter"}
DM_PKGS = {"sddm": "sddm", "gdm": "gdm", "lightdm": "lightdm", "greetd": "greetd", "cosmic": "cosmic-greeter"}
RUNS = {s["run"] for s in desktops.SHELLS.values() if "run" in s}


class Sys:
    def pacman(self, *args):
        try:
            r = subprocess.run(["pacman", *args], capture_output=True, text=True, stdin=subprocess.DEVNULL)
        except OSError:
            return ""
        return r.stdout if r.returncode == 0 else ""

    def installed(self):
        return set(self.pacman("-Qq").split())

    def group(self, name, sync=False):
        return set(self.pacman("-Sgq" if sync else "-Qgq", name).split())

    def depends(self, pkgs):
        out = set()
        for line in self.pacman("-Qi", *pkgs).splitlines():
            if line.startswith("Depends On") and ":" in line:
                out |= {re.split("[<>=]", w)[0] for w in line.split(":", 1)[1].split() if w != "None"}
        return out

    def cascade(self, pkgs):
        if not pkgs:
            return set()
        try:
            r = subprocess.run(["pacman", "-Rsu", "--print", "--print-format", "%n", "--", *sorted(pkgs)],
                               capture_output=True, text=True, stdin=subprocess.DEVNULL)
        except OSError:
            return set(pkgs)
        return set(r.stdout.split()) if r.returncode == 0 else set(pkgs)

    def files(self, pkgs):
        out = {}
        if not pkgs:
            return out
        for line in self.pacman("-Ql", *sorted(pkgs)).splitlines():
            name, _, path = line.partition(" ")
            out.setdefault(name, []).append(path)
        return out

    def read(self, path):
        try:
            with open(path, errors="replace") as f:
                return f.read()
        except OSError:
            return ""

    def exists(self, path):
        return os.path.exists(path)

    def nonempty(self, pattern):
        return [f for f in glob.glob(pattern) if os.path.getsize(f) > 0]

    def current_dm(self):
        try:
            unit = os.path.basename(os.readlink("/etc/systemd/system/display-manager.service"))
        except OSError:
            return None
        unit = unit.removesuffix(".service")
        for dm, u in DM_UNITS.items():
            if u == unit:
                return dm
        return None


def session_file(sysm, d):
    for base in SESSION_DIRS:
        p = f"{base}/{d['session']}.desktop"
        if sysm.exists(p):
            return p
    return None


def hypr_shell(home, sysm):
    m = re.search(r'^local shell = "([\w-]+)"', sysm.read(f"{home}/.config/hypr/hyprland.lua"), re.M)
    if not m:
        return None
    if m.group(1) == "dots":
        sid = sysm.read(f"{home}/.config/fiordland/dots").strip()
        return sid if sid in desktops.SHELLS else None
    return m.group(1)


def marked(sysm, home, pkgs, shell):
    for m in shell.get("markers", []):
        if m.startswith("pkg:"):
            if m[4:] in pkgs:
                return True
        elif sysm.exists(f"{home}/{m}"):
            return True
    return False


def detect(sysm, home, pkgs=None):
    pkgs = pkgs if pkgs is not None else sysm.installed()
    found = {}
    for d in desktops.DESKTOPS:
        if not session_file(sysm, d):
            continue
        shells = d.get("shells", [])
        sid = None
        if shells:
            if d["id"] == "hyprland":
                sid = hypr_shell(home, sysm)
            if sid not in shells:
                dots = sysm.read(f"{home}/.config/fiordland/dots").strip()
                sid = next((s for s in shells if desktops.SHELLS[s].get("script") == dots), None)
            if sid not in shells:
                sid = next((s for s in shells if marked(sysm, home, pkgs, desktops.SHELLS[s])), None)
            if sid not in shells:
                sid = next((s for s in shells if "run" in desktops.SHELLS[s]
                            and desktops.SHELLS[s]["pkgs"][0] in pkgs), "none")
        found[d["id"]] = sid
    return found


def validate(keep, default):
    ids = {d["id"] for d in desktops.DESKTOPS}
    if not keep:
        raise ValueError("pick at least one desktop or window manager")
    for did, sid in keep.items():
        if did not in ids:
            raise ValueError(f"unknown desktop {did}")
        shells = desktops.find(did).get("shells", [])
        if shells and sid not in shells:
            raise ValueError(f"{sid} is not a shell for {did}")
        if not shells and sid:
            raise ValueError(f"{did} has no shells")
    if default not in keep:
        raise ValueError("the default login must be one you keep")


def expand(sysm, names, installed):
    out = set()
    for n in names:
        members = sysm.group(n) if n not in installed else set()
        out |= members or {n}
    return out


def launchers(paths, sysm):
    found = []
    for p in paths:
        if not (p.startswith("/usr/share/applications/") and p.endswith(".desktop")):
            continue
        text = sysm.read(p)
        if re.search(r"^NoDisplay\s*=\s*true", text, re.M | re.I) or re.search(r"^OnlyShowIn\s*=", text, re.M):
            continue
        if re.search(r"^Hidden\s*=\s*true", text, re.M | re.I):
            continue
        found.append(os.path.basename(p)[:-8])
    return found


def build(sysm, current, keep, default, remove_apps=False, home=None):
    validate(keep, default)
    installed = sysm.installed()
    want = set()
    for did, sid in keep.items():
        want |= set(desktops.packages(did, sid))
    warnings = []
    wallet = home and sysm.nonempty(f"{home}/.local/share/kwalletd/*.kwl")
    if wallet and KWALLET_HOSTS & set(current) and not KWALLET_HOSTS & set(keep):
        want.add("kwalletmanager")
        warnings.append("Your saved passwords are in KWallet, which only unlocks by itself inside KDE Plasma. "
                        "It stays installed with your passwords in it, and KWallet Manager is added so you can open "
                        "or export them. Apps on the new desktop may ask you to log in again.")
    install = sorted(p for p in want if p not in installed and not sysm.group(p))

    d = desktops.find(default)
    dm = d["dm"]
    old_dm = sysm.current_dm()
    need = expand(sysm, want, installed) | CORE | SECRETS
    need |= sysm.depends(["fiordland-base", "fiordland-desktop"])
    for kd in keep:
        need.add(DM_PKGS[desktops.find(kd)["dm"]])

    dropped = set()
    for did, sid in current.items():
        if did not in keep or keep[did] != sid:
            dropped |= set(desktops.packages(did, sid))
    seeds = {p for p in expand(sysm, dropped, installed) if p in installed and p not in need}
    cascade = {p for p in sysm.cascade(seeds) if p not in need}

    kept_apps = {}
    if not remove_apps:
        owned = sysm.files(cascade)
        for p in sorted(cascade):
            apps = launchers(owned.get(p, []), sysm)
            if apps:
                kept_apps[p] = apps
    remove = sorted(cascade - set(kept_apps))

    return {
        "keep": keep, "default": default, "install": install, "remove": remove, "warnings": warnings,
        "kept_apps": kept_apps, "dm": dm, "old_dm": old_dm, "switch_dm": dm != old_dm,
        "added": sorted(k for k in keep if k not in current),
        "dropped": sorted(k for k in current if k not in keep),
        "reshelled": sorted(k for k in keep if k in current and current[k] != keep[k]),
    }
