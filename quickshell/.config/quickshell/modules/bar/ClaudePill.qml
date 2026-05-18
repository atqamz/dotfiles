// quickshell/.config/quickshell/modules/bar/ClaudePill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 10

    readonly property color claudeColor: {
        if (ClaudeUsage.status === "critical") return Theme.error;
        if (ClaudeUsage.status === "warning") return Theme.warning;
        if (ClaudeUsage.status === "error") return Theme.textDim;
        return Theme.text;
    }

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 6

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "smart_toy"
            color: root.claudeColor
            font.pixelSize: 14
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: ClaudeUsage.status === "error"
                  ? "--"
                  : `${ClaudeUsage.sessionPct.toFixed(0)}%`
            color: root.claudeColor
            font.pixelSize: 12
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: ClaudeUsage.status === "error"
                  ? ""
                  : `${ClaudeUsage.weeklyPct.toFixed(0)}%`
            color: root.claudeColor
            font.pixelSize: 12
            visible: ClaudeUsage.status !== "error"
        }
    }
}
