import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ColumnLayout {
    id: root

    spacing: 0

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.now ? Qt.formatDateTime(Time.now, "HH") : "--"
        color: Theme.text
        font.pixelSize: Theme.font.size.large
        font.bold: true
    }
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.now ? Qt.formatDateTime(Time.now, "mm") : "--"
        color: Theme.textVariant
        font.pixelSize: Theme.font.size.large
    }
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacing.smaller
        Layout.bottomMargin: Theme.spacing.smaller
        implicitWidth: 16
        implicitHeight: 1
        color: Theme.outlineVariant
    }
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.now ? Qt.formatDateTime(Time.now, "dd") : "--"
        color: Theme.textVariant
        font.pixelSize: Theme.font.size.small
    }
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.now ? Qt.formatDateTime(Time.now, "MMM") : "--"
        color: Theme.textDim
        font.pixelSize: Theme.font.size.smaller
    }
}
