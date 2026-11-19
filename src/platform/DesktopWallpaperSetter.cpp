#include "DesktopWallpaperSetter.h"

#include <QDir>
#include <QFileInfo>

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shobjidl.h>
#include <wrl/client.h>

namespace AuraPaper {

namespace {

class ScopedComInit {
public:
    ScopedComInit() {
        const HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
        m_shouldUninit = SUCCEEDED(hr);
    }
    ~ScopedComInit() {
        if (m_shouldUninit) {
            CoUninitialize();
        }
    }
private:
    bool m_shouldUninit = false;
};

DESKTOP_WALLPAPER_POSITION toDesktopPosition(FitMode mode) {
    switch (mode) {
    case FitMode::Center:  return DWPOS_CENTER;
    case FitMode::Tile:    return DWPOS_TILE;
    case FitMode::Stretch: return DWPOS_STRETCH;
    case FitMode::Fit:     return DWPOS_FIT;
    case FitMode::Span:    return DWPOS_SPAN;
    case FitMode::Fill:
    default:               return DWPOS_FILL;
    }
}

void writeFitModeToRegistry(FitMode mode) {
    const wchar_t *style = L"10";
    const wchar_t *tile = L"0";

    switch (mode) {
    case FitMode::Fill:    style = L"10"; tile = L"0"; break;
    case FitMode::Fit:     style = L"6";  tile = L"0"; break;
    case FitMode::Stretch: style = L"2";  tile = L"0"; break;
    case FitMode::Tile:    style = L"0";  tile = L"1"; break;
    case FitMode::Center:  style = L"0";  tile = L"0"; break;
    case FitMode::Span:    style = L"22"; tile = L"0"; break;
    }

    HKEY hKey = nullptr;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Control Panel\\Desktop", 0, KEY_SET_VALUE, &hKey) == ERROR_SUCCESS) {
        RegSetValueExW(hKey, L"WallpaperStyle", 0, REG_SZ,
                       reinterpret_cast<const BYTE *>(style),
                       static_cast<DWORD>((wcslen(style) + 1) * sizeof(wchar_t)));
        RegSetValueExW(hKey, L"TileWallpaper", 0, REG_SZ,
                       reinterpret_cast<const BYTE *>(tile),
                       static_cast<DWORD>((wcslen(tile) + 1) * sizeof(wchar_t)));
        RegCloseKey(hKey);
    }
}

QString formatHResult(HRESULT hr) {
    return QStringLiteral("0x%1").arg(static_cast<quint32>(hr), 8, 16, QLatin1Char('0'));
}

} // namespace

WallpaperApplyResult DesktopWallpaperSetter::applyWallpaper(const QString &imagePath, FitMode fitMode) {
    QFileInfo info(imagePath);
    if (!info.exists() || !info.isFile()) {
        return {false, QStringLiteral("壁纸文件不存在: %1").arg(imagePath)};
    }

    const QString nativePath = QDir::toNativeSeparators(info.absoluteFilePath());
    const std::wstring wPath = nativePath.toStdWString();

    ScopedComInit comInit;
    Microsoft::WRL::ComPtr<IDesktopWallpaper> desktopWallpaper;
    HRESULT hr = CoCreateInstance(CLSID_DesktopWallpaper, nullptr, CLSCTX_ALL,
                                  IID_PPV_ARGS(&desktopWallpaper));
    if (SUCCEEDED(hr) && desktopWallpaper) {
        desktopWallpaper->SetPosition(toDesktopPosition(fitMode));
        hr = desktopWallpaper->SetWallpaper(nullptr, wPath.c_str());
        if (SUCCEEDED(hr)) {
            return {true, {}};
        }
    }

    // Fallback to Registry + SystemParametersInfoW
    writeFitModeToRegistry(fitMode);
    if (SystemParametersInfoW(SPI_SETDESKWALLPAPER, 0,
                              const_cast<wchar_t *>(wPath.c_str()),
                              SPIF_UPDATEINIFILE | SPIF_SENDCHANGE)) {
        return {true, {}};
    }

    return {false, QStringLiteral("设置桌面壁纸失败 (COM %1, Win32 %2)")
                       .arg(formatHResult(hr))
                       .arg(GetLastError())};
}

WallpaperApplyResult DesktopWallpaperSetter::applyFitMode(FitMode fitMode) {
    ScopedComInit comInit;
    Microsoft::WRL::ComPtr<IDesktopWallpaper> desktopWallpaper;
    HRESULT hr = CoCreateInstance(CLSID_DesktopWallpaper, nullptr, CLSCTX_ALL,
                                  IID_PPV_ARGS(&desktopWallpaper));
    if (SUCCEEDED(hr) && desktopWallpaper) {
        hr = desktopWallpaper->SetPosition(toDesktopPosition(fitMode));
        if (SUCCEEDED(hr)) {
            return {true, {}};
        }
    }

    writeFitModeToRegistry(fitMode);
    const QString currentPath = currentDesktopWallpaperPath();
    if (!currentPath.isEmpty()) {
        std::wstring wPath = QDir::toNativeSeparators(currentPath).toStdWString();
        if (SystemParametersInfoW(SPI_SETDESKWALLPAPER, 0,
                                  const_cast<wchar_t *>(wPath.c_str()),
                                  SPIF_UPDATEINIFILE | SPIF_SENDCHANGE)) {
            return {true, {}};
        }
    }

    return {false, QStringLiteral("更新适应模式失败 (%1)").arg(formatHResult(hr))};
}

QString DesktopWallpaperSetter::currentDesktopWallpaperPath() {
    ScopedComInit comInit;
    Microsoft::WRL::ComPtr<IDesktopWallpaper> desktopWallpaper;
    if (SUCCEEDED(CoCreateInstance(CLSID_DesktopWallpaper, nullptr, CLSCTX_ALL,
                                   IID_PPV_ARGS(&desktopWallpaper))) && desktopWallpaper) {
        LPWSTR wallpaper = nullptr;
        if (SUCCEEDED(desktopWallpaper->GetWallpaper(nullptr, &wallpaper)) && wallpaper) {
            QString result = QString::fromWCharArray(wallpaper);
            CoTaskMemFree(wallpaper);
            if (!result.isEmpty() && QFileInfo::exists(result)) {
                return QDir::fromNativeSeparators(result);
            }
        }
    }

    wchar_t buffer[MAX_PATH * 2] = {0};
    if (SystemParametersInfoW(SPI_GETDESKWALLPAPER, static_cast<UINT>(std::size(buffer)), buffer, 0)) {
        QString result = QString::fromWCharArray(buffer);
        if (!result.isEmpty() && QFileInfo::exists(result)) {
            return QDir::fromNativeSeparators(result);
        }
    }

    return {};
}

} // namespace AuraPaper
