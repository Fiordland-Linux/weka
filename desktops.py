WAYLAND_WM = ["kitty", "thunar", "gvfs", "pavucontrol", "brightnessctl", "playerctl", "wl-clipboard", "grim", "slurp",
              "xdg-desktop-portal-gtk", "qt6-wayland", "network-manager-applet", "polkit-gnome", "greetd", "greetd-tuigreet"]
X11_WM = ["xorg-server", "xorg-xinit", "xterm", "kitty", "thunar", "gvfs", "pavucontrol", "brightnessctl", "playerctl",
          "network-manager-applet", "polkit-gnome", "dmenu", "feh", "lightdm", "lightdm-gtk-greeter"]
LIGHTDM = ["lightdm", "lightdm-gtk-greeter", "xorg-server"]

DESKTOPS = [
    {"id": "plasma", "name": "KDE Plasma", "kind": "desktop", "recommended": True,
     "desc": "Modern, flexible and familiar. Works like Windows out of the box.",
     "pkgs": ["plasma-meta", "konsole", "dolphin", "ark", "spectacle", "gwenview", "okular", "kate", "kcalc", "sddm"],
     "dm": "sddm", "session": "plasma"},
    {"id": "gnome", "name": "GNOME", "kind": "desktop",
     "desc": "Clean and focused, with a workflow built around activities.",
     "pkgs": ["gnome", "gnome-tweaks"], "dm": "gdm", "session": "gnome"},
    {"id": "cosmic", "name": "COSMIC", "kind": "desktop",
     "desc": "System76's new desktop, written in Rust, with optional tiling.",
     "pkgs": ["cosmic"], "dm": "cosmic", "session": "cosmic"},
    {"id": "xfce", "name": "Xfce", "kind": "desktop",
     "desc": "Light and traditional. Good on older hardware.",
     "pkgs": ["xfce4", "xfce4-goodies", "network-manager-applet", "pavucontrol", "gvfs", *LIGHTDM],
     "dm": "lightdm", "session": "xfce"},
    {"id": "cinnamon", "name": "Cinnamon", "kind": "desktop",
     "desc": "Linux Mint's desktop. A taskbar, a menu, no surprises.",
     "pkgs": ["cinnamon", "cinnamon-translations", "gnome-terminal", "nemo-fileroller", "lightdm", "lightdm-slick-greeter",
              "xorg-server"],
     "dm": "lightdm", "greeter": "lightdm-slick-greeter", "session": "cinnamon"},
    {"id": "budgie", "name": "Budgie", "kind": "desktop",
     "desc": "Simple and elegant, with a side panel for notifications.",
     "pkgs": ["budgie", "gnome-terminal", "nautilus", "network-manager-applet", "lightdm", "lightdm-slick-greeter"],
     "dm": "lightdm", "greeter": "lightdm-slick-greeter", "session": "budgie-desktop"},
    {"id": "mate", "name": "MATE", "kind": "desktop",
     "desc": "The classic GNOME 2 layout, still maintained.",
     "pkgs": ["mate", "mate-extra", "network-manager-applet", *LIGHTDM], "dm": "lightdm", "session": "mate"},
    {"id": "lxqt", "name": "LXQt", "kind": "desktop",
     "desc": "Lightweight Qt desktop.",
     "pkgs": ["lxqt", "breeze-icons", "network-manager-applet", "sddm", "xorg-server"], "dm": "sddm", "session": "lxqt"},
    {"id": "deepin", "name": "Deepin", "kind": "desktop",
     "desc": "Polished desktop from the deepin project.",
     "pkgs": ["deepin", *LIGHTDM], "dm": "lightdm", "session": "deepin"},
    {"id": "enlightenment", "name": "Enlightenment", "kind": "desktop",
     "desc": "Fast and unusual, with lots of eye candy.",
     "pkgs": ["enlightenment", "terminology", *LIGHTDM], "dm": "lightdm", "session": "enlightenment"},
    {"id": "lxde", "name": "LXDE", "kind": "desktop",
     "desc": "Very light GTK desktop.",
     "pkgs": ["lxde", *LIGHTDM], "dm": "lightdm", "session": "LXDE"},

    {"id": "hyprland", "name": "Hyprland", "kind": "wm", "wayland": True,
     "desc": "Animated tiling compositor. The home of most riced setups.",
     "pkgs": ["hyprland", "xdg-desktop-portal-hyprland", "hyprpolkitagent", *WAYLAND_WM],
     "dm": "greetd", "session": "hyprland", "cmd": "start-hyprland",
     "shells": ["crest", "noctalia", "dux", "caelestia", "illogical-impulse", "hyde", "ml4w", "jakoolit", "none"]},
    {"id": "niri", "name": "niri", "kind": "wm", "wayland": True,
     "desc": "Scrollable tiling. Windows sit on an endless strip.",
     "pkgs": ["niri", "xdg-desktop-portal-gnome", "xwayland-satellite", "alacritty", "fuzzel", "swaylock", *WAYLAND_WM],
     "dm": "greetd", "session": "niri", "cmd": "niri-session",
     "shells": ["noctalia", "dux", "inir", "none"]},
    {"id": "sway", "name": "Sway", "kind": "wm", "wayland": True,
     "desc": "i3 for Wayland. Stable and keyboard driven.",
     "pkgs": ["sway", "swaybg", "swaylock", "swayidle", "foot", "wmenu", "xdg-desktop-portal-wlr", *WAYLAND_WM],
     "dm": "greetd", "session": "sway", "cmd": "sway",
     "shells": ["dux", "none"]},
    {"id": "labwc", "name": "labwc", "kind": "wm", "wayland": True,
     "desc": "Openbox-style stacking compositor for Wayland.",
     "pkgs": ["labwc", "foot", "fuzzel", "swaybg", "xdg-desktop-portal-wlr", *WAYLAND_WM],
     "dm": "greetd", "session": "labwc", "cmd": "labwc",
     "shells": ["noctalia", "dux", "none"]},
    {"id": "i3", "name": "i3", "kind": "wm",
     "desc": "The classic manual tiling window manager for X11.",
     "pkgs": ["i3-wm", "i3status", "i3lock", "xss-lock", *X11_WM], "dm": "lightdm", "session": "i3"},
    {"id": "bspwm", "name": "bspwm", "kind": "wm",
     "desc": "Binary space partitioning, configured with shell scripts.",
     "pkgs": ["bspwm", "sxhkd", *X11_WM], "dm": "lightdm", "session": "bspwm"},
    {"id": "awesome", "name": "awesome", "kind": "wm",
     "desc": "Tiling and floating, configured in Lua.",
     "pkgs": ["awesome", *X11_WM], "dm": "lightdm", "session": "awesome"},
    {"id": "qtile", "name": "Qtile", "kind": "wm",
     "desc": "Tiling window manager written and configured in Python.",
     "pkgs": ["qtile", "python-psutil", *X11_WM], "dm": "lightdm", "session": "qtile"},
    {"id": "xmonad", "name": "xmonad", "kind": "wm",
     "desc": "Tiling window manager configured in Haskell.",
     "pkgs": ["xmonad", "xmonad-contrib", *X11_WM], "dm": "lightdm", "session": "xmonad"},
    {"id": "herbstluftwm", "name": "herbstluftwm", "kind": "wm",
     "desc": "Manual tiling with frames, driven by herbstclient.",
     "pkgs": ["herbstluftwm", *X11_WM], "dm": "lightdm", "session": "herbstluftwm"},
    {"id": "openbox", "name": "Openbox", "kind": "wm",
     "desc": "Minimal stacking window manager with a right-click menu.",
     "pkgs": ["openbox", "tint2", *X11_WM], "dm": "lightdm", "session": "openbox"},
    {"id": "fluxbox", "name": "Fluxbox", "kind": "wm",
     "desc": "Light stacking window manager with tabs.",
     "pkgs": ["fluxbox", *X11_WM], "dm": "lightdm", "session": "fluxbox"},
    {"id": "icewm", "name": "IceWM", "kind": "wm",
     "desc": "Light, with a taskbar and start menu.",
     "pkgs": ["icewm", *X11_WM], "dm": "lightdm", "session": "icewm-session"},
]

SHELLS = {
    "crest": {"name": "Fiordland Shell", "by": "crest, forked from Caelestia",
              "desc": "Floating top bar, dashboard, launcher and settings app. Made for Fiordland.",
              "pkgs": ["crest", "quickshell", "upower", "libnotify", "ttf-material-symbols-variable"],
              "run": "qs -c crest -d"},
    "noctalia": {"name": "Noctalia", "by": "noctalia-dev",
                 "desc": "Calm, minimal shell with a bar, launcher, control center and dock.",
                 "pkgs": ["noctalia", "upower", "ddcutil"], "run": "noctalia"},
    "dux": {"name": "Dux Shell", "by": "formerly DankMaterialShell",
            "desc": "Material 3 shell with widgets, clipboard history, plugins and wallpaper colours.",
            "pkgs": ["dux-shell", "matugen", "cava", "wtype", "qt6-multimedia"], "run": "dms run"},
    "caelestia": {"name": "Caelestia", "by": "caelestia-dots",
                  "desc": "The original Caelestia dots that crest is based on.",
                  "script": "caelestia", "pkgs": ["git", "base-devel"]},
    "illogical-impulse": {"name": "illogical-impulse", "by": "end-4",
                          "desc": "end-4's dots. AI sidebar, overview, Material You colours.",
                          "script": "illogical-impulse", "pkgs": ["git", "base-devel"]},
    "hyde": {"name": "HyDE", "by": "HyDE Project",
             "desc": "Theme switcher with dozens of complete looks. Replaces the login screen with SDDM.",
             "script": "hyde", "pkgs": ["git", "base-devel"]},
    "ml4w": {"name": "ML4W", "by": "My Linux For Work",
             "desc": "Complete Hyprland setup with a settings app and a welcome screen.",
             "script": "ml4w", "pkgs": ["git", "base-devel"]},
    "jakoolit": {"name": "JaKooLit", "by": "JaKooLit",
                 "desc": "Feature-packed dots with waybar layouts and a big keybind set.",
                 "script": "jakoolit", "pkgs": ["git", "base-devel"]},
    "inir": {"name": "iNiR", "by": "snowarch",
             "desc": "end-4's illogical-impulse rebuilt for niri.",
             "script": "inir", "pkgs": ["git", "base-devel"]},
    "none": {"name": "None", "by": "",
             "desc": "Just the window manager with a simple bar. Build your own.",
             "pkgs": []},
}

PLAIN = {
    "hyprland": ["waybar", "mako", "swaybg", "fuzzel", "hyprlock"],
    "niri": ["waybar", "mako", "swaybg", "swayidle"],
    "sway": [],
    "labwc": ["waybar", "mako"],
}

SHELLED = {
    "hyprland": ["fuzzel", "hyprlock"],
}


def find(did):
    for d in DESKTOPS:
        if d["id"] == did:
            return d
    return DESKTOPS[0]


def resolve(did, sid):
    d = find(did)
    shells = d.get("shells", [])
    if not shells:
        return d, None
    if sid not in shells:
        sid = shells[0]
    return d, sid


def packages(did, sid):
    d, sid = resolve(did, sid)
    pkgs = list(d["pkgs"])
    if sid:
        s = SHELLS[sid]
        pkgs += s["pkgs"]
        if sid == "none":
            pkgs += PLAIN.get(d["id"], [])
        elif "script" in s or sid != "crest":
            pkgs += SHELLED.get(d["id"], [])
    if d["id"] in ("plasma", "lxqt"):
        pkgs.append("print-manager")
    elif d["id"] != "gnome":
        pkgs.append("system-config-printer")
    seen = set()
    return [p for p in pkgs if not (p in seen or seen.add(p))]


def catalogue():
    out = []
    for d in DESKTOPS:
        out.append({
            "id": d["id"], "name": d["name"], "kind": d["kind"], "desc": d["desc"],
            "recommended": d.get("recommended", False),
            "shells": [{"id": s, "name": SHELLS[s]["name"], "by": SHELLS[s]["by"], "desc": SHELLS[s]["desc"],
                        "script": "script" in SHELLS[s]} for s in d.get("shells", [])],
        })
    return out
