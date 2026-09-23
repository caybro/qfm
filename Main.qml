import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Controls.impl

import Qt.labs.folderlistmodel
//import QtQml.Models

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

    footer: ToolBar {
        id: toolbar
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
    }

    component ToolbarButton: ToolButton {
        id: toolbarButton
        property string title
        property alias shortcut: action.shortcut
        horizontalPadding: 2

        Layout.preferredWidth: toolbar.width/10
        focusPolicy: Qt.NoFocus
        font.pixelSize: 11
        action: Action {
            id: action
            text: "%1 (%2)".arg(toolbarButton.title).arg(shortcut.toString())
            onTriggered: toolbarButton.animateClick()
        }
    }

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
        property url folder: FileUtils.homePathUrl()

        leftPadding: 2
        rightPadding: 2
        topPadding: 2
        bottomPadding: 2

        QtObject {
            id: d
            readonly property FolderListModel model: FolderListModel { // TODO custom model w/o 'dot', with permissions etc.
                folder: panel.folder
                showDirsFirst: sortField === FolderListModel.Name
                showDotAndDotDot: false
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
                        const path = FileUtils.urlToString(d.model.folder)
                        const parts = path.split(FileUtils.pathSeparator())
                        const count = parts.length
                        let accumulatedLink = ""
                        let result = []
                        for (let i = 0; i < count; i++) {
                            const part = parts[i]
                            accumulatedLink = accumulatedLink.concat(part, FileUtils.pathSeparator())
                            result.push("<a href='%1'>%2</a>".arg(FileUtils.pathToUrl(accumulatedLink)).arg(part))
                        }

                        return result.join('&thinsp;%1&thinsp;').arg(FileUtils.pathSeparator())
                    }
                    font.weight: Font.Medium
                    onLinkActivated: link => d.model.folder = link
                    HoverHandler {
                        cursorShape: !!parent.hoveredLink ? Qt.PointingHandCursor : undefined
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.StyledText
                    text: "&sum;&thinsp;%L1".arg(d.model.count - (d.model.showDotAndDotDot ? 2 : 0))
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
                // model: SortFilterProxyModel { // FIXME Qt variant doesn't work here
                //     sourceModel: d.model
                //     filters: [
                //         ValueFilter {
                //             roleName: "fileName"
                //             value: "."
                //             inverted: true
                //         }
                //     ]
                // }
                model: d.model
                keyNavigationEnabled: true
                focus: true
                clip: true

                delegate: FileListItemDelegate {
                    // FIXME use SFPM instead
                    visible: model.fileName !== "."
                    height: visible ? implicitHeight : 0
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
                            d.model.folder = FileUtils.homePathUrl()
                            listview.currentIndex = 0
                        } else {
                            listview.currentIndex = 0
                            listview.positionViewAtBeginning()
                        }
                    } else if (event.key === Qt.Key_End) {
                        listview.currentIndex = listview.count - 1
                        listview.positionViewAtEnd()
                    } else if (event.key === Qt.Key_Backspace) {
                        const parentDir = d.model.parentFolder
                        if (parentDir.toString() !== "") {
                            d.model.folder = parentDir
                            listview.currentIndex = 0
                        }
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: 8
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: d.model.get(listview.currentIndex, "fileName") ?? ""
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

        width: ListView.view.width
        highlighted: ListView.view.activeFocus && ListView.isCurrentItem

        horizontalPadding: 8
        verticalPadding: 4

        text: model.fileName
        icon.source: model.fileIsDir ? "icons/folder.svg" : "icons/file.svg"
        icon.width: 20
        icon.height: 20

        // TODO custom `background`

        contentItem: RowLayout {
            spacing: delegate.spacing
            ColorImage {
                width: delegate.icon.width
                height: delegate.icon.height
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
                text: Qt.locale().formattedDataSize(model.fileSize, 2, Locale.DataSizeTraditionalFormat)
            }
            Label {
                text: model.fileModified.toLocaleString(Qt.locale(), Locale.ShortFormat)
            }
        }

        // onClicked: {
        //     ListView.view.forceActiveFocus()
        //     ListView.view.currentIndex = index
        // }

        onClicked: {
            ListView.view.forceActiveFocus()
            if (model.fileIsDir) {
                d.model.folder = model.fileUrl
                ListView.view.currentIndex = 0
            }
            else {
                ListView.view.currentIndex = index
                Qt.openUrlExternally(model.fileUrl)
            }
        }
    }
}
