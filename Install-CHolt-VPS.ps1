# ============================================================
# Cai app cho VPS C Holt
# Cursor, PhpStorm, VS Code, DBeaver, MySQL Workbench,
# Postman, Figma, VipTalk, UniKey, Docker, Signal
# - Co app: SKIP | Loi/Thieu: cai lai
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\CHoltInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download($name, $url, $out) {
    Write-Host "  [.] Dang tai $name..." -ForegroundColor Yellow
    Invoke-WebRequest $url -OutFile $out -UseBasicParsing
    Write-Host "  [OK] Tai xong" -ForegroundColor Green
}

function RunInstaller($name, $path, $argList = "") {
    Write-Host "  [.] Dang cai $name..." -ForegroundColor Yellow
    if ($argList) {
        $p = Start-Process $path -ArgumentList $argList -Wait -PassThru
    } else {
        $p = Start-Process $path -Wait -PassThru
    }
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

$i = 0
$total = 11

# --- [1] UniKey ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] UniKey ===" -ForegroundColor Cyan
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
$i++; Write-Host ""; Write-Host "=== [$i/$total] VipTalk ===" -ForegroundColor Cyan
if (CheckReg "VipTalk") {
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VipTalk.exe"
    Download "VipTalk 1.12.142" "$ghBase/VipTalk-Setup-1.12.142.exe" $f
    RunInstaller "VipTalk" $f "/S"
}

# --- [3] Signal ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $f
    RunInstaller "Signal" $f "--silent"
}

# --- [4] VS Code ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] VS Code ===" -ForegroundColor Cyan
$codeExe = if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") { "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" } else { "C:\Program Files\Microsoft VS Code\Code.exe" }
if (Test-Path $codeExe) {
    Write-Host "  [SKIP] VS Code da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VSCode.exe"
    Download "VS Code" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" $f
    RunInstaller "VS Code" $f "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
}

# --- [5] Cursor ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] Cursor ===" -ForegroundColor Cyan
if (CheckReg "Cursor") {
    Write-Host "  [SKIP] Cursor da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\CursorSetup.exe"
    Download "Cursor 3.9.8" "https://downloads.cursor.com/production/4aa8ff1b7877ed7bd01bcba308698f71a6735380/win32/x64/user-setup/CursorUserSetup-x64-3.9.8.exe" $f
    RunInstaller "Cursor" $f "/VERYSILENT /NORESTART"
}

# --- [6] PhpStorm ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] PhpStorm ===" -ForegroundColor Cyan
if (CheckReg "PhpStorm") {
    Write-Host "  [SKIP] PhpStorm da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\PhpStorm.exe"
    Download "PhpStorm 2026.1.3" "https://download.jetbrains.com/webide/PhpStorm-2026.1.3.exe" $f
    RunInstaller "PhpStorm" $f "/S"
}

# --- [7] DBeaver ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] DBeaver ===" -ForegroundColor Cyan
if (CheckReg "DBeaver") {
    Write-Host "  [SKIP] DBeaver da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\DBeaver.exe"
    Download "DBeaver 26.1.1" "https://github.com/dbeaver/dbeaver/releases/download/26.1.1/dbeaver-ce-26.1.1-windows-x86_64.exe" $f
    RunInstaller "DBeaver" $f "/S"
}

# --- [8] MySQL Workbench ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] MySQL Workbench ===" -ForegroundColor Cyan
if (CheckReg "MySQL Workbench") {
    Write-Host "  [SKIP] MySQL Workbench da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\MySQLWorkbench.msi"
    Download "MySQL Workbench 8.0.47" "https://cdn.mysql.com/Downloads/MySQLGUITools/mysql-workbench-community-8.0.47-winx64.msi" $f
    RunInstaller "MySQL Workbench" "msiexec.exe" "/i `"$f`" /qn /norestart"
}

# --- [9] Postman ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] Postman ===" -ForegroundColor Cyan
$postmanExe = "$env:LOCALAPPDATA\Postman\Postman.exe"
if (Test-Path $postmanExe) {
    Write-Host "  [SKIP] Postman da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\PostmanSetup.exe"
    Download "Postman" "https://dl.pstmn.io/download/latest/win64" $f
    RunInstaller "Postman" $f "--silent"
}

# --- [10] Figma ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] Figma ===" -ForegroundColor Cyan
if (CheckReg "Figma") {
    Write-Host "  [SKIP] Figma da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\FigmaSetup.exe"
    Download "Figma 126.6.9" "https://desktop.figma.com/win/build/Figma-126.6.9.exe" $f
    RunInstaller "Figma" $f "--silent"
}

# --- [11] Docker Desktop ---
$i++; Write-Host ""; Write-Host "=== [$i/$total] Docker Desktop ===" -ForegroundColor Cyan
if (CheckReg "Docker Desktop") {
    Write-Host "  [SKIP] Docker da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\DockerSetup.exe"
    Download "Docker Desktop" "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" $f
    RunInstaller "Docker" $f "install --quiet --accept-license"
}

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - C Holt VPS" -ForegroundColor Green
Write-Host "  1.  UniKey" -ForegroundColor White
Write-Host "  2.  VipTalk 1.12.142" -ForegroundColor White
Write-Host "  3.  Signal 8.16.0" -ForegroundColor White
Write-Host "  4.  VS Code" -ForegroundColor White
Write-Host "  5.  Cursor 3.9.8" -ForegroundColor White
Write-Host "  6.  PhpStorm 2026.1.3" -ForegroundColor White
Write-Host "  7.  DBeaver 26.1.1" -ForegroundColor White
Write-Host "  8.  MySQL Workbench 8.0.47" -ForegroundColor White
Write-Host "  9.  Postman" -ForegroundColor White
Write-Host "  10. Figma 126.6.9" -ForegroundColor White
Write-Host "  11. Docker Desktop" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
pause
