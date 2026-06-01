import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    property int mode: 0  // 0=work, 1=short break, 2=long break
    property bool running: false
    property int elapsed: 0
    property int completed: 0

    readonly property var durations: [25 * 60, 5 * 60, 15 * 60]
    readonly property var labels: ["Work", "Short Break", "Long Break"]
    readonly property int total: durations[mode]
    readonly property int remaining: Math.max(0, total - elapsed)
    readonly property string timeText: {
        var m = Math.floor(remaining / 60);
        var s = remaining % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }
    readonly property real progress: total > 0 ? elapsed / total : 0

    function start(): void { running = true; }
    function pause(): void { running = false; }
    function reset(): void { running = false; elapsed = 0; }

    function onComplete(): void {
        running = false;
        elapsed = 0;
        if (mode === 0) {
            completed++;
            Quickshell.execDetached(["notify-send", "Pomodoro", "Work session complete! Take a break."]);
        } else {
            Quickshell.execDetached(["notify-send", "Pomodoro", "Break over! Time to focus."]);
        }
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            root.elapsed++;
            if (root.elapsed >= root.total) root.onComplete();
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Mode selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.labels

                Rectangle {
                    required property int index
                    required property string modelData
                    Layout.fillWidth: true
                    height: 28
                    radius: Theme.radius.normal
                    color: root.mode === index ? Theme.surfaceContainerHigh : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Theme.font.size.smaller
                        font.bold: root.mode === index
                        color: root.mode === index ? Theme.text : Theme.textMuted
                    }

                    StateLayer {
                        focused: root.mode === index
                        pressed: modeTap.pressed
                    }

                    MouseArea {
                        id: modeTap
                        anchors.fill: parent
                        onClicked: {
                            root.mode = index;
                            root.reset();
                        }
                    }
                }
            }
        }

        // Progress ring + time
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter

            Canvas {
                id: ring
                anchors.centerIn: parent
                width: 110; height: 110

                // Animated 0..1 sweep; smoothed so per-second ticks glide.
                property real prog: root.progress
                property color arcColor: root.mode === 0 ? Theme.primary : Theme.tertiary
                Behavior on prog { Anim { duration: Theme.anim.durations.normal } }
                onProgChanged: requestPaint()
                onArcColorChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const cx = width / 2, cy = height / 2, r = width / 2 - 4;
                    ctx.lineWidth = 4;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.strokeStyle = Theme.outlineVariant;
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.stroke();

                    if (prog > 0) {
                        const start = -Math.PI / 2;
                        ctx.beginPath();
                        ctx.strokeStyle = arcColor;
                        ctx.arc(cx, cy, r, start, start + 2 * Math.PI * Math.min(prog, 1));
                        ctx.stroke();
                    }
                }
            }

            // Time text
            StyledText {
                anchors.centerIn: parent
                text: root.timeText
                font.pixelSize: Theme.font.size.extraLarge
                font.bold: true
                color: Theme.text
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Rectangle {
                width: 36; height: 36; radius: Theme.radius.full
                color: Theme.surfaceContainerHigh

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "autorenew"
                    color: Theme.textVariant
                }

                StateLayer { pressed: resetTap.pressed }

                MouseArea {
                    id: resetTap
                    anchors.fill: parent
                    onClicked: root.reset()
                }
            }

            Rectangle {
                width: 48; height: 48; radius: Theme.radius.full
                color: root.running ? Theme.error : Theme.primary

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.running ? "pause" : "play_arrow"
                    color: root.running ? Theme.text : Theme.textOnPrimary
                    font.pixelSize: Theme.icon.size.normal
                }

                StateLayer {
                    pressed: playTap.pressed
                    tint: root.running ? Theme.text : Theme.textOnPrimary
                }

                MouseArea {
                    id: playTap
                    anchors.fill: parent
                    onClicked: root.running ? root.pause() : root.start()
                }
            }

            // Completed count
            StyledText {
                text: root.completed + "x"
                font.pixelSize: Theme.font.size.large
                font.bold: true
                color: Theme.textVariant
                visible: root.completed > 0
            }
        }
    }
}
