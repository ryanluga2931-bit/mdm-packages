# ============================================================
# Check-And-CleanDisk.ps1
# 1) BAO CAO: o dia + top thu muc ngon dung luong
# 2) DON RAC an toan: temp/cache/update cu/recycle bin/log
#    (KHONG dung app + data user + Documents)
# ============================================================

# Auto self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
$ErrorActionPreference = "SilentlyContinue"

function GB($bytes) { return "{0:N1} GB" -f ($bytes / 1GB) }
function MB($bytes) { return "{0:N0} MB" -f ($bytes / 1MB) }
function FolderSize($path) {
    if (-not (Test-Path $path)) { return 0 }
    return (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
}

# ============================================================
# [1] Bao cao o dia
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " O DIA" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $pct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100)
    Write-Host ("  {0}  {1} trong / {2} tong  ({3}% day)" -f $_.DeviceID, (GB $_.FreeSpace), (GB $_.Size), $pct) -ForegroundColor White
}

# ============================================================
# [2] Top thu muc ngon dung luong tren C
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " CHO NAO NGON DUNG LUONG (C:)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  (dang tinh, cho xiu...)" -ForegroundColor DarkGray

$checkDirs = @(
    "C:\Windows\Installer",
    "C:\Windows\SoftwareDistribution\Download",
    "C:\Windows.old",
    "C:\ProgramData",
    "C:\Program Files",
    "C:\Program Files (x86)"
)
# Moi user profile
Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue | ForEach-Object { $checkDirs += $_.FullName }

$sizes = @()
foreach ($d in ($checkDirs | Select-Object -Unique)) {
    if (Test-Path $d) {
        $s = FolderSize $d
        if ($s -gt 200MB) { $sizes += [PSCustomObject]@{ Path = $d; Bytes = $s } }
    }
}
$sizes | Sort-Object Bytes -Descending | Select-Object -First 15 | ForEach-Object {
    Write-Host ("  {0}  {1}" -f (GB $_.Bytes).PadLeft(9), $_.Path) -ForegroundColor White
}

# ============================================================
# [3] Tinh RAC AN TOAN co the don
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " RAC AN TOAN co the don:" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow

$junk = @()
# Temp cua tung user
Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue | ForEach-Object {
    $junk += "$($_.FullName)\AppData\Local\Temp"
}
$junk += @(
    "C:\Windows\Temp",
    "C:\Windows\SoftwareDistribution\Download",   # Windows Update cache (tu tai lai)
    "C:\Windows\Prefetch",
    "$env:SystemRoot\Logs\CBS"
)
# Cache trinh duyet cua tung user (cache thoi, KHONG dung dang nhap)
Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue | ForEach-Object {
    $u = $_.FullName
    $junk += "$u\AppData\Local\Google\Chrome\User Data\Default\Cache"
    $junk += "$u\AppData\Local\Google\Chrome\User Data\Default\Code Cache"
    $junk += "$u\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
    $junk += "$u\AppData\Local\Microsoft\Windows\INetCache"
}

$junkFound = @()
$totalJunk = 0
foreach ($j in ($junk | Select-Object -Unique)) {
    if (Test-Path $j) {
        $s = FolderSize $j
        if ($s -gt 0) {
            $junkFound += [PSCustomObject]@{ Path = $j; Bytes = $s }
            $totalJunk += $s
        }
    }
}
foreach ($item in ($junkFound | Sort-Object Bytes -Descending)) {
    Write-Host ("  [X] {0}  {1}" -f (MB $item.Bytes).PadLeft(10), $item.Path) -ForegroundColor Gray
}
Write-Host ""
Write-Host ("  TONG rac co the don: ~{0}" -f (GB $totalJunk)) -ForegroundColor Yellow

# Windows.old (neu co - thuong rat nang)
if (Test-Path "C:\Windows.old") {
    Write-Host ("  [!] C:\Windows.old ton tai ({0}) - la ban Windows cu, xoa an toan neu khong roll-back" -f (GB (FolderSize "C:\Windows.old"))) -ForegroundColor Yellow
}

# ============================================================
# [4] Hoi xac nhan don
# ============================================================
Write-Host ""
Write-Host "  >>> Chi don CACHE/TEMP/update cu. KHONG dung app, Documents, dang nhap." -ForegroundColor Green
Write-Host ""
$confirm = Read-Host "  Go 'YES' de DON rac, hoac Enter de chi xem (khong don)"
if ($confirm -ne "YES") {
    Write-Host "  Chi xem - khong don gi." -ForegroundColor Cyan
    Write-Host ""; pause; exit
}

# ============================================================
# [5] Don
# ============================================================
Write-Host ""
Write-Host "=== Dang don... ===" -ForegroundColor Cyan
foreach ($item in $junkFound) {
    # Xoa NOI DUNG ben trong, giu thu muc (temp/cache can folder de app chay)
    Get-ChildItem $item.Path -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
    Write-Host "  [OK] Don: $($item.Path)" -ForegroundColor Green
}

# Recycle Bin
Clear-RecycleBin -Force -EA SilentlyContinue
Write-Host "  [OK] Don Recycle Bin" -ForegroundColor Green

# Windows Update cleanup qua DISM (don component store cu)
Write-Host "  [.] DISM cleanup component store (cho vai phut)..." -ForegroundColor Yellow
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /Quiet 2>&1 | Out-Null
Write-Host "  [OK] DISM cleanup xong" -ForegroundColor Green

# ============================================================
# [6] Bao cao lai o dia sau khi don
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " O DIA SAU KHI DON" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $pct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100)
    Write-Host ("  {0}  {1} trong / {2} tong  ({3}% day)" -f $_.DeviceID, (GB $_.FreeSpace), (GB $_.Size), $pct) -ForegroundColor Green
}
Write-Host ""
Write-Host "  [!] Con day nua? Xoa Windows.old (neu co) + go app khong dung." -ForegroundColor Yellow
Write-Host ""
pause
