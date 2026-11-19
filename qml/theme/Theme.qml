pragma Singleton
import QtQuick

QtObject {
    id: theme

    property bool dark: typeof appController !== "undefined" && appController ? appController.darkTheme : true

    // Core surfaces
    property color windowBg:        dark ? "#0B0F19" : "#F2F5FA"
    property color sidebarBg:       dark ? "#111726" : "#FFFFFF"
    property color cardBg:          dark ? "#161E31" : "#FFFFFF"
    property color cardHoverBg:     dark ? "#1D2740" : "#F8FAFC"
    property color surfaceElevated: dark ? "#1E2942" : "#EDF2F7"
    property color inputBg:         dark ? "#0F1524" : "#F1F5F9"
    property color glassOverlay:    dark ? "#CC0E1525" : "#D9FFFFFF"

    // Borders
    property color border:          dark ? "#25314B" : "#E2E8F0"
    property color borderStrong:    dark ? "#36476B" : "#CBD5E1"

    // Typography
    property color textPrimary:     dark ? "#F1F5F9" : "#0F172A"
    property color textSecondary:   dark ? "#94A3B8" : "#475569"
    property color textMuted:       dark ? "#64748B" : "#94A3B8"

    // Accents
    property color accent:          dark ? "#6366F1" : "#4F46E5"
    property color accentHover:     dark ? "#818CF8" : "#4338CA"
    property color accentSoft:      dark ? "#296366F1" : "#1A4F46E5"

    property color lockAccent:      dark ? "#06B6D4" : "#0891B2"
    property color lockAccentHover: dark ? "#22D3EE" : "#0E7490"
    property color lockAccentSoft:  dark ? "#2906B6D4" : "#1A0891B2"

    property color success:         dark ? "#10B981" : "#059669"
    property color successSoft:     dark ? "#2610B981" : "#1A059669"
    property color warning:         dark ? "#F59E0B" : "#D97706"
    property color danger:          dark ? "#EF4444" : "#DC2626"
    property color dangerSoft:      dark ? "#26EF4444" : "#1ADC2626"

    // Typography scale
    readonly property string fontFamily: "Microsoft YaHei UI"
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 20

    Behavior on windowBg        { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on sidebarBg       { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on cardBg          { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on cardHoverBg     { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on surfaceElevated { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on inputBg         { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on border          { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on borderStrong    { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on textPrimary     { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on textSecondary   { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on textMuted       { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on accent          { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on lockAccent      { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
}
