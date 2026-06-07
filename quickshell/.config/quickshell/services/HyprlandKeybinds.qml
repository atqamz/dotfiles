pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // categories: [{ name: "Section name", binds: [{mods: "SUPER+SHIFT", key: "Q", action: "killactive"}] }]
    property var categories: []

    // Source files (lua provider, since the hyprlang -> 0.55 cutover). The shared
    // core lives in hyprland.lua; per-host binds live in host.lua (symlink ->
    // hosts/<hostname>.lua). Both are parsed and their categories concatenated.
    property string _mainText: ""
    property string _hostText: ""
    property bool _mainLoaded: false
    property bool _hostLoaded: false

    function reload(): void {
        mainFile.reload();
        hostFile.reload();
    }

    FileView {
        id: mainFile
        path: Quickshell.env("HOME") + "/.config/hypr/hyprland.lua"
        watchChanges: true
        onFileChanged: mainFile.reload()
        onLoaded: { root._mainText = this.text(); root._mainLoaded = true; root._rebuild(); }
    }

    FileView {
        id: hostFile
        path: Quickshell.env("HOME") + "/.config/hypr/host.lua"
        watchChanges: true
        onFileChanged: hostFile.reload()
        onLoaded: { root._hostText = this.text(); root._hostLoaded = true; root._rebuild(); }
    }

    function _rebuild(): void {
        const cats = [];
        if (root._mainLoaded) root._parseInto(root._mainText, cats);
        if (root._hostLoaded) root._parseInto(root._hostText, cats);
        root.categories = cats;
    }

    // --- lua source parsing -------------------------------------------------

    function _parseInto(text: string, cats): void {
        if (!text || text.length === 0) return;

        // Each required lua file is its own scope; collect that file's own string
        // locals (mainMod plus program vars like terminal/launcher) for resolution.
        const vars = {};
        const vre = /^\s*local\s+(\w+)\s*=\s*"([^"]*)"/gm;
        let vm;
        while ((vm = vre.exec(text)) !== null) vars[vm[1]] = vm[2];
        const mainMod = vars["mainMod"] || "SUPER";

        const lines = text.split("\n");
        // Accept both `#` (legacy hyprlang) and `--` (lua) comment leaders.
        const sectionRe = /^\s*(?:#+|--+)\s*Section:\s*(.+?)\s*#*\s*$/;
        const bindRe = /^\s*hl\.bind\(\s*(.+)$/;

        let cur = { name: "Misc", binds: [] };

        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i];
            const sm = line.match(sectionRe);
            if (sm) {
                if (cur.binds.length > 0) cats.push(cur);
                cur = { name: sm[1].trim(), binds: [] };
                continue;
            }
            const bm = line.match(bindRe);
            if (!bm) continue;
            const b = root._parseBind(bm[1], mainMod, vars);
            if (b) cur.binds.push(b);
        }
        if (cur.binds.length > 0) cats.push(cur);
    }

    // Parse the body after `hl.bind(`. Returns {mods, key, action} or null.
    function _parseBind(rest: string, mainMod: string, vars: var): var {
        const args = root._splitArgs(rest);
        if (args.length < 2) return null;
        const action = root._actionLabel(args[1], vars);
        if (action === null) return null; // e.g. submap function() bodies
        const keyspec = root._resolveKeyspec(args[0], mainMod);
        if (keyspec.length === 0) return null;
        const mk = root._splitMods(keyspec);
        return { mods: mk.mods, key: mk.key, action: action };
    }

    // Split top-level comma-separated args, respecting strings and (){}[ ] nesting.
    // Stops at the close paren of hl.bind( itself.
    function _splitArgs(s: string): var {
        const args = [];
        let cur = "";
        let depth = 0;
        let inStr = false, strCh = "";
        for (let i = 0; i < s.length; ++i) {
            const c = s[i];
            if (inStr) {
                cur += c;
                if (c === strCh) { inStr = false; }
                continue;
            }
            if (c === '"' || c === "'") { inStr = true; strCh = c; cur += c; continue; }
            if (c === '(' || c === '{' || c === '[') { depth++; cur += c; continue; }
            if (c === ')' || c === '}' || c === ']') {
                if (depth === 0 && c === ')') break; // closing hl.bind(
                depth--; cur += c; continue;
            }
            if (c === ',' && depth === 0) { args.push(cur.trim()); cur = ""; continue; }
            cur += c;
        }
        if (cur.trim().length > 0) args.push(cur.trim());
        return args;
    }

    // Resolve a lua keyspec expression to a flat string.
    // `mainMod .. " + SHIFT + Q"` -> "SUPER + SHIFT + Q"; `"XF86AudioPlay"` -> as-is.
    function _resolveKeyspec(arg: string, mainMod: string): string {
        const parts = arg.split("..");
        let out = "";
        for (let i = 0; i < parts.length; ++i) {
            const p = parts[i].trim();
            if (p === "mainMod") { out += mainMod; continue; }
            const sm = p.match(/^"((?:[^"\\]|\\.)*)"$/);
            if (sm) { out += sm[1]; continue; }
            out += p; // unknown token; keep raw
        }
        return out.trim();
    }

    // Split a flat keyspec into trailing key + leading modifiers (joined by " + ").
    function _splitMods(keyspec: string): var {
        const segs = keyspec.split(/\s*\+\s*/).map(s => s.trim()).filter(s => s.length > 0);
        if (segs.length <= 1) return { mods: "", key: keyspec.trim() };
        const key = segs[segs.length - 1];
        const mods = segs.slice(0, -1).join(" + ");
        return { mods: mods, key: key };
    }

    // Derive a human-readable action label from the second hl.bind arg.
    function _actionLabel(a: string, vars: var): var {
        // exec / exec_cmd with a [[ long string ]]
        let m = a.match(/hl\.dsp\.exec(?:_cmd)?\(\s*\[\[([\s\S]*?)\]\]\s*\)/);
        if (m) return m[1].trim();
        // exec / exec_cmd with a "double-quoted" string
        m = a.match(/hl\.dsp\.exec(?:_cmd)?\(\s*"((?:[^"\\]|\\.)*)"\s*\)/);
        if (m) return m[1];
        // exec / exec_cmd of a bare local var (e.g. terminal, launcher) -> its value
        m = a.match(/hl\.dsp\.exec(?:_cmd)?\(\s*([A-Za-z_]\w*)\s*\)/);
        if (m) return (vars && vars[m[1]] !== undefined) ? vars[m[1]] : m[1];
        // submap / layout: show the named target
        m = a.match(/hl\.dsp\.submap\(\s*"([^"]*)"\s*\)/);
        if (m) return "submap: " + m[1];
        m = a.match(/hl\.dsp\.layout\(\s*"([^"]*)"\s*\)/);
        if (m) return "layout: " + m[1];
        // generic hl.dsp.<path>(<args>) -> readable verb (+ first table hint)
        m = a.match(/hl\.dsp\.([a-zA-Z_.]+)\s*\((.*)\)\s*$/);
        if (m) {
            const verb = m[1].replace(/\./g, " ");
            const hint = root._tableHint(m[2].trim());
            return hint ? (verb + " (" + hint + ")") : verb;
        }
        // function() bodies and anything else: not a displayable action
        return null;
    }

    // Pull the first key=value pair out of a lua table literal for a short hint.
    function _tableHint(inner: string): string {
        const m = inner.match(/(\w+)\s*=\s*"?([^",}]+)"?/);
        return m ? (m[1] + "=" + m[2].trim()) : "";
    }
}
