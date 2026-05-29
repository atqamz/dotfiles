// Minimal black-themed quickshell config inspired by caelestia-shell
// (https://github.com/caelestia-dots/shell). This is a hand-rolled subset that
// avoids caelestia's compiled Qt6 plugin (not packaged on Fedora) — see
// README.md for the porting roadmap.

import Quickshell
import qs.modules

ShellRoot {
    Bar {}
    Notifications {}
    Launcher {}
    Power {}
    Clipboard {}
    WindowPicker {}
    Osd {}
    RecordingIndicator {}
    TagInput {}
    PassMenu {}
    EmojiPicker {}
    MediaControls {}
    Cheatsheet {}
    NotificationHistory {}
    SidebarRight {}
}
