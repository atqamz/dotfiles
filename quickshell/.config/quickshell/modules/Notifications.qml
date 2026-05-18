// quickshell/.config/quickshell/modules/Notifications.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Scope {
    id: root

    readonly property int maxVisible: 5

    readonly property var visibleNotifications: {
        const all = NotificationHistory.server.trackedNotifications.values;
        if (all.length <= root.maxVisible) return all;
        return all.slice(0, root.maxVisible);
    }

    readonly property int overflowCount: Math.max(0, NotificationHistory.server.trackedNotifications.values.length - root.maxVisible)

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: NotificationHistory.server.trackedNotifications.values.length > 0

            anchors {
                top: true
                right: true
            }

            margins {
                top: Theme.padding.larger
                right: Theme.padding.larger
            }

            implicitWidth: 380
            implicitHeight: stack.implicitHeight
            color: "transparent"

            ColumnLayout {
                id: stack
                width: parent.width
                spacing: Theme.spacing.normal

                StyledRect {
                    Layout.fillWidth: true
                    visible: root.overflowCount > 0
                    implicitHeight: overflowLabel.implicitHeight + Theme.padding.normal * 2
                    color: Theme.background
                    border.color: Theme.outlineVariant
                    border.width: 1
                    radius: Theme.radius.full

                    StyledText {
                        id: overflowLabel
                        anchors.centerIn: parent
                        text: "+" + root.overflowCount + " more"
                        color: Theme.textVariant
                        font.pixelSize: Theme.font.size.small
                    }
                }

                Repeater {
                    model: root.visibleNotifications

                    StyledRect {
                        id: card
                        required property var modelData
                        property bool hovered: hoverHandler.hovered
                        property bool dismissed: false

                        Layout.fillWidth: true
                        implicitHeight: content.implicitHeight + Theme.padding.large * 2
                        color: Theme.background
                        border.color: Theme.outlineVariant
                        border.width: 1
                        radius: Theme.radius.large
                        opacity: dismissed ? 0 : 1
                        x: dismissed ? width + 20 : 0

                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InCubic } }

                        Component.onCompleted: slideInAnim.start()

                        NumberAnimation {
                            id: slideInAnim
                            target: card
                            property: "x"
                            from: card.width + 20
                            to: 0
                            duration: 200
                            easing.type: Easing.OutCubic
                        }

                        HoverHandler { id: hoverHandler }

                        ColumnLayout {
                            id: content
                            anchors.fill: parent
                            anchors.margins: Theme.padding.large
                            spacing: Theme.spacing.normal

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.large

                                StyledRect {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: Theme.radius.full
                                    color: Theme.surfaceContainer
                                    border.color: Theme.outlineVariant
                                    border.width: 1

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "notifications"
                                        color: Theme.tertiary
                                        font.pixelSize: 16
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacing.smaller

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: card.modelData.summary
                                        color: Theme.text
                                        font.pixelSize: Theme.font.size.normal
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: card.modelData.body.length > 0
                                        text: card.modelData.body
                                        color: Theme.textVariant
                                        font.pixelSize: Theme.font.size.small
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 4
                                        textFormat: Text.MarkdownText
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: card.modelData.actions.values.length > 0
                                spacing: Theme.spacing.small

                                Repeater {
                                    model: card.modelData.actions.values

                                    StyledRect {
                                        id: actionBtn
                                        required property var modelData
                                        property bool hovered: actionHover.hovered

                                        Layout.preferredHeight: 24
                                        implicitWidth: actionLabel.implicitWidth + Theme.padding.normal * 2
                                        color: actionBtn.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                                        border.color: Theme.outlineVariant
                                        border.width: 1
                                        radius: Theme.radius.full

                                        HoverHandler { id: actionHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                actionBtn.modelData.invoke();
                                                card.dismissed = true;
                                            }
                                        }

                                        StyledText {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            text: actionBtn.modelData.text
                                            color: Theme.text
                                            font.pixelSize: Theme.font.size.small
                                        }
                                    }
                                }
                            }
                        }

                        Timer {
                            interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
                            running: !card.hovered && !card.dismissed
                            onTriggered: card.dismissed = true
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.MiddleButton
                            onClicked: card.dismissed = true
                        }

                        onDismissedChanged: if (dismissed) dismissTimer.restart()
                        Timer {
                            id: dismissTimer
                            interval: 220
                            onTriggered: card.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
