@echo off
setlocal enabledelayedexpansion

echo Installing required dependencies...

:: Check if Go is installed
where go >nul 2>nul
if %errorlevel% neq 0 (
    echo Installing Go...
    curl -Lo go.msi https://go.dev/dl/go1.21.5.windows-amd64.msi
    start /wait msiexec /i go.msi /quiet
    del go.msi
) else (
    echo Go is already installed
)

:: Create bin directory for tools
set "TOOLS_DIR=%USERPROFILE%\.local\bin"
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

:: Install Lune
echo Installing Lune...
curl -Lo "%TOOLS_DIR%\lune.exe" https://github.com/lune-org/lune/releases/latest/download/lune-windows.exe

:: Install Aftman
echo Installing Aftman...
curl -Lo "%TOOLS_DIR%\aftman.exe" https://github.com/LPGhatguy/aftman/releases/latest/download/aftman-windows.exe

:: Add tools directory to user PATH if not already there
for /f "tokens=3*" %%p in ('reg query HKCU\Environment /v PATH') do set "USER_PATH=%%p"
if not "!USER_PATH!"=="!USER_PATH:%TOOLS_DIR%=!" (
    echo Tools directory already in PATH
) else (
    setx PATH "%TOOLS_DIR%;%PATH%"
)

:: Install Rojo using Aftman
echo Installing Rojo...
"%TOOLS_DIR%\aftman.exe" install rojo-rbx/rojo@7.3.0

echo.
echo Installation complete! Please restart your terminal for the changes to take effect.
echo You can now use 'go', 'lune', and 'rojo' commands.
pause
