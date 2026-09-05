# ============================================================
# Check-DiskLayout.ps1  (CHI DOC - khong dung gi)
# Kiem tra C va D co the gop duoc khong + D dang chua gi
# ============================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
$ErrorActionPreference = "SilentlyContinue"
function GB($b){ "{0:N1} GB" -f ($b/1GB) }

# ============================================================
# [1] Co bao nhieu O VAT LY (Disk)?
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " O VAT LY (Physical Disk)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Get-Disk | ForEach-Object {
    Write-Host ("  Disk {0}: {1}  ({2})  Style={3}" -f $_.Number, (GB $_.Size), $_.FriendlyName, $_.PartitionStyle) -ForegroundColor White
}

# ============================================================
# [2] Cac PHAN VUNG - xem C va D co CUNG 1 disk + LIEN KE khong
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " PHAN VUNG (Partition) - thu tu tren dia" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Get-Partition | Sort-Object DiskNumber, Offset | ForEach-Object {
    $letter = if ($_.DriveLetter) { "$($_.DriveLetter):" } else { "(khong letter)" }
    Write-Host ("  Disk{0} | {1} | {2} | Offset={3}" -f `
        $_.DiskNumber, $letter.PadRight(14), (GB $_.Size).PadLeft(9), (GB $_.Offset)) -ForegroundColor White
}

# ============================================================
# [3] KET LUAN: gop duoc khong?
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " CO GOP DUOC C + D KHONG?" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow

$cPart = Get-Partition -DriveLetter C
$dPart = Get-Partition -DriveLetter D

if (-not $dPart) {
    Write-Host "  Khong tim thay o D." -ForegroundColor Red
} elseif ($cPart.DiskNumber -ne $dPart.DiskNumber) {
    Write-Host "  [KHONG] C va D o 2 O VAT LY KHAC NHAU (Disk$($cPart.DiskNumber) vs Disk$($dPart.DiskNumber))." -ForegroundColor Red
    Write-Host "  -> KHONG the gop thanh 1 o. 2 o cung khac nhau." -ForegroundColor Red
} else {
    # Cung disk - check D co ngay sau C khong
    $cEnd = $cPart.Offset + $cPart.Size
    $gap = $dPart.Offset - $cEnd
    Write-Host "  C va D CUNG Disk$($cPart.DiskNumber)." -ForegroundColor Green
    if ($dPart.Offset -gt $cPart.Offset -and $gap -lt 10MB) {
        Write-Host "  [CO THE] D nam NGAY SAU C -> co the: XOA D roi extend C." -ForegroundColor Green
    } else {
        Write-Host "  [KHO] D KHONG nam ngay sau C (hoac C sau D)." -ForegroundColor Yellow
        Write-Host "  -> Extend C ngay khong duoc, can tool partition ben thu 3." -ForegroundColor Yellow
    }
}

# ============================================================
# [4] D dang chua GI? (73GB da dung)
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " O D: DANG CHUA GI (top thu muc)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
if (Test-Path "D:\") {
    Get-ChildItem "D:\" -Directory -Force -EA SilentlyContinue | ForEach-Object {
        $s = (Get-ChildItem $_.FullName -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
        [PSCustomObject]@{ Path = $_.FullName; Bytes = $s }
    } | Sort-Object Bytes -Descending | Select-Object -First 15 | ForEach-Object {
        Write-Host ("  {0}  {1}" -f (GB $_.Bytes).PadLeft(9), $_.Path) -ForegroundColor White
    }
    # File le o goc D
    $rootFiles = (Get-ChildItem "D:\" -File -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($rootFiles -gt 0) { Write-Host ("  {0}  (file le o goc D:\)" -f (GB $rootFiles).PadLeft(9)) -ForegroundColor Gray }
} else {
    Write-Host "  D: trong hoac khong truy cap duoc." -ForegroundColor Gray
}

Write-Host ""
Write-Host "  >>> Script nay CHI DOC - khong xoa/thay doi gi." -ForegroundColor Green
Write-Host "  >>> Gui ket qua nay cho Claude de tinh buoc tiep." -ForegroundColor Yellow
Write-Host ""
pause
