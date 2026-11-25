pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.wallTop }
            GradientStop { position: 1; color: Theme.wallBottom }
        }
    }

    Repeater {
        model: 7

        Rectangle {
            id: ring
            required property int index
            readonly property real d: root.width * 0.95 * (1 - index / 8)
            x: root.width * 0.62 - d / 2
            y: root.height * 0.02 - d / 2
            width: d
            height: d
            radius: d / 2
            color: Qt.alpha(Theme.primary, Theme.dark ? 0.035 : 0.05)
        }
    }

    Repeater {
        model: 7

        Rectangle {
            id: glow
            required property int index
            readonly property real d: root.width * 0.75 * (1 - index / 8)
            x: root.width * 0.1 - d / 2
            y: root.height * 0.98 - d / 2
            width: d
            height: d
            radius: d / 2
            color: Qt.alpha(Theme.tertiary, Theme.dark ? 0.03 : 0.045)
        }
    }
}
