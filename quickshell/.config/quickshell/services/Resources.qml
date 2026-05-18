// quickshell/.config/quickshell/services/Resources.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuPct: 0
    property real ramPct: 0
    property real gpuUtilPct: 0
    property real gpuMemPct: 0
    property bool nvidiaAvailable: false

    property var _prevCpu: null    // {idle, total}

    function severity(pct) {
        if (pct >= 90) return "critical";
        if (pct >= 70) return "warning";
        return "ok";
    }

    function _parseCpuRam(text) {
        const blocks = text.split("---");
        if (blocks.length < 2) return;

        // CPU: "cpu  user nice system idle iowait irq softirq steal guest guest_nice"
        const cpuLine = blocks[0].trim().split(/\s+/);
        if (cpuLine.length >= 5 && cpuLine[0] === "cpu") {
            const nums = cpuLine.slice(1).map(n => parseInt(n, 10) || 0);
            const idle = nums[3] + (nums[4] || 0);
            const total = nums.reduce((a, b) => a + b, 0);
            if (root._prevCpu !== null) {
                const idleDelta = idle - root._prevCpu.idle;
                const totalDelta = total - root._prevCpu.total;
                if (totalDelta > 0) {
                    root.cpuPct = Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)));
                }
            }
            root._prevCpu = { idle: idle, total: total };
        }

        // MemInfo
        let memTotal = 0, memAvail = 0;
        for (const line of blocks[1].trim().split("\n")) {
            const m = line.match(/^(\w+):\s+(\d+)/);
            if (!m) continue;
            if (m[1] === "MemTotal") memTotal = parseInt(m[2], 10);
            else if (m[1] === "MemAvailable") memAvail = parseInt(m[2], 10);
        }
        if (memTotal > 0) {
            root.ramPct = Math.max(0, Math.min(100, 100 * (memTotal - memAvail) / memTotal));
        }
    }

    function _parseGpu(text) {
        const line = text.trim().split("\n")[0];
        if (!line) {
            root.nvidiaAvailable = false;
            return;
        }
        const parts = line.split(",").map(s => s.trim());
        if (parts.length < 3) {
            root.nvidiaAvailable = false;
            return;
        }
        const util = parseFloat(parts[0]);
        const memUsed = parseFloat(parts[1]);
        const memTotal = parseFloat(parts[2]);
        if (isNaN(util) || isNaN(memUsed) || isNaN(memTotal) || memTotal <= 0) {
            root.nvidiaAvailable = false;
            return;
        }
        root.gpuUtilPct = Math.max(0, Math.min(100, util));
        root.gpuMemPct = Math.max(0, Math.min(100, 100 * memUsed / memTotal));
        root.nvidiaAvailable = true;
    }

    Process {
        id: cpuRamProc
        command: ["bash", "-c", "head -1 /proc/stat; echo ---; head -3 /proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: root._parseCpuRam(this.text) }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector { onStreamFinished: root._parseGpu(this.text) }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.nvidiaAvailable = false;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cpuRamProc.running) cpuRamProc.running = true;
            if (!gpuProc.running) gpuProc.running = true;
        }
    }
}
