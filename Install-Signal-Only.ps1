# ============================================================
# Cai Signal (chi 1 app)
# ============================================================

# Auto self-elevate neu chua phai admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\SignalInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host ""
Write-Host "=== Cai Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    Write-Host "  [.] Dang tai Signal..." -ForegroundColor Yellow
    $curlExe = "$env:SystemRoot\System32\curl.exe"
    if (Test-Path $curlExe) { & $curlExe -L -s -o $f "$ghBase/Signal-8.16.0-x64.exe" }
    else {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest "$ghBase/Signal-8.16.0-x64.exe" -OutFile $f -UseBasicParsing
    }
    if ((Test-Path $f) -and (Get-Item $f).Length -gt 100KB) {
        Write-Host "  [OK] Tai xong ($([math]::Round((Get-Item $f).Length/1MB,1)) MB)" -ForegroundColor Green
        Write-Host "  [.] Dang cai..." -ForegroundColor Yellow
        $p = Start-Process $f -ArgumentList "--silent" -Wait -PassThru
        if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010) {
            Write-Host "  [OK] Signal cai xong" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Signal exit code: $($p.ExitCode)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [FAIL] Tai Signal that bai" -ForegroundColor Red
    }
}

# Shortcut Desktop
$publicLnk = "$env:PUBLIC\Desktop\Signal.lnk"
if ((Test-Path $sigExe) -and -not (Test-Path $publicLnk)) {
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($publicLnk)
    $sc.TargetPath = $sigExe
    $sc.Save()
    Write-Host "  [OK] Shortcut 'Signal' tao xong" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - Signal" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
