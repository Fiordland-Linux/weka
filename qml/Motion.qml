pragma Singleton
import QtQuick

QtObject {
    property bool system: false
    property bool user: false
    readonly property bool reduced: system || user

    readonly property int short: reduced ? 1 : 150
    readonly property int medium: reduced ? 1 : 300
    readonly property int long: reduced ? 1 : 500
    readonly property int extraLong: reduced ? 1 : 700

    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]

    readonly property var spatialFast: ({ spring: reduced ? 20 : 5, damping: reduced ? 1 : 0.28 })
    readonly property var spatialDefault: ({ spring: reduced ? 20 : 3.5, damping: reduced ? 1 : 0.35 })
    readonly property var spatialSlow: ({ spring: reduced ? 20 : 2.4, damping: reduced ? 1 : 0.4 })
    readonly property var effectsFast: ({ spring: 20, damping: 1 })
    readonly property var effectsDefault: ({ spring: 12, damping: 1 })
    readonly property var effectsSlow: ({ spring: 6, damping: 1 })
}
