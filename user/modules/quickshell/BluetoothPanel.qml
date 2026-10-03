import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property real anchorX
    required property real anchorBottom
    required property var shell

    property var deviceList: []
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var deviceObjects: adapter && adapter.devices ? adapter.devices.values : []

    signal closeRequested()

    function openFullApp(): void {
        root.shell.run(["kitty", "--class", "waybar-bluetooth", "--title", "[ bluetooth ]", "-e", "bluetui"]);
        root.closeRequested();
    }

    function deviceLabel(device): string {
        if (!device)
            return "unknown device";
        return device.name || device.deviceName || device.address || "unknown device";
    }

    function deviceIcon(device): string {
        const icon = device && device.icon ? device.icon.toLowerCase() : "";
        if (icon.indexOf("head") >= 0 || icon.indexOf("audio") >= 0)
            return "󰋋";
        if (icon.indexOf("keyboard") >= 0)
            return "󰌌";
        if (icon.indexOf("mouse") >= 0 || icon.indexOf("input") >= 0)
            return "󰍽";
        if (icon.indexOf("phone") >= 0)
            return "󰏲";
        if (icon.indexOf("computer") >= 0)
            return "󰍹";
        return "󰂯";
    }

    function batteryPercent(device): int {
        if (!device || !device.batteryAvailable)
            return -1;
        return Math.round(device.battery <= 1 ? device.battery * 100 : device.battery);
    }

    function deviceStatus(device): string {
        if (!device)
            return "unavailable";
        if (device.pairing)
            return "pairing…";
        switch (device.state) {
        case BluetoothDeviceState.Connected:
            return batteryPercent(device) >= 0 ? `connected · ${batteryPercent(device)}%` : "connected";
        case BluetoothDeviceState.Connecting:
            return "connecting…";
        case BluetoothDeviceState.Disconnecting:
            return "disconnecting…";
        default:
            return device.paired ? "paired" : "available";
        }
    }

    function deviceAction(device): string {
        if (!device)
            return "";
        if (device.pairing)
            return "cancel";
        switch (device.state) {
        case BluetoothDeviceState.Connected:
            return "disconnect";
        case BluetoothDeviceState.Connecting:
        case BluetoothDeviceState.Disconnecting:
            return "working…";
        default:
            return device.paired ? "connect" : "pair";
        }
    }

    function deviceRank(device): int {
        if (device && device.connected)
            return 0;
        if (device && device.paired)
            return 1;
        return 2;
    }

    function refreshDevices(): void {
        const devices = (root.deviceObjects || []).filter(device => device && root.deviceLabel(device) !== "unknown device");
        root.deviceList = devices.slice().sort((left, right) => {
            const rankDifference = root.deviceRank(left) - root.deviceRank(right);
            if (rankDifference !== 0)
                return rankDifference;
            return root.deviceLabel(left).localeCompare(root.deviceLabel(right));
        });
    }

    function activateDevice(device): void {
        if (!device || !adapter || !adapter.enabled)
            return;
        if (device.pairing) {
            device.cancelPair();
            return;
        }
        switch (device.state) {
        case BluetoothDeviceState.Connected:
            device.disconnect();
            break;
        case BluetoothDeviceState.Connecting:
        case BluetoothDeviceState.Disconnecting:
            break;
        default:
            if (device.paired)
                device.connect();
            else
                device.pair();
            break;
        }
        deviceRefresh.restart();
    }

    function adapterStatus(): string {
        if (!adapter)
            return "no adapter available";
        switch (adapter.state) {
        case BluetoothAdapterState.Blocked:
            return "blocked by the system";
        case BluetoothAdapterState.Enabling:
            return "turning on…";
        case BluetoothAdapterState.Disabling:
            return "turning off…";
        default:
            return adapter.enabled ? (adapter.discovering ? "on · scanning" : "on") : "off";
        }
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
    implicitWidth: 390
    implicitHeight: 510
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    onAdapterChanged: deviceRefresh.restart()
    onDeviceObjectsChanged: deviceRefresh.restart()

    Component.onCompleted: {
        deviceRefresh.restart();
        if (adapter && adapter.enabled)
            adapter.discovering = true;
    }

    Component.onDestruction: {
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }

    Connections {
        target: root.adapter

        function onEnabledChanged(): void {
            if (root.adapter && root.adapter.enabled)
                root.adapter.discovering = true;
            deviceRefresh.restart();
        }

        function onDiscoveringChanged(): void {
            deviceRefresh.restart();
        }
    }

    Timer {
        id: deviceRefresh
        interval: 100
        onTriggered: root.refreshDevices()
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: root.refreshDevices()
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
                text: "[ bluetooth ]"
                color: root.shell.focusedColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
                font.bold: true
            }

            PanelExpandButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                shell: root.shell
                onClicked: root.openFullApp()
            }
        }

        Rectangle {
            id: adapterCard
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                topMargin: 8
                leftMargin: 12
                rightMargin: 12
            }
            height: 66
            color: root.shell.secondBackground
            border.width: 1
            border.color: root.shell.borderColor

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                width: 28
                horizontalAlignment: Text.AlignLeft
                text: root.adapter && root.adapter.enabled ? "󰂯" : "󰂲"
                color: root.adapter && root.adapter.enabled ? root.shell.focusedColor : root.shell.structureColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 22
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: 50
                    right: adapterToggle.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 3

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.adapter ? (root.adapter.name || "Bluetooth") : "Bluetooth"
                    color: root.shell.textColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.adapterStatus()
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 10
                }
            }

            Rectangle {
                id: adapterToggle
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                width: 64
                height: 28
                color: adapterTogglePointer.containsMouse
                    ? root.shell.hoverColor
                    : (root.adapter && root.adapter.enabled ? root.shell.focusedColor : root.shell.background)
                border.width: 1
                border.color: adapterTogglePointer.containsMouse
                    ? root.shell.hoverColor
                    : (root.adapter && root.adapter.enabled ? root.shell.focusedColor : root.shell.borderColor)
                opacity: root.adapter && root.adapter.state !== BluetoothAdapterState.Blocked ? 1 : 0.45

                Text {
                    anchors.centerIn: parent
                    text: root.adapter && root.adapter.enabled ? "disable" : "enable"
                    color: adapterTogglePointer.containsMouse || (root.adapter && root.adapter.enabled) ? root.shell.background : root.shell.textColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: adapterTogglePointer
                    anchors.fill: parent
                    enabled: root.adapter && root.adapter.state !== BluetoothAdapterState.Blocked
                    hoverEnabled: true
                    onClicked: root.adapter.enabled = !root.adapter.enabled
                }
            }
        }

        Row {
            id: devicesHeader
            anchors {
                top: adapterCard.bottom
                left: parent.left
                right: parent.right
                topMargin: 10
                leftMargin: 12
                rightMargin: 12
            }
            height: 30

            Text {
                width: parent.width - scanButton.width
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: `devices (${root.deviceList.length})`
                color: root.shell.structureColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Rectangle {
                id: scanButton
                width: 82
                height: 26
                color: scanPointer.containsMouse ? root.shell.secondBackground : "transparent"
                border.width: 1
                border.color: root.shell.borderColor
                opacity: root.adapter && root.adapter.enabled ? 1 : 0.45

                Text {
                    anchors.centerIn: parent
                    text: root.adapter && root.adapter.discovering ? "stop scan" : "scan"
                    color: root.adapter && root.adapter.discovering ? root.shell.focusedColor : root.shell.textColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 10
                }

                MouseArea {
                    id: scanPointer
                    anchors.fill: parent
                    enabled: root.adapter && root.adapter.enabled
                    hoverEnabled: true
                    onClicked: root.adapter.discovering = !root.adapter.discovering
                }
            }
        }

        Text {
            visible: !root.adapter || !root.adapter.enabled
            anchors {
                top: devicesHeader.bottom
                left: parent.left
                right: parent.right
                margins: 12
            }
            height: visible ? 54 : 0
            verticalAlignment: Text.AlignVCenter
            text: root.adapter ? "turn on bluetooth to view devices" : "no bluetooth adapter available"
            color: root.shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 11
        }

        Text {
            visible: root.adapter && root.adapter.enabled && root.deviceList.length === 0
            anchors {
                top: devicesHeader.bottom
                left: parent.left
                right: parent.right
                margins: 12
            }
            height: visible ? 54 : 0
            verticalAlignment: Text.AlignVCenter
            text: root.adapter && root.adapter.discovering ? "searching for nearby devices…" : "no devices found"
            color: root.shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 11
        }

        Flickable {
            id: deviceScroll
            visible: root.adapter && root.adapter.enabled && root.deviceList.length > 0
            anchors {
                top: devicesHeader.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: 4
                bottomMargin: 12
                leftMargin: 12
                rightMargin: 12
            }
            clip: true
            contentWidth: width
            contentHeight: deviceColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: deviceColumn
                width: deviceScroll.width
                spacing: 3

                Repeater {
                    model: root.deviceList

                    Rectangle {
                        id: deviceRow
                        required property var modelData

                        width: deviceColumn.width
                        height: 48
                        color: modelData.connected
                            ? Qt.rgba(root.shell.focusedColor.r, root.shell.focusedColor.g, root.shell.focusedColor.b, 0.16)
                            : "transparent"

                        Rectangle {
                            visible: deviceRow.modelData.connected
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 1
                            color: root.shell.focusedColor
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            width: 26
                            horizontalAlignment: Text.AlignLeft
                            text: root.deviceIcon(deviceRow.modelData)
                            color: deviceRow.modelData.connected ? root.shell.focusedColor : root.shell.structureColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 17
                        }

                        Column {
                            anchors {
                                left: parent.left
                                leftMargin: 42
                                right: deviceActionButton.left
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 2

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: root.deviceLabel(deviceRow.modelData)
                                color: deviceRow.modelData.connected ? root.shell.focusedColor : root.shell.textColor
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 11
                                font.bold: deviceRow.modelData.connected
                            }

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: root.deviceStatus(deviceRow.modelData)
                                color: root.shell.structureColor
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 9
                            }
                        }

                        Rectangle {
                            id: deviceActionButton
                            anchors {
                                right: parent.right
                                rightMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                            width: 76
                            height: 28
                            color: deviceActionPointer.containsMouse ? root.shell.secondBackground : "transparent"
                            border.width: 1
                            border.color: deviceRow.modelData.connected ? root.shell.urgentColor : root.shell.borderColor
                            opacity: deviceRow.modelData.state === BluetoothDeviceState.Connecting
                                || deviceRow.modelData.state === BluetoothDeviceState.Disconnecting ? 0.55 : 1

                            Text {
                                anchors.centerIn: parent
                                text: root.deviceAction(deviceRow.modelData)
                                color: deviceRow.modelData.connected ? root.shell.urgentColor : root.shell.focusedColor
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: deviceActionPointer
                                anchors.fill: parent
                                enabled: root.adapter && root.adapter.enabled
                                    && deviceRow.modelData.state !== BluetoothDeviceState.Connecting
                                    && deviceRow.modelData.state !== BluetoothDeviceState.Disconnecting
                                hoverEnabled: true
                                onClicked: root.activateDevice(deviceRow.modelData)
                            }
                        }
                    }
                }
            }
        }

    }
}
