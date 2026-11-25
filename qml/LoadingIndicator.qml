import QtQuick

Item {
    id: root
    property real size: 48
    property color tone: Theme.primary
    property color container: Theme.primaryContainer
    property int sides: 6
    property real amp: 0.14

    implicitWidth: size
    implicitHeight: size
    Accessible.role: Accessible.Indicator
    Accessible.name: "loading"

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.container
    }

    CookieShape {
        id: shape
        anchors.centerIn: parent
        width: root.size * 0.62
        height: width
        color: root.tone
        sides: root.sides
        amp: root.amp
        spin: root.spin
    }

    property real spin: 0

    NumberAnimation on spin {
        from: 0
        to: 360
        duration: 2400
        loops: Animation.Infinite
        running: !Motion.reduced && root.visible
    }

    SequentialAnimation {
        loops: Animation.Infinite
        running: !Motion.reduced && root.visible

        NumberAnimation { target: root; property: "amp"; to: 0.01; duration: 420; easing.type: Easing.InOutQuad }
        ScriptAction { script: root.sides = root.sides === 6 ? 9 : root.sides === 9 ? 4 : 6 }
        NumberAnimation { target: root; property: "amp"; to: 0.14; duration: 420; easing.type: Easing.InOutQuad }
        PauseAnimation { duration: 500 }
    }
}
