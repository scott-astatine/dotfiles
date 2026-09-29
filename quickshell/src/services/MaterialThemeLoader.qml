pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import Quickshell

/**
 * Legacy MaterialThemeLoader singleton wrapper forwarding to consolidated PaletteManager.
 */
Singleton {
    id: root

    property string filePath: PaletteManager.filePath
    onFilePathChanged: { PaletteManager.filePath = filePath; }
    function reapplyTheme() { PaletteManager.reapplyTheme(); }
    function toggleLightDark() { PaletteManager.toggleLightDark(); }
}
