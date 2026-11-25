pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property real radius: Theme.xl
    property real lift: 12
    visible: !Theme.lowEnd
    z: -1

    Repeater {
        model: 6

        Rectangle {
            required property int index
            x: -index * 4
            y: root.lift - index * 4 + 4
            width: root.width + index * 8
            height: root.height + index * 8
            radius: root.radius + index * 4
            color: Qt.rgba(0, 0, 0, 0.35 / 14)
        }
    }
}
