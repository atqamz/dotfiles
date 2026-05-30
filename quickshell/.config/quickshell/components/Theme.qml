pragma Singleton

import QtQuick
import qs.components

QtObject {
    id: root

    // Material Design 3 -inspired dark palette, anchored to pure black surface.
    // No wallpaper-derived colours: caelestia derives M3 from the wallpaper image,
    // we hardcode an opinionated greyscale instead.
    readonly property color background: "#000000"
    readonly property color surface: "#0a0a0a"
    readonly property color surfaceContainerLow: "#101010"
    readonly property color surfaceContainer: "#141414"
    readonly property color surfaceContainerHigh: "#1a1a1a"
    readonly property color surfaceContainerHighest: "#202020"
    readonly property color surfaceBright: "#2a2a2a"
    readonly property color surfaceVariant: "#2a2a2a"
    readonly property color outline: "#3a3a3a"
    readonly property color outlineVariant: "#262626"
    readonly property color text: "#ffffff"
    readonly property color textVariant: "#cccccc"
    readonly property color textMuted: "#888888"
    readonly property color textDim: "#666666"
    readonly property color textDisabled: "#5e5e5e"
    readonly property color surfaceDisabled: "#0c0c0c"
    readonly property color primary: "#ffffff"
    readonly property color textOnPrimary: "#000000"
    readonly property color secondary: "#c0c0c0"
    readonly property color tertiary: "#a0a0a0"
    readonly property color warning: "#ffaa44"
    readonly property color error: "#ff4444"
    readonly property color scrim: "#cc000000"
    readonly property color shadow: "#66000000"

    // Interaction state-layer opacities (M3): overlay the layer's on-color.
    readonly property QtObject state: QtObject {
        readonly property real hover: 0.08
        readonly property real focus: 0.12
        readonly property real pressed: 0.12
        readonly property real dragged: 0.16
    }

    // Spacing scale (caelestia Tokens.spacing equivalent)
    readonly property QtObject spacing: QtObject {
        readonly property int smaller: 4
        readonly property int small: 6
        readonly property int normal: 8
        readonly property int large: 12
        readonly property int larger: 16
        readonly property int extraLarge: 24
    }

    readonly property QtObject padding: QtObject {
        readonly property int smaller: 4
        readonly property int small: 6
        readonly property int normal: 8
        readonly property int large: 12
        readonly property int larger: 16
    }

    readonly property QtObject radius: QtObject {
        readonly property int small: Math.round(8 * Config.options.appearance.radiusScale)
        readonly property int normal: Math.round(16 * Config.options.appearance.radiusScale)
        readonly property int large: Math.round(22 * Config.options.appearance.radiusScale)
        readonly property int extraLarge: Math.round(28 * Config.options.appearance.radiusScale)
        readonly property int full: 9999
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            // UI font: Rubik (Fedora google-rubik-fonts, static multi-weight).
            readonly property string sans: Config.options.appearance.fontFamily
            // Retained, unused by default UI.
            readonly property string mono: "JetBrains Mono"
            // Rounded variant of the legacy Material Icons set — identical
            // ligature names to "Material Icons", so existing icon usages
            // keep working. Deliberately NOT "Material Symbols Rounded".
            readonly property string material: "Material Icons Round"
        }
        // Static Rubik faces: select weight via font.weight, not variableAxes.
        readonly property QtObject weight: QtObject {
            readonly property int body: 400
            readonly property int title: 600
        }
        // Rung names are offset from end-4's by ~one step; values track end-4.
        readonly property QtObject size: QtObject {
            readonly property int smaller: Math.round(12 * Config.options.appearance.fontScale)
            readonly property int small: Math.round(13 * Config.options.appearance.fontScale)
            readonly property int normal: Math.round(15 * Config.options.appearance.fontScale)
            readonly property int large: Math.round(17 * Config.options.appearance.fontScale)
            readonly property int larger: Math.round(19 * Config.options.appearance.fontScale)
            readonly property int extraLarge: Math.round(22 * Config.options.appearance.fontScale)
        }
    }

    // Icon pixel sizes (Material Icons Round). Adopted by call sites in re-skin.
    readonly property QtObject icon: QtObject {
        readonly property QtObject size: QtObject {
            readonly property int small: Math.round(18 * Config.options.appearance.fontScale)
            readonly property int normal: Math.round(22 * Config.options.appearance.fontScale)
            readonly property int large: Math.round(28 * Config.options.appearance.fontScale)
            readonly property int larger: Math.round(36 * Config.options.appearance.fontScale)
        }
    }

    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int small: Math.max(1, Math.round(120 * Config.options.appearance.motionScale))
            readonly property int normal: Math.max(1, Math.round(200 * Config.options.appearance.motionScale))
            readonly property int large: Math.max(1, Math.round(320 * Config.options.appearance.motionScale))
            readonly property int extraLarge: Math.max(1, Math.round(480 * Config.options.appearance.motionScale))
            readonly property int springFast: Math.max(1, Math.round(350 * Config.options.appearance.motionScale))
            readonly property int spring: Math.max(1, Math.round(500 * Config.options.appearance.motionScale))
        }
        // Full-length bezier curves: groups of 3 points (c1,c2,end), end = 1,1.
        readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1, 1]
        readonly property var standardDecel: [0.0, 0.0, 0.0, 1.0, 1, 1]
        readonly property var standardAccel: [0.3, 0.0, 1.0, 1.0, 1, 1]
        readonly property var emphasized: [0.05, 0.0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1.0, 1, 1]
        readonly property var spring: [0.38, 1.21, 0.22, 1.0, 1, 1]
        readonly property var springFast: [0.42, 1.67, 0.21, 0.90, 1, 1]
        readonly property var decel: [0.05, 0.7, 0.1, 1.0, 1, 1]
        readonly property var accel: [0.3, 0.0, 0.8, 0.15, 1, 1]
        readonly property var clickBounce: [0.38, 1.21, 0.22, 1.0, 1, 1]
    }

    readonly property QtObject bar: QtObject {
        readonly property int width: 44
        readonly property int margin: 6
        readonly property int innerSpacing: 10
    }

    readonly property QtObject elevation: QtObject {
        readonly property int margin: 10
    }

    readonly property QtObject z: QtObject {
        readonly property int base: 0
        readonly property int panel: 10
        readonly property int overlay: 20
        readonly property int popup: 30
        readonly property int osd: 40
    }
}
