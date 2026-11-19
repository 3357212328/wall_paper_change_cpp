import QtQuick
import AuraPaper

Item {
    id: root

    property bool checked: false
    property color activeColor: Theme.accent
    property bool enabled: true
    signal toggled(bool value)

    implicitWidth: 46
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight
    opacity: enabled ? 1.0 : 0.45

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? root.activeColor : Theme.surfaceElevated
        border.width: root.checked ? 0 : 1
        border.color: mouseArea.containsMouse ? Theme.borderStrong : Theme.border

        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        Rectangle {
            id: knob
            readonly property real pad: 3
            readonly property real baseSize: track.height - pad * 2
            width: mouseArea.pressed ? baseSize + 5 : baseSize
            height: baseSize
            radius: baseSize / 2
            y: pad
            x: root.checked ? (track.width - width - pad) : pad
            color: "#FFFFFF"

            Behavior on x {
                NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
            Behavior on width {
                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: "#1F000000"
                border.width: 1
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }
}
