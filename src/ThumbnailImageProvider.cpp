#include "ThumbnailImageProvider.h"

#include <QImage>
#include <QImageReader>
#include <QRunnable>
#include <QUrl>
#include <atomic>

namespace AuraPaper {

namespace {

class ThumbnailResponse : public QQuickImageResponse {
public:
    ThumbnailResponse(const QString &filePath, const QSize &requestedSize, QThreadPool *pool)
        : m_filePath(filePath), m_requestedSize(requestedSize) {
        auto *task = new DecodeTask(this);
        task->setAutoDelete(true);
        pool->start(task, -1); // Low priority so UI stays silky smooth
    }

    QQuickTextureFactory *textureFactory() const override {
        if (m_image.isNull()) {
            return nullptr;
        }
        return QQuickTextureFactory::textureFactoryForImage(m_image);
    }

    QString errorString() const override {
        return m_error;
    }

    void cancel() override {
        m_cancelled.store(true, std::memory_order_relaxed);
    }

private:
    class DecodeTask : public QRunnable {
    public:
        explicit DecodeTask(ThumbnailResponse *response) : m_response(response) {}

        void run() override {
            if (m_response->m_cancelled.load(std::memory_order_relaxed)) {
                QMetaObject::invokeMethod(m_response, &QQuickImageResponse::finished, Qt::QueuedConnection);
                return;
            }

            QImageReader reader(m_response->m_filePath);
            reader.setAutoTransform(true);

            QSize target = m_response->m_requestedSize;
            if (!target.isValid() || target.width() <= 0 || target.height() <= 0) {
                target = QSize(360, 210);
            }
            // Clamp upper bound to prevent accidental multi-megabyte decode in thumbnails
            target.setWidth(qMin(target.width(), 1280));
            target.setHeight(qMin(target.height(), 720));

            const QSize srcSize = reader.size();
            if (srcSize.isValid() && !srcSize.isEmpty()) {
                QSize scaled = srcSize.scaled(target, Qt::KeepAspectRatioByExpanding);
                // Don't upscale tiny images unnecessarily
                if (scaled.width() < srcSize.width() && scaled.height() < srcSize.height()) {
                    reader.setScaledSize(scaled);
                }
            }

            if (m_response->m_cancelled.load(std::memory_order_relaxed)) {
                QMetaObject::invokeMethod(m_response, &QQuickImageResponse::finished, Qt::QueuedConnection);
                return;
            }

            QImage img = reader.read();
            if (img.isNull()) {
                m_response->m_error = reader.errorString();
            } else {
                if (img.width() > target.width() * 2 || img.height() > target.height() * 2) {
                    img = img.scaled(target, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
                }
                if (img.format() != QImage::Format_RGB32 && img.format() != QImage::Format_ARGB32_Premultiplied) {
                    img = img.convertToFormat(QImage::Format_RGB32);
                }
                m_response->m_image = std::move(img);
            }

            QMetaObject::invokeMethod(m_response, &QQuickImageResponse::finished, Qt::QueuedConnection);
        }

    private:
        ThumbnailResponse *m_response;
    };

    QString m_filePath;
    QSize m_requestedSize;
    QImage m_image;
    QString m_error;
    std::atomic_bool m_cancelled{false};
};

} // namespace

ThumbnailImageProvider::ThumbnailImageProvider() {
    m_pool.setMaxThreadCount(2);
    m_pool.setExpiryTimeout(15000);
}

ThumbnailImageProvider::~ThumbnailImageProvider() {
    m_pool.clear();
    m_pool.waitForDone(3000);
}

QQuickImageResponse *ThumbnailImageProvider::requestImageResponse(const QString &id,
                                                                  const QSize &requestedSize) {
    // Strip optional cache-buster query if present
    QString cleanId = id;
    const int queryIdx = cleanId.indexOf(QLatin1Char('?'));
    if (queryIdx >= 0) {
        cleanId = cleanId.left(queryIdx);
    }
    const QString filePath = QUrl::fromPercentEncoding(cleanId.toUtf8());
    return new ThumbnailResponse(filePath, requestedSize, &m_pool);
}

} // namespace AuraPaper
