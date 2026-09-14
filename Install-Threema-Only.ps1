# ============================================================
# Cai Threema (chi 1 app)
# ============================================================

# Auto self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Continue"
$tmp = "$env:TEMP\ThreemaInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function CheckReg($name) {
    return Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*$name*" }
}

Write-Host ""
Write-Host "=== Cai Threema ===" -ForegroundColor Cyan
$thrExe = "$env:LOCALAPPDATA\Programs\Threema\Threema.exe"
if ((CheckReg "Threema") -or (Test-Path $thrExe)) {
    Write-Host "  [SKIP] Threema da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai qua winget..." -ForegroundColor Yellow
    winget install --id Threema.Threema --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Threema cai xong" -ForegroundColor Green }
    else {
        Write-Host "  [.] winget loi, tai truc tiep..." -ForegroundColor Yellow
        $f = "$tmp\ThreemaSetup.exe"
        $curlExe = "$env:SystemRoot\System32\curl.exe"
        if (Test-Path $curlExe) { & $curlExe -L -s -o $f "https://releases.threema.ch/web-electron/v1/release/Threema-Latest.exe" }
        else { Invoke-WebRequest "https://releases.threema.ch/web-electron/v1/release/Threema-Latest.exe" -OutFile $f -UseBasicParsing }
        if ((Test-Path $f) -and (Get-Item $f).Length -gt 100KB) {
            Start-Process $f -ArgumentList "/S" -Wait
            Write-Host "  [OK] Threema cai xong (direct)" -ForegroundColor Green
        } else { Write-Host "  [FAIL] Tai Threema that bai" -ForegroundColor Red }
    }
} else {
    Write-Host "  [.] Khong co winget, tai truc tiep..." -ForegroundColor Yellow
    $f = "$tmp\ThreemaSetup.exe"
    $curlExe = "$env:SystemRoot\System32\curl.exe"
    if (Test-Path $curlExe) { & $curlExe -L -s -o $f "https://releases.threema.ch/web-electron/v1/release/Threema-Latest.exe" }
    else { Invoke-WebRequest "https://releases.threema.ch/web-electron/v1/release/Threema-Latest.exe" -OutFile $f -UseBasicParsing }
    if ((Test-Path $f) -and (Get-Item $f).Length -gt 100KB) {
        Start-Process $f -ArgumentList "/S" -Wait
        Write-Host "  [OK] Threema cai xong (direct)" -ForegroundColor Green
    } else { Write-Host "  [FAIL] Tai Threema that bai" -ForegroundColor Red }
}

# Shortcut Desktop
$publicLnk = "$env:PUBLIC\Desktop\Threema.lnk"
if ((Test-Path $thrExe) -and -not (Test-Path $publicLnk)) {
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($publicLnk); $sc.TargetPath = $thrExe; $sc.Save()
    Write-Host "  [OK] Shortcut 'Threema' tao xong" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - Threema" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
