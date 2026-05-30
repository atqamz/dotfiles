import QtQuick
import QtQuick.Controls
import qs.components

ScrollBar {
    id: root
    padding: 2

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: Theme.radius.full
        color: root.pressed ? Theme.textMuted
             : root.hovered ? Theme.outline
             : Theme.outlineVariant
        opacity: root.active ? 1 : 0

        Behavior on color { CAnim {} }
        Behavior on opacity { Anim {} }
    }
}
