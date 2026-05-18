// quickshell/.config/quickshell/modules/bar/Pill.qml
import QtQuick
import qs.components

// Reusable opaque-black capsule container. Wraps `contentItem` with the
// standard pill chrome from Theme. All pills in the bar use this so the
// look stays uniform.
StyledRect {
    id: root

    property Item contentItem: null
    property int horizontalPadding: 12

    implicitHeight: 28
    implicitWidth: (contentItem ? contentItem.implicitWidth : 0) + 2 * horizontalPadding

    color: Theme.background
    border.color: Theme.outlineVariant
    border.width: 1
    radius: Theme.radius.full

    onContentItemChanged: {
        if (contentItem) {
            contentItem.parent = root;
            contentItem.anchors.centerIn = root;
        }
    }
}
