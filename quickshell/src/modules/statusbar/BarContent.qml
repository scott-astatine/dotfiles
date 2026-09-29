import "./weather"
import "../../components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../../services"
import "../../core"
import "../../services"
import "../../core"
import "../../core"
import "../../core/functions"

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border

        Behavior on color {
            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        Behavior on border.color {
            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
    }

    FocusedScrollMouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Brightness.decreaseBrightnessForScreen(screen?.name)
        onScrollUp: Brightness.increaseBrightnessForScreen(screen?.name)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }


        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 8

            RippleButton {
                id: distroLauncherButton
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.rounding.screenRounding
                buttonRadius: Appearance.rounding.full
                colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                implicitWidth: 30
                implicitHeight: 30
                onClicked: {
                    GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                }
                CustomIcon {
                    anchors.centerIn: parent
                    width: 19.5
                    height: 19.5
                    source: "arch-symbolic.svg"
                    colorize: true
                    color: Appearance.colors.colPrimary
                }
            }

            BarGroup {
                id: leftWorkspacesGroup
                Layout.alignment: Qt.AlignVCenter
                padding: workspacesWidget.widgetPadding

                Workspaces {
                    id: workspacesWidget
                    Layout.fillHeight: true
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onPressed: event => {
                            if (event.button === Qt.RightButton) {
                                GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                            }
                        }
                    }
                }
            }

            ActiveWindow {
                Layout.leftMargin: 4
                Layout.rightMargin: 8
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.useShortenedForm === 0
            }
        }
    }

    Row { // Middle section: Date & System Stats
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        BarGroup {
            id: centerGroup
            anchors.verticalCenter: parent.verticalCenter

            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.alignment: Qt.AlignVCenter
            }

            VerticalBarSeparator {
                visible: true
            }

            ClockWidget {
                showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                Layout.alignment: Qt.AlignVCenter
            }

            VerticalBarSeparator {
                visible: true
            }

            ResourcesRight {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    FocusedScrollMouseArea { // Right side | scroll to change volume
        id: barRightSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Audio.decrementVolume();
        onScrollUp: Audio.incrementVolume();
        onMovedAway: GlobalStates.osdVolumeOpen = false;
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }


        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 6
            layoutDirection: Qt.LeftToRight
            anchors.rightMargin: 6

            Item { Layout.fillWidth: true } // Spacer

            // Weather
            Loader {
                Layout.leftMargin: 2
                active: Config.options.bar.weather.enable

                sourceComponent: BarGroup {
                    WeatherBar {}
                }
            }

            BarGroup { // Media playback
                id: mediaGroup
                Layout.alignment: Qt.AlignVCenter
                visible: root.useShortenedForm < 2

                Media {
                    Layout.fillWidth: false
                }
            }

            SysTray {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: false
                Layout.fillHeight: true
                invertSide: Config?.options.bar.bottom
                showOverflowMenu: false
                showSeparator: false
            }

            BarGroup { // Battery, Wifi & Bluetooth
                id: statusGroup
                Layout.alignment: Qt.AlignVCenter

                BatteryIndicator {
                    visible: Battery.available
                    Layout.alignment: Qt.AlignVCenter
                }

                UtilButtons {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            RippleButton { // Right sidebar button
                id: rightSidebarButton

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: 4
                Layout.fillWidth: false

                implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
                implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

                buttonRadius: Appearance.rounding.full
                colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                toggled: GlobalStates.sidebarRightOpen
                property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                Behavior on colText {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                onPressed: {
                    GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                }

                RowLayout {
                    id: indicatorsRowLayout
                    anchors.centerIn: parent
                    property real realSpacing: 15
                    spacing: 0

                    Revealer {
                        reveal: Audio.sink?.audio?.muted ?? false
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        MaterialSymbol {
                            text: "volume_off"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                    Revealer {
                        reveal: Audio.source?.audio?.muted ?? false
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        MaterialSymbol {
                            text: "mic_off"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                    HyprlandXkbIndicator {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: indicatorsRowLayout.realSpacing
                        color: rightSidebarButton.colText
                    }
                    Revealer {
                        reveal: Notifications.silent || Notifications.unread > 0
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
                        implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        NotificationUnreadCount {
                            id: notificationUnreadCount
                        }
                    }
                    MaterialSymbol {
                        text: Network.materialSymbol
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: event => {
                                event.accepted = true;
                                GlobalStates.wifiPopupOpen = !GlobalStates.wifiPopupOpen;
                            }
                        }
                    }
                    MaterialSymbol {
                        Layout.leftMargin: indicatorsRowLayout.realSpacing
                        visible: BluetoothStatus.available
                        text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: event => {
                                event.accepted = true;
                                GlobalStates.bluetoothPopupOpen = !GlobalStates.bluetoothPopupOpen;
                            }
                        }
                    }
                }
            }
        }
    }
}
