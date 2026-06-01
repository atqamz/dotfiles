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
    // When false the capsule chrome (background, border, radius, padding) is
    // dropped so the pill can sit bare inside a BarGroup that supplies its own
    // surface. Content and interaction handlers are unaffected.
    property bool chrome: true

    implicitHeight: 28
    // No content means no pill: avoids an empty chrome capsule taking padding width.
    implicitWidth: contentItem ? contentItem.implicitWidth + 2 * (chrome ? horizontalPadding : 0) : 0
    visible: contentItem !== null

    color: chrome ? Theme.surfaceContainer : "transparent"
    border.color: Theme.outlineVariant
    border.width: chrome ? 1 : 0
    radius: chrome ? Theme.radius.full : 0

    onContentItemChanged: {
        if (contentItem) {
            contentItem.parent = root;
            contentItem.anchors.centerIn = root;
        }
    }
}
