import QtQuick
import QtQuick.Layouts
import AuraPaper

Window {
    id: popup

    width: 236
    height: Math.max(300, menuCol.implicitHeight + 16)
    visible: false
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    property bool canAutoClose: false

    Connections {
        target: appController
        function onRequestTrayMenu(px, py) {
            popup.openAt(px, py)
        }
    }

    Timer {
        id: closeGuardTimer
        interval: 140
        onTriggered: popup.canAutoClose = true
    }

    function openAt(px, py) {
        canAutoClose = false
        closeGuardTimer.restart()
        x = px
        y = py
        menuCard.opacity = 0.0
        menuCol.y = 16
        show()
        raise()
        requestActivate()
        appController.prepareTrayPopupWindow(popup)
        openAnim.restart()
    }

    function closeMenu() {
        closeGuardTimer.stop()
        canAutoClose = false
        if (!visible) return
        hide()
        appController.onTrayPopupClosed()
    }

    onActiveChanged: {
        if (!active && visible && canAutoClose) {
            closeMenu()
        }
    }

    component TrayItem: Item {
        id: itemRoot
        property string label: ""
        property string iconName: ""
        property color accentColor: Theme.accent
        property bool isDanger: false
        property bool showLiveDot: false
        property color liveDotColor: Theme.success
        property bool boldLabel: false
        signal triggered()

        Layout.fillWidth: true
        implicitHeight: 36

        readonly property bool hovered: itemMouse.containsMouse
        readonly property color effectiveAccent: isDanger ? Theme.danger : accentColor

        // Animated hover pill background (uses opacity instead of color-to-transparent to avoid dark gray flash in light mode)
        Item {
            id: hoverWrap
            anchors.fill: parent
            scale: itemMouse.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

            Rectangle {
                id: hoverBg
                anchors.fill: parent
                radius: 9
                color: itemRoot.isDanger ? Theme.dangerSoft : Theme.surfaceElevated
                opacity: itemRoot.hovered ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Animated left accent bar that grows on hover
            Rectangle {
                x: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: itemRoot.hovered ? 16 : 0
                radius: 2
                color: itemRoot.effectiveAccent
                opacity: itemRoot.hovered ? 1.0 : 0.0

                Behavior on height  { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }

            // Content row with subtle smooth rightward glide on hover
            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                x: itemRoot.hovered ? 16 : 12
                width: parent.width - 26
                spacing: 10

                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                IconGlyph {
                    name: itemRoot.iconName
                    size: 15
                    color: itemRoot.hovered
                           ? itemRoot.effectiveAccent
                           : (itemRoot.isDanger ? Theme.danger : Theme.textSecondary)

                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                Text {
                    Layout.fillWidth: true
                    text: itemRoot.label
                    color: itemRoot.isDanger && itemRoot.hovered
                           ? Theme.danger
                           : Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: (itemRoot.boldLabel || itemRoot.hovered) ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight

                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                // Live running status indicator dot
                Rectangle {
                    visible: itemRoot.showLiveDot
                    width: 7
                    height: 7
                    radius: 4
                    color: itemRoot.liveDotColor
                }
            }
        }

        MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                popup.closeMenu()
                itemRoot.triggered()
            }
        }
    }

    component TrayDivider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.topMargin: 3
        Layout.bottomMargin: 3
        height: 1
        color: Theme.border
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: menuCard
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: menuCol
            property: "y"
            from: 16
            to: 8
            duration: 210
            easing.type: Easing.OutCubic
        }
    }

    // Keyboard Escape to close
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: popup.closeMenu()
    }

    Rectangle {
        id: menuCard
        anchors.fill: parent
        radius: 12
        color: Theme.cardBg
        border.width: 1
        border.color: Theme.borderStrong
        clip: true

        ColumnLayout {
            id: menuCol
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 2

            // Compact Brand Header
            Item {
                Layout.fillWidth: true
                implicitHeight: 40

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 9

                    Image {
                        source: "qrc:/AuraPaper/resources/icons/app_icon.png"
                        sourceSize: Qt.size(48, 48)
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        smooth: true
                        mipmap: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "AuraPaper 光影壁纸"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            text: {
                                var d = appController.desktopChannel.running
                                var l = appController.lockScreenChannel.running
                                if (d && l) return "桌面与锁屏轮换运行中"
                                if (d) return "桌面壁纸轮换运行中"
                                if (l) return "锁屏壁纸轮换运行中"
                                return "后台低占用待机中"
                            }
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }

            TrayDivider {}

            TrayItem {
                label: "显示主界面"
                iconName: "dashboard"
                accentColor: Theme.accent
                boldLabel: true
                onTriggered: appController.showMainWindow()
            }

            TrayDivider {}

            TrayItem {
                label: "立即切换桌面壁纸"
                iconName: "next"
                accentColor: Theme.accent
                onTriggered: appController.desktopChannel.nextWallpaper()
            }

            TrayItem {
                label: appController.desktopChannel.running ? "停止桌面自动更换" : "启动桌面自动更换"
                iconName: appController.desktopChannel.running ? "stop" : "play"
                accentColor: Theme.accent
                showLiveDot: appController.desktopChannel.running
                liveDotColor: Theme.success
                onTriggered: appController.desktopChannel.toggleRunning()
            }

            TrayDivider {}

            TrayItem {
                label: "立即切换锁屏壁纸"
                iconName: "next"
                accentColor: Theme.lockAccent
                onTriggered: appController.lockScreenChannel.nextWallpaper()
            }

            TrayItem {
                label: appController.lockScreenChannel.running ? "停止锁屏自动更换" : "启动锁屏自动更换"
                iconName: appController.lockScreenChannel.running ? "stop" : "play"
                accentColor: Theme.lockAccent
                showLiveDot: appController.lockScreenChannel.running
                liveDotColor: Theme.lockAccent
                onTriggered: appController.lockScreenChannel.toggleRunning()
            }

            TrayDivider {}

            TrayItem {
                label: Theme.dark ? "切换为浅色主题" : "切换为深色主题"
                iconName: Theme.dark ? "sun" : "moon"
                accentColor: Theme.warning
                onTriggered: appController.toggleTheme()
            }

            TrayItem {
                label: "退出 AuraPaper"
                iconName: "close"
                isDanger: true
                onTriggered: appController.quitApplication()
            }
        }
    }
}
