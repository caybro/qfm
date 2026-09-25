# Copilot instructions for qfm

## Build, test, and lint commands

- Configure from a clean checkout with Qt 6.11+ available to CMake:
  ```bash
  cmake -S . -B build/Qt6_SYSTEM_RelWithDebInfo -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
  ```
- Build the app target:
  ```bash
  cmake --build build/Qt6_SYSTEM_RelWithDebInfo --target qfm
  ```
- Run the built app:
  ```bash
  ./build/Qt6_SYSTEM_RelWithDebInfo/qfm
  ```
- Run CTest from the configured build tree:
  ```bash
  ctest --test-dir build/Qt6_SYSTEM_RelWithDebInfo --output-on-failure
  ```
  This repository currently has no project tests registered. If tests are added, run one test with:
  ```bash
  ctest --test-dir build/Qt6_SYSTEM_RelWithDebInfo -R '<test-name-or-regex>' --output-on-failure
  ```
- Run Qt-generated QML lint targets:
  ```bash
  cmake --build build/Qt6_SYSTEM_RelWithDebInfo --target all_qmllint
  cmake --build build/Qt6_SYSTEM_RelWithDebInfo --target all_qmllint_module
  cmake --build build/Qt6_SYSTEM_RelWithDebInfo --target all_qmllint_json
  ```
- Update/release translations after changing translatable QML strings:
  ```bash
  cmake --build build/Qt6_SYSTEM_RelWithDebInfo --target update_translations
  cmake --build build/Qt6_SYSTEM_RelWithDebInfo --target release_translations
  ```

## MCP servers

- This repository configures the official Qt Documentation MCP server in `.mcp.json` as `qt-docs`. Use it for Qt/QML API lookups, especially for Qt 6.11 behavior, QML types, properties, signals, and module documentation.

## Architecture

- `qfm` is a Qt Quick file manager built as a single CMake target and QML module with URI `QfmCore`. Keep new C++ sources, QML files, resources, and icons registered in `CMakeLists.txt` under the existing `qt_add_qml_module()` call so they are packaged into the module and visible through `qrc:/qt/qml/QfmCore/...`.
- `main.cpp` sets application metadata, creates a `QQmlApplicationEngine`, and loads `QfmCore/Main`. The top-level `Main.qml` owns persistent `Settings`, keyboard navigation, and the two-pane `SplitView`.
- C++ exposes the backend API to QML via `QML_ELEMENT`/`QML_SINGLETON` instead of manual context properties. `FileUtils` is the QML singleton for path/URL conversion and standard locations; `QfmFilesystemModel` is the list model backing file panels.
- `QfmFilesystemModel` defines all QML-visible model roles in its `Roles` enum and `roleNames()` map. `qml/components/QfmFileListPanel.qml` depends on those exact role names for display, sorting, filtering, metadata, and activation.
- Sorting/filtering is delegated in QML to the fetched `SortFilterProxyModel` dependency. Directory-first name sorting is implemented by combining an `isDir` `RoleSorter` with a `fileName` `StringSorter`; other columns use a `RoleSorter` on the selected role.
- UI composition is split between `Main.qml`, reusable controls in `qml/controls/`, and larger components in `qml/components/`. `QfmFileListPanel.qml` currently also contains local inline components for the file delegate, header button wrapper, and separator.
- Icons live in `icons/` and are consumed either as module resources like `/qt/qml/QfmCore/icons/file.svg` from C++ model data or as `qrc:/qt/qml/QfmCore/icons/...` URLs from QML.
- Translation files live in `i18n/`; `qt_add_translations()` uses base name `qml`, includes Czech plus plural English TS files, and merges Qt base translations.

## Repository-specific conventions

- Use C++20 and Qt string literals (`using namespace Qt::Literals::StringLiterals`, `"_L1"`) for fixed string data in C++ sources.
- Add QML-exposed C++ classes with `Q_OBJECT`, `QML_ELEMENT`, and `Q_PROPERTY(... FINAL)` following the existing backend pattern. Use explicit change guards before emitting notify signals.
- When adding or renaming filesystem model roles, update the enum, the string constants, `data()`, `roleNames()`, and all QML sort/filter/display bindings that reference the role name.
- `QfmFilesystemModel::fetchDir()` performs a full model reset for a directory change and includes hidden files; QML filtering controls whether hidden entries are displayed.
- QML uses `required property` declarations in delegates, `property alias` for state exposed to parents/settings, and local `QtObject { id: d }` objects for private component state.
- Keep user-visible QML strings wrapped in `qsTr()` so the generated translation targets pick them up.
- The UI style imports `QtQuick.Controls.Basic`; avoid mixing in another Controls style unless the whole app style strategy changes.
- Generated artifacts and configured build trees (`build*/`, `.qtcreator/`, generated `.qmlls.ini`) are ignored. Do not edit files under `build/`; change source files and rebuild.
