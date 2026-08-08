// Still preview of a foreign toplevel window for MangoWM.
//
// Quickshell's ScreencopyView only supports toplevel capture via Hyprland's
// `hyprland-toplevel-export-v1`, which Mango does not implement. Mango ships
// `ext-foreign-toplevel-image-capture-source-v1`, which is reachable through
// `grim -T <foreign_toplevel_id>`. This component captures once when shown and
// once when the target window changes — never on a timer, so grim doesn't get
// spawned repeatedly while the preview sits open.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // foreign_toplevel_id from `mmsg get focusing-client`.
    required property string captureId

    // Cap the decoded texture size; the Image is scaled down by fillMode.
    property int maxPixel: 1000

    readonly property bool captureable: captureId.length > 0

    readonly property string tmpRoot: `/tmp/caelestia-active-${Quickshell.processId}`
    // Nonce so each capture writes a distinct file: grim overwrites the path
    // only while we are NOT pointing at it (we re-assign after it exits), so
    // Qt never reads a half-written PNG.
    property int version: 0
    property string pendingPath: ""

    Image {
        id: preview

        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        sourceSize: root.maxPixel > 0 ? Qt.size(root.maxPixel, root.maxPixel) : undefined
        source: ""
    }

    function nextPath(): string {
        root.version++;
        return `${root.tmpRoot}-${root.captureId.substring(0, 8)}.${root.version}.png`;
    }

    function refresh(): void {
        if (!root.captureable || captureProcess.running)
            return;

        root.pendingPath = nextPath();
        captureProcess.command = ["grim", "-T", root.captureId, "-t", "png", root.pendingPath];
        captureProcess.running = true;
    }

    function showLatest(exitCode: int): void {
        if (exitCode !== 0) {
            // grim failed (window gone or not captureable); keep whatever we last had.
            return;
        }

        preview.source = "file://" + root.pendingPath;
    }

    onCaptureIdChanged: {
        preview.source = "";
        refresh();
    }

    onVisibleChanged: {
        if (root.visible)
            refresh();
    }

    Component.onCompleted: refresh()

    Process {
        id: captureProcess

        command: []
        running: false

        onExited: (exitCode, exitStatus) => root.showLatest(exitCode)
    }
}