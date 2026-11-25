pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Card {
    id: root
    required property var info
    property bool on: false
    property bool installed: false
    property bool inUse: false
    property bool isDefault: false
    property bool locked: false
    property bool canDefault: false
    property string shell: ""
    signal toggled
    signal blocked
    signal shellPicked(string id)
    signal defaultPicked

    readonly property bool wide: info.shells.length > 0
    readonly property int sides: [4, 6, 8, 9, 12][(info.id.charCodeAt(0) + info.id.length) % 5]

    implicitHeight: col.implicitHeight + 36
    selected: on
    hovered: hover.hovered
    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: info.name
    Accessible.checked: on
    Accessible.onToggleAction: locked ? blocked() : toggled()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.locked)
                root.blocked()
            else
                root.toggled()
            event.accepted = true
        }
    }

    HoverHandler {
        id: hover
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Item {
            id: head
            Layout.fillWidth: true
            implicitHeight: headCol.implicitHeight

            TapHandler {
                onTapped: root.locked ? root.blocked() : root.toggled()
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            ColumnLayout {
                id: headCol
                width: parent.width
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52

                        CookieShape {
                            anchors.fill: parent
                            sides: root.sides
                            amp: root.on ? 0.09 : 0.02
                            spin: root.on ? 22 : 0
                            color: root.on ? Theme.primary : Theme.secondaryContainer
                            SpringBehavior on amp { preset: Motion.spatialFast; eps: 0.002 }
                            SpringBehavior on spin { preset: Motion.spatialFast; eps: 0.2 }
                            ColorBehavior on color {}
                        }

                        Icon {
                            anchors.centerIn: parent
                            name: root.on ? "check" : root.info.kind === "wm" ? "terminal" : "desktop_windows"
                            size: 24
                            tint: root.on ? Theme.primaryOn : Theme.secondaryContainerOn
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Txt {
                            role: "titleL"
                            text: root.info.name
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Txt {
                            role: "labelM"
                            text: root.info.kind === "wm" ? "window manager" : "desktop"
                            color: Theme.surfaceVariantOn
                        }
                    }

                    Rectangle {
                        visible: root.inUse || root.installed
                        implicitWidth: badge.implicitWidth + 20
                        implicitHeight: 24
                        radius: 12
                        color: root.inUse ? Theme.tertiaryContainer : Theme.surfaceContainerHighest

                        Txt {
                            id: badge
                            anchors.centerIn: parent
                            role: "labelS"
                            text: root.inUse ? "in use" : "installed"
                            color: root.inUse ? Theme.tertiaryContainerOn : Theme.surfaceVariantOn
                        }
                    }
                }

                Txt {
                    Layout.fillWidth: true
                    text: root.info.desc
                    role: "bodyM"
                    color: Theme.surfaceVariantOn
                    wrapMode: Text.WordWrap
                    lineHeightMode: Text.ProportionalHeight
                    lineHeight: 1.15
                }
            }
        }

        Item {
            id: extra
            readonly property bool open: root.on && (root.wide || root.canDefault)
            Layout.fillWidth: true
            Layout.preferredHeight: open ? extraCol.implicitHeight : 0
            clip: true
            opacity: open ? 1 : 0
            SpringBehavior on Layout.preferredHeight { preset: Motion.spatialDefault; eps: 0.5 }
            FadeBehavior on opacity {}

            ColumnLayout {
                id: extraCol
                width: parent.width
                spacing: 8

                Txt {
                    visible: root.wide
                    role: "labelM"
                    text: "shell"
                    color: Theme.surfaceVariantOn
                }

                Flow {
                    visible: root.wide
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.info.shells

                        Chip {
                            required property var modelData
                            text: modelData.name
                            selected: root.shell === modelData.id
                            onClicked: root.shellPicked(modelData.id)
                        }
                    }
                }

                Chip {
                    visible: root.canDefault
                    text: "default login"
                    icon: "star"
                    selected: root.isDefault
                    onClicked: root.defaultPicked()
                }
            }
        }
    }
}
