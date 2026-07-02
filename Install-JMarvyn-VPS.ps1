# ============================================================
# Cai app cho VPS J Marvyn
# Signal, VipTalk, UniKey
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\JMarvynInstall"
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
Write-Host "=== [1/3] UniKey ===" -ForegroundColor Cyan
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
Write-Host "=== [2/3] VipTalk ===" -ForegroundColor Cyan
if (CheckReg "VipTalk") {
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VipTalk.exe"
    Download "VipTalk 1.12.142" "$ghBase/VipTalk-Setup-1.12.142.exe" $f
    RunInstaller "VipTalk" $f "/S"
}

# --- [3] Signal ---
Write-Host ""
Write-Host "=== [3/3] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $f
    RunInstaller "Signal" $f "--silent"
}

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - J Marvyn VPS" -ForegroundColor Green
Write-Host "  1. UniKey" -ForegroundColor White
Write-Host "  2. VipTalk 1.12.142" -ForegroundColor White
Write-Host "  3. Signal 8.16.0" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
pause
