// quickshell/.config/quickshell/modules/bar/PeekState.qml
import QtQuick
import qs.components

// Edge-peek finite state machine for a TopBar / BottomBar PanelWindow.
//
// Lifecycle:
//   Collapsed -> hotZone hover -> Peeking (slide in)
//   Peeking   -> anim done     -> Visible
//   Visible   -> pills not hovered + dwellMs -> Hiding (slide out)
//   Hiding    -> anim done                   -> Collapsed
//
// Caller provides:
//   - slideTarget: the Item being translated (y property is animated)
//   - slideFromY / slideToY: collapsed and visible y offsets
//   - hotZoneItem: an Item with a HoverHandler at the screen edge
//   - watchedItems: list of pill Items whose hover state defines "still over bar"
//
// PeekState exposes:
//   - state: string ("Collapsed" | "Peeking" | "Visible" | "Hiding")
//   - fullyHidden: bool (true when state === "Collapsed")
QtObject {
    id: peek

    property Item slideTarget: null
    property int slideFromY: 0
    property int slideToY: 0
    property Item hotZoneItem: null
    property var watchedItems: []
    property int dwellMs: 150

    property string state: "Collapsed"
    readonly property bool fullyHidden: state === "Collapsed"

    function _enter(): void {
        if (state === "Collapsed" || state === "Hiding") {
            state = "Peeking";
        }
    }

    function _maybeExit(): void {
        // Called when hover changes; if no watched item is hovered and not
        // currently in hotZone, schedule Hiding after dwellMs.
        if (state !== "Visible" && state !== "Peeking") return;
        const hotHovered = hotZoneItem && hotZoneItem.hovered === true;
        if (hotHovered) return;
        for (let i = 0; i < watchedItems.length; ++i) {
            if (watchedItems[i] && watchedItems[i].hovered === true) return;
        }
        _exitTimer.restart();
    }

    function _commitExit(): void {
        if (state === "Visible" || state === "Peeking") state = "Hiding";
    }

    property Timer _exitTimer: Timer {
        interval: peek.dwellMs
        repeat: false
        onTriggered: peek._commitExit()
    }

    property Connections _hotConn: Connections {
        target: peek.hotZoneItem
        function onHoveredChanged() {
            if (peek.hotZoneItem && peek.hotZoneItem.hovered) {
                peek._exitTimer.stop();
                peek._enter();
            } else {
                peek._maybeExit();
            }
        }
    }

    property NumberAnimation _slideAnim: NumberAnimation {
        target: peek.slideTarget
        property: "y"
        duration: 200
        from: peek.slideTarget ? peek.slideTarget.y : 0
        to: peek.state === "Peeking" ? peek.slideToY : peek.slideFromY
        easing.type: peek.state === "Peeking" ? Easing.OutCubic : Easing.InCubic
        onFinished: {
            if (peek.state === "Peeking") peek.state = "Visible";
            else if (peek.state === "Hiding") peek.state = "Collapsed";
        }
    }

    onStateChanged: {
        if (state === "Peeking" || state === "Hiding") {
            _slideAnim.from = slideTarget ? slideTarget.y : 0;
            _slideAnim.to = state === "Peeking" ? slideToY : slideFromY;
            _slideAnim.easing.type = state === "Peeking" ? Easing.OutCubic : Easing.InCubic;
            _slideAnim.restart();
        }
    }

    function notifyWatchedHoverChanged(): void {
        _maybeExit();
    }
}
