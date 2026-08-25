# ===== KIEM VPS CO CHAY DUOC DOCKER KHONG =====
Write-Host "`n===== KIEM DIEU KIEN CHAY DOCKER =====" -ForegroundColor Cyan
$hv = (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
Write-Host "1. HypervisorPresent : $hv" -ForegroundColor $(if($hv){'Green'}else{'Red'})
$vt = (Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled
Write-Host "2. VT Firmware       : $vt"
$launch = (bcdedit /enum "{current}" | Select-String "hypervisorlaunchtype")
Write-Host "3. Hypervisor launch : $($launch -replace '\s+',' ')"
foreach($f in @('Microsoft-Windows-Subsystem-Linux','VirtualMachinePlatform','Microsoft-Hyper-V-All')){
    $st = (Get-WindowsOptionalFeature -Online -FeatureName $f -EA SilentlyContinue).State
    Write-Host "4. Feature $f : $st"
}
Write-Host "`n===== KET LUAN =====" -ForegroundColor Cyan
if ($hv -eq $true) {
    Write-Host ">>> VPS CO the chay Docker (hypervisor dang chay). Neu Docker van loi -> cai lai." -ForegroundColor Green
} else {
    Write-Host ">>> VPS KHONG chay duoc Docker (hypervisor KHONG chay)." -ForegroundColor Red
    Write-Host "    Fix: doi VM size ben Azure sang loai ho tro nested virt (Dv3/Dsv3/Ev3...)." -ForegroundColor Yellow
}
