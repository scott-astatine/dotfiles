import "../core"
import "../core/functions"
import "."
import QtQuick

RippleButton {
    id: root
    property bool active: false
    property bool isCurrentItem: false

    horizontalPadding: Appearance.rounding.large
    verticalPadding: 12

    clip: true
    pointingHandCursor: !active    
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    colBackground: (isCurrentItem || active) ? Appearance.colors.colLayer3Hover : ColorUtils.transparentize(Appearance.colors.colLayer3)
    colBackgroundHover: Appearance.colors.colLayer3Hover
    colRipple: Appearance.colors.colLayer3Active
    buttonRadius: Appearance.rounding.small
}
