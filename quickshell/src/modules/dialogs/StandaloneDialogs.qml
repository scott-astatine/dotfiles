import "../../services"
import "../../components"
import "../../core"
import "../../services"
import "../../services/network"
import "../../core"
import "../../core"
import "../drawers/right/wifiNetworks"
import "../drawers/right/bluetoothDevices"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth

Scope {
    id: root

    PanelWindow {
        id: wifiWindow
        visible: GlobalStates.wifiPopupOpen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell:dialog"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.wifiPopupOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.wifiPopupOpen ? wifiFocusScope : null
        }

        onVisibleChanged: {
            if (visible) {
                Network.enableWifi();
                Network.rescanWifi();
                GlobalFocusGrab.addDismissable(wifiWindow);
            } else {
                GlobalFocusGrab.removeDismissable(wifiWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.wifiPopupOpen = false;
            }
        }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.wifiPopupOpen = false
            }

            FocusScope {
                id: wifiFocusScope
                anchors.centerIn: parent
                width: 400
                height: 640
                focus: true

                Component.onCompleted: wifiSearchInput.forceActiveFocus()

                Rectangle {
                    id: wifiDialogCard
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    MouseArea {
                        anchors.fill: parent
                        // Intercept clicks inside card
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol {
                                iconSize: 22
                                text: "wifi"
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                font.pixelSize: Appearance.font.pixelSize.title
                                text: Translation.tr("Wi-Fi Networks")
                                color: Appearance.colors.colOnLayer0
                            }
                            MaterialSymbol {
                                iconSize: 20
                                text: "close"
                                color: Appearance.colors.colOnLayer0
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalStates.wifiPopupOpen = false
                                }
                            }
                        }

                        // Sleek Custom Search Bar
                        Rectangle {
                            id: wifiSearchContainer
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colLayer1
                            border.width: wifiSearchInput.activeFocus ? 2 : 1
                            border.color: wifiSearchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                            Behavior on border.color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                MaterialSymbol {
                                    iconSize: 18
                                    text: "search"
                                    color: wifiSearchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                }

                                TextField {
                                    id: wifiSearchInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    focus: true
                                    placeholderText: Translation.tr("Search Wi-Fi networks...")
                                    placeholderTextColor: Appearance.colors.colSubtext
                                    color: Appearance.colors.colOnLayer1
                                    font {
                                        family: Appearance.font.family.main
                                        pixelSize: Appearance.font.pixelSize.small
                                    }
                                    background: null
                                    verticalAlignment: TextInput.AlignVCenter

                                    onTextChanged: {
                                        wifiListView.currentIndex = 0;
                                    }

                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Escape) {
                                            GlobalStates.wifiPopupOpen = false;
                                            event.accepted = true;
                                        } else if ((event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) || event.key === Qt.Key_Down) {
                                            wifiListView.forceActiveFocus();
                                            wifiListView.currentIndex = 0;
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (wifiListView.currentItem) {
                                                wifiListView.currentItem.clicked();
                                            }
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Tab) {
                                            wifiListView.forceActiveFocus();
                                            event.accepted = true;
                                        }
                                    }
                                }

                                MaterialSymbol {
                                    visible: wifiSearchInput.text.length > 0
                                    iconSize: 18
                                    text: "cancel"
                                    color: Appearance.colors.colSubtext
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            wifiSearchInput.text = "";
                                            wifiSearchInput.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }

                        StyledIndeterminateProgressBar {
                            visible: Network.wifiScanning
                            Layout.fillWidth: true
                        }

                        // List of filtered networks
                        ListView {
                            id: wifiListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            focus: true

                            currentIndex: 0
                            onCountChanged: {
                                if (currentIndex < 0 && count > 0) currentIndex = 0;
                            }
                            keyNavigationEnabled: true
                            highlightFollowsCurrentItem: true

                            model: ScriptModel {
                                values: (Network.friendlyWifiNetworks || []).filter(net => {
                                    if (!wifiSearchInput.text.trim()) return true;
                                    const ssid = (net && net.ssid ? net.ssid : "").toLowerCase();
                                    return ssid.includes(wifiSearchInput.text.trim().toLowerCase());
                                })
                            }

                            delegate: WifiNetworkItem {
                                required property WifiAccessPoint modelData
                                required property int index
                                wifiNetwork: modelData
                                isCurrentItem: (wifiListView.currentIndex <= 0 ? index === 0 : wifiListView.currentIndex === index)
                                width: wifiListView.width
                            }

                            Keys.onPressed: (event) => {
                                const item = wifiListView.currentItem;
                                if (item && item.wifiNetwork && item.wifiNetwork.askingPassword) {
                                    if (event.key === Qt.Key_Escape) {
                                        item.wifiNetwork.askingPassword = false;
                                        event.accepted = true;
                                    }
                                    return;
                                }

                                if (event.key === Qt.Key_Escape) {
                                    GlobalStates.wifiPopupOpen = false;
                                    event.accepted = true;
                                } else if ((event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) || event.key === Qt.Key_Down) {
                                    wifiListView.incrementCurrentIndex();
                                    if (wifiListView.currentItem) {
                                        wifiListView.currentItem.selectedSubButton = 0;
                                    }
                                    event.accepted = true;
                                } else if ((event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P) || event.key === Qt.Key_Up) {
                                    if (wifiListView.currentIndex === 0) {
                                        wifiSearchInput.forceActiveFocus();
                                    } else {
                                        wifiListView.decrementCurrentIndex();
                                        if (wifiListView.currentItem) {
                                            wifiListView.currentItem.selectedSubButton = 0;
                                        }
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                    if (item) {
                                        if (!item.expanded && !(item.wifiNetwork && item.wifiNetwork.askingPassword)) {
                                            item.expanded = true;
                                        } else {
                                            if (item.selectedSubButton === 0) {
                                                if (item.wifiNetwork && item.wifiNetwork.active) {
                                                    Network.disconnectWifiNetwork();
                                                } else {
                                                    item.wifiNetwork.askingPassword = false;
                                                    Network.connectToWifiNetwork(item.wifiNetwork);
                                                }
                                            } else if (item.selectedSubButton === 1) {
                                                Network.forgetWifiNetwork(item.wifiNetwork);
                                            }
                                        }
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                    if (item && item.wifiNetwork && (item.wifiNetwork.isSaved || item.wifiNetwork.active)) {
                                        if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) {
                                            item.selectedSubButton = (item.selectedSubButton === 0) ? 1 : 0;
                                        } else {
                                            item.selectedSubButton = (item.selectedSubButton === 1) ? 0 : 1;
                                        }
                                    } else if (item) {
                                        item.selectedSubButton = 0;
                                    }
                                    event.accepted = true;
                                }
                            }
                        }

                        // Hint Footer
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: Translation.tr("Type to filter • C-n/C-p to navigate • Enter to connect • ESC to exit")
                        }
                    }
                }
            }
        }

    PanelWindow {
        id: btWindow
        visible: GlobalStates.bluetoothPopupOpen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell:dialog"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.bluetoothPopupOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.bluetoothPopupOpen ? btFocusScope : null
        }

        onVisibleChanged: {
            if (visible) {
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = true;
                    Bluetooth.defaultAdapter.discovering = true;
                }
                GlobalFocusGrab.addDismissable(btWindow);
            } else {
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.discovering = false;
                }
                GlobalFocusGrab.removeDismissable(btWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.bluetoothPopupOpen = false;
            }
        }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.bluetoothPopupOpen = false
            }

            FocusScope {
                id: btFocusScope
                anchors.centerIn: parent
                width: 400
                height: 640
                focus: true

                Component.onCompleted: btSearchInput.forceActiveFocus()

                Rectangle {
                    id: btDialogCard
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    MouseArea {
                        anchors.fill: parent
                        // Intercept clicks inside card
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol {
                                iconSize: 22
                                text: "bluetooth"
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                font.pixelSize: Appearance.font.pixelSize.title
                                text: Translation.tr("Bluetooth Devices")
                                color: Appearance.colors.colOnLayer0
                            }
                            MaterialSymbol {
                                iconSize: 20
                                text: "close"
                                color: Appearance.colors.colOnLayer0
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalStates.bluetoothPopupOpen = false
                                }
                            }
                        }

                        // Sleek Custom Search Bar
                        Rectangle {
                            id: btSearchContainer
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colLayer1
                            border.width: btSearchInput.activeFocus ? 2 : 1
                            border.color: btSearchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                            Behavior on border.color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                MaterialSymbol {
                                    iconSize: 18
                                    text: "search"
                                    color: btSearchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                }

                                TextField {
                                    id: btSearchInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    focus: true
                                    placeholderText: Translation.tr("Search Bluetooth devices...")
                                    placeholderTextColor: Appearance.colors.colSubtext
                                    color: Appearance.colors.colOnLayer1
                                    font {
                                        family: Appearance.font.family.main
                                        pixelSize: Appearance.font.pixelSize.small
                                    }
                                    background: null
                                    verticalAlignment: TextInput.AlignVCenter

                                    onTextChanged: {
                                        btListView.currentIndex = 0;
                                    }

                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Escape) {
                                            GlobalStates.bluetoothPopupOpen = false;
                                            event.accepted = true;
                                        } else if ((event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) || event.key === Qt.Key_Down) {
                                            btListView.forceActiveFocus();
                                            btListView.currentIndex = 0;
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (btListView.currentItem) {
                                                btListView.currentItem.clicked();
                                            }
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Tab) {
                                            btListView.forceActiveFocus();
                                            event.accepted = true;
                                        }
                                    }
                                }

                                MaterialSymbol {
                                    visible: btSearchInput.text.length > 0
                                    iconSize: 18
                                    text: "cancel"
                                    color: Appearance.colors.colSubtext
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            btSearchInput.text = "";
                                            btSearchInput.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }

                        StyledIndeterminateProgressBar {
                            visible: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering) ? true : false
                            Layout.fillWidth: true
                        }

                        // List of filtered Bluetooth devices
                        ListView {
                            id: btListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            focus: true

                            currentIndex: 0
                            onCountChanged: {
                                if (currentIndex < 0 && count > 0) currentIndex = 0;
                            }
                            keyNavigationEnabled: true
                            highlightFollowsCurrentItem: true

                            model: ScriptModel {
                                values: (BluetoothStatus.friendlyDeviceList || []).filter(dev => {
                                    if (!btSearchInput.text.trim()) return true;
                                    const name = (dev && dev.name ? dev.name : "").toLowerCase();
                                    return name.includes(btSearchInput.text.trim().toLowerCase());
                                })
                            }

                            delegate: BluetoothDeviceItem {
                                required property BluetoothDevice modelData
                                required property int index
                                device: modelData
                                isCurrentItem: (btListView.currentIndex <= 0 ? index === 0 : btListView.currentIndex === index)
                                width: btListView.width
                            }

                            Keys.onPressed: (event) => {
                                const item = btListView.currentItem;
                                if (event.key === Qt.Key_Escape) {
                                    GlobalStates.bluetoothPopupOpen = false;
                                    event.accepted = true;
                                } else if ((event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) || event.key === Qt.Key_Down) {
                                    btListView.incrementCurrentIndex();
                                    if (btListView.currentItem) {
                                        btListView.currentItem.selectedSubButton = 0;
                                    }
                                    event.accepted = true;
                                } else if ((event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P) || event.key === Qt.Key_Up) {
                                    if (btListView.currentIndex === 0) {
                                        btSearchInput.forceActiveFocus();
                                    } else {
                                        btListView.decrementCurrentIndex();
                                        if (btListView.currentItem) {
                                            btListView.currentItem.selectedSubButton = 0;
                                        }
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                    if (item) {
                                        if (!item.expanded) {
                                            item.expanded = true;
                                        } else {
                                            if (item.selectedSubButton === 0) {
                                                if (item.device && item.device.connected) {
                                                    item.device.disconnect();
                                                } else if (item.device) {
                                                    item.device.connect();
                                                }
                                            } else if (item.selectedSubButton === 1) {
                                                if (item.device) item.device.forget();
                                            }
                                        }
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                    if (item && item.device && (item.device.paired || item.device.connected)) {
                                        if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) {
                                            item.selectedSubButton = (item.selectedSubButton === 0) ? 1 : 0;
                                        } else {
                                            item.selectedSubButton = (item.selectedSubButton === 1) ? 0 : 1;
                                        }
                                    } else if (item) {
                                        item.selectedSubButton = 0;
                                    }
                                    event.accepted = true;
                                }
                            }
                        }

                        // Hint Footer
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: Translation.tr("Type to filter • C-n/C-p to navigate • Enter to connect • ESC to exit")
                        }
                    }
                }
            }
        }
    }
