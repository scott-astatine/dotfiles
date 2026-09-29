//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

// NovaShell Entry Point - Clean Architecture & Reactive UI Layout
import "src/theme"
import "src/layout"
import "src/services"
import "src/components"
import "src/core"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Shell overlay components
    ReloadPopup {}

    Component.onCompleted: { 
        MaterialThemeLoader.reapplyTheme();
        Hyprsunset.load();
        ConflictKiller.load();
        Cliphist.refresh();
        Wallpapers.load();
        Updates.load(); 
    }

    ShellLayout {}

    // Shortcuts & IPC Handlers
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily();
        }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            GlobalStates.bluetoothPopupOpen = !GlobalStates.bluetoothPopupOpen;
        }

        function open(): void {
            GlobalStates.bluetoothPopupOpen = true;
        }

        function close(): void {
            GlobalStates.bluetoothPopupOpen = false;
        }
    }

    IpcHandler {
        target: "network"

        function toggle(): void {
            GlobalStates.wifiPopupOpen = !GlobalStates.wifiPopupOpen;
        }
    }

    IpcHandler {
        target: "wifi"

        function toggle(): void {
            GlobalStates.wifiPopupOpen = !GlobalStates.wifiPopupOpen;
        }

        function open(): void {
            GlobalStates.wifiPopupOpen = true;
        }

        function close(): void {
            GlobalStates.wifiPopupOpen = false;
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            if (GlobalStates.overviewOpen) {
                GlobalStates.overviewOpen = false;
            } else {
                GlobalStates.overviewOpen = true;
            }
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}
