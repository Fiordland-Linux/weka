pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool dark: true
    property bool lowEnd: false
    property bool symbols: true

    readonly property color primary: dark ? "#9ECAFF" : "#2C6197"
    readonly property color onPrimary: dark ? "#00325A" : "#FFFFFF"
    readonly property color primaryContainer: dark ? "#1D4A74" : "#D2E4FF"
    readonly property color onPrimaryContainer: dark ? "#D2E4FF" : "#001C37"
    readonly property color secondary: dark ? "#BAC8DB" : "#526070"
    readonly property color secondaryContainer: dark ? "#3A4857" : "#D6E4F7"
    readonly property color onSecondaryContainer: dark ? "#D6E4F7" : "#101D2A"
    readonly property color tertiary: dark ? "#86D6CB" : "#006A62"
    readonly property color onTertiary: dark ? "#003733" : "#FFFFFF"
    readonly property color tertiaryContainer: dark ? "#00504A" : "#A2F2E6"
    readonly property color onTertiaryContainer: dark ? "#A2F2E6" : "#00201D"
    readonly property color error: dark ? "#FFB4AB" : "#BA1A1A"
    readonly property color onError: dark ? "#690005" : "#FFFFFF"
    readonly property color errorContainer: dark ? "#93000A" : "#FFDAD6"
    readonly property color onErrorContainer: dark ? "#FFDAD6" : "#410002"
    readonly property color surface: dark ? "#0E1217" : "#F8F9FF"
    readonly property color surfaceDim: dark ? "#0E1217" : "#D8DAE0"
    readonly property color surfaceBright: dark ? "#34383E" : "#F8F9FF"
    readonly property color surfaceContainerLowest: dark ? "#090D12" : "#FFFFFF"
    readonly property color surfaceContainerLow: dark ? "#161B21" : "#F2F3F9"
    readonly property color surfaceContainer: dark ? "#1A1F25" : "#ECEEF4"
    readonly property color surfaceContainerHigh: dark ? "#252A30" : "#E6E8EE"
    readonly property color surfaceContainerHighest: dark ? "#30353B" : "#E1E2E8"
    readonly property color onSurface: dark ? "#E1E2E8" : "#191C20"
    readonly property color onSurfaceVariant: dark ? "#C1C7D0" : "#41474F"
    readonly property color outline: dark ? "#8B919A" : "#717880"
    readonly property color outlineVariant: dark ? "#41474F" : "#C1C7D0"
    readonly property color inverseSurface: dark ? "#E1E2E8" : "#2E3135"
    readonly property color inverseOnSurface: dark ? "#2E3135" : "#EFF0F7"
    readonly property color wallTop: dark ? "#0B1B2C" : "#D9E8F8"
    readonly property color wallBottom: dark ? "#0A1218" : "#EDF3F8"

    readonly property real glassAlpha: lowEnd ? 0.94 : 0.72

    readonly property int none: 0
    readonly property int xs: 4
    readonly property int sm: 8
    readonly property int md: 12
    readonly property int lg: 16
    readonly property int lgInc: 20
    readonly property int xl: 28
    readonly property int xlInc: 32
    readonly property int xxl: 48

    readonly property string font: "Inter"
    readonly property string mono: "JetBrains Mono"
    readonly property string symbolFont: "Material Symbols Rounded"

    readonly property var type: ({
        displayL: { s: 57, l: 64, w: 400, tight: true },
        displayM: { s: 45, l: 52, w: 400, tight: true },
        displayS: { s: 36, l: 44, w: 400, tight: true },
        headlineL: { s: 32, l: 40, w: 500, tight: true },
        headlineM: { s: 28, l: 36, w: 500, tight: true },
        headlineS: { s: 24, l: 32, w: 500, tight: true },
        titleL: { s: 22, l: 28, w: 600, tight: false },
        titleM: { s: 16, l: 24, w: 600, tight: false },
        titleS: { s: 14, l: 20, w: 600, tight: false },
        bodyL: { s: 16, l: 24, w: 400, tight: false },
        bodyM: { s: 14, l: 20, w: 400, tight: false },
        bodyS: { s: 12, l: 16, w: 400, tight: false },
        labelL: { s: 14, l: 20, w: 600, tight: false },
        labelM: { s: 12, l: 16, w: 600, tight: false },
        labelS: { s: 11, l: 16, w: 600, tight: false },
        mono: { s: 12, l: 18, w: 400, tight: false }
    })

    function glass(c) {
        return Qt.alpha(c, glassAlpha)
    }
}
