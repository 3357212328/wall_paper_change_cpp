import QtQuick
import QtQuick.Shapes
import AuraPaper

Item {
    id: root

    property real progress: 0.0
    property bool active: false
    property color accentColor: Theme.accent
    property string centerText: ""
    property real ringSize: 54
    property real lineWidth: 4

    implicitWidth: ringSize
    implicitHeight: ringSize
    width: ringSize
    height: ringSize

    property real animatedProgress: progress
    Behavior on animatedProgress {
        NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
    }

    // Subtle ambient pulse behind ring when active
    Rectangle {
        anchors.centerIn: parent
        width: root.ringSize + 8
        height: root.ringSize + 8
        radius: width / 2
        color: root.accentColor
        opacity: 0.0
        visible: root.active

        SequentialAnimation on opacity {
            running: root.active && root.visible && Window.window && Window.window.visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.06; to: 0.22; duration: 1400; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.22; to: 0.06; duration: 1400; easing.type: Easing.InOutSine }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Background track circle
        ShapePath {
            strokeColor: Theme.border
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: (root.height - root.lineWidth) / 2
                startAngle: 0
                sweepAngle: 360
            }
        }

        // Foreground progress arc
        ShapePath {
            strokeColor: root.active ? root.accentColor : Theme.textMuted
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: (root.height - root.lineWidth) / 2
                startAngle: -90
                sweepAngle: root.active ? Math.max(4, root.animatedProgress * 360) : 0
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.centerText
        color: root.active ? Theme.textPrimary : Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }
}
