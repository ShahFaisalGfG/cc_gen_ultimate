@echo off
:: Python Installer
:: Downloads and installs Python 3.10.0 silently and adds it to PATH
:: Returns exit code 0 on success, 1 on failure

echo Starting Python installation...
where python >nul 2>&1
if %errorLevel% equ 0 (
    echo Python already installed
    python --version
    exit /b 0
)

where curl >nul 2>&1 || (
    echo Error: curl not available
    exit /b 1
)

echo Downloading Python 3.10.0...
curl -o python-3.10.0-amd64.exe https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe >nul 2>&1
if %errorLevel% neq 0 (
    echo Download failed: Unable to download Python installer
    exit /b 1
)

echo Installing Python 3.10.0...
python-3.10.0-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: Unable to install Python
    del python-3.10.0-amd64.exe
    exit /b 1
)

echo Verifying Python installation...
start /wait cmd /c (
    python --version >nul 2>&1
    if %errorLevel% neq 0 (
        echo Installation failed: Python not detected in PATH
        del python-3.10.0-amd64.exe
        exit /b 1
    )
    echo Installation successful: Python installed
    del python-3.10.0-amd64.exe
    python --version
    exit /b 0
)

exit /b %errorLevel%