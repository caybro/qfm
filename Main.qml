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

    property bool lightMode: Application.styleHints.colorScheme === Qt.Light

    property color reallyDark: "#1f1f1f"
    property color dark: "#262626"
    property color reallyLight: "#e7e7e7"
    property color light: "#e0e0e0"

    font.family: "JetBrains Mono"
    font.pixelSize: 12

    footer: QfmToolbar {}

    Component.onCompleted: splitview.restoreState(settings.value("splitview"))
    Component.onDestruction: settings.setValue("splitview", splitview.saveState())

    Settings {
        id: settings
        property alias leftPanelFolder: leftPanel.folder
        property alias leftPanelSortRoleName: leftPanel.sortRoleName
        property alias leftPanelAscendingSortOrder: leftPanel.ascendingSortOrder
        property alias rightPanelFolder: rightPanel.folder
        property alias rightPanelSortRoleName: rightPanel.sortRoleName
        property alias rightPanelAscendingSortOrder: rightPanel.ascendingSortOrder
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
}
