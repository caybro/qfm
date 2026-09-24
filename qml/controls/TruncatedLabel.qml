import QtQuick
import QtQuick.Controls

Label {
    id: root

    elide: Text.ElideRight

    ToolTip.text: root.text
    ToolTip.visible: hhandler.hovered && truncated

    HoverHandler {
        id: hhandler
    }
}
