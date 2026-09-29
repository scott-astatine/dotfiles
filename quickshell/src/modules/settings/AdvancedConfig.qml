import QtQuick
import "../../components"
import "../../services"
import "../../core"
import "../../core"

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "colors"
        title: Translation.tr("Color generation")

        ConfigSwitch {
            buttonIcon: "hardware"
            text: Translation.tr("Shell & utilities")
            checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "tv_options_input_settings"
            text: Translation.tr("Qt apps")
            checked: Config.options.appearance.wallpaperTheming.enableQtApps
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableQtApps = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigSwitch {
            buttonIcon: "terminal"
            text: Translation.tr("Terminal")
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableTerminal = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Force dark mode in terminal")
                checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                onCheckedChanged: {
                     Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode= checked;
                }
                StyledToolTip {
                    text: Translation.tr("Ignored if terminal theming is not enabled")
                }
            }
        }

        ConfigSpinBox {
            icon: "invert_colors"
            text: Translation.tr("Terminal: Harmony (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100;
            }
        }
        ConfigSpinBox {
            icon: "gradient"
            text: Translation.tr("Terminal: Harmonize threshold")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value;
            }
        }
        ConfigSpinBox {
            icon: "format_color_text"
            text: Translation.tr("Terminal: Foreground boost (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100;
            }
        }
    }

    ContentSection {
        icon: "auto_awesome"
        title: Translation.tr("System UI Tweaks")

        ConfigSwitch {
            buttonIcon: "animation"
            text: Translation.tr("Smoother menu animations")
            checked: Config.options.tweaks.tweaks.smootherMenuAnimations
            onCheckedChanged: {
                Config.options.tweaks.tweaks.smootherMenuAnimations = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "search"
            text: Translation.tr("Smoother search bar transitions")
            checked: Config.options.tweaks.tweaks.smootherSearchBar
            onCheckedChanged: {
                Config.options.tweaks.tweaks.smootherSearchBar = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "toggle_on"
            text: Translation.tr("Switch handle position alignment fix")
            checked: Config.options.tweaks.tweaks.switchHandlePositionFix
            onCheckedChanged: {
                Config.options.tweaks.tweaks.switchHandlePositionFix = checked;
            }
        }
    }

    ContentSection {
        icon: "mouse"
        title: Translation.tr("Input & Scrolling")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "touchpad"
                text: Translation.tr("Faster touchpad scroll")
                checked: Config.options.interactions.scrolling.fasterTouchpadScroll
                onCheckedChanged: {
                    Config.options.interactions.scrolling.fasterTouchpadScroll = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "grid_off"
                text: Translation.tr("Dead pixel workaround")
                checked: Config.options.interactions.deadPixelWorkaround.enable
                onCheckedChanged: {
                    Config.options.interactions.deadPixelWorkaround.enable = checked;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "swipe"
                text: Translation.tr("Touchpad scroll factor")
                value: Config.options.interactions.scrolling.touchpadScrollFactor
                from: 50
                to: 1000
                stepSize: 25
                onValueChanged: {
                    Config.options.interactions.scrolling.touchpadScrollFactor = value;
                }
            }
            ConfigSpinBox {
                icon: "mouse"
                text: Translation.tr("Mouse scroll factor")
                value: Config.options.interactions.scrolling.mouseScrollFactor
                from: 10
                to: 500
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.mouseScrollFactor = value;
                }
            }
        }

        ConfigSpinBox {
            icon: "tune"
            text: Translation.tr("Mouse scroll delta threshold")
            value: Config.options.interactions.scrolling.mouseScrollDeltaThreshold
            from: 10
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.interactions.scrolling.mouseScrollDeltaThreshold = value;
            }
        }
    }
}
