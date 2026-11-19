#pragma once

#include <QQuickAsyncImageProvider>
#include <QThreadPool>

namespace AuraPaper {

class ThumbnailImageProvider : public QQuickAsyncImageProvider {
public:
    ThumbnailImageProvider();
    ~ThumbnailImageProvider() override;

    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

private:
    QThreadPool m_pool;
};

} // namespace AuraPaper
