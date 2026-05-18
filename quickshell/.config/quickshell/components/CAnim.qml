import QtQuick
import qs.components

ColorAnimation {
    duration: Theme.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [
        Theme.anim.standard[0],
        Theme.anim.standard[1],
        Theme.anim.standard[2],
        Theme.anim.standard[3],
        1, 1
    ]
}
