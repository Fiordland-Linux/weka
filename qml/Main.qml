import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 980
    height: 700
    minimumWidth: 760
    minimumHeight: 560
    visible: true
    title: "Desktops"
    color: Theme.bg
    font.family: Theme.font
    Material.theme: Material.Dark
    Material.accent: Theme.accent

    property var keep: ({})
    property string def: backend.currentDefault
    property bool removeApps: false
    property var plan: null
    property string planError: ""
    property bool planning: false
    property int page: 0
    property bool ok: false
    property string message: ""

    function count() { return Object.keys(keep).length }
    function setKeep(id, on, shell) {
        var k = Object.assign({}, keep)
        if (on) k[id] = shell
        else delete k[id]
        keep = k
        if (!(def in k)) def = Object.keys(k)[0] || ""
    }
    function changed() {
        var cur = backend.current
        var a = Object.keys(cur), b = Object.keys(keep)
        if (a.length !== b.length) return true
        for (var i = 0; i < b.length; i++)
            if (!(b[i] in cur) || cur[b[i]] !== keep[b[i]]) return true
        return def !== backend.currentDefault
    }
    function nameOf(id) {
        for (var i = 0; i < backend.catalogue.length; i++)
            if (backend.catalogue[i].id === id) return backend.catalogue[i].name
        return id
    }
    function shellName(d, sid) {
        for (var i = 0; i < d.shells.length; i++)
            if (d.shells[i].id === sid) return d.shells[i].name
        return sid
    }
    function review() {
        plan = null
        planError = ""
        planning = true
        page = 1
        backend.preview(keep, def, removeApps)
    }

    Component.onCompleted: keep = Object.assign({}, backend.current)

    Connections {
        target: backend
        function onPlanReady(p) { win.plan = p; win.planning = false }
        function onPlanFailed(e) { win.planError = e; win.planning = false }
        function onLogAdded(t) { logModel.append({ t: t }); logView.positionViewAtEnd() }
        function onFinished(success, msg) { win.ok = success; win.message = msg; win.page = 3 }
    }

    ListModel { id: logModel }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 4
                Label {
                    text: ["Desktops", "Review changes", "Applying", win.ok ? "All done" : "Stopped"][win.page]
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    color: Theme.text
                }
                Label {
                    text: ["Pick what you want installed. Anything you untick gets removed cleanly.",
                           "Here's exactly what will happen. Your files and other apps stay put.",
                           "Don't close this window or turn off your PC.",
                           win.ok ? "Restart to use your new setup." : "A snapshot was taken first, so you can roll back from the boot menu if needed."][win.page]
                    color: Theme.muted
                    font.pixelSize: 13
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                visible: backend.dryRun
                text: "DRY RUN"
                color: Theme.accent
                font.family: Theme.mono
                font.pixelSize: 11
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: win.page

            ScrollView {
                id: pick
                clip: true
                contentWidth: availableWidth
                GridLayout {
                    width: pick.availableWidth
                    columns: width > 860 ? 3 : 2
                    columnSpacing: 12
                    rowSpacing: 12
                    Repeater {
                        model: backend.catalogue
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            property bool on: modelData.id in win.keep
                            property bool installed: modelData.id in backend.current
                            property bool last: on && win.count() === 1
                            Layout.fillWidth: true
                            Layout.preferredHeight: col.implicitHeight + 28
                            radius: Theme.radius
                            color: on ? Theme.accentSoft : hov.hovered ? Theme.hover : Theme.panel
                            border.width: 1
                            border.color: on ? Theme.accent : Theme.line
                            Behavior on color { ColorAnimation { duration: Theme.fast } }

                            HoverHandler { id: hov }
                            TapHandler {
                                enabled: !card.last
                                onTapped: {
                                    var s = card.modelData.shells.length
                                        ? (backend.current[card.modelData.id] || card.modelData.shells[0].id) : ""
                                    win.setKeep(card.modelData.id, !card.on, s)
                                }
                            }
                            ToolTip.visible: card.last && hov.hovered
                            ToolTip.text: "You need at least one desktop or window manager"

                            ColumnLayout {
                                id: col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6
                                RowLayout {
                                    spacing: 10
                                    Rectangle {
                                        width: 18; height: 18; radius: 4
                                        color: card.on ? Theme.accent : "transparent"
                                        border.width: card.on ? 0 : 1.5
                                        border.color: Theme.lineStrong
                                        opacity: card.last ? 0.5 : 1
                                        Glyph { anchors.centerIn: parent; kind: "check"; color: Theme.accentInk; visible: card.on; width: 14; height: 14 }
                                    }
                                    Label { text: card.modelData.name; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Label { text: card.modelData.kind; color: Theme.faint; font.pixelSize: 11 }
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        text: backend.running === card.modelData.id ? "in use" : card.installed ? "installed" : ""
                                        color: Theme.accent
                                        font.pixelSize: 11
                                    }
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: card.modelData.desc
                                    color: Theme.muted
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                                ComboBox {
                                    id: shellBox
                                    Layout.fillWidth: true
                                    visible: card.on && card.modelData.shells.length > 0
                                    model: card.modelData.shells
                                    textRole: "name"
                                    valueRole: "id"
                                    currentIndex: Math.max(0, indexOfValue(win.keep[card.modelData.id] || ""))
                                    onActivated: win.setKeep(card.modelData.id, true, currentValue)
                                }
                                RadioButton {
                                    visible: card.on && win.count() > 1
                                    checked: win.def === card.modelData.id
                                    text: "Log into this by default"
                                    font.pixelSize: 12
                                    padding: 0
                                    onClicked: win.def = card.modelData.id
                                }
                            }
                        }
                    }
                }
            }

            ScrollView {
                id: rev
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: rev.availableWidth
                    spacing: 14

                    BusyIndicator { visible: win.planning; Layout.alignment: Qt.AlignHCenter; running: visible }
                    Label { visible: win.planning; text: "Working out what to change..."; color: Theme.muted; Layout.alignment: Qt.AlignHCenter }
                    Label { visible: win.planError !== ""; text: win.planError; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }

                    Rectangle {
                        visible: win.plan !== null && backend.running !== "" && !(backend.running in win.keep)
                        Layout.fillWidth: true
                        Layout.preferredHeight: warn.implicitHeight + 24
                        radius: Theme.radius
                        color: Qt.rgba(1, 0.56, 0.52, 0.1)
                        border.color: Theme.danger
                        Label {
                            id: warn
                            anchors.fill: parent
                            anchors.margins: 12
                            wrapMode: Text.WordWrap
                            color: Theme.text
                            text: "You're removing " + win.nameOf(backend.running) + ", which you're using right now. It keeps running until you restart, then you'll log into " + win.nameOf(win.def) + "."
                        }
                    }

                    Repeater {
                        model: win.plan ? [
                            { h: "Keeping", items: Object.keys(win.plan.keep).map(function (k) {
                                var d = backend.catalogue.find(function (x) { return x.id === k })
                                return d.name + (win.plan.keep[k] ? "  ·  " + win.shellName(d, win.plan.keep[k]) : "") + (k === win.plan.default ? "  (default login)" : "") }) },
                            { h: "Login screen", items: [win.plan.switch_dm ? "Switching " + (win.plan.old_dm || "none") + " → " + win.plan.dm : win.plan.dm + " (unchanged)"] },
                            { h: "Installing " + win.plan.install.length + " packages", items: win.plan.install, mono: true },
                            { h: "Removing " + win.plan.remove.length + " packages", items: win.plan.remove, mono: true, bad: true },
                            { h: "Apps that came with removed desktops, kept", items: win.plan.kept_apps.map(function (a) { return a.apps.join(", ") + "  (" + a.pkg + ")" }) }
                        ] : []
                        delegate: ColumnLayout {
                            required property var modelData
                            visible: modelData.items.length > 0
                            Layout.fillWidth: true
                            spacing: 6
                            Label { text: modelData.h; color: Theme.text; font.weight: Font.DemiBold; font.pixelSize: 14 }
                            Label {
                                Layout.fillWidth: true
                                text: modelData.items.join(modelData.mono ? "  " : "\n")
                                color: modelData.bad ? Theme.danger : Theme.muted
                                font.family: modelData.mono ? Theme.mono : Theme.font
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    CheckBox {
                        visible: win.plan !== null
                        text: "Also remove apps that came bundled with removed desktops"
                        checked: win.removeApps
                        onToggled: { win.removeApps = checked; win.review() }
                    }
                    Label {
                        visible: win.plan !== null && win.plan.install.length === 0 && win.plan.remove.length === 0 && !win.plan.switch_dm
                        text: "No packages change. Only your settings get updated."
                        color: Theme.muted
                    }
                }
            }

            ColumnLayout {
                spacing: 14
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: backend.steps
                        delegate: RowLayout {
                            required property string modelData
                            required property int index
                            property int at: backend.steps.indexOf(backend.step)
                            spacing: 8
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: index < at ? Theme.accent : index === at ? Theme.text : Theme.lineStrong
                            }
                            Label {
                                text: modelData
                                color: index <= at ? Theme.text : Theme.faint
                                font.pixelSize: 12
                            }
                        }
                    }
                }
                ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: backend.steps.length
                    value: Math.max(0, backend.steps.indexOf(backend.step)) + (win.page === 3 ? 1 : 0.5)
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radius
                    color: Theme.panel
                    border.color: Theme.line
                    ListView {
                        id: logView
                        anchors.fill: parent
                        anchors.margins: 10
                        clip: true
                        model: logModel
                        delegate: Text {
                            width: logView.width
                            text: t
                            color: t.indexOf("error:") === 0 ? Theme.danger : t.indexOf("$ ") === 0 ? Theme.accent : Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 11
                            wrapMode: Text.WrapAnywhere
                        }
                        ScrollBar.vertical: ScrollBar {}
                    }
                }
            }

            ColumnLayout {
                spacing: 14
                Item { Layout.fillHeight: true }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 560
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: win.ok ? Theme.text : Theme.danger
                    font.pixelSize: 15
                    text: win.message || (win.ok ? "Your desktops are set up. Restart to log into " + win.nameOf(win.def) + "." : "")
                }
                FButton {
                    Layout.alignment: Qt.AlignHCenter
                    kind: "ghost"
                    text: "Show log"
                    onClicked: win.page = 2
                }
                Item { Layout.fillHeight: true }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Label {
                visible: win.page === 0
                text: win.count() + " selected"
                color: Theme.faint
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            FButton {
                visible: win.page === 1
                kind: "ghost"
                text: "Back"
                onClicked: win.page = 0
            }
            FButton {
                visible: win.page === 0
                text: "Review"
                enabled: win.count() > 0 && win.changed()
                onClicked: win.review()
            }
            FButton {
                visible: win.page === 1
                text: "Apply"
                enabled: win.plan !== null && !win.planning
                onClicked: {
                    logModel.clear()
                    win.page = 2
                    backend.apply(win.keep, win.def, win.removeApps)
                }
            }
            FButton {
                visible: win.page === 3 && win.ok
                kind: "ghost"
                text: "Later"
                onClicked: Qt.quit()
            }
            FButton {
                visible: win.page === 3
                text: win.ok ? "Restart now" : "Close"
                onClicked: win.ok ? backend.reboot() : Qt.quit()
            }
        }
    }
}
