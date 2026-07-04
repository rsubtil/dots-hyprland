pragma ComponentBehavior: Bound
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    function dismiss() {
        GlobalStates.screenTranslatorOpen = false
    }

    property string lockedScreenName: ""
    readonly property string currentScreenName: Hyprland.focusedMonitor?.name ?? (Quickshell.screens[0]?.name ?? "")

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: translatorLoader
            required property var modelData
            active: GlobalStates.screenTranslatorOpen && modelData?.name === root.lockedScreenName

            sourceComponent: ScreenTranslatorPanel {
                screen: translatorLoader.modelData
                onDismiss: root.dismiss()
            }
        }
    }

    function translate() {
        root.lockedScreenName = root.currentScreenName
        if (!root.lockedScreenName) return;

        if (GlobalStates.screenTranslatorOpen) GlobalStates.screenTranslatorOpen = false;
        GlobalStates.screenTranslatorOpen = true
    }

    IpcHandler {
        target: "screenTranslator"

        function translate() {
            root.translate()
        }
    }

    GlobalShortcut {
        name: "screenTranslate"
        description: "Translates screen content"
        onPressed: root.translate()
    }
}
