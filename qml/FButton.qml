import QtQuick

Item {
    id: root
    property string text
    property string kind: "primary"
    property bool enabled: true
    signal clicked

    implicitWidth: label.implicitWidth + (kind === "link" ? 0 : 36)
    implicitHeight: 38
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        visible: root.kind !== "link"
        radius: Theme.radius
        color: root.kind === "primary" ? Theme.accent : mouse.containsMouse && root.enabled ? Theme.hover : "transparent"
        border.width: root.kind === "ghost" ? 1 : 0
        border.color: Theme.lineStrong
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.kind === "primary"
            color: "white"
            opacity: !root.enabled ? 0 : mouse.pressed ? 0.18 : mouse.containsMouse ? 0.1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        }
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.kind === "primary" ? Theme.accentInk : root.kind === "link" ? Theme.accent : Theme.text
        font.family: Theme.font
        font.pixelSize: 14
        font.weight: Font.Medium
        font.underline: root.kind === "link" && mouse.containsMouse
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: root.kind === "link" ? -6 : 0
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
