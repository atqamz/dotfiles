import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    property bool showDone: false
    property bool showAddDialog: false

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    readonly property var filteredList: {
        var result = [];
        for (var i = 0; i < Todo.list.length; i++) {
            if (Todo.list[i].done === root.showDone)
                result.push({ index: i, content: Todo.list[i].content, done: Todo.list[i].done });
        }
        return result;
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Tab bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Theme.radius.normal
                color: !root.showDone ? Theme.surfaceContainerHigh : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: "Todo"
                    font.bold: !root.showDone
                    color: !root.showDone ? Theme.text : Theme.textMuted
                }

                StateLayer {
                    focused: !root.showDone
                    pressed: todoTabTap.pressed
                }

                MouseArea {
                    id: todoTabTap
                    anchors.fill: parent
                    onClicked: root.showDone = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Theme.radius.normal
                color: root.showDone ? Theme.surfaceContainerHigh : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: "Done"
                    font.bold: root.showDone
                    color: root.showDone ? Theme.text : Theme.textMuted
                }

                StateLayer {
                    focused: root.showDone
                    pressed: doneTabTap.pressed
                }

                MouseArea {
                    id: doneTabTap
                    anchors.fill: parent
                    onClicked: root.showDone = true
                }
            }
        }

        // Task list
        Repeater {
            model: root.filteredList

            StyledRect {
                required property var modelData
                Layout.fillWidth: true
                color: Theme.surfaceContainerHigh
                radius: Theme.radius.normal
                implicitHeight: taskRow.implicitHeight + 16

                RowLayout {
                    id: taskRow
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.content
                        wrapMode: Text.Wrap
                        color: modelData.done ? Theme.textMuted : Theme.text
                        font.strikeout: modelData.done
                    }

                    IconButton {
                        radius: Theme.radius.full
                        padding: Theme.padding.small
                        icon: modelData.done ? "undo" : "check"
                        onClicked: Todo.markDone(modelData.index)
                    }

                    IconButton {
                        radius: Theme.radius.full
                        padding: Theme.padding.small
                        icon: "delete"
                        iconColor: Theme.error
                        tint: Theme.error
                        onClicked: Todo.deleteItem(modelData.index)
                    }
                }
            }
        }

        // Empty state
        StyledText {
            visible: root.filteredList.length === 0
            Layout.alignment: Qt.AlignHCenter
            text: root.showDone ? "No completed tasks" : "No tasks yet"
            color: Theme.textMuted
        }

        // Add button
        Rectangle {
            visible: !root.showDone && !root.showAddDialog
            Layout.fillWidth: true
            height: 40
            radius: Theme.radius.normal
            color: Theme.surfaceContainerLow

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                MaterialIcon {
                    text: "add"
                    color: Theme.textVariant
                }

                StyledText {
                    text: "Add task"
                    color: Theme.textVariant
                }
            }

            StateLayer { pressed: addBtnTap.pressed }

            MouseArea {
                id: addBtnTap
                anchors.fill: parent
                onClicked: {
                    root.showAddDialog = true;
                    addInput.forceActiveFocus();
                }
            }
        }

        // Add dialog
        RowLayout {
            visible: root.showAddDialog
            Layout.fillWidth: true
            spacing: 4

            TextField {
                id: addInput
                Layout.fillWidth: true
                placeholderText: "New task..."
                color: Theme.text
                renderType: Text.NativeRendering
                font.family: Theme.font.family.sans
                font.pixelSize: Theme.font.size.normal

                background: Rectangle {
                    radius: Theme.radius.small
                    color: Theme.surfaceContainerHighest
                    border.color: addInput.activeFocus ? Theme.primary : Theme.outline
                    border.width: 1

                    Behavior on border.color { CAnim {} }
                }

                Keys.onReturnPressed: {
                    if (addInput.text.length > 0) {
                        Todo.addTask(addInput.text);
                        addInput.text = "";
                    }
                }

                Keys.onEscapePressed: {
                    root.showAddDialog = false;
                    addInput.text = "";
                }
            }

            Rectangle {
                width: 36; height: 36; radius: Theme.radius.full
                color: addInput.text.length > 0 ? Theme.primary : Theme.surfaceContainerHigh

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "add"
                    color: addInput.text.length > 0 ? Theme.textOnPrimary : Theme.textMuted
                }

                StateLayer {
                    pressed: addSubmitTap.pressed
                    tint: addInput.text.length > 0 ? Theme.textOnPrimary : Theme.text
                }

                MouseArea {
                    id: addSubmitTap
                    anchors.fill: parent
                    onClicked: {
                        if (addInput.text.length > 0) {
                            Todo.addTask(addInput.text);
                            addInput.text = "";
                        }
                    }
                }
            }
        }
    }
}
