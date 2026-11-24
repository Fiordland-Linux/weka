import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property string kind: "check"
    property color color: Theme.text
    property real stroke: 1.8
    width: 16
    height: 16
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: root.color
        strokeWidth: root.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg {
            path: root.kind === "check" ? `M ${root.width * 0.2} ${root.height * 0.52} L ${root.width * 0.42} ${root.height * 0.74} L ${root.width * 0.8} ${root.height * 0.3}`
                : root.kind === "chevron" ? `M ${root.width * 0.25} ${root.height * 0.38} L ${root.width * 0.5} ${root.height * 0.63} L ${root.width * 0.75} ${root.height * 0.38}`
                : `M ${root.width * 0.62} ${root.height * 0.62} L ${root.width * 0.88} ${root.height * 0.88} M ${root.width * 0.42} ${root.height * 0.1} A ${root.width * 0.31} ${root.height * 0.31} 0 1 1 ${root.width * 0.419} ${root.height * 0.1}`
        }
    }
}
