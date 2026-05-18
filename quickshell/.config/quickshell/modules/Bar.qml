// quickshell/.config/quickshell/modules/Bar.qml
import QtQuick
import Quickshell
import qs.modules.bar as BarModules

// Single bottom bar holding all pills (launcher | workspaces | media |
// clock | resources | tray | status). Floats above windows
// (ExclusionMode.Ignore), peeks on bottom-edge hover.
Scope {
    id: bar

    Variants {
        model: Quickshell.screens
        BarModules.BottomBar {}
    }
}
