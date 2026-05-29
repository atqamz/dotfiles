import QtQuick

QtObject {
    required property string name
    property string statusText: ""
    property string icon: "close"
    property bool available: true
    property bool toggled: false
    required property var mainAction
}
