import QtQuick
import Quickshell
import "../../../services"
import "../.."
import "../../../services"
import "../.."
import "../../functions"
import "../../../components"

QuickToggleModel {
    name: Translation.tr("EasyEffects")

    available: EasyEffects.available
    toggled: EasyEffects.active
    icon: "graphic_eq"

    Component.onCompleted: {
        EasyEffects.fetchActiveState()
    }

    mainAction: () => {
        EasyEffects.toggle()
    }

    altAction: () => {
        Quickshell.execDetached(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"])
        GlobalStates.sidebarRightOpen = false
    }

    tooltipText: Translation.tr("EasyEffects | Right-click to configure")
}
