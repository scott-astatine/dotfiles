import ".."
import QtQuick
import "../../../components"
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../core"
import "../../../core"

StyledOverlayWidget {
    id: root
    title: Translation.tr("Notes")
    showCenterButton: true

    contentItem: NotesContent {
        radius: root.contentRadius
        isClickthrough: root.clickthrough
    }
}
