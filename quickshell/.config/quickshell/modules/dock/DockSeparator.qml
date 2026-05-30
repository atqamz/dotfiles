import QtQuick
import qs.components

Rectangle {
    implicitWidth: 1
    implicitHeight: Theme.icon.size.larger
    radius: Theme.radius.full
    color: Theme.outlineVariant
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
}
