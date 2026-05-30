import QtQuick
import qs.components

Item {
    id: btn
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    implicitWidth: parent ? parent.width : 140
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.normal
        color: btn.active ? Theme.surfaceContainerHigh : "transparent"

        // StateLayer reads parent.radius, so it must live inside a Rectangle.
        // It exposes only pressed/focused/hovered (no clicked) — drive pressed from a TapHandler.
        TapHandler { id: navTap; onTapped: btn.clicked() }
        StateLayer { pressed: navTap.pressed }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.padding.large
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.normal
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.icon
            font.pixelSize: Theme.icon.size.normal
            color: btn.active ? Theme.primary : Theme.textVariant
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.label
            color: btn.active ? Theme.text : Theme.textVariant
            font.pixelSize: Theme.font.size.normal
        }
    }
}
