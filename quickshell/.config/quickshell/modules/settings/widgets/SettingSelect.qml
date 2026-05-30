import QtQuick
import qs.components

Item {
    id: root
    property string label: ""
    property var options: []        // [{ label, value }]
    property var currentValue: null
    signal selected(var value)
    width: parent ? parent.width : 400
    implicitHeight: 44

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
    }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.smaller
        Repeater {
            model: root.options
            Item {
                required property var modelData
                readonly property bool sel: root.currentValue === modelData.value
                implicitWidth: segText.implicitWidth + 2 * Theme.padding.large
                implicitHeight: 32
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius.full
                    color: parent.sel ? Theme.primary : Theme.surfaceContainerHigh
                    border.color: parent.sel ? Theme.primary : Theme.outline
                    border.width: 1
                }
                StyledText {
                    id: segText
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.sel ? Theme.textOnPrimary : Theme.textVariant
                    font.pixelSize: Theme.font.size.small
                }
                MouseArea { anchors.fill: parent; onClicked: root.selected(modelData.value) }
            }
        }
    }
}
