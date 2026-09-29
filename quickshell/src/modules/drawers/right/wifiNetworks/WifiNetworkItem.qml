import "../../../../core"
import "../../../../components"
import "../../../../core/functions"
import "../../../../core"
import "../../../../services"
import "../../../../services/network"
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property WifiAccessPoint wifiNetwork
    enabled: !(Network.wifiConnectTarget === root.wifiNetwork && root.wifiNetwork && !root.wifiNetwork.active)

    property bool expanded: false
    property int selectedSubButton: 0 // 0 = Connect/Disconnect, 1 = Forget
    property int selectedPasswordSubButton: 1 // 0 = Cancel, 1 = Connect

    implicitHeight: mainLayout.implicitHeight + verticalPadding * 2

    active: (root.wifiNetwork && (root.wifiNetwork.askingPassword || root.wifiNetwork.active)) ? true : false
    pointingHandCursor: true

    onClicked: {
        expanded = !expanded;
    }

    // Custom Pill Action Button with Crisp Selection Highlight
    component ActionButton: Rectangle {
        id: btnRoot
        property string text
        property bool selected: false
        property color colSelectedBg: Appearance.colors.colPrimary
        property color colSelectedText: Appearance.colors.colOnPrimary
        property color colNormalBg: Qt.rgba(Appearance.colors.colLayer3.r, Appearance.colors.colLayer3.g, Appearance.colors.colLayer3.b, Appearance.colors.colLayer3.a * 0.6)
        property color colNormalText: Appearance.colors.colOnLayer0
        signal clicked()

        implicitHeight: 30
        implicitWidth: Math.max(72, btnText.implicitWidth + 24)
        radius: Appearance.rounding.full
        color: selected ? colSelectedBg : colNormalBg
        border.width: selected ? 2 : 1
        border.color: selected ? colSelectedBg : Appearance.colors.colLayer0Border

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        StyledText {
            id: btnText
            anchors.centerIn: parent
            text: btnRoot.text
            font.pixelSize: Appearance.font.pixelSize.small
            font.bold: btnRoot.selected
            color: btnRoot.selected ? btnRoot.colSelectedText : btnRoot.colNormalText
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btnRoot.clicked()
        }
    }

    ColumnLayout {
        id: mainLayout
        width: root.width - (root.horizontalPadding * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.verticalPadding
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                property int strength: (root.wifiNetwork && root.wifiNetwork.strength !== undefined) ? root.wifiNetwork.strength : 0
                text: strength > 80 ? "signal_wifi_4_bar" : strength > 60 ? "network_wifi_3_bar" : strength > 40 ? "network_wifi_2_bar" : strength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
                color: (root.wifiNetwork && root.wifiNetwork.active) ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: (root.wifiNetwork && root.wifiNetwork.ssid) ? root.wifiNetwork.ssid : Translation.tr("Unknown")
                    textFormat: Text.PlainText
                }
                StyledText {
                    visible: (root.wifiNetwork && (root.wifiNetwork.active || root.wifiNetwork.isSaved)) ? true : false
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: (root.wifiNetwork && root.wifiNetwork.active) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    text: (root.wifiNetwork && root.wifiNetwork.active) ? Translation.tr("Connected") : Translation.tr("Saved")
                }
            }
            MaterialSymbol {
                visible: (root.wifiNetwork && (root.wifiNetwork.isSecure || root.wifiNetwork.active)) ? true : false
                text: (root.wifiNetwork && root.wifiNetwork.active) ? "check" : Network.wifiConnectTarget === root.wifiNetwork ? "settings_ethernet" : "lock"
                iconSize: Appearance.font.pixelSize.larger
                color: (root.wifiNetwork && root.wifiNetwork.active) ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            }
        }

        // Action Buttons Row (visible ONLY when askingPassword is false and item is selected/expanded)
        RowLayout {
            id: actionButtonsRow
            visible: (root.isCurrentItem || root.expanded) && !(root.wifiNetwork && root.wifiNetwork.askingPassword)
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.rightMargin: 4
            Layout.bottomMargin: 2
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            // Connect / Disconnect Primary Button
            ActionButton {
                id: primaryBtn
                text: (root.wifiNetwork && root.wifiNetwork.active) ? Translation.tr("Disconnect") : Translation.tr("Connect")
                selected: root.isCurrentItem && root.selectedSubButton === 0
                colSelectedBg: Appearance.colors.colPrimary
                colSelectedText: Appearance.colors.colOnPrimary
                onClicked: {
                    if (root.wifiNetwork && root.wifiNetwork.active) {
                        Network.disconnectWifiNetwork();
                    } else {
                        root.wifiNetwork.askingPassword = false;
                        Network.connectToWifiNetwork(root.wifiNetwork);
                    }
                }
            }

            // Forget Button (visible ONLY if network is saved or active)
            ActionButton {
                id: forgetBtn
                visible: (root.wifiNetwork && (root.wifiNetwork.isSaved || root.wifiNetwork.active)) ? true : false
                text: Translation.tr("Forget")
                selected: root.isCurrentItem && root.selectedSubButton === 1
                colSelectedBg: Appearance.colors.colError
                colSelectedText: Appearance.colors.colOnError
                onClicked: {
                    Network.forgetWifiNetwork(root.wifiNetwork);
                }
            }
        }

        // Password Prompt
        ColumnLayout {
            id: passwordPrompt
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: (root.wifiNetwork && root.wifiNetwork.askingPassword) ? true : false

            onVisibleChanged: {
                if (visible) {
                    passwordFocusTimer.restart();
                }
            }

            Timer {
                id: passwordFocusTimer
                interval: 50
                onTriggered: {
                    passwordField.forceActiveFocus();
                }
            }

            MaterialTextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Password")
                focus: true

                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData

                onAccepted: {
                    if (root.wifiNetwork && passwordField.text.length > 0) {
                        Network.changePassword(root.wifiNetwork, passwordField.text);
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.wifiNetwork.askingPassword = false;
                        event.accepted = true;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    id: pwdCancelBtn
                    text: Translation.tr("Cancel")
                    selected: root.selectedPasswordSubButton === 0
                    colSelectedBg: Appearance.colors.colLayer2
                    colSelectedText: Appearance.colors.colOnLayer0
                    onClicked: {
                        root.wifiNetwork.askingPassword = false;
                    }
                }

                ActionButton {
                    id: pwdConnectBtn
                    text: Translation.tr("Connect")
                    selected: root.selectedPasswordSubButton === 1
                    colSelectedBg: Appearance.colors.colPrimary
                    colSelectedText: Appearance.colors.colOnPrimary
                    onClicked: {
                        if (root.wifiNetwork && passwordField.text.length > 0) {
                            Network.changePassword(root.wifiNetwork, passwordField.text);
                        }
                    }
                }
            }
        }
    }
}
