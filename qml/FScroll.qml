import QtQuick
import QtQuick.Controls.Basic

Flickable {
    id: root
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 4000
    maximumFlickVelocity: 2400
    contentWidth: width
    contentHeight: contentItem.childrenRect.height

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        implicitWidth: 10

        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: Qt.alpha(Theme.onSurface, parent.pressed ? 0.5 : 0.3)
        }

        background: Item {}
    }
}
