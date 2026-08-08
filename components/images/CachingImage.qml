import QtQuick
import Quickshell
import Caelestia.Internal
import qs.utils

Image {
    id: root

    property alias path: manager.path

    property int retryCount: 0

    asynchronous: true
    fillMode: Image.PreserveAspectCrop

    onStatusChanged: {
        if (status === Image.Ready)
            retryCount = 0;
        else if (status === Image.Error && retryCount < 10)
            retryTimer.start();
    }

    Timer {
        id: retryTimer

        interval: 250

        onTriggered: {
            root.retryCount++;
            if (root.source === manager.cachePath) {
                root.source = "";
                root.source = manager.cachePath;
            }
        }
    }

    Connections {
        function onDevicePixelRatioChanged(): void {
            manager.updateSource();
        }

        target: QsWindow.window
    }

    CachingImageManager {
        id: manager

        item: root
        cacheDir: Qt.resolvedUrl(Paths.imagecache)
    }
}
