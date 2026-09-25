import QtQuick
import QtQuick.Controls

ToolButton {
    icon.width: 16
    icon.height: 16
    focusPolicy: Qt.NoFocus

    font.pixelSize: 11
    font.weight: down || checked || highlighted ? Font.DemiBold : Font.Normal

    background: Rectangle {
        color: parent.down || parent.checked || parent.highlighted ? Qt.alpha(palette.highlight, 0.3)
                                                                   : parent.hovered ? Qt.alpha(palette.highlight, 0.15) : "transparent"
    }

    HoverHandler {
        cursorShape: hovered ? Qt.PointingHandCursor : undefined
    }
}
