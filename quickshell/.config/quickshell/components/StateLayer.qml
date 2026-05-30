import QtQuick
import qs.components

// Hover/focus/press tint layer. Drop into a parent that has `radius` set;
// tints to a soft white wash. Opacities come from Theme.state (M3).
Rectangle {
    id: root

    property alias hovered: hoverHandler.hovered
    property bool pressed: false
    property bool focused: false
    property color tint: Theme.text   // on-color to wash with

    anchors.fill: parent
    radius: parent.radius
    color: pressed ? Qt.rgba(tint.r, tint.g, tint.b, Theme.state.pressed)
         : focused ? Qt.rgba(tint.r, tint.g, tint.b, Theme.state.focus)
         : hovered ? Qt.rgba(tint.r, tint.g, tint.b, Theme.state.hover)
         : Qt.rgba(tint.r, tint.g, tint.b, 0)

    Behavior on color {
        CAnim {}
    }

    HoverHandler {
        id: hoverHandler
    }
}
