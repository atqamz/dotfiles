import QtQuick
import QtQuick.Controls
import qs.components

Slider {
    id: root
    implicitHeight: 24

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        radius: Theme.radius.full
        color: Theme.surfaceContainerHighest

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Theme.radius.full
            color: Theme.primary
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 18
        implicitHeight: 18
        radius: Theme.radius.full
        color: Theme.primary
        border.color: Theme.background
        border.width: root.pressed ? 3 : 0

        Behavior on border.width { Anim { duration: Theme.anim.durations.small } }
    }
}
