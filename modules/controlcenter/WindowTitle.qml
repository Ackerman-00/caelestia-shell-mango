import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.config

StyledRect {
    id: root

    required property ShellScreen screen
    required property Session session

    implicitHeight: text.implicitHeight + Appearance.padding.normal
    color: Colours.tPalette.m3surfaceContainer

    StyledText {
        id: text

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        text: qsTr("Caelestia Settings - %1").arg(root.session.active)
        font.capitalization: Font.Capitalize
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Appearance.padding.normal

        width: closeIcon.implicitHeight + Appearance.padding.normal
        height: closeIcon.implicitHeight + Appearance.padding.normal

        StateLayer {
            function onClicked(): void {
                root.session.root.close();
            }

            radius: Appearance.rounding.full
        }

        MaterialIcon {
            id: closeIcon

            anchors.centerIn: parent
            text: "close"
        }
    }
}
