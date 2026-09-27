#pragma once

#include <QAbstractListModel>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <qqmlintegration.h>

struct FileEntry {
  QFileInfo fi;
  bool selected{false};
};

class QfmFilesystemModel : public QAbstractListModel
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(QString baseDir READ baseDir WRITE setBaseDir NOTIFY baseDirChanged FINAL)
  Q_PROPERTY(bool showHiddenFiles READ showHiddenFiles WRITE setShowHiddenFiles NOTIFY showHiddenFilesChanged FINAL)
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

  Q_INVOKABLE void selectAllFiles();
  Q_INVOKABLE void toggleSelectedFile(int row);
  Q_INVOKABLE void toggleAllFiles();
  Q_INVOKABLE void clearSelectedFiles();

 signals:
  void baseDirChanged();
  void loadingChanged();
  void selectedFilesChanged();
  void showHiddenFilesChanged();

 protected:
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

 private:
  QList<FileEntry> m_entries;
  void fetchDir();

  QString m_baseDir;
  QString baseDir() const;
  void setBaseDir(const QString &newBaseDir);

  QFileSystemWatcher m_fsWatcher;

  bool m_loading{false};
  bool loading() const;
  void setLoading(bool newLoading);

  QStringList selectedFiles() const;

  bool m_showHiddenFiles{false};
  bool showHiddenFiles() const;
  void setShowHiddenFiles(bool newShowHiddenFiles);
};
