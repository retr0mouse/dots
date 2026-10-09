import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    readonly property color paletteBackground: "#101211"
    readonly property color paletteSecondBackground: "#1a1d1b"
    readonly property color paletteText: "#c5c8c5"
    readonly property color paletteBorder: "#303630"
    readonly property color paletteStructure: "#768076"
    readonly property color paletteFocused: "#98a87c"
    readonly property color paletteHover: "#7f9f9f"
    readonly property color paletteUrgent: "#d08770"
    readonly property int dialogWidth: 520
    readonly property int dialogHeight: 270

    width: dialogWidth
    height: dialogHeight
    minimumWidth: dialogWidth
    minimumHeight: dialogHeight
    maximumWidth: dialogWidth
    maximumHeight: dialogHeight
    visible: true
    color: paletteBackground
    title: "[ authentication ]"

    font.family: "Iosevka Nerd Font"
    font.pointSize: 11

    onClosing: hpa.setResult("fail")

    Shortcut {
        sequence: "Escape"
        onActivated: hpa.setResult("fail")
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        onActivated: authenticate()
    }

    function authenticate() {
        if (!passwordField.readOnly)
            hpa.setResult("auth:" + passwordField.text)
    }

    Rectangle {
        anchors.fill: parent
        color: paletteBackground
        border.color: paletteBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12

            Label {
                text: "[ authentication ]"
                color: paletteText
                font.bold: true
                font.pointSize: 15
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "authorizing " + hpa.getUser()
                color: paletteHover
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                elide: Text.ElideRight
            }

            Rectangle {
                color: paletteBorder
                implicitHeight: 1
                Layout.fillWidth: true
            }

            Label {
                text: hpa.getMessage()
                color: paletteText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 34
            }

            TextField {
                id: passwordField

                color: paletteText
                selectionColor: paletteFocused
                selectedTextColor: paletteBackground
                placeholderText: "[ password ]"
                placeholderTextColor: paletteStructure
                echoMode: TextInput.Password
                persistentSelection: true
                selectByMouse: true
                focus: true
                leftPadding: 12
                rightPadding: 12
                topPadding: 8
                bottomPadding: 8
                Layout.fillWidth: true

                background: Rectangle {
                    color: paletteSecondBackground
                    border.color: passwordField.activeFocus ? paletteFocused : paletteBorder
                    border.width: 1
                    radius: 0
                }

                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: hpa

                    function onFocusField() {
                        passwordField.forceActiveFocus()
                    }

                    function onBlockInput(block) {
                        passwordField.readOnly = block
                        if (!block) {
                            passwordField.forceActiveFocus()
                            passwordField.selectAll()
                        }
                    }
                }
            }

            Label {
                id: errorLabel

                text: ""
                color: paletteUrgent
                font.italic: true
                visible: text.length > 0
                Layout.alignment: Qt.AlignHCenter

                Connections {
                    target: hpa
                    function onSetErrorString(error) {
                        errorLabel.text = "[ " + error.toLowerCase() + " ]"
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                ThemedButton {
                    label: "[ cancel ]"
                    accent: paletteUrgent
                    onClicked: hpa.setResult("fail")
                }

                ThemedButton {
                    label: "[ authenticate ]"
                    accent: paletteFocused
                    onClicked: authenticate()
                }
            }
        }
    }

    component ThemedButton: Button {
        id: control

        required property string label
        required property color accent

        text: label
        hoverEnabled: true
        leftPadding: 14
        rightPadding: 14
        topPadding: 7
        bottomPadding: 7

        contentItem: Label {
            text: control.text
            color: control.hovered || control.activeFocus ? paletteBackground : paletteText
            font: control.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: control.hovered || control.activeFocus ? control.accent : paletteSecondBackground
            border.color: control.hovered || control.activeFocus ? control.accent : paletteBorder
            border.width: 1
            radius: 0
        }
    }
}
