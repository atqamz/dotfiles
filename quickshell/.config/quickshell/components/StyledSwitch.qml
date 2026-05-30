import QtQuick
import QtQuick.Controls
import qs.components

Switch {
    id: root
    property real uiScale: 0.85
    implicitHeight: 32 * root.uiScale
    implicitWidth: 52 * root.uiScale

    background: Rectangle {
        radius: Theme.radius.full
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: 2 * root.uiScale
        border.color: root.checked ? Theme.primary : Theme.outline

        Behavior on color { CAnim { curve: Theme.anim.springFast; duration: Theme.anim.durations.springFast } }
        Behavior on border.color { CAnim {} }
    }

    indicator: Rectangle {
        property int sz: (root.pressed || root.down) ? 28 : (root.checked ? 24 : 16)
        width: sz * root.uiScale
        height: sz * root.uiScale
        radius: Theme.radius.full
        color: root.checked ? Theme.textOnPrimary : Theme.outline
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (root.checked
            ? ((root.pressed || root.down) ? 22 : 24)
            : ((root.pressed || root.down) ? 2 : 8)) * root.uiScale

        Behavior on anchors.leftMargin { NumberAnimation { duration: Theme.anim.durations.springFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.springFast } }
        Behavior on width { NumberAnimation { duration: Theme.anim.durations.springFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.springFast } }
        Behavior on height { NumberAnimation { duration: Theme.anim.durations.springFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.springFast } }
        Behavior on color { CAnim {} }
    }
}
