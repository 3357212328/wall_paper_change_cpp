#pragma once

#include "WallpaperListModel.h"
#include "platform/WallpaperTypes.h"

#include <QElapsedTimer>
#include <QFileSystemWatcher>
#include <QObject>
#include <QSettings>
#include <QStringList>
#include <QTimer>
#include <QUrl>

#include <atomic>
#include <functional>

namespace AuraPaper {

class WallpaperChannel : public QObject {
    Q_OBJECT

    Q_PROPERTY(int kind READ kindInt CONSTANT)
    Q_PROPERTY(QString title READ title CONSTANT)
    Q_PROPERTY(QString folderPath READ folderPath WRITE setFolderPath NOTIFY folderPathChanged)
    Q_PROPERTY(bool includeSubfolders READ includeSubfolders WRITE setIncludeSubfolders NOTIFY includeSubfoldersChanged)
    Q_PROPERTY(int intervalSeconds READ intervalSeconds WRITE setIntervalSeconds NOTIFY intervalSecondsChanged)
    Q_PROPERTY(int switchOrder READ switchOrderInt WRITE setSwitchOrderInt NOTIFY switchOrderChanged)
    Q_PROPERTY(int fitMode READ fitModeInt WRITE setFitModeInt NOTIFY fitModeChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(bool applying READ applying NOTIFY applyingChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(int imageCount READ imageCount NOTIFY imageCountChanged)
    Q_PROPERTY(QString currentImagePath READ currentImagePath NOTIFY currentImageChanged)
    Q_PROPERTY(QString currentImageName READ currentImageName NOTIFY currentImageChanged)
    Q_PROPERTY(QString currentImageUrl READ currentImageUrl NOTIFY currentImageChanged)
    Q_PROPERTY(int remainingSeconds READ remainingSeconds NOTIFY countdownChanged)
    Q_PROPERTY(double progress READ progress NOTIFY countdownChanged)
    Q_PROPERTY(QString lastSwitchTimeText READ lastSwitchTimeText NOTIFY lastSwitchTimeChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(QAbstractItemModel *galleryModel READ galleryModel CONSTANT)

public:
    explicit WallpaperChannel(ChannelKind kind, QObject *parent = nullptr);
    ~WallpaperChannel() override;

    void setFullscreenCheckCallback(std::function<bool()> callback);

    void loadSettings(QSettings &settings);
    void saveSettings(QSettings &settings) const;

    ChannelKind kind() const { return m_kind; }
    int kindInt() const { return static_cast<int>(m_kind); }
    QString title() const;

    QString folderPath() const { return m_folderPath; }
    void setFolderPath(const QString &path);

    bool includeSubfolders() const { return m_includeSubfolders; }
    void setIncludeSubfolders(bool include);

    int intervalSeconds() const { return m_intervalSeconds; }
    void setIntervalSeconds(int seconds);

    SwitchOrder switchOrder() const { return m_switchOrder; }
    int switchOrderInt() const { return static_cast<int>(m_switchOrder); }
    void setSwitchOrderInt(int order);

    FitMode fitMode() const { return m_fitMode; }
    int fitModeInt() const { return static_cast<int>(m_fitMode); }
    void setFitModeInt(int mode);

    bool running() const { return m_running; }
    bool applying() const { return m_applying; }
    bool scanning() const { return m_scanning; }
    int imageCount() const { return m_listModel.count(); }

    QString currentImagePath() const { return m_currentImagePath; }
    QString currentImageName() const;
    QString currentImageUrl() const { return m_currentImageUrl; }

    int remainingSeconds() const { return m_remainingSeconds; }
    double progress() const { return m_progress; }
    QString lastSwitchTimeText() const { return m_lastSwitchTimeText; }
    QString lastError() const { return m_lastError; }

    QString searchText() const { return m_filterModel.searchQuery(); }
    void setSearchText(const QString &text);

    QAbstractItemModel *galleryModel() { return &m_filterModel; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void toggleRunning();
    Q_INVOKABLE void nextWallpaper();
    Q_INVOKABLE void previousWallpaper();
    Q_INVOKABLE void applyImage(const QString &filePath);
    Q_INVOKABLE void refreshFolder();
    Q_INVOKABLE void browseFolder();
    Q_INVOKABLE void setFolderFromUrl(const QUrl &url);
    Q_INVOKABLE void useSystemDefaultFolder();
    Q_INVOKABLE void openFolder() const;
    Q_INVOKABLE void revealCurrentImage() const;
    Q_INVOKABLE void revealImage(const QString &filePath) const;

    void refreshCountdownDisplay();

signals:
    void folderPathChanged();
    void includeSubfoldersChanged();
    void intervalSecondsChanged();
    void switchOrderChanged();
    void fitModeChanged();
    void runningChanged();
    void applyingChanged();
    void scanningChanged();
    void imageCountChanged();
    void currentImageChanged();
    void countdownChanged();
    void lastSwitchTimeChanged();
    void lastErrorChanged();
    void searchTextChanged();
    void settingsDirty();
    void wallpaperSwitched();
    void notificationRequested(const QString &message, bool isError);

private:
    void scheduleFolderScan();
    void handleScanFinished(quint64 generation, QVector<WallpaperEntry> entries);
    void updateFileWatcher();
    void rebuildOrderPool();
    QString pickNextImagePath();
    void applyImageInternal(const QString &filePath, bool recordHistory, bool resetTimer, bool silentToast);
    void onSwitchTimerTimeout();
    void restartSwitchTimer();
    void setLastError(const QString &err);

    ChannelKind m_kind;
    QString m_folderPath;
    bool m_includeSubfolders = true;
    int m_intervalSeconds = 300; // 5 minutes default
    SwitchOrder m_switchOrder = SwitchOrder::FileNameAsc;
    FitMode m_fitMode = FitMode::Fill;

    bool m_running = false;
    bool m_applying = false;
    bool m_scanning = false;
    bool m_autoResumePending = false;

    QString m_currentImagePath;
    QString m_currentImageUrl;
    QString m_lastSwitchTimeText;
    QString m_lastError;

    int m_remainingSeconds = 0;
    double m_progress = 0.0;
    qint64 m_cycleStartMs = 0;
    QElapsedTimer m_clock;

    WallpaperListModel m_listModel;
    WallpaperFilterModel m_filterModel;

    // Ordering & history state
    QVector<int> m_shuffleBag;
    int m_shuffleCursor = 0;
    int m_sequentialCursor = -1;
    QStringList m_history;
    int m_historyCursor = -1;

    QTimer m_switchTimer;
    QTimer m_watcherDebounce;
    QFileSystemWatcher m_watcher;

    std::atomic<quint64> m_scanGeneration{0};
    std::function<bool()> m_fullscreenCheck;
};

} // namespace AuraPaper
