import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: bar

    required property var shell
    required property var data

    // Fractional output scales can round the layer surface and its exclusive
    // zone to different physical pixels. Paint one pixel past the reserved
    // area so the wallpaper cannot show through between the bar and clients.
    readonly property int reservedHeight: 28
    readonly property int seamOverlap: 1
    readonly property var monitor: Hyprland.monitorFor(screen)
    property string activePanel: ""

    function togglePanel(panel: string): void {
        const nextPanel = activePanel === panel ? "" : panel;
        activePanel = "";
        if (nextPanel !== "")
            Qt.callLater(() => activePanel = nextPanel);
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: reservedHeight + seamOverlap
    color: shell.background
    exclusiveZone: reservedHeight

    Text {
        id: hiddenMetrics
        visible: false
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 15
    }

    Row {
        id: leftModules
        parent: bar.contentItem
        anchors.left: parent.left
        anchors.top: parent.top
        height: bar.reservedHeight

        Rectangle {
            id: dashboardButton
            width: 40
            height: parent.height
            color: dashboardPointer.containsMouse ? shell.focusedColor : shell.secondBackground

            Text {
                anchors.centerIn: parent
                text: ""
                color: dashboardPointer.containsMouse ? shell.background : shell.focusedColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 17
            }

            MouseArea {
                id: dashboardPointer
                anchors.fill: parent
                hoverEnabled: true
                onClicked: bar.togglePanel("dashboard")
            }
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 5
            rightPadding: 4
            text: "["
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                id: workspace
                required property var modelData
                visible: modelData.id > 0 && modelData.monitor === bar.monitor
                width: visible ? 28 : 0
                height: leftModules.height
                color: modelData.active ? shell.focusedColor : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: workspace.modelData.name
                    color: workspace.modelData.active ? shell.background : (workspace.modelData.urgent ? shell.urgentColor : shell.textColor)
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 15
                    font.bold: workspace.modelData.active
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: workspace.modelData.activate()
                    onWheel: wheel => Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
                }
            }
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 4
            text: "]"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }
    }

    Row {
        id: performanceModules
        parent: bar.contentItem
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        height: bar.reservedHeight

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 4
            text: "["
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            height: parent.height
            shell: bar.shell
            label: `CPU:${bar.data.cpu}%`
            onClicked: bar.shell.run(["kitty", "--class", "waybar-performance", "--title", "[ performance ]", "-e", "btop"])
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            height: parent.height
            shell: bar.shell
            label: `RAM:${bar.data.memory}%`
            onClicked: bar.shell.run(["kitty", "--class", "waybar-performance", "--title", "[ performance ]", "-e", "btop"])
        }

        Text {
            visible: bar.shell.showIgpu
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            visible: bar.shell.showIgpu
            height: parent.height
            shell: bar.shell
            label: `iGPU:${bar.data.igpu}`
            onClicked: bar.shell.run(["kitty", "--class", "waybar-performance", "--title", "[ performance ]", "-e", "btop"])
        }

        Text {
            visible: bar.shell.showDgpu
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            visible: bar.shell.showDgpu
            height: parent.height
            shell: bar.shell
            label: `dGPU:${bar.data.dgpu}`
            onClicked: bar.shell.run(["kitty", "--class", "waybar-performance", "--title", "[ performance ]", "-e", "btop"])
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 4
            text: "]"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }
    }

    Row {
        id: rightModules
        parent: bar.contentItem
        anchors.right: parent.right
        anchors.top: parent.top
        height: bar.reservedHeight

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 4
            text: "["
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            id: volumeButton
            height: parent.height
            shell: bar.shell
            label: bar.shell.volumeMuted ? "󰝟" : ""
            normalColor: bar.shell.volumeMuted ? bar.shell.structureColor : bar.shell.textColor
            onClicked: button => {
                if (button === Qt.MiddleButton || button === Qt.RightButton) {
                    bar.shell.toggleMute();
                } else {
                    bar.togglePanel("audio");
                }
            }
            onWheel: direction => bar.shell.setVolume(bar.shell.volume + direction * 0.05)
        }

        Text {
            visible: bar.shell.showBacklight
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            id: brightnessButton
            visible: bar.shell.showBacklight
            height: parent.height
            shell: bar.shell
            label: "󰍹"
            onClicked: bar.togglePanel("brightness")
            onWheel: direction => bar.shell.setBrightness(bar.data.brightnessRatio + direction * 0.05)
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            id: bluetoothButton
            height: parent.height
            shell: bar.shell
            label: bar.data.bluetoothText
            tooltip: bar.data.bluetoothTooltip
            onClicked: button => {
                if (button === Qt.MiddleButton || button === Qt.RightButton)
                    bar.shell.run(["kitty", "--class", "waybar-bluetooth", "--title", "[ bluetooth ]", "-e", "bluetui"]);
                else
                    bar.togglePanel("bluetooth");
            }
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            id: networkButton
            height: parent.height
            shell: bar.shell
            label: bar.shell.networkIcon()
            normalColor: bar.data.networkType === "disconnected" ? bar.shell.urgentColor : bar.shell.textColor
            tooltip: bar.data.networkName
            onClicked: button => {
                if (button === Qt.MiddleButton || button === Qt.RightButton)
                    bar.shell.run(["kitty", "--class", "waybar-network", "--title", "[ network ]", "-e", "wlctl"]);
                else
                    bar.togglePanel("network");
            }
        }

        Text {
            visible: bar.shell.showBattery
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            id: batteryButton
            visible: bar.shell.showBattery
            height: parent.height
            shell: bar.shell
            label: `${bar.shell.batteryIcon()} ${bar.data.batteryCapacity}%`
            normalColor: bar.data.batteryStatus === "Charging" ? bar.shell.focusedColor : (bar.data.batteryCapacity <= 30 ? bar.shell.urgentColor : bar.shell.textColor)
            onClicked: bar.togglePanel("power")
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 4
            text: "]"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 4
            text: "["
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            id: dateButton
            height: parent.height
            shell: bar.shell
            label: Qt.formatDateTime(clock.date, "dd/MM/yyyy")
            normalColor: bar.shell.textColor
            onClicked: bar.togglePanel("calendar")
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 6
            text: "|"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }

        BarButton {
            id: timeButton
            height: parent.height
            shell: bar.shell
            label: Qt.formatDateTime(clock.date, "HH:mm")
            normalColor: bar.shell.textColor
            onClicked: bar.togglePanel("calendar")
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 4
            text: "]"
            color: shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        id: delayedStatus
        interval: 700
        onTriggered: bar.data.refresh()
    }

    LazyLoader {
        active: bar.activePanel !== ""

        PanelWindow {
            id: dismissLayer

            visible: true
            screen: bar.screen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-menu-dismiss"

            MouseArea {
                parent: dismissLayer.contentItem
                anchors.fill: parent
                onClicked: Qt.callLater(() => bar.activePanel = "")
            }
        }
    }

    LazyLoader {
        active: bar.activePanel === "dashboard"

        FetchPanel {
            visible: true
            targetScreen: bar.screen
            anchorX: leftModules.x + dashboardButton.x + dashboardButton.width / 2
            anchorBottom: leftModules.y + dashboardButton.y + dashboardButton.height
            shell: bar.shell
            data: bar.data
            onCloseRequested: bar.activePanel = ""
        }
    }

    LazyLoader {
        active: bar.activePanel === "audio"

        AudioPanel {
            visible: true
            targetScreen: bar.screen
            anchorX: rightModules.x + volumeButton.x + volumeButton.width / 2
            anchorBottom: rightModules.y + volumeButton.y + volumeButton.height
            shell: bar.shell
            onCloseRequested: bar.activePanel = ""
        }
    }

    LazyLoader {
        active: bar.activePanel === "brightness"

        DisplayPanel {
            visible: true
            targetScreen: bar.screen
            anchorX: rightModules.x + brightnessButton.x + brightnessButton.width / 2
            anchorBottom: rightModules.y + brightnessButton.y + brightnessButton.height
            shell: bar.shell
            systemData: bar.data
            onCloseRequested: bar.activePanel = ""
        }
    }

    LazyLoader {
        active: bar.activePanel === "calendar"

        CalendarPanel {
            visible: true
            targetScreen: bar.screen
            anchorX: rightModules.x + timeButton.x + timeButton.width / 2
            anchorBottom: rightModules.y + timeButton.y + timeButton.height
            shell: bar.shell
            onCloseRequested: bar.activePanel = ""
        }
    }

    LazyLoader {
        active: bar.activePanel === "bluetooth"

        BluetoothPanel {
            visible: true
            targetScreen: bar.screen
            anchorX: rightModules.x + bluetoothButton.x + bluetoothButton.width / 2
            anchorBottom: rightModules.y + bluetoothButton.y + bluetoothButton.height
            shell: bar.shell
            onCloseRequested: bar.activePanel = ""
        }
    }

    LazyLoader {
        active: bar.activePanel === "network"

        NetworkPanel {
            visible: true
            targetScreen: bar.screen
            anchorX: rightModules.x + networkButton.x + networkButton.width / 2
            anchorBottom: rightModules.y + networkButton.y + networkButton.height
            shell: bar.shell
            data: bar.data
            onCloseRequested: bar.activePanel = ""
        }
    }

    LazyLoader {
        active: bar.activePanel === "power"

        PowerPanel {
            visible: true
            targetScreen: bar.screen
            anchorX: rightModules.x + batteryButton.x + batteryButton.width / 2
            anchorBottom: rightModules.y + rightModules.height
            shell: bar.shell
            onCloseRequested: bar.activePanel = ""
            onProfileSelectionChanged: delayedStatus.restart()
        }
    }
}
