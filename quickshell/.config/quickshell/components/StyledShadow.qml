import QtQuick
import QtQuick.Effects
import qs.components

// Usage: place as a sibling BEFORE the target rect; pass target.
// Set `cached: false` if the target animates size/radius.
// Not valid directly inside a Layout (anchoring to a sibling fails) — wrap the
// target in a plain Item if it lives in a RowLayout/ColumnLayout/GridLayout.
RectangularShadow {
    required property var target
    anchors.fill: target
    radius: target.radius
    blur: 0.9 * Theme.elevation.margin
    spread: 1
    offset: Qt.vector2d(0.0, 1.0)
    color: Theme.shadow
    cached: true
}
