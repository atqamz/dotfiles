pragma Singleton

import QtQuick

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
    readonly property color outline: "#3a3a3a"
    readonly property color outlineVariant: "#262626"
    readonly property color text: "#ffffff"
    readonly property color textVariant: "#cccccc"
    readonly property color textMuted: "#888888"
    readonly property color textDim: "#666666"
    readonly property color primary: "#ffffff"
    readonly property color textOnPrimary: "#000000"
    readonly property color secondary: "#b9c8da"
    readonly property color tertiary: "#9ccbfb"
    readonly property color warning: "#ffaa44"
    readonly property color error: "#ff4444"
    readonly property color scrim: "#cc000000"

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
        readonly property int small: 4
        readonly property int normal: 8
        readonly property int large: 12
        readonly property int full: 9999
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string sans: "JetBrains Mono"
            readonly property string mono: "JetBrains Mono"
            readonly property string material: "Material Icons"
        }
        readonly property QtObject size: QtObject {
            readonly property int smaller: 10
            readonly property int small: 11
            readonly property int normal: 12
            readonly property int large: 14
            readonly property int larger: 16
            readonly property int extraLarge: 20
        }
    }

    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int small: 120
            readonly property int normal: 200
            readonly property int large: 320
            readonly property int extraLarge: 480
        }
        // Material Design "emphasized" curve (approximation).
        readonly property var standard: [0.2, 0.0, 0.0, 1.0]
        readonly property var emphasized: [0.3, 0.0, 0.0, 1.0]
    }

    readonly property QtObject bar: QtObject {
        readonly property int width: 44
        readonly property int margin: 6
        readonly property int innerSpacing: 10
    }
}
