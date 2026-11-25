import QtQuick

Item {
    id: root
    property string text
    property bool shown: false

    function show(message) {
        text = message
        shown = true
        hide.restart()
    }

    width: body.width
    height: body.height
    y: shown ? parent.height - height - 28 : parent.height + 24
    opacity: shown ? 1 : 0
    visible: opacity > 0.01
    z: 20
    Accessible.role: Accessible.AlertMessage
    Accessible.name: text

    SpringBehavior on y { preset: Motion.spatialDefault }
    FadeBehavior on opacity {}

    Timer {
        id: hide
        interval: 3200
        onTriggered: root.shown = false
    }

    Shadow {
        anchors.fill: body
        radius: body.radius
    }

    Rectangle {
        id: body
        width: label.implicitWidth + 40
        height: 48
        radius: Theme.md
        color: Theme.inverseSurface

        Txt {
            id: label
            anchors.centerIn: parent
            role: "bodyM"
            text: root.text
            color: Theme.inverseOnSurface
        }
    }
}
