@echo off
setlocal EnableExtensions
title 1-Click Zed + SSH Setup (sahar@192.168.1.161 - Astrophysics-Midterm-20261109)
echo ============================================================================
echo   AI Workspace 1-Click Laptop Setup: sahar@192.168.1.161
echo   Remote Folder: /home/sahar/workspace/Astrophysics-Midterm-20261109
echo ============================================================================
echo.
set "SSH_DIR=%USERPROFILE%\.ssh"
set "KEY_FILE=%SSH_DIR%\id_ed25519"
set "PUB_FILE=%SSH_DIR%\id_ed25519.pub"
set "CFG_FILE=%SSH_DIR%\config"
set "KH_FILE=%SSH_DIR%\known_hosts"
if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"

echo [1/5] Checking local Ed25519 SSH key...
if not exist "%PUB_FILE%" (
    echo       Generating new Ed25519 SSH key in %KEY_FILE%...
    "%SystemRoot%\System32\OpenSSH\ssh-keygen.exe" -t ed25519 -N "" -f "%KEY_FILE%"
) else (
    echo       Found existing SSH public key: %PUB_FILE%
)
if not exist "%PUB_FILE%" (
    echo [ERROR] Could not find or generate %PUB_FILE%. Ensure Windows OpenSSH Client is enabled.
    pause
    exit /b 1
)

echo [2/5] Registering laptop SSH key on sahar@192.168.1.161 via Portal API (no password needed)...
"%SystemRoot%\System32\curl.exe" -fsSL -X POST "http://192.168.1.181:8000/api/onboarding/register-laptop-ssh-key?target_host=192.168.1.161&ssh_user=sahar&token=1794734138.8c74759e9a3db8264f9448d81badb2e2ddc72f0891ace7d170030634f00be2d3&format=text" -H "Content-Type: text/plain" --data-binary "@%PUB_FILE%"
if errorlevel 1 (
    echo [ERROR] Failed to reach Portal API to register SSH key. Verify OpenVPN / LAN connection.
    pause
    exit /b 1
)

echo [3/5] Configuring SSH known_hosts and %CFG_FILE% for 192.168.1.161...
"%SystemRoot%\System32\curl.exe" -fsSL "http://192.168.1.181:8000/api/onboarding/vm-known-hosts?target_host=192.168.1.161&ssh_user=sahar&token=1794734138.8c74759e9a3db8264f9448d81badb2e2ddc72f0891ace7d170030634f00be2d3" >> "%KH_FILE%" 2>nul
findstr /C:"Host 192.168.1.161" "%CFG_FILE%" >nul 2>nul
if errorlevel 1 (
    >> "%CFG_FILE%" echo.
    >> "%CFG_FILE%" echo Host sahar 192.168.1.161
    >> "%CFG_FILE%" echo     HostName 192.168.1.161
    >> "%CFG_FILE%" echo     User sahar
    >> "%CFG_FILE%" echo     IdentityFile ~/.ssh/id_ed25519
    >> "%CFG_FILE%" echo     IdentitiesOnly yes
    >> "%CFG_FILE%" echo     StrictHostKeyChecking accept-new
    >> "%CFG_FILE%" echo     ServerAliveInterval 30
    >> "%CFG_FILE%" echo     ServerAliveCountMax 6
)
"%SystemRoot%\System32\OpenSSH\ssh.exe" -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 sahar@192.168.1.161 "echo       Passwordless SSH verified OK!"

echo [4/5] Checking Zed Editor installation and configuring remote folder...
set "ZED_BIN=%LOCALAPPDATA%\Programs\Zed\bin\zed.exe"
if not exist "%ZED_BIN%" (
    for /f "delims=" %%I in ('where zed.exe 2^>nul') do set "ZED_BIN=%%I"
)
if not exist "%ZED_BIN%" (
    echo       Installing Zed Editor via winget...
    winget install --id ZedIndustries.Zed -e --source winget --accept-package-agreements --accept-source-agreements
    set "ZED_BIN=%LOCALAPPDATA%\Programs\Zed\bin\zed.exe"
)
set "ZED_CFG_DIR=%APPDATA%\Zed"
set "ZED_CFG=%ZED_CFG_DIR%\settings.json"
set "ZED_TMP=%ZED_CFG_DIR%\settings.json.tmp"
if not exist "%ZED_CFG_DIR%" mkdir "%ZED_CFG_DIR%"
if exist "%ZED_CFG%" (
    "%SystemRoot%\System32\curl.exe" -fsSL -X POST "http://192.168.1.181:8000/api/onboarding/merge-zed-client-settings?target_host=192.168.1.161&ssh_user=sahar&project_path=%2Fhome%2Fsahar%2Fworkspace%2FAstrophysics-Midterm-20261109&token=1794734138.8c74759e9a3db8264f9448d81badb2e2ddc72f0891ace7d170030634f00be2d3" --data-binary "@%ZED_CFG%" -o "%ZED_TMP%" && move /Y "%ZED_TMP%" "%ZED_CFG%" >nul
) else (
    "%SystemRoot%\System32\curl.exe" -fsSL -X POST "http://192.168.1.181:8000/api/onboarding/merge-zed-client-settings?target_host=192.168.1.161&ssh_user=sahar&project_path=%2Fhome%2Fsahar%2Fworkspace%2FAstrophysics-Midterm-20261109&token=1794734138.8c74759e9a3db8264f9448d81badb2e2ddc72f0891ace7d170030634f00be2d3" --data-binary "" -o "%ZED_CFG%"
)
if not exist "%ZED_CFG_DIR%\keymap.json" (
    "%SystemRoot%\System32\curl.exe" -fsSL "http://192.168.1.181:8000/api/onboarding/zed-client-keymap?target_host=192.168.1.161&ssh_user=sahar&token=1794734138.8c74759e9a3db8264f9448d81badb2e2ddc72f0891ace7d170030634f00be2d3" -o "%ZED_CFG_DIR%\keymap.json" 2>nul
)

echo [5/5] Launching Zed Editor directly into ssh://sahar@192.168.1.161/home/sahar/workspace/Astrophysics-Midterm-20261109 ...
if exist "%ZED_BIN%" (
    start "" "%ZED_BIN%" "ssh://sahar@192.168.1.161/home/sahar/workspace/Astrophysics-Midterm-20261109"
    echo       Zed launched! Click the Sparkle icon in the right dock to sign into Google Antigravity.
) else (
    echo       Zed binary not found in default path yet. Open Zed and connect to: ssh://sahar@192.168.1.161/home/sahar/workspace/Astrophysics-Midterm-20261109
)
echo.
echo ✅ All laptop SSH + Zed setup steps completed!
timeout /t 4 >nul
exit /b 0
