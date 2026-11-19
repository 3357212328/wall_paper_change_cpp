import QtQuick
import AuraPaper

Rectangle {
    id: root

    property bool hoverHighlight: false
    property color highlightColor: Theme.borderStrong
    property bool hovered: false

    radius: Theme.radiusLg
    color: Theme.cardBg
    border.width: 1
    border.color: (hoverHighlight && hovered) ? highlightColor : Theme.border

    Behavior on border.color { ColorAnimation { duration: 180 } }
}
