import QtQuick
import QtQuick.Layouts
import qs.components

// A small muted eyebrow label that anchors each sidebar section. Trailing
// content (counts, actions) declared as children lands on the right.
RowLayout {
    id: hdr
    property string label: ""
    default property alias content: trailing.data

    Layout.fillWidth: true
    spacing: Theme.spacing.small

    StyledText {
        text: hdr.label
        font.pixelSize: Theme.font.size.small
        font.weight: Theme.font.weight.title
        color: Theme.textMuted
    }

    Item { Layout.fillWidth: true }

    RowLayout {
        id: trailing
        spacing: Theme.spacing.small
    }
}
