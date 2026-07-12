pragma Singleton

import Quickshell
import qs.components
import qs.services

Singleton {
    property var screens: new Map()
    property var bars: new Map()

    function load(screen: ShellScreen, visibilities: DrawerVisibilities): void {
        screens.set(screen.name, visibilities);
    }

    function getForActive(): DrawerVisibilities {
        let result = screens.get(Mango.focusedOutput);
        if (!result && screens.size > 0)
            result = screens.values().next().value;
        return result;
    }
}
