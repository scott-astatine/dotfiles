pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell

/**
 * Legacy BluetoothStatus singleton wrapper forwarding to consolidated HardwareService.
 */
Singleton {
    id: root

    readonly property bool available: HardwareService.bluetoothAvailable
    readonly property bool enabled: HardwareService.bluetoothEnabled
    readonly property var firstActiveDevice: HardwareService.bluetoothFirstActiveDevice
    readonly property int activeDeviceCount: HardwareService.bluetoothActiveDeviceCount
    readonly property bool connected: HardwareService.bluetoothConnected
    readonly property var connectedDevices: HardwareService.bluetoothConnectedDevices
    readonly property var pairedButNotConnectedDevices: HardwareService.bluetoothPairedButNotConnectedDevices
    readonly property var unpairedDevices: HardwareService.bluetoothUnpairedDevices
    readonly property var friendlyDeviceList: HardwareService.bluetoothFriendlyDeviceList
}
