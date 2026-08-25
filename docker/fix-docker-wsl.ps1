# ===== FIX DOCKER: dam bao WSL2 backend chay =====
# Chay QUYEN ADMIN
$ErrorActionPreference="Continue"
Write-Host "===== FIX DOCKER WSL2 =====" -ForegroundColor Cyan

Write-Host "1. Tat Docker..." -ForegroundColor Cyan
Get-Process "*docker*","com.docker*" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
Start-Sleep 2

Write-Host "2. Update WSL kernel + set default v2..." -ForegroundColor Cyan
wsl --update 2>&1 | Out-String | Write-Host
wsl --set-default-version 2 2>&1 | Out-String | Write-Host
wsl --status 2>&1 | Out-String | Write-Host

Write-Host "3. Kiem WSL distro (Docker can it nhat 1 distro chay dc)..." -ForegroundColor Cyan
$distros = wsl --list --quiet 2>$null
if (-not $distros) {
    Write-Host "   Chua co distro WSL. Cai Ubuntu..." -ForegroundColor Yellow
    wsl --install -d Ubuntu --no-launch 2>&1 | Out-String | Write-Host
}

Write-Host "4. Ep Docker dung WSL2 backend (sua settings)..." -ForegroundColor Cyan
$cfg = "$env:APPDATA\Docker\settings.json"
if (Test-Path $cfg) {
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    $j.wslEngineEnabled = $true
    $j.useWindowsContainers = $false
    $j | ConvertTo-Json -Depth 20 | Set-Content $cfg
    Write-Host "   Da bat wslEngineEnabled=true" -ForegroundColor Green
} else { Write-Host "   Chua co settings.json (Docker chua chay lan nao) - se tao khi mo Docker" }

Write-Host "5. Kiem hypervisor + VBS lan cuoi..." -ForegroundColor Cyan
Write-Host "   HypervisorPresent: $((Get-CimInstance Win32_ComputerSystem).HypervisorPresent)"
$dg = Get-CimInstance Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue
Write-Host "   VBS status: $($dg.VirtualizationBasedSecurityStatus) (0=off la tot cho Docker; 2=running co the vuong)"

Write-Host "`n===== XONG =====" -ForegroundColor Cyan
Write-Host ">>> RESTART may (shutdown /r /t 5) roi mo Docker Desktop." -ForegroundColor Yellow
Write-Host ">>> Neu VAN loi -> gui em ket qua 'wsl --status' + 'bcdedit /enum {current}'" -ForegroundColor Magenta
