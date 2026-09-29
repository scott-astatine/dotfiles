import "../../services"
import "../../components"
import "../../core"
import "../../core"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    implicitWidth: colLayout.implicitWidth
    implicitHeight: colLayout.implicitHeight

    function truncateText(str, maxLen) {
        if (!str) return "";
        return str.length > maxLen ? str.substring(0, maxLen) + "…" : str;
    }

    ColumnLayout {
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: -4

        StyledText {
            Layout.fillWidth: false
            Layout.maximumWidth: 260
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: {
                let rawText = root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                    root.activeWindow?.appId :
                    (root.biggestWindow?.class) ?? Translation.tr("Desktop");
                return truncateText(rawText, 25);
            }
        }

        StyledText {
            Layout.fillWidth: false
            Layout.maximumWidth: 260
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: {
                let rawText = root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                    root.activeWindow?.title :
                    (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`;
                return truncateText(rawText, 35);
            }
        }
    }
}
