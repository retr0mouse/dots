//@ pragma ShellId reisdro-dots
//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

ShellRoot {
    id: shellRoot

    readonly property color background: "#101211"
    readonly property color secondBackground: "#1a1d1b"
    readonly property color textColor: "#c5c8c5"
    readonly property color borderColor: "#303630"
    readonly property color structureColor: "#768076"
    readonly property color focusedColor: "#98a87c"
    readonly property color hoverColor: "#7f9f9f"
    readonly property color urgentColor: "#d08770"

    readonly property bool showBattery: Quickshell.env("QS_SHOW_BATTERY") === "1"
    readonly property bool showBacklight: Quickshell.env("QS_SHOW_BACKLIGHT") === "1"
    readonly property bool showDgpu: Quickshell.env("QS_SHOW_DGPU") === "1"
    readonly property bool showIgpu: Quickshell.env("QS_SHOW_IGPU") === "1"
    readonly property bool showPowerProfile: Quickshell.env("QS_SHOW_POWER_PROFILE") === "1"
    readonly property bool showVpn: Quickshell.env("QS_SHOW_VPN") === "1"
    readonly property string backlightDevice: Quickshell.env("QS_BACKLIGHT_DEVICE") || ""

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property real volume: audioSink && audioSink.audio ? audioSink.audio.volume : 0
    readonly property bool volumeMuted: audioSink && audioSink.audio ? audioSink.audio.muted : false
    property int lastBatteryNotice: 0

    function run(command: list<string>): void {
        Quickshell.execDetached(command);
    }

    function setVolume(value: real): void {
        if (audioSink && audioSink.audio)
            audioSink.audio.volume = Math.max(0, Math.min(1.5, value));
    }

    function toggleMute(): void {
        if (audioSink && audioSink.audio)
            audioSink.audio.muted = !audioSink.audio.muted;
    }

    function setBrightness(value: real): void {
        const bounded = Math.max(0.01, Math.min(1, value));
        systemData.brightnessRatio = bounded;
        run(["brightnessctl", "--device", backlightDevice, "set", `${Math.round(bounded * 100)}%`]);
        brightnessRefresh.restart();
    }

    function networkIcon(): string {
        if (systemData.networkType === "wifi")
            return "󰤨";
        if (systemData.networkType === "ethernet")
            return "󰈀";
        return "󰖪";
    }

    function batteryIcon(): string {
        if (systemData.batteryStatus === "Charging")
            return "󰂄";

        const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰁹"];
        return icons[Math.min(icons.length - 1, Math.floor(systemData.batteryCapacity / 12.5))];
    }

    function checkBattery(): void {
        if (!showBattery || systemData.batteryStatus === "Charging" || systemData.batteryStatus === "Full" || systemData.batteryCapacity > 30) {
            lastBatteryNotice = 0;
            return;
        }

        if (systemData.batteryCapacity <= 15 && lastBatteryNotice < 2) {
            lastBatteryNotice = 2;
            run(["notify-send", "--urgency=critical", "Very Low Battery", `${systemData.batteryCapacity}% remaining`]);
        } else if (systemData.batteryCapacity <= 30 && lastBatteryNotice < 1) {
            lastBatteryNotice = 1;
            run(["notify-send", "--urgency=normal", "Low Battery", `${systemData.batteryCapacity}% remaining`]);
        }
    }

    SystemData {
        id: systemData
        onBatteryCapacityChanged: shellRoot.checkBattery()
        onBatteryStatusChanged: shellRoot.checkBattery()
    }

    PwObjectTracker {
        objects: [shellRoot.audioSink]
    }

    Timer {
        id: brightnessRefresh
        interval: 250
        onTriggered: systemData.refresh()
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
            shell: shellRoot
            data: systemData
        }
    }
}
