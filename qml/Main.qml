import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import AuraPaper

ApplicationWindow {
    id: mainWindow

    width: 1120
    height: 760
    minimumWidth: 940
    minimumHeight: 650
    visible: !startMinimizedArg
    title: "AuraPaper 光影壁纸"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    property int currentTab: 0

    readonly property var pageTitles: [
        { title: "总览面板", subtitle: "实时掌控桌面与锁屏双壁纸引擎状态" },
        { title: "桌面壁纸设置", subtitle: "独立配置桌面壁纸目录、更换间隔、排序与适应模式" },
        { title: "锁屏壁纸设置", subtitle: "独立配置 Windows 锁屏壁纸目录、更换间隔、排序与智能适配" },
        { title: "系统设置", subtitle: "开机自启动、黑白主题切换、系统托盘与低资源优化" }
    ]

    onVisibleChanged: {
        appController.onWindowVisibilityChanged(visible)
        if (visible) {
            revealAnim.restart()
        }
    }

    Connections {
        target: appController
        function onToastMessage(msg, isError) {
            toastOverlay.show(msg, isError)
        }
        function onRequestWindowReveal() {
            revealAnim.restart()
        }
    }

    // Window Entrance Reveal Animation
    ParallelAnimation {
        id: revealAnim
        NumberAnimation {
            target: rootFrame
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 240
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: rootFrame
            property: "scale"
            from: 0.975
            to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    // Main Window Container
    Rectangle {
        id: rootFrame
        anchors.fill: parent
        radius: mainWindow.visibility === Window.Maximized ? 0 : 12
        color: Theme.windowBg
        border.width: mainWindow.visibility === Window.Maximized ? 0 : 1
        border.color: Theme.border
        clip: true

        // True soft radial aurora glow (zero hard edge, zero extra FBO memory)
        Shape {
            id: auroraShape
            anchors.right: parent.right
            anchors.top: parent.top
            width: 560
            height: 460
            opacity: Theme.dark ? 0.20 : 0.11

            property color glowColor: mainWindow.currentTab === 2 ? Theme.lockAccent : Theme.accent
            Behavior on glowColor { ColorAnimation { duration: 420; easing.type: Easing.InOutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            ShapePath {
                strokeColor: "transparent"
                strokeWidth: 0
                fillGradient: RadialGradient {
                    centerX: 430; centerY: 40
                    focalX: 430; focalY: 40
                    centerRadius: 340
                    GradientStop { position: 0.0; color: auroraShape.glowColor }
                    GradientStop { position: 0.55; color: Qt.rgba(auroraShape.glowColor.r, auroraShape.glowColor.g, auroraShape.glowColor.b, 0.25) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                startX: 0; startY: 0
                PathLine { x: 560; y: 0 }
                PathLine { x: 560; y: 460 }
                PathLine { x: 0; y: 460 }
                PathLine { x: 0; y: 0 }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left Navigation Sidebar
            SidebarNav {
                Layout.fillHeight: true
                hostWindow: mainWindow
                currentIndex: mainWindow.currentTab
                onTabSelected: function(idx) {
                    mainWindow.currentTab = idx
                }
            }

            // Right Main Content Area
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Custom Frameless Title Bar
                CustomTitleBar {
                    Layout.fillWidth: true
                    hostWindow: mainWindow
                    pageTitle: mainWindow.pageTitles[mainWindow.currentTab].title
                    pageSubtitle: mainWindow.pageTitles[mainWindow.currentTab].subtitle
                }

                // Memory-conscious Animated Page Host:
                // Only active (or fading-out) pages stay loaded in GPU memory
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Tab 0: Overview
                    Loader {
                        id: overviewLoader
                        width: parent.width
                        height: parent.height
                        readonly property bool tabActive: mainWindow.currentTab === 0
                        active: tabActive || opacity > 0.01
                        y: tabActive ? 0 : 14
                        opacity: tabActive ? 1.0 : 0.0
                        visible: opacity > 0.01
                        enabled: tabActive
                        sourceComponent: Component {
                            OverviewPage {
                                onNavigateToTab: function(idx) { mainWindow.currentTab = idx }
                            }
                        }

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on y       { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }

                    // Tab 1: Desktop Wallpaper Settings (100% independent channel)
                    Loader {
                        id: desktopLoader
                        width: parent.width
                        height: parent.height
                        readonly property bool tabActive: mainWindow.currentTab === 1
                        active: tabActive || opacity > 0.01
                        y: tabActive ? 0 : 14
                        opacity: tabActive ? 1.0 : 0.0
                        visible: opacity > 0.01
                        enabled: tabActive
                        sourceComponent: Component {
                            ChannelSettingsPage {
                                channel: appController.desktopChannel
                                accentColor: Theme.accent
                                channelIcon: "monitor"
                                isDesktop: true
                            }
                        }

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on y       { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }

                    // Tab 2: Lock Screen Wallpaper Settings (100% independent channel)
                    Loader {
                        id: lockScreenLoader
                        width: parent.width
                        height: parent.height
                        readonly property bool tabActive: mainWindow.currentTab === 2
                        active: tabActive || opacity > 0.01
                        y: tabActive ? 0 : 14
                        opacity: tabActive ? 1.0 : 0.0
                        visible: opacity > 0.01
                        enabled: tabActive
                        sourceComponent: Component {
                            ChannelSettingsPage {
                                channel: appController.lockScreenChannel
                                accentColor: Theme.lockAccent
                                channelIcon: "lock"
                                isDesktop: false
                            }
                        }

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on y       { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }

                    // Tab 3: System Settings
                    Loader {
                        id: settingsLoader
                        width: parent.width
                        height: parent.height
                        readonly property bool tabActive: mainWindow.currentTab === 3
                        active: tabActive || opacity > 0.01
                        y: tabActive ? 0 : 14
                        opacity: tabActive ? 1.0 : 0.0
                        visible: opacity > 0.01
                        enabled: tabActive
                        sourceComponent: Component {
                            SettingsPage {}
                        }

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on y       { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // Global Floating Toast Overlay
        ToastOverlay {
            id: toastOverlay
        }

        // Frameless Window Resize Handles (active only when not maximized)
        Item {
            anchors.fill: parent
            visible: mainWindow.visibility !== Window.Maximized
            readonly property int edgeSize: 6

            MouseArea {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.topMargin: parent.edgeSize; anchors.bottomMargin: parent.edgeSize
                width: parent.edgeSize; cursorShape: Qt.SizeHorCursor
                onPressed: mainWindow.startSystemResize(Qt.LeftEdge)
            }
            MouseArea {
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.topMargin: parent.edgeSize; anchors.bottomMargin: parent.edgeSize
                width: parent.edgeSize; cursorShape: Qt.SizeHorCursor
                onPressed: mainWindow.startSystemResize(Qt.RightEdge)
            }
            MouseArea {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: parent.edgeSize; anchors.rightMargin: parent.edgeSize
                height: parent.edgeSize; cursorShape: Qt.SizeVerCursor
                onPressed: mainWindow.startSystemResize(Qt.TopEdge)
            }
            MouseArea {
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: parent.edgeSize; anchors.rightMargin: parent.edgeSize
                height: parent.edgeSize; cursorShape: Qt.SizeVerCursor
                onPressed: mainWindow.startSystemResize(Qt.BottomEdge)
            }
            MouseArea {
                anchors.right: parent.right; anchors.bottom: parent.bottom
                width: parent.edgeSize * 2; height: parent.edgeSize * 2; cursorShape: Qt.SizeFDiagCursor
                onPressed: mainWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
            }
            MouseArea {
                anchors.left: parent.left; anchors.bottom: parent.bottom
                width: parent.edgeSize * 2; height: parent.edgeSize * 2; cursorShape: Qt.SizeBDiagCursor
                onPressed: mainWindow.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
            }
            MouseArea {
                anchors.right: parent.right; anchors.top: parent.top
                width: parent.edgeSize * 2; height: parent.edgeSize * 2; cursorShape: Qt.SizeBDiagCursor
                onPressed: mainWindow.startSystemResize(Qt.RightEdge | Qt.TopEdge)
            }
            MouseArea {
                anchors.left: parent.left; anchors.top: parent.top
                width: parent.edgeSize * 2; height: parent.edgeSize * 2; cursorShape: Qt.SizeFDiagCursor
                onPressed: mainWindow.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
            }
        }
    }
}
