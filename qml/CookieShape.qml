import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int sides: 8
    property real amp: 0.08
    property real spin: 0
    property color color: Theme.primary

    implicitWidth: 48
    implicitHeight: 48

    function outline() {
        const pts = []
        const r = Math.min(width, height) / 2
        const rot = spin * Math.PI / 180
        const n = 96
        for (let i = 0; i < n; i++) {
            const a = i / n * 2 * Math.PI
            const rho = r * (1 + amp * Math.cos(sides * a)) / (1 + amp)
            pts.push(Qt.point(width / 2 + rho * Math.cos(a + rot), height / 2 + rho * Math.sin(a + rot)))
        }
        return pts
    }

    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0

            PathPolyline {
                path: root.outline()
            }
        }
    }
}
