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

        readonly property SortFilterProxyModel proxyModel: SortFilterProxyModel {
            id: proxyModel

            sourceModel: QfmFilesystemModel {
                baseDir: root.folder
            }
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
                },
                RegExpFilter {
                    pattern: `*${typeAheadArea.text}*`
                    caseSensitivity: btnMatchCase.checked ? Qt.CaseSensitive : Qt.CaseInsensitive
                    syntax: RegExpFilter.Wildcard
                    enabled: !!pattern && typeAheadArea.visible
                }
            ]
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
                text: "&sum;&thinsp;%L1".arg(d.proxyModel.count)
            }
            QfmToolButton {
                icon.source: "qrc:/qt/qml/QfmCore/icons/visibility_off.svg"
                checkable: true
                checked: d.showHiddenFiles
                onToggled: d.showHiddenFiles = checked
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
        Separator {}
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

            Keys.onPressed: function(event) {
                /*if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    console.warn("!!! ENTER PRESSED")
                    event.accept = true
                    if (!!currentItem)
                        currentItem.activate()
                }*/
                if (((event.modifiers & Qt.ControlModifier) || (event.modifiers & Qt.AltModifier)) && event.key === Qt.Key_S) { // Ctrl+S or Alt+S
                    event.accepted = true
                    if (!typeAheadArea.visible)
                        typeAheadArea.open()
                    else {
                        typeAheadArea.forceActiveFocus()
                        // TODO cycle search
                    }
                }
            }
            Keys.onEscapePressed: typeAheadArea.close()
        }
        Separator {}
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            visible: !typeAheadArea.visible
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
        TextField {
            Layout.fillWidth: true
            Layout.margins: 8

            id: typeAheadArea
            visible: false
            placeholderText: "/"
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
                checked: true
                checkable: true
                icon.source: checked ? "qrc:/qt/qml/QfmCore/icons/match_case.svg" : "qrc:/qt/qml/QfmCore/icons/match_case_off.svg"

                ToolTip.visible: hovered
                ToolTip.text: checked ? qsTr("Case sensitive") : qsTr("Case insensitive")
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
                font.weight: delegate.model.isDir ? Font.Bold : Font.Normal
            }
            Label {
                text: Qt.locale().formattedDataSize(delegate.model.size, 2, Locale.DataSizeTraditionalFormat)
            }
            Label {
                text: delegate.model.modified.toLocaleString(Qt.locale(), Locale.ShortFormat) // TODO find a more suitable/compact format
            }
        }

        function selectItem() {
            ListView.view.forceActiveFocus()
            ListView.view.currentIndex = index
        }

        function activateItem() {
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

        onClicked: activateItem()
        //onClicked: selectItem()
        //onDoubleClicked: activateItem()
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

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: root.palette.button
    }
}
