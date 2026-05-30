import QtQuick
import QtQuick.Controls
import qs.components

ToolTip {
    id: root
    delay: 400
    padding: Theme.padding.normal

    contentItem: StyledText {
        text: root.text
        color: Theme.text
        font.pixelSize: Theme.font.size.small
    }

    background: Rectangle {
        radius: Theme.radius.small
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outlineVariant
    }
}
