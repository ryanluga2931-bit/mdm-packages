# ===== TAT CREDENTIAL GUARD + VBS TRIET DE (ca UEFI) =====
# Chay QUYEN ADMIN roi RESTART. Docker/WSL2 can hypervisor -> phai tat VBS het.
$ErrorActionPreference="Continue"
Write-Host "===== KILL CREDENTIAL GUARD + VBS (HARD) =====" -ForegroundColor Cyan

Write-Host "Trang thai TRUOC:" -ForegroundColor Yellow
$dg=Get-CimInstance Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue
Write-Host "  VBS status: $($dg.VirtualizationBasedSecurityStatus)  SecurityServices: $($dg.SecurityServicesRunning -join ',')"

Write-Host "1. Tat qua Registry (VBS + CredGuard + HVCI)..." -ForegroundColor Cyan
$dgp="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
New-Item $dgp -Force|Out-Null
Set-ItemProperty $dgp "EnableVirtualizationBasedSecurity" 0 -Type DWord
Set-ItemProperty $dgp "RequirePlatformSecurityFeatures" 0 -Type DWord
$cg="$dgp\Scenarios\CredentialGuard"; New-Item $cg -Force|Out-Null
Set-ItemProperty $cg "Enabled" 0 -Type DWord
$hvci="$dgp\Scenarios\HypervisorEnforcedCodeIntegrity"; New-Item $hvci -Force|Out-Null
Set-ItemProperty $hvci "Enabled" 0 -Type DWord
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" "LsaCfgFlags" 0 -Type DWord -EA SilentlyContinue

Write-Host "2. Tat qua bcdedit (vsm + hypervisor giu auto cho Docker)..." -ForegroundColor Cyan
bcdedit /set vsmlaunchtype off | Out-Null
bcdedit /set hypervisorlaunchtype auto | Out-Null

Write-Host "3. Xoa Credential Guard EFI variable (mountvol)..." -ForegroundColor Cyan
# tai DG Readiness tool tu Microsoft de xoa UEFI lock
$tool="$env:TEMP\DG_Readiness.zip"
try {
  Invoke-WebRequest "https://download.microsoft.com/download/B/D/8/BD821B1F-05F2-4A7E-AA03-DF6C4F687B07/dgreadiness_v3.6.zip" -OutFile $tool -UseBasicParsing
  Expand-Archive $tool "$env:TEMP\DG" -Force
  $ps=Get-ChildItem "$env:TEMP\DG" -Recurse -Filter "DG_Readiness_Tool*.ps1" | Select -First 1
  if($ps){ & $ps.FullName -Disable -AutoReboot:$false 2>&1 | Out-String | Write-Host }
} catch { Write-Host "   (khong tai duoc DG tool, dung registry+bcdedit la du trong da so ca)" -ForegroundColor Yellow }

Write-Host "`n===== XONG =====" -ForegroundColor Cyan
Write-Host ">>> BAT BUOC RESTART: shutdown /r /t 5" -ForegroundColor Yellow
Write-Host ">>> Luc boot: NEU hien man xanh hoi 'disable Credential Guard' -> bam phim theo huong dan (thuong F3/Del)" -ForegroundColor Magenta
Write-Host ">>> Sau restart: chay 'wsl --install -d Ubuntu' -> neu cai duoc = da thong -> Docker chay" -ForegroundColor Green
