cmake_minimum_required(VERSION 3.22)

project(qfm VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 LinguistTools)

qt_standard_project_setup(
    REQUIRES 6.11
    I18N_TRANSLATED_LANGUAGES cs
)

add_definitions(-DAPP_VERSION="${CMAKE_PROJECT_VERSION}")

qt_add_executable(${CMAKE_PROJECT_NAME}
    main.cpp
)

qt_add_qml_module(${CMAKE_PROJECT_NAME}
    URI QfmCore
    QML_FILES
      Main.qml
    SOURCES
      fileutils.h fileutils.cpp
    RESOURCES
      icons/create_new_folder.svg
      icons/file.svg
      icons/folder.svg
      icons/folder_limited.svg
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.caybro.qfm
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::QuickControls2
)

qt_add_translations(${CMAKE_PROJECT_NAME}
    RESOURCE_PREFIX /qt/qml/QfmCore/i18n
    TS_FILE_BASE qml
    PLURALS_TS_FILE i18n/qml_en.ts
    TS_OUTPUT_DIRECTORY i18n
    MERGE_QT_TRANSLATIONS
      QT_TRANSLATION_CATALOGS qtbase
)

install(TARGETS ${CMAKE_PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
