import QtQuick

Behavior {
    enabled: !Motion.reduced

    ColorAnimation {
        duration: Motion.durShort
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standard
    }
}
