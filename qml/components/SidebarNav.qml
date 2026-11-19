import QtQuick
import QtQuick.Layouts
import AuraPaper

Rectangle {
    id: root

    required property Window hostWindow
    property int currentIndex: 0
    signal tabSelected(int index)

    width: 224
    color: Theme.sidebarBg

    // Subtle right border
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Theme.border
    }

    readonly property var navItems: [
        { label: "总览面板", icon: "dashboard", badge: "overview" },
        { label: "桌面壁纸", icon: "monitor",   badge: "desktop"  },
        { label: "锁屏壁纸", icon: "lock",      badge: "lock"     },
        { label: "系统设置", icon: "settings",  badge: "settings" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // App Brand Header (supports window dragging)
        Item {
            Layout.fillWidth: true
            height: 54

            MouseArea {
                anchors.fill: parent
                onPressed: if (hostWindow) hostWindow.startSystemMove()
            }

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Image {
                    source: "qrc:/AuraPaper/resources/icons/app_icon.png"
                    sourceSize: Qt.size(72, 72)
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    smooth: true
                    mipmap: true
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "AuraPaper"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "光影壁纸引擎"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }

        // Section Label
        Text {
            text: "功能导航"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Layout.leftMargin: 10
            Layout.topMargin: 4
        }

        // Navigation Items with animated sliding highlight
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.navItems.length * 48

            readonly property int rowHeight: 48

            // Sliding active pill background
            Rectangle {
                id: activeBg
                x: 0
                y: root.currentIndex * parent.rowHeight + 2
                width: parent.width
                height: 42
                radius: Theme.radiusMd
                color: root.currentIndex === 2 ? Theme.lockAccentSoft : Theme.accentSoft

                Behavior on y {
                    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: 220 } }

                // Glowing left accent pill
                Rectangle {
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: 20
                    radius: 2
                    color: root.currentIndex === 2 ? Theme.lockAccent : Theme.accent

                    Behavior on color { ColorAnimation { duration: 220 } }
                }
            }

            Column {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.navItems

                    Item {
                        width: parent.width
                        height: 48

                        readonly property bool isSelected: index === root.currentIndex
                        readonly property color itemAccent: index === 2 ? Theme.lockAccent : Theme.accent
                        readonly property bool channelActive: (modelData.badge === "desktop" && appController.desktopChannel.running)
                                                              || (modelData.badge === "lock" && appController.lockScreenChannel.running)

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 2
                            anchors.bottomMargin: 4
                            radius: Theme.radiusMd
                            color: (!isSelected && navMouse.containsMouse) ? Theme.surfaceElevated : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 12
                            spacing: 11

                            IconGlyph {
                                name: modelData.icon
                                size: 17
                                color: isSelected ? itemAccent
                                                  : (navMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: isSelected ? Theme.textPrimary
                                                  : (navMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: isSelected ? Font.DemiBold : Font.Medium
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            // Live running status indicator dot
                            Rectangle {
                                visible: channelActive
                                width: 8
                                height: 8
                                radius: 4
                                color: index === 2 ? Theme.lockAccent : Theme.success

                                SequentialAnimation on opacity {
                                    running: channelActive && root.visible && Window.window && Window.window.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.35; duration: 950; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.35; to: 1.0; duration: 950; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tabSelected(index)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Compact Low-Resource Status Card at bottom of sidebar
        Rectangle {
            Layout.fillWidth: true
            height: 78
            radius: Theme.radiusMd
            color: Theme.surfaceElevated
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    IconGlyph {
                        name: "cpu"
                        size: 13
                        color: Theme.accent
                    }

                    Text {
                        text: "内存占用"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: appController.memoryUsageMB.toFixed(1) + " MB"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                // Quick Trim Memory clickable link
                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 7
                    color: trimMouse.containsMouse ? Theme.cardHoverBg : Theme.cardBg
                    border.width: 1
                    border.color: Theme.border
                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        IconGlyph {
                            name: "sparkles"
                            size: 12
                            color: Theme.accent
                        }
                        Text {
                            text: "释放内存缓存"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: trimMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appController.trimMemoryNow()
                    }
                }
            }
        }
    }
}
