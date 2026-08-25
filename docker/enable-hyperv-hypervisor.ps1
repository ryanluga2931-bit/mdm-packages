# ===== BAT Hyper-V Hypervisor component (dang bi Disabled) =====
# Chay QUYEN ADMIN
$ErrorActionPreference="Continue"
Write-Host "===== BAT HYPER-V HYPERVISOR =====" -ForegroundColor Cyan

Write-Host "Truoc khi bat:" -ForegroundColor Yellow
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor | Select FeatureName,State | Format-Table

Write-Host "1. Bat Microsoft-Hyper-V-Hypervisor (component con - dang Disabled)..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-Hypervisor /all /norestart
Write-Host ""
Write-Host "2. Bat luon Microsoft-Hyper-V + Management..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-Services /all /norestart | Out-Null

Write-Host "3. Ep hypervisor auto + bat auto start HvHost..." -ForegroundColor Cyan
bcdedit /set hypervisorlaunchtype auto | Out-Null
Set-Service vmcompute -StartupType Automatic -EA SilentlyContinue
Set-Service hns -StartupType Automatic -EA SilentlyContinue

Write-Host "`nSau khi bat:" -ForegroundColor Yellow
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor | Select FeatureName,State | Format-Table

Write-Host "===== XONG =====" -ForegroundColor Cyan
Write-Host ">>> BAT BUOC RESTART: shutdown /r /t 5" -ForegroundColor Yellow
Write-Host ">>> Sau restart: chay 'wsl --install -d Ubuntu' -> neu OK thi Docker se chay." -ForegroundColor Green
Write-Host ">>> Neu sau restart 'Microsoft-Hyper-V-Hypervisor' VAN Disabled = Azure chan nested virt that su." -ForegroundColor Magenta
