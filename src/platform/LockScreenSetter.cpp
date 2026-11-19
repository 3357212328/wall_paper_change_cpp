#include "LockScreenSetter.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <winrt/base.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.System.UserProfile.h>

#include <sstream>
#include <iomanip>

namespace AuraPaper {

namespace {

class ScopedWinRtApartment {
public:
    ScopedWinRtApartment() {
        try {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
            m_initialized = true;
        } catch (const winrt::hresult_error &e) {
            // RPC_E_CHANGED_MODE (0x80010106) means apartment is already initialized on this thread.
            if (e.code() == RPC_E_CHANGED_MODE) {
                m_initialized = false;
            } else {
                throw;
            }
        }
    }
    ~ScopedWinRtApartment() {
        if (m_initialized) {
            winrt::uninit_apartment();
        }
    }
private:
    bool m_initialized = false;
};

std::wstring formatError(const winrt::hresult_error &e) {
    std::wostringstream oss;
    oss << L"0x" << std::hex << std::uppercase << std::setw(8) << std::setfill(L'0')
        << static_cast<unsigned long>(e.code().value)
        << L": " << e.message().c_str();
    return oss.str();
}

} // namespace

NativeApplyResult LockScreenSetter::applyLockScreenImage(const std::wstring &nativeFilePath) {
    if (nativeFilePath.empty()) {
        return {false, L"锁屏壁纸路径为空"};
    }

    try {
        ScopedWinRtApartment apartment;

        auto file = winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(nativeFilePath).get();
        if (!file) {
            return {false, L"无法读取锁屏壁纸文件"};
        }

        winrt::Windows::System::UserProfile::LockScreen::SetImageFileAsync(file).get();
        return {true, L""};
    } catch (const winrt::hresult_error &e) {
        return {false, L"设置锁屏壁纸失败 (" + formatError(e) + L")"};
    } catch (const std::exception &e) {
        std::string narrow(e.what());
        std::wstring wide(narrow.begin(), narrow.end());
        return {false, L"设置锁屏壁纸异常: " + wide};
    }
}

} // namespace AuraPaper
