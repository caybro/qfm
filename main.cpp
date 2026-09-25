#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>

using namespace Qt::Literals::StringLiterals;

int main(int argc, char *argv[])
{
  QGuiApplication::setDesktopSettingsAware(false); // ignore single click to activate

  QGuiApplication app(argc, argv);
  QGuiApplication::setOrganizationName("caybro"_L1);
  QGuiApplication::setApplicationName("qfm"_L1);
  QGuiApplication::setApplicationDisplayName("Quick File Manager"_L1);
  QGuiApplication::setApplicationVersion(APP_VERSION);
  QGuiApplication::setWindowIcon(QIcon(":/qt/qml/QfmCore/icons/qfm.svg"_L1));
  //QGuiApplication::setDesktopFileName("qfm"_L1); // TODO

  QQmlApplicationEngine engine;
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() { QCoreApplication::exit(EXIT_FAILURE); },
      Qt::QueuedConnection);
  engine.loadFromModule("QfmCore"_L1, "Main"_L1);

  return QGuiApplication::exec();
}
