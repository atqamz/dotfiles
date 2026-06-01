import QtQuick
import QtQuick.Controls
import qs.components

Item {
    id: root
    property string label: ""
    property string text: ""
    signal edited(string value)
    width: parent ? parent.width : 400
    implicitHeight: 48

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
    }
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 200
        height: 34
        radius: Theme.radius.small
        color: Theme.surfaceContainerHigh
        border.color: field.activeFocus ? Theme.primary : Theme.outline
        border.width: 1
        TextField {
            id: field
            anchors.fill: parent
            anchors.margins: 2
            leftPadding: Theme.padding.normal
            text: root.text
            color: Theme.text
            renderType: Text.NativeRendering
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family.sans
            background: null
            onEditingFinished: root.edited(text)
            // Typing drops the `text: root.text` binding; re-establish it on
            // blur so external changes to root.text show again.
            onActiveFocusChanged: if (!activeFocus) text = Qt.binding(() => root.text)
        }
    }
}
