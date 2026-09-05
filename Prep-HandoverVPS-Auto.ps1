# ============================================================
# Prep-HandoverVPS-Auto.ps1
# XOA THANG - khong hoi YES. Tu tat app truoc de khong ket file.
# GIU: app da cai + Windows + account 'shunt'. XOA: data cu + rac + sach o D.
# ============================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
$ErrorActionPreference = "SilentlyContinue"
function GB($b){ "{0:N1} GB" -f ($b/1GB) }

$systemProfiles = @("Public","Default","Default User","All Users","defaultuser0","defaultuser1","WDAGUtilityAccount")
$currentUser = $env:USERNAME

# ============================================================
# [0] TAT cac app + service co the giu file (tranh ket khi xoa)
# ============================================================
Write-Host ""
Write-Host "=== Tat app dang chay (de xoa duoc)... ===" -ForegroundColor Cyan

# Dung Docker Desktop + service + engine (giu D:\Docker 67GB nen phai tat)
Write-Host "  [.] Tat Docker..." -ForegroundColor Yellow
Stop-Process -Name "Docker Desktop" -Force -EA SilentlyContinue
Stop-Service -Name "com.docker.service" -Force -EA SilentlyContinue
Stop-Process -Name "com.docker.backend","dockerd","vpnkit","com.docker.build" -Force -EA SilentlyContinue
wsl --shutdown 2>&1 | Out-Null

# Dung cac app khac
$killApps = @("chrome","signal","telegram","viptalk","threema","AdsPower Global",
              "adspower_global","Code","Postman","opera","firefox","claude","msedge","Docker")
foreach ($a in $killApps) { Stop-Process -Name $a -Force -EA SilentlyContinue }
Start-Sleep -Seconds 3
Write-Host "  [OK] Da tat app" -ForegroundColor Green

# ============================================================
# [1] Gom danh sach can xoa (giong ban da quet ra)
# ============================================================
$targets = @()

# --- O D: xoa sach (tru thu muc he thong ngam) ---
if (Test-Path "D:\") {
    Get-ChildItem "D:\" -Force -EA SilentlyContinue |
        Where-Object { $_.Name -notin @('$RECYCLE.BIN','System Volume Information') } |
        ForEach-Object { $targets += $_.FullName }
}

# --- Profile user CU (khac shunt) - xoa han ca folder ---
Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue |
    Where-Object { $systemProfiles -notcontains $_.Name -and $_.Name -ne $currentUser } |
    ForEach-Object { $targets += $_.FullName }

# --- Data ca nhan + dang nhap cua user hien tai (shunt) ---
$me = "C:\Users\$currentUser"
$targets += @(
    "$me\Downloads","$me\Documents","$me\Desktop","$me\Pictures","$me\Videos","$me\Music",
    "$me\AppData\Roaming\Signal","$me\AppData\Roaming\Telegram Desktop\tdata",
    "$me\AppData\Roaming\VipTalk","$me\AppData\Roaming\Threema",
    "$me\AppData\Local\Google\Chrome\User Data","$me\AppData\Roaming\adspower_global",
    "$me\AppData\Roaming\Claude","$me\.ssh"
)

# ============================================================
# [2] XOA (khong hoi)
# ============================================================
Write-Host ""
Write-Host "=== Dang xoa data cu + sach o D... ===" -ForegroundColor Cyan
$ok=0; $fail=0; $freed=0
foreach ($p in ($targets | Select-Object -Unique)) {
    if (-not (Test-Path $p)) { continue }
    $sz = (Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    try {
        Remove-Item $p -Recurse -Force -EA Stop
        Write-Host ("  [OK] {0}  {1}" -f (GB $sz).PadLeft(9), $p) -ForegroundColor Green
        $ok++; $freed += $sz
    } catch {
        # Thu takeown + xoa lai neu ket quyen
        takeown /f "$p" /r /d y 2>&1 | Out-Null
        icacls "$p" /grant "*S-1-5-32-544:F" /t /c 2>&1 | Out-Null
        Remove-Item $p -Recurse -Force -EA SilentlyContinue
        if (-not (Test-Path $p)) {
            Write-Host ("  [OK] {0}  {1} (sau takeown)" -f (GB $sz).PadLeft(9), $p) -ForegroundColor Green
            $ok++; $freed += $sz
        } else {
            Write-Host "  [FAIL] $p - $($_.Exception.Message)" -ForegroundColor Red; $fail++
        }
    }
}

# ============================================================
# [3] Rac he thong
# ============================================================
Write-Host ""
Write-Host "=== Don rac he thong... ===" -ForegroundColor Cyan
$junk = @("C:\Windows\Temp","C:\Windows\SoftwareDistribution\Download","C:\Windows\Prefetch")
Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue | ForEach-Object { $junk += "$($_.FullName)\AppData\Local\Temp" }
foreach ($j in ($junk | Select-Object -Unique)) {
    if (Test-Path $j) { Get-ChildItem $j -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue }
}
Clear-RecycleBin -Force -EA SilentlyContinue
Write-Host "  [OK] Da don rac + Recycle Bin" -ForegroundColor Green
Write-Host "  [.] DISM cleanup (cho vai phut)..." -ForegroundColor Yellow
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /Quiet 2>&1 | Out-Null
Write-Host "  [OK] DISM xong" -ForegroundColor Green

# ============================================================
# [4] Bao cao
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " O DIA SAU KHI DON" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $pct=[math]::Round(($_.Size-$_.FreeSpace)/$_.Size*100)
    Write-Host ("  {0}  {1} trong / {2} tong  ({3}% day)" -f $_.DeviceID,(GB $_.FreeSpace),(GB $_.Size),$pct) -ForegroundColor Green
}
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " XONG - VPS san sang giao S Hunt" -ForegroundColor Green
Write-Host ("  Xoa OK: {0} muc | Giai phong: {1} | That bai: {2}" -f $ok, (GB $freed), $fail) -ForegroundColor White
Write-Host "  App da cai + Windows: NGUYEN VEN" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Xong. Cua so tu dong dong sau 30 giay..." -ForegroundColor Gray
Start-Sleep -Seconds 30
