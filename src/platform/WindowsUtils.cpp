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
#include <shobjidl.h>
#include <wrl/client.h>

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

void WindowsUtils::activatePopupWindow(QWindow *window) {
    if (!window) {
        return;
    }
    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (!hwnd) {
        return;
    }
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);

    HWND fg = GetForegroundWindow();
    DWORD fgThread = fg ? GetWindowThreadProcessId(fg, nullptr) : 0;
    DWORD curThread = GetCurrentThreadId();
    bool attached = false;
    if (fgThread && fgThread != curThread) {
        attached = AttachThreadInput(curThread, fgThread, TRUE) != FALSE;
    }

    SetForegroundWindow(hwnd);
    BringWindowToTop(hwnd);
    SetFocus(hwnd);

    if (attached) {
        AttachThreadInput(curThread, fgThread, FALSE);
    }
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

QString WindowsUtils::pickFolderNative(QWindow *owner, const QString &title, const QString &initialDir) {
    const HRESULT initHr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    const bool shouldUninit = SUCCEEDED(initHr);

    QString result;
    {
        Microsoft::WRL::ComPtr<IFileOpenDialog> dialog;
        if (SUCCEEDED(CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_ALL,
                                       IID_PPV_ARGS(&dialog))) && dialog) {
            DWORD options = 0;
            if (SUCCEEDED(dialog->GetOptions(&options))) {
                dialog->SetOptions(options | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM | FOS_PATHMUSTEXIST);
            }
            if (!title.isEmpty()) {
                const std::wstring wTitle = title.toStdWString();
                dialog->SetTitle(wTitle.c_str());
            }
            if (!initialDir.isEmpty() && QDir(initialDir).exists()) {
                const std::wstring wDir = QDir::toNativeSeparators(initialDir).toStdWString();
                Microsoft::WRL::ComPtr<IShellItem> folderItem;
                if (SUCCEEDED(SHCreateItemFromParsingName(wDir.c_str(), nullptr,
                                                          IID_PPV_ARGS(&folderItem))) && folderItem) {
                    dialog->SetFolder(folderItem.Get());
                }
            }

            HWND hwndOwner = owner ? reinterpret_cast<HWND>(owner->winId()) : nullptr;
            if (SUCCEEDED(dialog->Show(hwndOwner))) {
                Microsoft::WRL::ComPtr<IShellItem> item;
                if (SUCCEEDED(dialog->GetResult(&item)) && item) {
                    PWSTR pathPtr = nullptr;
                    if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &pathPtr)) && pathPtr) {
                        result = QDir::fromNativeSeparators(QString::fromWCharArray(pathPtr));
                        CoTaskMemFree(pathPtr);
                    }
                }
            }
        }
    }

    if (shouldUninit) {
        CoUninitialize();
    }
    return result;
}

QString WindowsUtils::defaultWindowsWallpaperFolder() {
    const QString path = QStringLiteral("C:/Windows/Web/Wallpaper");
    if (QDir(path).exists()) {
        return path;
    }
    return {};
}

} // namespace AuraPaper
