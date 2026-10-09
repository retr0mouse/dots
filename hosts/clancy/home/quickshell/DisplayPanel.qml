import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property real anchorX
    required property real anchorBottom
    required property var shell
    required property var systemData

    property var status: ({})
    property var monitors: []
    property string errorMessage: ""
    property bool statusReady: false
    property bool actionPending: false
    property real brightnessValue: systemData.brightnessRatio
    property bool brightnessDragging: false

    readonly property var visibleMonitors: monitors.filter(monitor => monitor
        && monitor.enabled !== false
        && root.monitorWidth(monitor) > 0
        && root.monitorHeight(monitor) > 0)
    readonly property bool daemonRunning: status.daemon ? status.daemon.running !== false : false
    readonly property bool managed: status.daemon ? status.daemon.unmanaged !== true : false
    readonly property string activeProfile: profileName(status.active_profile
        || (status.daemon ? status.daemon.active_profile : null))
    readonly property string recommendedProfile: profileName(status.recommended_profile)

    signal closeRequested()

    function profileName(profile): string {
        if (!profile)
            return "";
        if (typeof profile === "string")
            return profile;
        return String(profile.name || profile.profile_name || "");
    }

    function profileTitle(): string {
        if (!managed)
            return "display management is off";
        if (activeProfile !== "")
            return activeProfile;
        if (recommendedProfile !== "")
            return recommendedProfile;
        return visibleMonitors.length > 0 ? "custom layout" : "no active displays";
    }

    function profileSubtitle(): string {
        if (!statusReady)
            return errorMessage !== "" ? errorMessage : "reading monitor state…";
        if (!managed)
            return "turn management on for automatic profiles";
        const count = visibleMonitors.length;
        const displayText = count === 1 ? "1 display" : `${count} displays`;
        if (activeProfile !== "")
            return `${displayText} · active profile`;
        if (recommendedProfile !== "")
            return `${displayText} · recommended profile`;
        return `${displayText} · no saved profile matches`;
    }

    function monitorWidth(monitor): real {
        if (!monitor)
            return 0;
        const logical = Number(monitor.logical_width || monitor.width || 0);
        if (logical > 0)
            return logical;
        const match = String(monitor.mode || "").match(/^(\d+)x(\d+)/);
        return match ? Number(match[1]) / Math.max(0.1, Number(monitor.scale || 1)) : 0;
    }

    function monitorHeight(monitor): real {
        if (!monitor)
            return 0;
        const logical = Number(monitor.logical_height || monitor.height || 0);
        if (logical > 0)
            return logical;
        const match = String(monitor.mode || "").match(/^(\d+)x(\d+)/);
        return match ? Number(match[2]) / Math.max(0.1, Number(monitor.scale || 1)) : 0;
    }

    function layoutBounds(): var {
        if (visibleMonitors.length === 0)
            return { x: 0, y: 0, width: 1, height: 1 };

        let minX = Infinity;
        let minY = Infinity;
        let maxX = -Infinity;
        let maxY = -Infinity;
        visibleMonitors.forEach(monitor => {
            const x = Number(monitor.x || 0);
            const y = Number(monitor.y || 0);
            minX = Math.min(minX, x);
            minY = Math.min(minY, y);
            maxX = Math.max(maxX, x + monitorWidth(monitor));
            maxY = Math.max(maxY, y + monitorHeight(monitor));
        });
        return { x: minX, y: minY, width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) };
    }

    function monitorRect(monitor, canvasWidth: real, canvasHeight: real): var {
        const bounds = layoutBounds();
        const padding = 13;
        const availableWidth = Math.max(1, canvasWidth - padding * 2);
        const availableHeight = Math.max(1, canvasHeight - padding * 2);
        const factor = Math.min(availableWidth / bounds.width, availableHeight / bounds.height);
        const contentWidth = bounds.width * factor;
        const contentHeight = bounds.height * factor;
        const offsetX = padding + (availableWidth - contentWidth) / 2;
        const offsetY = padding + (availableHeight - contentHeight) / 2;
        return {
            x: offsetX + (Number(monitor.x || 0) - bounds.x) * factor,
            y: offsetY + (Number(monitor.y || 0) - bounds.y) * factor,
            width: Math.max(58, monitorWidth(monitor) * factor),
            height: Math.max(42, monitorHeight(monitor) * factor)
        };
    }

    function monitorLabel(monitor): string {
        return String(monitor.description || monitor.model || monitor.name || "display");
    }

    function monitorDetail(monitor): string {
        const mode = String(monitor.mode || "").replace("Hz", " Hz");
        const scale = Number(monitor.scale || 1);
        return mode !== "" ? `${mode} · ${scale}x` : `${scale}x`;
    }

    function refresh(): void {
        if (!statusProcess.running)
            statusProcess.exec(["hyprmoncfg", "status", "--json"]);
    }

    function applyStatus(output: string): void {
        const text = output.trim();
        if (text === "")
            return;
        try {
            const parsed = JSON.parse(text);
            status = parsed;
            monitors = parsed.monitors instanceof Array ? parsed.monitors : [];
            statusReady = true;
            errorMessage = "";
        } catch (error) {
            errorMessage = "unable to read hyprmoncfg status";
            console.warn(`Unable to parse hyprmoncfg status: ${error}`);
        }
    }

    function toggleManagement(): void {
        if (actionPending || !statusReady)
            return;
        actionPending = true;
        actionProcess.exec(["hyprmoncfg", managed ? "unmanage" : "manage"]);
    }

    function openEditor(): void {
        shell.run(["kitty", "--class", "panel-monitor", "--title", "[ displays ]", "-e", "hyprmoncfg", "tui"]);
        closeRequested();
    }

    screen: targetScreen
    anchors {
        top: true
        left: true
    }
    margins {
        top: Math.round(anchorBottom + 7)
        left: Math.max(0, Math.min(Math.max(0, targetScreen.width - implicitWidth), Math.round(anchorX - implicitWidth / 2)))
    }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 430
    implicitHeight: 438
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    Component.onCompleted: refresh()

    Timer {
        interval: 2500
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: actionRefresh
        interval: 900
        onTriggered: root.refresh()
    }

    Timer {
        id: brightnessApply
        interval: 45
        onTriggered: root.shell.setBrightness(root.brightnessValue)
    }

    Connections {
        target: root.systemData

        function onBrightnessRatioChanged(): void {
            if (!root.brightnessDragging)
                root.brightnessValue = root.systemData.brightnessRatio;
        }
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyStatus(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!root.statusReady && text.trim() !== "")
                    root.errorMessage = "hyprmoncfg is unavailable";
            }
        }
    }

    Process {
        id: actionProcess
        onRunningChanged: {
            if (!running) {
                root.actionPending = false;
                actionRefresh.restart();
            }
        }
    }

    Rectangle {
        parent: root.contentItem
        anchors.fill: parent
        color: root.shell.background
        border.width: 1
        border.color: root.shell.borderColor

        Item {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            height: 28

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "[ displays ]"
                color: root.shell.focusedColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
                font.bold: true
            }

            PanelExpandButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                shell: root.shell
                onClicked: root.openEditor()
            }
        }

        Column {
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 12
                topMargin: 8
            }
            spacing: 10

            Rectangle {
                width: parent.width
                height: 68
                color: root.shell.secondBackground
                border.width: 1
                border.color: root.managed ? root.shell.focusedColor : root.shell.borderColor

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    width: 28
                    text: root.managed ? "󰍹" : "󰶐"
                    color: root.managed ? root.shell.focusedColor : root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 22
                }

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 50
                        right: manageButton.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.profileTitle()
                        color: root.shell.textColor
                        elide: Text.ElideRight
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.profileSubtitle()
                        color: root.shell.structureColor
                        elide: Text.ElideRight
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    id: manageButton
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    width: 68
                    height: 28
                    color: managePointer.containsMouse
                        ? root.shell.hoverColor
                        : (root.managed ? root.shell.focusedColor : root.shell.background)
                    border.width: 1
                    border.color: managePointer.containsMouse
                        ? root.shell.hoverColor
                        : (root.managed ? root.shell.focusedColor : root.shell.borderColor)
                    opacity: root.statusReady && !root.actionPending ? 1 : 0.5

                    Text {
                        anchors.centerIn: parent
                        text: root.actionPending ? "working…" : (root.managed ? "unmanage" : "manage")
                        color: managePointer.containsMouse || root.managed ? root.shell.background : root.shell.textColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: managePointer
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.statusReady && !root.actionPending
                        onClicked: root.toggleManagement()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 190
                color: root.shell.secondBackground
                border.width: 1
                border.color: root.shell.borderColor

                Text {
                    id: layoutTitle
                    anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: 10
                        leftMargin: 12
                    }
                    text: "live layout"
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Item {
                    id: topology
                    anchors {
                        top: layoutTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 10
                        topMargin: 7
                    }

                    Text {
                        visible: root.visibleMonitors.length === 0
                        anchors.centerIn: parent
                        text: root.statusReady ? "no active displays reported" : "loading display layout…"
                        color: root.shell.structureColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: root.visibleMonitors

                        Rectangle {
                            id: monitorCard
                            required property var modelData
                            readonly property var geometry: root.monitorRect(modelData, topology.width, topology.height)

                            x: geometry.x
                            y: geometry.y
                            width: Math.min(geometry.width, topology.width - x)
                            height: Math.min(geometry.height, topology.height - y)
                            color: modelData.focused ? root.shell.focusedColor : root.shell.background
                            border.width: 1
                            border.color: modelData.focused ? root.shell.focusedColor : root.shell.structureColor

                            Column {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 7
                                }
                                spacing: 2

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.monitorLabel(monitorCard.modelData)
                                    color: monitorCard.modelData.focused ? root.shell.background : root.shell.textColor
                                    elide: Text.ElideRight
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: Math.min(11, Math.max(8, monitorCard.height / 5))
                                    font.bold: true
                                }

                                Text {
                                    visible: monitorCard.height >= 52
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.monitorDetail(monitorCard.modelData)
                                    color: monitorCard.modelData.focused ? root.shell.background : root.shell.structureColor
                                    elide: Text.ElideRight
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 8
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 62
                color: root.shell.secondBackground
                border.width: 1
                border.color: root.shell.borderColor

                Text {
                    id: brightnessIcon
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    width: 28
                    text: "󰃠"
                    color: root.shell.textColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 18
                }

                Item {
                    id: brightnessSlider
                    anchors {
                        left: brightnessIcon.right
                        right: brightnessValue.left
                        leftMargin: 7
                        rightMargin: 9
                        verticalCenter: parent.verticalCenter
                    }
                    height: 32

                    function updateFromPointer(pointerX: real): void {
                        root.brightnessValue = Math.max(0.01, Math.min(1, pointerX / Math.max(1, width)));
                        brightnessApply.restart();
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: 4
                        color: root.shell.background

                        Rectangle {
                            width: root.brightnessValue * parent.width
                            height: parent.height
                            color: root.shell.focusedColor
                        }
                    }

                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - width, root.brightnessValue * parent.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        color: brightnessPointer.pressed ? root.shell.hoverColor : root.shell.textColor
                        border.width: 1
                        border.color: root.shell.focusedColor
                    }

                    MouseArea {
                        id: brightnessPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: mouse => {
                            root.brightnessDragging = true;
                            brightnessSlider.updateFromPointer(mouse.x);
                        }
                        onPositionChanged: mouse => {
                            if (pressed)
                                brightnessSlider.updateFromPointer(mouse.x);
                        }
                        onReleased: {
                            brightnessApply.stop();
                            root.brightnessDragging = false;
                            root.shell.setBrightness(root.brightnessValue);
                        }
                        onCanceled: {
                            brightnessApply.stop();
                            root.brightnessDragging = false;
                        }
                    }
                }

                Text {
                    id: brightnessValue
                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(root.brightnessValue * 100)}%`
                    color: root.shell.textColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

        }
    }
}
