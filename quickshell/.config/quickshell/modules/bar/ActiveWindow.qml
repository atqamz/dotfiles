// quickshell/.config/quickshell/modules/bar/ActiveWindow.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

// Focused-window indicator (app icon + elided title) modelled on end-4's
// ActiveWindow. Single line to fit the thin bar; fills the otherwise-empty
// left stretch so the bar no longer reads as sparse.
Item {
    id: root

    property alias hovered: hover.hovered
    property int maxTitleWidth: 280

    readonly property var win: ToplevelManager.activeToplevel
    readonly property string appId: (win && win.appId) ? win.appId : ""
    readonly property string title: (win && win.title) ? win.title : ""

    implicitWidth: row.implicitWidth
    implicitHeight: Config.options.bar.height

    HoverHandler { id: hover }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.small

        Image {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.icon.size.small
            height: width
            sourceSize.width: width
            sourceSize.height: width
            source: root.appId.length > 0 ? Quickshell.iconPath(root.appId, "application-x-executable") : ""
            visible: root.appId.length > 0 && status === Image.Ready
            fillMode: Image.PreserveAspectFit
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title.length > 0 ? root.title : "Desktop"
            color: Theme.textVariant
            font.pixelSize: Theme.font.size.small
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, root.maxTitleWidth)
        }
    }
}
