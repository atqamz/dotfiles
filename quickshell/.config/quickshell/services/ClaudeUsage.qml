// quickshell/.config/quickshell/services/ClaudeUsage.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real sessionPct: 0
    property real weeklyPct: 0
    property string sessionResetIso: ""
    property string weeklyResetIso: ""
    property string status: "ok"      // ok | warning | critical | error
    property string errorKind: ""

    function severity(pct: real): string {
        if (pct >= 80) return "critical";
        if (pct >= 50) return "warning";
        return "ok";
    }

    function _parse(text: string): void {
        try {
            const d = JSON.parse(text);
            if (d.error) {
                root.sessionPct = 0;
                root.weeklyPct = 0;
                root.status = "error";
                root.errorKind = d.error;
                return;
            }
            root.sessionPct = parseFloat(d.sessionUsage ?? 0) || 0;
            root.weeklyPct = parseFloat(d.weeklyUsage ?? 0) || 0;
            root.sessionResetIso = d.sessionResetAt ?? "";
            root.weeklyResetIso = d.weeklyResetAt ?? "";
            root.status = severity(Math.max(root.sessionPct, root.weeklyPct));
            root.errorKind = "";
        } catch (e) {
            root.sessionPct = 0;
            root.weeklyPct = 0;
            root.status = "error";
            root.errorKind = "parse";
        }
    }

    Process {
        id: proc
        command: ["bash", "-c", "source \"$HOME/.claude/fetch-usage.sh\"; fetch_usage_data"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
    }

    Timer {
        interval: 600000             // 10 minutes — matches fetch-usage.sh CACHE_MAX_AGE
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }
}
