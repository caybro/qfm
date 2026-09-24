#include "qfmfilesystemmodel.h"

#include <QDebug>
#include <QDirIterator>
#include <QUrl>

using namespace Qt::Literals::StringLiterals;

namespace {
constexpr auto kRoleFileName = "fileName";
constexpr auto kRoleFilePath = "filePath"; // including fileName
constexpr auto kRolePath = "path"; // excluding fileName
constexpr auto kRoleUrl = "url";
constexpr auto kRoleIconSource = "iconSource";
constexpr auto kRoleBaseName = "baseName";
constexpr auto kRoleSuffix = "suffix";
constexpr auto kRoleSize = "size";
constexpr auto kRoleModified = "modified";
constexpr auto kRoleAccessed = "accessed";
constexpr auto kRoleIsDir = "isDir";
constexpr auto kRoleIsSymlink = "isSymlink";
}

QfmFilesystemModel::QfmFilesystemModel(QObject *parent)
    : QAbstractListModel(parent)
{
  connect(this, &QfmFilesystemModel::baseDirChanged, this, &QfmFilesystemModel::fetchDir);
}

QVariant QfmFilesystemModel::get(int row, Roles role) const
{
  return index(row).data(role);
}

int QfmFilesystemModel::rowCount(const QModelIndex &parent) const
{
  return m_entries.size();
}

QVariant QfmFilesystemModel::data(const QModelIndex &index, int role) const
{
  const auto row = index.row();
  if (row < 0 || row >= rowCount())
    return {};

  const auto entry = m_entries.at(row);

  switch (static_cast<QfmFilesystemModel::Roles>(role)) {
  case fileName:
    return entry.fileName();
  case filePath:
    return entry.canonicalFilePath();
  case path:
    return entry.canonicalPath();
  case url:
    return QUrl::fromLocalFile(entry.canonicalFilePath());
  case iconSource: {
    if (entry.isSymLink()) {
      if (entry.isDir())
        return "icons/folder_link.svg"_L1;
      return "icons/file_link.svg"_L1;
    }
    if (entry.isDir())
      return "icons/folder.svg"_L1;
    return "icons/file.svg"_L1;
  }
  case baseName:
    return entry.baseName();
  case suffix:
    return entry.suffix();
  case size:
    return entry.size();
  case modified:
    return qMax(entry.lastModified(), entry.metadataChangeTime());
  case accessed:
    return entry.lastRead();
  case isDir:
    return entry.isDir();
  case isSymlink:
    return entry.isSymLink();
  }

  return {};
}

QHash<int, QByteArray> QfmFilesystemModel::roleNames() const
{
  static const QHash<int, QByteArray> roles{
      {QfmFilesystemModel::Roles::fileName, kRoleFileName},
      {QfmFilesystemModel::Roles::filePath, kRoleFilePath}, // including fileName
      {QfmFilesystemModel::Roles::path, kRolePath}, // excluding fileName
      {QfmFilesystemModel::Roles::url, kRoleUrl},
      {QfmFilesystemModel::Roles::iconSource, kRoleIconSource},
      {QfmFilesystemModel::Roles::baseName, kRoleBaseName},
      {QfmFilesystemModel::Roles::suffix, kRoleSuffix},
      {QfmFilesystemModel::Roles::size, kRoleSize},
      {QfmFilesystemModel::Roles::modified, kRoleModified},
      {QfmFilesystemModel::Roles::accessed, kRoleAccessed},
      {QfmFilesystemModel::Roles::isDir, kRoleIsDir},
      {QfmFilesystemModel::Roles::isSymlink, kRoleIsSymlink},
  };
  return roles;
}

void QfmFilesystemModel::fetchDir()
{
  if (m_baseDir.isEmpty()) {
    qWarning() << Q_FUNC_INFO << "baseDir empty... can't construct model";
    return;
  }

  setLoading(true);
  beginResetModel();

  m_entries.clear();
  //qWarning() << "!!! ITERATING:" << m_baseDir;
  QDirIterator it(m_baseDir, QDir::Files | QDir::Dirs | QDir::Hidden | QDir::NoDot);
  while (it.hasNext()) {
    const auto fi = it.nextFileInfo();
    //qWarning() << "!!! FOUND:" << it.fileName() << fi.canonicalFilePath();
    m_entries.append(fi);
  }

  endResetModel();
  setLoading(false);
}

QString QfmFilesystemModel::baseDir() const
{
  return m_baseDir;
}

void QfmFilesystemModel::setBaseDir(const QString &newBaseDir)
{
  if (m_baseDir == newBaseDir)
    return;
  m_baseDir = newBaseDir;
  emit baseDirChanged();
}

bool QfmFilesystemModel::loading() const
{
  return m_loading;
}

void QfmFilesystemModel::setLoading(bool newLoading)
{
  if (m_loading == newLoading)
    return;
  m_loading = newLoading;
  emit loadingChanged();
}
