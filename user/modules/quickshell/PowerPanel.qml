import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property real anchorX
    required property real anchorBottom
    required property var shell

    readonly property var battery: UPower.displayDevice
    readonly property real batteryPercent: battery ? normalizedPercent(battery.percentage) : 0

    signal closeRequested()
    signal profileSelectionChanged()

    function normalizedPercent(value: real): real {
        return value <= 1 ? value * 100 : value;
    }

    function formatDuration(seconds: real): string {
        if (!seconds || seconds <= 0)
            return "estimating";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        if (hours === 0)
            return `${minutes} min`;
        return `${hours} h ${minutes} min`;
    }

    function batteryState(): string {
        if (!battery)
            return "unavailable";
        switch (battery.state) {
        case UPowerDeviceState.Charging:
            return "charging";
        case UPowerDeviceState.Discharging:
            return "discharging";
        case UPowerDeviceState.Empty:
            return "empty";
        case UPowerDeviceState.FullyCharged:
            return "fully charged";
        case UPowerDeviceState.PendingCharge:
            return "pending charge";
        case UPowerDeviceState.PendingDischarge:
            return "pending discharge";
        default:
            return UPower.onBattery ? "on battery" : "plugged in";
        }
    }

    function remainingTime(): string {
        if (!battery)
            return "unavailable";
        if (battery.state === UPowerDeviceState.Charging)
            return formatDuration(battery.timeToFull);
        if (battery.state === UPowerDeviceState.Discharging)
            return formatDuration(battery.timeToEmpty);
        return "—";
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
    implicitWidth: 380
    implicitHeight: 326
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

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
                text: "[ power ]"
                color: root.shell.focusedColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
                font.bold: true
            }

        }

        Column {
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 14
                topMargin: 8
            }
            spacing: 10

            Row {
                width: parent.width
                height: 56
                spacing: 12

                Text {
                    width: 42
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.shell.batteryIcon()
                    color: root.battery && root.battery.state === UPowerDeviceState.Charging ? root.shell.focusedColor : root.shell.textColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 26
                }

                Column {
                    width: parent.width - 54
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: root.battery ? `${Math.round(root.batteryPercent)}% · ${root.batteryState()}` : "battery unavailable"
                        color: root.shell.textColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Text {
                        text: root.battery && root.battery.model ? root.battery.model : "system battery"
                        color: root.shell.structureColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 7
                color: root.shell.secondBackground

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.batteryPercent / 100))
                    height: parent.height
                    color: root.battery && root.batteryPercent <= 30 ? root.shell.urgentColor : root.shell.focusedColor
                }
            }

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 8
                rowSpacing: 5

                Repeater {
                    model: [
                        { label: "remaining", value: root.remainingTime() },
                        { label: "rate", value: root.battery ? `${root.battery.changeRate.toFixed(1)} W` : "—" },
                        { label: "energy", value: root.battery ? `${root.battery.energy.toFixed(1)} Wh` : "—" },
                        { label: "full", value: root.battery ? `${root.battery.energyCapacity.toFixed(1)} Wh` : "—" },
                        { label: "health", value: root.battery && root.battery.healthSupported ? `${Math.round(root.normalizedPercent(root.battery.healthPercentage))}%` : "unavailable" },
                        { label: "source", value: UPower.onBattery ? "battery" : "AC power" }
                    ]

                    Row {
                        required property var modelData
                        width: (parent.width - 8) / 2
                        height: 20

                        Text {
                            width: 70
                            text: `${modelData.label}:`
                            color: root.shell.structureColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                        }

                        Text {
                            width: parent.width - 70
                            elide: Text.ElideRight
                            text: modelData.value
                            color: root.shell.textColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.shell.borderColor
            }

            Text {
                text: "power profile"
                color: root.shell.structureColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Row {
                width: parent.width
                height: 34
                spacing: 6

                Repeater {
                    model: [
                        { label: "silent", value: PowerProfile.PowerSaver },
                        { label: "balanced", value: PowerProfile.Balanced },
                        { label: "performance", value: PowerProfile.Performance }
                    ]

                    Rectangle {
                        id: profileButton
                        required property var modelData
                        readonly property bool selected: PowerProfiles.profile === modelData.value
                        readonly property bool supported: modelData.value !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile

                        width: (parent.width - 12) / 3
                        height: parent.height
                        color: profilePointer.containsMouse && supported && selected
                            ? root.shell.hoverColor
                            : (selected
                                ? root.shell.focusedColor
                                : (profilePointer.containsMouse && supported ? root.shell.secondBackground : "transparent"))
                        border.width: 1
                        border.color: profilePointer.containsMouse && supported && selected
                            ? root.shell.hoverColor
                            : (selected ? root.shell.focusedColor : root.shell.borderColor)
                        opacity: supported ? 1 : 0.4

                        Text {
                            anchors.centerIn: parent
                            text: profileButton.modelData.label
                            color: profileButton.selected ? root.shell.background : root.shell.textColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                            font.bold: profileButton.selected
                        }

                        MouseArea {
                            id: profilePointer
                            anchors.fill: parent
                            enabled: profileButton.supported
                            hoverEnabled: true
                            onClicked: {
                                PowerProfiles.profile = profileButton.modelData.value;
                                root.profileSelectionChanged();
                            }
                        }
                    }
                }
            }

            Text {
                visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                width: parent.width
                text: `performance limited: ${PerformanceDegradationReason.toString(PowerProfiles.degradationReason)}`
                color: root.shell.urgentColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 10
            }
        }
    }
}
