import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.impl

import QfmCore

import SortFilterProxyModel

Frame {
    id: root

    property string folder: FileUtils.homePath
    property alias sortRoleName: d.sortRoleName
    property alias ascendingSortOrder: d.ascendingSortOrder
    property alias showHiddenFiles: d.showHiddenFiles

    property alias listview: listview

    leftPadding: 2
    rightPadding: 2
    topPadding: 2
    bottomPadding: 2

    QtObject {
        id: d

        property string sortRoleName: "fileName"
        property bool ascendingSortOrder: true
        property bool showHiddenFiles: true

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
            filters: [
                ValueFilter {
                    roleName: "isHidden"
                    value: false
                    enabled: !d.showHiddenFiles
                }
            ]
        }
    }

    contentItem: ColumnLayout {
        spacing: 1
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8

            Label { // TODO use TruncatedLabel, turn it into a BreadcrumbLabel component
                Layout.fillWidth: true
                elide: Text.ElideMiddle
                textFormat: Text.StyledText
                text: {
                    const path = FileUtils.urlToString(root.folder)
                    const parts = path.split(FileUtils.pathSeparator)
                    const count = parts.length
                    let accumulatedLink = ""
                    let result = []
                    for (let i = 0; i < count; i++) {
                        const part = parts[i]
                        accumulatedLink = accumulatedLink.concat(part, FileUtils.pathSeparator)
                        result.push("<a href='%1'>%2</a>".arg(accumulatedLink).arg(part))
                    }

                    return result.join('&thinsp;%1&thinsp;').arg(FileUtils.pathSeparator)
                }
                font.weight: Font.Medium
                onLinkActivated: link => root.folder = link
                HoverHandler {
                    cursorShape: !!parent.hoveredLink ? Qt.PointingHandCursor : undefined
                }
            }
            Label {
                textFormat: Text.StyledText
                text: "&sum;&thinsp;%L1".arg(d.proxyModel.count)
            }
            QfmToolButton {
                icon.source: "../../icons/visibility_off.svg"
                checkable: true
                checked: d.showHiddenFiles
                onToggled: d.showHiddenFiles = checked
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

            delegate: FileListItemDelegate {}

            ScrollBar.vertical: ScrollBar {
                parent: root
                x: root.mirrored ? 1 : root.width - width
                y: listview.y
                height: listview.height
                policy: ScrollBar.AsNeeded
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            Label {
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight

                text: {
                    if (!listview.currentItem)
                        return qsTr("N/A") // not ready or empty dir
                    return listview.currentItem.isSymlink ? "%1 → %2".arg(listview.currentItem.text).arg(listview.currentItem.symlinkTarget)
                                                          : listview.currentItem.text
                }

                font.weight: Font.Medium
            }
            Label {
                verticalAlignment: Text.AlignVCenter
                text: listview.currentItem?.permissionsString ?? "???"
                font.weight: Font.Medium
            }
        }
    }

    component FileListItemDelegate: ItemDelegate { // TODO separate component
        id: delegate
        required property var model
        required property int index

        readonly property bool isSymlink: model.isSymlink
        readonly property string symlinkTarget: model.symlinkTarget
        readonly property string permissionsString: model.permissionsString

        width: ListView.view.width
        highlighted: ListView.view.activeFocus && ListView.isCurrentItem

        horizontalPadding: 8
        topPadding: 2
        bottomPadding: 2

        text: model.fileName
        icon.source: model.iconSource
        icon.width: 20
        icon.height: 20

        enabled: model.isReadable // TODO custom `background`

        contentItem: RowLayout {
            spacing: delegate.spacing
            ColorImage {
                Layout.preferredWidth: delegate.icon.width
                Layout.preferredHeight: delegate.icon.height
                source: delegate.icon.source
                color: filenameLabel.color
            }
            TruncatedLabel {
                id: filenameLabel
                Layout.fillWidth: true
                text: delegate.text
            }
            Label {
                text: Qt.locale().formattedDataSize(delegate.model.size, 0, Locale.DataSizeTraditionalFormat)
            }
            Label {
                text: delegate.model.modified.toLocaleString(Qt.locale(), Locale.ShortFormat) // TODO find a more suitable/compact format
            }
        }

        // onClicked: {
        //     ListView.view.forceActiveFocus()
        //     ListView.view.currentIndex = index
        // }

        onClicked: {
            ListView.view.forceActiveFocus()

            if (!model.isReadable)
                return

            if (model.isDir) { // DIR
                root.folder = model.filePath
                ListView.view.currentIndex = 0
            } else { // FILE
                ListView.view.currentIndex = index
                Qt.openUrlExternally(model.url)
            }
        }
    }

    component HeaderButton: QfmFileListHeaderButton {
        checked: d.sortRoleName === sortRoleName
        isDown: checked && d.ascendingSortOrder
        isUp: checked && !d.ascendingSortOrder
        onClicked: {
            listview.forceActiveFocus()
            checked ? d.ascendingSortOrder = !d.ascendingSortOrder
                    : d.sortRoleName = sortRoleName
        }
    }
}
