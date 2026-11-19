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

"%QT_DIR%\bin\windeployqt.exe" --release --qmldir "%~dp0qml" --no-translations --no-opengl-sw "%~dp0build\AuraPaper.exe"
if errorlevel 1 exit /b 1

echo.
echo [AuraPaper] Build & deploy succeeded: %~dp0build\AuraPaper.exe
endlocal
