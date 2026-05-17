import Quickshell
import Quickshell.Services.Notifications
import QtQuick

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
                top: 36
                right: 12
            }

            implicitWidth: 360
            implicitHeight: stack.implicitHeight
            color: "transparent"

            Column {
                id: stack
                width: parent.width
                spacing: 8

                Repeater {
                    model: server.trackedNotifications.values

                    Rectangle {
                        required property var modelData
                        width: stack.width
                        implicitHeight: content.implicitHeight + 16
                        color: "#1a1a1a"
                        border.color: "#3a3a3a"
                        border.width: 1
                        radius: 4

                        Column {
                            id: content
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Text {
                                width: parent.width
                                text: modelData.summary
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "JetBrains Mono"
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                            }
                            Text {
                                width: parent.width
                                visible: modelData.body.length > 0
                                text: modelData.body
                                color: "#cccccc"
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 4
                                textFormat: Text.MarkdownText
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
