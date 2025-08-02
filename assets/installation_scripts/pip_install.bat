@echo off
:: Pip Updater
:: Updates pip to the latest version
:: Returns exit code 0 on success, 1 on failure

echo Starting pip installation...
where python >nul 2>&1 || (
    echo Installation failed: Python not found in PATH
    exit /b 1
)

echo Upgrading pip...
python -m pip install --upgrade pip >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: Unable to upgrade pip
    exit /b 1
)

echo Verifying pip installation...
pip --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: pip not detected
    exit /b 1
)

::echo Installation successful: pip updated
::pip --version
exit /b 0