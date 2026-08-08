import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config
import qs.modules.launcher.services

Item {
    id: root

    required property Clipboard.Entry modelData
    required property var list

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        id: rowHover

        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }

        radius: Appearance.rounding.normal
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.larger

        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: root.modelData?.binary ? "image" : "content_copy"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.extraLarge

            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: root.modelData?.preview ?? ""
            color: root.modelData?.binary ? Colours.palette.m3outline : Colours.palette.m3onSurface
            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        StyledRect {
            id: deleteWrapper

            color: Colours.palette.m3errorContainer
            radius: Appearance.rounding.normal
            clip: true

            implicitWidth: deleteIcon.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: deleteIcon.implicitHeight + Appearance.padding.small * 2

            opacity: rowHover.containsMouse || deleteHover.containsMouse ? 1 : 0
            scale: rowHover.containsMouse || deleteHover.containsMouse ? 1 : 0.7

            Layout.alignment: Qt.AlignVCenter

            StateLayer {
                id: deleteHover

                enabled: rowHover.containsMouse

                function onClicked(): void {
                    root.modelData?.remove();
                }

                color: Colours.palette.m3onErrorContainer
                radius: Appearance.rounding.normal
            }

            MaterialIcon {
                id: deleteIcon

                anchors.centerIn: parent

                text: "delete"
                color: Colours.palette.m3onErrorContainer
                font.pointSize: Appearance.font.size.normal
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }
}
