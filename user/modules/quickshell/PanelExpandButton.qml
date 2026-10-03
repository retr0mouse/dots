import QtQuick

Rectangle {
    id: root

    required property var shell

    signal clicked()

    implicitWidth: 30
    implicitHeight: 28
    color: pointer.containsMouse ? shell.secondBackground : "transparent"

    Text {
        anchors.centerIn: parent
        text: "󰁌"
        color: pointer.containsMouse ? root.shell.focusedColor : root.shell.structureColor
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 15
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
