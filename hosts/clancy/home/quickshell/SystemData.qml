import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int cpu: 0
    property int memory: 0
    property string igpu: "N/A"
    property string dgpu: "N/A"
    property string powerProfile: ""
    property string bluetoothText: "󰂲"
    property string bluetoothTooltip: "Bluetooth unavailable"
    property string networkType: "disconnected"
    property string networkName: "offline"
    property string vpnText: ""
    property string vpnClass: ""
    property string vpnTooltip: ""
    property int batteryCapacity: 0
    property string batteryStatus: "Unknown"
    property real brightnessRatio: 0

    property double previousCpuTotal: 0
    property double previousCpuIdle: 0

    function refresh(): void {
        if (!statusProcess.running)
            statusProcess.running = true;
    }

    function applyStatus(text: string): void {
        try {
            const status = JSON.parse(text);
            const totalDelta = status.cpuTotal - previousCpuTotal;
            const idleDelta = status.cpuIdle - previousCpuIdle;

            if (previousCpuTotal > 0 && totalDelta > 0)
                cpu = Math.max(0, Math.min(100, Math.round(100 * (totalDelta - idleDelta) / totalDelta)));

            previousCpuTotal = status.cpuTotal;
            previousCpuIdle = status.cpuIdle;
            memory = status.memory;
            igpu = status.igpu;
            dgpu = status.dgpu;
            powerProfile = status.powerProfile;
            bluetoothText = status.bluetoothText;
            bluetoothTooltip = status.bluetoothTooltip;
            networkType = status.networkType;
            networkName = status.networkName;
            vpnText = status.vpnText;
            vpnClass = status.vpnClass;
            vpnTooltip = status.vpnTooltip;
            batteryCapacity = status.batteryCapacity;
            batteryStatus = status.batteryStatus;
            brightnessRatio = status.brightnessMax > 0 ? status.brightness / status.brightnessMax : 0;
        } catch (error) {
            console.warn(`Unable to parse quickshell-status output: ${error}`);
        }
    }

    Process {
        id: statusProcess
        command: [Quickshell.env("QS_STATUS_COMMAND") || "quickshell-status"]
        stdout: StdioCollector {
            onStreamFinished: root.applyStatus(text)
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
