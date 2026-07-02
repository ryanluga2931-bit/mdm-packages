# ============================================================
# Cai app cho VPS E Garrick
# VS Code, Docker (+ WSL2), Signal, Postman,
# DBeaver, MySQL Workbench, VipTalk, UniKey
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\EGarrickInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download($name, $url, $out) {
    Write-Host "  [.] Dang tai $name..." -ForegroundColor Yellow
    Invoke-WebRequest $url -OutFile $out -UseBasicParsing
    Write-Host "  [OK] Tai xong" -ForegroundColor Green
}

function RunInstaller($name, $path, $argList = "") {
    Write-Host "  [.] Dang cai $name..." -ForegroundColor Yellow
    if ($argList) { $p = Start-Process $path -ArgumentList $argList -Wait -PassThru }
    else { $p = Start-Process $path -Wait -PassThru }
    if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010 -or $p.ExitCode -eq 1641) {
        Write-Host "  [OK] Cai xong: $name" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $name exit code: $($p.ExitCode)" -ForegroundColor Yellow
    }
}

function CheckReg($name) {
    return Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*$name*" }
}

# --- [1] UniKey ---
Write-Host ""
Write-Host "=== [1/8] UniKey ===" -ForegroundColor Cyan
$ukExe = "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"
if (Test-Path $ukExe) {
    Write-Host "  [SKIP] UniKey da co" -ForegroundColor Cyan
} else {
    $f = "$tmp\UniKey.zip"
    Download "UniKey" "$ghBase/UniKey-Windows.zip" $f
    Expand-Archive $f -DestinationPath "C:\Program Files\UniKey" -Force
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut("$env:PUBLIC\Desktop\UniKey.lnk")
    $sc.TargetPath = $ukExe; $sc.Save()
    Write-Host "  [OK] UniKey xong" -ForegroundColor Green
}

# --- [2] VipTalk ---
Write-Host ""
Write-Host "=== [2/8] VipTalk ===" -ForegroundColor Cyan
if (CheckReg "VipTalk") {
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VipTalk.exe"
    Download "VipTalk 1.12.142" "$ghBase/VipTalk-Setup-1.12.142.exe" $f
    RunInstaller "VipTalk" $f "/S"
}

# --- [3] Signal ---
Write-Host ""
Write-Host "=== [3/8] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $f
    RunInstaller "Signal" $f "--silent"
}

# --- [4] VS Code ---
Write-Host ""
Write-Host "=== [4/8] VS Code ===" -ForegroundColor Cyan
$codeExe = if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") { "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" } else { "C:\Program Files\Microsoft VS Code\Code.exe" }
if (Test-Path $codeExe) {
    Write-Host "  [SKIP] VS Code da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VSCode.exe"
    Download "VS Code" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" $f
    RunInstaller "VS Code" $f "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
}

# --- [5] Postman ---
Write-Host ""
Write-Host "=== [5/8] Postman ===" -ForegroundColor Cyan
$postmanExe = "$env:LOCALAPPDATA\Postman\Postman.exe"
if (Test-Path $postmanExe) {
    Write-Host "  [SKIP] Postman da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\PostmanSetup.exe"
    Download "Postman" "https://dl.pstmn.io/download/latest/win64" $f
    RunInstaller "Postman" $f "--silent"
}

# --- [6] DBeaver ---
Write-Host ""
Write-Host "=== [6/8] DBeaver ===" -ForegroundColor Cyan
if (CheckReg "DBeaver") {
    Write-Host "  [SKIP] DBeaver da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\DBeaver.exe"
    Download "DBeaver 26.1.1" "https://github.com/dbeaver/dbeaver/releases/download/26.1.1/dbeaver-ce-26.1.1-windows-x86_64.exe" $f
    RunInstaller "DBeaver" $f "/S"
}

# --- [7] MySQL Workbench ---
Write-Host ""
Write-Host "=== [7/8] MySQL Workbench ===" -ForegroundColor Cyan
if (CheckReg "MySQL Workbench") {
    Write-Host "  [SKIP] MySQL Workbench da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\MySQLWorkbench.msi"
    Download "MySQL Workbench 8.0.47" "https://cdn.mysql.com/Downloads/MySQLGUITools/mysql-workbench-community-8.0.47-winx64.msi" $f
    RunInstaller "MySQL Workbench" "msiexec.exe" "/i `"$f`" /qn /norestart"
}

# --- [8] WSL2 + Docker Desktop ---
Write-Host ""
Write-Host "=== [8/8] WSL2 + Docker Desktop ===" -ForegroundColor Cyan

if (CheckReg "Docker Desktop") {
    Write-Host "  [SKIP] Docker Desktop da cai" -ForegroundColor Cyan
} else {
    # Bat WSL feature
    Write-Host "  [.] Bat Windows Subsystem for Linux..." -ForegroundColor Yellow
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -EA SilentlyContinue
    if ($wslFeature.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart | Out-Null
        Write-Host "  [OK] WSL feature bat xong" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] WSL feature da bat" -ForegroundColor Cyan
    }

    # Bat Virtual Machine Platform
    Write-Host "  [.] Bat Virtual Machine Platform..." -ForegroundColor Yellow
    $vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -EA SilentlyContinue
    if ($vmpFeature.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart | Out-Null
        Write-Host "  [OK] VirtualMachinePlatform bat xong" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] VirtualMachinePlatform da bat" -ForegroundColor Cyan
    }

    # Cap nhat WSL2 kernel
    Write-Host "  [.] Tai va cap nhat WSL2 kernel..." -ForegroundColor Yellow
    $wslUpdate = "$tmp\wsl_update.msi"
    Download "WSL2 Kernel" "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" $wslUpdate
    RunInstaller "WSL2 Kernel" "msiexec.exe" "/i `"$wslUpdate`" /qn /norestart"

    # Dat WSL2 lam mac dinh
    Write-Host "  [.] Dat WSL2 lam mac dinh..." -ForegroundColor Yellow
    & wsl --set-default-version 2 2>&1 | Out-Null
    Write-Host "  [OK] WSL2 set default xong" -ForegroundColor Green

    # Cai Docker Desktop
    $f = "$tmp\DockerSetup.exe"
    Download "Docker Desktop" "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" $f
    RunInstaller "Docker Desktop" $f "install --quiet --accept-license"

    Write-Host ""
    Write-Host "  [!] Restart may sau khi cai xong de WSL2 + Docker hoat dong!" -ForegroundColor Yellow
}

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - E Garrick VPS" -ForegroundColor Green
Write-Host "  1. UniKey" -ForegroundColor White
Write-Host "  2. VipTalk 1.12.142" -ForegroundColor White
Write-Host "  3. Signal 8.16.0" -ForegroundColor White
Write-Host "  4. VS Code" -ForegroundColor White
Write-Host "  5. Postman" -ForegroundColor White
Write-Host "  6. DBeaver 26.1.1" -ForegroundColor White
Write-Host "  7. MySQL Workbench 8.0.47" -ForegroundColor White
Write-Host "  8. WSL2 + Docker Desktop" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " LUU Y: Restart may de WSL2 + Docker hoat dong!" -ForegroundColor Yellow
pause
