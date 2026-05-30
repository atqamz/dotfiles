import QtQuick
import qs.components
import qs.services

Row {
    id: row
    spacing: Theme.spacing.small

    Repeater {
        model: DockService.entries
        delegate: Loader {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: modelData.separator ? sepComp : btnComp
            Component { id: sepComp; DockSeparator {} }
            Component { id: btnComp; DockAppButton { entry: modelData } }
        }
    }
}
