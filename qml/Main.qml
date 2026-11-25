pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Window {
    id: win
    width: 1080
    height: 740
    minimumWidth: 780
    minimumHeight: 580
    visible: true
    title: "Desktops"
    color: Theme.surface

    property var keep: ({})
    property string def: backend.currentDefault
    property bool removeApps: false
    property var plan: null
    property string planError: ""
    property bool planning: false
    property int page: 0
    property bool ok: false
    property string message: ""
    property string demoState: ""
    property string stepOverride: ""
    readonly property string stepNow: stepOverride || backend.step

    readonly property var titles: ["pick a desktop", "review changes", "applying", ok ? "all done" : "stopped"]
    readonly property var subtitles: [
        "tick what you want installed. anything you untick is removed cleanly.",
        "here is exactly what will happen. your files and other apps stay put.",
        "keep this window open and your pc on.",
        ok ? "restart to use your new setup." : "a snapshot was taken first, so you can roll back from the boot menu."
    ]
    readonly property var rail: [
        { icon: "desktop_windows", label: "pick", enabled: page === 1 },
        { icon: "fact_check", label: "review", enabled: false },
        { icon: "downloading", label: "apply", enabled: false },
        { icon: "check_circle", label: "done", enabled: false }
    ]

    function count() { return Object.keys(keep).length }

    function setKeep(id, on, shell) {
        const k = Object.assign({}, keep)
        if (on)
            k[id] = shell
        else
            delete k[id]
        keep = k
        if (!(def in k))
            def = Object.keys(k)[0] || ""
    }

    function changed() {
        const cur = backend.current
        const a = Object.keys(cur)
        const b = Object.keys(keep)
        if (a.length !== b.length)
            return true
        for (let i = 0; i < b.length; i++)
            if (!(b[i] in cur) || cur[b[i]] !== keep[b[i]])
                return true
        return def !== backend.currentDefault
    }

    function nameOf(id) {
        for (let i = 0; i < backend.catalogue.length; i++)
            if (backend.catalogue[i].id === id)
                return backend.catalogue[i].name
        return id
    }

    function shellName(d, sid) {
        for (let i = 0; i < d.shells.length; i++)
            if (d.shells[i].id === sid)
                return d.shells[i].name
        return sid
    }

    function review() {
        plan = null
        planError = ""
        planning = true
        page = 1
        backend.preview(keep, def, removeApps)
    }

    function sections() {
        if (!plan)
            return []
        const p = plan
        const kept = Object.keys(p.keep).map(function (k) {
            const d = backend.catalogue.find(function (x) { return x.id === k })
            return d.name + (p.keep[k] ? "  ·  " + shellName(d, p.keep[k]) : "") + (k === p.default ? "  (default login)" : "")
        })
        return [
            { h: "heads up", tone: "warn", items: p.warnings || [] },
            { h: "keeping", tone: "plain", items: kept },
            { h: "login screen", tone: "plain", items: [p.switch_dm ? "switching " + (p.old_dm || "none") + " to " + p.dm : p.dm + " stays as it is"] },
            { h: "installing " + p.install.length + " packages", tone: "mono", items: p.install },
            { h: "removing " + p.remove.length + " packages", tone: "bad", items: p.remove },
            { h: "apps that came with removed desktops, kept", tone: "plain", items: p.kept_apps.map(function (a) { return a.apps.join(", ") + "  (" + a.pkg + ")" }) }
        ]
    }

    function runDemo(name) {
        const cur = Object.assign({}, backend.current)
        stepOverride = ""
        if (name === "pick") {
            keep = cur
            def = backend.currentDefault
            page = 0
        } else if (name === "pick2") {
            const k = Object.assign({}, cur)
            k["niri"] = "noctalia"
            k["gnome"] = ""
            keep = k
            page = 0
        } else if (name === "review") {
            const k = Object.assign({}, cur)
            delete k["plasma"]
            k["niri"] = "noctalia"
            keep = k
            def = "hyprland"
            review()
        } else if (name === "apply") {
            logModel.clear()
            for (const t of ["$ pacman -Syu --needed --noconfirm -- niri noctalia fuzzel", ":: Synchronizing package databases...", " core is up to date", " extra is up to date", "resolving dependencies...", "(14/14) installing noctalia", "wrote /etc/greetd/config.toml"])
                logModel.append({ t: t })
            stepOverride = "install"
            page = 2
        } else if (name === "done") {
            ok = true
            message = ""
            page = 3
        } else if (name === "fail") {
            ok = false
            message = "login screen greetd did not install, nothing was removed."
            page = 3
        }
    }

    onDemoStateChanged: runDemo(demoState)

    Component.onCompleted: keep = Object.assign({}, backend.current)

    Binding { target: Theme; property: "dark"; value: backend.dark }
    Binding { target: Theme; property: "lowEnd"; value: backend.lowEnd }
    Binding { target: Theme; property: "symbols"; value: backend.hasSymbols }
    Binding { target: Motion; property: "system"; value: backend.reducedMotion }

    Connections {
        target: backend
        function onPlanReady(p) { win.plan = p; win.planning = false }
        function onPlanFailed(e) { win.planError = e; win.planning = false }
        function onLogAdded(t) { logModel.append({ t: t }); logView.positionViewAtEnd() }
        function onFinished(success, msg) { win.ok = success; win.message = msg; win.page = 3 }
    }

    ListModel { id: logModel }

    Backdrop { anchors.fill: parent }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        NavRail {
            Layout.fillHeight: true
            model: win.rail
            current: win.page
            onPicked: index => { if (index === 0) win.page = 0 }
        }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                height: 84

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Txt {
                        role: "headlineL"
                        text: win.titles[win.page]
                    }

                    Txt {
                        role: "bodyL"
                        text: win.subtitles[win.page]
                        color: Theme.onSurfaceVariant
                    }
                }

                Rectangle {
                    visible: backend.dryRun
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: dry.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: Theme.tertiaryContainer

                    Txt {
                        id: dry
                        anchors.centerIn: parent
                        role: "labelM"
                        text: "dry run"
                        color: Theme.onTertiaryContainer
                    }
                }
            }

            Item {
                id: body
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                PageFade {
                    anchors.fill: parent
                    on: win.page === 0

                    FScroll {
                        id: pickScroll
                        anchors.fill: parent

                        ColumnLayout {
                            width: pickScroll.width - 12
                            spacing: 0

                            GridLayout {
                                id: grid
                                Layout.fillWidth: true
                                columns: Math.max(1, Math.floor(width / 330))
                                columnSpacing: 14
                                rowSpacing: 14

                                Repeater {
                                    model: backend.catalogue

                                    DesktopCard {
                                        id: card
                                        required property var modelData
                                        info: modelData
                                        on: modelData.id in win.keep
                                        installed: modelData.id in backend.current
                                        inUse: backend.running === modelData.id
                                        isDefault: win.def === modelData.id
                                        locked: on && win.count() === 1
                                        canDefault: on && win.count() > 1
                                        shell: win.keep[modelData.id] || ""
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 100
                                        Layout.alignment: Qt.AlignTop
                                        onToggled: {
                                            const s = modelData.shells.length
                                                ? (backend.current[modelData.id] || modelData.shells[0].id) : ""
                                            win.setKeep(card.modelData.id, !card.on, s)
                                        }
                                        onBlocked: snack.show("you need at least one desktop or window manager")
                                        onShellPicked: id => win.setKeep(modelData.id, true, id)
                                        onDefaultPicked: win.def = modelData.id
                                    }
                                }
                            }

                            Item {
                                Layout.preferredHeight: 108
                            }
                        }
                    }
                }

                PageFade {
                    anchors.fill: parent
                    on: win.page === 1

                    FScroll {
                        id: revScroll
                        anchors.fill: parent

                        ColumnLayout {
                            width: revScroll.width - 12
                            spacing: 14

                            RowLayout {
                                visible: win.planning
                                Layout.fillWidth: true
                                Layout.topMargin: 40
                                spacing: 16

                                Item { Layout.fillWidth: true }
                                LoadingIndicator { size: 56 }
                                Txt {
                                    role: "titleM"
                                    text: "working out what to change"
                                    color: Theme.onSurfaceVariant
                                }
                                Item { Layout.fillWidth: true }
                            }

                            Card {
                                visible: win.planError !== ""
                                Layout.fillWidth: true
                                Layout.preferredHeight: errText.implicitHeight + 40
                                tone: Theme.errorContainer

                                Txt {
                                    id: errText
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    text: win.planError
                                    color: Theme.onErrorContainer
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Card {
                                visible: win.plan !== null && backend.running !== "" && !(backend.running in win.keep)
                                Layout.fillWidth: true
                                Layout.preferredHeight: warnRow.implicitHeight + 40
                                tone: Theme.errorContainer

                                RowLayout {
                                    id: warnRow
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 14

                                    Icon {
                                        name: "warning"
                                        filled: true
                                        tint: Theme.onErrorContainer
                                        Layout.alignment: Qt.AlignTop
                                    }

                                    Txt {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        color: Theme.onErrorContainer
                                        text: "you're removing " + win.nameOf(backend.running) + ", which you're using right now. it keeps running until you restart, then you'll log into " + win.nameOf(win.def) + "."
                                    }
                                }
                            }

                            Repeater {
                                model: win.sections()

                                Card {
                                    id: sec
                                    required property var modelData
                                    visible: modelData.items.length > 0
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: secCol.implicitHeight + 40
                                    tone: modelData.tone === "warn" ? Theme.tertiaryContainer
                                        : modelData.tone === "bad" ? Qt.alpha(Theme.errorContainer, 0.45) : Theme.surfaceContainer

                                    ColumnLayout {
                                        id: secCol
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 10

                                        Txt {
                                            role: "titleM"
                                            text: sec.modelData.h
                                            color: sec.modelData.tone === "bad" ? Theme.error : Theme.onSurface
                                        }

                                        Flow {
                                            visible: sec.modelData.tone === "mono" || sec.modelData.tone === "bad"
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Repeater {
                                                model: sec.modelData.tone === "mono" || sec.modelData.tone === "bad" ? sec.modelData.items : []

                                                Rectangle {
                                                    id: tag
                                                    required property string modelData
                                                    implicitWidth: tagText.implicitWidth + 16
                                                    implicitHeight: 24
                                                    radius: Theme.sm
                                                    color: sec.modelData.tone === "bad" ? Qt.alpha(Theme.error, 0.14) : Theme.surfaceContainerHighest

                                                    Txt {
                                                        id: tagText
                                                        anchors.centerIn: parent
                                                        role: "mono"
                                                        text: tag.modelData
                                                        color: sec.modelData.tone === "bad" ? Theme.error : Theme.onSurfaceVariant
                                                    }
                                                }
                                            }
                                        }

                                        Txt {
                                            visible: sec.modelData.tone !== "mono" && sec.modelData.tone !== "bad"
                                            Layout.fillWidth: true
                                            text: sec.modelData.items.join("\n")
                                            color: sec.modelData.tone === "warn" ? Theme.onTertiaryContainer : Theme.onSurfaceVariant
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }

                            Card {
                                visible: win.plan !== null
                                Layout.fillWidth: true
                                Layout.preferredHeight: 76

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    spacing: 16

                                    Txt {
                                        Layout.fillWidth: true
                                        role: "titleS"
                                        text: "also remove apps that came bundled with removed desktops"
                                    }

                                    FSwitch {
                                        label: "remove bundled apps"
                                        checked: win.removeApps
                                        onToggled: { win.removeApps = !win.removeApps; win.review() }
                                    }
                                }
                            }

                            Txt {
                                visible: win.plan !== null && win.plan.install.length === 0 && win.plan.remove.length === 0 && !win.plan.switch_dm
                                text: "no packages change. only your settings get updated."
                                color: Theme.onSurfaceVariant
                            }

                            Item {
                                Layout.preferredHeight: 108
                            }
                        }
                    }
                }

                PageFade {
                    anchors.fill: parent
                    on: win.page === 2

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.rightMargin: 12
                        spacing: 16

                        Card {
                            Layout.fillWidth: true
                            Layout.preferredHeight: stepsCol.implicitHeight + 44

                            ColumnLayout {
                                id: stepsCol
                                anchors.fill: parent
                                anchors.margins: 22
                                spacing: 18

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Repeater {
                                        model: backend.steps

                                        Rectangle {
                                            id: stepPill
                                            required property string modelData
                                            required property int index
                                            readonly property int at: backend.steps.indexOf(win.stepNow)
                                            readonly property bool done: index < at || win.page === 3
                                            readonly property bool now: index === at
                                            implicitWidth: stepRow.implicitWidth + 24
                                            implicitHeight: 36
                                            radius: now ? 18 : Theme.sm
                                            color: now ? Theme.primaryContainer : done ? Theme.tertiaryContainer : "transparent"
                                            border.width: now || done ? 0 : 1
                                            border.color: Theme.outlineVariant
                                            SpringBehavior on radius { preset: Motion.spatialFast; eps: 0.1 }
                                            ColorBehavior on color {}

                                            Row {
                                                id: stepRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Icon {
                                                    visible: stepPill.done || stepPill.now
                                                    name: stepPill.done ? "check" : "sync"
                                                    size: 18
                                                    tint: stepPill.done ? Theme.onTertiaryContainer : Theme.onPrimaryContainer
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Txt {
                                                    role: "labelL"
                                                    text: stepPill.modelData
                                                    color: stepPill.done ? Theme.onTertiaryContainer : stepPill.now ? Theme.onPrimaryContainer : Theme.onSurfaceVariant
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }
                                }

                                WavyProgress {
                                    Layout.fillWidth: true
                                    value: (Math.max(0, backend.steps.indexOf(win.stepNow)) + 0.5) / backend.steps.length
                                }
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.bottomMargin: 12
                            tone: Theme.surfaceContainerLowest
                            shapeRadius: Theme.lgInc

                            ListView {
                                id: logView
                                anchors.fill: parent
                                anchors.margins: 16
                                clip: true
                                model: logModel
                                spacing: 2

                                delegate: Txt {
                                    required property string t
                                    width: logView.width
                                    role: "mono"
                                    text: t
                                    wrapMode: Text.WrapAnywhere
                                    color: t.indexOf("error:") === 0 ? Theme.error : t.indexOf("$ ") === 0 ? Theme.primary : Theme.onSurfaceVariant
                                }
                            }
                        }
                    }
                }

                PageFade {
                    anchors.fill: parent
                    on: win.page === 3

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, 560)
                        spacing: 24

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 132
                            Layout.preferredHeight: 132

                            CookieShape {
                                anchors.fill: parent
                                sides: win.ok ? 9 : 4
                                amp: win.ok ? 0.06 : 0.16
                                color: win.ok ? Theme.primaryContainer : Theme.errorContainer
                                SpringBehavior on amp { preset: Motion.spatialSlow; eps: 0.002 }
                            }

                            Icon {
                                anchors.centerIn: parent
                                name: win.ok ? "check" : "close"
                                size: 64
                                tint: win.ok ? Theme.onPrimaryContainer : Theme.onErrorContainer
                            }
                        }

                        Txt {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            role: "bodyL"
                            color: win.ok ? Theme.onSurface : Theme.error
                            text: win.message || (win.ok ? "your desktops are set up. restart to log into " + win.nameOf(win.def) + "." : "")
                        }
                    }
                }

                Card {
                    id: bar
                    visible: opacity > 0.01
                    opacity: win.page === 2 ? 0 : 1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 12
                    anchors.bottomMargin: 8
                    height: 72
                    shapeRadius: Theme.xl
                    tone: Theme.surfaceContainerHigh
                    FadeBehavior on opacity {}

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 16
                        spacing: 10

                        Txt {
                            visible: win.page === 0
                            role: "titleS"
                            text: win.count() + " selected"
                            color: Theme.onSurfaceVariant
                        }

                        Item { Layout.fillWidth: true }

                        PillButton {
                            visible: win.page === 1
                            kind: "outlined"
                            icon: "arrow_back"
                            text: "back"
                            onClicked: win.page = 0
                        }

                        PillButton {
                            visible: win.page === 0
                            icon: "arrow_forward"
                            text: "review"
                            enabled: win.count() > 0 && win.changed()
                            onClicked: win.review()
                        }

                        PillButton {
                            visible: win.page === 1
                            text: "apply"
                            icon: "check"
                            enabled: win.plan !== null && !win.planning
                            onClicked: {
                                logModel.clear()
                                win.page = 2
                                backend.apply(win.keep, win.def, win.removeApps)
                            }
                        }

                        PillButton {
                            visible: win.page === 3
                            kind: "text"
                            icon: "history"
                            text: "show log"
                            onClicked: win.page = 2
                        }

                        PillButton {
                            visible: win.page === 3 && win.ok
                            kind: "outlined"
                            text: "later"
                            onClicked: Qt.quit()
                        }

                        PillButton {
                            visible: win.page === 3
                            icon: win.ok ? "restart_alt" : "close"
                            text: win.ok ? "restart now" : "close"
                            onClicked: win.ok ? backend.reboot() : Qt.quit()
                        }
                    }
                }
            }
        }
    }

    Snackbar {
        id: snack
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
