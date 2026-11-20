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
        Rectangle {
            implicitWidth: 34
            implicitHeight: 32
            Layout.preferredWidth: 34
            Layout.preferredHeight: 32
            radius: 8
            color: minMouse.pressed
                   ? (Theme.dark ? "#364A75" : "#CBD5E1")
                   : (minMouse.containsMouse ? (Theme.dark ? "#2B3B5E" : "#DCE5F2") : Theme.surfaceElevated)
            border.width: 1
            border.color: minMouse.containsMouse ? (Theme.dark ? "#546D9E" : "#94A3B8") : Theme.border
            scale: minMouse.pressed ? 0.90 : (minMouse.containsMouse ? 1.06 : 1.0)

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.centerIn: parent
                width: minMouse.containsMouse ? 13 : 11
                height: 2
                radius: 1
                color: Theme.textPrimary

                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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
            implicitWidth: 34
            implicitHeight: 32
            Layout.preferredWidth: 34
            Layout.preferredHeight: 32
            radius: 8
            color: maxMouse.pressed
                   ? (Theme.dark ? "#364A75" : "#CBD5E1")
                   : (maxMouse.containsMouse ? (Theme.dark ? "#2B3B5E" : "#DCE5F2") : Theme.surfaceElevated)
            border.width: 1
            border.color: maxMouse.containsMouse ? (Theme.dark ? "#546D9E" : "#94A3B8") : Theme.border
            scale: maxMouse.pressed ? 0.90 : (maxMouse.containsMouse ? 1.06 : 1.0)

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            // Maximize glyph
            Rectangle {
                visible: !(hostWindow && hostWindow.visibility === Window.Maximized)
                anchors.centerIn: parent
                width: 11
                height: 11
                radius: 2
                color: "transparent"
                border.width: 1.7
                border.color: Theme.textPrimary
                scale: maxMouse.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            // Restore glyph
            Item {
                visible: !!(hostWindow && hostWindow.visibility === Window.Maximized)
                anchors.centerIn: parent
                width: 12
                height: 12
                scale: maxMouse.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Rectangle {
                    x: 3
                    y: 0
                    width: 9
                    height: 9
                    radius: 1.5
                    color: "transparent"
                    border.width: 1.5
                    border.color: Theme.textPrimary
                }
                Rectangle {
                    x: 0
                    y: 3
                    width: 9
                    height: 9
                    radius: 1.5
                    color: maxMouse.pressed
                           ? (Theme.dark ? "#364A75" : "#CBD5E1")
                           : (maxMouse.containsMouse ? (Theme.dark ? "#2B3B5E" : "#DCE5F2") : Theme.surfaceElevated)
                    border.width: 1.5
                    border.color: Theme.textPrimary
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
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
            implicitWidth: 34
            implicitHeight: 32
            Layout.preferredWidth: 34
            Layout.preferredHeight: 32
            radius: 8
            color: closeMouse.pressed
                   ? "#B91C1C"
                   : (closeMouse.containsMouse ? Theme.danger : Theme.surfaceElevated)
            border.width: 1
            border.color: closeMouse.containsMouse ? Theme.danger : Theme.border
            scale: closeMouse.pressed ? 0.90 : (closeMouse.containsMouse ? 1.06 : 1.0)

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Item {
                anchors.centerIn: parent
                width: 12
                height: 12

                Rectangle {
                    anchors.centerIn: parent
                    width: 13
                    height: 1.8
                    radius: 0.9
                    rotation: 45
                    antialiasing: true
                    color: closeMouse.containsMouse ? "#FFFFFF" : Theme.textPrimary
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 13
                    height: 1.8
                    radius: 0.9
                    rotation: -45
                    antialiasing: true
                    color: closeMouse.containsMouse ? "#FFFFFF" : Theme.textPrimary
                }
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
