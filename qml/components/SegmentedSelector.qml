import QtQuick
import QtQuick.Layouts
import AuraPaper

Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    property color accentColor: Theme.accent
    signal selected(int index)

    implicitHeight: 38
    height: 38
    radius: Theme.radiusSm + 3
    color: Theme.inputBg
    border.width: 1
    border.color: Theme.border

    readonly property real pad: 3
    readonly property int itemCount: model ? model.length : 0
    readonly property real itemWidth: itemCount > 0 ? (width - pad * 2) / itemCount : 0

    // Animated sliding highlight pill
    Rectangle {
        id: indicator
        visible: root.itemCount > 0
        y: root.pad
        height: root.height - root.pad * 2
        width: Math.max(0, root.itemWidth)
        x: root.pad + root.currentIndex * root.itemWidth
        radius: Theme.radiusSm
        color: root.accentColor

        Behavior on x {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Row {
        anchors.fill: parent
        anchors.margins: root.pad

        Repeater {
            model: root.model

            Item {
                width: root.itemWidth
                height: root.height - root.pad * 2

                readonly property bool isActive: index === root.currentIndex

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: isActive ? Font.DemiBold : Font.Normal
                    color: isActive ? "#FFFFFF" : (itemMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                    elide: Text.ElideRight

                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.currentIndex !== index) {
                            root.selected(index)
                        }
                    }
                }
            }
        }
    }
}
