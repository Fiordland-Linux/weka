import QtQuick

Behavior {
    id: root
    property var preset: Motion.spatialDefault
    property real eps: 0.25
    enabled: !Motion.reduced

    SpringAnimation {
        spring: root.preset.spring
        damping: root.preset.damping
        epsilon: root.eps
    }
}
