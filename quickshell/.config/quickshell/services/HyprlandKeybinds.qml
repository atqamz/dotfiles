pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // categories: [{ name: "Section name", binds: [{mods: "SUPER+SHIFT", key: "Q", action: "killactive"}] }]
    property var categories: []

    function reload(): void {
        configFile.reload();
    }

    FileView {
        id: configFile
        path: ""

        Component.onCompleted: {
            configFile.path = Quickshell.env("HOME") + "/.config/hypr/hyprland.conf";
        }

        watchChanges: true
        onFileChanged: configFile.reload()
        onLoaded: root._parse(this.text())
    }

    function _parse(text: string): void {
        const lines = text.split("\n");
        const cats = [];
        let cur = { name: "Misc", binds: [] };

        const sectionRe = /^\s*#+\s*Section:\s*(.+?)\s*#*\s*$/;
        const bindRe = /^\s*bind[lemi]*\s*=\s*([^,]*),\s*([^,]*),\s*(.+?)\s*$/;

        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i];
            const sm = line.match(sectionRe);
            if (sm) {
                if (cur.binds.length > 0) cats.push(cur);
                cur = { name: sm[1].trim(), binds: [] };
                continue;
            }
            const bm = line.match(bindRe);
            if (bm) {
                const mods = bm[1].trim().replace(/\$mainMod/g, "SUPER").toUpperCase();
                const key = bm[2].trim().toUpperCase();
                const action = bm[3].trim();
                if (key.length === 0) continue;
                cur.binds.push({ mods: mods, key: key, action: action });
            }
        }
        if (cur.binds.length > 0) cats.push(cur);
        root.categories = cats;
    }
}
