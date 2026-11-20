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

    function accentForIndex(idx) {
        if (idx === 0) return Theme.overviewAccent
        if (idx === 2) return Theme.lockAccent
        if (idx === 3) return Theme.settingsAccent
        return Theme.accent
    }

    function softAccentForIndex(idx) {
        if (idx === 0) return Theme.overviewAccentSoft
        if (idx === 2) return Theme.lockAccentSoft
        if (idx === 3) return Theme.settingsAccentSoft
        return Theme.accentSoft
    }

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

        // Navigation Items with unified smooth hover glide & active pill
        Item {
            id: navContainer
            Layout.fillWidth: true
            Layout.preferredHeight: root.navItems.length * 48

            readonly property int rowHeight: 48
            property int hoveredIndex: -1
            property int lastHoveredIndex: 0

            // Layer 1: Unified gliding hover highlight (animates y & opacity, never color-to-transparent)
            Rectangle {
                id: hoverPill
                x: 0
                y: navContainer.lastHoveredIndex * navContainer.rowHeight + 3
                width: parent.width
                height: 42
                radius: Theme.radiusMd
                color: Theme.surfaceElevated
                opacity: (navContainer.hoveredIndex >= 0 && navContainer.hoveredIndex !== root.currentIndex) ? 1.0 : 0.0

                Behavior on y {
                    enabled: hoverPill.opacity > 0.05
                    NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
            }

            // Layer 2: Sliding active pill background
            Rectangle {
                id: activeBg
                x: 0
                y: root.currentIndex * navContainer.rowHeight + 3
                width: parent.width
                height: 42
                radius: Theme.radiusMd
                color: root.softAccentForIndex(root.currentIndex)

                Behavior on y {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: 200 } }

                // Glowing left accent pill
                Rectangle {
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: 20
                    radius: 2
                    color: root.accentForIndex(root.currentIndex)

                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // Layer 3: Interactive button items
            Column {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.navItems

                    Item {
                        width: parent.width
                        height: navContainer.rowHeight

                        readonly property bool isSelected: index === root.currentIndex
                        readonly property bool isHovered: navMouse.containsMouse
                        readonly property color itemAccent: root.accentForIndex(index)
                        readonly property bool channelActive: (modelData.badge === "desktop" && appController.desktopChannel.running)
                                                              || (modelData.badge === "lock" && appController.lockScreenChannel.running)

                        Item {
                            anchors.fill: parent
                            scale: navMouse.pressed ? 0.97 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            RowLayout {
                                anchors.verticalCenter: parent.verticalCenter
                                x: (isHovered && !isSelected) ? 20 : 18
                                width: parent.width - 30
                                spacing: 11

                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                IconGlyph {
                                    name: modelData.icon
                                    size: 17
                                    color: isSelected ? itemAccent
                                                      : (isHovered ? Theme.textPrimary : Theme.textSecondary)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: isSelected ? Theme.textPrimary
                                                      : (isHovered ? Theme.textPrimary : Theme.textSecondary)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: isSelected ? Font.DemiBold : Font.Medium
                                    Behavior on color { ColorAnimation { duration: 150 } }
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
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                navContainer.lastHoveredIndex = index
                                navContainer.hoveredIndex = index
                            }
                            onExited: {
                                if (navContainer.hoveredIndex === index) {
                                    navContainer.hoveredIndex = -1
                                }
                            }
                            onClicked: root.tabSelected(index)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
