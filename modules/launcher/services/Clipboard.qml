pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.config
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${Config.launcher.actionPrefix}clipboard`.length).replace(/^\s+/, "");
    }

    function reload(): void {
        getHistory.running = true;
    }

    function mimeFor(preview: string): string {
        const match = preview.match(/([a-z0-9-]+) \d+x\d+ \]\]$/i);
        if (!match)
            return "image/png";

        const format = match[1].toLowerCase();
        if (format === "svg")
            return "image/svg+xml";
        if (format === "tif" || format === "tiff")
            return "image/tiff";
        return `image/${format}`;
    }

    function formatFor(preview: string): string {
        if (preview.startsWith("\x89PNG") || preview.includes("IHDR"))
            return "PNG";
        if (preview.startsWith("\xFF\xD8"))
            return "JPEG";
        return "";
    }

    list: entries.instances
    useFuzzy: Config.launcher.useFuzzy.clipboard
    key: "preview"
    keys: ["preview"]
    weights: [1]

    Variants {
        id: entries

        Entry {}
    }

    Process {
        id: getHistory

        running: true
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                entries.model = text.split("\n").filter(line => line.length > 0).map(line => {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        return null;

                    const dbId = line.slice(0, tab);
                    const preview = line.slice(tab + 1);
                    const marker = preview.startsWith("[[ binary data ");
                    const rawBinary = !marker && /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/.test(preview);
                    const binary = marker || rawBinary;
                    const format = root.formatFor(preview);

                    return {
                        dbId,
                        preview: binary && !marker ? `Image (${format || "clipboard"})` : preview,
                        binary,
                        mime: marker ? root.mimeFor(preview) : ""
                    };
                }).filter(entry => entry !== null);
            }
        }
    }

    component Entry: QtObject {
        required property var modelData

        readonly property string entryId: modelData.dbId
        readonly property string preview: modelData.preview
        readonly property bool binary: modelData.binary
        readonly property string mime: modelData.mime

        function onClicked(list: AppList): void {
            list.visibilities.launcher = false;

            const command = binary
                ? mime
                    ? `cliphist decode ${entryId} | wl-copy --type ${mime}`
                    : `f=$(mktemp) && cliphist decode ${entryId} > "$f" && wl-copy --type "$(file -b --mime-type "$f")" < "$f" && rm -f "$f"`
                : `cliphist decode ${entryId} | wl-copy`;

            Quickshell.execDetached(["sh", "-c", command]);
            Toaster.toast(qsTr("Copied to clipboard"), binary ? qsTr("Image copied to clipboard") : qsTr("Text copied to clipboard"), "content_copy");
        }

        function remove(): void {
            Quickshell.execDetached(["cliphist", "delete", entryId]);
            root.reload();
        }
    }
}
