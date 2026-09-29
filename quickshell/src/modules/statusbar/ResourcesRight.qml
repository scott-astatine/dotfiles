import "../../core"
import "../../components"
import "../../core"
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // GPU temperature from nvidia-smi
    property string gpuTemp: "--"
    readonly property bool hasGpuTemp: gpuTemp !== "--" && gpuTemp !== "" && !isNaN(Number(gpuTemp))

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gpuTempProc.running = false
            gpuTempProc.running = true
        }
    }

    Process {
        id: gpuTempProc
        command: ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader"]
        stdout: StdioCollector {
            id: gpuStdout
            onStreamFinished: {
                const val = (gpuStdout.value?.trim() ?? "")
                if (val && !isNaN(Number(val))) {
                    root.gpuTemp = val
                } else {
                    root.gpuTemp = "--"
                }
            }
        }
    }

    function formatMemUsed() {
        return (ResourceUsage.memoryUsed / (1024 * 1024)).toFixed(1)
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // GPU Temp Section (only shown when GPU temp is available)
        RowLayout {
            visible: root.hasGpuTemp
            spacing: 4

            MaterialSymbol {
                text: "thermostat"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3secondary
                fill: 1
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: `${root.gpuTemp}°C`
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                text: "•"
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }
        }

        // RAM Icon
        MaterialSymbol {
            text: "memory"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.m3colors.m3primary
            fill: 1
            Layout.alignment: Qt.AlignVCenter
        }

        // RAM Value
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: `${root.formatMemUsed()} GiB`
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
