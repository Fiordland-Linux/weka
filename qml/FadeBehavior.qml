import QtQuick

Behavior {
    enabled: !Motion.reduced

    NumberAnimation {
        duration: Motion.durShort
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standard
    }
}
