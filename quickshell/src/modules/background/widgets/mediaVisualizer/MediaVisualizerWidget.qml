pragma ComponentBehavior: Bound

import QtQuick
import "../../../../services"
import "../../../../core"
import "../../../media"
import ".."

AbstractBackgroundWidget {
    id: root
    configEntryName: "mediaVisualizer"
    z: 100

    width: 560
    height: 280
    implicitWidth: 560
    implicitHeight: 280

    PlayerControl {
        anchors.fill: parent
        player: MediaService.activePlayer
        style: "ambient"
        radius: 28
        showVisualizer: Config.options.background.widgets.mediaVisualizer?.showVisualizer ?? true
        showControls: Config.options.background.widgets.mediaVisualizer?.showControls ?? true
    }
}
