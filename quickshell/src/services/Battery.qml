pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell
import Quickshell.Services.UPower
import "../core"

/**
 * Battery service managing UPower device properties and notifications.
 */
Singleton {
    id: root

    property bool available: UPower.displayDevice?.isLaptopBattery ?? false
    property var chargeState: UPower.displayDevice?.state ?? 0
    property bool isCharging: chargeState === UPowerDeviceState.Charging || chargeState === 1
    property bool isPluggedIn: isCharging || chargeState === UPowerDeviceState.PendingCharge || chargeState === UPowerDeviceState.FullyCharged || chargeState === 4 || chargeState === 5
    property real percentage: UPower.displayDevice?.percentage ?? 1
    readonly property bool allowAutomaticSuspend: Config.options.battery?.automaticSuspend ?? false
    readonly property bool soundEnabled: Config.options.sounds?.battery ?? false

    property bool isLow: available && (percentage <= (Config.options.battery?.low ?? 20) / 100)
    property bool isCritical: available && (percentage <= (Config.options.battery?.critical ?? 10) / 100)
    property bool isSuspending: available && (percentage <= (Config.options.battery?.suspend ?? 5) / 100)
    property bool isFull: available && (percentage >= (Config.options.battery?.full ?? 95) / 100)

    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging
    property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging
    property bool isFullAndCharging: isFull && isCharging

    property real energyRate: UPower.displayDevice?.changeRate ?? 0
    property real timeToEmpty: UPower.displayDevice?.timeToEmpty ?? 0
    property real timeToFull: UPower.displayDevice?.timeToFull ?? 0

    property real health: (function() {
        if (!UPower.devices) return 100;
        const devList = UPower.devices.values;
        for (let i = 0; i < devList.length; ++i) {
            const dev = devList[i];
            if (dev.isLaptopBattery && dev.healthSupported) {
                const health = dev.healthPercentage;
                if (health === 0) {
                    return 0.01;
                } else if (health < 1) {
                    return health * 100;
                } else {
                    return health;
                }
            }
        }
        return 100;
    })()

    onIsLowAndNotChargingChanged: {
        if (!root.available || !isLowAndNotCharging) return;
        Quickshell.execDetached([
            "notify-send", 
            Translation.tr("Low battery"), 
            Translation.tr("Consider plugging in your device"), 
            "-u", "critical",
            "-a", "Shell",
            "--hint=int:transient:1",
        ]);
        if (root.soundEnabled) Audio.playSystemSound("dialog-warning");
    }

    onIsCriticalAndNotChargingChanged: {
        if (!root.available || !isCriticalAndNotCharging) return;
        Quickshell.execDetached([
            "notify-send", 
            Translation.tr("Critically low battery"), 
            Translation.tr("Please charge!\nAutomatic suspend triggers at %1%").arg(Config.options.battery?.suspend ?? 5), 
            "-u", "critical",
            "-a", "Shell",
            "--hint=int:transient:1",
        ]);
        if (root.soundEnabled) Audio.playSystemSound("suspend-error");
    }

    onIsSuspendingAndNotChargingChanged: {
        if (root.available && isSuspendingAndNotCharging) {
            Quickshell.execDetached(["bash", "-c", `systemctl suspend || loginctl suspend`]);
        }
    }

    onIsFullAndChargingChanged: {
        if (!root.available || !isFullAndCharging) return;
        Quickshell.execDetached([
            "notify-send",
            Translation.tr("Battery full"),
            Translation.tr("Please unplug the charger"),
            "-a", "Shell",
            "--hint=int:transient:1",
        ]);
        if (root.soundEnabled) Audio.playSystemSound("complete");
    }

    onIsPluggedInChanged: {
        if (!root.available || !root.soundEnabled) return;
        if (isPluggedIn) {
            Audio.playSystemSound("power-plug");
        } else {
            Audio.playSystemSound("power-unplug");
        }
    }
}
