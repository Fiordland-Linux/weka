pragma Singleton
import QtQuick

QtObject {
    readonly property color bg: "#101113"
    readonly property color panel: "#15161a"
    readonly property color raised: "#1b1d21"
    readonly property color hover: "#212328"
    readonly property color line: "#25272c"
    readonly property color lineStrong: "#383b41"
    readonly property color text: "#e9eaec"
    readonly property color muted: "#9b9fa7"
    readonly property color faint: "#686c74"
    readonly property color accent: "#8ec5ff"
    readonly property color accentInk: "#0a1f33"
    readonly property color accentSoft: Qt.rgba(0.557, 0.773, 1, 0.12)
    readonly property color danger: "#ff8f85"
    readonly property string font: "Inter"
    readonly property string mono: "JetBrains Mono"
    readonly property int radius: 8
    readonly property int fast: 140
    readonly property int medium: 260
}
