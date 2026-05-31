import QtQuick
import qs.components

// Compact icon button: a MaterialIcon centred in a hover/press StateLayer,
// sized to the icon plus symmetric padding. Replaces the hand-rolled
// `Item { property real radius; StateLayer; MaterialIcon; MouseArea }` idiom.
Item {
    id: root

    property string icon: ""
    property color iconColor: Theme.textVariant
    property int iconSize: Theme.icon.size.small
    property real radius: Theme.radius.small
    property real padding: Theme.padding.smaller
    // StateLayer wash colour (e.g. Theme.error for destructive actions).
    property alias tint: state.tint
    signal clicked()

    implicitWidth: ico.implicitWidth + 2 * root.padding
    implicitHeight: ico.implicitHeight + 2 * root.padding

    StateLayer {
        id: state
        pressed: ma.pressed
    }

    MaterialIcon {
        id: ico
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
