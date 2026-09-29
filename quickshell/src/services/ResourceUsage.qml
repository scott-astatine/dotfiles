pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell

/**
 * Legacy ResourceUsage singleton wrapper forwarding to consolidated EnvironmentService.
 */
Singleton {
    id: root

    readonly property real memoryTotal: EnvironmentService.memoryTotal
    readonly property real memoryFree: EnvironmentService.memoryFree
    readonly property real memoryUsed: EnvironmentService.memoryUsed
    readonly property real memoryUsedPercentage: EnvironmentService.memoryUsedPercentage
    readonly property real swapTotal: EnvironmentService.swapTotal
    readonly property real swapFree: EnvironmentService.swapFree
    readonly property real swapUsed: EnvironmentService.swapUsed
    readonly property real swapUsedPercentage: EnvironmentService.swapUsedPercentage
    readonly property real cpuUsage: EnvironmentService.cpuUsage
    readonly property string gpuTemp: EnvironmentService.gpuTemp
    readonly property var cpuUsageHistory: EnvironmentService.cpuUsageHistory
    readonly property var memoryUsageHistory: EnvironmentService.memoryUsageHistory
    readonly property var swapUsageHistory: EnvironmentService.swapUsageHistory
    function kbToGbString(kb) { return EnvironmentService.kbToGbString(kb); }
}
