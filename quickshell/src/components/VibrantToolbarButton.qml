import QtQuick
import QtQuick.Layouts
import "../core"
import "../core/functions"

ToolbarButton {
    colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
    colRipple: Appearance.colors.colPrimaryContainerActive
}
