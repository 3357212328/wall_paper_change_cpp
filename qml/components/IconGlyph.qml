import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string name: ""
    property color color: "#FFFFFF"
    property real size: 18
    property real strokeWidth: 1.9

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    readonly property var paths: ({
        "dashboard":   "M3 3h7v9H3z M14 3h7v5h-7z M14 12h7v9h-7z M3 16h7v5H3z",
        "monitor":     "M2 4a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2z M8 21h8 M12 17v4",
        "lock":        "M5 11a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z M8 9V6a4 4 0 0 1 8 0v3",
        "settings":    "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33h.08a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82v.08a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z",
        "play":        "M6 4l14 8-14 8z",
        "stop":        "M6 6h12v12H6z",
        "pause":       "M6 4h4v16H6z M14 4h4v16h-4z",
        "next":        "M5 4l10 8-10 8z M19 5v14",
        "prev":        "M19 20L9 12l10-8z M5 19V5",
        "folder":      "M3 6a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z",
        "folderOpen":  "M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v1H3z M3 10h18l-1.5 8a2 2 0 0 1-2 1.6H6.5a2 2 0 0 1-2-1.6z",
        "refresh":     "M21 12a9 9 0 1 1-2.64-6.36L21 8 M21 3v5h-5",
        "sun":         "M12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8z M12 2v2 M12 20v2 M4.93 4.93l1.41 1.41 M17.66 17.66l1.41 1.41 M2 12h2 M20 12h2 M4.93 19.07l1.41-1.41 M17.66 6.34l1.41-1.41",
        "moon":        "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z",
        "search":      "M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16z M21 21l-4.35-4.35",
        "check":       "M20 6L9 17l-5-5",
        "alert":       "M12 9v4 M12 17h.01 M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z",
        "minimize":    "M5 12h14",
        "maximize":    "M5 5h14v14H5z",
        "restore":     "M7 9h10v10H7z M9 9V5h10v10h-2",
        "close":       "M6 6l12 12 M18 6L6 18",
        "tray":        "M4 14v4a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-4 M12 3v11 M8 10l4 4 4-4",
        "sparkles":    "M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z M19 16l.9 2.1L22 19l-2.1.9L19 22l-.9-2.1L16 19l2.1-.9z",
        "image":       "M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z M21 15l-5-5L5 21",
        "clock":       "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z M12 6v6l4 2",
        "shuffle":     "M16 3h5v5 M4 20L21 3 M21 16v5h-5 M15 15l6 6 M4 4l5 5",
        "cpu":         "M6 6h12v12H6z M9 9h6v6H9z M9 2v4 M15 2v4 M9 18v4 M15 18v4 M2 9h4 M2 15h4 M18 9h4 M18 15h4",
        "external":    "M14 3h7v7 M10 14L21 3 M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"
    })

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 24.0
            yScale: root.height / 24.0
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: root.paths[root.name] || ""
            }
        }
    }
}
