#pragma once

#include <QObject>
#include <QString>

namespace AuraPaper {

class NativeSystemTray : public QObject {
    Q_OBJECT
public:
    explicit NativeSystemTray(QObject *parent = nullptr);
    ~NativeSystemTray() override;

    void setToolTip(const QString &tip);
    void show();
    void ensureVisible();
    void hide();
    bool isVisible() const { return m_visible; }
    void showBalloon(const QString &title, const QString &message);

signals:
    void leftClicked();
    void rightClicked();

private:
    void createMessageWindow();
    void addIcon();
    void removeIcon();
    static long long __stdcall wndProc(void *hwnd, unsigned int msg,
                                       unsigned long long wParam, long long lParam);

    void *m_hwnd = nullptr;
    void *m_hIcon = nullptr;
    unsigned int m_taskbarCreatedMsg = 0;
    QString m_toolTip;
    bool m_visible = false;
};

} // namespace AuraPaper
