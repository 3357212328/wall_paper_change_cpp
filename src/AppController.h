#pragma once

#include "WallpaperChannel.h"
#include "platform/NativeSystemTray.h"

#include <QObject>
#include <QPointer>
#include <QSettings>
#include <QTimer>

class QQmlEngine;
class QQuickWindow;

namespace AuraPaper {

class AppController : public QObject {
    Q_OBJECT

    Q_PROPERTY(AuraPaper::WallpaperChannel *desktopChannel READ desktopChannel CONSTANT)
    Q_PROPERTY(AuraPaper::WallpaperChannel *lockScreenChannel READ lockScreenChannel CONSTANT)
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(bool autoStart READ autoStart WRITE setAutoStart NOTIFY autoStartChanged)
    Q_PROPERTY(bool startMinimized READ startMinimized WRITE setStartMinimized NOTIFY startMinimizedChanged)
    Q_PROPERTY(bool minimizeToTrayOnClose READ minimizeToTrayOnClose WRITE setMinimizeToTrayOnClose NOTIFY minimizeToTrayOnCloseChanged)
    Q_PROPERTY(double memoryUsageMB READ memoryUsageMB NOTIFY memoryUsageChanged)
    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)

public:
    explicit AppController(QObject *parent = nullptr);
    ~AppController() override;

    void attachWindow(QQuickWindow *window, QQmlEngine *engine);
    void setupSystemTray();

    WallpaperChannel *desktopChannel() { return &m_desktopChannel; }
    WallpaperChannel *lockScreenChannel() { return &m_lockScreenChannel; }

    bool darkTheme() const { return m_darkTheme; }
    void setDarkTheme(bool dark);
    Q_INVOKABLE void toggleTheme();

    bool autoStart() const { return m_autoStart; }
    void setAutoStart(bool enabled);

    bool startMinimized() const { return m_startMinimized; }
    void setStartMinimized(bool minimized);

    bool minimizeToTrayOnClose() const { return m_minimizeToTrayOnClose; }
    void setMinimizeToTrayOnClose(bool minimize);

    double memoryUsageMB() const { return m_memoryUsageMB; }
    QString appVersion() const { return QStringLiteral("1.0.6"); }

    Q_INVOKABLE void showMainWindow();
    Q_INVOKABLE void hideToTray(bool showBalloonIfFirst = true);
    Q_INVOKABLE void handleCloseRequest();
    Q_INVOKABLE void quitApplication();
    Q_INVOKABLE void trimMemoryNow();
    Q_INVOKABLE void onWindowVisibilityChanged(bool visible);
    Q_INVOKABLE QString formatDuration(int totalSeconds) const;
    Q_INVOKABLE void registerTrayPopup(QQuickWindow *popup);
    Q_INVOKABLE void registerTrayBalloon(QQuickWindow *balloon);
    Q_INVOKABLE void prepareTrayPopupWindow(QQuickWindow *popup);
    Q_INVOKABLE void onTrayPopupClosed();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

signals:
    void darkThemeChanged();
    void autoStartChanged();
    void startMinimizedChanged();
    void minimizeToTrayOnCloseChanged();
    void memoryUsageChanged();
    void toastMessage(const QString &message, bool isError);
    void requestWindowReveal();
    void requestTrayMenu(int x, int y);
    void requestTrayBalloon(int x, int y, const QString &title, const QString &message);

private:
    void loadAllSettings();
    void scheduleSaveSettings();
    void saveAllSettings();
    void updateMemoryUsage();
    void releaseIdleResources();
    void performAutoCacheRelease();

    QSettings m_settings;
    WallpaperChannel m_desktopChannel;
    WallpaperChannel m_lockScreenChannel;

    bool m_darkTheme = true;
    bool m_autoStart = false;
    bool m_startMinimized = true;
    bool m_minimizeToTrayOnClose = true;
    bool m_trayHintShown = false;
    bool m_quitting = false;

    double m_memoryUsageMB = 0.0;
    int m_memTickCounter = 0;

    QPointer<QQuickWindow> m_window;
    QPointer<QQuickWindow> m_trayPopup;
    QPointer<QQuickWindow> m_trayBalloon;
    QPointer<QQmlEngine> m_engine;

    QTimer m_uiTickTimer;
    QTimer m_saveDebounceTimer;
    QTimer m_trimDelayTimer;
    QTimer m_autoCacheTimer;
    QTimer m_checkpointTimer;

    NativeSystemTray *m_trayIcon = nullptr;
};

} // namespace AuraPaper
