import QtQuick

Text {
    id: root
    property string role: "bodyM"
    property bool emphasized: false
    readonly property var spec: Theme.type[role] || Theme.type.bodyM

    color: Theme.surfaceOn
    font.family: role === "mono" ? Theme.mono : Theme.font
    font.pixelSize: spec.s
    font.weight: Math.min(1000, spec.w + (emphasized ? 200 : 0))
    font.letterSpacing: spec.tight ? -0.02 * spec.s : 0
    lineHeight: spec.l
    lineHeightMode: Text.FixedHeight
    verticalAlignment: Text.AlignVCenter
}
