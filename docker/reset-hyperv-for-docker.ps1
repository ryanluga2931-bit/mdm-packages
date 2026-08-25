# ===== BAT LAI Hyper-V (DG tool vua tat) + set cho Docker =====
# Chay QUYEN ADMIN. DG readiness tool da tat Hyper-V+IOMMU, phai bat lai cho Docker.
$ErrorActionPreference="Continue"
Write-Host "===== RESET HYPER-V CHO DOCKER =====" -ForegroundColor Cyan

Write-Host "1. Bat lai TAT CA feature Hyper-V + WSL..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-Hypervisor /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

Write-Host "2. Ep hypervisor auto (DG tool co the da doi)..." -ForegroundColor Cyan
bcdedit /set hypervisorlaunchtype auto | Out-Null

Write-Host "3. Trang thai feature sau khi bat:" -ForegroundColor Cyan
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor,VirtualMachinePlatform,Microsoft-Windows-Subsystem-Linux | Select FeatureName,State | Format-Table

Write-Host "===== XONG =====" -ForegroundColor Cyan
Write-Host ">>> RESTART: shutdown /r /t 5" -ForegroundColor Yellow
Write-Host ">>> Sau restart TEST: wsl --install -d Ubuntu" -ForegroundColor Green
Write-Host ">>> Cai duoc = OK. Van HCS_E_HYPERV_NOT_INSTALLED = Azure khong cho nested virt (nho SA)." -ForegroundColor Magenta
