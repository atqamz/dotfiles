// quickshell/.config/quickshell/modules/bar/BarGroup.qml
import QtQuick
import qs.components

// Rounded "island" segment that houses one or more bar widgets, mirroring
// end-4's BarGroup. The group supplies the surface + chrome so the widgets
// placed inside stay bare (chromeless pills, raw widgets); they are laid out
// left-to-right in an internal Row. Declared children land in that Row.
Item {
    id: root

    property alias hovered: groupHover.hovered
    property int padding: 8
    property int spacing: 8
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: Config.options.bar.height

    HoverHandler { id: groupHover }

    StyledRect {
        anchors.fill: parent
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        radius: Theme.radius.normal
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
