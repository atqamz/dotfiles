// quickshell/.config/quickshell/modules/MediaControls.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Scope {
    id: root

    property bool open: false

    function toggle(): void { root.open = !root.open; }

    IpcHandler {
        target: "mediaControls"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea {
                anchors.fill: parent
                focus: true
                onClicked: root.open = false
                Keys.onEscapePressed: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 420
                implicitHeight: 220
                color: Theme.background
                border.color: Theme.outlineVariant
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                Timer {
                    interval: 1000
                    running: root.open && MprisService.isPlaying && MprisService.activePlayer !== null
                    repeat: true
                    onTriggered: {
                        if (MprisService.activePlayer) MprisService.activePlayer.positionChanged();
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large
                    visible: MprisService.hasPlayer

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.large

                        StyledRect {
                            implicitWidth: 80
                            implicitHeight: 80
                            color: Theme.surfaceContainer
                            border.color: Theme.outlineVariant
                            border.width: 1
                            radius: Theme.radius.normal
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: MprisService.artUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: MprisService.artUrl.length > 0
                                asynchronous: true
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: MprisService.artUrl.length === 0
                                text: "music_note"
                                color: Theme.textMuted
                                font.pixelSize: 40
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.smaller

                            StyledText {
                                Layout.fillWidth: true
                                text: MprisService.title || "Unknown title"
                                color: Theme.text
                                font.pixelSize: Theme.font.size.large
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: MprisService.artist || "Unknown artist"
                                color: Theme.textVariant
                                font.pixelSize: Theme.font.size.normal
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        visible: MprisService.length > 0

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceContainerHigh
                            radius: Theme.radius.full
                        }
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, MprisService.position / Math.max(1, MprisService.length)))
                            height: parent.height
                            color: Theme.text
                            radius: Theme.radius.full
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.spacing.extraLarge

                        StyledRect {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Theme.radius.full
                            color: prevHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                            border.color: Theme.outlineVariant
                            border.width: 1
                            opacity: MprisService.canGoPrevious ? 1.0 : 0.4

                            HoverHandler { id: prevHover }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: MprisService.previous()
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                color: Theme.text
                                font.pixelSize: 22
                            }
                        }

                        StyledRect {
                            implicitWidth: 52
                            implicitHeight: 52
                            radius: Theme.radius.full
                            color: playHover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                            border.color: Theme.outlineVariant
                            border.width: 1

                            HoverHandler { id: playHover }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: MprisService.togglePlaying()
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: MprisService.isPlaying ? "pause" : "play_arrow"
                                color: Theme.text
                                font.pixelSize: 28
                            }
                        }

                        StyledRect {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Theme.radius.full
                            color: nextHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                            border.color: Theme.outlineVariant
                            border.width: 1
                            opacity: MprisService.canGoNext ? 1.0 : 0.4

                            HoverHandler { id: nextHover }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: MprisService.next()
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "skip_next"
                                color: Theme.text
                                font.pixelSize: 22
                            }
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: !MprisService.hasPlayer
                    text: "No active media player"
                    color: Theme.textMuted
                    font.pixelSize: Theme.font.size.normal
                }
            }
        }
    }
}
