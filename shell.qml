//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import QtQuick
import Quickshell
import Caelestia

ShellRoot {
    id: root

    settings.watchFiles: true
    readonly property bool toolingMode: Quickshell.env("CAELESTIA_QML_TOOLING") === "1"

    Component.onCompleted: {
        if (!Quickshell.env("XDG_CURRENT_DESKTOP"))
            CUtils.setEnv("XDG_CURRENT_DESKTOP", "mango");
        if (!Quickshell.env("XDG_SESSION_DESKTOP"))
            CUtils.setEnv("XDG_SESSION_DESKTOP", "mango");
        if (!Quickshell.env("SDL_VIDEODRIVER"))
            CUtils.setEnv("SDL_VIDEODRIVER", "wayland");
        if (!Quickshell.env("XDG_DESKTOP_PORTAL"))
            CUtils.setEnv("XDG_DESKTOP_PORTAL", "mango");
    }

    Loader {
        active: !root.toolingMode
        sourceComponent: Item {
            Background {}
            Drawers {}
            AreaPicker {}
            Lock {
                id: lock
            }

            Shortcuts {}
            BatteryMonitor {}
            IdleMonitors {
                lock: lock
            }
        }
    }
}
