import QtQuick
import QtQuick.Layouts
import qs.components

Rectangle {
    id: tile

    signal pressAndHold()

    required property QuickToggleModel model

    Layout.fillWidth: true
    implicitHeight: 56
    radius: Theme.radius.large
    color: model.toggled ? Theme.primary : Theme.surface
    opacity: model.available ? 1.0 : 0.4

    Behavior on color { ColorAnimation { duration: 200 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        MaterialIcon {
            text: tile.model.icon
            color: tile.model.toggled ? Theme.textOnPrimary : Theme.text
            font.pixelSize: 20
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: tile.model.name
                font.pixelSize: Theme.font.size.small
                font.bold: true
                color: tile.model.toggled ? Theme.textOnPrimary : Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                visible: tile.model.statusText.length > 0
                text: tile.model.statusText
                font.pixelSize: Theme.font.size.smaller
                color: tile.model.toggled ? Qt.rgba(1, 1, 1, 0.7) : Theme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: tile.model.available
        onClicked: tile.model.mainAction()
        onPressAndHold: tile.pressAndHold()
    }
}
