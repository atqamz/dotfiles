import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: btn
    required property var entry            // { id, name, iconPath, toplevels, pinned }
    property real radius: Theme.radius.normal
    readonly property var tops: entry.toplevels || []
    readonly property bool running: tops.length > 0
    readonly property bool active: tops.some(function (t) { return t.activated; })
    property int cycleIdx: 0

    implicitWidth: Config.options.dock.iconSize + 2 * Theme.padding.small
    implicitHeight: Config.options.dock.iconSize + 2 * Theme.padding.small
    scale: ma.pressed ? 0.92 : 1
    Behavior on scale { Anim { curve: Theme.anim.clickBounce; duration: Theme.anim.durations.normal } }

    StateLayer { pressed: ma.pressed; focused: btn.active }

    Image {
        id: icon
        anchors.centerIn: parent
        width: Config.options.dock.iconSize
        height: width
        sourceSize.width: width
        sourceSize.height: width
        source: btn.entry.iconPath
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectFit
    }
    MaterialIcon {
        anchors.centerIn: parent
        text: "widgets"
        font.pixelSize: Theme.icon.size.large
        color: Theme.text
        visible: icon.status !== Image.Ready
    }

    Rectangle {                       // running indicator
        visible: btn.running
        width: btn.active ? 6 : 4
        height: width
        radius: Theme.radius.full
        color: Theme.text
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 1
        Behavior on width { Anim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                if (btn.entry.pinned) DockService.unpin(btn.entry.id);
                else DockService.pin(btn.entry.id);
            } else if (mouse.button === Qt.MiddleButton) {
                var e = DockService.resolve(btn.entry.id); if (e) e.execute();
            } else {
                if (btn.running && btn.tops.length > 0) {
                    // First click on an unfocused app focuses it; clicking the
                    // already-active app cycles to its next window.
                    if (btn.active) {
                        btn.cycleIdx = (btn.cycleIdx + 1) % btn.tops.length;
                    } else {
                        btn.cycleIdx = 0;
                    }
                    btn.tops[btn.cycleIdx].activate();
                } else {
                    var de = DockService.resolve(btn.entry.id); if (de) de.execute();
                }
            }
        }
    }

    StyledToolTip { text: btn.entry.name; visible: ma.containsMouse }
}
