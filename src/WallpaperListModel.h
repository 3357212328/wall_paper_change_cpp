#pragma once

#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <QString>
#include <QVector>

namespace AuraPaper {

struct WallpaperEntry {
    QString filePath;
    QString fileName;
    QString thumbUrl;
    QString sizeText;
    qint64 modifiedMs = 0;
};

class WallpaperListModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        FilePathRole = Qt::UserRole + 1,
        FileNameRole,
        ThumbUrlRole,
        SizeTextRole,
        ModifiedMsRole
    };

    explicit WallpaperListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setEntries(QVector<WallpaperEntry> entries);
    const QVector<WallpaperEntry> &entries() const { return m_entries; }
    int count() const { return m_entries.size(); }

    static QString makeThumbUrl(const QString &filePath);

private:
    QVector<WallpaperEntry> m_entries;
};

class WallpaperFilterModel : public QSortFilterProxyModel {
    Q_OBJECT
public:
    explicit WallpaperFilterModel(QObject *parent = nullptr);

    void setSearchQuery(const QString &query);
    QString searchQuery() const { return m_query; }

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_query;
};

} // namespace AuraPaper
