import QtQuick
import QtQuick.Layouts
import qs.components

import "calendar_layout.js" as CalendarLayout

Item {
    id: root

    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarGrid: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                font.pixelSize: Theme.font.size.large
                font.bold: true
                color: root.monthShift !== 0 ? Theme.tertiary : Theme.text

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.monthShift = 0
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 28; height: 28; radius: Theme.radius.full
                color: "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: "<"
                    color: Theme.text
                }

                StateLayer { pressed: prevTap.pressed }

                MouseArea {
                    id: prevTap
                    anchors.fill: parent
                    onClicked: root.monthShift--
                }
            }

            Rectangle {
                width: 28; height: 28; radius: Theme.radius.full
                color: "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: ">"
                    color: Theme.text
                }

                StateLayer { pressed: nextTap.pressed }

                MouseArea {
                    id: nextTap
                    anchors.fill: parent
                    onClicked: root.monthShift++
                }
            }
        }

        // Week day headers
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: CalendarLayout.weekDays

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 28

                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.pixelSize: Theme.font.size.smaller
                        font.bold: true
                        color: Theme.textMuted
                    }
                }
            }
        }

        // 6 weeks of days
        Repeater {
            model: 6

            RowLayout {
                required property int index
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: 7

                    Item {
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 32

                        readonly property var cell: root.calendarGrid[parent.index][index]
                        readonly property bool isToday: cell.today === 1
                        readonly property bool isOtherMonth: cell.today === -1

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28; height: 28; radius: Theme.radius.full
                            color: isToday ? Theme.primary : "transparent"
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: cell.day.toString()
                            font.pixelSize: Theme.font.size.small
                            color: isToday ? Theme.textOnPrimary
                                   : isOtherMonth ? Theme.textDim
                                   : Theme.text
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            root.monthShift += wheel.angleDelta.y < 0 ? 1 : -1;
        }
    }
}
