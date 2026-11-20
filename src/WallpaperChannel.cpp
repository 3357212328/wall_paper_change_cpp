#include "WallpaperChannel.h"
#include "platform/DesktopWallpaperSetter.h"
#include "platform/ImageFitRenderer.h"
#include "platform/LockScreenSetter.h"
#include "platform/WindowsUtils.h"

#include <QCollator>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QGuiApplication>
#include <QMetaObject>
#include <QPointer>
#include <QRandomGenerator>
#include <QScreen>
#include <QThreadPool>

#include <algorithm>

namespace AuraPaper {

namespace {

constexpr int kMinIntervalSeconds = 5;
constexpr int kMaxIntervalSeconds = 86400 * 7; // 7 days
constexpr int kMaxHistorySize = 60;

bool isSupportedImageExt(const QString &extLower) {
    return extLower == QLatin1String("jpg")
           || extLower == QLatin1String("jpeg")
           || extLower == QLatin1String("png")
           || extLower == QLatin1String("bmp")
           || extLower == QLatin1String("webp")
           || extLower == QLatin1String("jfif")
           || extLower == QLatin1String("dib");
}

QString formatFileSize(qint64 bytes) {
    if (bytes < 1024) {
        return QStringLiteral("%1 B").arg(bytes);
    }
    if (bytes < 1024 * 1024) {
        return QStringLiteral("%1 KB").arg(bytes / 1024.0, 0, 'f', 0);
    }
    return QStringLiteral("%1 MB").arg(bytes / (1024.0 * 1024.0), 0, 'f', 1);
}

QSize primaryScreenPhysicalSize() {
    if (QScreen *screen = QGuiApplication::primaryScreen()) {
        const qreal dpr = screen->devicePixelRatio();
        const QSize logical = screen->size();
        return QSize(qRound(logical.width() * dpr), qRound(logical.height() * dpr));
    }
    return QSize(1920, 1080);
}

} // namespace

WallpaperChannel::WallpaperChannel(ChannelKind kind, QObject *parent)
    : QObject(parent), m_kind(kind) {
    m_filterModel.setSourceModel(&m_listModel);
    m_clock.start();

    m_switchTimer.setSingleShot(true);
    connect(&m_switchTimer, &QTimer::timeout, this, &WallpaperChannel::onSwitchTimerTimeout);

    m_watcherDebounce.setSingleShot(true);
    m_watcherDebounce.setInterval(700);
    connect(&m_watcherDebounce, &QTimer::timeout, this, &WallpaperChannel::scheduleFolderScan);

    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this](const QString &) {
        m_watcherDebounce.start();
    });

    if (m_kind == ChannelKind::Desktop) {
        const QString existing = DesktopWallpaperSetter::currentDesktopWallpaperPath();
        if (!existing.isEmpty()) {
            m_currentImagePath = existing;
            m_currentImageUrl = WallpaperListModel::makeThumbUrl(existing);
        }
    }
}

WallpaperChannel::~WallpaperChannel() {
    m_scanGeneration.fetch_add(1);
    m_switchTimer.stop();
}

void WallpaperChannel::setFullscreenCheckCallback(std::function<bool()> callback) {
    m_fullscreenCheck = std::move(callback);
}

QString WallpaperChannel::title() const {
    return m_kind == ChannelKind::Desktop ? QStringLiteral("桌面壁纸") : QStringLiteral("锁屏壁纸");
}

QString WallpaperChannel::currentImageName() const {
    if (m_currentImagePath.isEmpty()) {
        return QStringLiteral("未选择壁纸");
    }
    return QFileInfo(m_currentImagePath).fileName();
}

void WallpaperChannel::loadSettings(QSettings &settings) {
    const QString group = (m_kind == ChannelKind::Desktop)
                              ? QStringLiteral("Desktop")
                              : QStringLiteral("LockScreen");
    settings.beginGroup(group);

    m_folderPath = settings.value(QStringLiteral("folderPath")).toString();
    m_includeSubfolders = settings.value(QStringLiteral("includeSubfolders"), true).toBool();
    m_intervalSeconds = qBound(kMinIntervalSeconds,
                               settings.value(QStringLiteral("intervalSeconds"), 300).toInt(),
                               kMaxIntervalSeconds);
    const int orderVal = settings.value(QStringLiteral("switchOrder"), 0).toInt();
    m_switchOrder = static_cast<SwitchOrder>(qBound(0, orderVal, 3));

    const int maxFit = (m_kind == ChannelKind::Desktop) ? 5 : 4;
    const int fitVal = settings.value(QStringLiteral("fitMode"), 0).toInt();
    m_fitMode = static_cast<FitMode>(qBound(0, fitVal, maxFit));

    const QString savedCurrent = settings.value(QStringLiteral("currentImagePath")).toString();
    if (!savedCurrent.isEmpty() && QFileInfo::exists(savedCurrent)) {
        if (m_currentImagePath.isEmpty() || m_kind == ChannelKind::LockScreen) {
            m_currentImagePath = savedCurrent;
            m_currentImageUrl = WallpaperListModel::makeThumbUrl(savedCurrent);
        }
    }

    m_autoResumePending = settings.value(QStringLiteral("running"), false).toBool();
    const qint64 totalMs = static_cast<qint64>(m_intervalSeconds) * 1000;
    const qint64 loadedRemainMs = settings.value(QStringLiteral("remainingMs"), -1).toLongLong();
    if (m_autoResumePending && loadedRemainMs > 0) {
        m_savedRemainingMs = qBound<qint64>(1000, loadedRemainMs, totalMs);
        m_remainingSeconds = static_cast<int>((m_savedRemainingMs + 999) / 1000);
        m_progress = totalMs > 0
                         ? qBound(0.0, static_cast<double>(totalMs - m_savedRemainingMs) / static_cast<double>(totalMs), 1.0)
                         : 0.0;
    } else {
        m_savedRemainingMs = -1;
    }
    settings.endGroup();

    emit folderPathChanged();
    emit includeSubfoldersChanged();
    emit intervalSecondsChanged();
    emit switchOrderChanged();
    emit fitModeChanged();
    emit currentImageChanged();
    emit countdownChanged();

    if (!m_folderPath.isEmpty() && QDir(m_folderPath).exists()) {
        updateFileWatcher();
        scheduleFolderScan();
    } else {
        m_autoResumePending = false;
        m_savedRemainingMs = -1;
    }
}

void WallpaperChannel::saveSettings(QSettings &settings) const {
    const QString group = (m_kind == ChannelKind::Desktop)
                              ? QStringLiteral("Desktop")
                              : QStringLiteral("LockScreen");
    const bool effectiveRunning = m_running || m_autoResumePending;
    const qint64 remainMs = m_pausedForSleep
                                ? m_sleepRemainingMs
                                : (m_running
                                       ? currentRemainingMs()
                                       : (m_autoResumePending ? m_savedRemainingMs : -1));

    settings.beginGroup(group);
    settings.setValue(QStringLiteral("folderPath"), m_folderPath);
    settings.setValue(QStringLiteral("includeSubfolders"), m_includeSubfolders);
    settings.setValue(QStringLiteral("intervalSeconds"), m_intervalSeconds);
    settings.setValue(QStringLiteral("switchOrder"), static_cast<int>(m_switchOrder));
    settings.setValue(QStringLiteral("fitMode"), static_cast<int>(m_fitMode));
    settings.setValue(QStringLiteral("currentImagePath"), m_currentImagePath);
    settings.setValue(QStringLiteral("running"), effectiveRunning);
    settings.setValue(QStringLiteral("remainingMs"), remainMs);
    settings.endGroup();
}

void WallpaperChannel::setFolderPath(const QString &path) {
    QString normalized = QDir::fromNativeSeparators(path.trimmed());
    if (normalized == m_folderPath) {
        return;
    }
    m_folderPath = normalized;
    emit folderPathChanged();
    emit settingsDirty();

    updateFileWatcher();
    scheduleFolderScan();
}

void WallpaperChannel::setIncludeSubfolders(bool include) {
    if (m_includeSubfolders == include) {
        return;
    }
    m_includeSubfolders = include;
    emit includeSubfoldersChanged();
    emit settingsDirty();

    if (!m_folderPath.isEmpty()) {
        scheduleFolderScan();
    }
}

void WallpaperChannel::setIntervalSeconds(int seconds) {
    const int clamped = qBound(kMinIntervalSeconds, seconds, kMaxIntervalSeconds);
    if (m_intervalSeconds == clamped) {
        return;
    }
    m_intervalSeconds = clamped;
    emit intervalSecondsChanged();
    emit settingsDirty();

    if (m_running) {
        restartSwitchTimer();
    }
}

void WallpaperChannel::setSwitchOrderInt(int order) {
    const auto newOrder = static_cast<SwitchOrder>(qBound(0, order, 3));
    if (m_switchOrder == newOrder) {
        return;
    }
    m_switchOrder = newOrder;
    emit switchOrderChanged();
    emit settingsDirty();

    // Re-sort gallery & reset playback bag
    if (!m_folderPath.isEmpty()) {
        scheduleFolderScan();
    } else {
        rebuildOrderPool();
    }
}

void WallpaperChannel::setFitModeInt(int mode) {
    const int maxFit = (m_kind == ChannelKind::Desktop) ? 5 : 4;
    const auto newMode = static_cast<FitMode>(qBound(0, mode, maxFit));
    if (m_fitMode == newMode) {
        return;
    }
    m_fitMode = newMode;
    emit fitModeChanged();
    emit settingsDirty();

    // Live apply fit mode change
    if (m_kind == ChannelKind::Desktop) {
        QPointer<WallpaperChannel> self(this);
        QThreadPool::globalInstance()->start([self, newMode]() {
            const auto res = DesktopWallpaperSetter::applyFitMode(newMode);
            if (!self) return;
            QMetaObject::invokeMethod(self, [self, res]() {
                if (!self) return;
                if (!res.success) {
                    self->setLastError(res.errorMessage);
                    emit self->notificationRequested(res.errorMessage, true);
                } else {
                    self->setLastError({});
                    emit self->notificationRequested(QStringLiteral("已更新桌面壁纸适应模式"), false);
                }
            }, Qt::QueuedConnection);
        });
    } else if (!m_currentImagePath.isEmpty() && QFileInfo::exists(m_currentImagePath)) {
        applyImageInternal(m_currentImagePath, false, false, false);
    }
}

void WallpaperChannel::setSearchText(const QString &text) {
    if (m_filterModel.searchQuery() == text.trimmed()) {
        return;
    }
    m_filterModel.setSearchQuery(text);
    emit searchTextChanged();
}

void WallpaperChannel::start() {
    if (m_running) {
        return;
    }
    if (m_folderPath.isEmpty() || !QDir(m_folderPath).exists()) {
        emit notificationRequested(
            QStringLiteral("请先为%1选择一个有效的图片文件夹").arg(title()), true);
        return;
    }
    if (m_listModel.count() == 0) {
        if (m_scanning) {
            m_autoResumePending = true;
            return;
        }
        emit notificationRequested(
            QStringLiteral("%1文件夹中未找到支持的图片文件").arg(title()), true);
        return;
    }

    m_running = true;
    emit runningChanged();
    emit settingsDirty();

    // Check if current image is from the selected folder; if not, switch right away
    const auto &entries = m_listModel.entries();
    const bool currentInFolder = std::any_of(entries.begin(), entries.end(),
        [this](const WallpaperEntry &e) {
            return e.filePath.compare(m_currentImagePath, Qt::CaseInsensitive) == 0;
        });

    restartSwitchTimer();
    emit notificationRequested(QStringLiteral("已启动%1自动更换").arg(title()), false);

    if (!currentInFolder) {
        const QString firstPath = pickNextImagePath();
        if (!firstPath.isEmpty()) {
            applyImageInternal(firstPath, true, true, true);
        }
    }
}

void WallpaperChannel::stop() {
    m_autoResumePending = false;
    m_savedRemainingMs = -1;
    m_pausedForSleep = false;
    m_sleepRemainingMs = -1;
    if (!m_running) {
        return;
    }
    m_running = false;
    m_switchTimer.stop();
    m_remainingSeconds = 0;
    m_progress = 0.0;
    emit runningChanged();
    emit countdownChanged();
    emit settingsDirty();
    emit notificationRequested(QStringLiteral("已停止%1自动更换").arg(title()), false);
}

void WallpaperChannel::toggleRunning() {
    if (m_running) {
        stop();
    } else {
        start();
    }
}

void WallpaperChannel::nextWallpaper() {
    if (m_listModel.count() == 0) {
        emit notificationRequested(
            QStringLiteral("%1文件夹暂无可用图片，请先选择文件夹").arg(title()), true);
        return;
    }

    // If user stepped back in history, walk forward first
    if (m_historyCursor >= 0 && m_historyCursor + 1 < m_history.size()) {
        ++m_historyCursor;
        const QString nextFromHistory = m_history.at(m_historyCursor);
        if (QFileInfo::exists(nextFromHistory)) {
            applyImageInternal(nextFromHistory, false, m_running, false);
            return;
        }
    }

    const QString nextPath = pickNextImagePath();
    if (!nextPath.isEmpty()) {
        applyImageInternal(nextPath, true, m_running, false);
    }
}

void WallpaperChannel::previousWallpaper() {
    if (m_listModel.count() == 0) {
        return;
    }

    if (m_historyCursor > 0 && m_historyCursor - 1 < m_history.size()) {
        --m_historyCursor;
        const QString prev = m_history.at(m_historyCursor);
        if (QFileInfo::exists(prev)) {
            applyImageInternal(prev, false, m_running, false);
            return;
        }
    }

    // Fallback: previous item in list
    const auto &entries = m_listModel.entries();
    int curIdx = -1;
    for (int i = 0; i < entries.size(); ++i) {
        if (entries.at(i).filePath.compare(m_currentImagePath, Qt::CaseInsensitive) == 0) {
            curIdx = i;
            break;
        }
    }
    const int prevIdx = (curIdx <= 0) ? (entries.size() - 1) : (curIdx - 1);
    m_sequentialCursor = prevIdx;
    applyImageInternal(entries.at(prevIdx).filePath, true, m_running, false);
}

void WallpaperChannel::applyImage(const QString &filePath) {
    if (filePath.isEmpty() || !QFileInfo::exists(filePath)) {
        emit notificationRequested(QStringLiteral("图片文件不存在"), true);
        return;
    }
    applyImageInternal(filePath, true, m_running, false);
}

void WallpaperChannel::refreshFolder() {
    if (!m_folderPath.isEmpty()) {
        scheduleFolderScan();
    }
}

void WallpaperChannel::browseFolder() {
    const QString initialDir = (!m_folderPath.isEmpty() && QDir(m_folderPath).exists())
                                   ? m_folderPath
                                   : QDir::homePath();
    const QString selected = WindowsUtils::pickFolderNative(
        QGuiApplication::focusWindow(),
        QStringLiteral("选择%1文件夹").arg(title()),
        initialDir);
    if (!selected.isEmpty()) {
        setFolderPath(selected);
    }
}

void WallpaperChannel::setFolderFromUrl(const QUrl &url) {
    const QString localPath = url.isLocalFile() ? url.toLocalFile() : url.toString();
    QFileInfo info(localPath);
    if (info.isDir()) {
        setFolderPath(info.absoluteFilePath());
    } else if (info.isFile()) {
        setFolderPath(info.absolutePath());
    }
}

void WallpaperChannel::useSystemDefaultFolder() {
    const QString sysFolder = WindowsUtils::defaultWindowsWallpaperFolder();
    if (!sysFolder.isEmpty()) {
        setFolderPath(sysFolder);
        emit notificationRequested(QStringLiteral("已加载 Windows 系统自带壁纸库"), false);
    } else {
        emit notificationRequested(QStringLiteral("未找到系统默认壁纸目录"), true);
    }
}

void WallpaperChannel::openFolder() const {
    if (!m_folderPath.isEmpty()) {
        WindowsUtils::openFolderInExplorer(m_folderPath);
    }
}

void WallpaperChannel::revealCurrentImage() const {
    if (!m_currentImagePath.isEmpty()) {
        WindowsUtils::revealFileInExplorer(m_currentImagePath);
    }
}

void WallpaperChannel::revealImage(const QString &filePath) const {
    if (!filePath.isEmpty()) {
        WindowsUtils::revealFileInExplorer(filePath);
    }
}

void WallpaperChannel::refreshCountdownDisplay() {
    if (!m_running) {
        if (m_remainingSeconds != 0 || m_progress != 0.0) {
            m_remainingSeconds = 0;
            m_progress = 0.0;
            emit countdownChanged();
        }
        return;
    }
    if (m_pausedForSleep) {
        return;
    }

    const qint64 totalMs = static_cast<qint64>(m_intervalSeconds) * 1000;
    const qint64 elapsedMs = m_clock.elapsed() - m_cycleStartMs;
    const qint64 remainMs = qMax<qint64>(0, totalMs - elapsedMs);
    const int newRemainSec = static_cast<int>((remainMs + 999) / 1000);
    const double newProgress = totalMs > 0
                                   ? qBound(0.0, static_cast<double>(elapsedMs) / static_cast<double>(totalMs), 1.0)
                                   : 0.0;

    if (newRemainSec != m_remainingSeconds || qAbs(newProgress - m_progress) > 0.002) {
        m_remainingSeconds = newRemainSec;
        m_progress = newProgress;
        emit countdownChanged();
    }
}

void WallpaperChannel::updateFileWatcher() {
    const QStringList watched = m_watcher.directories();
    if (!watched.isEmpty()) {
        m_watcher.removePaths(watched);
    }
    if (!m_folderPath.isEmpty() && QDir(m_folderPath).exists()) {
        m_watcher.addPath(m_folderPath);
    }
}

void WallpaperChannel::scheduleFolderScan() {
    const quint64 gen = m_scanGeneration.fetch_add(1) + 1;
    const QString folder = m_folderPath;
    const bool recursive = m_includeSubfolders;
    const SwitchOrder order = m_switchOrder;

    if (folder.isEmpty() || !QDir(folder).exists()) {
        m_scanning = false;
        emit scanningChanged();
        handleScanFinished(gen, {});
        return;
    }

    if (!m_scanning) {
        m_scanning = true;
        emit scanningChanged();
    }

    QPointer<WallpaperChannel> self(this);
    QThreadPool::globalInstance()->start([self, gen, folder, recursive, order]() {
        QVector<WallpaperEntry> found;
        const QDirIterator::IteratorFlags flags = recursive
            ? QDirIterator::Subdirectories
            : QDirIterator::NoIteratorFlags;

        QDirIterator it(folder, QDir::Files | QDir::Readable | QDir::NoDotAndDotDot, flags);
        while (it.hasNext()) {
            if (!self || self->m_scanGeneration.load() != gen) {
                return; // Superseded by newer scan
            }
            const QString filePath = it.next();
            const QFileInfo fi = it.fileInfo();
            if (!isSupportedImageExt(fi.suffix().toLower())) {
                continue;
            }
            WallpaperEntry entry;
            entry.filePath = QDir::fromNativeSeparators(fi.absoluteFilePath());
            entry.fileName = fi.fileName();
            entry.thumbUrl = WallpaperListModel::makeThumbUrl(entry.filePath);
            entry.sizeText = formatFileSize(fi.size());
            entry.modifiedMs = fi.lastModified().toMSecsSinceEpoch();
            found.push_back(std::move(entry));
        }

        QCollator collator;
        collator.setNumericMode(true);
        collator.setCaseSensitivity(Qt::CaseInsensitive);

        if (order == SwitchOrder::FileNameDesc) {
            std::sort(found.begin(), found.end(), [&](const WallpaperEntry &a, const WallpaperEntry &b) {
                return collator.compare(a.fileName, b.fileName) > 0;
            });
        } else if (order == SwitchOrder::ModifiedDesc) {
            std::sort(found.begin(), found.end(), [&](const WallpaperEntry &a, const WallpaperEntry &b) {
                if (a.modifiedMs != b.modifiedMs) return a.modifiedMs > b.modifiedMs;
                return collator.compare(a.fileName, b.fileName) < 0;
            });
        } else {
            // FileNameAsc or Random gallery display order: natural ascending
            std::sort(found.begin(), found.end(), [&](const WallpaperEntry &a, const WallpaperEntry &b) {
                return collator.compare(a.fileName, b.fileName) < 0;
            });
        }

        if (!self) return;
        QMetaObject::invokeMethod(self, [self, gen, entries = std::move(found)]() mutable {
            if (self) {
                self->handleScanFinished(gen, std::move(entries));
            }
        }, Qt::QueuedConnection);
    });
}

void WallpaperChannel::handleScanFinished(quint64 generation, QVector<WallpaperEntry> entries) {
    if (m_scanGeneration.load() != generation) {
        return;
    }

    if (m_scanning) {
        m_scanning = false;
        emit scanningChanged();
    }

    m_listModel.setEntries(std::move(entries));
    emit imageCountChanged();
    rebuildOrderPool();

    if (m_listModel.count() == 0 && m_running) {
        stop();
    } else if (m_autoResumePending) {
        m_autoResumePending = false;
        if (m_listModel.count() > 0 && !m_running) {
            m_running = true;
            emit runningChanged();

            const qint64 totalMs = static_cast<qint64>(m_intervalSeconds) * 1000;
            const auto &entries = m_listModel.entries();
            const bool currentInFolder = std::any_of(entries.begin(), entries.end(),
                [this](const WallpaperEntry &e) {
                    return e.filePath.compare(m_currentImagePath, Qt::CaseInsensitive) == 0;
                });

            if (currentInFolder && m_savedRemainingMs > 0 && m_savedRemainingMs <= totalMs) {
                resumeSwitchTimer(m_savedRemainingMs);
            } else {
                restartSwitchTimer();
            }
            m_savedRemainingMs = -1;
        }
    }
}

void WallpaperChannel::rebuildOrderPool() {
    const int n = m_listModel.count();
    m_shuffleBag.clear();
    m_shuffleCursor = 0;
    m_sequentialCursor = -1;

    if (n <= 0) {
        return;
    }

    const auto &entries = m_listModel.entries();
    int currentIdx = -1;
    for (int i = 0; i < n; ++i) {
        if (entries.at(i).filePath.compare(m_currentImagePath, Qt::CaseInsensitive) == 0) {
            currentIdx = i;
            break;
        }
    }
    m_sequentialCursor = currentIdx;

    if (m_switchOrder == SwitchOrder::Random) {
        m_shuffleBag.resize(n);
        for (int i = 0; i < n; ++i) {
            m_shuffleBag[i] = i;
        }
        auto *rng = QRandomGenerator::global();
        for (int i = n - 1; i > 0; --i) {
            const int j = rng->bounded(i + 1);
            std::swap(m_shuffleBag[i], m_shuffleBag[j]);
        }
        // Avoid immediately repeating the currently displayed wallpaper on the first pick
        if (n > 1 && currentIdx >= 0 && m_shuffleBag[0] == currentIdx) {
            std::swap(m_shuffleBag[0], m_shuffleBag[n - 1]);
        }
    }
}

QString WallpaperChannel::pickNextImagePath() {
    const int n = m_listModel.count();
    if (n == 0) {
        return {};
    }
    const auto &entries = m_listModel.entries();
    if (n == 1) {
        return entries.at(0).filePath;
    }

    if (m_switchOrder == SwitchOrder::Random) {
        if (m_shuffleBag.size() != n || m_shuffleCursor >= m_shuffleBag.size()) {
            rebuildOrderPool();
        }
        const int idx = m_shuffleBag.at(m_shuffleCursor++);
        return entries.at(idx).filePath;
    }

    // Sequential (FileNameAsc, FileNameDesc, ModifiedDesc are already sorted in m_listModel)
    m_sequentialCursor = (m_sequentialCursor + 1) % n;
    return entries.at(m_sequentialCursor).filePath;
}

void WallpaperChannel::applyImageInternal(const QString &filePath, bool recordHistory,
                                          bool resetTimer, bool silentToast) {
    if (m_applying) {
        return;
    }

    m_applying = true;
    emit applyingChanged();
    setLastError({});

    const ChannelKind kind = m_kind;
    const FitMode fitMode = m_fitMode;
    const QSize screenSize = primaryScreenPhysicalSize();

    QPointer<WallpaperChannel> self(this);
    QThreadPool::globalInstance()->start([self, filePath, kind, fitMode, screenSize,
                                          recordHistory, resetTimer, silentToast]() {
        bool ok = false;
        QString errMsg;

        if (kind == ChannelKind::Desktop) {
            const QString readyPath = ImageFitRenderer::prepareForDesktop(filePath, &errMsg);
            if (!readyPath.isEmpty()) {
                const auto res = DesktopWallpaperSetter::applyWallpaper(readyPath, fitMode);
                ok = res.success;
                errMsg = res.errorMessage;
            }
        } else {
            const QString readyPath = ImageFitRenderer::prepareForLockScreen(
                filePath, fitMode, screenSize, &errMsg);
            if (!readyPath.isEmpty()) {
                const std::wstring nativeW = QDir::toNativeSeparators(readyPath).toStdWString();
                const auto res = LockScreenSetter::applyLockScreenImage(nativeW);
                ok = res.success;
                errMsg = QString::fromStdWString(res.errorMessage);
            }
        }

        if (!self) return;
        QMetaObject::invokeMethod(self, [self, filePath, ok, errMsg, recordHistory, resetTimer, silentToast]() {
            if (!self) return;
            self->m_applying = false;
            emit self->applyingChanged();

            if (ok) {
                self->m_currentImagePath = filePath;
                self->m_currentImageUrl = WallpaperListModel::makeThumbUrl(filePath);
                self->m_lastSwitchTimeText = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));

                // Sync sequential cursor if user clicked an image directly
                const auto &entries = self->m_listModel.entries();
                for (int i = 0; i < entries.size(); ++i) {
                    if (entries.at(i).filePath.compare(filePath, Qt::CaseInsensitive) == 0) {
                        self->m_sequentialCursor = i;
                        break;
                    }
                }

                if (recordHistory) {
                    if (self->m_historyCursor >= 0 && self->m_historyCursor + 1 < self->m_history.size()) {
                        self->m_history.resize(self->m_historyCursor + 1);
                    }
                    if (self->m_history.isEmpty() || self->m_history.last() != filePath) {
                        self->m_history.append(filePath);
                        if (self->m_history.size() > kMaxHistorySize) {
                            self->m_history.removeFirst();
                        }
                    }
                    self->m_historyCursor = self->m_history.size() - 1;
                }

                emit self->currentImageChanged();
                emit self->lastSwitchTimeChanged();
                emit self->settingsDirty();
                emit self->wallpaperSwitched();

                if (resetTimer && self->m_running) {
                    self->restartSwitchTimer();
                }

                if (!silentToast) {
                    emit self->notificationRequested(
                        QStringLiteral("%1已更换为 %2").arg(self->title(), QFileInfo(filePath).fileName()),
                        false);
                }
            } else {
                self->setLastError(errMsg);
                emit self->notificationRequested(errMsg, true);
            }
        }, Qt::QueuedConnection);
    });
}

void WallpaperChannel::pauseForSleep() {
    if (!m_running || m_pausedForSleep) {
        return;
    }
    m_sleepRemainingMs = currentRemainingMs();
    m_pausedForSleep = true;
    m_switchTimer.stop();
}

void WallpaperChannel::resumeFromSleep() {
    if (!m_pausedForSleep) {
        return;
    }
    m_pausedForSleep = false;
    const qint64 remain = m_sleepRemainingMs;
    m_sleepRemainingMs = -1;

    if (!m_running) {
        return;
    }
    if (remain > 0) {
        resumeSwitchTimer(remain);
    } else {
        restartSwitchTimer();
    }
}

void WallpaperChannel::onSwitchTimerTimeout() {
    if (!m_running || m_pausedForSleep) {
        return;
    }
    if (m_fullscreenCheck && m_fullscreenCheck()) {
        // Fullscreen app or game running -> quietly postpone one cycle
        restartSwitchTimer();
        return;
    }

    const QString nextPath = pickNextImagePath();
    if (!nextPath.isEmpty()) {
        applyImageInternal(nextPath, true, true, true);
    } else {
        stop();
    }
}

void WallpaperChannel::restartSwitchTimer() {
    m_savedRemainingMs = -1;
    m_cycleStartMs = m_clock.elapsed();
    m_switchTimer.start(m_intervalSeconds * 1000);
    refreshCountdownDisplay();
}

void WallpaperChannel::resumeSwitchTimer(qint64 remainingMs) {
    const qint64 totalMs = static_cast<qint64>(m_intervalSeconds) * 1000;
    const qint64 clampedRemain = qBound<qint64>(1000, remainingMs, totalMs);
    const qint64 elapsedMs = totalMs - clampedRemain;
    m_cycleStartMs = m_clock.elapsed() - elapsedMs;
    m_switchTimer.start(static_cast<int>(clampedRemain));
    refreshCountdownDisplay();
}

qint64 WallpaperChannel::currentRemainingMs() const {
    if (!m_running) {
        return -1;
    }
    const qint64 totalMs = static_cast<qint64>(m_intervalSeconds) * 1000;
    const qint64 elapsedMs = m_clock.elapsed() - m_cycleStartMs;
    return qBound<qint64>(0, totalMs - elapsedMs, totalMs);
}

void WallpaperChannel::setLastError(const QString &err) {
    if (m_lastError == err) {
        return;
    }
    m_lastError = err;
    emit lastErrorChanged();
}

} // namespace AuraPaper
