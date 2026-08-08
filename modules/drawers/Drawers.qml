pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import qs.modules.bar

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData
        readonly property bool barDisabled: Strings.testRegexList(Config.bar.excludedScreens, modelData.name)

        Exclusions {
            screen: scope.modelData
            bar: bar
            borderThickness: Config.border.thickness
        }

        StyledWindow {
            id: win

            readonly property var monitor: Hypr.monitorFor(screen)
            readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject?.specialWorkspace?.name.length ?? 0) > 0
            readonly property bool hasFullscreen: {
                if (hasSpecialWorkspace) {
                    const specialName = monitor?.lastIpcObject?.specialWorkspace?.name;
                    if (!specialName)
                        return false;
                    const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
                    return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
                }
                return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
            }
            property real borderThickness: hasFullscreen ? 0 : Config.border.thickness
            readonly property real borderLayoutThickness: hasFullscreen ? 0 : Config.border.thickness
            readonly property int clampedThickness: Math.max(Config.border.minThickness, borderThickness)
            property real borderRounding: hasFullscreen ? 0 : Config.border.rounding
            property real shadowOpacity: hasFullscreen ? 0 : 0.7
            readonly property int dragMaskPadding: {
                // Always return 0 when panels are open or focus is active
                if (panels.popouts.isDetached)
                    return 0;

                // Always return 0 when there are windows (we'll rely on panel regions for hover)
                const mon = Hypr.monitorFor(screen);
                if (mon?.lastIpcObject.specialWorkspace?.name || mon?.activeWorkspace.lastIpcObject.windows > 0)
                    return 0;

                // When workspace is empty, use drag thresholds for hover activation
                const thresholds = [];
                for (const panel of ["dashboard", "launcher", "session", "sidebar"])
                    if (Config[panel].enabled)
                        thresholds.push(Config[panel].dragThreshold);
                return Math.max(...thresholds);
            }

            onHasFullscreenChanged: {
                visibilities.launcher = false;
                visibilities.session = false;
                visibilities.dashboard = false;
            }

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.launcher ? WlrKeyboardFocus.Exclusive : (visibilities.session || panels.dashboard.needsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

            // Mango drag activation relies on the Interactions hover logic only. The mask
            // must NEVER expand for drag thresholds: dragMaskPadding can never be 0 on Mango
            // (its workspace-window check reads Hyprland-only IPC fields), which carved ~50px
            // dead strips over app edges (titlebars/scrollbars/bottom buttons).
            mask: Region {
                // Static: bar column + edge strips only (clamped thickness). NEVER flips to
                // full-screen: Mango has no press IPC, so a capture would swallow app clicks.
                x: bar.clampedWidth
                y: win.clampedThickness
                width: win.width - bar.clampedWidth - win.clampedThickness
                height: win.height - win.clampedThickness * 2
                intersection: Intersection.Xor

                regions: panelRegions.instances
            }

            Variants {
                id: panelRegions

                model: panels.children

                Region {
                    required property Item modelData

                    x: bar.implicitWidth + modelData.x
                    y: Config.border.thickness + modelData.y
                    width: modelData.visible ? Math.max(0, modelData.width) : 0
                    height: modelData.visible ? Math.max(0, modelData.height) : 0
                    intersection: Intersection.Subtract
                }
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Behavior on borderThickness {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on borderRounding {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on shadowOpacity {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            // HyprlandFocusGrab - emulated for MangoWC: full-screen input capture + manual close
            Item {
                id: focusGrab

                property bool active: (visibilities.launcher && Config.launcher.enabled) || (visibilities.session && Config.session.enabled) || (visibilities.sidebar && Config.sidebar.enabled) || (!Config.dashboard.showOnHover && visibilities.dashboard && Config.dashboard.enabled) || (panels.popouts.hasCurrent && panels.popouts.currentName.startsWith("traymenu") && panels.popouts.trayMenuDepth > 1)
                // property var windows: [win]  // Not used in MangoWM
                signal cleared()

                function clearInteraction(): void {
                    visibilities.launcher = false;
                    visibilities.session = false;
                    visibilities.sidebar = false;
                    visibilities.dashboard = false;
                    panels.popouts.hasCurrent = false;
                    panels.popouts.clearState();
                    bar.closeTray();
                }

                onCleared: clearInteraction()
            }

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
                color: Colours.palette.m3scrim

                Behavior on opacity {
                    Anim {}
                }
            }

            Item {
                anchors.fill: parent
                opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
                layer.enabled: false  // Disable blur effect for crisp panels with MangoWC

                Border {
                    bar: bar
                    borderThickness: win.borderThickness
                    borderRounding: win.borderRounding
                }

                Backgrounds {
                    panels: panels
                    bar: bar
                    borderThickness: win.borderThickness
                    borderRounding: win.borderRounding
                }
            }

            DrawerVisibilities {
                id: visibilities

                Component.onCompleted: Visibilities.load(scope.modelData, this)
            }

            Interactions {
                screen: scope.modelData
                popouts: panels.popouts
                visibilities: visibilities
                panels: panels
                bar: bar
                borderThickness: win.borderLayoutThickness
                fullscreen: win.hasFullscreen

                onOutsideClicked: {
                    if (focusGrab.active)
                        focusGrab.clearInteraction();
                }

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                    bar: bar
                    borderThickness: win.borderLayoutThickness
                }

                BarWrapper {
                    id: bar

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    screen: scope.modelData
                    visibilities: visibilities
                    popouts: panels.popouts

                    disabled: scope.barDisabled
                    fullscreen: win.hasFullscreen

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }
        }
    }
}
