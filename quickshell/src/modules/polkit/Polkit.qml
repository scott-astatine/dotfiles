import "../../services"
import "../../components"
import "../../core"
import "../../services"
import "../../core"
import "../../core"
import "../../core/functions"
import QtQuick
import Quickshell
import Quickshell.Wayland

FullscreenPolkitWindow {
    id: root
    contentComponent: Component {
        PolkitContent {}
    }
}
