import QtQuick

Behavior {
    enabled: !Motion.reduced

    NumberAnimation {
        duration: Motion.short
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standard
    }
}
