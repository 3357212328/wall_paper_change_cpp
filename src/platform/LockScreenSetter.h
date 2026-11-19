#pragma once

#include <string>

namespace AuraPaper {

struct NativeApplyResult {
    bool success = false;
    std::wstring errorMessage;
};

class LockScreenSetter {
public:
    // Must be called from a background worker thread (MTA-friendly).
    // Expects an absolute Windows native file path (e.g., C:\Users\...\img.jpg).
    static NativeApplyResult applyLockScreenImage(const std::wstring &nativeFilePath);
};

} // namespace AuraPaper
