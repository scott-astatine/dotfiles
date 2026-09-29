import "../../../../core"
import "../../../../components"
import "../../../../core/functions"
import "../../../../core"
import "../../../../services"
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property var device
    property bool expanded: false
    property int selectedSubButton: 0 // 0 = Connect/Disconnect, 1 = Forget

    implicitHeight: mainLayout.implicitHeight + verticalPadding * 2

    active: (root.device && root.device.connected) ? true : false
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
                text: Icons.getBluetoothDeviceMaterialSymbol(root.device && root.device.icon ? root.device.icon : "")
                color: (root.device && root.device.connected) ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: (root.device && root.device.name) ? root.device.name : Translation.tr("Unknown device")
                    textFormat: Text.PlainText
                }
                StyledText {
                    visible: (root.device && (root.device.connected || root.device.paired)) ? true : false
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: (root.device && root.device.connected) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    text: {
                        let statusText = (root.device && root.device.connected) ? Translation.tr("Connected") : Translation.tr("Paired");
                        if (root.device && root.device.batteryAvailable) {
                            statusText += " • " + Math.round(root.device.battery * 100) + "%";
                        }
                        return statusText;
                    }
                }
            }
            MaterialSymbol {
                visible: (root.device && (root.device.connected || root.device.paired)) ? true : false
                text: (root.device && root.device.connected) ? "check" : "bluetooth"
                iconSize: Appearance.font.pixelSize.larger
                color: (root.device && root.device.connected) ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            }
        }

        // Action Buttons Row (visible when item is current or expanded)
        RowLayout {
            id: actionButtonsRow
            visible: root.isCurrentItem || root.expanded
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
                text: (root.device && root.device.connected) ? Translation.tr("Disconnect") : Translation.tr("Connect")
                selected: root.isCurrentItem && root.selectedSubButton === 0
                colSelectedBg: Appearance.colors.colPrimary
                colSelectedText: Appearance.colors.colOnPrimary
                onClicked: {
                    if (root.device && root.device.connected) {
                        root.device.disconnect();
                    } else if (root.device) {
                        root.device.connect();
                    }
                }
            }

            // Forget Button (visible ONLY if device is paired or connected)
            ActionButton {
                id: forgetBtn
                visible: (root.device && (root.device.paired || root.device.connected)) ? true : false
                text: Translation.tr("Forget")
                selected: root.isCurrentItem && root.selectedSubButton === 1
                colSelectedBg: Appearance.colors.colError
                colSelectedText: Appearance.colors.colOnError
                onClicked: {
                    if (root.device) root.device.forget();
                }
            }
        }
    }
}
