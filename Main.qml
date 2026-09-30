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

    SplitView {
        id: splitview
        anchors.fill: parent

        QfmFileListPanel {
            id: leftPanel
            SplitView.minimumWidth: 100
            SplitView.preferredWidth: parent.width/2
            focus: true
            KeyNavigation.tab: rightPanel
        }
        QfmFileListPanel {
            id: rightPanel
            SplitView.minimumWidth: 100
            SplitView.preferredWidth: parent.width/2
            KeyNavigation.tab: leftPanel
        }
    }

    Shortcut {
        sequences: [StandardKey.Quit]
        onActivated: Qt.quit()
    }
}
