import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AuraPaper

Item {
    id: root

    required property var channel
    property color accentColor: Theme.accent
    property string channelIcon: "monitor"
    property bool isDesktop: true

    // Interval UI state synced with channel.intervalSeconds
    property int customUnitIndex: 1 // 0 = 秒, 1 = 分钟, 2 = 小时
    property int customValue: 5
    property bool syncingInterval: false

    function syncIntervalFromChannel() {
        if (!channel) return
        syncingInterval = true
        var sec = channel.intervalSeconds
        if (sec >= 3600 && sec % 3600 === 0) {
            customUnitIndex = 2
            customValue = Math.max(1, Math.floor(sec / 3600))
        } else if (sec >= 60 && sec % 60 === 0) {
            customUnitIndex = 1
            customValue = Math.max(1, Math.floor(sec / 60))
        } else {
            customUnitIndex = 0
            customValue = Math.max(5, sec)
        }
        syncingInterval = false
    }

    function applyCustomInterval(val, unitIdx) {
        if (syncingInterval || !channel) return
        var multiplier = unitIdx === 2 ? 3600 : (unitIdx === 1 ? 60 : 1)
        var totalSec = Math.max(5, val * multiplier)
        channel.intervalSeconds = totalSec
    }

    Component.onCompleted: syncIntervalFromChannel()

    Connections {
        target: root.channel
        function onIntervalSecondsChanged() {
            root.syncIntervalFromChannel()
        }
    }

    // Drag & Drop folder anywhere on page
    DropArea {
        anchors.fill: parent
        z: 20
        onDropped: function(drop) {
            if (drop.hasUrls && drop.urls.length > 0) {
                root.channel.setFolderFromUrl(drop.urls[0])
            }
        }
    }

    readonly property var intervalPresets: [
        { label: "30秒",  sec: 30 },
        { label: "1分钟", sec: 60 },
        { label: "5分钟", sec: 300 },
        { label: "15分钟", sec: 900 },
        { label: "30分钟", sec: 1800 },
        { label: "1小时", sec: 3600 },
        { label: "6小时", sec: 21600 }
    ]

    readonly property var orderLabels: ["文件名 A-Z", "文件名 Z-A", "随机轮换", "最新修改"]
    readonly property var fitLabels: isDesktop
                                     ? ["填充", "适应", "拉伸", "平铺", "居中", "跨区"]
                                     : ["填充", "适应", "拉伸", "平铺", "居中"]

    Flickable {
        id: pageScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: pageCol.implicitHeight + 30
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: pageCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 8
            spacing: 16

            // Top Split: Left Preview + Right Settings Panel
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Left: Hero Preview & Transport Controls
                WallpaperPreviewCard {
                    Layout.preferredWidth: Math.max(330, pageCol.width * 0.42)
                    Layout.fillHeight: true
                    Layout.preferredHeight: configCard.implicitHeight
                    Layout.minimumHeight: 376
                    channel: root.channel
                    accentColor: root.accentColor
                    channelIcon: root.channelIcon
                    compact: false
                }

                // Right: Configuration Card
                CardContainer {
                    id: configCard
                    Layout.fillWidth: true
                    implicitHeight: configCol.implicitHeight + 36
                    Layout.preferredHeight: implicitHeight

                    ColumnLayout {
                        id: configCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 18
                        spacing: 14

                        // 1. Folder Path Selection
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            RowLayout {
                                Layout.fillWidth: true
                                IconGlyph {
                                    name: "folder"
                                    size: 14
                                    color: root.accentColor
                                }
                                Text {
                                    text: "壁纸文件夹路径"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }

                                // Include Subfolders toggle
                                Text {
                                    text: "扫描子文件夹"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                                AnimatedToggle {
                                    implicitWidth: 38
                                    implicitHeight: 21
                                    checked: root.channel.includeSubfolders
                                    activeColor: root.accentColor
                                    onToggled: function(v) { root.channel.includeSubfolders = v }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: Theme.radiusSm + 1
                                    color: Theme.inputBg
                                    border.width: 1
                                    border.color: Theme.border

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        verticalAlignment: Text.AlignVCenter
                                        text: root.channel.folderPath.length > 0
                                              ? root.channel.folderPath
                                              : "未选择文件夹（支持拖拽文件夹到窗口）"
                                        color: root.channel.folderPath.length > 0
                                               ? Theme.textPrimary : Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                    }
                                }

                                AccentButton {
                                    text: "浏览"
                                    iconName: "folderOpen"
                                    variant: "primary"
                                    accentColor: root.accentColor
                                    buttonHeight: 36
                                    onClicked: root.channel.browseFolder()
                                }

                                AccentButton {
                                    iconName: "external"
                                    variant: "secondary"
                                    buttonHeight: 36
                                    enabled: root.channel.folderPath.length > 0
                                    onClicked: root.channel.openFolder()
                                }

                                AccentButton {
                                    iconName: "refresh"
                                    variant: "secondary"
                                    buttonHeight: 36
                                    busy: root.channel.scanning
                                    enabled: root.channel.folderPath.length > 0
                                    onClicked: root.channel.refreshFolder()
                                }
                            }
                        }

                        // 2. Interval Time Selection
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                IconGlyph {
                                    name: "clock"
                                    size: 14
                                    color: root.accentColor
                                }
                                Text {
                                    text: "自动更换间隔"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "当前: " + appController.formatDuration(root.channel.intervalSeconds)
                                    color: root.accentColor
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }

                            // Quick interval chips
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: root.intervalPresets

                                    Rectangle {
                                        readonly property bool isCurrent: root.channel.intervalSeconds === modelData.sec
                                        height: 28
                                        width: chipTxt.implicitWidth + 18
                                        radius: 14
                                        color: isCurrent ? root.accentColor
                                                         : (chipMouse.containsMouse ? Theme.cardHoverBg : Theme.surfaceElevated)
                                        border.width: 1
                                        border.color: isCurrent ? root.accentColor : Theme.border

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            id: chipTxt
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: isCurrent ? "#FFFFFF" : Theme.textSecondary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: isCurrent ? Font.DemiBold : Font.Normal
                                        }

                                        MouseArea {
                                            id: chipMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.channel.intervalSeconds = modelData.sec
                                        }
                                    }
                                }
                            }

                            // Custom interval numeric + unit selector
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "自定义："
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }

                                SpinBox {
                                    id: intervalSpin
                                    from: root.customUnitIndex === 0 ? 5 : 1
                                    to: root.customUnitIndex === 2 ? 168 : 999
                                    value: root.customValue
                                    editable: true
                                    implicitWidth: 108
                                    implicitHeight: 34

                                    onValueModified: {
                                        root.customValue = value
                                        root.applyCustomInterval(value, root.customUnitIndex)
                                    }

                                    contentItem: TextInput {
                                        text: intervalSpin.textFromValue(intervalSpin.value, intervalSpin.locale)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: Theme.textPrimary
                                        horizontalAlignment: Qt.AlignHCenter
                                        verticalAlignment: Qt.AlignVCenter
                                        readOnly: !intervalSpin.editable
                                        validator: intervalSpin.validator
                                    }

                                    background: Rectangle {
                                        radius: Theme.radiusSm
                                        color: Theme.inputBg
                                        border.width: 1
                                        border.color: intervalSpin.activeFocus ? root.accentColor : Theme.border
                                    }

                                    up.indicator: Rectangle {
                                        x: parent.width - width
                                        height: parent.height
                                        width: 26
                                        radius: Theme.radiusSm
                                        color: intervalSpin.up.pressed ? Theme.surfaceElevated : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "+"
                                            color: Theme.textSecondary
                                            font.pixelSize: 14
                                        }
                                    }

                                    down.indicator: Rectangle {
                                        x: 0
                                        height: parent.height
                                        width: 26
                                        radius: Theme.radiusSm
                                        color: intervalSpin.down.pressed ? Theme.surfaceElevated : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "−"
                                            color: Theme.textSecondary
                                            font.pixelSize: 14
                                        }
                                    }
                                }

                                SegmentedSelector {
                                    Layout.preferredWidth: 156
                                    implicitHeight: 34
                                    height: 34
                                    model: ["秒", "分钟", "小时"]
                                    currentIndex: root.customUnitIndex
                                    accentColor: root.accentColor
                                    onSelected: function(idx) {
                                        root.customUnitIndex = idx
                                        var clamped = idx === 0 ? Math.max(5, root.customValue) : Math.max(1, root.customValue)
                                        root.customValue = clamped
                                        root.applyCustomInterval(clamped, idx)
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        // 3. Switch Order Selection
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            RowLayout {
                                IconGlyph {
                                    name: "shuffle"
                                    size: 14
                                    color: root.accentColor
                                }
                                Text {
                                    text: "壁纸更换顺序"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                            }

                            SegmentedSelector {
                                Layout.fillWidth: true
                                model: root.orderLabels
                                currentIndex: root.channel.switchOrder
                                accentColor: root.accentColor
                                onSelected: function(idx) { root.channel.switchOrder = idx }
                            }
                        }

                        // 4. Image Fit Mode Selection
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            RowLayout {
                                Layout.fillWidth: true
                                IconGlyph {
                                    name: "image"
                                    size: 14
                                    color: root.accentColor
                                }
                                Text {
                                    text: "图片适应模式"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    visible: !root.isDesktop
                                    text: "非填充模式将按屏幕分辨率实时智能适配"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }
                            }

                            SegmentedSelector {
                                Layout.fillWidth: true
                                model: root.fitLabels
                                currentIndex: root.channel.fitMode
                                accentColor: root.accentColor
                                onSelected: function(idx) { root.channel.fitMode = idx }
                            }
                        }
                    }
                }
            }

            // Bottom Section: Interactive Virtualized Wallpaper Gallery
            CardContainer {
                Layout.fillWidth: true
                Layout.preferredHeight: 335

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Gallery Header & Search Filter
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: root.channel.title + "图库"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            height: 22
                            implicitWidth: countTxt.implicitWidth + 14
                            radius: 11
                            color: root.isDesktop ? Theme.accentSoft : Theme.lockAccentSoft

                            Text {
                                id: countTxt
                                anchors.centerIn: parent
                                text: root.channel.imageCount + " 张"
                                color: root.accentColor
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: "点击任意缩略图即可立即应用"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        Item { Layout.fillWidth: true }

                        // Search box
                        Rectangle {
                            width: 210
                            height: 32
                            radius: 16
                            color: Theme.inputBg
                            border.width: 1
                            border.color: searchInput.activeFocus ? root.accentColor : Theme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 10
                                spacing: 6

                                IconGlyph {
                                    name: "search"
                                    size: 13
                                    color: Theme.textMuted
                                }

                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    clip: true
                                    selectByMouse: true
                                    text: root.channel.searchText
                                    onTextEdited: root.channel.searchText = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "搜索文件名..."
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        visible: searchInput.text.length === 0
                                    }
                                }
                            }
                        }
                    }

                    // Virtualized Thumbnail GridView (low RAM!)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        GridView {
                            id: galleryGrid
                            anchors.fill: parent
                            clip: true
                            model: root.channel.galleryModel
                            cacheBuffer: 160
                            boundsBehavior: Flickable.StopAtBounds

                            readonly property int cols: Math.max(3, Math.floor(width / 176))
                            cellWidth: width / cols
                            cellHeight: 124

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            delegate: Item {
                                id: tileRoot
                                width: galleryGrid.cellWidth
                                height: galleryGrid.cellHeight

                                readonly property bool isCurrent: model.filePath === root.channel.currentImagePath

                                Rectangle {
                                    id: tileCard
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    radius: Theme.radiusMd
                                    color: Theme.inputBg
                                    border.width: isCurrent ? 2 : 1
                                    border.color: isCurrent ? root.accentColor
                                                            : (tileMouse.containsMouse ? Theme.borderStrong : Theme.border)
                                    clip: true
                                    scale: tileMouse.pressed ? 0.96 : (tileMouse.containsMouse ? 1.02 : 1.0)

                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: isCurrent ? 2 : 1
                                        source: model.thumbUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        sourceSize: Qt.size(260, 150)
                                        opacity: status === Image.Ready ? 1.0 : 0.0

                                        Behavior on opacity { NumberAnimation { duration: 220 } }
                                    }

                                    // Bottom filename caption gradient
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 34
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "#00000000" }
                                            GradientStop { position: 1.0; color: "#CC090D16" }
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            anchors.bottomMargin: 5
                                            text: model.fileName
                                            color: "#F8FAFC"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    // Active checkmark pill
                                    Rectangle {
                                        visible: isCurrent
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 7
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: root.accentColor

                                        IconGlyph {
                                            anchors.centerIn: parent
                                            name: "check"
                                            size: 12
                                            color: "#FFFFFF"
                                        }
                                    }

                                    // Hover quick-apply overlay pill
                                    Rectangle {
                                        visible: !isCurrent && tileMouse.containsMouse
                                        anchors.centerIn: parent
                                        height: 26
                                        width: 72
                                        radius: 13
                                        color: "#CC0B101C"
                                        border.width: 1
                                        border.color: "#44FFFFFF"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "设为壁纸"
                                            color: "#FFFFFF"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                        }
                                    }

                                    MouseArea {
                                        id: tileMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.channel.applyImage(model.filePath)
                                    }
                                }
                            }
                        }

                        // Empty Gallery State
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            visible: root.channel.imageCount === 0 && !root.channel.scanning

                            IconGlyph {
                                Layout.alignment: Qt.AlignHCenter
                                name: "folderOpen"
                                size: 32
                                color: Theme.textMuted
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.channel.folderPath.length === 0
                                      ? "尚未选择壁纸文件夹"
                                      : "该文件夹中没有找到支持的图片 (JPG / PNG / WebP / BMP)"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 10

                                AccentButton {
                                    text: "选择文件夹"
                                    iconName: "folderOpen"
                                    variant: "primary"
                                    accentColor: root.accentColor
                                    buttonHeight: 34
                                    onClicked: root.channel.browseFolder()
                                }

                                AccentButton {
                                    text: "加载 Windows 系统壁纸"
                                    iconName: "sparkles"
                                    variant: "secondary"
                                    buttonHeight: 34
                                    onClicked: root.channel.useSystemDefaultFolder()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
