#!/usr/bin/env python3
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from backend import HERE, Backend


def main():
    dry = "--dry-run" in sys.argv or os.environ.get("WEKA_DRY") == "1"
    os.environ.setdefault("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense")
    QQuickStyle.setStyle("Material")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("weka")
    app.setApplicationDisplayName("Desktops")
    app.setDesktopFileName("weka")
    app.setWindowIcon(QIcon.fromTheme("preferences-desktop"))
    backend = Backend(dry_run=dry)
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(os.path.join(HERE, "qml", "Main.qml")))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
