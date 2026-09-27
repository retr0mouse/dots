import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property real anchorX
    required property real anchorBottom
    required property var shell

    property date today: new Date()
    property int displayYear: today.getFullYear()
    property int displayMonth: today.getMonth()

    signal closeRequested()

    function moveMonth(offset: int): void {
        const next = new Date(displayYear, displayMonth + offset, 1);
        displayYear = next.getFullYear();
        displayMonth = next.getMonth();
    }

    function resetToToday(): void {
        today = new Date();
        displayYear = today.getFullYear();
        displayMonth = today.getMonth();
    }

    function firstCellDate(): date {
        const first = new Date(displayYear, displayMonth, 1);
        const mondayOffset = (first.getDay() + 6) % 7;
        return new Date(displayYear, displayMonth, 1 - mondayOffset);
    }

    function cellDate(index: int): date {
        const first = firstCellDate();
        return new Date(first.getFullYear(), first.getMonth(), first.getDate() + index);
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
    implicitWidth: 360
    implicitHeight: 350
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        parent: root.contentItem
        anchors.fill: parent
        color: root.shell.background
        border.width: 1
        border.color: root.shell.borderColor

        Row {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            height: 28

            Text {
                width: parent.width - previousButton.width - nextButton.width - closeButton.width
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: `[ ${Qt.formatDate(new Date(root.displayYear, root.displayMonth, 1), "MMMM yyyy").toLowerCase()} ]`
                color: root.shell.focusedColor
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.resetToToday()
                }
            }

            Rectangle {
                id: previousButton
                width: 30
                height: parent.height
                color: previousPointer.containsMouse ? root.shell.secondBackground : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.shell.textColor
                    font.pixelSize: 20
                }

                MouseArea {
                    id: previousPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.moveMonth(-1)
                }
            }

            Rectangle {
                id: nextButton
                width: 30
                height: parent.height
                color: nextPointer.containsMouse ? root.shell.secondBackground : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: root.shell.textColor
                    font.pixelSize: 20
                }

                MouseArea {
                    id: nextPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.moveMonth(1)
                }
            }

            Rectangle {
                id: closeButton
                width: 30
                height: parent.height
                color: closePointer.containsMouse ? root.shell.secondBackground : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: root.shell.structureColor
                    font.pixelSize: 18
                }

                MouseArea {
                    id: closePointer
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.closeRequested()
                }
            }
        }

        Grid {
            id: weekdayGrid
            anchors {
                top: header.bottom
                topMargin: 8
                left: parent.left
                right: parent.right
                leftMargin: 12
                rightMargin: 12
            }
            columns: 7

            Repeater {
                model: ["mo", "tu", "we", "th", "fr", "sa", "su"]

                Text {
                    required property string modelData
                    width: weekdayGrid.width / 7
                    height: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: root.shell.structureColor
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        Grid {
            id: dayGrid
            anchors {
                top: weekdayGrid.bottom
                topMargin: 2
                left: weekdayGrid.left
                right: weekdayGrid.right
            }
            columns: 7

            Repeater {
                model: 42

                Rectangle {
                    id: dayCell
                    required property int index
                    readonly property date representedDate: root.cellDate(index)
                    readonly property bool inCurrentMonth: representedDate.getMonth() === root.displayMonth
                    readonly property bool isToday: representedDate.getFullYear() === root.today.getFullYear()
                        && representedDate.getMonth() === root.today.getMonth()
                        && representedDate.getDate() === root.today.getDate()

                    width: dayGrid.width / 7
                    height: 42
                    color: isToday ? root.shell.focusedColor : (dayPointer.containsMouse ? root.shell.secondBackground : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.representedDate.getDate()
                        color: dayCell.isToday ? root.shell.background : (dayCell.inCurrentMonth ? root.shell.textColor : root.shell.structureColor)
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 14
                        font.bold: dayCell.isToday
                    }

                    MouseArea {
                        id: dayPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.displayYear = dayCell.representedDate.getFullYear();
                            root.displayMonth = dayCell.representedDate.getMonth();
                        }
                    }
                }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 9
            }
            text: Qt.formatDate(root.today, "dddd, d MMMM yyyy").toLowerCase()
            color: root.shell.structureColor
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 12
        }
    }
}
