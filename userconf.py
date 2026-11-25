import os
import re
import shutil
import tempfile
import time

import desktops

WALL = "/usr/share/fiordland/wallpaper.png"


def backup(path):
    if os.path.exists(path):
        shutil.copy2(path, f"{path}.weka-{time.strftime('%Y%m%d-%H%M%S')}")


def read(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def write(path, text, log):
    real = os.path.realpath(path)
    folder = os.path.dirname(real)
    os.makedirs(folder, exist_ok=True)
    backup(real)
    mode = os.stat(real).st_mode & 0o777 if os.path.exists(real) else 0o644
    fd, tmp = tempfile.mkstemp(prefix=".weka-", dir=folder)
    try:
        with os.fdopen(fd, "w") as f:
            f.write(text)
        os.chmod(tmp, mode)
        os.replace(tmp, real)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise
    log(f"wrote {path}")


def swap_run(text, run):
    for old in desktops.SHELLS.values():
        if "run" in old and old["run"] != run and old["run"] in text:
            text = text.replace(old["run"], run)
    return text


def kdl_spawn(run):
    return "spawn-at-startup " + " ".join(f'"{w}"' for w in run.split())


def apply(home, did, sid, log=print, system=read):
    shell = desktops.SHELLS.get(sid) if sid else None
    script = shell and "script" in shell
    run = shell.get("run") if shell and not script else None
    if did == "hyprland":
        path = f"{home}/.config/hypr/hyprland.lua"
        text = read(path)
        if not re.search(r'^local shell = "[\w-]*"', text, re.M):
            text = system("/usr/share/fiordland/hyprland.lua")
        if not text:
            return
        val = "dots" if script else sid
        new = re.sub(r'^local shell = "[\w-]*"', f'local shell = "{val}"', text, count=1, flags=re.M)
        if new != read(path):
            write(path, new, log)
    elif did == "niri":
        path = f"{home}/.config/niri/config.kdl"
        text = read(path)
        if not text:
            text = system("/usr/share/doc/niri/default-config.kdl")
            extra = [kdl_spawn(run)] if run else ['spawn-at-startup "mako"', f'spawn-at-startup "swaybg" "-m" "fill" "-i" "{WALL}"']
            write(path, text.rstrip("\n") + "\n\n" + "\n".join(extra) + "\n", log)
        elif run:
            new = text
            for old in desktops.SHELLS.values():
                if "run" in old and old["run"] != run:
                    new = new.replace(kdl_spawn(old["run"]), kdl_spawn(run))
            if kdl_spawn(run) not in new:
                new = new.rstrip("\n") + "\n" + kdl_spawn(run) + "\n"
            if new != text:
                write(path, new, log)
    elif did == "sway":
        path = f"{home}/.config/sway/config"
        text = read(path)
        if not text:
            text = system("/etc/sway/config")
            if text and run:
                text = text.replace("\ninclude ", f"\nexec {run}\n\ninclude ", 1)
            if text:
                write(path, text, log)
        elif run:
            new = swap_run(text, run)
            if f"exec {run}" not in new:
                new = new.rstrip("\n") + f"\nexec {run}\n"
            if new != text:
                write(path, new, log)
    elif did == "labwc":
        path = f"{home}/.config/labwc/autostart"
        text = read(path)
        if not text:
            auto = [f"swaybg -m fill -i {WALL} &", "nm-applet --indicator &"]
            auto += [f"{run} &"] if run else ["waybar &", "mako &"]
            write(path, "\n".join(auto) + "\n", log)
        elif run:
            new = swap_run(text, run)
            if run not in new:
                new = new.rstrip("\n") + f"\n{run} &\n"
            if new != text:
                write(path, new, log)


def apply_all(home, keep, log=print, system=read, current=None):
    current = current or {}
    changed = {d: s for d, s in keep.items() if d not in current or current[d] != s}
    dots = f"{home}/.config/fiordland/dots"
    scripts = [desktops.SHELLS[s]["script"] for s in changed.values() if s and "script" in desktops.SHELLS[s]]
    if scripts:
        if read(dots).strip() not in scripts:
            write(dots, scripts[0] + "\n", log)
    elif os.path.exists(dots) and not any(s and "script" in desktops.SHELLS[s] for s in keep.values()):
        backup(dots)
        os.remove(dots)
        log(f"removed {dots}")
    for did, sid in changed.items():
        apply(home, did, sid, log, system)
