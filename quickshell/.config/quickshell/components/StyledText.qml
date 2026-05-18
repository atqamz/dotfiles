import QtQuick
import qs.components

Text {
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Theme.text
    font.family: Theme.font.family.sans
    font.pixelSize: Theme.font.size.normal

    Behavior on color {
        CAnim {}
    }
}
