import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AuraPaper

Flickable {
    id: root

    contentWidth: width
    contentHeight: contentCol.implicitHeight + 36
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 8
        spacing: 16

        // 1. Appearance / Light-Dark Theme Card
        CardContainer {
            Layout.fillWidth: true
            Layout.preferredHeight: appearanceCol.implicitHeight + 40

            ColumnLayout {
                id: appearanceCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    IconGlyph { name: Theme.dark ? "moon" : "sun"; size: 16; color: Theme.accent }
                    Text {
                        text: "界面外观与黑白主题"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    // Dark Mode visual selector card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: 92
                        radius: Theme.radiusMd
                        color: "#0F1524"
                        border.width: Theme.dark ? 2 : 1
                        border.color: Theme.dark ? Theme.accent : Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Rectangle {
                                width: 44; height: 44; radius: 12
                                color: "#1E2942"
                                IconGlyph { anchors.centerIn: parent; name: "moon"; size: 20; color: "#FDE047" }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    text: "深邃暗黑主题"
                                    color: "#F8FAFC"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "低眩光深空面板，适合夜间与高对比度欣赏壁纸"
                                    color: "#94A3B8"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                visible: Theme.dark
                                width: 24; height: 24; radius: 12
                                color: Theme.accent
                                IconGlyph { anchors.centerIn: parent; name: "check"; size: 13; color: "#FFFFFF" }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appController.darkTheme = true
                        }
                    }

                    // Light Mode visual selector card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: 92
                        radius: Theme.radiusMd
                        color: "#F8FAFC"
                        border.width: !Theme.dark ? 2 : 1
                        border.color: !Theme.dark ? Theme.accent : Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Rectangle {
                                width: 44; height: 44; radius: 12
                                color: "#FEF3C7"
                                IconGlyph { anchors.centerIn: parent; name: "sun"; size: 20; color: "#D97706" }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    text: "纯净浅白主题"
                                    color: "#0F172A"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "通透明亮陶瓷质感，适合日间办公环境"
                                    color: "#475569"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                visible: !Theme.dark
                                width: 24; height: 24; radius: 12
                                color: Theme.accent
                                IconGlyph { anchors.centerIn: parent; name: "check"; size: 13; color: "#FFFFFF" }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appController.darkTheme = false
                        }
                    }
                }
            }
        }

        // 2. Startup & Tray Behavior Card
        CardContainer {
            Layout.fillWidth: true
            Layout.preferredHeight: startupCol.implicitHeight + 40

            ColumnLayout {
                id: startupCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    IconGlyph { name: "settings"; size: 16; color: Theme.accent }
                    Text {
                        text: "启动与系统托盘行为"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }

                // Row: Autostart
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "开机自启动"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "随 Windows 登录自动启动并恢复桌面与锁屏壁纸定时更换任务"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                    Item { Layout.fillWidth: true }
                    AnimatedToggle {
                        checked: appController.autoStart
                        activeColor: Theme.accent
                        onToggled: function(v) { appController.autoStart = v }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                // Row: Start minimized when autostarting
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "开机自启时静默最小化到托盘"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "开机后不弹出主界面，直接于后台低资源状态运行"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                    Item { Layout.fillWidth: true }
                    AnimatedToggle {
                        checked: appController.startMinimized
                        enabled: appController.autoStart
                        activeColor: Theme.accent
                        onToggled: function(v) { appController.startMinimized = v }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                // Row: Minimize to tray on close
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "关闭窗口时最小化到系统托盘"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "点击右上角关闭按钮时隐藏至右下角托盘继续后台更换壁纸"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                    Item { Layout.fillWidth: true }
                    AnimatedToggle {
                        checked: appController.minimizeToTrayOnClose
                        activeColor: Theme.accent
                        onToggled: function(v) { appController.minimizeToTrayOnClose = v }
                    }
                }
            }
        }

        // 3. Performance & Memory Optimization Card
        CardContainer {
            Layout.fillWidth: true
            Layout.preferredHeight: perfCol.implicitHeight + 40

            ColumnLayout {
                id: perfCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    IconGlyph { name: "cpu"; size: 16; color: Theme.accent }
                    Text {
                        text: "性能与低资源占用优化"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "全屏游戏 / 影音播放时自动暂停更换"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "检测到 DirectX 全屏游戏或演示文稿时跳过本次切换，杜绝画面掉帧"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                    Item { Layout.fillWidth: true }
                    AnimatedToggle {
                        checked: appController.pauseOnFullscreen
                        activeColor: Theme.accent
                        onToggled: function(v) { appController.pauseOnFullscreen = v }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: "实时内存占用：" + appController.memoryUsageMB.toFixed(1) + " MB"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "每次更换桌面或锁屏壁纸后将自动释放程序缓存；最小化至托盘后自动回收 GPU 场景纹理与工作集内存"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }

                    AccentButton {
                        text: "立即整理内存"
                        iconName: "sparkles"
                        variant: "secondary"
                        buttonHeight: 36
                        onClicked: appController.trimMemoryNow()
                    }
                }
            }
        }

        // 4. About & Quit Card
        CardContainer {
            Layout.fillWidth: true
            Layout.preferredHeight: aboutRow.implicitHeight + 36

            RowLayout {
                id: aboutRow
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Image {
                    source: "qrc:/AuraPaper/resources/icons/app_icon.png"
                    sourceSize: Qt.size(80, 80)
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    smooth: true
                    mipmap: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "AuraPaper 光影壁纸  v" + appController.appVersion
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "C++20 · Qt Quick 6.8 · Windows IDesktopWallpaper COM & WinRT LockScreen API"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                AccentButton {
                    text: "完全退出程序"
                    variant: "danger"
                    buttonHeight: 34
                    onClicked: appController.quitApplication()
                }
            }
        }
    }
}
