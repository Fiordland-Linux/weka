import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real value: 0
    property bool indeterminate: false
    property real amplitude: 3
    property real wavelength: 28
    property real thickness: 6
    property real phase: 0
    property real head: -0.35
    property color active: Theme.primary
    property color track: Theme.secondaryContainer

    readonly property real pad: thickness / 2
    readonly property real span: Math.max(1, width - thickness)
    readonly property real startAt: indeterminate ? (Motion.reduced ? 0 : Math.max(0, head)) : 0
    readonly property real endAt: indeterminate ? (Motion.reduced ? 0.5 : Math.min(1, head + 0.35)) : Math.max(0, Math.min(1, value))

    implicitHeight: 16
    implicitWidth: 240
    Accessible.role: Accessible.ProgressBar
    Accessible.name: "progress"

    function wave() {
        const pts = []
        const x0 = pad + startAt * span
        const x1 = pad + endAt * span
        const cy = height / 2
        for (let x = x0; x < x1 + 3; x += 3) {
            const xx = Math.min(x, x1)
            pts.push(Qt.point(xx, cy + amplitude * Math.sin(2 * Math.PI * (xx - phase) / wavelength)))
            if (xx >= x1)
                break
        }
        if (pts.length < 2)
            pts.push(Qt.point(x0 + 0.1, cy), Qt.point(x0 + 0.2, cy))
        return pts
    }

    NumberAnimation on phase {
        from: 0
        to: root.wavelength
        duration: 1400
        loops: Animation.Infinite
        running: !Motion.reduced && root.visible
    }

    NumberAnimation on head {
        from: -0.35
        to: 1
        duration: 1600
        loops: Animation.Infinite
        running: root.indeterminate && !Motion.reduced && root.visible
    }

    SpringBehavior on value { preset: Motion.effectsSlow; eps: 0.002 }

    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            strokeColor: root.track
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: root.pad + root.endAt * root.span + (root.endAt > 0 ? 8 : 0)
            startY: root.height / 2

            PathLine {
                x: root.width - root.pad
                y: root.height / 2
            }
        }

        ShapePath {
            strokeColor: root.active
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.wave()
            }
        }
    }

    Rectangle {
        visible: !root.indeterminate && root.endAt < 0.97
        width: 4
        height: 4
        radius: 2
        x: root.width - root.pad - 2
        y: (root.height - 4) / 2
        color: root.active
    }
}
