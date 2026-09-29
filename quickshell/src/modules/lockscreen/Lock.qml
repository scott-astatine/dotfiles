pragma ComponentBehavior: Bound
import "../../services"
import "../../components"
import "../../core"
import "../../services"
import "../../core"
import "../../core/functions"
import "../../core/panels/lock"
import QtQuick
import Quickshell

LockScreen {
    id: root

    lockSurface: LockSurface {
        context: root.context
    }
}
