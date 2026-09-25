#include "fileutils.h"

#include <QDir>

FileUtils::FileUtils(QObject *parent)
    : QObject{parent}
{}

QString FileUtils::homePath() const
{
  return QDir::homePath();
}

QString FileUtils::rootPath() const
{
  return QDir::rootPath();
}

QString FileUtils::pathSeparator() const
{
  return QDir::separator();
}

QString FileUtils::urlToString(const QUrl &url) const
{
  return QDir::toNativeSeparators(url.toString(QUrl::PreferLocalFile | QUrl::NormalizePathSegments | QUrl::StripTrailingSlash));
}

QUrl FileUtils::pathToUrl(const QString &path) const
{
  return QUrl::fromLocalFile(path);
}
