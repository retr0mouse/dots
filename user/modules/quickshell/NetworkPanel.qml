import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property real anchorX
    required property real anchorBottom
    required property var shell
    required property var data

    property var networkList: []
    property var scannerDevice: null
    property string passwordSsid: ""
    property string passwordText: ""
    property bool passwordVisible: false
    property string errorMessage: ""
    property var details: ({
        device: "",
        type: "disconnected",
        connection: "",
        ip: "",
        gateway: "",
        dns: "",
        mac: "",
        mtu: "",
        speed: "",
        frequency: "",
        rxBytes: 0,
        txBytes: 0
    })

    readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: findDevice(DeviceType.Wifi)
    readonly property var wiredDevice: findDevice(DeviceType.Wired)
    readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    readonly property var connectedWifi: findConnectedWifi()
    readonly property bool connected: Boolean((wiredDevice && wiredDevice.connected) || connectedWifi)
    readonly property string connectionKind: wiredDevice && wiredDevice.connected ? "ethernet" : (connectedWifi ? "wifi" : "disconnected")
    readonly property string connectionName: {
        if (connectedWifi)
            return connectedWifi.name;
        if (wiredDevice && wiredDevice.connected && wiredDevice.network)
            return wiredDevice.network.name;
        return "offline";
    }
    readonly property int currentSignal: connectedWifi ? Math.round(connectedWifi.signalStrength * 100) : -1
    readonly property bool vpnUnavailableAtHome: root.data.vpnClass === "home"

    signal closeRequested()

    function openFullApp(): void {
        root.shell.run(["kitty", "--class", "waybar-network", "--title", "[ network ]", "-e", "wlctl"]);
        root.closeRequested();
    }

    function findDevice(type): var {
        const devices = root.networkDevices || [];
        for (let index = 0; index < devices.length; ++index) {
            if (devices[index] && devices[index].type === type)
                return devices[index];
        }
        return null;
    }

    function findConnectedWifi(): var {
        const networks = root.wifiNetworkObjects || [];
        for (let index = 0; index < networks.length; ++index) {
            if (networks[index] && networks[index].connected)
                return networks[index];
        }
        return null;
    }

    function refreshNetworks(): void {
        const networks = (root.wifiNetworkObjects || []).filter(network => network && network.name !== "");
        root.networkList = networks.slice().sort((left, right) => {
            if (left.connected !== right.connected)
                return left.connected ? -1 : 1;
            return right.signalStrength - left.signalStrength;
        });
    }

    function syncScanner(): void {
        if (scannerDevice && scannerDevice !== wifiDevice)
            scannerDevice.scannerEnabled = false;
        scannerDevice = wifiDevice;
        if (scannerDevice)
            scannerDevice.scannerEnabled = true;
    }

    function wifiIcon(strength: real): string {
        if (strength >= 0.75)
            return "󰤨";
        if (strength >= 0.5)
            return "󰤥";
        if (strength >= 0.25)
            return "󰤢";
        return "󰤟";
    }

    function securityIcon(network): string {
        return network && network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe ? "󰌾" : "";
    }

    function requiresPassword(network): bool {
        if (!network || network.known)
            return false;
        return network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Sae
            || network.security === WifiSecurityType.StaticWep
            || network.security === WifiSecurityType.DynamicWep;
    }

    function requiresExternalManager(network): bool {
        return network && !network.known
            && (network.security === WifiSecurityType.Wpa2Eap
                || network.security === WifiSecurityType.WpaEap
                || network.security === WifiSecurityType.Leap
                || network.security === WifiSecurityType.Wpa3SuiteB192);
    }

    function activateNetwork(network): void {
        if (!network || network.stateChanging)
            return;

        errorMessage = "";
        if (network.connected) {
            network.disconnect();
            passwordSsid = "";
        } else if (requiresExternalManager(network)) {
            root.openFullApp();
        } else if (requiresPassword(network)) {
            passwordText = "";
            passwordVisible = false;
            passwordSsid = network.name;
        } else {
            network.connect();
            actionRefresh.restart();
        }
    }

    function connectWithPassword(network): void {
        if (!network || passwordText.length === 0)
            return;
        network.connectWithPsk(passwordText);
        passwordSsid = "";
        passwordText = "";
        passwordVisible = false;
        actionRefresh.restart();
    }

    function connectionIcon(): string {
        if (connectionKind === "ethernet")
            return "󰈀";
        if (connectionKind === "wifi")
            return wifiIcon(connectedWifi ? connectedWifi.signalStrength : 0);
        return "󰖪";
    }

    function connectivityLabel(): string {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "internet available";
        case NetworkConnectivity.Portal:
            return "sign-in required";
        case NetworkConnectivity.Limited:
            return "limited connectivity";
        case NetworkConnectivity.None:
            return "no internet";
        default:
            return connected ? "connected" : "disconnected";
        }
    }

    function formatBytes(value: real): string {
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let amount = Math.max(0, value || 0);
        let unit = 0;
        while (amount >= 1024 && unit < units.length - 1) {
            amount /= 1024;
            unit += 1;
        }
        return `${amount.toFixed(unit === 0 ? 0 : 1)} ${units[unit]}`;
    }

    function refreshDetails(): void {
        if (!detailsProcess.running)
            detailsProcess.exec([Quickshell.env("QS_NETWORK_DETAILS_COMMAND") || "quickshell-network-details"]);
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
    implicitWidth: 440
    implicitHeight: 650
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onWifiDeviceChanged: {
        syncScanner();
        networkRefresh.restart();
    }
    onWifiNetworkObjectsChanged: networkRefresh.restart()

    Component.onCompleted: {
        syncScanner();
        networkRefresh.restart();
        refreshDetails();
    }

    Component.onDestruction: {
        if (scannerDevice)
            scannerDevice.scannerEnabled = false;
    }

    Timer {
        id: networkRefresh
        interval: 75
        onTriggered: root.refreshNetworks()
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refreshNetworks()
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refreshDetails()
    }

    Timer {
        id: actionRefresh
        interval: 1400
        onTriggered: {
            root.refreshDetails();
            root.data.refresh();
            root.refreshNetworks();
        }
    }

    Timer {
        id: vpnRefresh
        interval: 1800
        onTriggered: root.data.refresh()
    }

    Process {
        id: detailsProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const output = text.trim();
                if (output === "")
                    return;
                try {
                    root.details = JSON.parse(output);
                } catch (error) {
                    console.warn(`Unable to parse quickshell-network-details output: ${error}`);
                }
            }
        }
    }

    Process {
        id: vpnToggle
        command: ["vpn-control", "toggle"]
        onRunningChanged: {
            if (!running)
                vpnRefresh.restart();
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
                text: "[ network ]"
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

        Flickable {
            id: scroll
            anchors {
                top: header.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 12
                topMargin: 6
            }
            clip: true
            contentWidth: width
            contentHeight: body.implicitHeight + 8
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: body
                width: scroll.width - 10
                spacing: 10

                Row {
                    width: parent.width
                    height: 58
                    spacing: 12

                    Text {
                        width: 26
                        height: parent.height
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        text: root.connectionIcon()
                        color: root.connected ? root.shell.focusedColor : root.shell.urgentColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 25
                    }

                    Column {
                        width: parent.width - 38
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.connectionName
                            color: root.shell.textColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: `${root.connectivityLabel()}${root.currentSignal >= 0 ? ` · ${root.currentSignal}% signal` : ""}`
                            color: root.shell.structureColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 5

                    Repeater {
                        model: [
                            { label: "interface", value: root.details.device || "—" },
                            { label: "address", value: root.details.ip || "—" },
                            { label: "gateway", value: root.details.gateway || "—" },
                            { label: "speed", value: root.details.speed || "—" },
                            { label: "frequency", value: root.details.frequency || "—" },
                            { label: "MTU", value: root.details.mtu || "—" },
                            { label: "received", value: root.formatBytes(root.details.rxBytes) },
                            { label: "sent", value: root.formatBytes(root.details.txBytes) }
                        ]

                        Row {
                            required property var modelData
                            width: (parent.width - 8) / 2
                            height: 20

                            Text {
                                width: 66
                                text: `${modelData.label}:`
                                color: root.shell.structureColor
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 10
                            }

                            Text {
                                width: parent.width - 66
                                elide: Text.ElideRight
                                text: modelData.value
                                color: root.shell.textColor
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 3

                    Text {
                        text: `DNS: ${root.details.dns || "—"}`
                        color: root.shell.structureColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 10
                    }

                    Text {
                        text: `MAC: ${root.details.mac || "—"}`
                        color: root.shell.structureColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.shell.borderColor
                }

                Rectangle {
                    visible: root.shell.showVpn
                    width: parent.width
                    height: visible ? 54 : 0
                    color: vpnPointer.containsMouse && !root.vpnUnavailableAtHome ? root.shell.secondBackground : "transparent"
                    border.width: 1
                    border.color: root.shell.borderColor
                    opacity: root.vpnUnavailableAtHome ? 0.65 : 1

                    Text {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                        }
                        text: root.data.vpnText || "󰦝"
                        color: root.data.vpnClass === "connected" ? root.shell.focusedColor : (root.data.vpnClass === "error" ? root.shell.urgentColor : root.shell.structureColor)
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 18
                    }

                    Column {
                        anchors {
                            left: parent.left
                            leftMargin: 44
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 2

                        Text {
                            text: "WireGuard"
                            color: root.shell.textColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: root.vpnUnavailableAtHome
                                ? "not needed on the home network"
                                : (root.data.vpnClass === "connected" ? "connected" : (root.data.vpnClass === "error" ? "active but unhealthy" : "off"))
                            color: root.shell.structureColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: vpnToggle.running
                            ? "working…"
                            : (root.vpnUnavailableAtHome ? "unavailable" : (root.data.vpnClass === "connected" ? "disable" : "enable"))
                        color: root.vpnUnavailableAtHome ? root.shell.structureColor : root.shell.focusedColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: vpnPointer
                        anchors.fill: parent
                        enabled: !vpnToggle.running && !root.vpnUnavailableAtHome
                        hoverEnabled: true
                        onClicked: vpnToggle.running = true
                    }
                }

                Row {
                    width: parent.width
                    height: 30

                    Text {
                        width: parent.width - wifiToggle.width
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: `wi-fi (${root.networkList.length})`
                        color: root.shell.structureColor
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Rectangle {
                        id: wifiToggle
                        width: 64
                        height: 26
                        color: wifiTogglePointer.containsMouse
                            ? root.shell.hoverColor
                            : (Networking.wifiEnabled ? root.shell.focusedColor : root.shell.secondBackground)
                        border.width: 1
                        border.color: wifiTogglePointer.containsMouse
                            ? root.shell.hoverColor
                            : (Networking.wifiEnabled ? root.shell.focusedColor : root.shell.borderColor)
                        opacity: Networking.wifiHardwareEnabled ? 1 : 0.4

                        Text {
                            anchors.centerIn: parent
                            text: Networking.wifiEnabled ? "disable" : "enable"
                            color: wifiTogglePointer.containsMouse || Networking.wifiEnabled ? root.shell.background : root.shell.textColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: wifiTogglePointer
                            anchors.fill: parent
                            enabled: Networking.wifiHardwareEnabled
                            hoverEnabled: true
                            onClicked: {
                                Networking.wifiEnabled = !Networking.wifiEnabled;
                                actionRefresh.restart();
                            }
                        }
                    }
                }

                Text {
                    visible: root.errorMessage !== ""
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    wrapMode: Text.Wrap
                    text: root.errorMessage
                    color: root.shell.urgentColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 10
                }

                Text {
                    visible: !Networking.wifiEnabled || !root.wifiDevice
                    width: parent.width
                    height: visible ? 34 : 0
                    verticalAlignment: Text.AlignVCenter
                    text: root.wifiDevice ? "wi-fi is disabled" : "no wi-fi adapter available"
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 11
                }

                Column {
                    visible: Networking.wifiEnabled && root.wifiDevice
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    spacing: 3

                    Repeater {
                        model: root.networkList

                        Item {
                            id: networkItem
                            required property var modelData
                            readonly property bool prompting: root.passwordSsid === modelData.name

                            width: body.width
                            height: 38 + (prompting ? 50 : 0)

                            Rectangle {
                                id: networkRow
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: 38
                                color: networkItem.modelData.connected
                                    ? Qt.rgba(root.shell.focusedColor.r, root.shell.focusedColor.g, root.shell.focusedColor.b, 0.16)
                                    : "transparent"

                                Rectangle {
                                    visible: networkItem.modelData.connected
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                    }
                                    height: 1
                                    color: root.shell.focusedColor
                                }

                                Text {
                                    id: signalIcon
                                    anchors {
                                        left: parent.left
                                        leftMargin: 8
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: 26
                                    horizontalAlignment: Text.AlignLeft
                                    text: root.wifiIcon(networkItem.modelData.signalStrength)
                                    color: networkItem.modelData.connected ? root.shell.focusedColor : root.shell.structureColor
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                }

                                Text {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 42
                                        right: networkActionButton.left
                                        rightMargin: 8
                                        verticalCenter: parent.verticalCenter
                                    }
                                    elide: Text.ElideRight
                                    text: `${networkItem.modelData.name} ${root.securityIcon(networkItem.modelData)}`
                                    color: networkItem.modelData.connected ? root.shell.focusedColor : root.shell.textColor
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: networkItem.modelData.connected
                                }

                                Rectangle {
                                    id: networkActionButton
                                    anchors {
                                        right: parent.right
                                        rightMargin: 4
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: 76
                                    height: 28
                                    color: networkActionPointer.containsMouse ? root.shell.secondBackground : "transparent"
                                    border.width: 1
                                    border.color: networkItem.modelData.connected ? root.shell.focusedColor : root.shell.borderColor
                                    opacity: networkItem.modelData.stateChanging ? 0.55 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: networkItem.modelData.stateChanging
                                            ? "working…"
                                            : (networkItem.modelData.connected ? "disconnect" : "connect")
                                        color: root.shell.focusedColor
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        id: networkActionPointer
                                        anchors.fill: parent
                                        enabled: !networkItem.modelData.stateChanging
                                        hoverEnabled: true
                                        onClicked: root.activateNetwork(networkItem.modelData)
                                    }
                                }
                            }

                            Row {
                                visible: networkItem.prompting
                                anchors {
                                    top: networkRow.bottom
                                    left: parent.left
                                    right: parent.right
                                    topMargin: 6
                                }
                                height: visible ? 38 : 0
                                spacing: 6

                                TextField {
                                    id: passwordField
                                    width: parent.width - viewButton.width - connectButton.width - 12
                                    height: parent.height
                                    placeholderText: "network password"
                                    echoMode: root.passwordVisible ? TextInput.Normal : TextInput.Password
                                    color: root.shell.textColor
                                    placeholderTextColor: root.shell.structureColor
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 11
                                    leftPadding: 10
                                    rightPadding: 10
                                    text: root.passwordText
                                    onTextEdited: root.passwordText = text
                                    onVisibleChanged: {
                                        if (visible)
                                            Qt.callLater(() => forceActiveFocus());
                                    }
                                    Keys.onReturnPressed: root.connectWithPassword(networkItem.modelData)
                                    Keys.onEscapePressed: {
                                        root.passwordSsid = "";
                                        root.passwordText = "";
                                        root.passwordVisible = false;
                                    }

                                    background: Rectangle {
                                        color: root.shell.secondBackground
                                        border.width: 1
                                        border.color: passwordField.activeFocus ? root.shell.focusedColor : root.shell.borderColor
                                    }
                                }

                                Rectangle {
                                    id: viewButton
                                    width: 46
                                    height: parent.height
                                    color: viewPointer.containsMouse ? root.shell.secondBackground : "transparent"
                                    border.width: 1
                                    border.color: root.shell.borderColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.passwordVisible ? "hide" : "view"
                                        color: root.shell.textColor
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        id: viewPointer
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.passwordVisible = !root.passwordVisible;
                                            passwordField.forceActiveFocus();
                                        }
                                    }
                                }

                                Rectangle {
                                    id: connectButton
                                    width: 64
                                    height: parent.height
                                    color: connectPointer.containsMouse ? root.shell.hoverColor : root.shell.focusedColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "connect"
                                        color: root.shell.background
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        id: connectPointer
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.connectWithPassword(networkItem.modelData)
                                    }
                                }
                            }

                            Connections {
                                target: networkItem.modelData

                                function onConnectionFailed(reason): void {
                                    root.errorMessage = `${networkItem.modelData.name}: ${ConnectionFailReason.toString(reason)}`;
                                    if (reason === ConnectionFailReason.NoSecrets) {
                                        root.passwordText = "";
                                        root.passwordSsid = networkItem.modelData.name;
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
