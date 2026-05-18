// quickshell/.config/quickshell/modules/Bar.qml
import QtQuick
import Quickshell
import qs.modules.bar as BarModules

// Primary-monitor-only floating-pills bar. Spawns TopBar (4 pills, peeks
// from top) and BottomBar (status pill, peeks from bottom) on the primary
// screen only — multi-monitor: secondary screens get nothing.
Scope {
    id: bar

    readonly property var primaryScreens: Quickshell.screens.filter(
        s => Quickshell.primaryScreen && s.name === Quickshell.primaryScreen.name
    )

    Variants {
        model: bar.primaryScreens
        BarModules.TopBar {}    // modelData property already declared `required` in TopBar.qml
    }

    Variants {
        model: bar.primaryScreens
        BarModules.BottomBar {}
    }
}
