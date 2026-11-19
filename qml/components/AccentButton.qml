import QtQuick
import QtQuick.Layouts
import AuraPaper

Item {
    id: root

    property string text: ""
    property string iconName: ""
    property string variant: "primary" // "primary" | "secondary" | "danger" | "ghost"
    property color accentColor: Theme.accent
    property bool busy: false
    property bool enabled: true
    property int buttonHeight: 38
    property int horizontalPadding: text.length > 0 ? 16 : 10
    property int fontSize: 13

    signal clicked()

    implicitHeight: buttonHeight
    implicitWidth: contentRow.implicitWidth + horizontalPadding * 2
    opacity: enabled ? 1.0 : 0.45

    readonly property color bgColor: {
        if (variant === "primary") {
            return mouseArea.containsMouse ? Qt.lighter(accentColor, 1.12) : accentColor
        }
        if (variant === "danger") {
            return mouseArea.containsMouse ? Qt.lighter(Theme.danger, 1.1) : Theme.danger
        }
        if (variant === "secondary") {
            return mouseArea.containsMouse ? Theme.cardHoverBg : Theme.surfaceElevated
        }
        return mouseArea.containsMouse ? Theme.surfaceElevated : "transparent"
    }

    readonly property color fgColor: {
        if (variant === "primary" || variant === "danger") {
            return "#FFFFFF"
        }
        return Theme.textPrimary
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusSm + 2
        color: root.bgColor
        border.width: variant === "secondary" ? 1 : 0
        border.color: mouseArea.containsMouse ? Theme.borderStrong : Theme.border
        scale: mouseArea.pressed ? 0.96 : 1.0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 7

            Item {
                visible: root.busy || root.iconName.length > 0
                implicitWidth: 16
                implicitHeight: 16

                IconGlyph {
                    anchors.centerIn: parent
                    visible: !root.busy && root.iconName.length > 0
                    name: root.iconName
                    size: 15
                    color: root.fgColor
                }

                // Minimal lightweight rotating arc while busy
                Rectangle {
                    visible: root.busy
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 7
                    color: "transparent"
                    border.width: 2
                    border.color: root.fgColor
                    opacity: 0.85

                    Rectangle {
                        width: 6
                        height: 6
                        anchors.top: parent.top
                        anchors.right: parent.right
                        color: bg.color
                    }

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 750
                        loops: Animation.Infinite
                        running: root.busy && root.visible && Window.window && Window.window.visible
                    }
                }
            }

            Text {
                visible: root.text.length > 0
                text: root.text
                color: root.fgColor
                font.family: Theme.fontFamily
                font.pixelSize: root.fontSize
                font.weight: (root.variant === "primary" || root.variant === "danger") ? Font.DemiBold : Font.Medium
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled && !root.busy
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
