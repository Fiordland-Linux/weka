import QtQuick

Behavior {
    enabled: !Motion.reduced

    ColorAnimation {
        duration: Motion.short
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standard
    }
}
