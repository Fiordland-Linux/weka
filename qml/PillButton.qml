import QtQuick

Item {
    id: root
    property string text
    property string icon
    property string kind: "filled"
    signal clicked

    readonly property bool pressed: tap.pressed
    readonly property bool hovered: hover.hovered
    readonly property color fg: kind === "filled" ? Theme.onPrimary
        : kind === "tonal" ? Theme.onSecondaryContainer
        : kind === "danger" ? Theme.onErrorContainer
        : Theme.primary
    readonly property color bg: kind === "filled" ? Theme.primary
        : kind === "tonal" ? Theme.secondaryContainer
        : kind === "danger" ? Theme.errorContainer
        : "transparent"

    implicitHeight: 40
    implicitWidth: row.implicitWidth + (icon !== "" ? 40 : 48)
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.38
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: root.clicked()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked()
            event.accepted = true
        }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.pressed ? Theme.md : height / 2
        color: root.bg
        border.width: root.kind === "outlined" ? 1 : 0
        border.color: Theme.outline
        SpringBehavior on radius { preset: Motion.spatialFast; eps: 0.1 }
        ColorBehavior on color {}

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.fg
            opacity: !root.enabled ? 0 : root.pressed ? 0.12 : root.hovered ? 0.08 : 0
            FadeBehavior on opacity {}
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: body.radius + 4
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 20
            tint: root.fg
            anchors.verticalCenter: parent.verticalCenter
        }

        Txt {
            role: "labelL"
            text: root.text
            color: root.fg
            anchors.verticalCenter: parent.verticalCenter
        }
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
