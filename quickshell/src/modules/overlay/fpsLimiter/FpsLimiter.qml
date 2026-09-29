import ".."
import QtQuick
import "../../../components"
import Quickshell
import "../../../core"
import "../../../core"

StyledOverlayWidget {
    id: root
    title: "MangoHud FPS"
    minimumWidth: 275
    minimumHeight: 100
    contentItem: FpsLimiterContent {
        radius: root.contentRadius
    }
}
