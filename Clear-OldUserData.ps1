# ============================================================
# Clear-OldUserData.ps1
# Don DATA cu cua MOT user cu the (khi ban giao VPS).
# GIU: app da cai + Windows + cac user khac.
#
# AN TOAN: HOI chon user -> LIET KE -> HOI xac nhan -> moi xoa.
# ============================================================

# Auto self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "SilentlyContinue"

$systemProfiles = @("Public","Default","Default User","All Users",
                    "defaultuser0","defaultuser1","WDAGUtilityAccount")

$userDirs = Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue |
    Where-Object { $systemProfiles -notcontains $_.Name }

# ============================================================
# CHON USER can don (chi 1 user)
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " CAC PROFILE USER tren C:\Users" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
$idx = 0
$menu = @{}
foreach ($d in $userDirs) {
    $idx++
    $menu[$idx] = $d
    $size = "{0:N0} MB" -f ((Get-ChildItem $d.FullName -Recurse -EA SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)
    Write-Host "  [$idx] $($d.Name.PadRight(20)) $size" -ForegroundColor White
}

Write-Host ""
$pick = Read-Host "  Nhap SO thu tu user CAN DON DATA (vd: 3), hoac Enter de HUY"
if (-not $pick -or -not $menu.ContainsKey([int]$pick)) {
    Write-Host "  Da HUY - khong xoa gi." -ForegroundColor Cyan
    Write-Host ""; pause; exit
}
$targetUser = $menu[[int]$pick]
Write-Host ""
Write-Host "  >>> Da chon: $($targetUser.Name)" -ForegroundColor Yellow

# ============================================================
# Cac muc DATA se xoa trong profile user do
# ============================================================
$dataTargets = @(
    "AppData\Roaming\Signal",
    "AppData\Roaming\Telegram Desktop\tdata",
    "AppData\Roaming\VipTalk",
    "AppData\Roaming\Threema",
    "AppData\Local\Google\Chrome\User Data",
    "AppData\Roaming\Mozilla\Firefox\Profiles",
    "AppData\Roaming\Opera Software",
    "AppData\Local\Arc\User Data",
    "AppData\Roaming\adspower_global",
    "AppData\Local\adspower_global\cache",
    "AppData\Roaming\Code\User\globalStorage",
    "AppData\Roaming\Postman",
    "AppData\Roaming\Claude",
    "AppData\Roaming\ToolManager",
    ".ssh",
    ".aws",
    ".config\gh",
    "Downloads",
    "Documents",
    "Desktop",
    "Pictures",
    "Videos",
    "Music",
    "AppData\Local\Microsoft\OneDrive",
    "AppData\Local\Google\DriveFS"
)

$toDelete = @()
foreach ($t in $dataTargets) {
    $p = Join-Path $targetUser.FullName $t
    if (Test-Path $p) {
        $sz = "{0:N0} MB" -f ((Get-ChildItem $p -Recurse -EA SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)
        $toDelete += [PSCustomObject]@{ Path = $p; Size = $sz }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " SE XOA $($toDelete.Count) muc data cua '$($targetUser.Name)':" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
if ($toDelete.Count -eq 0) {
    Write-Host "  (Khong co data cu nao - user nay da sach)" -ForegroundColor Green
    Write-Host ""; pause; exit
}
foreach ($item in $toDelete) {
    Write-Host "  [X] $($item.Size.PadLeft(10))  $($item.Path)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  >>> CHI dung toi user '$($targetUser.Name)'. Cac user khac + app: KHONG dung." -ForegroundColor Green
Write-Host "  >>> Xoa VINH VIEN, khong khoi phuc duoc." -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "  Go dung 'YES' (in hoa) de xac nhan xoa, hoac Enter de HUY"

if ($confirm -ne "YES") {
    Write-Host "  Da HUY - khong xoa gi." -ForegroundColor Cyan
    Write-Host ""; pause; exit
}

# ============================================================
# Thuc hien xoa
# ============================================================
Write-Host ""
Write-Host "=== Dang xoa data cua $($targetUser.Name)... ===" -ForegroundColor Cyan
$okCount = 0; $failCount = 0
foreach ($item in $toDelete) {
    try {
        Remove-Item $item.Path -Recurse -Force -EA Stop
        Write-Host "  [OK]  $($item.Path)" -ForegroundColor Green
        $okCount++
    } catch {
        Write-Host "  [FAIL] $($item.Path) - $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - Don data '$($targetUser.Name)'" -ForegroundColor Green
Write-Host "  Xoa OK  : $okCount muc" -ForegroundColor Green
Write-Host "  That bai: $failCount muc (dong app roi chay lai)" -ForegroundColor Yellow
Write-Host "  Cac user khac + app: NGUYEN VEN" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
