#pragma once

#include <QAbstractListModel>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <qqmlintegration.h>

class QfmFilesystemModel : public QAbstractListModel
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(QString baseDir READ baseDir WRITE setBaseDir NOTIFY baseDirChanged FINAL)
  Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged FINAL)

 public:
  QfmFilesystemModel(QObject *parent = nullptr);

  enum Roles {
    fileName = Qt::DisplayRole,
    filePath = Qt::UserRole + 1,// including fileName
    path, // excluding fileName
    url,
    iconSource,
    baseName,
    suffix,
    size,
    modified,
    accessed,
    isDir,
    isSymlink,
    symlinkTarget,
    isReadable,
    isExecutable,
    isHidden,
    permissionsString,
  };
  Q_ENUM(Roles);

 signals:
  void baseDirChanged();
  void loadingChanged();

 protected:
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

 private:
  QList<QFileInfo> m_entries;
  void fetchDir();

  QString m_baseDir;
  QString baseDir() const;
  void setBaseDir(const QString &newBaseDir);

  QFileSystemWatcher m_fsWatcher;

  bool m_loading{false};
  bool loading() const;
  void setLoading(bool newLoading);
};
