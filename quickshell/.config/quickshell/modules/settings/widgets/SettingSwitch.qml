import QtQuick
import qs.components

Item {
    id: root
    property string label: ""
    property bool checked: false
    signal toggled(bool value)
    width: parent ? parent.width : 400
    implicitHeight: 44

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
    }
    StyledSwitch {
        id: sw
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        onToggled: root.toggled(checked)
    }
}
