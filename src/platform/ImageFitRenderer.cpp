#include "ImageFitRenderer.h"

#include <QColor>
#include <QDir>
#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QPainter>
#include <QStandardPaths>

#include <atomic>

namespace AuraPaper {

namespace {

std::atomic<int> g_lockSlot{0};
std::atomic<int> g_deskSlot{0};

QColor computeAmbientDarkColor(const QImage &src) {
    // Downsample to 1x1 to get average tone cheaply
    QImage tiny = src.scaled(1, 1, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    if (tiny.isNull()) {
        return QColor(12, 15, 22);
    }
    QColor avg = tiny.pixelColor(0, 0);
    // Keep it refined and dark so lock screen clock remains high contrast
    int h = 0, s = 0, l = 0;
    avg.getHsl(&h, &s, &l);
    return QColor::fromHsl(h, qMin(s, 75), qBound(10, l / 4, 26));
}

QSize clampRenderSize(const QSize &rawSize) {
    QSize sz = rawSize.isValid() && !rawSize.isEmpty() ? rawSize : QSize(1920, 1080);
    constexpr int kMaxW = 3840;
    constexpr int kMaxH = 2160;
    if (sz.width() > kMaxW || sz.height() > kMaxH) {
        sz = sz.scaled(kMaxW, kMaxH, Qt::KeepAspectRatio);
    }
    return sz;
}

} // namespace

QString ImageFitRenderer::cacheDirectory() {
    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)
                      + QStringLiteral("/cache");
    QDir().mkpath(dirPath);
    return dirPath;
}

bool ImageFitRenderer::isNativelySupportedFormat(const QString &filePath) {
    const QString ext = QFileInfo(filePath).suffix().toLower();
    return ext == QLatin1String("jpg") || ext == QLatin1String("jpeg")
           || ext == QLatin1String("png") || ext == QLatin1String("bmp")
           || ext == QLatin1String("jfif") || ext == QLatin1String("dib");
}

QString ImageFitRenderer::prepareForDesktop(const QString &sourcePath, QString *errorOut) {
    if (isNativelySupportedFormat(sourcePath)) {
        return sourcePath;
    }

    QImageReader reader(sourcePath);
    reader.setAutoTransform(true);
    QImage img = reader.read();
    if (img.isNull()) {
        if (errorOut) {
            *errorOut = QStringLiteral("无法解码图片: %1").arg(reader.errorString());
        }
        return {};
    }

    const int slot = g_deskSlot.fetch_add(1) % 2;
    const QString outPath = cacheDirectory() + QStringLiteral("/desktop_converted_%1.jpg").arg(slot);
    if (!img.save(outPath, "JPG", 94)) {
        if (errorOut) {
            *errorOut = QStringLiteral("保存转换后的桌面壁纸缓存失败");
        }
        return {};
    }
    return outPath;
}

QString ImageFitRenderer::prepareForLockScreen(const QString &sourcePath, FitMode fitMode,
                                               const QSize &targetScreenSize, QString *errorOut) {
    if (fitMode == FitMode::Fill && isNativelySupportedFormat(sourcePath)) {
        return sourcePath;
    }

    const QSize canvasSize = clampRenderSize(targetScreenSize);

    QImageReader reader(sourcePath);
    reader.setAutoTransform(true);

    // Pre-scale during decode if source is much larger than target to minimize peak RAM
    const QSize srcSize = reader.size();
    if (srcSize.isValid() && fitMode != FitMode::Tile && fitMode != FitMode::Center) {
        if (srcSize.width() > canvasSize.width() * 2 || srcSize.height() > canvasSize.height() * 2) {
            QSize preScale = srcSize.scaled(canvasSize * 2, Qt::KeepAspectRatio);
            reader.setScaledSize(preScale);
        }
    }

    QImage src = reader.read();
    if (src.isNull()) {
        if (errorOut) {
            *errorOut = QStringLiteral("无法读取锁屏壁纸: %1").arg(reader.errorString());
        }
        return {};
    }

    QImage canvas(canvasSize, QImage::Format_RGB32);
    canvas.fill(computeAmbientDarkColor(src));

    QPainter painter(&canvas);
    painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
    painter.setRenderHint(QPainter::Antialiasing, true);

    switch (fitMode) {
    case FitMode::Fill:
    case FitMode::Span: {
        QSize scaled = src.size().scaled(canvasSize, Qt::KeepAspectRatioByExpanding);
        QRect targetRect((canvasSize.width() - scaled.width()) / 2,
                         (canvasSize.height() - scaled.height()) / 2,
                         scaled.width(), scaled.height());
        painter.drawImage(targetRect, src);
        break;
    }
    case FitMode::Fit: {
        QSize scaled = src.size().scaled(canvasSize, Qt::KeepAspectRatio);
        QRect targetRect((canvasSize.width() - scaled.width()) / 2,
                         (canvasSize.height() - scaled.height()) / 2,
                         scaled.width(), scaled.height());
        painter.drawImage(targetRect, src);
        break;
    }
    case FitMode::Stretch: {
        painter.drawImage(QRect(QPoint(0, 0), canvasSize), src);
        break;
    }
    case FitMode::Center: {
        QPoint topLeft((canvasSize.width() - src.width()) / 2,
                       (canvasSize.height() - src.height()) / 2);
        painter.drawImage(topLeft, src);
        break;
    }
    case FitMode::Tile: {
        for (int y = 0; y < canvasSize.height(); y += src.height()) {
            for (int x = 0; x < canvasSize.width(); x += src.width()) {
                painter.drawImage(x, y, src);
            }
        }
        break;
    }
    }

    painter.end();

    const int slot = g_lockSlot.fetch_add(1) % 2;
    const QString outPath = cacheDirectory() + QStringLiteral("/lockscreen_rendered_%1.jpg").arg(slot);
    if (!canvas.save(outPath, "JPG", 92)) {
        if (errorOut) {
            *errorOut = QStringLiteral("保存锁屏渲染缓存失败");
        }
        return {};
    }
    return outPath;
}

} // namespace AuraPaper
