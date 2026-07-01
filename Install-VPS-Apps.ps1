# ============================================================
# Cai app tren VPS / may Windows
# Tai tu GitHub: VipTalk, UniKey, Signal, CapCut, Dolphin Anty
# ============================================================

$ErrorActionPreference = "Stop"
$baseUrl = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\AppInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download($name, $url, $out) {
    Write-Host "[.] Dang tai $name..." -ForegroundColor Yellow
    Invoke-WebRequest $url -OutFile $out -UseBasicParsing
    Write-Host "[OK] Tai xong: $name" -ForegroundColor Green
}

function Run($name, $path, $argList) {
    Write-Host "[.] Dang cai $name..." -ForegroundColor Yellow
    $p = Start-Process $path -ArgumentList $argList -Wait -PassThru
    if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010) {
        Write-Host "[OK] Cai xong: $name" -ForegroundColor Green
    } else {
        Write-Host "[WARN] $name exit code: $($p.ExitCode)" -ForegroundColor Yellow
    }
}

# --- VipTalk ---
Write-Host ""
Write-Host "=== [1/5] VipTalk ===" -ForegroundColor Cyan
$vt = "$tmp\VipTalk-Setup.exe"
Download "VipTalk 1.12.142" "$baseUrl/VipTalk-Setup-1.12.142.exe" $vt
Run "VipTalk" $vt "/S"

# --- UniKey ---
Write-Host ""
Write-Host "=== [2/5] UniKey ===" -ForegroundColor Cyan
$ukZip = "$tmp\UniKey.zip"
Download "UniKey" "$baseUrl/UniKey-Windows.zip" $ukZip
$ukDir = "C:\Program Files\UniKey"
Expand-Archive $ukZip -DestinationPath $ukDir -Force
$shell = New-Object -ComObject WScript.Shell
$sc = $shell.CreateShortcut("$env:PUBLIC\Desktop\UniKey.lnk")
$sc.TargetPath = "$ukDir\UniKey\UniKeyNT.exe"
$sc.Save()
Write-Host "[OK] UniKey giai nen + shortcut xong" -ForegroundColor Green

# --- Signal ---
Write-Host ""
Write-Host "=== [3/5] Signal ===" -ForegroundColor Cyan
$sig = "$tmp\Signal-Setup.exe"
Download "Signal 8.16.0" "$baseUrl/Signal-8.16.0-x64.exe" $sig
Run "Signal" $sig "--silent"

# --- CapCut ---
Write-Host ""
Write-Host "=== [4/5] CapCut ===" -ForegroundColor Cyan
$cc = "$tmp\CapCut-Setup.exe"
Download "CapCut 8.9.1" "$baseUrl/CapCut-8.9.1-Setup.exe" $cc
Run "CapCut" $cc "/S"

# --- Dolphin Anty ---
Write-Host ""
Write-Host "=== [5/5] Dolphin Anty ===" -ForegroundColor Cyan
$da = "$tmp\DolphinAnty-Setup.exe"
Download "Dolphin Anty" "$baseUrl/DolphinAnty-latest.exe" $da
Run "Dolphin Anty" $da "--silent"

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - Da cai 5 app!" -ForegroundColor Green
Write-Host "  1. VipTalk 1.12.142" -ForegroundColor White
Write-Host "  2. UniKey" -ForegroundColor White
Write-Host "  3. Signal 8.16.0" -ForegroundColor White
Write-Host "  4. CapCut 8.9.1" -ForegroundColor White
Write-Host "  5. Dolphin Anty" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
pause
