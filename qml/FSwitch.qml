import QtQuick

Item {
    id: root
    property bool checked: false
    property string label
    signal toggled

    implicitWidth: 52
    implicitHeight: 32
    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onToggleAction: root.toggled()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.toggled()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.outline
        ColorBehavior on color {}
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: height / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }

    Rectangle {
        id: thumb
        readonly property real d: tap.pressed ? 28 : 24
        width: d
        height: d
        radius: d / 2
        x: (root.checked ? root.width - 16 : 16) - d / 2
        y: (root.height - d) / 2
        color: root.checked ? Theme.onPrimary : Theme.outline
        SpringBehavior on x { preset: Motion.spatialFast; eps: 0.1 }
        SpringBehavior on width { preset: Motion.spatialFast; eps: 0.1 }
        SpringBehavior on height { preset: Motion.spatialFast; eps: 0.1 }
        ColorBehavior on color {}

        Icon {
            anchors.centerIn: parent
            name: root.checked ? "check" : "close"
            size: 16
            tint: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        }
    }

    TapHandler {
        id: tap
        onTapped: root.toggled()
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
