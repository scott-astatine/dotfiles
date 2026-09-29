import QtQuick
import Quickshell
import "../../../services"
import "../.."
import "../../../services"
import "../.."
import "../../functions"
import "../../../components"

QuickToggleModel {
    name: Translation.tr("Virtual Keyboard")
    toggled: GlobalStates.oskOpen
    icon: toggled ? "keyboard_hide" : "keyboard"
    
    mainAction: () => {
        GlobalStates.oskOpen = !GlobalStates.oskOpen
    }

    tooltipText: Translation.tr("On-screen keyboard")
}
