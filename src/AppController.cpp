#include "AppController.h"
#include "platform/WindowsUtils.h"

#include <QCursor>
#include <QDir>
#include <QEvent>
#include <QGuiApplication>
#include <QPixmapCache>
#include <QQmlEngine>
#include <QQuickWindow>
#include <QScreen>
#include <QStandardPaths>

namespace AuraPaper {

namespace {

QString configFilePath() {
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(dir);
    return dir + QStringLiteral("/config.ini");
}

} // namespace

AppController::AppController(QObject *parent)
    : QObject(parent),
      m_settings(configFilePath(), QSettings::IniFormat),
      m_desktopChannel(ChannelKind::Desktop, this),
      m_lockScreenChannel(ChannelKind::LockScreen, this) {
    auto fullscreenGuard = [this]() -> bool {
        return m_pauseOnFullscreen && WindowsUtils::isFullscreenAppRunning();
    };
    m_desktopChannel.setFullscreenCheckCallback(fullscreenGuard);
    m_lockScreenChannel.setFullscreenCheckCallback(fullscreenGuard);

    // Debounced config persistence
    m_saveDebounceTimer.setSingleShot(true);
    m_saveDebounceTimer.setInterval(400);
    connect(&m_saveDebounceTimer, &QTimer::timeout, this, &AppController::saveAllSettings);

    // 1-second UI countdown & memory refresh timer (ONLY runs when main window is visible!)
    m_uiTickTimer.setInterval(1000);
    connect(&m_uiTickTimer, &QTimer::timeout, this, [this]() {
        m_desktopChannel.refreshCountdownDisplay();
        m_lockScreenChannel.refreshCountdownDisplay();
        if (++m_memTickCounter >= 2) {
            m_memTickCounter = 0;
            updateMemoryUsage();
        }
    });

    // Delayed resource trim after hiding to tray
    m_trimDelayTimer.setSingleShot(true);
    m_trimDelayTimer.setInterval(800);
    connect(&m_trimDelayTimer, &QTimer::timeout, this, &AppController::releaseIdleResources);

    // Automatic cache release after every wallpaper switch (desktop or lock screen)
    m_autoCacheTimer.setSingleShot(true);
    m_autoCacheTimer.setInterval(650);
    connect(&m_autoCacheTimer, &QTimer::timeout, this, &AppController::performAutoCacheRelease);

    // Wire channel signals
    auto wireChannel = [this](WallpaperChannel *ch) {
        connect(ch, &WallpaperChannel::settingsDirty, this, &AppController::scheduleSaveSettings);
        connect(ch, &WallpaperChannel::wallpaperSwitched, this, [this]() {
            m_autoCacheTimer.start();
        });
        connect(ch, &WallpaperChannel::notificationRequested, this, &AppController::toastMessage);
    };
    wireChannel(&m_desktopChannel);
    wireChannel(&m_lockScreenChannel);

    loadAllSettings();
    updateMemoryUsage();
}

AppController::~AppController() {
    saveAllSettings();
    if (m_trayIcon) {
        m_trayIcon->hide();
    }
}

void AppController::attachWindow(QQuickWindow *window, QQmlEngine *engine) {
    if (m_window) {
        m_window->removeEventFilter(this);
    }
    m_window = window;
    m_engine = engine;
    if (m_window) {
        m_window->installEventFilter(this);
        WindowsUtils::applyWindowVisuals(m_window, m_darkTheme);
    }
}

bool AppController::eventFilter(QObject *watched, QEvent *event) {
    if (watched == m_window && event->type() == QEvent::Close && !m_quitting) {
        if (m_minimizeToTrayOnClose) {
            event->ignore();
            hideToTray(true);
            return true;
        }
        event->ignore();
        quitApplication();
        return true;
    }
    return QObject::eventFilter(watched, event);
}

void AppController::registerTrayPopup(QQuickWindow *popup) {
    m_trayPopup = popup;
}

void AppController::prepareTrayPopupWindow(QQuickWindow *popup) {
    if (!popup) {
        return;
    }
    WindowsUtils::applyWindowVisuals(popup, m_darkTheme);
    WindowsUtils::activatePopupWindow(popup);
}

void AppController::onTrayPopupClosed() {
    if (!m_window || !m_window->isVisible()) {
        m_trimDelayTimer.start();
    }
}

void AppController::setupSystemTray() {
    if (m_trayIcon) {
        return;
    }

    m_trayIcon = new NativeSystemTray(this);
    m_trayIcon->setToolTip(QStringLiteral("AuraPaper 光影壁纸 - 桌面与锁屏智能壁纸引擎"));

    connect(m_trayIcon, &NativeSystemTray::rightClicked, this, [this]() {
        const QPoint cursorPos = QCursor::pos();
        QScreen *screen = QGuiApplication::screenAt(cursorPos);
        if (!screen) {
            screen = QGuiApplication::primaryScreen();
        }
        const QRect avail = screen ? screen->availableGeometry() : QRect(0, 0, 1920, 1080);
        const int menuW = m_trayPopup ? m_trayPopup->width() : 236;
        const int menuH = m_trayPopup ? m_trayPopup->height() : 340;

        int px = cursorPos.x() - menuW / 2;
        int py = cursorPos.y() - menuH - 10;
        if (py < avail.top() + 8) {
            py = cursorPos.y() + 10;
        }
        px = qBound(avail.left() + 8, px, avail.right() - menuW - 8);
        py = qBound(avail.top() + 8, py, avail.bottom() - menuH - 8);

        m_trimDelayTimer.stop();
        emit requestTrayMenu(px, py);
    });

    connect(m_trayIcon, &NativeSystemTray::leftClicked, this, [this]() {
        if (m_trayPopup && m_trayPopup->isVisible()) {
            m_trayPopup->hide();
        }
        if (m_window && m_window->isVisible() && m_window->visibility() != QWindow::Minimized) {
            hideToTray(false);
        } else {
            showMainWindow();
        }
    });

    m_trayIcon->show();
}

void AppController::setDarkTheme(bool dark) {
    if (m_darkTheme == dark) {
        return;
    }
    m_darkTheme = dark;
    emit darkThemeChanged();
    if (m_window) {
        WindowsUtils::applyWindowVisuals(m_window, m_darkTheme);
    }
    scheduleSaveSettings();
}

void AppController::toggleTheme() {
    setDarkTheme(!m_darkTheme);
}

void AppController::setAutoStart(bool enabled) {
    if (m_autoStart == enabled) {
        return;
    }
    if (!WindowsUtils::setAutoStartEnabled(enabled, m_startMinimized)) {
        emit toastMessage(QStringLiteral("修改开机自启动注册表失败，请检查权限"), true);
        return;
    }
    m_autoStart = enabled;
    emit autoStartChanged();
    scheduleSaveSettings();
    emit toastMessage(enabled ? QStringLiteral("已开启开机自启动") : QStringLiteral("已关闭开机自启动"), false);
}

void AppController::setStartMinimized(bool minimized) {
    if (m_startMinimized == minimized) {
        return;
    }
    m_startMinimized = minimized;
    emit startMinimizedChanged();
    if (m_autoStart) {
        WindowsUtils::setAutoStartEnabled(true, m_startMinimized);
    }
    scheduleSaveSettings();
}

void AppController::setMinimizeToTrayOnClose(bool minimize) {
    if (m_minimizeToTrayOnClose == minimize) {
        return;
    }
    m_minimizeToTrayOnClose = minimize;
    emit minimizeToTrayOnCloseChanged();
    scheduleSaveSettings();
}

void AppController::setPauseOnFullscreen(bool pause) {
    if (m_pauseOnFullscreen == pause) {
        return;
    }
    m_pauseOnFullscreen = pause;
    emit pauseOnFullscreenChanged();
    scheduleSaveSettings();
}

void AppController::showMainWindow() {
    m_trimDelayTimer.stop();
    if (!m_window) {
        return;
    }
    m_window->show();
    if (m_window->visibility() == QWindow::Minimized) {
        m_window->showNormal();
    }
    m_window->raise();
    m_window->requestActivate();
    WindowsUtils::applyWindowVisuals(m_window, m_darkTheme);
    emit requestWindowReveal();
}

void AppController::hideToTray(bool showBalloonIfFirst) {
    if (m_trayIcon) {
        m_trayIcon->ensureVisible();
    }
    if (m_window) {
        m_window->hide();
    }
    onWindowVisibilityChanged(false);

    if (showBalloonIfFirst && !m_trayHintShown && m_trayIcon && m_trayIcon->isVisible()) {
        m_trayHintShown = true;
        m_trayIcon->showBalloon(
            QStringLiteral("AuraPaper 光影壁纸"),
            QStringLiteral("程序已最小化到系统托盘并在后台低占用运行，点击托盘图标可随时恢复界面。"));
    }
}

void AppController::handleCloseRequest() {
    if (m_minimizeToTrayOnClose) {
        hideToTray(true);
    } else {
        quitApplication();
    }
}

void AppController::quitApplication() {
    m_quitting = true;
    m_uiTickTimer.stop();
    m_trimDelayTimer.stop();
    m_autoCacheTimer.stop();
    m_saveDebounceTimer.stop();
    saveAllSettings();
    if (m_trayIcon) {
        m_trayIcon->hide();
    }
    if (m_trayPopup) {
        m_trayPopup->hide();
    }
    if (m_window) {
        m_window->hide();
    }
    QCoreApplication::exit(0);
}

void AppController::trimMemoryNow() {
    QPixmapCache::clear();
    if (m_engine) {
        m_engine->collectGarbage();
    }
    WindowsUtils::trimProcessMemory();
    updateMemoryUsage();
    emit toastMessage(
        QStringLiteral("已完成内存整理，当前占用 %1 MB").arg(m_memoryUsageMB, 0, 'f', 1), false);
}

void AppController::onWindowVisibilityChanged(bool visible) {
    if (visible) {
        m_trimDelayTimer.stop();
        m_desktopChannel.refreshCountdownDisplay();
        m_lockScreenChannel.refreshCountdownDisplay();
        updateMemoryUsage();
        if (!m_uiTickTimer.isActive()) {
            m_uiTickTimer.start();
        }
    } else {
        m_uiTickTimer.stop();
        m_trimDelayTimer.start();
    }
}

QString AppController::formatDuration(int totalSeconds) const {
    if (totalSeconds <= 0) {
        return QStringLiteral("00:00");
    }
    const int hours = totalSeconds / 3600;
    const int minutes = (totalSeconds % 3600) / 60;
    const int secs = totalSeconds % 60;
    if (hours > 0) {
        return QStringLiteral("%1:%2:%3")
            .arg(hours, 2, 10, QLatin1Char('0'))
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(secs, 2, 10, QLatin1Char('0'));
    }
    return QStringLiteral("%1:%2")
        .arg(minutes, 2, 10, QLatin1Char('0'))
        .arg(secs, 2, 10, QLatin1Char('0'));
}

void AppController::loadAllSettings() {
    m_settings.beginGroup(QStringLiteral("App"));
    m_darkTheme = m_settings.value(QStringLiteral("darkTheme"), true).toBool();
    m_startMinimized = m_settings.value(QStringLiteral("startMinimized"), true).toBool();
    m_minimizeToTrayOnClose = m_settings.value(QStringLiteral("minimizeToTrayOnClose"), true).toBool();
    m_pauseOnFullscreen = m_settings.value(QStringLiteral("pauseOnFullscreen"), true).toBool();
    m_settings.endGroup();

    // Always trust Windows Registry as source of truth for AutoStart
    m_autoStart = WindowsUtils::isAutoStartEnabled();

    m_desktopChannel.loadSettings(m_settings);
    m_lockScreenChannel.loadSettings(m_settings);
}

void AppController::scheduleSaveSettings() {
    m_saveDebounceTimer.start();
}

void AppController::saveAllSettings() {
    m_settings.beginGroup(QStringLiteral("App"));
    m_settings.setValue(QStringLiteral("darkTheme"), m_darkTheme);
    m_settings.setValue(QStringLiteral("startMinimized"), m_startMinimized);
    m_settings.setValue(QStringLiteral("minimizeToTrayOnClose"), m_minimizeToTrayOnClose);
    m_settings.setValue(QStringLiteral("pauseOnFullscreen"), m_pauseOnFullscreen);
    m_settings.endGroup();

    m_desktopChannel.saveSettings(m_settings);
    m_lockScreenChannel.saveSettings(m_settings);
    m_settings.sync();
}

void AppController::updateMemoryUsage() {
    const double mb = WindowsUtils::getProcessWorkingSetMB();
    if (qAbs(mb - m_memoryUsageMB) >= 0.1) {
        m_memoryUsageMB = mb;
        emit memoryUsageChanged();
    }
}

void AppController::releaseIdleResources() {
    // Only release GPU/scenegraph resources when window is truly hidden
    if (m_window && !m_window->isVisible()) {
        m_window->releaseResources();
    }
    if (m_trayPopup && !m_trayPopup->isVisible()) {
        m_trayPopup->releaseResources();
    }
    QPixmapCache::clear();
    if (m_engine) {
        m_engine->collectGarbage();
    }
    WindowsUtils::trimProcessMemory();
}

void AppController::performAutoCacheRelease() {
    QPixmapCache::clear();
    if (m_engine) {
        m_engine->collectGarbage();
    }
    if (m_window && !m_window->isVisible()) {
        m_window->releaseResources();
    }
    WindowsUtils::trimProcessMemory();
    if (m_window && m_window->isVisible()) {
        updateMemoryUsage();
    }
}

} // namespace AuraPaper
