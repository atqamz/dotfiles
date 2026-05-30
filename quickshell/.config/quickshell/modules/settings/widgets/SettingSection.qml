import QtQuick
import qs.components

Column {
    id: root
    property string title: ""
    default property alias content: inner.data
    width: parent ? parent.width : 400
    spacing: Theme.spacing.small

    StyledText {
        text: root.title
        color: Theme.text
        font.pixelSize: Theme.font.size.large
        font.weight: Theme.font.weight.title
        visible: root.title !== ""
    }
    Column {
        id: inner
        width: parent.width
        spacing: Theme.spacing.smaller
    }
}
