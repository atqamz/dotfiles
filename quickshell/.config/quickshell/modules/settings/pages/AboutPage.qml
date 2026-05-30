import QtQuick
import Quickshell
import qs.components

Column {
    width: parent ? parent.width : 400
    spacing: Theme.spacing.large

    StyledText {
        text: "Quickshell dotfiles shell"
        color: Theme.text
        font.pixelSize: Theme.font.size.large
        font.weight: Theme.font.weight.title
    }
    StyledText {
        text: "Quickshell 0.3.0 · Qt 6.10.3"
        color: Theme.textVariant
        font.pixelSize: Theme.font.size.normal
    }
    StyledText {
        text: "Settings file (hand-editable, picked up live):"
        color: Theme.textVariant
        font.pixelSize: Theme.font.size.small
    }
    Row {
        spacing: Theme.spacing.normal
        StyledText {
            id: pathText
            text: Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family.mono
        }
        MaterialIcon {
            text: "content_copy"
            font.pixelSize: Theme.icon.size.small
            color: Theme.textVariant
            MouseArea { anchors.fill: parent; onClicked: Quickshell.clipboardText = pathText.text }
        }
    }
    StyledText {
        text: "Delete the file to restore all defaults."
        color: Theme.textMuted
        font.pixelSize: Theme.font.size.small
    }
}
