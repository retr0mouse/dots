import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var shell
    property var audioNode: null
    property string icon: ""
    property string title: "audio"
    property real maximumValue: 1.5

    readonly property bool available: audioNode && audioNode.audio
    readonly property real volume: available ? audioNode.audio.volume : 0
    readonly property bool muted: available ? audioNode.audio.muted : false

    implicitHeight: title === "" ? 34 : 54

    Text {
        id: titleText
        visible: root.title !== ""
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: visible ? 20 : 0
        elide: Text.ElideRight
        text: root.title
        color: root.shell.textColor
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 12
    }

    Text {
        id: muteButton
        anchors {
            left: parent.left
            verticalCenter: slider.verticalCenter
        }
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.muted ? "󰝟" : root.icon
        color: root.muted ? root.shell.structureColor : root.shell.textColor
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 15

        MouseArea {
            anchors.fill: parent
            enabled: root.available
            onClicked: root.audioNode.audio.muted = !root.audioNode.audio.muted
        }
    }

    Slider {
        id: slider
        anchors {
            left: muteButton.right
            right: valueText.left
            bottom: parent.bottom
            leftMargin: 8
            rightMargin: 8
        }
        height: 30
        enabled: root.available
        from: 0
        to: root.maximumValue
        value: root.volume
        onMoved: {
            if (root.available)
                root.audioNode.audio.volume = value;
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            color: root.shell.secondBackground

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: root.muted ? root.shell.structureColor : root.shell.focusedColor
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 11
            height: 11
            color: slider.pressed ? root.shell.hoverColor : root.shell.textColor
            border.width: 1
            border.color: root.shell.focusedColor
        }
    }

    Text {
        id: valueText
        anchors {
            right: parent.right
            verticalCenter: slider.verticalCenter
        }
        width: 40
        horizontalAlignment: Text.AlignRight
        text: `${Math.round(root.volume * 100)}%`
        color: root.shell.structureColor
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 12
    }
}
