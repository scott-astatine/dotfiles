pragma ComponentBehavior: Bound
import "../../services"
import "../../components"
import "../../core"
import "../../core"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "./crosshair"
import "./volumeMixer"
import "./floatingImage"
import "./fpsLimiter"
import "./recorder"
import "./resources"
import "./notes"

DelegateChooser {
    id: root
    role: "identifier"

    DelegateChoice { roleValue: "crosshair"; Crosshair {} }
    DelegateChoice { roleValue: "floatingImage"; FloatingImage {} }
    DelegateChoice { roleValue: "fpsLimiter"; FpsLimiter {} }
    DelegateChoice { roleValue: "recorder"; Recorder {} }
    DelegateChoice { roleValue: "resources"; Resources {} }
    DelegateChoice { roleValue: "notes"; Notes {} }
    DelegateChoice { roleValue: "volumeMixer"; VolumeMixer {} }
}
