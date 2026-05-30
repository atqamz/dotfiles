// quickshell/.config/quickshell/modules/bar/TrayPill.qml
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components
import qs.services

Pill {
    id: root

    readonly property alias hovered: hoverHandler.hovered

    visible: TrayService.count > 0
    horizontalPadding: 6

    HoverHandler { id: hoverHandler }

    contentItem: Row {
        spacing: 8

        Repeater {
            model: TrayService.items

            Item {
                required property var modelData
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    sourceSize.width: 18
                    sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                }

                StateLayer {
                    radius: Theme.radius.small
                    pressed: itemMouse.pressed
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            anchor.open();
                        } else {
                            modelData.activate();
                        }
                    }
                }

                QsMenuAnchor {
                    id: anchor
                    menu: modelData.menu
                    anchor.window: root.QsWindow.window
                    anchor.rect.x: root.mapToItem(null, 0, 0).x
                    anchor.rect.y: root.mapToItem(null, 0, 0).y
                    anchor.rect.width: root.width
                    anchor.rect.height: root.height
                    anchor.edges: Edges.Top
                }
            }
        }
    }
}
