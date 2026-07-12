pragma Singleton

import qs.components.misc
import Quickshell
import Quickshell.Io
import Quickshell.Wayland._ToplevelManagement
import QtQuick

Singleton {
    id: root

    // MangoWC workspaces (tags) via Wayland protocols
    readonly property var toplevels: ({
        values: root._toplevelArray
    }) // Real window list with .values accessor

    property var _toplevelArray: [] // Converted JS array from toplevel model
    
    readonly property var workspaces: ({
        values: parsedTags
    }) // Workspace list with .values accessor
    
    readonly property var monitors: outputsList // Monitor list - still stubbed

    // Active window with full compatibility layer
    readonly property var activeToplevel: focusedClient
    
    // Compatibility wrapper for window info that needs lastIpcObject
    readonly property QtObject focusedClient: QtObject {
        readonly property var wayland: ToplevelManager.activeToplevel
        readonly property string title: ToplevelManager.activeToplevel?.title ?? ""
        readonly property string appId: ToplevelManager.activeToplevel?.appId ?? ""
        readonly property string address: "0x0"
        readonly property var workspace: root.focusedWorkspace
        readonly property var monitor: root.focusedMonitor
        
        readonly property var lastIpcObject: {
            const obj = {
                title: ToplevelManager.activeToplevel?.title ?? "",
                initialTitle: ToplevelManager.activeToplevel?.title ?? "",
                initialClass: ToplevelManager.activeToplevel?.appId ?? "",
                floating: root.focusedClientFloating,
                fullscreen: root.focusedClientFullscreen ? 2 : 0,
                at: [root.focusedClientX, root.focusedClientY],
                size: [root.focusedClientWidth, root.focusedClientHeight],
                workspace: { "id": root.activeTagNumber, "name": `tag ${root.activeTagNumber}` },
                address: "0x0",
                pid: -1,
                xwayland: false,
                pinned: false
            };
            // Set 'class' property (reserved keyword)
            obj["class"] = ToplevelManager.activeToplevel?.appId ?? "";
            return obj;
        }
    }

    readonly property var focusedMonitor: ({
        name: focusedOutput,
        id: 0,
        x: 0,
        y: 0,
        focused: true,
        lastIpcObject: {
            specialWorkspace: { name: "" }
        }
    }) // Current focused monitor
    
    readonly property var focusedWorkspace: ({
        id: activeTagNumber,
        name: `tag ${activeTagNumber}`,
        lastIpcObject: {
            windows: root.toplevels.values.length,  // Actual window count
            specialWorkspace: { name: "" }
        },
        monitor: focusedMonitor,
        toplevels: root.toplevels
    }) // Current focused workspace

    readonly property int activeWsId: activeTagNumber

    // Mango tag state
    property var parsedTags: []
    property int activeTags: 0
    property int occupiedTags: 0
    property int activeTagNumber: 1
    property string focusedOutput: ""
    property var outputsList: []

    // Client info
    property string focusedClientTitle: ""
    property string focusedClientAppId: ""
    property int focusedClientX: 0
    property int focusedClientY: 0
    property int focusedClientWidth: 0
    property int focusedClientHeight: 0
    property bool focusedClientFloating: false
    property bool focusedClientFullscreen: false

    // Layout
    property string currentLayout: ""
    property var availableLayouts: []

    // Keyboard state (MangoWC doesn't expose this, so we stub it)
    readonly property var keyboard: null
    readonly property bool capsLock: false
    readonly property bool numLock: false
    readonly property string defaultKbLayout: ""
    readonly property string kbLayoutFull: currentKbLayout
    readonly property string kbLayout: currentKbLayout

    property string currentKbLayout: ""
    property bool hadKeyboard: false

    readonly property var kbMap: new Map()

    // Extras placeholder (removed for MangoWC)
    readonly property var extras: ({
        devices: {
            keyboards: []
        },
        options: {},
        message: function() {},
        batchMessage: function() {},
        applyOptions: function() {},
        refreshOptions: function() {},
        refreshDevices: function() {}
    })

    readonly property var options: ({})
    readonly property var devices: extras.devices

    signal configReloaded

    function dispatch(request: string): void {
        // MangoWC dispatch via mmsg dispatch
        const parts = request.split(" ");
        const command = parts[0];
        const args = parts.slice(1);
        
        if (command === "killwindow" || command === "closewindow" || command === "killclient") {
            Quickshell.execDetached(["mmsg", "dispatch", "killclient"]);
        } else if (command === "togglefloating") {
            Quickshell.execDetached(["mmsg", "dispatch", "togglefloating"]);
        } else if (command === "togglefullscreen" || command === "fullscreen") {
            Quickshell.execDetached(["mmsg", "dispatch", "togglefullscreen"]);
        } else if (command === "pin") {
            Quickshell.execDetached(["mmsg", "dispatch", "togglepin"]);
        } else if (command === "workspace" || command === "tag") {
            const tagNum = parseInt(args[0]);
            if (!isNaN(tagNum)) {
                Quickshell.execDetached(["mmsg", "dispatch", "view," + tagNum.toString()]);
                activeTagNumber = tagNum;
            }
        } else if (command === "movetoworkspace") {
            const tagNum = parseInt(args[0].replace(/^[^0-9]*/, ""));
            if (!isNaN(tagNum)) {
                Quickshell.execDetached(["mmsg", "dispatch", "sendtotag," + tagNum.toString()]);
            }
        } else if (command === "togglespecialworkspace") {
            console.warn("MangoWC: Special workspaces not supported");
        } else if (command.startsWith("resize")) {
            Quickshell.execDetached(["mmsg", "dispatch", "resizewin," + args.join(",")]);
        } else if (command.startsWith("move")) {
            Quickshell.execDetached(["mmsg", "dispatch", "movewin," + args.join(",")]);
        } else if (command === "focusdir") {
            Quickshell.execDetached(["mmsg", "dispatch", "focusdir," + args[0]]);
        } else if (command === "cyclelayout") {
            Quickshell.execDetached(["mmsg", "dispatch", "cyclelayout"]);
        } else {
            const fullCmd = [command, ...args].join(",");
            console.log("MangoWC: Dispatching:", fullCmd);
            Quickshell.execDetached(["mmsg", "dispatch", fullCmd]);
        }
    }

    function monitorFor(screen): var {
        // MangoWC doesn't have per-screen monitor info easily accessible via Wayland protocols
        return {
            name: focusedOutput,
            id: 0,
            focused: true,
            lastIpcObject: {
                specialWorkspace: { name: "" }
            },
            activeWorkspace: focusedWorkspace
        };
    }

    function reloadDynamicConfs(): void {
        // MangoWC doesn't have dynamic config reloading via IPC
        console.log("MangoWC: Dynamic config reload not supported");
    }

    Component.onCompleted: {
        reloadDynamicConfs();
        console.log("MangoWC: Using Wayland protocols + mmsg IPC");
        console.log("MangoWC: Toplevels available:", toplevels.values.length);
        
        // Initialize with some default tags
        const tags = [];
        for (let i = 1; i <= 9; i++) {
            tags.push({
                id: i,
                name: `tag ${i}`,
                lastIpcObject: {
                    windows: 0,
                    specialWorkspace: { name: "" }
                },
                monitor: focusedMonitor,
                toplevels: { values: [] }
            });
        }
        parsedTags = tags;
    }
    
    // Poll tag state and focused client periodically
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            // Convert toplevel model to JS array (supports .filter, .find, etc.)
            const model = ToplevelManager.toplevels;
            const arr = [];
            if (model) {
                const count = model.count || 0;
                for (let i = 0; i < count; i++) {
                    const item = model.get ? model.get(i) : model[i];
                    if (item) arr.push(item);
                }
            }
            root._toplevelArray = arr;

            tagQuery.running = false;
            tagQuery.running = true;
            clientQuery.running = false;
            clientQuery.running = true;
        }
    }

    Process {
        id: tagQuery
        command: ["mmsg", "get", "all-tags"]
        stdout: StdioCollector {
            onStreamFinished: root.parseTagState(text)
        }
    }

    Process {
        id: clientQuery
        command: ["mmsg", "get", "focusing-client"]
        stdout: StdioCollector {
            onStreamFinished: root.parseFocusedClient(text)
        }
    }

    function parseTagState(output: string): void {
        try {
            const data = JSON.parse(output);
            const monitors = data.all_tags ?? [];
            let activeTag = 1;
            const occupiedMap = {};

            for (const mon of monitors) {
                for (const tag of (mon.tags ?? [])) {
                    occupiedMap[tag.index] = tag.client_count > 0;
                    if (tag.is_active) {
                        activeTag = tag.index;
                    }
                }
            }

            activeTagNumber = activeTag;

            const newTags = [];
            for (let i = 1; i <= 9; i++) {
                newTags.push({
                    id: i,
                    name: `tag ${i}`,
                    lastIpcObject: {
                        windows: occupiedMap[i] ? 1 : 0,
                        specialWorkspace: { name: "" }
                    },
                    monitor: focusedMonitor,
                    toplevels: { values: [] }
                });
            }
            parsedTags = newTags;
        } catch (e) {
            console.error("MangoWC: Error parsing tag state:", e);
        }
    }

    function parseFocusedClient(output: string): void {
        try {
            const data = JSON.parse(output);
            root.focusedClientTitle = data.title ?? "";
            root.focusedClientAppId = data.appid ?? "";
            root.focusedClientX = data.x ?? 0;
            root.focusedClientY = data.y ?? 0;
            root.focusedClientWidth = data.width ?? 0;
            root.focusedClientHeight = data.height ?? 0;
            root.focusedClientFloating = data.is_floating ?? false;
            root.focusedClientFullscreen = data.is_fullscreen ?? false;
        } catch (e) {
            // No focused client — reset to defaults
            root.focusedClientTitle = "";
            root.focusedClientAppId = "";
            root.focusedClientX = 0;
            root.focusedClientY = 0;
            root.focusedClientWidth = 0;
            root.focusedClientHeight = 0;
            root.focusedClientFloating = false;
            root.focusedClientFullscreen = false;
        }
    }

    // Stub for toast notifications (removed keyboard-related toasts)
    onCapsLockChanged: {
        // MangoWC doesn't expose capslock state
    }

    onNumLockChanged: {
        // MangoWC doesn't expose numlock state
    }

    onKbLayoutFullChanged: {
        // MangoWC doesn't expose keyboard layout changes
    }

    // Remove Hyprland event connections
    // MangoWC doesn't have a similar event system

    IpcHandler {
        target: "mango"

        function refreshDevices(): void {
            // No-op for MangoWC
        }
    }

    CustomShortcut {
        name: "refreshDevices"
        description: "Reload devices"
        onPressed: {} // No-op for MangoWC
        onReleased: {} // No-op for MangoWC
    }
}
