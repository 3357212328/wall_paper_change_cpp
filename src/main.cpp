#include "AppController.h"
#include "ThumbnailImageProvider.h"

#include <QFont>
#include <QGuiApplication>
#include <QIcon>
#include <QImageReader>
#include <QLocalServer>
#include <QLocalSocket>
#include <QPixmapCache>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStringList>

int main(int argc, char *argv[]) {
    QCoreApplication::setOrganizationName(QStringLiteral("AuraPaper"));
    QCoreApplication::setApplicationName(QStringLiteral("AuraPaper"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0.4"));

    // Allow decoding ultra-high-res / 200MB+ wallpapers (Qt 6 defaults to 128 MB)
    QImageReader::setAllocationLimit(0);

    // Keep Qt Quick texture/pixmap memory footprint tightly bounded
    QPixmapCache::setCacheLimit(16384); // 16 MB

    QGuiApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
    app.setWindowIcon(QIcon(QStringLiteral(":/AuraPaper/resources/icons/app_icon.png")));

    // Crisp modern Chinese + Latin UI typography
    QFont defaultFont(QStringLiteral("Microsoft YaHei UI"));
    defaultFont.setPointSize(10);
    app.setFont(defaultFont);

    // Single-instance check via local IPC socket
    const QString serverName = QStringLiteral("AuraPaper_SingleInstance_v1");
    {
        QLocalSocket probe;
        probe.connectToServer(serverName, QIODevice::WriteOnly);
        if (probe.waitForConnected(250)) {
            probe.write("SHOW");
            probe.flush();
            probe.waitForBytesWritten(250);
            probe.disconnectFromServer();
            return 0;
        }
    }

    QLocalServer ipcServer;
    QLocalServer::removeServer(serverName);
    ipcServer.listen(serverName);

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const QStringList args = app.arguments();
    const bool startMinimizedFlag = args.contains(QStringLiteral("--minimized"));

    AuraPaper::AppController controller;
    controller.setupSystemTray();

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("thumb"), new AuraPaper::ThumbnailImageProvider());
    engine.rootContext()->setContextProperty(QStringLiteral("appController"), &controller);
    engine.rootContext()->setContextProperty(QStringLiteral("startMinimizedArg"), startMinimizedFlag);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("AuraPaper"), QStringLiteral("Main"));
    engine.loadFromModule(QStringLiteral("AuraPaper"), QStringLiteral("TrayMenuPopup"));
    engine.loadFromModule(QStringLiteral("AuraPaper"), QStringLiteral("TrayBalloonPopup"));

    const auto roots = engine.rootObjects();
    if (!roots.isEmpty()) {
        if (auto *win = qobject_cast<QQuickWindow *>(roots.at(0))) {
            controller.attachWindow(win, &engine);
            if (startMinimizedFlag) {
                controller.hideToTray(false);
            } else {
                controller.onWindowVisibilityChanged(true);
            }
        }
        if (roots.size() > 1) {
            if (auto *trayWin = qobject_cast<QQuickWindow *>(roots.at(1))) {
                controller.registerTrayPopup(trayWin);
            }
        }
        if (roots.size() > 2) {
            if (auto *balloonWin = qobject_cast<QQuickWindow *>(roots.at(2))) {
                controller.registerTrayBalloon(balloonWin);
            }
        }
    }

    QObject::connect(&ipcServer, &QLocalServer::newConnection, &controller, [&]() {
        while (QLocalSocket *client = ipcServer.nextPendingConnection()) {
            QObject::connect(client, &QLocalSocket::readyRead, client, [client, &controller]() {
                const QByteArray msg = client->readAll();
                if (msg.contains("SHOW")) {
                    controller.showMainWindow();
                }
                client->disconnectFromServer();
                client->deleteLater();
            });
        }
    });

    return app.exec();
}
