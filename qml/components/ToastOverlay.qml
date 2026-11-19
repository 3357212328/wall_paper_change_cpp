import QtQuick
import QtQuick.Layouts
import AuraPaper

Item {
    id: root

    property string message: ""
    property bool isError: false
    property bool shown: false

    function show(msg, errorFlag) {
        message = msg
        isError = !!errorFlag
        shown = true
        hideTimer.restart()
    }

    anchors.fill: parent
    z: 999

    Timer {
        id: hideTimer
        interval: 2800
        onTriggered: root.shown = false
    }

    Rectangle {
        id: toastPill
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.shown ? (parent.height - height - 24) : (parent.height + 16)
        opacity: root.shown ? 1.0 : 0.0
        scale: root.shown ? 1.0 : 0.94

        height: 42
        implicitWidth: Math.min(parent.width - 64, row.implicitWidth + 32)
        width: implicitWidth
        radius: 21
        color: Theme.dark ? "#E6172033" : "#F2FFFFFF"
        border.width: 1
        border.color: root.isError ? Theme.danger : Theme.borderStrong

        Behavior on y       { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 9

            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: root.isError ? Theme.dangerSoft : Theme.successSoft

                IconGlyph {
                    anchors.centerIn: parent
                    name: root.isError ? "alert" : "check"
                    size: 13
                    color: root.isError ? Theme.danger : Theme.success
                }
            }

            Text {
                text: root.message
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.maximumWidth: root.width - 140
            }
        }
    }
}
