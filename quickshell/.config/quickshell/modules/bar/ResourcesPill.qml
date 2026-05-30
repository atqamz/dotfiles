// quickshell/.config/quickshell/modules/bar/ResourcesPill.qml
import QtQuick
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    horizontalPadding: 10

    function rampColor(pct) {
        if (pct >= 90) return Theme.error;
        if (pct >= 70) return Theme.warning;
        return Theme.text;
    }

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 10

        // CPU
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "memory"
                color: root.rampColor(Resources.cpuPct)
                font.pixelSize: Theme.icon.size.small
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Resources.cpuPct.toFixed(0) + "%"
                color: root.rampColor(Resources.cpuPct)
                font.pixelSize: Theme.font.size.smaller
            }
        }

        // RAM
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "developer_board"
                color: root.rampColor(Resources.ramPct)
                font.pixelSize: Theme.icon.size.small
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Resources.ramPct.toFixed(0) + "%"
                color: root.rampColor(Resources.ramPct)
                font.pixelSize: Theme.font.size.smaller
            }
        }

        // GPU (Nvidia, optional)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Resources.nvidiaAvailable
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "auto_awesome_motion"
                color: root.rampColor(Math.max(Resources.gpuUtilPct, Resources.gpuMemPct))
                font.pixelSize: Theme.icon.size.small
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Resources.gpuUtilPct.toFixed(0) + "%"
                color: root.rampColor(Resources.gpuUtilPct)
                font.pixelSize: Theme.font.size.smaller
            }
        }

        // Claude (session / weekly)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: ClaudeUsage.status !== "error"
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "smart_toy"
                color: {
                    if (ClaudeUsage.status === "critical") return Theme.error;
                    if (ClaudeUsage.status === "warning") return Theme.warning;
                    return Theme.text;
                }
                font.pixelSize: Theme.icon.size.small
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: ClaudeUsage.sessionPct.toFixed(0) + "/" + ClaudeUsage.weeklyPct.toFixed(0) + "%"
                color: {
                    if (ClaudeUsage.status === "critical") return Theme.error;
                    if (ClaudeUsage.status === "warning") return Theme.warning;
                    return Theme.text;
                }
                font.pixelSize: Theme.font.size.smaller
            }
        }
    }
}
