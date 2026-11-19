#pragma once

#include <QString>

class QWindow;

namespace AuraPaper {

class WindowsUtils {
public:
    static bool isAutoStartEnabled();
    static bool setAutoStartEnabled(bool enabled, bool startMinimized = true);

    static void applyWindowVisuals(QWindow *window, bool darkMode);
    static double getProcessWorkingSetMB();
    static void trimProcessMemory();
    static bool isFullscreenAppRunning();

    static void revealFileInExplorer(const QString &filePath);
    static void openFolderInExplorer(const QString &folderPath);
    static QString defaultWindowsWallpaperFolder();
};

} // namespace AuraPaper
