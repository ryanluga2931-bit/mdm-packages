# ============================================================
# Clear-OldUserData.ps1
# Don DATA cu con sot khi ban giao VPS (user cu da xoa, app giu lai)
# QUET TAT CA user tren may.
#
# AN TOAN: LIET KE truoc -> HOI xac nhan -> moi xoa.
# GIU: app da cai (Program Files, Windows). XOA: data/dang nhap/file ca nhan.
# ============================================================

# Auto self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# Xac dinh cac profile user THAT (bo profile he thong)
# ============================================================
$systemProfiles = @("Public","Default","Default User","All Users",
                    "defaultuser0","defaultuser1","WDAGUtilityAccount")
$currentUser = $env:USERNAME

$userDirs = Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue |
    Where-Object { $systemProfiles -notcontains $_.Name }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " CAC PROFILE USER TIM THAY tren C:\Users" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
foreach ($d in $userDirs) {
    $marker = if ($d.Name -eq $currentUser) { "  <-- DANG DANG NHAP (giu)" } else { "" }
    $size = "{0:N0} MB" -f ((Get-ChildItem $d.FullName -Recurse -EA SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)
    Write-Host "  $($d.Name.PadRight(20)) $size $marker" -ForegroundColor White
}

# ============================================================
# Danh sach cac muc DATA se xoa trong TUNG profile
# (chi data/dang nhap/cache/file ca nhan - KHONG dung app)
# ============================================================
$dataTargets = @(
    # --- App messaging: xoa dang nhap + tin nhan cu ---
    "AppData\Roaming\Signal",
    "AppData\Roaming\Telegram Desktop\tdata",
    "AppData\Roaming\VipTalk",
    "AppData\Roaming\Threema",
    # --- Browser: xoa profile + dang nhap + lich su + cookie ---
    "AppData\Local\Google\Chrome\User Data",
    "AppData\Roaming\Mozilla\Firefox\Profiles",
    "AppData\Roaming\Opera Software",
    "AppData\Local\Arc\User Data",
    # --- AdsPower / anti-detect: profile trinh duyet ---
    "AppData\Roaming\adspower_global",
    "AppData\Local\adspower_global\cache",
    # --- Dev / cong cu ---
    "AppData\Roaming\Code\User\globalStorage",
    "AppData\Roaming\Postman",
    "AppData\Roaming\Claude",
    "AppData\Roaming\ToolManager",
    ".ssh",
    ".aws",
    ".config\gh",
    # --- File ca nhan nguoi cu ---
    "Downloads",
    "Documents",
    "Desktop",
    "Pictures",
    "Videos",
    "Music",
    # --- OneDrive / Google Drive cache ---
    "AppData\Local\Microsoft\OneDrive",
    "AppData\Local\Google\DriveFS"
)

# Liet ke thuc te cai gi se xoa
$toDelete = @()
foreach ($d in $userDirs) {
    foreach ($t in $dataTargets) {
        $p = Join-Path $d.FullName $t
        if (Test-Path $p) {
            $sz = "{0:N0} MB" -f ((Get-ChildItem $p -Recurse -EA SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)
            $toDelete += [PSCustomObject]@{ Path = $p; Size = $sz }
        }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " SE XOA $($toDelete.Count) muc data (GIU nguyen app):" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
if ($toDelete.Count -eq 0) {
    Write-Host "  (Khong tim thay data cu nao de xoa - may da sach)" -ForegroundColor Green
    Write-Host ""
    pause
    exit
}
foreach ($item in $toDelete) {
    Write-Host "  [X] $($item.Size.PadLeft(10))  $($item.Path)" -ForegroundColor Gray
}

# ============================================================
# HOI XAC NHAN - go dung chu YES moi xoa
# ============================================================
Write-Host ""
Write-Host "  >>> Cac muc tren se bi XOA VINH VIEN (khong khoi phuc duoc)." -ForegroundColor Red
Write-Host "  >>> App da cai + Windows KHONG bi dung toi." -ForegroundColor Green
Write-Host ""
$confirm = Read-Host "  Go dung 'YES' (in hoa) de xac nhan xoa, hoac Enter de HUY"

if ($confirm -ne "YES") {
    Write-Host ""
    Write-Host "  Da HUY - khong xoa gi ca." -ForegroundColor Cyan
    Write-Host ""
    pause
    exit
}

# ============================================================
# Thuc hien xoa
# ============================================================
Write-Host ""
Write-Host "=== Dang xoa... ===" -ForegroundColor Cyan
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

# ============================================================
# Don them: Recycle Bin + temp
# ============================================================
Write-Host ""
Write-Host "=== Don Recycle Bin + Temp ===" -ForegroundColor Cyan
Clear-RecycleBin -Force -EA SilentlyContinue
Write-Host "  [OK] Da don Recycle Bin" -ForegroundColor Green
Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue
Write-Host "  [OK] Da don Temp" -ForegroundColor Green

# ============================================================
# Ket qua
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - Don data cu" -ForegroundColor Green
Write-Host "  Xoa OK  : $okCount muc" -ForegroundColor Green
Write-Host "  That bai: $failCount muc (co the dang chay - dong app roi chay lai)" -ForegroundColor Yellow
Write-Host "  App da cai + Windows: NGUYEN VEN" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
