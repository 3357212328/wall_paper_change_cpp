#include "NativeSystemTray.h"

#include <QMetaObject>

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>

namespace AuraPaper {

namespace {
constexpr UINT kTrayCallbackMsg = WM_APP + 101;
constexpr UINT kTrayIconId = 1;
constexpr WORD kAppIconResourceId = 101;
constexpr const wchar_t *kTrayWindowClass = L"AuraPaper_NativeTrayWindowClass";
} // namespace

NativeSystemTray::NativeSystemTray(QObject *parent)
    : QObject(parent) {
    m_taskbarCreatedMsg = RegisterWindowMessageW(L"TaskbarCreated");

    const int cx = GetSystemMetrics(SM_CXSMICON);
    const int cy = GetSystemMetrics(SM_CYSMICON);
    HICON icon = static_cast<HICON>(LoadImageW(
        GetModuleHandleW(nullptr),
        MAKEINTRESOURCEW(kAppIconResourceId),
        IMAGE_ICON, cx, cy, LR_DEFAULTCOLOR));
    if (!icon) {
        icon = LoadIconW(nullptr, IDI_APPLICATION);
    }
    m_hIcon = icon;

    createMessageWindow();
}

NativeSystemTray::~NativeSystemTray() {
    hide();
    if (m_hwnd) {
        DestroyWindow(static_cast<HWND>(m_hwnd));
        m_hwnd = nullptr;
    }
    if (m_hIcon) {
        DestroyIcon(static_cast<HICON>(m_hIcon));
        m_hIcon = nullptr;
    }
}

void NativeSystemTray::setToolTip(const QString &tip) {
    m_toolTip = tip;
    if (m_visible && m_hwnd) {
        NOTIFYICONDATAW nid{};
        nid.cbSize = sizeof(nid);
        nid.hWnd = static_cast<HWND>(m_hwnd);
        nid.uID = kTrayIconId;
        nid.uFlags = NIF_TIP;
        const std::wstring wTip = m_toolTip.left(127).toStdWString();
        wcsncpy_s(nid.szTip, wTip.c_str(), _TRUNCATE);
        Shell_NotifyIconW(NIM_MODIFY, &nid);
    }
}

void NativeSystemTray::show() {
    if (m_visible) {
        return;
    }
    addIcon();
}

void NativeSystemTray::ensureVisible() {
    if (!m_hwnd) {
        createMessageWindow();
    }
    if (!m_visible) {
        addIcon();
    }
}

void NativeSystemTray::hide() {
    if (!m_visible) {
        return;
    }
    removeIcon();
}

void NativeSystemTray::showBalloon(const QString &title, const QString &message) {
    if (!m_visible || !m_hwnd) {
        return;
    }
    NOTIFYICONDATAW nid{};
    nid.cbSize = sizeof(nid);
    nid.hWnd = static_cast<HWND>(m_hwnd);
    nid.uID = kTrayIconId;
    nid.uFlags = NIF_INFO;
    nid.dwInfoFlags = NIIF_INFO;
    const std::wstring wTitle = title.left(63).toStdWString();
    const std::wstring wMsg = message.left(255).toStdWString();
    wcsncpy_s(nid.szInfoTitle, wTitle.c_str(), _TRUNCATE);
    wcsncpy_s(nid.szInfo, wMsg.c_str(), _TRUNCATE);
    Shell_NotifyIconW(NIM_MODIFY, &nid);
}

void NativeSystemTray::createMessageWindow() {
    HINSTANCE hInst = GetModuleHandleW(nullptr);
    WNDCLASSEXW wc{};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = reinterpret_cast<WNDPROC>(&NativeSystemTray::wndProc);
    wc.hInstance = hInst;
    wc.lpszClassName = kTrayWindowClass;
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, kTrayWindowClass, L"AuraPaperTrayHost", 0,
        0, 0, 0, 0, nullptr, nullptr, hInst, this);
    m_hwnd = hwnd;
}

void NativeSystemTray::addIcon() {
    if (!m_hwnd) {
        return;
    }
    NOTIFYICONDATAW nid{};
    nid.cbSize = sizeof(nid);
    nid.hWnd = static_cast<HWND>(m_hwnd);
    nid.uID = kTrayIconId;
    nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    nid.uCallbackMessage = kTrayCallbackMsg;
    nid.hIcon = static_cast<HICON>(m_hIcon);
    const std::wstring wTip = m_toolTip.left(127).toStdWString();
    wcsncpy_s(nid.szTip, wTip.c_str(), _TRUNCATE);

    if (Shell_NotifyIconW(NIM_ADD, &nid)) {
        m_visible = true;
    }
}

void NativeSystemTray::removeIcon() {
    if (!m_hwnd) {
        return;
    }
    NOTIFYICONDATAW nid{};
    nid.cbSize = sizeof(nid);
    nid.hWnd = static_cast<HWND>(m_hwnd);
    nid.uID = kTrayIconId;
    Shell_NotifyIconW(NIM_DELETE, &nid);
    m_visible = false;
}

long long __stdcall NativeSystemTray::wndProc(void *hwndPtr, unsigned int msg,
                                              unsigned long long wParam, long long lParam) {
    HWND hwnd = static_cast<HWND>(hwndPtr);
    NativeSystemTray *self = nullptr;

    if (msg == WM_NCCREATE) {
        auto *cs = reinterpret_cast<CREATESTRUCTW *>(lParam);
        self = static_cast<NativeSystemTray *>(cs->lpCreateParams);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
        return DefWindowProcW(hwnd, msg, wParam, lParam);
    }

    self = reinterpret_cast<NativeSystemTray *>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (self) {
        if (msg == kTrayCallbackMsg) {
            const UINT eventMsg = LOWORD(static_cast<DWORD>(lParam));
            if (eventMsg == WM_LBUTTONUP || eventMsg == WM_LBUTTONDBLCLK) {
                QMetaObject::invokeMethod(self, &NativeSystemTray::leftClicked, Qt::QueuedConnection);
                return 0;
            }
            if (eventMsg == WM_RBUTTONUP) {
                // Microsoft KB135788: claim foreground synchronously on tray right-click
                SetForegroundWindow(hwnd);
                QMetaObject::invokeMethod(self, &NativeSystemTray::rightClicked, Qt::QueuedConnection);
                return 0;
            }
        } else if (msg == WM_POWERBROADCAST) {
            if (wParam == PBT_APMSUSPEND) {
                QMetaObject::invokeMethod(self, &NativeSystemTray::systemSuspending, Qt::DirectConnection);
                return TRUE;
            }
            if (wParam == PBT_APMRESUMEAUTOMATIC || wParam == PBT_APMRESUMESUSPEND) {
                QMetaObject::invokeMethod(self, &NativeSystemTray::systemResumed, Qt::QueuedConnection);
                return TRUE;
            }
        } else if (self->m_taskbarCreatedMsg != 0 && msg == self->m_taskbarCreatedMsg) {
            if (self->m_visible) {
                self->m_visible = false;
                self->addIcon();
            }
            return 0;
        }
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

} // namespace AuraPaper
