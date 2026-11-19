cmake_minimum_required(VERSION 3.21)

project(AuraPaper VERSION 1.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Default Qt installation path if not passed on command line
if(NOT DEFINED CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH "D:/Qt/6.8.3/msvc2022_64")
endif()

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    QuickLayouts
    Network
)

qt_standard_project_setup(REQUIRES 6.8)

set(APP_SOURCES
    src/main.cpp
    src/AppController.h
    src/AppController.cpp
    src/WallpaperChannel.h
    src/WallpaperChannel.cpp
    src/WallpaperListModel.h
    src/WallpaperListModel.cpp
    src/ThumbnailImageProvider.h
    src/ThumbnailImageProvider.cpp
    src/platform/WallpaperTypes.h
    src/platform/DesktopWallpaperSetter.h
    src/platform/DesktopWallpaperSetter.cpp
    src/platform/LockScreenSetter.h
    src/platform/LockScreenSetter.cpp
    src/platform/ImageFitRenderer.h
    src/platform/ImageFitRenderer.cpp
    src/platform/NativeSystemTray.h
    src/platform/NativeSystemTray.cpp
    src/platform/WindowsUtils.h
    src/platform/WindowsUtils.cpp
    resources/app.rc
)

qt_add_executable(AuraPaper WIN32 ${APP_SOURCES})

if(MSVC)
    target_compile_options(AuraPaper PRIVATE
        /utf-8
        /Zc:__cplusplus
        /permissive-
        /bigobj
        /W3
    )
    target_compile_definitions(AuraPaper PRIVATE
        UNICODE
        _UNICODE
        WIN32_LEAN_AND_MEAN
        NOMINMAX
    )
endif()

set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(AuraPaper
    URI AuraPaper
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/theme/Theme.qml
        qml/components/IconGlyph.qml
        qml/components/AnimatedToggle.qml
        qml/components/AccentButton.qml
        qml/components/CardContainer.qml
        qml/components/SegmentedSelector.qml
        qml/components/CountdownRing.qml
        qml/components/WallpaperPreviewCard.qml
        qml/components/CustomTitleBar.qml
        qml/components/SidebarNav.qml
        qml/components/ToastOverlay.qml
        qml/components/TrayMenuPopup.qml
        qml/pages/OverviewPage.qml
        qml/pages/ChannelSettingsPage.qml
        qml/pages/SettingsPage.qml
)

qt_add_resources(AuraPaper "app_icons"
    PREFIX "/AuraPaper"
    FILES
        resources/icons/app_icon.png
)

target_include_directories(AuraPaper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(AuraPaper PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickLayouts
    Qt6::Network
    dwmapi
    ole32
    psapi
    shell32
    advapi32
    windowsapp
)
