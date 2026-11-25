import QtQuick

Item {
    id: root
    property bool on: false
    property real shift: on ? 0 : 24

    opacity: on ? 1 : 0
    visible: opacity > 0.01
    enabled: on
    transform: Translate { y: root.shift }

    FadeBehavior on opacity {}
    SpringBehavior on shift { preset: Motion.spatialDefault }
}
