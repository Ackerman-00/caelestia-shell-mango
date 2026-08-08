import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.components.images
import qs.services
import qs.config
import qs.utils

Item {
    id: root

    required property PopoutState popouts

    implicitWidth: Hypr.activeToplevel ? child.implicitWidth : -Appearance.padding.large * 2
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        RowLayout {
            id: detailsRow

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            IconImage {
                id: icon

                asynchronous: true
                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(Hypr.activeToplevel?.lastIpcObject.class ?? "", "image-missing")
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: Hypr.activeToplevel?.title ?? ""
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Hypr.activeToplevel?.lastIpcObject.class ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            Item {
                implicitWidth: expandIcon.implicitHeight + Appearance.padding.small * 2
                implicitHeight: expandIcon.implicitHeight + Appearance.padding.small * 2

                Layout.alignment: Qt.AlignVCenter

                StateLayer {
                    function onClicked(): void {
                        root.popouts.detachRequested("winfo");
                    }

                    radius: Appearance.rounding.normal
                }

                MaterialIcon {
                    id: expandIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: font.pointSize * 0.05

                    text: "chevron_right"

                    font.pointSize: Appearance.font.size.large
                }
            }
        }

        ClippingWrapperRectangle {
            color: "transparent"
            radius: Appearance.rounding.small

            implicitWidth: Math.min(root.size, root.size * root.aspect)
            implicitHeight: Math.min(root.size, root.size / Math.max(root.aspect, 0.0001))

            MangoWindow {
                id: preview

                anchors.fill: parent
                captureId: Hypr.activeToplevel?.lastIpcObject.toplevelId ?? ""
            }
        }
    }

    readonly property real size: Config.bar.sizes.windowPreviewSize
    readonly property real aspect: {
        const s = Hypr.activeToplevel?.lastIpcObject.size ?? null;
        return s && s[1] > 0 ? s[0] / s[1] : 1.0;
    }
}
