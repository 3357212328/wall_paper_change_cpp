#pragma once

#include "WallpaperTypes.h"
#include <QSize>
#include <QString>

namespace AuraPaper {

class ImageFitRenderer {
public:
    static QString prepareForDesktop(const QString &sourcePath, QString *errorOut = nullptr);
    static QString prepareForLockScreen(const QString &sourcePath, FitMode fitMode,
                                        const QSize &targetScreenSize, QString *errorOut = nullptr);
    static bool isNativelySupportedFormat(const QString &filePath);
    static QString cacheDirectory();
};

} // namespace AuraPaper
