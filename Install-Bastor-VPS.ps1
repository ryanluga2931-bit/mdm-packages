# ============================================================
# Cai app cho VPS Bastor
# VipTalk, Signal, UniKey, Google Drive, WPS Office
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\BastorInstall"
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

function AddShortcut($name, $targetPath, $argList = "") {
    $publicLnk = "$env:PUBLIC\Desktop\$name.lnk"
    $userLnk   = "$env:USERPROFILE\Desktop\$name.lnk"
    if ((Test-Path $publicLnk) -or (Test-Path $userLnk)) {
        Write-Host "  [SKIP] Shortcut '$name' da co" -ForegroundColor Cyan
        return
    }
    if (-not (Test-Path $targetPath)) {
        Write-Host "  [SKIP] Shortcut '$name': khong tim thay exe" -ForegroundColor Gray
        return
    }
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($publicLnk)
    $sc.TargetPath = $targetPath
    if ($argList) { $sc.Arguments = $argList }
    $sc.Save()
    Write-Host "  [OK] Shortcut '$name' tao xong" -ForegroundColor Green
}

# --- [1] UniKey ---
Write-Host ""
Write-Host "=== [1/5] UniKey ===" -ForegroundColor Cyan
$ukExe = "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"
if (Test-Path $ukExe) {
    Write-Host "  [SKIP] UniKey da co" -ForegroundColor Cyan
} else {
    $f = "$tmp\UniKey.zip"
    Download "UniKey" "$ghBase/UniKey-Windows.zip" $f
    Expand-Archive $f -DestinationPath "C:\Program Files\UniKey" -Force
    Write-Host "  [OK] UniKey xong" -ForegroundColor Green
}
AddShortcut "UniKey" $ukExe

# --- [2] VipTalk ---
Write-Host ""
Write-Host "=== [2/5] VipTalk ===" -ForegroundColor Cyan
if (CheckReg "VipTalk") {
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VipTalk.exe"
    Download "VipTalk 1.12.142" "$ghBase/VipTalk-Setup-1.12.142.exe" $f
    RunInstaller "VipTalk" $f "/S"
}

# --- [3] Signal ---
Write-Host ""
Write-Host "=== [3/5] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $f
    RunInstaller "Signal" $f "--silent"
}
AddShortcut "Signal" $sigExe

# --- [4] Google Drive ---
Write-Host ""
Write-Host "=== [4/5] Google Drive ===" -ForegroundColor Cyan
$gdriveExe = "C:\Program Files\Google\Drive File Stream\GoogleDriveFS.exe"
if (Test-Path $gdriveExe) {
    Write-Host "  [SKIP] Google Drive da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\GoogleDriveSetup.exe"
    Download "Google Drive" "https://dl.google.com/release2/drive-file-stream/adwqz7o72qaif7fr4h4d6xoysy6a_99.0.0.0/setup.exe" $f
    RunInstaller "Google Drive" $f "--silent"
}
AddShortcut "Google Drive" $gdriveExe

# --- [5] WPS Office ---
Write-Host ""
Write-Host "=== [5/5] WPS Office ===" -ForegroundColor Cyan
if (CheckReg "WPS Office") {
    Write-Host "  [SKIP] WPS Office da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\WPSSetup.exe"
    Download "WPS Office 12.1" "https://official-package.wpscdn.cn/wps/download/WPS_Setup_x64_26373.exe" $f
    RunInstaller "WPS Office" $f "/S"
}

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - Bastor VPS" -ForegroundColor Green
Write-Host "  1. UniKey" -ForegroundColor White
Write-Host "  2. VipTalk 1.12.142" -ForegroundColor White
Write-Host "  3. Signal 8.16.0" -ForegroundColor White
Write-Host "  4. Google Drive" -ForegroundColor White
Write-Host "  5. WPS Office 12.1" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
pause
