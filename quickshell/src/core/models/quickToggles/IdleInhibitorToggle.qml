import QtQuick
import Quickshell
import "../../../services"
import "../.."
import "../../../services"
import "../.."
import "../../functions"
import "../../../components"

QuickToggleModel {
    name: Translation.tr("Keep awake")

    toggled: Idle.inhibit
    icon: "coffee"
    mainAction: () => {
        Idle.toggleInhibit()
    }
    tooltipText: Translation.tr("Keep system awake")
}
