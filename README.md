# weka

<p><a href="https://donate.stripe.com/8x25kFfe96fn0WL6X12wU00"><img src=".github/donate.svg" alt="Donate to Fiordland"></a> <a href="https://discord.gg/gy4ANH2Q9V"><img src=".github/discord.svg" alt="Join the Fiordland Discord"></a></p>

Created by [Apollo](https://apollo44.lat) ([3cfl](https://github.com/3cfl) on GitHub, u5sk on Discord), as part of [Fiordland Linux](https://github.com/Fiordland-Linux/fiordland).

The Desktops app for [Fiordland Linux](https://fiordlandlinux.org). Swap desktops and window managers cleanly, without reinstalling: weka installs the new one, sets up its login manager and removes what the old one left behind.

## Run

```
python3 weka.py            open the app
python3 weka.py --dry-run  walk through without changing anything
```

Needs `python`, `pyside6`, `qt6-wayland`, `polkit`, `pacman`. Privileged steps go through `weka-helper` with polkit (`dist/lat.apollo44.weka.policy`).

## Tests

```
python -m pytest -q tests
```

## License

GPL-3.0. See [LICENSE](LICENSE).
