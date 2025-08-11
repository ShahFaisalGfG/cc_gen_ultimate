@echo off
:: LibreTranslate CLI Installer
:: Installs libretranslate Python package
:: Returns exit code 0 on success, 1 on failure

echo Starting libretranslate installation...
where python >nul 2>&1 || (
    echo Installation failed: Python not found in PATH
    exit /b 1
)

echo Installing libretranslate...
pip install --upgrade libretranslate --timeout 1000
if %errorLevel% neq 0 (
    echo Installation failed: Unable to install libretranslate
    exit /b 1
)

echo Uninstalling argos-translate-files...
pip show argos-translate-files >nul 2>&1
if %errorLevel% equ 0 (
    pip uninstall -y argos-translate-files
)


::pip install --upgrade argos-translate-files --timeout 1000
::if %errorLevel% neq 0 (
::    echo Installation failed: Unable to install argos-translate-files
::    exit /b 1
::)

echo Verifying libretranslate installation...
pip show libretranslate >nul 2>&1
if %errorLevel% neq 0 (
    echo Installation failed: libretranslate package not found
    exit /b 1
)

::echo Installation successful: libretranslate installed
::pip show libretranslate | findstr "Version:"

::echo argos-translate-files installed
::pip show argos-translate-files | findstr "Version:"
exit /b 0