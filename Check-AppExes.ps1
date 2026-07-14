# ============================================================
# Check-AppExes.ps1 — Quet TOAN BO exe tren may nay
# Bao gom: registry, thu muc cai, Store apps, services
# ============================================================

$ErrorActionPreference = "SilentlyContinue"
$results = @()

Write-Host ""
Write-Host "Dang quet toan bo app tren may..." -ForegroundColor Cyan

# ============================================================
# [1] Registry — Uninstall keys (64-bit + 32-bit + User)
# ============================================================
Write-Host "  [.] Quet registry..." -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($reg in $regPaths) {
    Get-ItemProperty $reg -EA SilentlyContinue | Where-Object { $_.DisplayName } | ForEach-Object {
        $exePath = ""
        # Thu DisplayIcon truoc
        if ($_.DisplayIcon -and $_.DisplayIcon -match '\.exe') {
            $icon = $_.DisplayIcon -replace '"','' -replace ',\d+$',''
            if (Test-Path $icon) { $exePath = $icon }
        }
        # Thu InstallLocation
        if (-not $exePath -and $_.InstallLocation) {
            $loc = $_.InstallLocation.TrimEnd('\')
            if (Test-Path $loc) {
                $exeInDir = Get-ChildItem $loc -Filter "*.exe" -Depth 2 -EA SilentlyContinue | Select-Object -First 1
                if ($exeInDir) { $exePath = $exeInDir.FullName }
            }
        }
        $results += [PSCustomObject]@{
            Source  = "Registry"
            Name    = $_.DisplayName
            Version = $_.DisplayVersion
            Exe     = if ($exePath) { Split-Path $exePath -Leaf } else { "-" }
            Path    = $exePath
        }
    }
}

# ============================================================
# [2] Quet thu muc cai pho bien
# ============================================================
Write-Host "  [.] Quet thu muc Program Files..." -ForegroundColor Yellow
$scanDirs = @(
    "C:\Program Files",
    "C:\Program Files (x86)",
    "$env:LOCALAPPDATA\Programs",
    "$env:LOCALAPPDATA",
    "$env:APPDATA",
    "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps"
)
$knownExeSkip = @("unins*.exe","uninst*.exe","uninstall*.exe","update.exe","crashreport*.exe","helper.exe")

foreach ($dir in $scanDirs) {
    if (-not (Test-Path $dir)) { continue }
    # Chi lay exe chinh (depth 3, bo exe phu)
    Get-ChildItem $dir -Filter "*.exe" -Recurse -Depth 3 -EA SilentlyContinue | Where-Object {
        $skip = $false
        foreach ($pat in $knownExeSkip) { if ($_.Name -like $pat) { $skip = $true; break } }
        -not $skip -and $_.Length -gt 100KB
    } | ForEach-Object {
        # Khong add trung voi registry
        $alreadyHave = $results | Where-Object { $_.Path -eq $_.FullName }
        if (-not $alreadyHave) {
            $fvi = $_.VersionInfo
            $results += [PSCustomObject]@{
                Source  = "Dir-Scan"
                Name    = if ($fvi.ProductName) { $fvi.ProductName } else { $_.BaseName }
                Version = $fvi.ProductVersion
                Exe     = $_.Name
                Path    = $_.FullName
            }
        }
    }
}

# ============================================================
# [3] Windows Store / MSIX apps
# ============================================================
Write-Host "  [.] Quet Store apps (MSIX)..." -ForegroundColor Yellow
Get-AppxPackage -AllUsers -EA SilentlyContinue | Where-Object { $_.SignatureKind -ne "System" } | ForEach-Object {
    $results += [PSCustomObject]@{
        Source  = "Store/MSIX"
        Name    = $_.Name
        Version = $_.Version
        Exe     = $_.PackageFamilyName
        Path    = $_.InstallLocation
    }
}

# ============================================================
# [4] Services (exe dang chay ngam)
# ============================================================
Write-Host "  [.] Quet Windows Services..." -ForegroundColor Yellow
Get-WmiObject Win32_Service -EA SilentlyContinue | Where-Object { $_.PathName -and $_.PathName -match '\.exe' } | ForEach-Object {
    $exePath = $_.PathName -replace '^"?([^"]+\.exe).*$','$1'
    $results += [PSCustomObject]@{
        Source  = "Service"
        Name    = $_.DisplayName
        Version = ""
        Exe     = Split-Path $exePath -Leaf
        Path    = $exePath
    }
}

# ============================================================
# [5] Process dang chay (bat ky app nao dang mo)
# ============================================================
Write-Host "  [.] Quet process dang chay..." -ForegroundColor Yellow
Get-Process -EA SilentlyContinue | Where-Object { $_.MainModule -and $_.MainModule.FileName } | ForEach-Object {
    $p = $_.MainModule.FileName
    $alreadyHave = $results | Where-Object { $_.Path -eq $p }
    if (-not $alreadyHave) {
        $results += [PSCustomObject]@{
            Source  = "Running"
            Name    = $_.ProductVersion
            Version = $_.FileVersion
            Exe     = Split-Path $p -Leaf
            Path    = $p
        }
    }
}

# ============================================================
# Loc + sap xep
# ============================================================
$unique = $results | Where-Object { $_.Exe -and $_.Exe -ne "-" } |
    Sort-Object Exe -Unique |
    Sort-Object Source, Name

# ============================================================
# In ket qua theo nguon
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " TONG KET: $($unique.Count) exe tim thay" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

foreach ($src in @("Registry","Dir-Scan","Service","Store/MSIX","Running")) {
    $group = $unique | Where-Object { $_.Source -eq $src }
    if ($group.Count -eq 0) { continue }
    Write-Host ""
    Write-Host "--- $src ($($group.Count)) ---" -ForegroundColor Cyan
    foreach ($item in $group) {
        Write-Host ("  " + $item.Exe.PadRight(45) + $item.Name) -ForegroundColor White
    }
}

# ============================================================
# Xuat danh sach exe thuan tuy de copy vao allow list
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " DANH SACH EXE THUAN - COPY VAO ALLOW LIST" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
$unique | Where-Object { $_.Source -ne "Store/MSIX" } |
    Select-Object -ExpandProperty Exe | Sort-Object -Unique | ForEach-Object {
    Write-Host $_
}

# Xuat ra file CSV de luu lai
$csvPath = "$env:USERPROFILE\Desktop\AppExeList.csv"
$unique | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "  [OK] Da xuat file CSV: $csvPath" -ForegroundColor Green
Write-Host ""
pause
