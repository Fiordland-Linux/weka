#!/usr/bin/env python3
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from backend import HERE, Backend

STATES = ["pick", "pick2", "review", "apply", "done", "fail"]


def shoot(app, engine, outdir, prefix):
    root = engine.rootObjects()[0]
    os.makedirs(outdir, exist_ok=True)
    queue = list(STATES)

    def grab(name):
        root.grabWindow().save(os.path.join(outdir, f"{prefix}-{name}.png"))
        step()

    def step():
        if not queue:
            app.quit()
            return
        name = queue.pop(0)
        root.setProperty("demoState", "")
        root.setProperty("demoState", name)
        QTimer.singleShot(1000, lambda: grab(name))

    QTimer.singleShot(1200, step)


def main():
    ap = argparse.ArgumentParser(prog="weka")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--demo", action="store_true")
    ap.add_argument("--theme", choices=["light", "dark"], default="")
    ap.add_argument("--screenshot", metavar="DIR")
    ap.add_argument("--prefix", default="shot")
    args, rest = ap.parse_known_args()
    dry = args.dry_run or os.environ.get("WEKA_DRY") == "1"
    demo = args.demo or bool(args.screenshot)
    app = QGuiApplication([sys.argv[0], *rest])
    app.setApplicationName("weka")
    app.setApplicationDisplayName("Desktops")
    app.setDesktopFileName("weka")
    app.setWindowIcon(QIcon.fromTheme("preferences-desktop"))
    backend = Backend(dry_run=dry, demo=demo, theme=args.theme)
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(os.path.join(HERE, "qml", "Main.qml")))
    if not engine.rootObjects():
        sys.exit(1)
    if args.screenshot:
        shoot(app, engine, args.screenshot, args.prefix)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
