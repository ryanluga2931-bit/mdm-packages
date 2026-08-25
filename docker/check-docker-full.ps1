# ===== CHECK ALL - moi thu anh huong Docker =====
Write-Host "`n===== CHECK DOCKER FULL =====" -ForegroundColor Cyan
$hv = (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
Write-Host "HypervisorPresent    : $hv"
# DEVICE GUARD / CREDENTIAL GUARD (thu pham chinh - chiem hypervisor)
$dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue
if ($dg) {
    $svcRun = $dg.SecurityServicesRunning
    Write-Host "VBS Running          : $($dg.VirtualizationBasedSecurityStatus)  (2=running)"
    Write-Host "SecurityServicesRun  : $($svcRun -join ',')  (1=CredentialGuard,2=HVCI)"
    if ($svcRun -contains 1) { Write-Host ">>> CREDENTIAL GUARD DANG CHAY = CHIEM hypervisor -> Docker KHONG chay duoc!" -ForegroundColor Red }
}
# WSL status
Write-Host "`n--- WSL ---"
wsl --status 2>&1 | Out-String | Write-Host
wsl --list --verbose 2>&1 | Out-String | Write-Host
# Docker service
$ds = Get-Service com.docker.service -EA SilentlyContinue
Write-Host "Docker service       : $(if($ds){$ds.Status}else{'chua cai'})"
Write-Host "`n===== KET LUAN =====" -ForegroundColor Cyan
if ($dg -and ($dg.SecurityServicesRunning -contains 1)) {
    Write-Host ">>> Docker loi vi CREDENTIAL GUARD. Chay disable-credguard.ps1 (admin) roi RESTART." -ForegroundColor Yellow
} elseif ($hv) {
    Write-Host ">>> Hypervisor OK, khong co CredGuard. Neu Docker loi -> thu 'wsl --update' + restart Docker." -ForegroundColor Green
}
