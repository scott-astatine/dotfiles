pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell

/**
 * Legacy Network singleton wrapper forwarding to consolidated HardwareService.
 */
Singleton {
    id: root

    readonly property var wifi: HardwareService.wifi
    readonly property var ethernet: HardwareService.ethernet
    readonly property bool wifiEnabled: HardwareService.wifiEnabled
    readonly property bool wifiScanning: HardwareService.wifiScanning
    readonly property bool wifiConnecting: HardwareService.wifiConnecting
    readonly property var wifiConnectTarget: HardwareService.wifiConnectTarget
    readonly property var wifiNetworks: HardwareService.wifiNetworks
    readonly property var savedSsids: HardwareService.savedSsids
    readonly property bool active: HardwareService.activeWifi
    readonly property var friendlyWifiNetworks: HardwareService.friendlyWifiNetworks
    readonly property var wifiStatus: HardwareService.wifiStatus
    readonly property string networkName: HardwareService.networkName
    readonly property int networkStrength: HardwareService.networkStrength
    readonly property string materialSymbol: HardwareService.networkMaterialSymbol

    function enableWifi(enabled) { HardwareService.enableWifi(enabled); }
    function toggleWifi() { HardwareService.toggleWifi(); }
    function rescanWifi() { HardwareService.rescanWifi(); }
    function connectToWifiNetwork(accessPoint) { HardwareService.connectToWifiNetwork(accessPoint); }
    function disconnectWifiNetwork() { HardwareService.disconnectWifiNetwork(); }
    function forgetWifiNetwork(accessPoint) { HardwareService.forgetWifiNetwork(accessPoint); }
    function changePassword(network, password) { HardwareService.changeWifiPassword(network, password); }
}
