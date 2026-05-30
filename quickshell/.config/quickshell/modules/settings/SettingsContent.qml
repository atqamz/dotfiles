import QtQuick
import Quickshell
import qs.components
import "widgets"

Item {
    id: root
    signal requestClose()

    readonly property var pages: [
        { name: "Appearance", icon: "palette",   source: "pages/AppearancePage.qml" },
        { name: "Bar",        icon: "toolbar",    source: "pages/BarPage.qml" },
        { name: "Dock",       icon: "dock",       source: "pages/DockPage.qml" },
        { name: "Overview",   icon: "grid_view",  source: "pages/OverviewPage.qml" },
        { name: "Behavior",   icon: "tune",       source: "pages/BehaviorPage.qml" },
        { name: "About",      icon: "info",       source: "pages/AboutPage.qml" }
    ]
    property int currentPage: 0

    implicitWidth: Screen.width > 0 ? Math.min(900, Screen.width - 80) : 900
    implicitHeight: Screen.height > 0 ? Math.min(620, Screen.height - 80) : 620

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.large
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1

        Column {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            Item {
                width: parent.width
                height: 56
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.padding.larger
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing.normal
                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "settings"; font.pixelSize: Theme.icon.size.large; color: Theme.text
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Settings"; color: Theme.text
                        font.pixelSize: Theme.font.size.large; font.weight: Theme.font.weight.title
                    }
                }
                Item {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36; height: 36
                    MaterialIcon { anchors.centerIn: parent; text: "close"; font.pixelSize: Theme.icon.size.normal; color: Theme.textVariant }
                    MouseArea { anchors.fill: parent; onClicked: root.requestClose() }
                }
            }
        }

        Row {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.padding.large
            spacing: Theme.spacing.large

            Column {
                id: navRail
                width: 150
                height: parent.height
                spacing: Theme.spacing.smaller
                Repeater {
                    model: root.pages
                    NavButton {
                        required property var modelData
                        required property int index
                        width: navRail.width
                        icon: modelData.icon
                        label: modelData.name
                        active: root.currentPage === index
                        onClicked: root.currentPage = index
                    }
                }
            }

            Rectangle {
                width: parent.width - navRail.width - Theme.spacing.large
                height: parent.height
                radius: Theme.radius.normal
                color: Theme.surfaceContainerLow
                clip: true
                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: Theme.padding.large
                    source: Config.ready ? root.pages[root.currentPage].source : ""
                }
            }
        }
    }
}
