import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.impl

import QfmCore

ItemDelegate {
    id: root

    required property var model
    required property int index
    
    readonly property string fileName: model.fileName
    readonly property bool isSymlink: model.isSymlink
    readonly property string symlinkTarget: model.symlinkTarget
    readonly property string permissionsString: model.permissionsString

    signal navigateTo(string directory)
    
    width: ListView.view.width
    highlighted: ListView.view.activeFocus && ListView.isCurrentItem
    
    horizontalPadding: 8
    topPadding: 2
    bottomPadding: 2
    
    text: model.fileName
    icon.source: model.iconSource
    icon.width: 20
    icon.height: 20
    icon.color: model.isReadable ? (model.isSelected ? palette.accent : palette.text)
                                 : palette.disabled.text
    
    background: Rectangle {
        color: {
            if (parent.down || parent.checked || parent.highlighted)
                return Qt.alpha(palette.highlight, 0.25)
            if (parent.hovered)
                return Qt.alpha(palette.highlight, 0.15)
            
            return "transparent"
        }
    }
    
    contentItem: RowLayout {
        spacing: root.spacing
        ColorImage {
            Layout.preferredWidth: root.icon.width
            Layout.preferredHeight: root.icon.height
            source: root.icon.source
            color: root.icon.color
        }
        TruncatedLabel {
            id: filenameLabel
            Layout.fillWidth: true
            text: root.text
            font.weight: root.model.isDir ? Font.Bold : Font.Normal
            font.italic: root.model.isSymlink
            color: root.icon.color
        }
        Label {
            text: Qt.locale().formattedDataSize(root.model.size, 2, Locale.DataSizeTraditionalFormat)
            color: root.icon.color
        }
        Label {
            text: root.model.modified.toLocaleString(Qt.locale(), Locale.ShortFormat) // TODO find a more suitable/compact format
            color: root.icon.color
        }
    }
    
    function select() {
        ListView.view.forceActiveFocus()
        ListView.view.currentIndex = index
    }
    
    function activate() {
        ListView.view.forceActiveFocus()
        
        if (!model.isReadable)
            return
        
        if (model.isDir) { // DIR
            root.navigateTo(model.filePath)
        } else { // FILE
            ListView.view.currentIndex = index
            Qt.openUrlExternally(model.url)
        }
    }
    
    onClicked: select()
    onDoubleClicked: activate()
}
