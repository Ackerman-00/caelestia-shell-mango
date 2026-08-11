//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma DefaultEnv XDG_DATA_DIRS=/usr/local/share:/usr/share

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
        // Purge stale active-window preview captures from previous sessions.
        // /tmp is cleared by the OS on reboot; this also handles live restarts.
        Quickshell.execDetached(["sh", "-c", "rm -f /tmp/caelestia-active-*"]);

        if (!Quickshell.env("XDG_CURRENT_DESKTOP"))
            CUtils.setEnv("XDG_CURRENT_DESKTOP", "mango");
        if (!Quickshell.env("XDG_SESSION_DESKTOP"))
            CUtils.setEnv("XDG_SESSION_DESKTOP", "mango");
        if (!Quickshell.env("SDL_VIDEODRIVER"))
            CUtils.setEnv("SDL_VIDEODRIVER", "wayland");
        if (!Quickshell.env("XDG_DESKTOP_PORTAL"))
            CUtils.setEnv("XDG_DESKTOP_PORTAL", "mango");

        if (Quickshell.env("CAELESTIA_CLIPBOARD_DAEMON") !== "0") {
            Quickshell.execDetached(["sh", "-c", `pgrep -f "wl-paste --type text --watch cliphist [s]tore" > /dev/null || (wl-paste --type text --watch cliphist store &)`]);
            Quickshell.execDetached(["sh", "-c", `pgrep -f "wl-paste --type image --watch cliphist [s]tore" > /dev/null || (wl-paste --type image --watch cliphist store &)`]);
        }
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
