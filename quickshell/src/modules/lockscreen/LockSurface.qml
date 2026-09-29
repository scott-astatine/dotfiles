import QtQuick
import "../../components"
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import "../../services"
import "../../core"
import "../../services"
import "../../core"
import "../../core"
import "../../core/functions"
import "../../core/panels/lock"
import "../statusbar" as Bar
import "../media"
import Quickshell
import Quickshell.Services.SystemTray

MouseArea {
    id: root
    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower

    property int wallpaperRevision: 0

    function reloadWallpaper() {
        let path = (Config.options.background.wallpaperPath && Config.options.background.wallpaperPath.length > 0)
                ? Config.options.background.wallpaperPath
                : (Quickshell.env("HOME") + "/.cache/current_wallpaper.jpg");
        if (!path.startsWith("file://") && path.startsWith("/")) path = "file://" + path;
        // Cache-bust: append unique token so QML actually reloads the same-path image
        bgImage.source = "";
        bgImage.source = path + "?v=" + Date.now();
    }

    Connections {
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.reloadWallpaper();
        }
    }
    Connections {
        target: Wallpapers
        function onChanged() {
            root.reloadWallpaper();
        }
    }

    // No polling timer — wallpaper updates are event-driven via Wallpapers.onChanged()

    // Wallpaper background
    Image {
        id: bgImage
        anchors.fill: parent
        source: {
            let path = (Config.options.background.wallpaperPath && Config.options.background.wallpaperPath.length > 0)
                    ? Config.options.background.wallpaperPath
                    : (Quickshell.env("HOME") + "/.cache/current_wallpaper.jpg");
            if (!path.startsWith("file://") && path.startsWith("/")) path = "file://" + path;
            return path;
        }
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        
        Rectangle {
            anchors.fill: parent
            color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.45)
        }
    }

    // Force focus on entry
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    
    focus: true
    onVisibleChanged: {
        if (visible) focusTimer.restart();
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: root.forceFieldFocus()
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        forceFieldFocus();
    }

    // Toolbar appearing animation
    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }
    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Init
    Component.onCompleted: {
        forceFieldFocus();
        focusTimer.restart();
        toolbarScale = 1;
        toolbarOpacity = 1;
    }

    // Key presses
    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) { // Esc to clear
            root.context.currentText = "";
        } 
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        forceFieldFocus();
    }

    // RippleButton {
    //     anchors {
    //         top: parent.top
    //         left: parent.left
    //         leftMargin: 10
    //         topMargin: 10
    //     }
    //     implicitHeight: 40
    //     colBackground: Appearance.colors.colLayer2
    //     onClicked: {
    //         context.unlocked(LockContext.ActionEnum.Unlock);
    //         GlobalStates.screenLocked = false;
    //     }
    //     contentItem: StyledText {
    //         text: "[[ DEBUG BYPASS ]]"
    //     }
    // }

    // Center Hero Header Section (Glassmorphic & Modern Typography)
    ColumnLayout {
        id: heroContainer
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: parent.height * 0.08
        }
        spacing: 20
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        // Drop-Shadow Clock (Space Grotesk typography)
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: clockText.implicitWidth
            implicitHeight: clockText.implicitHeight

            // Shadow layer for contrast over any wallpaper
            StyledText {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 3
                anchors.verticalCenterOffset: 4
                text: DateTime.time
                font.family: "Space Grotesk"
                font.pixelSize: 145
                font.weight: Font.DemiBold
                color: ColorUtils.transparentize("#000000", 0.65)
            }

            // Main Clock Text
            StyledText {
                id: clockText
                anchors.centerIn: parent
                text: DateTime.time
                font.family: "Space Grotesk"
                font.pixelSize: 145
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
        }

        // Architectural Cyberpunk Date & Weather Badge
        Rectangle {
            id: dateBadge
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: dateContentRow.implicitWidth + 48
            implicitHeight: dateContentRow.implicitHeight + 22
            radius: 18
            color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.55)
            border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.45)
            border.width: 1.5

            StyledRectangularShadow {
                target: dateBadge
            }

            // Left Neon Accent Bar
            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: 7
                }
                width: 4
                radius: 2
                color: Appearance.colors.colPrimary
            }

            RowLayout {
                id: dateContentRow
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 4
                spacing: 16

                ColumnLayout {
                    spacing: 2

                    // Cyberpunk Header Tag: Pulsing Dot + Uppercase Day of Week
                    RowLayout {
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            text: Qt.locale().toString(DateTime.clock.date, "dddd").toUpperCase()
                            font.family: "Space Grotesk, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                            color: Appearance.colors.colPrimary
                        }
                    }

                    // Main Date String: MMMM d일 (e.g. 9월 8일) or full formatted date
                    StyledText {
                        text: Qt.locale().toString(DateTime.clock.date, "MMMM d일")
                        font.family: "Noto Serif CJK KR, Noto Sans CJK KR, Space Grotesk, sans-serif"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer0
                    }
                }

                // Vertical Glass Divider
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.6)
                }

                // Telemetry / Weather Sub-chip
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    RowLayout {
                        spacing: 6

                        MaterialSymbol {
                            text: Weather.currentIcon || "thermostat"
                            iconSize: 20
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            text: (Weather.currentTemp && Weather.currentTemp.length > 0) ? Weather.currentTemp : "SYNC"
                            font.family: "Space Grotesk, sans-serif"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                        }
                    }

                    StyledText {
                        text: Boolean(Weather.currentCondition && Weather.currentCondition !== "") ? Weather.currentCondition : Qt.locale().toString(DateTime.clock.date, "yyyy")
                        font.family: Appearance.font.family.main
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // MPRIS Crystal HUD (wide island with shard visualizer)
        Loader {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            active: Boolean(MprisController.activePlayer?.trackTitle)
            visible: active

            sourceComponent: PlayerControl {
                player: MprisController.activePlayer
                style: "crystal"
                implicitWidth: 760
                implicitHeight: 188
                radius: 36
            }
        }
    }

    // Floating Glass Command Deck (Sculpted single-piece command dock - 760px width matching Media Player)
    Rectangle {
        id: islandCommandDeck
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: heroContainer.bottom
            topMargin: 36
        }
        implicitWidth: 760
        implicitHeight: 56
        radius: 28

        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.45)
        border.color: passwordBox.activeFocus 
            ? Appearance.colors.colPrimary 
            : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.4)
        border.width: passwordBox.activeFocus ? 2 : 1.5

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        Behavior on border.color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
            }
        }

        StyledRectangularShadow {
            target: islandCommandDeck
        }

        RowLayout {
            id: deckContentRow
            anchors {
                fill: parent
                leftMargin: 20
                rightMargin: 20
            }
            spacing: 14

            // Segment A: User Identity Module
            RowLayout {
                spacing: 8

                MaterialSymbol {
                    fill: 1
                    text: "account_circle"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: SystemInfo.username
                    font.family: "Space Grotesk, sans-serif"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }
            }

            // Glass Divider A-B
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.6)
            }

            // Segment B: Biometric & Password Command Core
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    active: root.context.fingerprintsConfigured
                    visible: active

                    sourceComponent: MaterialSymbol {
                        fill: 1
                        text: "fingerprint"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colPrimary
                    }
                }

                ToolbarTextField {
                    id: passwordBox
                    Layout.fillWidth: true
                    placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

                    clip: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
                    selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

                    enabled: !root.context.unlockInProgress
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhNoAutoUppercase

                    onTextChanged: root.context.currentText = this.text
                    onAccepted: {
                        root.context.tryUnlock(ctrlHeld);
                    }
                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            passwordBox.text = root.context.currentText;
                        }
                    }

                    Keys.onPressed: event => {
                        root.context.resetClearTimer();
                    }
                    
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: passwordBox.width - 8
                            height: passwordBox.height
                            radius: height / 2
                        }
                    }

                    ErrorShakeAnimation {
                        id: wrongPasswordShakeAnim
                        target: passwordBox
                    }
                    Connections {
                        target: GlobalStates
                        function onScreenUnlockFailedChanged() {
                            if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                        }
                    }

                    property bool materialShapeChars: Config.options.lock.materialShapeChars
                    color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
                    Loader {
                        active: passwordBox.materialShapeChars
                        anchors {
                            fill: parent
                            leftMargin: passwordBox.padding
                            rightMargin: passwordBox.padding
                        }
                        sourceComponent: PasswordChars {
                            length: root.context.currentText.length
                            selectionStart: passwordBox.selectionStart
                            selectionEnd: passwordBox.selectionEnd
                            cursorPosition: passwordBox.cursorPosition
                        }
                    }
                }

                ToolbarButton {
                    id: confirmButton
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: 18
                    toggled: true
                    enabled: !root.context.unlockInProgress
                    colBackgroundToggled: Appearance.colors.colPrimary

                    onClicked: root.context.tryUnlock()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        iconSize: 22
                        text: {
                            if (root.context.targetAction === LockContext.ActionEnum.Unlock) {
                                return root.ctrlHeld ? "coffee" : "arrow_right_alt";
                            } else if (root.context.targetAction === LockContext.ActionEnum.Poweroff) {
                                return "power_settings_new";
                            } else if (root.context.targetAction === LockContext.ActionEnum.Reboot) {
                                return "restart_alt";
                            }
                        }
                        color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                    }
                }
            }

            // Glass Divider B-C
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.6)
            }

            // Segment C: Quick Action Hub
            RowLayout {
                spacing: 6

                IconToolbarButton {
                    id: wallpaperShuffleButton
                    text: "wallpaper"
                    property real shuffleRotation: 0
                    rotation: shuffleRotation

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 650
                            easing.type: Easing.OutBack
                        }
                    }

                    onClicked: {
                        shuffleRotation += 360;
                        Wallpapers.shuffle();
                    }
                    StyledToolTip {
                        text: Translation.tr("Shuffle wallpaper")
                    }
                }

                IconToolbarButton {
                    id: sleepButton
                    onClicked: Session.suspend()
                    text: "dark_mode"
                }

                PasswordGuardedIconToolbarButton {
                    id: powerButton
                    text: "power_settings_new"
                    targetAction: LockContext.ActionEnum.Poweroff
                }

                PasswordGuardedIconToolbarButton {
                    id: rebootButton
                    text: "restart_alt"
                    targetAction: LockContext.ActionEnum.Reboot
                }
            }
        }
    }

    component PasswordGuardedIconToolbarButton: IconToolbarButton {
        id: guardedBtn
        required property var targetAction

        toggled: root.context.targetAction === guardedBtn.targetAction

        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guardedBtn.targetAction);
                return;
            }
            if (root.context.targetAction === guardedBtn.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guardedBtn.targetAction;
                root.context.shouldReFocus();
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}
