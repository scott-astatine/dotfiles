import QtQuick
import Quickshell
import "../core"
import "../core/functions"
import "."

StyledText {
    text: "Some body content"
    color: Appearance.colors.colOnSurfaceVariant
    font.pixelSize: Appearance.font.pixelSize.small
    wrapMode: Text.Wrap
}
