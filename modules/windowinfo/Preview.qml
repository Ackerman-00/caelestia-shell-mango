pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.components.images
import qs.services
import qs.config

Item {
    id: root

    required property ShellScreen screen
    required property var client  // Changed from HyprlandToplevel

    Layout.preferredWidth: 0
    Layout.fillHeight: true

    StyledClippingRect {
        id: preview

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: label.top
        anchors.topMargin: Appearance.padding.large
        anchors.bottomMargin: Appearance.spacing.normal

        implicitWidth: view.implicitWidth

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.small

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: !root.client

            sourceComponent: ColumnLayout {
                spacing: 0

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "web_asset_off"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.extraLarge * 3
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No active client")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Try switching to a window")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.large
                }
            }
        }

        MangoWindow {
            id: view

            anchors.centerIn: parent
            captureId: root.client?.lastIpcObject.toplevelId ?? ""
            maxPixel: 800

            readonly property real aspectRatio: {
                const s = root.client?.lastIpcObject.size ?? null;
                return s && s[1] > 0 ? s[0] / s[1] : 1.0;
            }

            implicitWidth: parent.height * Math.min(root.screen.width / root.screen.height, aspectRatio)
            implicitHeight: parent.height
        }
    }

    StyledText {
        id: label

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.padding.large

        animate: true
        text: {
            const client = root.client;
            if (!client)
                return qsTr("No active client");

            const mon = client.monitor;
            return qsTr("%1 on monitor %2 at %3, %4").arg(client.title).arg(mon.name).arg(client.lastIpcObject.at[0]).arg(client.lastIpcObject.at[1]);
        }
    }
}
