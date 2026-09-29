pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../core"

/**
 * Per-monitor brightness service. Supports both brightnessctl (laptop backlight)
 * and ddcutil (external monitors via DDC/CI).
 */
Singleton {
    id: root

    property var ddcMonitors: []
    readonly property list<BrightnessMonitor> monitors: Quickshell.screens.map(screen => monitorComp.createObject(root, {
        screen
    }))

    // Legacy property for backwards compat (maps to focused monitor's brightness)
    property real brightness: {
        const focused = getMonitorForFocused();
        return focused ? focused.brightness : 0.5;
    }

    signal userBrightnessChanged()

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.screen === screen) ?? null;
    }

    function getMonitorForFocused(): var {
        const focusedName = Hyprland.focusedMonitor?.name;
        if (!focusedName) return monitors[0] ?? null;
        return monitors.find(m => m.screen.name === focusedName) ?? monitors[0] ?? null;
    }

    function increaseBrightness(step = 0.05): void {
        const monitor = getMonitorForFocused();
        if (monitor) {
            monitor.setBrightness(monitor.brightness + step);
            root.userBrightnessChanged();
        }
    }

    function decreaseBrightness(step = 0.05): void {
        const monitor = getMonitorForFocused();
        if (monitor) {
            monitor.setBrightness(monitor.brightness - step);
            root.userBrightnessChanged();
        }
    }

    // Per-screen variants (called from bar/corners with explicit screen name)
    function increaseBrightnessForScreen(screenName, step = 0.05) {
        const monitor = monitors.find(m => m.screen.name === screenName);
        if (monitor) {
            monitor.setBrightness(monitor.brightness + step);
            root.userBrightnessChanged();
        }
    }

    function decreaseBrightnessForScreen(screenName, step = 0.05) {
        const monitor = monitors.find(m => m.screen.name === screenName);
        if (monitor) {
            monitor.setBrightness(monitor.brightness - step);
            root.userBrightnessChanged();
        }
    }

    function getBrightnessForScreen(screenName) {
        const monitor = monitors.find(m => m.screen.name === screenName);
        return monitor ? monitor.brightness : 0.5;
    }

    // --- DDC detection on startup ---
    onMonitorsChanged: {
        ddcMonitors = [];
        ddcProc.running = true;
    }

    function initializeMonitor(i: int): void {
        if (i >= monitors.length)
            return;
        monitors[i].initialize();
    }

    function ddcDetectFinished(): void {
        initializeMonitor(0);
    }

    Process {
        id: ddcProc
        command: ["ddcutil", "detect", "--brief"]
        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: data => {
                if (data.startsWith("Display ")) {
                    const lines = data.split("\n").map(l => l.trim());
                    const connectorLine = lines.find(l => l.startsWith("DRM connector:"));
                    const busLine = lines.find(l => l.startsWith("I2C bus:"));
                    if (connectorLine && busLine) {
                        root.ddcMonitors.push({
                            name: connectorLine.split("-").slice(1).join('-'),
                            busNum: busLine.split("/dev/i2c-")[1]
                        });
                    }
                }
            }
        }
        onExited: root.ddcDetectFinished()
    }

    Process {
        id: setProc
    }

    component BrightnessMonitor: QtObject {
        id: monitor

        required property ShellScreen screen
        property bool isDdc: false
        property string busNum: ""
        property int rawMaxBrightness: 100
        property real brightness: 0.5
        property bool ready: false

        onBrightnessChanged: {
            if (!monitor.ready) return;
            root.brightnessChanged();
        }

        function initialize() {
            monitor.ready = false;
            // Check if ddcutil detected this screen's connector
            const match = root.ddcMonitors.find(m =>
                m.name === screen.name &&
                !root.monitors.slice(0, root.monitors.indexOf(this)).some(mon => mon.busNum === m.busNum)
            );
            isDdc = !!match;
            busNum = match?.busNum ?? "";
            initProc.command = isDdc
                ? ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"]
                : ["sh", "-c", `echo "a b c $(brightnessctl g) $(brightnessctl m)"`];
            initProc.running = true;
        }

        readonly property Process initProc: Process {
            stdout: SplitParser {
                onRead: data => {
                    const [, , , current, max] = data.split(" ");
                    monitor.rawMaxBrightness = parseInt(max);
                    const parsed = parseInt(current) / monitor.rawMaxBrightness;
                    if (!isNaN(parsed))
                        monitor.brightness = parsed;
                    monitor.ready = true;
                }
            }
            onExited: (exitCode, exitStatus) => {
                root.initializeMonitor(root.monitors.indexOf(monitor) + 1);
            }
        }

        // Debounce timer for DDC monitors (I2C is slow, rapid changes cause issues)
        property var setTimer: Timer {
            interval: monitor.isDdc ? 300 : 0
            onTriggered: {
                syncBrightness();
            }
        }

        function syncBrightness() {
            const brightnessValue = Math.max(monitor.brightness, 0);
            if (isDdc) {
                const rawValueRounded = Math.max(Math.floor(brightnessValue * monitor.rawMaxBrightness), 1);
                setProc.exec(["ddcutil", "-b", busNum, "setvcp", "10", `${rawValueRounded}`]);
            } else {
                const valuePercentNumber = Math.floor(brightnessValue * 100);
                let valuePercent = `${valuePercentNumber}%`;
                if (valuePercentNumber == 0) valuePercent = "1"; // Prevent fully black
                setProc.exec(["brightnessctl", "--class", "backlight", "s", valuePercent, "--quiet"]);
            }
        }

        function setBrightness(value: real): void {
            value = Math.max(0, Math.min(1, value));
            monitor.brightness = value;
            if (isDdc)
                setTimer.restart();  // Debounce DDC
            else
                syncBrightness();    // Backlight is instant
        }
    }

    Component {
        id: monitorComp
        BrightnessMonitor {}
    }
}
