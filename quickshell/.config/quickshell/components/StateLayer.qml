import QtQuick
import qs.components

// Caelestia-style hover/press tint layer. Drop into a parent that has `radius`
// set; covers the parent and tints to a soft white wash on hover.
Rectangle {
    id: root

    property alias hovered: hoverHandler.hovered
    property color hoverColor: Qt.rgba(1, 1, 1, 0.08)
    property color pressColor: Qt.rgba(1, 1, 1, 0.16)
    property bool pressed: false

    anchors.fill: parent
    radius: parent.radius
    color: pressed ? pressColor : (hovered ? hoverColor : "transparent")

    Behavior on color {
        CAnim {}
    }

    HoverHandler {
        id: hoverHandler
    }
}
