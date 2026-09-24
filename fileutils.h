#pragma once

#include <QObject>
#include <QUrl>
#include <qqmlintegration.h>

class FileUtils : public QObject
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
 public:
  explicit FileUtils(QObject *parent = nullptr);

  // TODO make these props
  Q_INVOKABLE QString homePath() const;
  Q_INVOKABLE QUrl homePathUrl() const;
  Q_INVOKABLE QString rootPath() const;
  Q_INVOKABLE QString pathSeparator() const;

  Q_INVOKABLE QString urlToString(const QUrl& url) const;
  Q_INVOKABLE QUrl pathToUrl(const QString& path) const;
};
