import QtQuick
import qs.components

Item {
    id: root

    signal clicked()

    implicitWidth: 36
    implicitHeight: 36

    StyledRect {
        anchors.fill: parent
        color: Theme.surfaceContainer
        radius: Theme.radius.large

        MaterialIcon {
            anchors.centerIn: parent
            text: "auto_awesome"
            color: Theme.primary
            font.pixelSize: 22
        }

        StateLayer {
            id: layer
            radius: parent.radius
        }

        TapHandler {
            onTapped: root.clicked()
        }
    }
}
