#pragma once

#include <QObject>

namespace AuraPaper {
Q_NAMESPACE

enum class ChannelKind : int {
    Desktop = 0,
    LockScreen = 1
};
Q_ENUM_NS(ChannelKind)

enum class SwitchOrder : int {
    FileNameAsc = 0,
    FileNameDesc = 1,
    Random = 2,
    ModifiedDesc = 3
};
Q_ENUM_NS(SwitchOrder)

enum class FitMode : int {
    Fill = 0,
    Fit = 1,
    Stretch = 2,
    Tile = 3,
    Center = 4,
    Span = 5
};
Q_ENUM_NS(FitMode)

} // namespace AuraPaper
