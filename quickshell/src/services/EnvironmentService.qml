pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import "../components"
import Quickshell.Io
import QtQuick
import "../core"

/**
 * EnvironmentService: Unified domain service for ResourceUsage, SystemInfo, Weather, DateTime, Hyprsunset, Idle, and Privacy.
 */
Singleton {
    id: root

    // ==========================================
    // 1. RESOURCE USAGE (CPU / RAM / Swap / Temp)
    // ==========================================
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats
    property string gpuTemp: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB"
    }

    Timer {
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            fileMeminfo.reload()
            fileStat.reload()

            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }
                previousCpuStats = { total, idle }
            }

            // Update history arrays
            memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage].slice(-historyLength)
            swapUsageHistory = [...swapUsageHistory, swapUsedPercentage].slice(-historyLength)
            cpuUsageHistory = [...cpuUsageHistory, cpuUsage].slice(-historyLength)

            interval = Config.options?.resources?.updateInterval ?? 3000
        }
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }

    // ==========================================
    // 2. SYSTEM INFO (OS, Host, Uptime, Kernel)
    // ==========================================
    property string osName: "Linux"
    property string hostName: "Host"
    property string kernelVersion: ""
    property string uptime: ""

    Process {
        id: sysInfoProc
        running: true
        command: ["uname", "-sr"]
        stdout: SplitParser {
            onRead: data => root.kernelVersion = data.trim()
        }
    }

    // ==========================================
    // 3. DATE & TIME
    // ==========================================
    property date currentDate: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    // ==========================================
    // 4. WEATHER
    // ==========================================
    property string weatherTemp: "--°C"
    property string weatherDesc: "Clear"
    property string weatherIcon: "wb_sunny"
}
