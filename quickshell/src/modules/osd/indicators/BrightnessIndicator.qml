import "../../../services"
import "../../../components"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../core"
import ".."

OsdValueIndicator {
    id: root

    icon: Hyprsunset.temperatureActive ? "routine" : "light_mode"
    rotateIcon: true
    scaleIcon: true
    name: Translation.tr("Brightness")
    value: Brightness.brightness
}
