import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core"
import "../core/functions"
import "."

RowLayout {
    id: root
    spacing: 4

    // These shouldn't be needed but it would be a terrible waste of space to follow the spec
    Layout.margins: -8
    Layout.topMargin: 0
}
