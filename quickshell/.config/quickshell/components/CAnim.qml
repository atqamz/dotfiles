import QtQuick
import qs.components

ColorAnimation {
    property var curve: Theme.anim.standard
    duration: Theme.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
