pragma ComponentBehavior: Bound
import "../../core"
import "../../components"
import "../../core/models"
import "../../services"
import "../../core/functions"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance — style: "ambient" | "crystal" | "current"
    id: root
    property MprisPlayer player
    property string style: "current" // "ambient" | "crystal" | "current"
    property var artUrl: player?.trackArtUrl ?? ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: {
        let baseWallColor = Appearance.colors.colPrimary;
        if (root.downloaded && root.displayedArtFilePath.length > 0 && colorQuantizer?.colors && colorQuantizer.colors.length > 0) {
            return ColorUtils.mix(colorQuantizer.colors[0], baseWallColor, 0.4);
        }
        return baseWallColor;
    }
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property list<real> internalVisualizerPoints: []
    readonly property list<real> effectiveVisualizerPoints: visualizerPoints.length > 0 ? visualizerPoints : internalVisualizerPoints
    property real maxVisualizerValue: 1000
    property int visualizerSmoothing: 2
    property real radius: Appearance.rounding.windowRounding
    property bool showVisualizer: Config.options.background.widgets.mediaVisualizer?.showVisualizer ?? true
    property bool showControls: true

    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing || player?.isPlaying === true
    readonly property bool compactMode: width < 520
    readonly property bool isCrystal: style === "crystal"
    readonly property bool isCurrent: style === "current"
    readonly property bool isAmbient: !isCrystal && !isCurrent

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""
    property string trackTitleText: StringUtils.cleanMusicTitle(root.player?.trackTitle) || (root.player ? "Untitled" : "No Media Playing")
    property string trackArtistText: root.player?.trackArtist ?? (root.player ? "Unknown Artist" : "—")

    component IconBtn: RippleButton {
        property string iconName
        property real size: root.compactMode ? 32 : 36
        implicitWidth: size
        implicitHeight: size
        buttonRadius: size / 2
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.45)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            iconSize: root.compactMode ? 16 : 18
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName
        }
    }

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    onArtFilePathChanged: {
        if (!root.artUrl || root.artUrl.length == 0)
            return;
        coverArtDownloader.targetFile = root.artUrl;
        coverArtDownloader.artFilePath = root.artFilePath;
        root.downloaded = false;
        coverArtDownloader.running = true;
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: ["bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'`]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true;
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    property real _lastCavaMs: 0

    onIsPlayingChanged: {
        if (!isPlaying)
            root.internalVisualizerPoints = [];
    }

    Process {
        id: internalCavaProc
        // Only when this control is on-screen and playing — avoid stacked cava on lock + desktop
        running: root.visible && root.opacity > 0.01 && root.showVisualizer && root.visualizerPoints.length === 0 && root.isPlaying
        onRunningChanged: {
            if (!internalCavaProc.running)
                root.internalVisualizerPoints = [];
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/media/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                if (!internalCavaProc.running)
                    return;
                // Cap ~30Hz — raw cava floods the scene graph
                const now = Date.now();
                if (now - root._lastCavaMs < 33)
                    return;
                root._lastCavaMs = now;
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.internalVisualizerPoints = points;
            }
        }
    }

    // Only one style tree exists at a time (ambient bloom/layers used to stay alive under crystal)
    Loader {
        anchors.fill: parent
        active: root.isAmbient
        sourceComponent: ambientComponent
    }
    Loader {
        anchors.fill: parent
        active: root.isCrystal
        sourceComponent: crystalComponent
    }
    Loader {
        anchors.fill: parent
        active: root.isCurrent
        sourceComponent: currentComponent
    }

    // ── Current Style Card (Mockup Current) ──────────────────────
    Component {
        id: currentComponent
        Item {
            id: currentRoot
            anchors.fill: parent

            StyledRectangularShadow {
                target: currentShell
            }

            Rectangle {
                id: currentShell
                anchors.fill: parent
                anchors.margins: Appearance.sizes.elevationMargin
                radius: root.radius || 24
                color: ColorUtils.applyAlpha(blendedColors.colLayer0, 0.78)
                border.color: ColorUtils.transparentize(blendedColors.colPrimary, 0.45)
                border.width: 1.5
                clip: true

                WaveVisualizer {
                    id: visualizerCanvas
                    anchors.fill: parent
                    visible: root.showVisualizer
                    live: root.isPlaying
                    points: root.effectiveVisualizerPoints
                    maxVisualizerValue: root.maxVisualizerValue
                    smoothing: root.visualizerSmoothing
                    color: blendedColors.colPrimary
                    secondaryColor: blendedColors.colSecondary
                    fillOpacity: root.compactMode ? 0.45 : 0.65
                    strokeWidth: root.compactMode ? 2.5 : 3.5
                    strokeOpacity: 0.95
                    saturation: 1.3
                    blurAmount: 0.1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.topMargin: currentShell.height * 0.025
                    anchors.bottomMargin: currentShell.height * 0.025
                    spacing: 14

                    MouseArea {
                        id: currentArtArea
                        Layout.fillHeight: true
                        Layout.preferredWidth: currentShell.height * 0.95
                        Layout.maximumWidth: currentShell.height * 0.95
                        Layout.alignment: Qt.AlignVCenter
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.player?.raise)
                                root.player.raise();
                        }

                        Rectangle {
                            id: currentArtCard
                            anchors.fill: parent
                            radius: 16
                            color: ColorUtils.transparentize(blendedColors.colLayer1, 0.35)
                            border.width: 1.5
                            border.color: ColorUtils.transparentize(blendedColors.colPrimary, currentArtArea.containsMouse ? 0.2 : 0.45)
                            clip: true

                            Rectangle {
                                id: currentMask
                                anchors.fill: parent
                                radius: currentArtCard.radius
                                visible: false
                            }

                            StyledImage {
                                id: currentArtImage
                                anchors.fill: parent
                                source: root.displayedArtFilePath
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                antialiasing: true
                                visible: false // hidden for OpacityMask
                            }

                            OpacityMask {
                                anchors.fill: parent
                                source: currentArtImage
                                maskSource: currentMask
                                visible: root.downloaded && currentArtImage.status === Image.Ready
                            }

                            CustomIcon {
                                anchors.centerIn: parent
                                source: "file://" + FileUtils.trimFileProtocol(Directories.shellConfig) + "/assets/icons/fluent/music-note-2-filled.svg"
                                width: 40
                                height: 40
                                colorize: true
                                color: blendedColors.colPrimary
                                visible: !currentArtImage.visible
                            }
                        }

                        StyledRectangularShadow {
                            target: currentArtCard
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        Layout.rightMargin: 10
                        Layout.bottomMargin: 10
                        spacing: 4

                        StyledText {
                            Layout.fillWidth: true
                            font.family: "Space Grotesk, Google Sans Flex, sans-serif"
                            font.pixelSize: root.compactMode ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.large + 2
                            font.weight: Font.Bold
                            color: blendedColors.colOnLayer0
                            elide: Text.ElideRight
                            text: root.trackTitleText
                            animateChange: true
                            animationDistanceX: 6
                        }

                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: blendedColors.colSubtext
                            elide: Text.ElideRight
                            text: root.trackArtistText
                            animateChange: true
                            animationDistanceX: 4
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                font.family: "JetBrains Mono, monospace"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: blendedColors.colSubtext
                                text: StringUtils.friendlyTimeForSeconds(root.player?.position)
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            StyledText {
                                font.family: "JetBrains Mono, monospace"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: blendedColors.colSubtext
                                text: StringUtils.friendlyTimeForSeconds(root.player?.length)
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 12
                            Loader {
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: StyledSlider {
                                    configuration: StyledSlider.Configuration.Wavy
                                    animateWave: root.isPlaying
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    handleColor: blendedColors.colPrimary
                                    value: (root.player?.length > 0) ? (root.player.position / root.player.length) : 0
                                    onMoved: {
                                        if (root.player && root.player.length > 0)
                                            root.player.position = value * root.player.length;
                                    }
                                }
                            }
                            Loader {
                                anchors.fill: parent
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar {
                                    wavy: root.isPlaying
                                    animateWave: root.isPlaying
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    value: (root.player?.length > 0) ? (root.player.position / root.player.length) : 0
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: root.compactMode ? 6 : 10
                            visible: root.showControls

                            IconBtn {
                                iconName: "shuffle"
                                enabled: Boolean(root.player?.canControl)
                                size: 32
                                colBackground: root.player?.shuffle ? blendedColors.colPrimary : ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.45)
                                downAction: () => {
                                    if (root.player)
                                        root.player.shuffle = !root.player.shuffle;
                                }
                                contentItem: MaterialSymbol {
                                    iconSize: 15
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: root.player?.shuffle ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                                    text: "shuffle"
                                }
                            }

                            IconBtn {
                                iconName: "skip_previous"
                                size: 34
                                enabled: Boolean(root.player?.canGoPrevious)
                                downAction: () => root.player?.previous()
                            }

                            RippleButton {
                                implicitWidth: 42
                                implicitHeight: 42
                                buttonRadius: 21
                                enabled: Boolean(root.player?.canControl)
                                colBackground: root.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                                colBackgroundHover: root.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                                colRipple: root.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive
                                downAction: () => root.player?.togglePlaying()
                                contentItem: MaterialSymbol {
                                    iconSize: 22
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: root.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                                    text: root.isPlaying ? "pause" : "play_arrow"
                                }
                            }

                            IconBtn {
                                iconName: "skip_next"
                                size: 34
                                enabled: Boolean(root.player?.canGoNext)
                                downAction: () => root.player?.next()
                            }

                            IconBtn {
                                iconName: root.player?.loopStatus === 2 ? "repeat_one" : "repeat"
                                size: 32
                                enabled: Boolean(root.player?.canControl)
                                colBackground: root.player?.loopStatus !== 0 ? blendedColors.colPrimary : ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.45)
                                downAction: () => {
                                    if (root.player)
                                        root.player.loopStatus = (root.player.loopStatus + 1) % 3;
                                }
                                contentItem: MaterialSymbol {
                                    iconSize: 15
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: root.player?.loopStatus !== 0 ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                                    text: root.player?.loopStatus === 2 ? "repeat_one" : "repeat"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Ambient Stage ──────────────────────────────────────────────
    Component {
        id: ambientComponent
        Item {
            id: ambientRoot
            anchors.fill: parent

        // Soft color wash (no MultiEffect blur — that was a major FPS killer)
        Rectangle {
            id: bloom
            x: ambientArt.x + ambientArt.width / 2 - width / 2
            y: ambientArt.y + ambientArt.height / 2 - height / 2
            width: ambientArt.width * 1.55
            height: ambientArt.height * 1.55
            radius: width / 2
            visible: root.showVisualizer
            color: ColorUtils.transparentize(root.artDominantColor, 0.62)
            opacity: root.isPlaying ? 0.55 : 0.28
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        // Soft ripple rings (max 2)
        Repeater {
            model: root.showVisualizer ? 2 : 0
            delegate: Rectangle {
                id: rippleRing
                required property int index
                anchors.centerIn: ambientArt
                width: ambientArt.width
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1.5
                border.color: ColorUtils.transparentize(root.artDominantColor, 0.5)
                opacity: 0
                visible: root.isPlaying
                z: 1

                SequentialAnimation {
                    running: root.isPlaying && root.visible
                    loops: Animation.Infinite
                    PauseAnimation {
                        duration: rippleRing.index * 700
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: rippleRing
                            property: "opacity"
                            from: 0.55
                            to: 0
                            duration: 2200
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: rippleRing
                            property: "scale"
                            from: 0.78
                            to: 1.35
                            duration: 2200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        // Glass panel (sits under / beside art)
        StyledRectangularShadow {
            target: ambientPanel
        }
        Rectangle {
            id: ambientPanel
            readonly property real slideUnderArt: ambientArt.width * 0.48
            anchors {
                left: parent.left
                leftMargin: Math.max(Appearance.sizes.elevationMargin, ambientArt.x + ambientArt.width - slideUnderArt)
                right: parent.right
                rightMargin: Appearance.sizes.elevationMargin
                top: parent.top
                topMargin: root.compactMode ? 18 : 28
                bottom: parent.bottom
                bottomMargin: Appearance.sizes.elevationMargin
            }
            radius: root.radius || 28
            color: ColorUtils.applyAlpha(blendedColors.colLayer0, 0.72)
            border.color: ColorUtils.transparentize(blendedColors.colPrimary, 0.55)
            border.width: 1
            clip: true

            WaveVisualizer {
                id: ambientVisualizerCanvas
                anchors.fill: parent
                visible: root.showVisualizer
                live: root.isPlaying
                points: root.effectiveVisualizerPoints
                maxVisualizerValue: root.maxVisualizerValue
                smoothing: root.visualizerSmoothing
                color: blendedColors.colPrimary
                secondaryColor: blendedColors.colSecondary
                fillOpacity: root.compactMode ? 0.45 : 0.65
                strokeWidth: root.compactMode ? 2.5 : 3.5
                strokeOpacity: 0.95
                saturation: 1.3
                blurAmount: 0.1
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: ambientPanel.slideUnderArt + 12
                anchors.rightMargin: root.compactMode ? 14 : 20
                anchors.topMargin: root.compactMode ? 14 : 18
                anchors.bottomMargin: root.compactMode ? 12 : 16
                spacing: root.compactMode ? 4 : 6

                RowLayout {
                    spacing: 8
                    Rectangle {
                        implicitWidth: 7
                        implicitHeight: 7
                        radius: 3.5
                        color: blendedColors.colPrimary
                        visible: root.isPlaying
                        SequentialAnimation on opacity {
                            running: root.isPlaying && root.visible
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 1
                                to: 0.35
                                duration: 700
                            }
                            NumberAnimation {
                                from: 0.35
                                to: 1
                                duration: 700
                            }
                        }
                    }
                    StyledText {
                        text: "NOW PLAYING"
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: Appearance.font.pixelSize.smaller - 1
                        font.weight: Font.Medium
                        font.letterSpacing: 1.4
                        color: ColorUtils.mix(blendedColors.colPrimary, blendedColors.colSecondary, 0.35)
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        visible: Boolean(root.player?.identity)
                        implicitWidth: identityLabel.implicitWidth + 14
                        implicitHeight: identityLabel.implicitHeight + 8
                        radius: 999
                        color: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.45)
                        border.color: ColorUtils.transparentize(blendedColors.colPrimary, 0.55)
                        border.width: 1
                        StyledText {
                            id: identityLabel
                            anchors.centerIn: parent
                            font.family: "JetBrains Mono, monospace"
                            font.pixelSize: Appearance.font.pixelSize.smaller - 1
                            font.letterSpacing: 0.8
                            color: blendedColors.colOnSecondaryContainer
                            text: (root.player?.identity ?? "").toUpperCase()
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    font.family: "Space Grotesk, Google Sans Flex, sans-serif"
                    font.pixelSize: root.compactMode ? Appearance.font.pixelSize.large : Appearance.font.pixelSize.huge + 4
                    font.weight: Font.Bold
                    color: blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: root.trackTitleText
                    animateChange: true
                    animationDistanceX: 6
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: root.compactMode ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.normal
                    color: blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: root.trackArtistText
                    animateChange: true
                    animationDistanceX: 6
                }

                Item {
                    Layout.fillHeight: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    StyledText {
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: blendedColors.colSubtext
                        text: StringUtils.friendlyTimeForSeconds(root.player?.position)
                    }
                    Item {
                        id: ambientProgress
                        Layout.fillWidth: true
                        implicitHeight: 14
                        Loader {
                            anchors.fill: parent
                            active: root.player?.canSeek ?? false
                            sourceComponent: StyledSlider {
                                configuration: StyledSlider.Configuration.Wavy
                                animateWave: root.isPlaying
                                highlightColor: blendedColors.colPrimary
                                trackColor: blendedColors.colSecondaryContainer
                                handleColor: blendedColors.colPrimary
                                value: (root.player?.length > 0) ? (root.player.position / root.player.length) : 0
                                onMoved: {
                                    if (root.player && root.player.length > 0)
                                        root.player.position = value * root.player.length;
                                }
                            }
                        }
                        Loader {
                            anchors.fill: parent
                            active: !(root.player?.canSeek ?? false)
                            sourceComponent: StyledProgressBar {
                                wavy: root.isPlaying
                                animateWave: root.isPlaying
                                highlightColor: blendedColors.colPrimary
                                trackColor: blendedColors.colSecondaryContainer
                                value: (root.player?.length > 0) ? (root.player.position / root.player.length) : 0
                            }
                        }
                    }
                    StyledText {
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: blendedColors.colSubtext
                        text: StringUtils.friendlyTimeForSeconds(root.player?.length)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.compactMode ? 6 : 8
                    visible: root.showControls

                    IconBtn {
                        iconName: "skip_previous"
                        enabled: Boolean(root.player?.canGoPrevious)
                        downAction: () => root.player?.previous()
                    }
                    RippleButton {
                        property real size: root.compactMode ? 42 : 48
                        implicitWidth: size
                        implicitHeight: size
                        buttonRadius: size / 2
                        enabled: Boolean(root.player?.canControl)
                        colBackground: root.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                        colBackgroundHover: root.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                        colRipple: root.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive
                        downAction: () => root.player?.togglePlaying()
                        contentItem: MaterialSymbol {
                            iconSize: root.compactMode ? 22 : 26
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                            text: root.isPlaying ? "pause" : "play_arrow"
                        }
                    }
                    IconBtn {
                        iconName: "skip_next"
                        enabled: Boolean(root.player?.canGoNext)
                        downAction: () => root.player?.next()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    IconBtn {
                        iconName: "shuffle"
                        visible: !root.compactMode
                        enabled: Boolean(root.player?.canControl)
                        colBackground: root.player?.shuffle ? blendedColors.colPrimary : ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.45)
                        downAction: () => {
                            if (root.player)
                                root.player.shuffle = !root.player.shuffle;
                        }
                        contentItem: MaterialSymbol {
                            iconSize: 16
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.player?.shuffle ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                            text: "shuffle"
                        }
                    }
                    IconBtn {
                        iconName: root.player?.loopStatus === 2 ? "repeat_one" : "repeat"
                        visible: !root.compactMode
                        enabled: Boolean(root.player?.canControl)
                        colBackground: root.player?.loopStatus !== 0 ? blendedColors.colPrimary : ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.45)
                        downAction: () => {
                            if (root.player)
                                root.player.loopStatus = (root.player.loopStatus + 1) % 3;
                        }
                        contentItem: MaterialSymbol {
                            iconSize: 16
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.player?.loopStatus !== 0 ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                            text: root.player?.loopStatus === 2 ? "repeat_one" : "repeat"
                        }
                    }
                }
            }
        }

        // Tilted album art (above panel)
        MouseArea {
            id: ambientArt
            x: Appearance.sizes.elevationMargin + (root.compactMode ? 10 : 18)
            y: root.compactMode ? 22 : 28
            width: root.compactMode ? Math.min(120, parent.height - 44) : Math.min(180, parent.height - 56)
            height: width
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 3
            onClicked: {
                if (root.player?.raise)
                    root.player.raise();
            }

            transform: Rotation {
                origin.x: ambientArt.width / 2
                origin.y: ambientArt.height / 2
                angle: ambientArt.containsMouse ? 0 : -2.5
                Behavior on angle {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                id: ambientArtCard
                anchors.fill: parent
                z: 1
                radius: 16
                color: ColorUtils.transparentize(blendedColors.colLayer1, 0.4)
                border.width: 1
                border.color: ColorUtils.transparentize(blendedColors.colPrimary, ambientArt.containsMouse ? 0.15 : 0.45)
                clip: true

                Rectangle {
                    id: ambientMask
                    anchors.fill: parent
                    radius: ambientArtCard.radius
                    visible: false
                }

                StyledImage {
                    id: ambientArtImage
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    visible: false // hidden for OpacityMask
                }

                OpacityMask {
                    anchors.fill: parent
                    source: ambientArtImage
                    maskSource: ambientMask
                    visible: root.downloaded && ambientArtImage.status === Image.Ready
                }

                CustomIcon {
                    anchors.centerIn: parent
                    source: "file://" + FileUtils.trimFileProtocol(Directories.shellConfig) + "/assets/icons/fluent/music-note-2-filled.svg"
                    width: 48
                    height: 48
                    colorize: true
                    color: blendedColors.colPrimary
                    visible: !ambientArtImage.visible
                }
            }

            StyledRectangularShadow {
                target: ambientArtCard
            }
        }
        } // ambientRoot Item
    } // ambientComponent

    // ── Crystal HUD ────────────────────────────────────────────────
    Component {
        id: crystalComponent
        Item {
            id: crystalRoot
            anchors.fill: parent

        StyledRectangularShadow {
            target: crystalShell
        }
        Rectangle {
            id: crystalShell
            anchors.fill: parent
            anchors.margins: Appearance.sizes.elevationMargin
            radius: root.radius || 36
            color: ColorUtils.applyAlpha(blendedColors.colLayer0, 0.68)
            border.color: ColorUtils.transparentize(blendedColors.colPrimary, 0.55)
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                MouseArea {
                    id: crystalArtArea
                    Layout.preferredWidth: height
                    Layout.fillHeight: true
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player?.raise)
                            root.player.raise();
                    }

                    Rectangle {
                        id: crystalArtCard
                        anchors.fill: parent
                        radius: 24
                        color: ColorUtils.transparentize(blendedColors.colLayer1, 0.35)
                        border.width: 1
                        border.color: ColorUtils.transparentize(blendedColors.colPrimary, crystalArtArea.containsMouse ? 0.2 : 0.5)
                        clip: true

                        StyledImage {
                            id: crystalArtImage
                            anchors.fill: parent
                            source: root.displayedArtFilePath
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            antialiasing: true
                            visible: root.downloaded && status === Image.Ready
                        }

                        CustomIcon {
                            anchors.centerIn: parent
                            source: "file://" + FileUtils.trimFileProtocol(Directories.shellConfig) + "/assets/icons/fluent/music-note-2-filled.svg"
                            width: 40
                            height: 40
                            colorize: true
                            color: blendedColors.colPrimary
                            visible: !crystalArtImage.visible
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        StyledText {
                            Layout.fillWidth: true
                            font.family: "Space Grotesk, Google Sans Flex, sans-serif"
                            font.pixelSize: Appearance.font.pixelSize.huge + 2
                            font.weight: Font.Bold
                            color: blendedColors.colOnLayer0
                            elide: Text.ElideRight
                            text: root.trackTitleText
                            animateChange: true
                            animationDistanceX: 6
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: blendedColors.colSubtext
                            elide: Text.ElideRight
                            Layout.maximumWidth: parent.width * 0.35
                            text: root.trackArtistText
                            animateChange: true
                            animationDistanceX: 4
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        WaveVisualizer {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: Math.min(54, parent.height)
                            visible: root.showVisualizer
                            live: root.isPlaying
                            points: root.effectiveVisualizerPoints
                            maxVisualizerValue: root.maxVisualizerValue
                            smoothing: root.visualizerSmoothing
                            visualStyle: "crystal"
                            maxBars: 28
                            color: blendedColors.colPrimary
                            secondaryColor: blendedColors.colSecondary
                            fillOpacity: 0.7
                            strokeWidth: 0
                            blurAmount: 0
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            RowLayout {
                                Layout.fillWidth: true
                                StyledText {
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: blendedColors.colSubtext
                                    text: StringUtils.friendlyTimeForSeconds(root.player?.position)
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: blendedColors.colSubtext
                                    text: StringUtils.friendlyTimeForSeconds(root.player?.length)
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 12
                                Loader {
                                    anchors.fill: parent
                                    active: root.player?.canSeek ?? false
                                    sourceComponent: StyledSlider {
                                        configuration: StyledSlider.Configuration.Wavy
                                        animateWave: root.isPlaying
                                        highlightColor: blendedColors.colPrimary
                                        trackColor: blendedColors.colSecondaryContainer
                                        handleColor: blendedColors.colPrimary
                                        value: (root.player?.length > 0) ? (root.player.position / root.player.length) : 0
                                        onMoved: {
                                            if (root.player && root.player.length > 0)
                                                root.player.position = value * root.player.length;
                                        }
                                    }
                                }
                                Loader {
                                    anchors.fill: parent
                                    active: !(root.player?.canSeek ?? false)
                                    sourceComponent: StyledProgressBar {
                                        wavy: root.isPlaying
                                        animateWave: root.isPlaying
                                        highlightColor: blendedColors.colPrimary
                                        trackColor: blendedColors.colSecondaryContainer
                                        value: (root.player?.length > 0) ? (root.player.position / root.player.length) : 0
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 8
                            visible: root.showControls

                            IconBtn {
                                iconName: "skip_previous"
                                size: 34
                                enabled: Boolean(root.player?.canGoPrevious)
                                downAction: () => root.player?.previous()
                            }
                            RippleButton {
                                implicitWidth: 42
                                implicitHeight: 42
                                buttonRadius: 21
                                enabled: Boolean(root.player?.canControl)
                                colBackground: blendedColors.colOnLayer0
                                colBackgroundHover: ColorUtils.mix(blendedColors.colOnLayer0, blendedColors.colPrimary, 0.15)
                                colRipple: blendedColors.colPrimary
                                downAction: () => root.player?.togglePlaying()
                                contentItem: MaterialSymbol {
                                    iconSize: 22
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: blendedColors.colLayer0
                                    text: root.isPlaying ? "pause" : "play_arrow"
                                }
                            }
                            IconBtn {
                                iconName: "skip_next"
                                size: 34
                                enabled: Boolean(root.player?.canGoNext)
                                downAction: () => root.player?.next()
                            }
                        }
                    }
                }
            }
        }
        } // crystalRoot
    } // crystalComponent
}
