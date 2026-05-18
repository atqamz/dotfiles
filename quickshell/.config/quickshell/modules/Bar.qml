// quickshell/.config/quickshell/modules/Bar.qml
import QtQuick
import Quickshell
import qs.modules.bar as BarModules

// Floating-pills bar. TopBar (4 pills, peeks from top) and BottomBar
// (status pill, peeks from bottom). Primary-screen-only filtering is
// deferred — TODO once primaryScreen API behaviour is verified.
Scope {
    id: bar

    Variants {
        model: Quickshell.screens
        BarModules.TopBar {}
    }

    Variants {
        model: Quickshell.screens
        BarModules.BottomBar {}
    }
}
