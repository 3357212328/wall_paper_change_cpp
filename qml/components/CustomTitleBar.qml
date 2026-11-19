import QtQuick
import QtQuick.Layouts
import AuraPaper

Rectangle {
    id: root

    required property Window hostWindow
    property string pageTitle: "总览"
    property string pageSubtitle: ""

    height: 54
    color: "transparent"

    // Drag & double-click maximize area
    MouseArea {
        anchors.fill: parent
        onPressed: {
            if (hostWindow) {
                hostWindow.startSystemMove()
            }
        }
        onDoubleClicked: {
            if (!hostWindow) return
            if (hostWindow.visibility === Window.Maximized) {
                hostWindow.showNormal()
            } else {
                hostWindow.showMaximized()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 12
        spacing: 10

        ColumnLayout {
            spacing: 1
            Text {
                text: root.pageTitle
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
            }
            Text {
                visible: root.pageSubtitle.length > 0
                text: root.pageSubtitle
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        Item { Layout.fillWidth: true }

        // Animated Theme Switch Pill (Light / Dark)
        Rectangle {
            id: themeBtn
            height: 32
            implicitWidth: themeRow.implicitWidth + 20
            radius: 16
            color: themeMouse.containsMouse ? Theme.cardHoverBg : Theme.surfaceElevated
            border.width: 1
            border.color: themeMouse.containsMouse ? Theme.borderStrong : Theme.border

            Behavior on color { ColorAnimation { duration: 160 } }

            RowLayout {
                id: themeRow
                anchors.centerIn: parent
                spacing: 6

                Item {
                    width: 16
                    height: 16

                    IconGlyph {
                        anchors.centerIn: parent
                        name: Theme.dark ? "moon" : "sun"
                        size: 15
                        color: Theme.dark ? "#FDE047" : "#F59E0B"
                        rotation: Theme.dark ? 0 : 180

                        Behavior on rotation {
                            NumberAnimation { duration: 380; easing.type: Easing.OutBack }
                        }
                    }
                }

                Text {
                    text: Theme.dark ? "深色主题" : "浅色主题"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }

            MouseArea {
                id: themeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appController.toggleTheme()
            }
        }

        // Minimize to Tray Quick Button
        Rectangle {
            width: 34
            height: 32
            radius: 8
            color: trayMouse.containsMouse ? Theme.surfaceElevated : "transparent"
            Behavior on color { ColorAnimation { duration: 140 } }

            IconGlyph {
                anchors.centerIn: parent
                name: "tray"
                size: 15
                color: trayMouse.containsMouse ? Theme.accent : Theme.textSecondary
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appController.hideToTray(true)
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 16
            color: Theme.border
        }

        // Minimize Window
        Rectangle {
            width: 34
            height: 32
            radius: 8
            color: minMouse.containsMouse ? Theme.surfaceElevated : "transparent"
            Behavior on color { ColorAnimation { duration: 140 } }

            IconGlyph {
                anchors.centerIn: parent
                name: "minimize"
                size: 14
                color: Theme.textSecondary
            }

            MouseArea {
                id: minMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (hostWindow) hostWindow.showMinimized()
            }
        }

        // Maximize / Restore Window
        Rectangle {
            width: 34
            height: 32
            radius: 8
            color: maxMouse.containsMouse ? Theme.surfaceElevated : "transparent"
            Behavior on color { ColorAnimation { duration: 140 } }

            IconGlyph {
                anchors.centerIn: parent
                name: (hostWindow && hostWindow.visibility === Window.Maximized) ? "restore" : "maximize"
                size: 13
                color: Theme.textSecondary
            }

            MouseArea {
                id: maxMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!hostWindow) return
                    if (hostWindow.visibility === Window.Maximized) {
                        hostWindow.showNormal()
                    } else {
                        hostWindow.showMaximized()
                    }
                }
            }
        }

        // Close Button (minimizes to tray if enabled)
        Rectangle {
            width: 34
            height: 32
            radius: 8
            color: closeMouse.containsMouse ? Theme.danger : "transparent"
            Behavior on color { ColorAnimation { duration: 140 } }

            IconGlyph {
                anchors.centerIn: parent
                name: "close"
                size: 14
                color: closeMouse.containsMouse ? "#FFFFFF" : Theme.textSecondary
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (appController.minimizeToTrayOnClose) {
                        appController.hideToTray(true)
                    } else {
                        appController.quitApplication()
                    }
                }
            }
        }
    }
}
