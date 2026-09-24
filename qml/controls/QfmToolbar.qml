import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ToolBar {
    id: root

    RowLayout {
        spacing: 0
        anchors.fill: parent
        ToolbarButton {
            title: qsTr("Help")
            shortcut: "F1"
        }
        ToolbarButton {
            title: qsTr("Menu")
            shortcut: "F2"
        }
        ToolbarButton {
            title: qsTr("View")
            shortcut: "F3"
        }
        ToolbarButton {
            title: qsTr("Edit")
            shortcut: "F4"
        }
        ToolbarButton {
            title: qsTr("Copy")
            shortcut: "F5"
        }
        ToolbarButton {
            title: qsTr("Rename")
            shortcut: "F6"
        }
        ToolbarButton {
            title: qsTr("New")
            shortcut: "F7"
        }
        ToolbarButton {
            title: qsTr("Delete")
            shortcut: "F8"
        }
        ToolbarButton {
            title: qsTr("Symlink")
            shortcut: "F9"
        }
        ToolbarButton {
            title: qsTr("Quit")
            shortcut: "F10"
            onClicked: Qt.quit() // TODO confirm when an ongoing operation
        }
    }

    component ToolbarButton: ToolButton {
        id: toolbarButton
        property string title
        property alias shortcut: action.shortcut
        horizontalPadding: 2

        Layout.preferredWidth: root.width/10
        focusPolicy: Qt.NoFocus
        font.pixelSize: 11
        action: Action {
            id: action
            text: "%1 (%2)".arg(toolbarButton.title).arg(shortcut.toString())
            onTriggered: toolbarButton.animateClick()
        }
    }
}
