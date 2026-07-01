# ============================================================
# Cai app cho VPS O Clay
# VipTalk, Threema, Signal
# - Co app va chay duoc: SKIP
# - Thieu hoac loi: cai lai
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\OClayInstall"
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

# --- [1] VipTalk ---
Write-Host ""
Write-Host "=== [1/3] VipTalk ===" -ForegroundColor Cyan
$vtReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*VipTalk*" }
if ($vtReg) {
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $vt = "$tmp\VipTalk-Setup.exe"
    Download "VipTalk 1.12.142" "$ghBase/VipTalk-Setup-1.12.142.exe" $vt
    RunInstaller "VipTalk" $vt "/S"
}

# --- [2] Signal ---
Write-Host ""
Write-Host "=== [2/3] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $sig = "$tmp\Signal-Setup.exe"
    Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $sig
    RunInstaller "Signal" $sig "--silent"
}

# --- [3] Threema ---
Write-Host ""
Write-Host "=== [3/3] Threema ===" -ForegroundColor Cyan
$threemaInstalled = Get-AppxPackage -Name "*Threema*" -EA SilentlyContinue
if ($threemaInstalled) {
    Write-Host "  [SKIP] Threema da cai: $($threemaInstalled.Version)" -ForegroundColor Cyan
} else {
    $msix = "$tmp\Threema-Setup.msix"
    Download "Threema 2.0-beta62" "https://releases.threema.ch/desktop/2.0-beta62/threema-desktop-v2.0-beta62-windows-x64.msix" $msix
    Write-Host "  [.] Dang cai Threema (msix)..." -ForegroundColor Yellow
    try {
        Add-AppxPackage -Path $msix
        Write-Host "  [OK] Threema cai xong" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] Loi cai Threema: $_" -ForegroundColor Red
    }
}

# --- [4] Telegram ---
Write-Host ""
Write-Host "=== [4/4] Telegram ===" -ForegroundColor Cyan
$tgExe = "$env:APPDATA\Telegram Desktop\Telegram.exe"
if (Test-Path $tgExe) {
    Write-Host "  [SKIP] Telegram da cai" -ForegroundColor Cyan
} else {
    $tg = "$tmp\TelegramSetup.exe"
    Download "Telegram 6.9.3" "https://github.com/telegramdesktop/tdesktop/releases/download/v6.9.3/tsetup-x64.6.9.3.exe" $tg
    RunInstaller "Telegram" $tg "/VERYSILENT /NORESTART"
}

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - O Clay VPS" -ForegroundColor Green
Write-Host "  1. VipTalk 1.12.142" -ForegroundColor White
Write-Host "  2. Signal 8.16.0" -ForegroundColor White
Write-Host "  3. Threema 2.0-beta62" -ForegroundColor White
Write-Host "  4. Telegram 6.9.3" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
pause
