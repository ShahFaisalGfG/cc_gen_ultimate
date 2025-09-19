@echo off
:: Python Installer
:: Installs python using winget
:: Returns exit code 0 on success, 1 on failure

echo Starting Python installation...
where python >nul 2>&1
if %errorLevel% equ 0 (
    echo python already installed
    python -version | findstr "version"
    exit /b 0
)

where winget >nul 2>&1 || (
    echo Error: winget not available (Windows 10 1809+ required)
    exit /b 1
)

echo Installing Python...
winget install --id Python.Python.3.11 --scope user --exact --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: Unable to install Python
    exit /b 1
)

echo Verifying Python installation...
python -version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: Python not detected in PATH
    exit /b 1
)

::echo Installation successful: Python installed
::python -version | findstr "version"
exit /b 0