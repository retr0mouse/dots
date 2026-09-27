import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property real anchorX
    required property real anchorBottom
    required property var shell
    property string icon: ""
    property string title: ""
    property real controlValue: 0
    property real maximumValue: 1
    property bool muted: false

    signal valueRequested(real value)
    signal toggleRequested()

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
    implicitWidth: 320
    implicitHeight: 58
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        parent: root.contentItem
        anchors.fill: parent
        color: root.shell.background
        border.width: 1
        border.color: root.shell.borderColor

        Text {
            id: iconText
            anchors.left: parent.left
            anchors.leftMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            text: root.icon
            color: root.muted ? root.shell.structureColor : root.shell.textColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 17

            MouseArea {
                anchors.fill: parent
                onClicked: root.toggleRequested()
            }
        }

        Slider {
            id: control
            anchors.left: iconText.right
            anchors.right: valueText.left
            anchors.leftMargin: 8
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            from: 0
            to: root.maximumValue
            value: root.controlValue
            onMoved: root.valueRequested(value)

            background: Rectangle {
                x: control.leftPadding
                y: control.topPadding + control.availableHeight / 2 - height / 2
                width: control.availableWidth
                height: 4
                color: root.shell.secondBackground

                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height
                    color: root.shell.focusedColor
                }
            }

            handle: Rectangle {
                x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
                width: 12
                height: 12
                color: control.pressed ? root.shell.hoverColor : root.shell.textColor
                border.width: 1
                border.color: root.shell.focusedColor
            }
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(root.controlValue * 100)}%`
            color: root.shell.textColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 14
            font.bold: true
        }
    }
}
