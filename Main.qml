pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Controls.impl

import Qt.labs.folderlistmodel // TODO remove with custom sort fields

import QfmCore

import SortFilterProxyModel

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

    SplitView {
        id: splitview
        anchors.fill: parent

        FileListPanel {
            id: leftPanel
            SplitView.minimumWidth: 100
            SplitView.preferredWidth: parent.width/2
            focus: true
            KeyNavigation.tab: rightPanel
        }
        FileListPanel {
            id: rightPanel
            SplitView.minimumWidth: 100
            SplitView.preferredWidth: parent.width/2
            KeyNavigation.tab: leftPanel
        }
    }

    component FileListPanel: Frame {
        id: panel
        property string folder: FileUtils.homePath()

        leftPadding: 2
        rightPadding: 2
        topPadding: 2
        bottomPadding: 2

        QtObject {
            id: d
            readonly property QfmFilesystemModel model: QfmFilesystemModel {
                baseDir: panel.folder
            }
            readonly property SortFilterProxyModel proxyModel: SortFilterProxyModel {
                sourceModel: d.model
                sorters: [
                    RoleSorter {
                        roleName: "isDir"
                        sortOrder: Qt.DescendingOrder
                    },
                    StringSorter {
                        roleName: "fileName"
                        caseSensitivity: Qt.CaseSensitive
                    }
                ]
            }
        }

        contentItem: ColumnLayout {
            spacing: 0
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 8
                Label { // TODO use TruncatedLabel, turn it into a BreadcrumbLabel component
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideMiddle
                    textFormat: Text.StyledText
                    text: {
                        const path = FileUtils.urlToString(panel.folder)
                        const parts = path.split(FileUtils.pathSeparator())
                        const count = parts.length
                        let accumulatedLink = ""
                        let result = []
                        for (let i = 0; i < count; i++) {
                            const part = parts[i]
                            accumulatedLink = accumulatedLink.concat(part, FileUtils.pathSeparator())
                            result.push("<a href='%1'>%2</a>".arg(accumulatedLink).arg(part))
                        }

                        return result.join('&thinsp;%1&thinsp;').arg(FileUtils.pathSeparator())
                    }
                    font.weight: Font.Medium
                    onLinkActivated: link => panel.folder = link
                    HoverHandler {
                        cursorShape: !!parent.hoveredLink ? Qt.PointingHandCursor : undefined
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.StyledText
                    text: "&sum;&thinsp;%L1".arg(d.proxyModel.count)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                FileListHeaderButton {
                    Layout.fillWidth: true
                    title: qsTr("Name")
                    sortField: FolderListModel.Name
                    isCurrentSortField: d.model.sortField === sortField
                    isDown: isCurrentSortField && !d.model.sortReversed
                    isUp: isCurrentSortField && d.model.sortReversed
                    onClicked: isCurrentSortField ? d.model.sortReversed = !d.model.sortReversed
                                                  : d.model.sortField = sortField
                }
                ToolSeparator {}
                FileListHeaderButton {
                    title: qsTr("Size")
                    sortField: FolderListModel.Size
                    isCurrentSortField: d.model.sortField === sortField
                    isDown: isCurrentSortField && !d.model.sortReversed
                    isUp: isCurrentSortField && d.model.sortReversed
                    onClicked: isCurrentSortField ? d.model.sortReversed = !d.model.sortReversed
                                                  : d.model.sortField = sortField
                }
                ToolSeparator {}
                FileListHeaderButton {
                    title: qsTr("Last modified")
                    sortField: FolderListModel.Time
                    isCurrentSortField: d.model.sortField === sortField
                    isDown: isCurrentSortField && !d.model.sortReversed
                    isUp: isCurrentSortField && d.model.sortReversed
                    onClicked: isCurrentSortField ? d.model.sortReversed = !d.model.sortReversed
                                                  : d.model.sortField = sortField
                }
            }
            ListView {
                id: listview
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: d.proxyModel
                keyNavigationEnabled: true
                focus: true
                clip: true

                delegate: FileListItemDelegate {
                }

                ScrollBar.vertical: ScrollBar {
                    parent: panel
                    x: panel.mirrored ? 1 : panel.width - width
                    y: listview.y
                    height: listview.height
                    policy: ScrollBar.AsNeeded
                }

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Home) {
                        if (event.modifiers & Qt.ControlModifier) {
                            panel.folder = FileUtils.homePath()
                            listview.currentIndex = 0
                        } else {
                            listview.currentIndex = 0
                            listview.positionViewAtBeginning()
                        }
                    } else if (event.key === Qt.Key_End) {
                        listview.currentIndex = listview.count - 1
                        listview.positionViewAtEnd()
                    } else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) {
                        const parentDir = d.model.baseDir + "/.." // TODO add goUp() method to model
                        if (parentDir.toString() !== "") {
                            panel.folder = parentDir
                            listview.currentIndex = 0 // TODO position currentIndex on the previous parent folder
                        }
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                Layout.margins: 8
                text: (listview.currentItem?.isSymlink ? "→ " : "") + // TODO add symlink target
                      listview.currentItem?.text ?? qsTr("N/A") // not ready or empty dir
                font.weight: Font.Medium
            }
        }
    }

    component FileListHeaderButton: ToolButton {
        property string title
        property int sortField: FolderListModel.Unsorted
        property bool isCurrentSortField
        property bool isUp
        property bool isDown

        focusPolicy: Qt.NoFocus
        text: "  %1 %2".arg(title).arg(isDown ? "↓" : isUp ? "↑" : " ")
        font.weight: isCurrentSortField ? Font.DemiBold : Font.Normal
        font.pixelSize: 11
    }

    component FileListItemDelegate: ItemDelegate {
        id: delegate
        required property var model
        required property int index

        readonly property bool isSymlink: model.isSymlink

        width: ListView.view.width
        highlighted: ListView.view.activeFocus && ListView.isCurrentItem

        horizontalPadding: 8
        verticalPadding: 4

        text: model.fileName
        icon.source: model.iconSource
        icon.width: 20
        icon.height: 20

        // TODO custom `background`

        contentItem: RowLayout {
            spacing: delegate.spacing
            ColorImage {
                Layout.preferredWidth: delegate.icon.width
                Layout.preferredHeight: delegate.icon.height
                source: delegate.icon.source
                color: filenameLabel.color
            }
            Label { // TODO make a TruncatedLabel component
                id: filenameLabel
                Layout.fillWidth: true
                text: delegate.text
                elide: Text.ElideRight
                ToolTip.text: delegate.text
                ToolTip.visible: hhandler.hovered && filenameLabel.truncated
                HoverHandler {
                    id: hhandler
                }
            }
            Label {
                text: Qt.locale().formattedDataSize(delegate.model.size, 2, Locale.DataSizeTraditionalFormat)
            }
            Label {
                text: delegate.model.modified.toLocaleString(Qt.locale(), Locale.ShortFormat)
            }
        }

        // onClicked: {
        //     ListView.view.forceActiveFocus()
        //     ListView.view.currentIndex = index
        // }

        onClicked: {
            ListView.view.forceActiveFocus()
            if (model.isDir) {
                panel.folder = model.filePath
                ListView.view.currentIndex = 0
            }
            else {
                ListView.view.currentIndex = index
                Qt.openUrlExternally(model.url)
            }
        }
    }
}
