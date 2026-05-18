pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> allPlayers: Mpris.players.values
    readonly property MprisPlayer activePlayer: {
        for (let i = 0; i < allPlayers.length; ++i) {
            if (allPlayers[i].isPlaying) return allPlayers[i];
        }
        return allPlayers.length > 0 ? allPlayers[0] : null;
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0

    function togglePlaying(): void {
        if (activePlayer && canTogglePlaying) activePlayer.togglePlaying();
    }
    function next(): void {
        if (activePlayer && canGoNext) activePlayer.next();
    }
    function previous(): void {
        if (activePlayer && canGoPrevious) activePlayer.previous();
    }
    function pauseAll(): void {
        for (let i = 0; i < allPlayers.length; ++i) {
            if (allPlayers[i].canPause) allPlayers[i].pause();
        }
    }

    IpcHandler {
        target: "mpris"
        function playPause(): void { root.togglePlaying(); }
        function next(): void { root.next(); }
        function previous(): void { root.previous(); }
        function pauseAll(): void { root.pauseAll(); }
    }
}
