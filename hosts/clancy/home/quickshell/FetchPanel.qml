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
    required property var data

    signal closeRequested()

    property real reveal: 0
    property var fetch: ({
        user: "user",
        host: "nixos",
        os: "NixOS",
        kernel: "loading…",
        uptime: "loading…",
        packages: "loading…",
        shell: "zsh",
        compositor: "Hyprland",
        cpu: "loading…",
        gpu: "loading…"
    })

    readonly property var rows: [
        ["os", fetch.os],
        ["host", `${fetch.user}@${fetch.host}`],
        ["kernel", fetch.kernel],
        ["uptime", fetch.uptime],
        ["packages", fetch.packages],
        ["shell", fetch.shell],
        ["wm", fetch.compositor],
        ["cpu", fetch.cpu],
        ["gpu", fetch.gpu],
        ["memory", `${data.memory}%`]
    ]

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
    implicitWidth: 470
    implicitHeight: 354
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    Component.onCompleted: {
        revealAnimation.restart();
        fetchProcess.exec([Quickshell.env("QS_FETCH_COMMAND") || "quickshell-fetch"]);
    }

    Rectangle {
        parent: root.contentItem
        anchors.fill: parent
        color: root.shell.background
        border.width: 1
        border.color: root.shell.borderColor

        Rectangle {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 44
            color: root.shell.secondBackground

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "[ nixos ]"
                color: root.shell.textColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 15
                font.bold: true
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                color: powerPointer.containsMouse ? root.shell.secondBackground : root.shell.background
                border.width: 1
                border.color: powerPointer.containsMouse ? root.shell.hoverColor : root.shell.borderColor

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    color: powerPointer.containsMouse ? root.shell.hoverColor : root.shell.textColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 15
                }

                MouseArea {
                    id: powerPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.shell.run(["session-menu"]);
                        root.closeRequested();
                    }
                }
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom

            Text {
                id: nixLogo
                anchors.left: parent.left
                anchors.leftMargin: 25
                anchors.verticalCenter: parent.verticalCenter
                width: 108
                horizontalAlignment: Text.AlignHCenter
                text: ""
                color: root.shell.focusedColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 72
                transformOrigin: Item.Center

                RotationAnimator on rotation {
                    running: root.visible
                    from: 0
                    to: 360
                    duration: 12000
                    loops: Animation.Infinite
                }
            }

            Column {
                anchors.left: nixLogo.right
                anchors.leftMargin: 18
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Repeater {
                    model: root.rows

                    Row {
                        id: fetchRow
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 22
                        opacity: Math.max(0, Math.min(1, (root.reveal - index * 0.07) * 3.2))
                        x: (1 - opacity) * 14

                        Text {
                            width: 78
                            text: `${fetchRow.modelData[0]}:`
                            color: root.shell.hoverColor
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Text {
                            width: fetchRow.width - 78
                            text: fetchRow.modelData[1]
                            color: root.shell.textColor
                            elide: Text.ElideRight
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }

    NumberAnimation {
        id: revealAnimation
        target: root
        property: "reveal"
        from: 0
        to: 1.7
        duration: 780
        easing.type: Easing.OutCubic
    }

    Process {
        id: fetchProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const output = text.trim();
                if (output.length === 0)
                    return;

                try {
                    root.fetch = JSON.parse(output);
                } catch (error) {
                    console.warn(`Unable to parse quickshell-fetch output: ${error}`);
                }
            }
        }
    }
}
