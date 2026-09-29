import "../../core"
import "../../components"
import "../../core"
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    // CPU temperature from thermal zone
    property string cpuTemp: "--"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            fileCpuTemp.reload()
            const rawTemp = fileCpuTemp.text().trim()
            if (rawTemp) {
                root.cpuTemp = Math.round(Number(rawTemp) / 1000).toString()
            }
        }
    }

    FileView { id: fileCpuTemp; path: "/sys/class/thermal/thermal_zone8/temp" }

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // CPU Icon
        MaterialSymbol {
            text: "planner_review"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.m3colors.m3primary
            fill: 1
            Layout.alignment: Qt.AlignVCenter
        }

        // CPU %
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
            Layout.alignment: Qt.AlignVCenter
        }

        // Separator
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            text: "•"
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            Layout.rightMargin: 2
        }

        // CPU Temp Icon
        MaterialSymbol {
            text: "device_thermostat"
            iconSize: Appearance.font.pixelSize.normal
            color: {
                const temp = Number(root.cpuTemp)
                return temp >= 85 ? Appearance.colors.colError : Appearance.m3colors.m3tertiary
            }
            fill: 1
            Layout.alignment: Qt.AlignVCenter
        }

        // CPU Temp Value
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: {
                const temp = Number(root.cpuTemp)
                return temp >= 85 ? Appearance.colors.colError : Appearance.colors.colOnLayer1
            }
            text: `${root.cpuTemp}°C`
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
