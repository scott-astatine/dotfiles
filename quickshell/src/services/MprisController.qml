pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell

/**
 * Legacy MprisController singleton wrapper forwarding to consolidated MediaService.
 */
Singleton {
    id: root

    readonly property var players: MediaService.players
    readonly property var trackedPlayer: MediaService.trackedPlayer
    readonly property var activePlayer: MediaService.activePlayer
    readonly property var activeTrack: MediaService.activeTrack
    readonly property bool hasActivePlasmaIntegration: MediaService.hasActivePlasmaIntegration
    function isRealPlayer(player) { return MediaService.isRealPlayer(player); }
}
