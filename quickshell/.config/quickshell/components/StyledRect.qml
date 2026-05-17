import QtQuick
import qs.components

Rectangle {
    color: "transparent"
    radius: Theme.radius.normal

    Behavior on color {
        CAnim {}
    }
    Behavior on border.color {
        CAnim {}
    }
}
