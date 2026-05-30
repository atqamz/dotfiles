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

    Behavior on color { CAnim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        MaterialIcon {
            text: tile.model.icon
            color: tile.model.toggled ? Theme.textOnPrimary : Theme.text
            font.pixelSize: Theme.icon.size.normal
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: tile.model.name
                font.pixelSize: Theme.font.size.normal
                font.bold: true
                color: tile.model.toggled ? Theme.textOnPrimary : Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                visible: tile.model.statusText.length > 0
                text: tile.model.statusText
                font.pixelSize: Theme.font.size.smaller
                // on-primary black text
                color: tile.model.toggled ? Qt.rgba(0, 0, 0, 0.6) : Theme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: tile.model.available
        onClicked: tile.model.mainAction()
        onPressAndHold: tile.pressAndHold()
    }
    StateLayer { pressed: mouseArea.pressed }
}
