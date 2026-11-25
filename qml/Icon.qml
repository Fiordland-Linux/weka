import QtQuick

Text {
    id: root
    property string name
    property bool filled: false
    property real size: 24
    property real fill: filled ? 1 : 0
    property color tint: Theme.onSurface

    readonly property var glyphs: ({
        check: [0xE668, "✓"],
        close: [0xE5CD, "×"],
        arrow_back: [0xE5C4, "←"],
        arrow_forward: [0xE5C8, "→"],
        desktop_windows: [0xE30C, "▣"],
        terminal: [0xEB8E, "›"],
        fact_check: [0xF0C5, "☰"],
        downloading: [0xF001, "↓"],
        check_circle: [0xF0BE, "✓"],
        error: [0xF8B6, "!"],
        warning: [0xF083, "!"],
        star: [0xF09A, "★"],
        restart_alt: [0xF053, "↻"],
        expand_more: [0xE5CF, "⌵"],
        info: [0xE88E, "i"],
        sync: [0xE627, "↻"],
        widgets: [0xE1BD, "▦"],
        tune: [0xE429, "≡"],
        history: [0xE8B3, "↺"],
        lock: [0xE899, "■"]
    })
    readonly property var entry: glyphs[name] || [0xE5CD, "?"]

    text: Theme.symbols ? String.fromCodePoint(entry[0]) : entry[1]
    color: tint
    font.family: Theme.symbols ? Theme.symbolFont : Theme.font
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": 400, "GRAD": 0, "opsz": 24 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    width: size
    height: size
    Accessible.ignored: true

    FadeBehavior on fill {}
}
