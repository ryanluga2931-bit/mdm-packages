# ===== CAI LAI DOCKER DESKTOP FULL (tai tu GitHub) =====
# Chay QUYEN ADMIN
$ErrorActionPreference = "Continue"
$REL = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/docker-v1"

Write-Host "1. Tat Docker dang chay..." -ForegroundColor Cyan
Get-Process "*docker*","com.docker*" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue

Write-Host "2. Bat feature ao hoa..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:Containers /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart | Out-Null

Write-Host "3. Bat hypervisor launch (QUAN TRONG)..." -ForegroundColor Cyan
bcdedit /set hypervisorlaunchtype auto | Out-Null

Write-Host "4. Tai + cai WSL2 kernel tu GitHub..." -ForegroundColor Cyan
$wsl = "$env:TEMP\wsl_update_x64.msi"
Invoke-WebRequest "$REL/wsl_update_x64.msi" -OutFile $wsl
Start-Process msiexec.exe -ArgumentList "/i `"$wsl`" /quiet /norestart" -Wait

Write-Host "5. Tai Docker Desktop tu GitHub (~650MB)..." -ForegroundColor Cyan
$dk = "$env:TEMP\DockerDesktopInstaller.exe"
Invoke-WebRequest "$REL/DockerDesktopInstaller.exe" -OutFile $dk

Write-Host "6. Cai Docker Desktop (WSL2 backend)..." -ForegroundColor Cyan
Start-Process $dk -ArgumentList "install","--quiet","--accept-license","--backend=wsl-2" -Wait

Write-Host "`nXONG! PHAI RESTART may roi mo Docker Desktop." -ForegroundColor Green
Write-Host "May se tu restart sau 15 giay..." -ForegroundColor Yellow
shutdown /r /t 15 /c "Restart de hoan tat cai Docker"
