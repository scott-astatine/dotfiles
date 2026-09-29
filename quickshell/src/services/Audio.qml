pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell

/**
 * Legacy Audio singleton wrapper forwarding to consolidated HardwareService.
 */
Singleton {
    id: root

    signal sinkProtectionTriggered(string reason)

    Connections {
        target: HardwareService
        function onSinkProtectionTriggered(reason) {
            root.sinkProtectionTriggered(reason);
        }
    }

    readonly property var ready: HardwareService.audioReady
    readonly property var sink: HardwareService.sink
    readonly property var source: HardwareService.source
    readonly property real hardMaxValue: HardwareService.hardMaxValue
    readonly property var audioTheme: HardwareService.audioTheme
    property real value: HardwareService.audioValue
    onValueChanged: { HardwareService.audioValue = value; }
    readonly property var outputAppNodes: HardwareService.outputAppNodes
    readonly property var inputAppNodes: HardwareService.inputAppNodes
    readonly property var outputDevices: HardwareService.outputDevices
    readonly property var inputDevices: HardwareService.inputDevices

    function friendlyDeviceName(node) { return HardwareService.friendlyDeviceName(node); }
    function appNodeDisplayName(node) { return HardwareService.appNodeDisplayName(node); }
    function toggleMute() { HardwareService.toggleAudioMute(); }
    function toggleMicMute() { HardwareService.toggleMicMute(); }
    function incrementVolume() { HardwareService.incrementVolume(); }
    function decrementVolume() { HardwareService.decrementVolume(); }
    function setDefaultSink(node) { HardwareService.setDefaultSink(node); }
    function setDefaultSource(node) { HardwareService.setDefaultSource(node); }
}
