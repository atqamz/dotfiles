import QtQuick
import qs.components

// Material Icons supports ligature text mode: setting `text: "wifi"` resolves
// to the wifi glyph. Caelestia uses Material Symbols (newer, variable axes);
// we use the static Material Icons because that is what Fedora packages.
StyledText {
    font.family: Theme.font.family.material
    font.pixelSize: Theme.font.size.larger
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
