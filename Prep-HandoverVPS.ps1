# ============================================================
# Prep-HandoverVPS.ps1
# Chuan bi VPS SACH de giao nguoi moi (S Hunt).
# GIU: app da cai + Windows. XOA: data nguoi cu + rac + SACH o D.
#
# AN TOAN: liet ke -> go 'YES' -> moi xoa.
# ============================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
$ErrorActionPreference = "SilentlyContinue"
function GB($b){ "{0:N1} GB" -f ($b/1GB) }
function MB($b){ "{0:N0} MB" -f ($b/1MB) }
function DirSize($p){ if(Test-Path $p){(Get-ChildItem $p -Recurse -Force -EA SilentlyContinue|Measure-Object Length -Sum).Sum}else{0} }

$systemProfiles = @("Public","Default","Default User","All Users","defaultuser0","defaultuser1","WDAGUtilityAccount")
$currentUser = $env:USERNAME
$plan = @()   # danh sach se xoa: {Path, Bytes, Type}

# ============================================================
# [A] XOA SACH toan bo o D (tru thu muc he thong ngam)
# ============================================================
if (Test-Path "D:\") {
    Get-ChildItem "D:\" -Force -EA SilentlyContinue |
        Where-Object { $_.Name -notin @('$RECYCLE.BIN','System Volume Information') } |
        ForEach-Object {
            $plan += [PSCustomObject]@{ Path=$_.FullName; Bytes=(DirSize $_.FullName); Type="O D (xoa sach)" }
        }
}

# ============================================================
# [B] XOA data cua tat ca user CU (khong phai user dang dang nhap)
#     -> ca profile folder luon (user cu da xoa account, con folder rac)
# ============================================================
Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue |
    Where-Object { $systemProfiles -notcontains $_.Name -and $_.Name -ne $currentUser } |
    ForEach-Object {
        $plan += [PSCustomObject]@{ Path=$_.FullName; Bytes=(DirSize $_.FullName); Type="Profile user cu" }
    }

# ============================================================
# [C] Data ca nhan cua user DANG dang nhap (Downloads/Docs/Desktop...)
#     + dang nhap app (de S Hunt dang nhap moi)
# ============================================================
$me = "C:\Users\$currentUser"
$myData = @(
    "$me\Downloads","$me\Documents","$me\Desktop","$me\Pictures","$me\Videos","$me\Music",
    "$me\AppData\Roaming\Signal","$me\AppData\Roaming\Telegram Desktop\tdata",
    "$me\AppData\Roaming\VipTalk","$me\AppData\Roaming\Threema",
    "$me\AppData\Local\Google\Chrome\User Data","$me\AppData\Roaming\adspower_global",
    "$me\AppData\Roaming\Claude","$me\.ssh"
)
foreach ($p in $myData) {
    if (Test-Path $p) { $plan += [PSCustomObject]@{ Path=$p; Bytes=(DirSize $p); Type="Data user hien tai" } }
}

# ============================================================
# [D] Rac he thong (temp/cache/update)
# ============================================================
$junk = @("C:\Windows\Temp","C:\Windows\SoftwareDistribution\Download","C:\Windows\Prefetch")
Get-ChildItem "C:\Users" -Directory -EA SilentlyContinue | ForEach-Object {
    $junk += "$($_.FullName)\AppData\Local\Temp"
}
foreach ($p in ($junk | Select-Object -Unique)) {
    if (Test-Path $p) { $plan += [PSCustomObject]@{ Path=$p; Bytes=(DirSize $p); Type="Rac he thong" } }
}

# ============================================================
# LIET KE
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " CHUAN BI GIAO VPS - user dang login: $currentUser (GIU)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
$total = 0
foreach ($grp in @("O D (xoa sach)","Profile user cu","Data user hien tai","Rac he thong")) {
    $items = $plan | Where-Object { $_.Type -eq $grp }
    if ($items.Count -eq 0) { continue }
    Write-Host ""
    Write-Host "  --- $grp ---" -ForegroundColor Yellow
    foreach ($i in ($items | Sort-Object Bytes -Descending)) {
        Write-Host ("    [X] {0}  {1}" -f (MB $i.Bytes).PadLeft(10), $i.Path) -ForegroundColor Gray
        $total += $i.Bytes
    }
}
Write-Host ""
Write-Host ("  TONG giai phong: ~{0}" -f (GB $total)) -ForegroundColor Yellow
Write-Host ""
Write-Host "  >>> GIU: app da cai (Program Files) + Windows + user '$currentUser' (chi xoa data, giu account)" -ForegroundColor Green
Write-Host "  >>> XOA VINH VIEN, dong het app truoc khi chay." -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "  Go 'YES' de don sach giao may, hoac Enter de HUY"
if ($confirm -ne "YES") { Write-Host "  Da HUY - khong xoa gi."; Write-Host ""; pause; exit }

# ============================================================
# THUC HIEN
# ============================================================
Write-Host ""
Write-Host "=== Dang don... ===" -ForegroundColor Cyan
$ok=0; $fail=0
foreach ($i in $plan) {
    try {
        # Junk/temp: xoa noi dung, giu folder. Con lai: xoa han
        if ($i.Type -eq "Rac he thong") {
            Get-ChildItem $i.Path -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA Stop
        } else {
            Remove-Item $i.Path -Recurse -Force -EA Stop
        }
        Write-Host "  [OK] $($i.Path)" -ForegroundColor Green; $ok++
    } catch {
        Write-Host "  [FAIL] $($i.Path) - $($_.Exception.Message)" -ForegroundColor Red; $fail++
    }
}

Clear-RecycleBin -Force -EA SilentlyContinue
Write-Host "  [OK] Don Recycle Bin" -ForegroundColor Green
Write-Host "  [.] DISM cleanup (cho vai phut)..." -ForegroundColor Yellow
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /Quiet 2>&1 | Out-Null
Write-Host "  [OK] DISM xong" -ForegroundColor Green

# ============================================================
# BAO CAO
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
Write-Host "  Xoa OK: $ok | That bai: $fail (dong app roi chay lai)" -ForegroundColor White
Write-Host "  App da cai + Windows: NGUYEN VEN" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
