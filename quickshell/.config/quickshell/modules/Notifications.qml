import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.components

Scope {
    NotificationServer {
        id: server
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: false
        persistenceSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: server.trackedNotifications.values.length > 0

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

            Column {
                id: stack
                width: parent.width
                spacing: Theme.spacing.normal

                Repeater {
                    model: server.trackedNotifications.values

                    StyledRect {
                        required property var modelData
                        width: stack.width
                        implicitHeight: content.implicitHeight + Theme.padding.large * 2
                        color: Theme.background
                        border.color: Theme.outlineVariant
                        border.width: 1
                        radius: Theme.radius.large

                        Row {
                            id: content
                            anchors.fill: parent
                            anchors.margins: Theme.padding.large
                            spacing: Theme.spacing.large

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "notifications"
                                color: Theme.tertiary
                                font.pixelSize: 22
                                width: 28
                            }

                            Column {
                                width: parent.width - 28 - parent.spacing
                                spacing: Theme.spacing.smaller

                                StyledText {
                                    width: parent.width
                                    text: modelData.summary
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.normal
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }
                                StyledText {
                                    width: parent.width
                                    visible: modelData.body.length > 0
                                    text: modelData.body
                                    color: Theme.textVariant
                                    font.pixelSize: Theme.font.size.small
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 4
                                    textFormat: Text.MarkdownText
                                }
                            }
                        }

                        Timer {
                            interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
                            running: true
                            onTriggered: modelData.dismiss()
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
