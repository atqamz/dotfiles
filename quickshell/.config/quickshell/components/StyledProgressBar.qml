import QtQuick
import QtQuick.Controls
import qs.components

ProgressBar {
    id: root
    implicitHeight: 6

    property color fillColor: Theme.primary

    background: Rectangle {
        radius: Theme.radius.full
        color: Theme.surfaceContainerHighest
    }

    contentItem: Item {
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Theme.radius.full
            color: root.fillColor

            Behavior on width { Anim {} }
        }
    }
}
