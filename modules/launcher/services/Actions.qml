pragma Singleton

import ".."
import QtQuick
import Quickshell
import qs.services
import qs.config
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(Config.launcher.actionPrefix.length);
    }

    list: variants.instances
    useFuzzy: Config.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: Config.launcher.actions.filter(a => (a.enabled ?? true) && (Config.launcher.enableDangerousActions || !(a.dangerous ?? false)))

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ?? qsTr("Unnamed")
        readonly property string desc: modelData.description ?? qsTr("No description")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(list: AppList): void {
            if (command.length === 0)
                return;

            if (command[0] === "autocomplete" && command.length > 1) {
                list.search.text = command[1] === "clipboard"
                    ? `${Config.launcher.actionPrefix}${command[1]}`
                    : `${Config.launcher.actionPrefix}${command[1]} `;
            } else if (command[0] === "setMode" && command.length > 1) {
                list.visibilities.launcher = false;
                Colours.setMode(command[1]);
            } else {
                list.visibilities.launcher = false;
                let cmd = [...command];
                if (cmd[0] === "caelestia" && cmd[1] === "shell") {
                    // Mango: the shell is launched with -p <path>, not -c caelestia,
                    // so IPC must target the running instance's shell dir directly.
                    cmd = ["quickshell", "ipc", "-p", Quickshell.shellDir, "call", ...cmd.slice(2)];
                } else if (cmd[0] === "caelestia" && cmd[1] === "wallpaper" && cmd[2] === "-r" && cmd.length === 3) {
                    // Random wallpaper needs the configured wallsdir; the CLI default
                    // (~/Pictures/Wallpapers) may not match Config.paths.wallpaperDir.
                    cmd.push(Paths.wallsdir);
                }
                Quickshell.execDetached(cmd);
            }
        }
    }
}
