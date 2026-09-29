import QtQuick
import "../components"
import Quickshell
import "../core"

import "../theme"
import "../modules/background"
import "../modules/statusbar"
import "../modules/cheatsheet"
import "../modules/dock"
import "../modules/lockscreen"
import "../modules/media"
import "../modules/notifications"
import "../modules/osd"
import "../modules/onScreenKeyboard"
import "../modules/launcher"
import "../modules/polkit"
import "../modules/regionSelector"
import "../modules/screenCorners"
import "../modules/screenTranslator"
import "../modules/sessionScreen"
import "../modules/drawers/right"
import "../modules/overlay"
import "../modules/dialogs"
import "../modules/wallpaper"

Scope {
    id: root

    // Component loaders for all active UI views
    Background {}
    Bar {}
    Cheatsheet {}
    Dock { extraCondition: Config.options.dock.enable }
    Lock {}
    MediaControls {}
    NotificationPopup {}
    OnScreenDisplay {}
    OnScreenKeyboard {}
    Overlay {}
    Overview {}
    Polkit {}
    RegionSelector {}
    ScreenCorners {}
    ScreenTranslator {}
    SessionScreen {}
    SidebarRight {}
    StandaloneDialogs {}
    WallpaperSelector {}
}
