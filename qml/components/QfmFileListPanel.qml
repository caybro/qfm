import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.impl

import QfmCore

import SortFilterProxyModel

Frame {
    id: root

    property string folder: FileUtils.homePath()
    property alias sortRoleName: d.sortRoleName
    property alias ascendingSortOrder: d.ascendingSortOrder

    leftPadding: 2
    rightPadding: 2
    topPadding: 2
    bottomPadding: 2

    QtObject {
        id: d

        property string sortRoleName: "fileName"
        property bool ascendingSortOrder: true

        readonly property QfmFilesystemModel model: QfmFilesystemModel {
            baseDir: root.folder
        }
        readonly property SortFilterProxyModel proxyModel: SortFilterProxyModel {
            id: proxyModel

            sourceModel: d.model
            sorters: [
                RoleSorter {
                    roleName: "isDir"
                    sortOrder: Qt.DescendingOrder
                    enabled: d.sortRoleName === "fileName"
                },
                StringSorter {
                    roleName: d.sortRoleName
                    caseSensitivity: Qt.CaseSensitive
                    ascendingOrder: d.ascendingSortOrder
                    enabled: d.sortRoleName === "fileName"
                },
                RoleSorter {
                    roleName: d.sortRoleName
                    ascendingOrder: d.ascendingSortOrder
                    enabled: d.sortRoleName !== "fileName"
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
                    const path = FileUtils.urlToString(root.folder)
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
                onLinkActivated: link => root.folder = link
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
            HeaderButton {
                Layout.fillWidth: true
                title: qsTr("Name")
                sortRoleName: "fileName"
            }
            ToolSeparator {}
            HeaderButton {
                title: qsTr("Size")
                sortRoleName: "size"
            }
            ToolSeparator {}
            HeaderButton {
                title: qsTr("Last modified")
                sortRoleName: "modified"
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
                parent: root
                x: root.mirrored ? 1 : root.width - width
                y: listview.y
                height: listview.height
                policy: ScrollBar.AsNeeded
            }

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Home) {
                    if (event.modifiers & Qt.ControlModifier) {
                        root.folder = FileUtils.homePath()
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
                        root.folder = parentDir
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
            text: (listview.currentItem?.isSymlink ? "→ " : "") + // TODO add/display symlink target
                  listview.currentItem?.text ?? qsTr("N/A") // not ready or empty dir
            font.weight: Font.Medium
        }
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
                root.folder = model.filePath
                ListView.view.currentIndex = 0
            }
            else {
                ListView.view.currentIndex = index
                Qt.openUrlExternally(model.url)
            }
        }
    }

    component HeaderButton: QfmFileListHeaderButton {
        isCurrentSortField: d.sortRoleName === sortRoleName
        isDown: isCurrentSortField && d.ascendingSortOrder
        isUp: isCurrentSortField && !d.ascendingSortOrder
        onClicked: {
            listview.forceActiveFocus()
            isCurrentSortField ? d.ascendingSortOrder = !d.ascendingSortOrder
                               : d.sortRoleName = sortRoleName
        }
    }
}
