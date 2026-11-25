pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Card {
    id: root
    property var model: []
    property int current: 0
    signal picked(int index)

    implicitWidth: 92
    shapeRadius: Theme.xl

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 20
        anchors.bottomMargin: 20
        spacing: 6

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            Layout.bottomMargin: 18

            CookieShape {
                anchors.fill: parent
                sides: 9
                amp: 0.07
                color: Theme.tertiaryContainer
                spin: root.current * 20
                SpringBehavior on spin { preset: Motion.spatialSlow; eps: 0.2 }
            }

            Icon {
                anchors.centerIn: parent
                name: "widgets"
                size: 24
                filled: true
                tint: Theme.tertiaryContainerOn
            }
        }

        Repeater {
            model: root.model

            Item {
                id: item
                required property var modelData
                required property int index
                readonly property bool on: index === root.current
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                Accessible.selected: on

                Rectangle {
                    id: pill
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    height: 32
                    width: item.on ? 56 : 32
                    radius: 16
                    color: item.on ? Theme.secondaryContainer : "transparent"
                    SpringBehavior on width { preset: Motion.spatialFast; eps: 0.2 }
                    ColorBehavior on color {}

                    Icon {
                        anchors.centerIn: parent
                        name: item.modelData.icon
                        size: 24
                        filled: item.on
                        tint: item.on ? Theme.secondaryContainerOn : Theme.surfaceVariantOn
                    }
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 40
                    role: "labelM"
                    emphasized: item.on
                    text: item.modelData.label
                    color: item.on ? Theme.surfaceOn : Theme.surfaceVariantOn
                }

                TapHandler {
                    enabled: item.modelData.enabled
                    onTapped: root.picked(item.index)
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
