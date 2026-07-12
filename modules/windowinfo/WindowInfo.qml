import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property ShellScreen screen
    required property var client  // Changed from HyprlandToplevel
    signal closeRequested()

    implicitWidth: child.implicitWidth
    implicitHeight: screen.height * Config.winfo.sizes.heightMult

    RowLayout {
        id: child

        anchors.fill: parent
        anchors.margins: Appearance.padding.large

        spacing: Appearance.spacing.normal

        Preview {
            screen: root.screen
            client: root.client
        }

        ColumnLayout {
            spacing: Appearance.spacing.normal

            Layout.preferredWidth: Config.winfo.sizes.detailsWidth
            Layout.fillHeight: true

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: Colours.tPalette.m3surfaceContainer
                radius: Appearance.rounding.normal

                Details {
                    client: root.client
                }

                StateLayer {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Appearance.padding.small

                    implicitWidth: closeIcon.implicitWidth + Appearance.padding.small * 2
                    implicitHeight: closeIcon.implicitHeight + Appearance.padding.small * 2

                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        root.closeRequested();
                    }

                    MaterialIcon {
                        id: closeIcon
                        anchors.centerIn: parent
                        text: "close"
                        font.pointSize: Appearance.font.size.large
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: buttons.implicitHeight

                color: Colours.tPalette.m3surfaceContainer
                radius: Appearance.rounding.normal

                Buttons {
                    id: buttons

                    client: root.client
                }
            }
        }
    }
}
