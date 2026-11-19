import QtQuick
import QtQuick.Layouts
import AuraPaper

Rectangle {
    id: root

    required property Window hostWindow
    property string pageTitle: "总览"
    property string pageSubtitle: ""

    height: 68
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
        anchors.rightMargin: 14
        anchors.topMargin: 12
        anchors.bottomMargin: 4
        spacing: 10

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 3
            Text {
                text: root.pageTitle
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 17
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

        // Divider
        Rectangle {
            width: 1
            height: 16
            color: Theme.border
        }

        // Minimize Window
        Item {
            implicitWidth: 34
            implicitHeight: 32
            Layout.preferredWidth: 34
            Layout.preferredHeight: 32

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.surfaceElevated
                opacity: minMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 130 } }
            }

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
        Item {
            implicitWidth: 34
            implicitHeight: 32
            Layout.preferredWidth: 34
            Layout.preferredHeight: 32

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.surfaceElevated
                opacity: maxMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 130 } }
            }

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
        Item {
            implicitWidth: 34
            implicitHeight: 32
            Layout.preferredWidth: 34
            Layout.preferredHeight: 32

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.danger
                opacity: closeMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 130 } }
            }

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
                onClicked: appController.handleCloseRequest()
            }
        }
    }
}
