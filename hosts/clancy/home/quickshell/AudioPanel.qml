import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property real anchorX
    required property real anchorBottom
    required property var shell

    property var outputDevices: []
    property var inputDevices: []
    property var applicationStreams: []
    readonly property var allNodes: Pipewire.nodes.values
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    signal closeRequested()

    function openFullApp(): void {
        root.shell.run(["pwvucontrol"]);
        root.closeRequested();
    }

    function nodeClass(node): string {
        if (!node || !node.properties)
            return "";
        return node.properties["media.class"] || "";
    }

    function nodeLabel(node, application: bool): string {
        if (!node)
            return application ? "unknown application" : "unknown device";

        const properties = node.properties || {};
        if (application)
            return properties["application.name"] || properties["media.name"] || node.description || node.nickname || node.name;
        return node.description || node.nickname || properties["node.description"] || node.name;
    }

    function refreshNodes(): void {
        const nodes = root.allNodes || [];
        root.outputDevices = nodes.filter(node => node && node.isSink && !node.isStream && node.audio);
        root.inputDevices = nodes.filter(node => {
            const mediaClass = root.nodeClass(node);
            return node && !node.isStream && !node.isSink && node.audio && mediaClass.indexOf("Audio/Source") === 0;
        });
        root.applicationStreams = nodes.filter(node => {
            const mediaClass = root.nodeClass(node);
            return node && node.isStream && node.audio && (node.isSink || mediaClass === "Stream/Output/Audio");
        });
    }

    function selectOutput(node): void {
        if (node) {
            Pipewire.preferredDefaultAudioSink = node;
            root.shell.run([
                Quickshell.env("QS_AUDIO_DEVICE_COMMAND") || "quickshell-audio-device",
                "output",
                `${node.id}`,
                node.name
            ]);
        }
    }

    function selectInput(node): void {
        if (node) {
            Pipewire.preferredDefaultAudioSource = node;
            root.shell.run([
                Quickshell.env("QS_AUDIO_DEVICE_COMMAND") || "quickshell-audio-device",
                "input",
                `${node.id}`,
                node.name
            ]);
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
    implicitWidth: 430
    implicitHeight: 550
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    PwObjectTracker {
        objects: root.allNodes || []
    }

    Timer {
        id: nodeRefresh
        interval: 75
        onTriggered: root.refreshNodes()
    }

    onAllNodesChanged: nodeRefresh.restart()
    Component.onCompleted: nodeRefresh.restart()

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
                text: "[ audio ]"
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
            ScrollBar.vertical: ScrollBar {}

            Column {
                id: body
                width: scroll.width - 10
                spacing: 8

                Text {
                    width: parent.width
                    text: "output"
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }

                AudioVolumeRow {
                    width: parent.width
                    shell: root.shell
                    audioNode: root.defaultSink
                    icon: ""
                    title: ""
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.outputDevices

                        Rectangle {
                            id: outputRow
                            required property var modelData
                            width: body.width
                            height: 30
                            color: outputPointer.containsMouse ? root.shell.secondBackground : "transparent"

                            Text {
                                anchors {
                                    left: parent.left
                                    right: outputState.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8
                                }
                                elide: Text.ElideRight
                                text: root.nodeLabel(outputRow.modelData, false)
                                color: root.shell.textColor
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 12
                            }

                            Text {
                                id: outputState
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    rightMargin: 8
                                }
                                text: root.defaultSink && outputRow.modelData && root.defaultSink.id === outputRow.modelData.id ? "●" : "○"
                                color: text === "●" ? root.shell.focusedColor : root.shell.structureColor
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: outputPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.selectOutput(outputRow.modelData)
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
                    width: parent.width
                    text: "microphone"
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }

                AudioVolumeRow {
                    width: parent.width
                    shell: root.shell
                    audioNode: root.defaultSource
                    icon: ""
                    maximumValue: 1
                    title: ""
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.inputDevices

                        Rectangle {
                            id: inputRow
                            required property var modelData
                            width: body.width
                            height: 30
                            color: inputPointer.containsMouse ? root.shell.secondBackground : "transparent"

                            Text {
                                anchors {
                                    left: parent.left
                                    right: inputState.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8
                                }
                                elide: Text.ElideRight
                                text: root.nodeLabel(inputRow.modelData, false)
                                color: root.shell.textColor
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 12
                            }

                            Text {
                                id: inputState
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    rightMargin: 8
                                }
                                text: root.defaultSource && inputRow.modelData && root.defaultSource.id === inputRow.modelData.id ? "●" : "○"
                                color: text === "●" ? root.shell.focusedColor : root.shell.structureColor
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: inputPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.selectInput(inputRow.modelData)
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
                    width: parent.width
                    text: `applications (${root.applicationStreams.length})`
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    visible: root.applicationStreams.length === 0
                    width: parent.width
                    height: visible ? 32 : 0
                    verticalAlignment: Text.AlignVCenter
                    text: "no applications are playing audio"
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 12
                }

                Repeater {
                    model: root.applicationStreams

                    AudioVolumeRow {
                        required property var modelData
                        width: body.width
                        shell: root.shell
                        audioNode: modelData
                        icon: "󰎆"
                        title: root.nodeLabel(modelData, true)
                    }
                }
            }
        }
    }
}
