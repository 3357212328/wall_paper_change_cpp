import QtQuick
import QtQuick.Layouts
import AuraPaper

Window {
    id: balloon

    width: 332
    height: 86
    visible: false
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus

    property string titleText: "AuraPaper 光影壁纸"
    property string bodyText: ""
    property int targetX: 0
    property int targetY: 0

    Connections {
        target: appController
        function onRequestTrayBalloon(px, py, title, message) {
            balloon.showAt(px, py, title, message)
        }
    }

    function showAt(px, py, title, message) {
        titleText = title
        bodyText = message
        targetX = px
        targetY = py
        x = px
        y = py
        card.opacity = 1.0
        card.y = 4
        progressBar.width = card.width - 28
        show()
        raise()
        inAnim.restart()
        progressAnim.restart()
        autoHideTimer.restart()
    }

    function dismiss() {
        autoHideTimer.stop()
        progressAnim.stop()
        if (!visible) return
        outAnim.restart()
    }

    Timer {
        id: autoHideTimer
        interval: 3000
        onTriggered: balloon.dismiss()
    }

    ParallelAnimation {
        id: inAnim
        NumberAnimation { target: card; property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "y"; from: 14; to: 4; duration: 220; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: outAnim
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: card; property: "y"; to: 14; duration: 200; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                balloon.hide()
                balloon.releaseResources()
            }
        }
    }

    NumberAnimation {
        id: progressAnim
        target: progressBar
        property: "width"
        from: card.width - 28
        to: 0
        duration: 3000
        easing.type: Easing.Linear
    }

    Rectangle {
        id: card
        x: 4
        y: 4
        width: balloon.width - 8
        height: balloon.height - 8
        radius: 13
        color: Theme.cardBg
        border.width: 1
        border.color: Theme.borderStrong

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 10
            anchors.bottomMargin: 12
            spacing: 12

            Image {
                source: "qrc:/AuraPaper/resources/icons/app_icon.png"
                sourceSize: Qt.size(64, 64)
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                smooth: true
                mipmap: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: balloon.titleText
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: balloon.bodyText
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }

        // Subtle 3-second countdown bar at bottom
        Rectangle {
            id: progressBar
            x: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
            height: 2
            radius: 1
            color: Theme.accent
            opacity: 0.75
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: balloon.dismiss()
        }
    }
}
