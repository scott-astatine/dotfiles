import "../../../../../services"
import "../../../../../components"
import "../../../../../core"
import "../../../../../core/models/quickToggles"
import "../../../../../core/functions"
import "../../../../../core"
import QtQuick
import Quickshell
import Quickshell.Bluetooth

AndroidQuickToggleButton {
    id: root
    
    toggleModel: BluetoothToggle {}
}
