#pragma once

#include <QString>

class QWindow;

namespace AuraPaper {

class WindowsUtils {
public:
    static bool isAutoStartEnabled();
    static bool setAutoStartEnabled(bool enabled, bool startMinimized = true);

    static void applyWindowVisuals(QWindow *window, bool darkMode);
    static void activatePopupWindow(QWindow *window);
    static double getProcessWorkingSetMB();
    static void trimProcessMemory();
    static bool isFullscreenAppRunning();

    static void revealFileInExplorer(const QString &filePath);
    static void openFolderInExplorer(const QString &folderPath);
    static QString pickFolderNative(QWindow *owner, const QString &title, const QString &initialDir);
    static QString defaultWindowsWallpaperFolder();
};

} // namespace AuraPaper
