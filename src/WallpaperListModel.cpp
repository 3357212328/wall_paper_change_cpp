#include "WallpaperListModel.h"

#include <QUrl>

namespace AuraPaper {

WallpaperListModel::WallpaperListModel(QObject *parent)
    : QAbstractListModel(parent) {}

int WallpaperListModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) {
        return 0;
    }
    return m_entries.size();
}

QVariant WallpaperListModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size()) {
        return {};
    }
    const auto &entry = m_entries.at(index.row());
    switch (role) {
    case FilePathRole:   return entry.filePath;
    case FileNameRole:   return entry.fileName;
    case ThumbUrlRole:   return entry.thumbUrl;
    case SizeTextRole:   return entry.sizeText;
    case ModifiedMsRole: return entry.modifiedMs;
    default:             return {};
    }
}

QHash<int, QByteArray> WallpaperListModel::roleNames() const {
    return {
        {FilePathRole,   "filePath"},
        {FileNameRole,   "fileName"},
        {ThumbUrlRole,   "thumbUrl"},
        {SizeTextRole,   "sizeText"},
        {ModifiedMsRole, "modifiedMs"}
    };
}

void WallpaperListModel::setEntries(QVector<WallpaperEntry> entries) {
    beginResetModel();
    m_entries = std::move(entries);
    endResetModel();
}

QString WallpaperListModel::makeThumbUrl(const QString &filePath) {
    if (filePath.isEmpty()) {
        return {};
    }
    return QStringLiteral("image://thumb/")
           + QString::fromUtf8(QUrl::toPercentEncoding(filePath));
}

WallpaperFilterModel::WallpaperFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent) {}

void WallpaperFilterModel::setSearchQuery(const QString &query) {
    const QString trimmed = query.trimmed();
    if (m_query == trimmed) {
        return;
    }
    m_query = trimmed;
    invalidateFilter();
}

bool WallpaperFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const {
    if (m_query.isEmpty()) {
        return true;
    }
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    const QString name = idx.data(WallpaperListModel::FileNameRole).toString();
    return name.contains(m_query, Qt::CaseInsensitive);
}

} // namespace AuraPaper
