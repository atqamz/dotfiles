// Shared chrome for the full-screen search overlays (launcher, clipboard,
// pass, window picker, emoji): the per-screen PanelWindow, scrim, centred card,
// search field and keyboard routing. Callers place their own result view
// (ListView/GridView/whatever) as the default child — it fills the area under
// the search field — and keep ownership of their model, selection index and
// activation. Instantiate inside a `Variants { model: Quickshell.screens }`.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: overlay

    required property var modelData
    // Whether the overlay is open. Bind to the caller's shared `open` flag.
    property bool opened: false
    // Extra visibility gate, ANDed with `opened`. Defaults to focused-monitor
    // only so the card and its exclusive keyboard focus land on one screen.
    property bool active: HyprlandData.isFocusedScreen(modelData)
    // When true, Delete is forwarded through `navigate` instead of editing the
    // search text (clipboard uses it to remove the selected entry).
    property bool captureDelete: false
    // Two-way query plumbing: bind `queryText` to the caller's query string and
    // write it back from `onQueryEdited`. The caller's property stays the single
    // source of truth (it gets reset on toggle), so there is no binding loop.
    property string queryText: ""
    signal queryEdited(string text)

    property string icon: "search"
    property string placeholder: ""
    property int cardWidth: 600
    property int cardHeight: 480

    // Escape (or scrim click), Enter, and arrow/Tab navigation. `navigate`
    // carries the raw Qt key so callers can map it to 1-D or 2-D movement.
    signal escaped()
    signal accepted()
    signal navigate(int key)

    // The result view (ListView/GridView/…). Defined in the caller's scope so
    // its bindings resolve against the caller's root; loaded under the field.
    property Component resultView: null
    property alias field: searchField

    screen: modelData
    visible: opened && active

    property bool shown: false
    onVisibleChanged: {
        shown = visible;
        if (visible) {
            // A TextField's `text:` binding is dropped once the user types, so
            // sync the field to the (just-reset) query imperatively on open to
            // guarantee it clears, then focus it.
            searchField.text = overlay.queryText;
            searchField.forceActiveFocus();
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: overlay.shown ? 1 : 0
        Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }

        MouseArea {
            anchors.fill: parent
            onClicked: overlay.escaped()
        }
    }

    StyledRect {
        id: card
        anchors.centerIn: parent
        width: overlay.cardWidth
        height: overlay.cardHeight
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        radius: Theme.radius.large

        opacity: overlay.shown ? 1 : 0
        scale: overlay.shown ? 1 : 0.94
        transformOrigin: Item.Center
        Behavior on opacity { Anim { duration: Theme.anim.durations.normal } }
        Behavior on scale { Anim { curve: Theme.anim.spring; duration: Theme.anim.durations.spring } }

        MouseArea { anchors.fill: parent }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.padding.larger
            spacing: Theme.spacing.large

            Row {
                id: headerRow
                width: parent.width
                spacing: Theme.spacing.large

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: overlay.icon
                    color: Theme.textVariant
                    font.pixelSize: Theme.font.size.extraLarge
                    width: 28
                }

                TextField {
                    id: searchField
                    width: parent.width - 28 - parent.spacing
                    placeholderText: overlay.placeholder
                    color: Theme.text
                    placeholderTextColor: Theme.textMuted
                    renderType: Text.NativeRendering
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.family.sans
                    text: overlay.queryText
                    onTextChanged: if (text !== overlay.queryText) overlay.queryEdited(text)
                    background: Rectangle {
                        radius: Theme.radius.small
                        color: Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: searchField.activeFocus ? Theme.primary : Theme.outline
                        Behavior on border.color { CAnim {} }
                    }
                    padding: Theme.padding.normal

                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Escape:
                            overlay.escaped();
                            event.accepted = true;
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            overlay.accepted();
                            event.accepted = true;
                            break;
                        case Qt.Key_Up:
                        case Qt.Key_Down:
                        case Qt.Key_Left:
                        case Qt.Key_Right:
                        case Qt.Key_Tab:
                        case Qt.Key_Backtab:
                            overlay.navigate(event.key);
                            event.accepted = true;
                            break;
                        case Qt.Key_Delete:
                            if (overlay.captureDelete) {
                                overlay.navigate(event.key);
                                event.accepted = true;
                            }
                            break;
                        }
                    }
                }
            }

            Loader {
                id: contentHolder
                width: parent.width
                height: parent.height - headerRow.height - parent.spacing
                sourceComponent: overlay.resultView
            }
        }
    }
}
