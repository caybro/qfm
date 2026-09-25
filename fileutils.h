#pragma once

#include <QObject>
#include <QUrl>
#include <qqmlintegration.h>

class FileUtils : public QObject
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(QString homePath READ homePath FINAL CONSTANT)
  Q_PROPERTY(QString rootPath READ rootPath FINAL CONSTANT)
  Q_PROPERTY(QString pathSeparator READ pathSeparator FINAL CONSTANT)

 public:
  explicit FileUtils(QObject *parent = nullptr);

  Q_INVOKABLE QString urlToString(const QUrl& url) const;
  Q_INVOKABLE QUrl pathToUrl(const QString& path) const;
  Q_INVOKABLE QString parentDir(const QString& path) const;

 private:
  QString homePath() const;
  QString rootPath() const;
  QString pathSeparator() const;
};
