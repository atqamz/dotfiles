pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volume: 0
    property bool muted: false
    property int micVolume: 0
    property bool micMuted: false

    function refresh(): void {
        proc.running = true;
    }

    function increment(): void {
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+"]);
        refresh();
    }

    function decrement(): void {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]);
        refresh();
    }

    function toggleMute(): void {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        refresh();
    }

    function toggleMicMute(): void {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
        micProc.running = true;
    }

    function refreshMic(): void {
        micProc.running = true;
    }

    Process {
        id: proc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (!m) return;
                root.volume = Math.round(parseFloat(m[1]) * 100);
                root.muted = m[2] !== undefined;
            }
        }
    }

    Process {
        id: micProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (!m) return;
                root.micVolume = Math.round(parseFloat(m[1]) * 100);
                root.micMuted = m[2] !== undefined;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            proc.running = true;
            micProc.running = true;
        }
    }
}
