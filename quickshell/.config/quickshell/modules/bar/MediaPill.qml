// quickshell/.config/quickshell/modules/bar/MediaPill.qml
import QtQuick
import Quickshell
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    visible: MprisService.hasPlayer
    horizontalPadding: 10

    readonly property string truncatedTitle: {
        const t = MprisService.title;
        if (t.length <= 24) return t;
        return t.substring(0, 23) + "…";
    }

    HoverHandler { id: hoverHandler }

    StateLayer {
        pressed: leftTap.pressed
    }

    TapHandler {
        id: leftTap
        acceptedButtons: Qt.LeftButton
        onTapped: Quickshell.execDetached(["qs", "ipc", "call", "mediaControls", "toggle"])
    }
    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: MprisService.togglePlaying()
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: MprisService.next()
    }

    contentItem: Row {
        spacing: 6

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: MprisService.isPlaying ? "pause" : "music_note"
            color: Theme.text
            font.pixelSize: Theme.icon.size.small
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.truncatedTitle
            color: Theme.text
            font.pixelSize: Theme.font.size.smaller
            visible: root.truncatedTitle.length > 0
        }
    }
}
