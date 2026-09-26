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
  Q_PROPERTY(QStringList selectedFiles READ selectedFiles NOTIFY selectedFilesChanged FINAL)

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
    isSelected,
  };
  Q_ENUM(Roles);

  Q_INVOKABLE void addSelectedFile(const QString& fileName);
  Q_INVOKABLE void removeSelectedFile(const QString& fileName);
  Q_INVOKABLE void toggleSelectedFile(const QString& fileName);
  Q_INVOKABLE void clearSelectedFiles();

 signals:
  void baseDirChanged();
  void loadingChanged();
  void selectedFilesChanged(const QStringList& fileNamesChanged);

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

  QSet<QString> m_selectedFiles;
  QStringList selectedFiles() const;
  void updateAndEmitSelected(const QStringList& fileNamesChanged);
};
