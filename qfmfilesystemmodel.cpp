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
constexpr auto kRoleSymlinkTarget = "symlinkTarget";
constexpr auto kRoleIsReadable = "isReadable";
constexpr auto kRoleIsExecutable = "isExecutable";
constexpr auto kRoleIsHidden = "isHidden";
constexpr auto kRolePermissionsString = "permissionsString";

auto entryIcon(const QFileInfo& entry) {
  if (entry.isDir()) {
    if (!entry.isReadable())
      return "/qt/qml/QfmCore/icons/folder_limited.svg"_L1;
    if (entry.isSymLink())
      return "/qt/qml/QfmCore/icons/folder_link.svg"_L1;
    return "/qt/qml/QfmCore/icons/folder.svg"_L1;
  } else if (entry.isFile()) {
    if (entry.isExecutable())
      return "/qt/qml/QfmCore/icons/file_exec.svg"_L1;
    if (entry.isSymLink())
      return "/qt/qml/QfmCore/icons/file_link.svg"_L1;
    return "/qt/qml/QfmCore/icons/file.svg"_L1;
  }
  if (entry.isSymLink())
    return "/qt/qml/QfmCore/icons/file_link.svg"_L1;

  return "/qt/qml/QfmCore/icons/file_other.svg"_L1;
}

constexpr auto permissionsToString = [](QFile::Permissions perms) {
  return QLatin1StringView("u[%1%2%3] g[%4%5%6] a[%7%8%9]")
      .arg(perms.testFlag(QFileDevice::ReadUser) ? "r" : "_", perms.testFlag(QFileDevice::WriteUser) ? "w" : "_", perms.testFlag(QFileDevice::ExeUser) ? "x" : "_",
           perms.testFlag(QFileDevice::ReadGroup) ? "r" : "_", perms.testFlag(QFileDevice::WriteGroup) ? "w" : "_", perms.testFlag(QFileDevice::ExeGroup) ? "x" : "_",
           perms.testFlag(QFileDevice::ReadOther) ? "r" : "_", perms.testFlag(QFileDevice::WriteOther) ? "w" : "_", perms.testFlag(QFileDevice::ExeOther) ? "x" : "_"
           );
};
}

QfmFilesystemModel::QfmFilesystemModel(QObject *parent)
    : QAbstractListModel(parent)
{
  connect(this, &QfmFilesystemModel::baseDirChanged, this, &QfmFilesystemModel::fetchDir);
  connect(&m_fsWatcher, &QFileSystemWatcher::directoryChanged, this, &QfmFilesystemModel::fetchDir);
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
    return entry.absoluteFilePath();
  case path:
    return QDir::cleanPath(entry.absolutePath());
  case url:
    return QUrl::fromLocalFile(entry.canonicalFilePath());
  case iconSource:
    return entryIcon(entry);
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
  case symlinkTarget:
    return entry.isSymLink() && entry.exists() ? entry.symLinkTarget()
                                               : "N/A"_L1;
  case isReadable:
    return entry.isReadable();
  case isExecutable:
    return entry.isExecutable();
  case isHidden:
    return entry.isHidden();
  case permissionsString:
    return permissionsToString(entry.permissions());
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
      {QfmFilesystemModel::Roles::symlinkTarget, kRoleSymlinkTarget},
      {QfmFilesystemModel::Roles::isReadable, kRoleIsReadable},
      {QfmFilesystemModel::Roles::isExecutable, kRoleIsExecutable},
      {QfmFilesystemModel::Roles::isHidden, kRoleIsHidden},
      {QfmFilesystemModel::Roles::permissionsString, kRolePermissionsString},
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
  QDirIterator it(m_baseDir, QDir::Files | QDir::Dirs | QDir::Hidden | QDir::NoDotAndDotDot);
  while (it.hasNext()) {
    const auto fi = it.nextFileInfo();
    //qWarning() << "!!! FOUND:" << it.fileName() << QDir::cleanPath(fi.absoluteFilePath());
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
  if (newBaseDir.isEmpty())
    return;

  if (m_baseDir == newBaseDir)
    return;

  const auto newDir = QDir::cleanPath(newBaseDir);

  if (m_fsWatcher.directories().contains(m_baseDir)) {
    const auto removeResult = m_fsWatcher.removePath(m_baseDir);
    qWarning() << "!!! REMOVED FS WATCHER DIR:" << m_baseDir << "WITH RESULT" << removeResult;
  }
  const auto addResult = m_fsWatcher.addPath(newDir);
  qWarning() << "!!! ADDED FS WATCHER DIR:" << newDir << "WITH RESULT" << addResult;

  m_baseDir = newDir;
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
