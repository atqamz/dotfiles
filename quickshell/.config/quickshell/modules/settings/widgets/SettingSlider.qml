import QtQuick
import qs.components

Item {
    id: root
    property string label: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property string suffix: ""
    property int decimals: 0
    signal moved(real value)
    width: parent ? parent.width : 400
    implicitHeight: 52

    StyledText {
        id: lbl
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
        width: 160
        elide: Text.ElideRight
    }
    StyledText {
        id: readout
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        horizontalAlignment: Text.AlignRight
        text: root.value.toFixed(root.decimals) + root.suffix
        color: Theme.textVariant
        font.pixelSize: Theme.font.size.small
    }
    StyledSlider {
        id: slider
        anchors.left: lbl.right
        anchors.right: readout.left
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        anchors.verticalCenter: parent.verticalCenter
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onMoved: root.moved(value)
    }
}
