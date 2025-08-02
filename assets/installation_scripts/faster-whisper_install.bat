@echo off
:: Whisper Installer
:: Installs faster-whisper Python package
:: Returns exit code 0 on success, 1 on failure

echo Starting Whisper installation...
where python >nul 2>&1 || (
    echo Installation failed: Python not found in PATH
    exit /b 1
)

echo Installing faster-whisper...
pip install --upgrade faster-whisper >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: Unable to install faster-whisper
    exit /b 1
)

echo Verifying Whisper installation...
pip show faster-whisper >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: Whisper not detected
    exit /b 1
)

::echo Installation successful: Whisper installed
::pip show faster-whisper | findstr "Version"
exit /b 0