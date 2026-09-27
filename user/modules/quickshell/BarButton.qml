import QtQuick

Rectangle {
    id: root

    required property var shell
    property string label: ""
    property color normalColor: shell.textColor
    property color hoverColor: shell.hoverColor
    property color activeBackground: "transparent"
    property int horizontalPadding: 3
    property string tooltip: ""

    signal clicked(int button)
    signal wheel(int direction)

    implicitWidth: labelItem.implicitWidth + horizontalPadding * 2
    implicitHeight: 28
    color: activeBackground

    Text {
        id: labelItem
        anchors.centerIn: parent
        text: root.label
        color: pointer.containsMouse ? root.hoverColor : root.normalColor
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 15
        font.bold: false
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse.button)
        onWheel: wheel => root.wheel(wheel.angleDelta.y > 0 ? 1 : -1)
    }

}
