# ===== CAI LAI DOCKER DESKTOP FULL (tai tu GitHub) =====
# Chay QUYEN ADMIN. Ghi log ra C:\docker-install-log.txt de doc lai.
$ErrorActionPreference = "Continue"
$LOG = "C:\docker-install-log.txt"
$REL = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/docker-v1"
function Log($m,$c="White"){ Write-Host $m -ForegroundColor $c; Add-Content $LOG "$(Get-Date -Format 'HH:mm:ss') $m" }
Set-Content $LOG "=== Docker install log ==="

Log "1. Tat Docker dang chay..." Cyan
Get-Process "*docker*","com.docker*" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue

Log "2. Bat feature ao hoa..." Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:Containers /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart | Out-Null

Log "3. Bat hypervisor launch (QUAN TRONG)..." Cyan
bcdedit /set hypervisorlaunchtype auto | Out-Null

Log "4. Tai + cai WSL2 kernel tu GitHub..." Cyan
$wsl = "$env:TEMP\wsl_update_x64.msi"
try { Invoke-WebRequest "$REL/wsl_update_x64.msi" -OutFile $wsl -UseBasicParsing; Start-Process msiexec.exe -ArgumentList "/i `"$wsl`" /quiet /norestart" -Wait; Log "   WSL2 kernel: OK" Green }
catch { Log "   WSL2 kernel LOI: $_" Red }

Log "5. Tai Docker Desktop tu GitHub (~630MB)..." Cyan
$dk = "$env:TEMP\DockerDesktopInstaller.exe"
try { Invoke-WebRequest "$REL/DockerDesktopInstaller.exe" -OutFile $dk -UseBasicParsing; Log "   Tai xong: $((Get-Item $dk).Length/1MB -as [int])MB" Green }
catch { Log "   Tai Docker LOI: $_" Red }

Log "6. Cai Docker Desktop (WSL2 backend)..." Cyan
$p = Start-Process $dk -ArgumentList "install","--quiet","--accept-license","--backend=wsl-2" -Wait -PassThru
Log "   Installer exit code: $($p.ExitCode)  (0=OK)" $(if($p.ExitCode -eq 0){'Green'}else{'Red'})

Log "`n===== XONG =====" Cyan
Log "Log luu tai: $LOG" Yellow
Log "PHAI RESTART MAY roi mo Docker Desktop." Yellow
Write-Host "`n>>> KHONG tu restart. Doc ket qua o tren + file $LOG" -ForegroundColor Magenta
Write-Host ">>> Khi nao san sang, RESTART TAY: shutdown /r /t 5" -ForegroundColor Magenta
