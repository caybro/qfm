import QtQuick
import QtQuick.Controls

ToolButton {
    property string title
    property string sortRoleName
    property bool isCurrentSortField
    property bool isUp
    property bool isDown

    focusPolicy: Qt.NoFocus
    text: "  %1 %2".arg(title).arg(isDown ? "↓" : isUp ? "↑" : " ")
    font.weight: isCurrentSortField ? Font.DemiBold : Font.Normal
    font.pixelSize: 11
}
