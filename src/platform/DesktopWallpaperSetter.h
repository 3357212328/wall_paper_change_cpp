#pragma once

#include "WallpaperTypes.h"
#include <QString>

namespace AuraPaper {

struct WallpaperApplyResult {
    bool success = false;
    QString errorMessage;
};

class DesktopWallpaperSetter {
public:
    static WallpaperApplyResult applyWallpaper(const QString &imagePath, FitMode fitMode);
    static WallpaperApplyResult applyFitMode(FitMode fitMode);
    static QString currentDesktopWallpaperPath();
};

} // namespace AuraPaper
