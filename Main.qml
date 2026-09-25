import QtCore
import QtQuick
import QtQuick.Controls.Basic

import QfmCore

ApplicationWindow {
    id: root
    width: 1024
    height: 768
    minimumWidth: 250
    minimumHeight: 200
    visible: true

    title: FileUtils.urlToString(leftPanel.focus ? leftPanel.folder : rightPanel.folder)

    font.family: "JetBrains Mono"
    font.pixelSize: 12

    footer: QfmToolbar {}

    Component.onCompleted: splitview.restoreState(settings.value("splitview"))
    Component.onDestruction: settings.setValue("splitview", splitview.saveState())

    Settings {
        id: settings

        property alias x: root.x
        property alias y: root.y
        property alias width: root.width
        property alias height: root.height

        property alias leftPanelFolder: leftPanel.folder
        property alias leftPanelSortRoleName: leftPanel.sortRoleName
        property alias leftPanelAscendingSortOrder: leftPanel.ascendingSortOrder
        property alias leftPanelShowHiddenFiles: leftPanel.showHiddenFiles

        property alias rightPanelFolder: rightPanel.folder
        property alias rightPanelSortRoleName: rightPanel.sortRoleName
        property alias rightPanelAscendingSortOrder: rightPanel.ascendingSortOrder
        property alias rightPanelShowHiddenFiles: rightPanel.showHiddenFiles
    }

    function handleShortcut(event, panel) {
        if (event.key === Qt.Key_Home) {
            if (event.modifiers & Qt.ControlModifier) {
                panel.folder = FileUtils.homePath
                panel.listview.currentIndex = 0
            } else {
                panel.listview.currentIndex = 0
                panel.listview.positionViewAtBeginning()
            }
        } else if (event.key === Qt.Key_End) {
            panel.listview.currentIndex = panel.listview.count - 1
            panel.listview.positionViewAtEnd()
        } else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Left || event.matches(StandardKey.Back)) {
            const parentDir = panel.folder + "/.." // TODO add goUp() method to model
            if (parentDir.toString() !== "") {
                panel.folder = parentDir
                panel.listview.currentIndex = 0 // TODO position currentIndex on the previous parent folder
            }
        } else if (event.key === Qt.Key_Slash && (event.modifiers & Qt.ControlModifier)) {
            panel.folder = FileUtils.rootPath
            panel.listview.currentIndex = 0
        }
    }

    SplitView {
        id: splitview
        anchors.fill: parent

        QfmFileListPanel {
            id: leftPanel
            SplitView.minimumWidth: 100
            SplitView.preferredWidth: parent.width/2
            focus: true
            KeyNavigation.tab: rightPanel
            Keys.onPressed: event => handleShortcut(event, leftPanel)
        }
        QfmFileListPanel {
            id: rightPanel
            SplitView.minimumWidth: 100
            SplitView.preferredWidth: parent.width/2
            KeyNavigation.tab: leftPanel
            Keys.onPressed: event => handleShortcut(event, rightPanel)
        }
    }

    Shortcut {
        sequences: [StandardKey.Quit]
        onActivated: Qt.quit()
    }
}
