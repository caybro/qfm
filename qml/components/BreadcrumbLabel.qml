import QtQuick
import QtQuick.Controls

import QfmCore

TruncatedLabel {
    id: root

    property string folder

    elide: Text.ElideMiddle
    textFormat: Text.StyledText
    font.weight: Font.Medium

    text: {
        const path = FileUtils.urlToString(root.folder)
        const parts = path.split(FileUtils.pathSeparator)
        const count = parts.length
        let accumulatedLink = ""
        let result = []
        for (let i = 0; i < count; i++) {
            const part = parts[i]
            accumulatedLink = accumulatedLink.concat(part, FileUtils.pathSeparator)
            if (i === count - 1)
                result.push(part)
            else
                result.push("<a href='%1'>%2</a>".arg(accumulatedLink).arg(part))
        }
        
        return result.join('&thinsp;%1&thinsp;').arg(FileUtils.pathSeparator)
    }
}
