import QtQuick

Rectangle {
    id: root
    property bool selected: false
    property bool hovered: false
    property color tone: Theme.surfaceContainer
    property real shapeRadius: Theme.xl

    radius: shapeRadius
    color: selected ? Theme.glass(Theme.primaryContainer) : Theme.glass(hovered ? Theme.surfaceContainerHigh : tone)
    border.width: selected || activeFocus ? 2 : 1
    border.color: selected || activeFocus ? Theme.primary : Qt.alpha(Theme.outlineVariant, 0.6)

    ColorBehavior on color {}
    ColorBehavior on border.color {}

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.radius * 0.7
        anchors.rightMargin: root.radius * 0.7
        height: 1
        color: Qt.alpha(Theme.surfaceOn, 0.08)
    }
}
