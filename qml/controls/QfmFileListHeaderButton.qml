import QtQuick
import QtQuick.Controls

import QfmCore

QfmToolButton {
    property string title
    property string sortRoleName
    property bool isUp
    property bool isDown

    text: "  %1 %2".arg(title).arg(isDown ? "↓" : isUp ? "↑" : " ")
}
