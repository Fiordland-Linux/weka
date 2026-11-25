import QtQuick

Item {
    id: root
    property string text
    property string icon
    property bool selected: false
    signal clicked

    readonly property bool leading: selected || icon !== ""

    implicitHeight: 32
    implicitWidth: row.implicitWidth + (leading ? 20 : 28)
    activeFocusOnTab: true
    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    Accessible.checked: selected
    Accessible.onPressAction: root.clicked()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: tap.pressed ? Theme.xs : Theme.sm
        color: root.selected ? Theme.secondaryContainer : "transparent"
        border.width: root.selected ? 0 : 1
        border.color: root.activeFocus ? Theme.primary : Theme.outline
        ColorBehavior on color {}

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.onSurfaceVariant
            opacity: tap.pressed ? 0.12 : hover.hovered ? 0.08 : 0
            FadeBehavior on opacity {}
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.leading
            name: root.icon !== "" ? root.icon : "check"
            size: 18
            filled: root.selected
            tint: root.selected ? Theme.onSecondaryContainer : Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Txt {
            role: "labelL"
            text: root.text
            color: root.selected ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    TapHandler {
        id: tap
        onTapped: root.clicked()
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
}
