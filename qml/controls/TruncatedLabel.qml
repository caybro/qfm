import QtQuick
import QtQuick.Controls

Label {
    elide: Text.ElideRight

    ToolTip.text: text
    ToolTip.visible: hhandler.hovered && truncated

    HoverHandler {
        id: hhandler
        cursorShape: !!parent.hoveredLink ? Qt.PointingHandCursor : undefined
    }
}
