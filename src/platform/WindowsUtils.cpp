#include "WindowsUtils.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QWindow>

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <dwmapi.h>
#include <psapi.h>
#include <shellapi.h>

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif

namespace AuraPaper {

namespace {
constexpr const wchar_t *kRunRegPath = L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr const wchar_t *kAppRegName = L"AuraPaper";
} // namespace

bool WindowsUtils::isAutoStartEnabled() {
    HKEY hKey = nullptr;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, kRunRegPath, 0, KEY_QUERY_VALUE, &hKey) != ERROR_SUCCESS) {
        return false;
    }
    DWORD type = 0;
    DWORD size = 0;
    const bool exists = (RegQueryValueExW(hKey, kAppRegName, nullptr, &type, nullptr, &size) == ERROR_SUCCESS)
                        && (type == REG_SZ || type == REG_EXPAND_SZ) && size > sizeof(wchar_t);
    RegCloseKey(hKey);
    return exists;
}

bool WindowsUtils::setAutoStartEnabled(bool enabled, bool startMinimized) {
    HKEY hKey = nullptr;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, kRunRegPath, 0, KEY_SET_VALUE, &hKey) != ERROR_SUCCESS) {
        return false;
    }

    LONG result = ERROR_SUCCESS;
    if (enabled) {
        QString exePath = QDir::toNativeSeparators(QCoreApplication::applicationFilePath());
        QString command = QStringLiteral("\"%1\"").arg(exePath);
        if (startMinimized) {
            command += QStringLiteral(" --minimized");
        }
        std::wstring wCmd = command.toStdWString();
        result = RegSetValueExW(hKey, kAppRegName, 0, REG_SZ,
                                reinterpret_cast<const BYTE *>(wCmd.c_str()),
                                static_cast<DWORD>((wCmd.size() + 1) * sizeof(wchar_t)));
    } else {
        result = RegDeleteValueW(hKey, kAppRegName);
        if (result == ERROR_FILE_NOT_FOUND) {
            result = ERROR_SUCCESS;
        }
    }

    RegCloseKey(hKey);
    return result == ERROR_SUCCESS;
}

void WindowsUtils::applyWindowVisuals(QWindow *window, bool darkMode) {
    if (!window) {
        return;
    }
    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (!hwnd) {
        return;
    }

    const BOOL useDark = darkMode ? TRUE : FALSE;
    DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &useDark, sizeof(useDark));

    // Windows 11 rounded corners (gracefully ignored on Windows 10)
    const DWORD cornerPref = 2; // DWMWCP_ROUND
    DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &cornerPref, sizeof(cornerPref));
}

double WindowsUtils::getProcessWorkingSetMB() {
    PROCESS_MEMORY_COUNTERS_EX pmc{};
    pmc.cb = sizeof(pmc);
    if (GetProcessMemoryInfo(GetCurrentProcess(),
                             reinterpret_cast<PROCESS_MEMORY_COUNTERS *>(&pmc),
                             sizeof(pmc))) {
        return static_cast<double>(pmc.WorkingSetSize) / (1024.0 * 1024.0);
    }
    return 0.0;
}

void WindowsUtils::trimProcessMemory() {
    SetProcessWorkingSetSize(GetCurrentProcess(),
                             static_cast<SIZE_T>(-1),
                             static_cast<SIZE_T>(-1));
}

bool WindowsUtils::isFullscreenAppRunning() {
    QUERY_USER_NOTIFICATION_STATE state = QUNS_ACCEPTS_NOTIFICATIONS;
    if (SUCCEEDED(SHQueryUserNotificationState(&state))) {
        return state == QUNS_BUSY || state == QUNS_RUNNING_D3D_FULL_SCREEN;
    }
    return false;
}

void WindowsUtils::revealFileInExplorer(const QString &filePath) {
    if (filePath.isEmpty()) {
        return;
    }
    const QString native = QDir::toNativeSeparators(QFileInfo(filePath).absoluteFilePath());
    QProcess::startDetached(QStringLiteral("explorer.exe"),
                            {QStringLiteral("/select,%1").arg(native)});
}

void WindowsUtils::openFolderInExplorer(const QString &folderPath) {
    if (folderPath.isEmpty()) {
        return;
    }
    const QString native = QDir::toNativeSeparators(QFileInfo(folderPath).absoluteFilePath());
    QProcess::startDetached(QStringLiteral("explorer.exe"), {native});
}

QString WindowsUtils::defaultWindowsWallpaperFolder() {
    const QString path = QStringLiteral("C:/Windows/Web/Wallpaper");
    if (QDir(path).exists()) {
        return path;
    }
    return {};
}

} // namespace AuraPaper
