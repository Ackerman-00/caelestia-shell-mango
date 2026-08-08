import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent

    signal detachRequested(mode: string)

    function clearState(): void {
        currentName = "";
        hasCurrent = false;
    }
}
