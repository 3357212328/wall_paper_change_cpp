import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import AuraPaper

CardContainer {
    id: root

    required property var channel
    property color accentColor: Theme.accent
    property string channelIcon: "monitor"
    property bool compact: false
    signal openSettingsClicked()

    hoverHighlight: true
    highlightColor: accentColor
    hovered: cardHover.hovered

    // Dual-layer crossfade state
    property string layerASource: ""
    property string layerBSource: ""
    property bool showLayerA: true

    function syncSource(newUrl) {
        if (!newUrl || newUrl.length === 0) {
            layerASource = ""
            layerBSource = ""
            return
        }
        if (showLayerA) {
            if (layerASource === newUrl) return
            layerBSource = newUrl
            showLayerA = false
        } else {
            if (layerBSource === newUrl) return
            layerASource = newUrl
            showLayerA = true
        }
    }

    Component.onCompleted: {
        if (channel && channel.currentImageUrl) {
            layerASource = channel.currentImageUrl
            showLayerA = true
        }
    }

    Connections {
        target: root.channel
        function onCurrentImageChanged() {
            root.syncSource(root.channel.currentImageUrl)
        }
    }

    HoverHandler { id: cardHover }

    // Drag & Drop folder directly onto the preview card
    DropArea {
        anchors.fill: parent
        z: 10
        onDropped: function(drop) {
            if (drop.hasUrls && drop.urls.length > 0) {
                root.channel.setFolderFromUrl(drop.urls[0])
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Preview Viewport with rounded mask & dual-layer crossfade
        Item {
            id: viewportWrap
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 185 : 230
            Layout.fillHeight: !root.compact

            Rectangle {
                id: previewMask
                anchors.fill: parent
                radius: Theme.radiusMd
                visible: false
                layer.enabled: true
            }

            Item {
                id: previewContent
                anchors.fill: parent
                visible: false

                // Subtle gradient backdrop when no wallpaper is loaded
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.dark ? "#131B2E" : "#E2E8F0" }
                        GradientStop { position: 1.0; color: Theme.dark ? "#1B2541" : "#CBD5E1" }
                    }
                }

                // Layer A
                Image {
                    id: imgA
                    anchors.fill: parent
                    source: root.layerASource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize: Qt.size(720, 420)
                    opacity: root.showLayerA && status === Image.Ready ? 1.0 : 0.0
                    scale: root.showLayerA ? (cardHover.hovered ? 1.03 : 1.0) : 1.06

                    Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.InOutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                }

                // Layer B
                Image {
                    id: imgB
                    anchors.fill: parent
                    source: root.layerBSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize: Qt.size(720, 420)
                    opacity: !root.showLayerA && status === Image.Ready ? 1.0 : 0.0
                    scale: !root.showLayerA ? (cardHover.hovered ? 1.03 : 1.0) : 1.06

                    Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.InOutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                }

                // Loading indicator while decoding large 200MB+ wallpapers
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: (imgA.status === Image.Loading || imgB.status === Image.Loading)
                             && imgA.opacity < 0.05 && imgB.opacity < 0.05

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: "transparent"
                        border.width: 2.5
                        border.color: root.accentColor

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.top: parent.top
                            anchors.right: parent.right
                            color: Theme.dark ? "#172036" : "#D6DEE9"
                        }

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 850
                            loops: Animation.Infinite
                            running: parent.visible && Window.window && Window.window.visible
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "正在解码高清壁纸..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                }

                // Empty state placeholder
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.layerASource.length === 0 && root.layerBSource.length === 0

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 48
                        height: 48
                        radius: 24
                        color: Theme.surfaceElevated

                        IconGlyph {
                            anchors.centerIn: parent
                            name: "image"
                            size: 22
                            color: Theme.textMuted
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "暂无壁纸预览 · 拖入或选择壁纸文件夹"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }

                // Subtle bottom readability gradient over image
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 82
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: "#B8060A12" }
                    }
                }
            }

            MultiEffect {
                anchors.fill: previewContent
                source: previewContent
                maskEnabled: true
                maskSource: previewMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            // Top floating badges
            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 8

                // Channel pill
                Rectangle {
                    height: 28
                    implicitWidth: chRow.implicitWidth + 18
                    radius: 14
                    color: "#B80B101C"
                    border.width: 1
                    border.color: "#2EFFFFFF"

                    RowLayout {
                        id: chRow
                        anchors.centerIn: parent
                        spacing: 6
                        IconGlyph {
                            name: root.channelIcon
                            size: 13
                            color: root.accentColor
                        }
                        Text {
                            text: root.channel.title
                            color: "#F8FAFC"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Live status + countdown pill
                Rectangle {
                    height: 28
                    implicitWidth: statusRow.implicitWidth + 18
                    radius: 14
                    color: "#B80B101C"
                    border.width: 1
                    border.color: root.channel.running ? root.accentColor : "#2EFFFFFF"

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 4
                            color: root.channel.running ? Theme.success : Theme.textMuted

                            SequentialAnimation on opacity {
                                running: root.channel.running && root.visible && Window.window && Window.window.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            text: root.channel.running
                                  ? ("切换倒计时 " + appController.formatDuration(root.channel.remainingSeconds))
                                  : "已暂停"
                            color: "#F8FAFC"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            // Bottom floating filename & quick reveal
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.channel.currentImageName
                        color: "#FFFFFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideMiddle
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.channel.imageCount > 0
                              ? ("图库共 " + root.channel.imageCount + " 张 · "
                                 + (root.channel.lastSwitchTimeText.length > 0
                                    ? ("上次更换 " + root.channel.lastSwitchTimeText)
                                    : "就绪"))
                              : "尚未指定图库文件夹"
                        color: "#CBD5E1"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                // Reveal current file button
                Rectangle {
                    visible: root.channel.currentImagePath.length > 0
                    width: 30
                    height: 30
                    radius: 8
                    color: revealMouse.containsMouse ? "#52FFFFFF" : "#33000000"
                    border.width: 1
                    border.color: "#33FFFFFF"

                    IconGlyph {
                        anchors.centerIn: parent
                        name: "external"
                        size: 13
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: revealMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.channel.revealCurrentImage()
                    }
                }
            }
        }

        // Bottom control bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            AccentButton {
                text: root.channel.running ? "停止更换" : "开始更换"
                iconName: root.channel.running ? "stop" : "play"
                variant: root.channel.running ? "danger" : "primary"
                accentColor: root.accentColor
                buttonHeight: 36
                onClicked: root.channel.toggleRunning()
            }

            AccentButton {
                iconName: "prev"
                variant: "secondary"
                buttonHeight: 36
                enabled: root.channel.imageCount > 0
                onClicked: root.channel.previousWallpaper()
            }

            AccentButton {
                text: "换一张"
                iconName: "next"
                variant: "secondary"
                buttonHeight: 36
                busy: root.channel.applying
                enabled: root.channel.imageCount > 0
                onClicked: root.channel.nextWallpaper()
            }

            Item { Layout.fillWidth: true }

            AccentButton {
                visible: root.compact
                text: "详细设置"
                variant: "ghost"
                buttonHeight: 34
                onClicked: root.openSettingsClicked()
            }
        }
    }
}
