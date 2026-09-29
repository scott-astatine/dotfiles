pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import "../components"
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import "../core"
import "./network"

/**
 * HardwareService: Unified domain service managing Audio, Network, Bluetooth, Brightness, and Battery.
 */
Singleton {
    id: root

    // ==========================================
    // 1. AUDIO (Pipewire Sink/Source & Volume)
    // ==========================================
    property bool audioReady: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00
    property string audioTheme: Config.options.sounds.theme
    property real audioValue: sink?.audio.volume ?? 0

    function friendlyDeviceName(node) {
        return (node?.nickname || node?.description || Translation.tr("Unknown"))
    }
    function appNodeDisplayName(node) {
        return (node?.properties?.["application.name"] || node?.description || node?.name || Translation.tr("Unknown"))
    }
    function correctType(node, isSink) {
        return (node?.isSink === isSink) && node?.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => {
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    signal sinkProtectionTriggered(string reason)

    function toggleAudioMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }
    function toggleMicMute() {
        if (source?.audio) source.audio.muted = !source.audio.muted
    }
    function incrementVolume() {
        if (!sink?.audio) return
        const currentVolume = sink.audio.volume
        const step = currentVolume < 0.1 ? 0.01 : 0.02
        sink.audio.volume = Math.min(1, sink.audio.volume + step)
    }
    function decrementVolume() {
        if (!sink?.audio) return
        const currentVolume = sink.audio.volume
        const step = currentVolume < 0.1 ? 0.01 : 0.02
        sink.audio.volume = Math.max(0, sink.audio.volume - step)
    }
    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node
    }
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node
    }

    PwObjectTracker {
        objects: [sink, source]
    }

    // Protection against sudden volume spikes
    Connections {
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return
            const newVolume = sink.audio.volume
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false
                lastVolume = 0
                return
            }
            if (!lastReady) {
                lastVolume = newVolume
                lastReady = true
                return
            }
            const volumeDiff = newVolume - lastVolume
            if (volumeDiff > Config.options.audio.protection.maxJump) {
                sink.audio.volume = lastVolume
                root.sinkProtectionTriggered(Translation.tr("Prevented sudden volume spike (%1%)").arg(Math.round(volumeDiff * 100)))
            } else {
                lastVolume = newVolume
            }
        }
    }

    // ==========================================
    // 2. BLUETOOTH (BlueZ Adapter & Devices)
    // ==========================================
    readonly property bool bluetoothAvailable: Bluetooth.adapters.values.length > 0
    readonly property bool bluetoothEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice bluetoothFirstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int bluetoothActiveDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool bluetoothConnected: Bluetooth.devices.values.some(d => d.connected)

    function bluetoothSortFunction(a, b) {
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/
        const aIsMac = macRegex.test(a.name)
        const bIsMac = macRegex.test(b.name)
        if (aIsMac !== bIsMac) return aIsMac ? 1 : -1
        return a.name.localeCompare(b.name)
    }
    property list<var> bluetoothConnectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(bluetoothSortFunction)
    property list<var> bluetoothPairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(bluetoothSortFunction)
    property list<var> bluetoothUnpairedDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected).sort(bluetoothSortFunction)
    property list<var> bluetoothFriendlyDeviceList: [
        ...bluetoothConnectedDevices,
        ...bluetoothPairedButNotConnectedDevices,
        ...bluetoothUnpairedDevices
    ]

    // ==========================================
    // 3. NETWORK (NetworkManager & Wi-Fi)
    // ==========================================
    property bool wifi: true
    property bool ethernet: false
    property bool wifiEnabled: true
    property bool wifiScanning: false
    property bool wifiConnecting: netConnectProc.running
    property WifiAccessPoint wifiConnectTarget: null
    property list<WifiAccessPoint> wifiNetworks: []
    property var savedSsids: []
    readonly property WifiAccessPoint activeWifi: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active) return -1
        if (!a.active && b.active) return 1
        return b.strength - a.strength
    })
    property string wifiStatus: "disconnected"
    readonly property string networkName: activeWifi?.ssid ?? (ethernet ? Translation.tr("Ethernet") : "")
    readonly property int networkStrength: activeWifi?.strength ?? 0
    readonly property string networkMaterialSymbol: root.ethernet
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                root.networkStrength > 83 ? "signal_wifi_4_bar" :
                root.networkStrength > 67 ? "network_wifi" :
                root.networkStrength > 50 ? "network_wifi_3_bar" :
                root.networkStrength > 33 ? "network_wifi_2_bar" :
                root.networkStrength > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    function enableWifi(enabled = true) {
        const cmd = enabled ? "on" : "off"
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd])
        rescanTimer.restart()
    }
    function toggleWifi() {
        enableWifi(!wifiEnabled)
    }
    function rescanWifi() {
        wifiScanning = true
        rescanProc.exec(["bash", "-c", "LC_ALL=C nmcli dev wifi rescan 2>/dev/null || true"])
        rescanTimer.restart()
    }
    function connectToWifiNetwork(accessPoint) {
        if (!accessPoint || !accessPoint.ssid || accessPoint.active) return
        root.wifiConnectTarget = accessPoint
        if (accessPoint.isSaved) {
            const ssidEscaped = accessPoint.ssid.replace(/'/g, "'\\''")
            netConnectProc.exec(["bash", "-c", `LC_ALL=C nmcli dev wifi connect '${ssidEscaped}'`])
        } else if (accessPoint.isSecure) {
            accessPoint.askingPassword = true
        } else {
            const ssidEscaped = accessPoint.ssid.replace(/'/g, "'\\''")
            netConnectProc.exec(["bash", "-c", `LC_ALL=C nmcli dev wifi connect '${ssidEscaped}'`])
        }
    }
    function disconnectWifiNetwork() {
        if (activeWifi && activeWifi.ssid) {
            const ssidEscaped = activeWifi.ssid.replace(/'/g, "'\\''")
            disconnectProc.exec(["bash", "-c", `LC_ALL=C nmcli connection down '${ssidEscaped}'`])
        }
    }
    function forgetWifiNetwork(accessPoint) {
        if (!accessPoint || !accessPoint.ssid) return
        const ssidEscaped = accessPoint.ssid.replace(/'/g, "'\\''")
        forgetProc.exec(["bash", "-c", `LC_ALL=C nmcli connection delete '${ssidEscaped}'`])
    }
    function changeWifiPassword(network, password) {
        if (!network || !network.ssid) return
        network.askingPassword = false
        const ssidEscaped = network.ssid.replace(/'/g, "'\\''")
        const passwordEscaped = password.replace(/'/g, "'\\''")
        netConnectProc.exec(["bash", "-c", `LC_ALL=C nmcli dev wifi connect '${ssidEscaped}' password '${passwordEscaped}'`])
    }

    Timer {
        id: rescanTimer
        interval: wifiScanning ? 2000 : 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiRadioProc.exec(["bash", "-c", "LC_ALL=C nmcli radio wifi"])
            netStatusProc.exec(["bash", "-c", "LC_ALL=C nmcli -t -f TYPE,STATE dev"])
            savedConnProc.exec(["bash", "-c", "LC_ALL=C nmcli -t -f NAME connection show"])
            if (root.wifiEnabled) {
                wifiListProc.exec(["bash", "-c", "LC_ALL=C nmcli -t -f ACTIVE,SSID,BSSID,SIGNAL,SECURITY dev wifi list"])
            }
        }
    }

    Process {
        id: wifiRadioProc
        stdout: StdioCollector {
            onStreamFinished: {
                const status = text.trim()
                root.wifiEnabled = (status === "enabled")
                if (!root.wifiEnabled) root.wifiStatus = "disabled"
            }
        }
    }

    Process {
        id: netStatusProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let ethActive = false
                let wifiState = "disconnected"
                for (const line of lines) {
                    const parts = line.trim().split(":")
                    if (parts.length >= 2) {
                        if (parts[0] === "ethernet" && parts[1] === "connected") ethActive = true
                        if (parts[0] === "wifi") wifiState = parts[1]
                    }
                }
                root.ethernet = ethActive
                if (!root.wifiEnabled) {
                    root.wifiStatus = "disabled"
                } else if (wifiState === "connected") {
                    root.wifiStatus = "connected"
                } else if (wifiState.startsWith("connect")) {
                    root.wifiStatus = "connecting"
                } else {
                    root.wifiStatus = "disconnected"
                }
            }
        }
    }

    Process {
        id: savedConnProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedSsids = text.trim().split("\n").map(s => s.trim()).filter(s => s.length > 0)
            }
        }
    }

    Process {
        id: wifiListProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiScanning = false
                const lines = text.trim().split("\n")
                const parsedNetworks = []
                const seenSsids = new Set()
                for (const line of lines) {
                    if (!line.trim()) continue
                    const cleanLine = line.replace(/\\:/g, "__COLON__")
                    const parts = cleanLine.split(":")
                    if (parts.length >= 5) {
                        const active = (parts[0].trim() === "yes")
                        const ssid = parts[1].trim()
                        const bssid = parts[2].replace(/__COLON__/g, ":").trim()
                        const strength = parseInt(parts[3].trim()) || 0
                        const security = parts[4].replace(/__COLON__/g, ":").trim()
                        if (!ssid) continue
                        if (seenSsids.has(ssid)) continue
                        seenSsids.add(ssid)
                        const component = Qt.createComponent("network/WifiAccessPoint.qml")
                        if (component.status === Component.Ready) {
                            const ap = component.createObject(root, {
                                lastIpcObject: {
                                    active: active,
                                    ssid: ssid,
                                    bssid: bssid,
                                    strength: strength,
                                    frequency: 2400,
                                    security: security
                                }
                            })
                            parsedNetworks.push(ap)
                        }
                    }
                }
                root.wifiNetworks = parsedNetworks
            }
        }
    }

    Process {
        id: enableWifiProc
        onExited: rescanTimer.restart()
    }
    Process {
        id: disconnectProc
        onExited: rescanTimer.restart()
    }
    Process {
        id: forgetProc
        onExited: rescanTimer.restart()
    }
    Process {
        id: netConnectProc
        onExited: rescanTimer.restart()
    }
    Process {
        id: rescanProc
        onExited: {
            wifiListProc.exec(["bash", "-c", "LC_ALL=C nmcli -t -f ACTIVE,SSID,BSSID,SIGNAL,SECURITY dev wifi list"])
        }
    }

    // ==========================================
    // 4. BRIGHTNESS — Moved to Brightness.qml (per-monitor DDC/CI + backlight)
    // ==========================================
    // Legacy property kept for any remaining direct references
    property real brightness: Brightness.brightness
    function setBrightness(val) { Brightness.getMonitorForFocused()?.setBrightness(val); }

    // ==========================================
    // 5. BATTERY (Power & Status)
    // ==========================================
    property int batteryPercentage: 100
    property string batteryState: "discharging"
    property bool isCharging: false
    property bool isPluggedIn: true
}
