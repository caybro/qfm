#include "qfmfilesystemmodel.h"

#include <QDebug>
#include <QDirIterator>
#include <QUrl>
#include <QJsonArray>

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
constexpr auto kRoleIsSelected = "isSelected";

constexpr auto isSelectedDataRole = QfmFilesystemModel::Roles::isSelected;

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
  constexpr auto r = "r"_L1, w = "w"_L1, x = "x"_L1, _ = "_"_L1;
  return "u[%1%2%3] g[%4%5%6] a[%7%8%9]"_L1
      .arg(perms.testFlag(QFileDevice::ReadUser) ? r : _, perms.testFlag(QFileDevice::WriteUser) ? w : _, perms.testFlag(QFileDevice::ExeUser) ? x : _,
           perms.testFlag(QFileDevice::ReadGroup) ? r : _, perms.testFlag(QFileDevice::WriteGroup) ? w : _, perms.testFlag(QFileDevice::ExeGroup) ? x : _,
           perms.testFlag(QFileDevice::ReadOther) ? r : _, perms.testFlag(QFileDevice::WriteOther) ? w : _, perms.testFlag(QFileDevice::ExeOther) ? x : _
           );
};
}

QfmFilesystemModel::QfmFilesystemModel(QObject *parent)
    : QAbstractListModel(parent)
{
  connect(this, &QfmFilesystemModel::baseDirChanged, this, &QfmFilesystemModel::fetchDir);
  connect(&m_fsWatcher, &QFileSystemWatcher::directoryChanged, this, &QfmFilesystemModel::fetchDir);
  connect(this, &QfmFilesystemModel::showHiddenFilesChanged, this, &QfmFilesystemModel::fetchDir);
  connect(this, &QfmFilesystemModel::selectedFilesChanged, this, [&]() {
    //const auto sel = selectedFiles();
    //qWarning() << "!!! SELECTED FILES:" << sel.count() << sel;
  });
}

void QfmFilesystemModel::selectAllFiles()
{
  for (auto& entry: m_entries) {
    if (!m_showHiddenFiles && entry.fi.isHidden())
      continue;
    entry.selected = true;
  }
  emit dataChanged(index(0), index(rowCount() - 1), {isSelectedDataRole});
  emit selectedFilesChanged();
}

void QfmFilesystemModel::toggleSelectedFile(int row)
{
  const auto idx = index(row);
  if (!idx.isValid())
    return;

  auto& entry = m_entries[row];
  entry.selected = !entry.selected;
  emit dataChanged(idx, idx, {isSelectedDataRole});
  emit selectedFilesChanged();
}

void QfmFilesystemModel::toggleAllFiles()
{
  for (auto& entry: m_entries) {
    if (!m_showHiddenFiles && entry.fi.isHidden())
      continue;
    entry.selected = !entry.selected;
  }
  emit dataChanged(index(0), index(rowCount() - 1), {isSelectedDataRole});
  emit selectedFilesChanged();
}

void QfmFilesystemModel::clearSelectedFiles()
{
  for (auto& entry: m_entries) {
    entry.selected = false;
  }
  emit dataChanged(index(0), index(rowCount() - 1), {isSelectedDataRole});
  emit selectedFilesChanged();
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

  const auto item = m_entries.at(row);
  const auto entry = item.fi;

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
  case isSelected:
    return item.selected;
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
      {QfmFilesystemModel::Roles::isSelected, kRoleIsSelected},
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
  qDebug() << "!!! ITERATING:" << m_baseDir;
  auto flags = QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot;
  if (m_showHiddenFiles)
    flags |= QDir::Hidden;
  QDirIterator it(m_baseDir, flags);
  while (it.hasNext()) {
    const auto fi = it.nextFileInfo();
    qDebug() << "!!! FOUND:" << it.fileName() << QDir::cleanPath(fi.absoluteFilePath());
    m_entries.emplace_back(fi, false);
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
    [[maybe_unused]] const auto removeResult = m_fsWatcher.removePath(m_baseDir);
    qDebug() << "!!! REMOVED FS WATCHER DIR:" << m_baseDir << "WITH RESULT" << removeResult;
  }
  [[maybe_unused]] const auto addResult = m_fsWatcher.addPath(newDir);
  qDebug() << "!!! ADDED FS WATCHER DIR:" << newDir << "WITH RESULT" << addResult;

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

QJsonObject QfmFilesystemModel::selectedFiles() const
{
  QJsonObject result;
  QJsonArray files;
  qint64 totalBytes{0};
  for (const auto& entry: std::as_const(m_entries)) {
    if (entry.selected) {
      files.append(entry.fi.fileName());
      totalBytes += entry.fi.size();
    }
  }
  result.insert("files"_L1, files);
  result.insert("count"_L1, files.count());
  result.insert("totalBytes"_L1, totalBytes);
  return result;
}

bool QfmFilesystemModel::showHiddenFiles() const
{
  return m_showHiddenFiles;
}

void QfmFilesystemModel::setShowHiddenFiles(bool newShowHiddenFiles)
{
  if (m_showHiddenFiles == newShowHiddenFiles)
    return;
  m_showHiddenFiles = newShowHiddenFiles;
  emit showHiddenFilesChanged();
}
