# ===== TAT CREDENTIAL GUARD + VBS (nhuong hypervisor cho Docker) =====
# Chay QUYEN ADMIN roi RESTART
$ErrorActionPreference="Continue"
Write-Host "Tat Credential Guard + VBS..." -ForegroundColor Cyan
# 1. Registry tat Device Guard / Credential Guard
$p1="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
New-Item $p1 -Force | Out-Null
Set-ItemProperty $p1 "EnableVirtualizationBasedSecurity" 0 -Type DWord
Set-ItemProperty $p1 "RequirePlatformSecurityFeatures" 0 -Type DWord
$p2="HKLM:\SYSTEM\CurrentControlSet\Control\LSA"
Set-ItemProperty $p2 "LsaCfgFlags" 0 -Type DWord -EA SilentlyContinue
$p3="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard"
New-Item $p3 -Force | Out-Null
Set-ItemProperty $p3 "Enabled" 0 -Type DWord
# 2. Tat qua bcdedit
bcdedit /set vsmlaunchtype off | Out-Null
# 3. Xoa EFI vars Credential Guard (neu co tool)
Write-Host "`nXONG. PHAI RESTART may (co the man hinh boot hoi confirm - bam phim theo huong dan)." -ForegroundColor Green
Write-Host "Sau restart: mo Docker Desktop -> se chay." -ForegroundColor Green
Write-Host "Restart tay: shutdown /r /t 5" -ForegroundColor Yellow
