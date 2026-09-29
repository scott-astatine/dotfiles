import "../../core"
import "../../components"
import "../../core"
import "../../services"
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        // Time Text
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
            Layout.alignment: Qt.AlignVCenter
        }

        // Bullet Separator
        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            text: "•"
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            Layout.rightMargin: 2
        }

        // Calendar Icon
        MaterialSymbol {
            visible: root.showDate
            text: "calendar_today"
            iconSize: Appearance.font.pixelSize.small
            color: Appearance.m3colors.m3primary
            fill: 1
            Layout.alignment: Qt.AlignVCenter
        }

        // Date Text
        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.longDate
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
