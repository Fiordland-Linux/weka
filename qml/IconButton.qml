import QtQuick

Item {
    id: root
    property string icon
    property string label
    property bool toggle: false
    property bool selected: false
    signal clicked

    readonly property bool pressed: tap.pressed

    implicitWidth: 40
    implicitHeight: 40
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.38
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.clicked()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.pressed ? Theme.sm : root.toggle && !root.selected ? Theme.lg : height / 2
        color: root.selected ? Theme.primary : root.toggle ? Theme.surfaceContainerHighest : "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.primary
        SpringBehavior on radius { preset: Motion.spatialFast; eps: 0.1 }
        ColorBehavior on color {}

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.selected ? Theme.primaryOn : Theme.surfaceVariantOn
            opacity: root.pressed ? 0.12 : hover.hovered ? 0.08 : 0
            FadeBehavior on opacity {}
        }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: 24
        filled: root.selected
        tint: root.selected ? Theme.primaryOn : Theme.surfaceVariantOn
    }

    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: root.clicked()
    }

    HoverHandler {
        id: hover
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }
}
