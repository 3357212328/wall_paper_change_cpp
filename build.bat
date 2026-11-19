@echo off
setlocal EnableDelayedExpansion

set "VS_VCVARS=D:\Microsoft Visual Studio\Community\VC\Auxiliary\Build\vcvars64.bat"
set "VS_CMAKE=D:\Microsoft Visual Studio\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
set "VS_NINJA=D:\Microsoft Visual Studio\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"
set "QT_DIR=D:\Qt\6.8.3\msvc2022_64"

call "%VS_VCVARS%"
if errorlevel 1 exit /b 1

set "PATH=%VS_CMAKE%;%VS_NINJA%;!PATH!"

cmake -S "%~dp0." -B "%~dp0build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QT_DIR%"
if errorlevel 1 exit /b 1

cmake --build "%~dp0build" --parallel
if errorlevel 1 exit /b 1

set "DIST_DIR=%~dp0dist\AuraPaper-win64"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"
copy /y "%~dp0build\AuraPaper.exe" "%DIST_DIR%\AuraPaper.exe" >nul
copy /y "%~dp0README.md" "%DIST_DIR%\README.md" >nul

"%QT_DIR%\bin\windeployqt.exe" --release --qmldir "%~dp0qml" --no-translations --no-opengl-sw --no-compiler-runtime "%DIST_DIR%\AuraPaper.exe"
if errorlevel 1 exit /b 1

rem Prune unused QtQuick Controls styles (app explicitly uses Basic style) & non-runtime plugins
for %%S in (Fusion Material Imagine Universal FluentWinUI3 Windows) do (
    del /f /q "%DIST_DIR%\Qt6QuickControls2%%S*.dll" 2>nul
    if exist "%DIST_DIR%\qml\QtQuick\Controls\%%S" rmdir /s /q "%DIST_DIR%\qml\QtQuick\Controls\%%S"
)
if exist "%DIST_DIR%\qml\QtQuick\NativeStyle" rmdir /s /q "%DIST_DIR%\qml\QtQuick\NativeStyle"
for %%D in (qmltooling tls networkinformation generic iconengines styles) do (
    if exist "%DIST_DIR%\%%D" rmdir /s /q "%DIST_DIR%\%%D"
)
del /f /q "%DIST_DIR%\Qt6Svg.dll" "%DIST_DIR%\Qt6Widgets.dll" 2>nul
for %%F in (qsvg.dll qtiff.dll qwbmp.dll qtga.dll qicns.dll qpdf.dll) do (
    del /f /q "%DIST_DIR%\imageformats\%%F" 2>nul
)
for /r "%DIST_DIR%\qml" %%T in (*.qmltypes) do del /f /q "%%T" 2>nul

echo.
echo [AuraPaper] Build & slim package succeeded: %DIST_DIR%\AuraPaper.exe
endlocal
