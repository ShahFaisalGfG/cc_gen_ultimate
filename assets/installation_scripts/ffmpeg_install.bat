@echo off
:: FFmpeg Installer
:: Installs FFmpeg using winget
:: Returns exit code 0 on success, 1 on failure

echo Starting FFmpeg installation...
where ffmpeg >nul 2>&1
if %errorLevel% equ 0 (
    echo FFmpeg already installed
    ffmpeg -version | findstr "version"
    exit /b 0
)

where winget >nul 2>&1 || (
    echo Error: winget not available (Windows 10 1809+ required)
    exit /b 1
)

echo Installing FFmpeg...
winget install --id Gyan.FFmpeg --exact --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: Unable to install FFmpeg
    exit /b 1
)

echo Verifying FFmpeg installation...
ffmpeg -version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: FFmpeg not detected in PATH
    exit /b 1
)

::echo Installation successful: FFmpeg installed
::ffmpeg -version | findstr "version"
exit /b 0