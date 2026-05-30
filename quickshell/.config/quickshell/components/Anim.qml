import QtQuick
import qs.components

NumberAnimation {
    // Override `curve` with any Theme.anim.* (e.g. Theme.anim.spring) and
    // `duration` as needed. Defaults reproduce the prior standard motion.
    property var curve: Theme.anim.standard
    duration: Theme.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
