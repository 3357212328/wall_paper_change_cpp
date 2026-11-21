import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AuraPaper

Flickable {
    id: root

    signal navigateToTab(int tabIndex)

    contentWidth: width
    contentHeight: mainCol.implicitHeight + 36
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 8
        spacing: 18

        // Top KPI / Quick Status Strip
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 14
            rowSpacing: 14

            // KPI 1: Desktop channel status
            CardContainer {
                Layout.fillWidth: true
                Layout.preferredHeight: 86
                hoverHighlight: true
                highlightColor: Theme.accent
                hovered: kpiDeskMouse.containsMouse

                MouseArea {
                    id: kpiDeskMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigateToTab(1)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    CountdownRing {
                        ringSize: 48
                        lineWidth: 3.5
                        active: appController.desktopChannel.running
                        progress: appController.desktopChannel.progress
                        accentColor: Theme.accent
                        centerText: appController.desktopChannel.running ? "运行" : "待机"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                            text: "桌面壁纸库"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            text: appController.desktopChannel.imageCount + " 张图片"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        Text {
                            text: appController.desktopChannel.running
                                  ? ("剩余 " + appController.formatDuration(appController.desktopChannel.remainingSeconds))
                                  : "未开启自动轮换"
                            color: appController.desktopChannel.running ? Theme.accent : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // KPI 2: Lock Screen channel status
            CardContainer {
                Layout.fillWidth: true
                Layout.preferredHeight: 86
                hoverHighlight: true
                highlightColor: Theme.lockAccent
                hovered: kpiLockMouse.containsMouse

                MouseArea {
                    id: kpiLockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigateToTab(2)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    CountdownRing {
                        ringSize: 48
                        lineWidth: 3.5
                        active: appController.lockScreenChannel.running
                        progress: appController.lockScreenChannel.progress
                        accentColor: Theme.lockAccent
                        centerText: appController.lockScreenChannel.running ? "运行" : "待机"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                            text: "锁屏壁纸库"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            text: appController.lockScreenChannel.imageCount + " 张图片"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        Text {
                            text: appController.lockScreenChannel.running
                                  ? ("剩余 " + appController.formatDuration(appController.lockScreenChannel.remainingSeconds))
                                  : "未开启自动轮换"
                            color: appController.lockScreenChannel.running ? Theme.lockAccent : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // KPI 3: Quick AutoStart Toggle
            CardContainer {
                Layout.fillWidth: true
                Layout.preferredHeight: 86

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "开机自启动"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            text: appController.autoStart ? "已开启" : "已关闭"
                            color: appController.autoStart ? Theme.success : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }
                        Text {
                            text: "登录系统静默托盘运行"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    AnimatedToggle {
                        checked: appController.autoStart
                        activeColor: Theme.success
                        onToggled: function(val) { appController.autoStart = val }
                    }
                }
            }
        }

        // Section Heading
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "双引擎实时预览"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
            }
            Text {
                text: "桌面壁纸与锁屏壁纸完全独立配置、互不干扰"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 12
                Layout.leftMargin: 6
            }
            Item { Layout.fillWidth: true }
        }

        // Dual Independent Preview Cards (Desktop + Lock Screen)
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            WallpaperPreviewCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 312
                channel: appController.desktopChannel
                accentColor: Theme.accent
                channelIcon: "monitor"
                compact: true
                onOpenSettingsClicked: root.navigateToTab(1)
            }

            WallpaperPreviewCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 312
                channel: appController.lockScreenChannel
                accentColor: Theme.lockAccent
                channelIcon: "lock"
                compact: true
                onOpenSettingsClicked: root.navigateToTab(2)
            }
        }

        // Friendly Tips & Resource Saver Strip
        CardContainer {
            Layout.fillWidth: true
            Layout.preferredHeight: 58

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: Theme.accentSoft

                    IconGlyph {
                        anchors.centerIn: parent
                        name: "sparkles"
                        size: 16
                        color: Theme.accent
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "小贴士：可将任意图片文件夹直接拖拽至上方预览卡片或设置页；点击右上角关闭按钮即可最小化到系统托盘，自动释放界面显存与缓存，保持极低内存占用。"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
