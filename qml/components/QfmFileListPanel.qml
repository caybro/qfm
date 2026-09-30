import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.impl

import QfmCore

import SortFilterProxyModel

Pane {
    id: root

    property string folder: FileUtils.homePath
    property alias sortRoleName: d.sortRoleName
    property alias ascendingSortOrder: d.ascendingSortOrder
    property alias showHiddenFiles: d.baseModel.showHiddenFiles

    property alias listview: listview

    onFolderChanged: {
        if (typeAheadArea.visible)
            typeAheadArea.close()
        listview.currentIndex = 0
    }

    leftPadding: 2
    rightPadding: 2
    topPadding: 2
    bottomPadding: 2

    QtObject {
        id: d

        property string sortRoleName: "fileName"
        property bool ascendingSortOrder: true

        readonly property QfmFilesystemModel baseModel: QfmFilesystemModel {
            id: baseModel
            baseDir: root.folder
        }

        readonly property SortFilterProxyModel proxyModel: SortFilterProxyModel {
            id: proxyModel
            sourceModel: d.baseModel
            sorters: [
                RoleSorter {
                    roleName: "isDir"
                    sortOrder: Qt.DescendingOrder // always dirs first
                },
                StringSorter {
                    roleName: "fileName"
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
                RegExpFilter {
                    pattern: `*${typeAheadArea.text}*`
                    caseSensitivity: btnMatchCase.checked ? Qt.CaseSensitive : Qt.CaseInsensitive
                    syntax: RegExpFilter.Wildcard
                    enabled: !!pattern && typeAheadArea.visible
                }
            ]
        }
    }

    TapHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        acceptedButtons: Qt.BackButton
        onTapped: cdUp()
    }

    function cdUp() {
        const parentDir = FileUtils.parentDir(root.folder)
        if (parentDir.toString() !== "") {
            root.folder = parentDir
            // TODO position currentIndex on the previous parent folder
        }
    }

    contentItem: ColumnLayout {
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8

            BreadcrumbLabel {
                Layout.fillWidth: true
                folder: root.folder
                onLinkActivated: link => root.folder = link
            }
            Label {
                textFormat: Text.StyledText
                text: {
                    const fileCount = d.proxyModel.count
                    if (d.baseModel.selectedFiles.count > 0)
                        return "&sum;&thinsp;%L1 (%2)/%L3".arg(d.baseModel.selectedFiles.count)
                                                          .arg(Qt.locale().formattedDataSize(d.baseModel.selectedFiles.totalBytes, 2, Locale.DataSizeTraditionalFormat))
                                                          .arg(fileCount)
                    return "&sum;&thinsp;%L1".arg(fileCount)
                }
            }
            QfmToolButton {
                icon.source: "qrc:/qt/qml/QfmCore/icons/visibility_off.svg"
                checkable: true
                checked: d.baseModel.showHiddenFiles
                onToggled: d.baseModel.showHiddenFiles = checked
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Show hidden files")
            }
        }
        Separator {}
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            HeaderButton {
                Layout.fillWidth: true
                title: qsTr("Name")
                sortRoleName: "fileName"
            }
            Separator { vertical: true }
            HeaderButton {
                title: qsTr("Size")
                sortRoleName: "size"
            }
            Separator { vertical: true }
            HeaderButton {
                title: qsTr("Last modified")
                sortRoleName: "modified"
            }
        }
        Separator {}
        ListView {
            id: listview
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: d.proxyModel
            keyNavigationEnabled: true
            focus: true
            clip: true
            snapMode: ListView.SnapOneItem

            delegate: QfmFileListItemDelegate {
                onNavigateTo: directory => root.folder = directory
            }

            ScrollBar.vertical: ScrollBar {
                parent: root
                x: root.mirrored ? 1 : root.width - width
                y: listview.y
                height: listview.height
                policy: ScrollBar.AsNeeded
            }

            function pageStep() {
                const firstVisibleIndex = indexAt(0, contentY + 1)
                const lastVisibleIndex = indexAt(0, contentY + height - 1)
                if (firstVisibleIndex >= 0 && lastVisibleIndex > firstVisibleIndex)
                    return lastVisibleIndex - firstVisibleIndex

                return Math.max(1, Math.floor(height / Math.max(currentItem?.height ?? 1, 1)) - 1)
            }

            function movePage(direction) {
                if (count === 0)
                    return

                const baseIndex = currentIndex >= 0 ? currentIndex : direction > 0 ? 0 : count - 1
                currentIndex = Math.max(0, Math.min(count - 1, baseIndex + direction * pageStep()))
                positionViewAtIndex(currentIndex, direction > 0 ? ListView.Beginning : ListView.End)
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    event.accepted = true
                    if (!!currentItem)
                        currentItem.activate()
                } else if (event.key === Qt.Key_PageUp) {
                    event.accepted = true
                    movePage(-1)
                } else if (event.key === Qt.Key_PageDown) {
                    event.accepted = true
                    movePage(1)
                } else if ((((event.modifiers & Qt.ControlModifier) || (event.modifiers & Qt.AltModifier)) && event.key === Qt.Key_S)) {// Ctrl+S or Alt+S
                    event.accepted = true
                    if (!typeAheadArea.visible)
                        typeAheadArea.open()
                    else {
                        typeAheadArea.forceActiveFocus()
                        // TODO cycle search
                    }
                } else if (event.key === Qt.Key_Insert) {
                    d.baseModel.toggleSelectedFile(d.proxyModel.mapToSource(listview.currentIndex))
                    listview.incrementCurrentIndex()
                } else if (event.key === Qt.Key_Plus) {
                    d.baseModel.selectAllFiles() // TODO dialog to select an optional pattern
                } else if (event.key === Qt.Key_Minus) {
                    d.baseModel.clearSelectedFiles(); // TODO a dialog to deselect
                } else if (event.key === Qt.Key_Asterisk) {
                    d.baseModel.toggleAllFiles()
                } else if (event.key === Qt.Key_Home) {
                    if (event.modifiers & Qt.ControlModifier) {
                        root.folder = FileUtils.homePath
                        listview.currentIndex = 0
                    } else {
                        listview.currentIndex = 0
                        listview.positionViewAtBeginning()
                    }
                } else if (event.key === Qt.Key_End) {
                    listview.currentIndex = listview.count - 1
                    listview.positionViewAtEnd()
                } else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Left || event.matches(StandardKey.Back)) {
                    root.cdUp()
                } else if (event.key === Qt.Key_Slash && (event.modifiers & Qt.ControlModifier)) {
                    root.folder = FileUtils.rootPath
                    listview.currentIndex = 0
                }
            }
            Keys.onEscapePressed: typeAheadArea.close()
        }
        Separator {}
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            visible: !typeAheadArea.visible
            TruncatedLabel {
                Layout.fillWidth: true
                text: {
                    const current = listview.currentItem
                    if (!current)
                        return qsTr("N/A") // not ready or empty dir
                    return current.isSymlink ? "→ " + current.symlinkTarget : current.text
                }
                font.weight: Font.Medium
            }
            Label {
                text: listview.currentItem?.permissionsString ?? "???"
                font.weight: Font.Medium
            }
        }
        TextInput {
            Layout.fillWidth: true
            Layout.margins: 8

            id: typeAheadArea
            visible: false
            onAccepted: close()

            Keys.onEscapePressed: close()
            Keys.onUpPressed: {
                listview.forceActiveFocus()
                listview.decrementCurrentIndex()
            }
            Keys.onDownPressed: {
                listview.forceActiveFocus()
                listview.incrementCurrentIndex()
            }

            function open() {
                clear()
                visible = true
                forceActiveFocus()
            }

            function close() {
                listview.forceActiveFocus()
                listview.positionViewAtIndex(listview.currentIndex, ListView.Beginning)
                visible = false
            }

            QfmToolButton {
                id: btnMatchCase
                anchors.right: parent.right
                anchors.rightMargin: parent.rightPadding
                anchors.verticalCenter: parent.verticalCenter
                checkable: true
                checked: true
                icon.source: checked ? "qrc:/qt/qml/QfmCore/icons/match_case.svg" : "qrc:/qt/qml/QfmCore/icons/match_case_off.svg"

                ToolTip.visible: hovered
                ToolTip.text: checked ? qsTr("Case sensitive") : qsTr("Case insensitive")
            }
        }
    }

    component HeaderButton: QfmFileListHeaderButton {
        background: Rectangle {
            color: "transparent"
        }
        checked: d.sortRoleName === sortRoleName
        isDown: checked && d.ascendingSortOrder
        isUp: checked && !d.ascendingSortOrder
        onClicked: {
            listview.forceActiveFocus()
            checked ? d.ascendingSortOrder = !d.ascendingSortOrder
                    : d.sortRoleName = sortRoleName
        }
    }

    component Separator: Rectangle {
        property bool vertical
        Layout.fillWidth: !vertical
        Layout.preferredHeight: vertical ? parent.height : 1
        Layout.preferredWidth: vertical ? 1 : -1
        color: root.palette.button
    }
}
