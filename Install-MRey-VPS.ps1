# ============================================================
# Cai app cho VPS M Rey
# UniKey, VipTalk, Signal, Threema, OpenVPN + import AsE-011
# ============================================================

# Auto self-elevate neu chua phai admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\MReyInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download($name, $url, $out) {
    Write-Host "  [.] Dang tai $name..." -ForegroundColor Yellow
    for ($i = 1; $i -le 3; $i++) {
        try {
            Remove-Item $out -EA SilentlyContinue
            $curlExe = "$env:SystemRoot\System32\curl.exe"
            if (Test-Path $curlExe) { & $curlExe -L -s -o $out $url }
            else {
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest $url -OutFile $out -UseBasicParsing -EA Stop
            }
            if ((Test-Path $out) -and (Get-Item $out).Length -gt 100KB) {
                Write-Host "  [OK] Tai xong ($([math]::Round((Get-Item $out).Length/1MB,1)) MB)" -ForegroundColor Green
                return $true
            }
            Write-Host "  [WARN] File trong, thu lai $i/3..." -ForegroundColor Yellow
        } catch {
            if ($i -lt 3) {
                Write-Host "  [WARN] Lan $i that bai: $($_.Exception.Message)" -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            } else {
                Write-Host "  [FAIL] Tai that bai: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    return $false
}

function RunInstaller($name, $path, $argList = "") {
    Write-Host "  [.] Dang cai $name..." -ForegroundColor Yellow
    if ($argList) { $p = Start-Process $path -ArgumentList $argList -Wait -PassThru }
    else { $p = Start-Process $path -Wait -PassThru }
    if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010 -or $p.ExitCode -eq 1641) {
        Write-Host "  [OK] Cai xong: $name" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $name exit code: $($p.ExitCode)" -ForegroundColor Yellow
    }
}

function CheckReg($name) {
    return Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*$name*" }
}

function AddShortcut($name, $targetPath) {
    $publicLnk = "$env:PUBLIC\Desktop\$name.lnk"
    if (Test-Path $publicLnk) { return }
    if (-not (Test-Path $targetPath)) { return }
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($publicLnk)
    $sc.TargetPath = $targetPath
    $sc.Save()
    Write-Host "  [OK] Shortcut '$name' tao xong" -ForegroundColor Green
}

# ============================================================
# [1] UniKey
# ============================================================
Write-Host ""
Write-Host "=== [1/5] UniKey ===" -ForegroundColor Cyan
$ukExe = "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"
if (Test-Path $ukExe) {
    Write-Host "  [SKIP] UniKey da co" -ForegroundColor Cyan
} else {
    $f = "$tmp\UniKey.zip"
    if (Download "UniKey" "$ghBase/UniKey-Windows.zip" $f) {
        Expand-Archive $f -DestinationPath "C:\Program Files\UniKey" -Force
        Write-Host "  [OK] UniKey xong" -ForegroundColor Green
    }
}
AddShortcut "UniKey" $ukExe

# ============================================================
# [2] VipTalk
# ============================================================
Write-Host ""
Write-Host "=== [2/5] VipTalk ===" -ForegroundColor Cyan
if (CheckReg "VipTalk") {
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VipTalk.exe"
    if (Download "VipTalk 1.12.143" "$ghBase/VipTalk-Setup-1.12.143.exe" $f) {
        RunInstaller "VipTalk" $f "/S"
    }
}

# ============================================================
# [3] Signal
# ============================================================
Write-Host ""
Write-Host "=== [3/5] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    if (Download "Signal" "$ghBase/Signal-8.16.0-x64.exe" $f) {
        RunInstaller "Signal" $f "--silent"
    }
}
AddShortcut "Signal" $sigExe

# ============================================================
# [4] Threema
# ============================================================
Write-Host ""
Write-Host "=== [4/5] Threema ===" -ForegroundColor Cyan
$thrInstalled = CheckReg "Threema"
$thrExe = "$env:LOCALAPPDATA\Programs\Threema\Threema.exe"
if ($thrInstalled -or (Test-Path $thrExe)) {
    Write-Host "  [SKIP] Threema da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Threema qua winget..." -ForegroundColor Yellow
    winget install --id Threema.Threema --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Threema cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\ThreemaSetup.exe"
        if (Download "Threema" "https://releases.threema.ch/web-electron/v1/release/Threema-Latest.exe" $f) {
            RunInstaller "Threema" $f "/S"
        }
    }
} else {
    $f = "$tmp\ThreemaSetup.exe"
    if (Download "Threema" "https://releases.threema.ch/web-electron/v1/release/Threema-Latest.exe" $f) {
        RunInstaller "Threema" $f "/S"
    }
}

# ============================================================
# [5] OpenVPN + Import AsE-011
# ============================================================
Write-Host ""
Write-Host "=== [5/5] OpenVPN + Config AsE-011 ===" -ForegroundColor Cyan

# Cai OpenVPN neu chua co
$ovpnExe = "C:\Program Files\OpenVPN\bin\openvpn.exe"
$ovpnGui = "C:\Program Files\OpenVPN\bin\openvpn-gui.exe"
if (Test-Path $ovpnExe) {
    Write-Host "  [SKIP] OpenVPN da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai OpenVPN qua winget..." -ForegroundColor Yellow
    winget install --id OpenVPNTechnologies.OpenVPN --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] OpenVPN cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\OpenVPNSetup.exe"
        if (Download "OpenVPN" "https://swupdate.openvpn.org/community/releases/OpenVPN-2.6.12-I001-amd64.msi" $f) {
            RunInstaller "OpenVPN" "msiexec.exe" "/i `"$f`" /qn /norestart"
        }
    }
} else {
    $f = "$tmp\OpenVPNSetup.msi"
    if (Download "OpenVPN" "https://swupdate.openvpn.org/community/releases/OpenVPN-2.6.12-I001-amd64.msi" $f) {
        RunInstaller "OpenVPN" "msiexec.exe" "/i `"$f`" /qn /norestart"
    }
}

# Import file AsE-011.ovpn tu Downloads
Write-Host "  [.] Tim file AsE-011.ovpn trong Downloads..." -ForegroundColor Yellow

# Thu tim trong Downloads cua moi user
$ovpnFile = $null
$searchPaths = @(
    "$env:USERPROFILE\Downloads\AsE-011.ovpn",
    "$env:PUBLIC\Downloads\AsE-011.ovpn",
    "C:\Users\mrey\Downloads\AsE-011.ovpn"
)
# Tim them cac file .ovpn co ten chua AsE-011
Get-ChildItem "C:\Users" -Recurse -Filter "*AsE-011*.ovpn" -Depth 4 -EA SilentlyContinue | ForEach-Object {
    if (-not $ovpnFile) { $ovpnFile = $_.FullName }
}
foreach ($p in $searchPaths) {
    if (-not $ovpnFile -and (Test-Path $p)) { $ovpnFile = $p }
}

if ($ovpnFile) {
    Write-Host "  [OK] Tim thay: $ovpnFile" -ForegroundColor Green

    # Copy vao thu muc config cua OpenVPN (system-wide)
    $configDir = "C:\Program Files\OpenVPN\config"
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Force $configDir | Out-Null }
    Copy-Item $ovpnFile "$configDir\AsE-011.ovpn" -Force
    Write-Host "  [OK] Da copy config -> $configDir\AsE-011.ovpn" -ForegroundColor Green

    # Tao file auth: nhap pass luc chay script (khong luu vao code)
    $vpnUser = "mrey"
    $vpnPass = Read-Host "  Nhap VPN password cho AsE-011"
    $authFile = "$configDir\AsE-011-auth.txt"
    Set-Content $authFile "$vpnUser`n$vpnPass" -Encoding UTF8
    Write-Host "  [OK] Da luu credentials -> AsE-011-auth.txt" -ForegroundColor Green

    # Them dong auth-user-pass vao .ovpn neu chua co
    $ovpnContent = Get-Content "$configDir\AsE-011.ovpn" -Raw
    if ($ovpnContent -notmatch "auth-user-pass") {
        Add-Content "$configDir\AsE-011.ovpn" "`nauth-user-pass AsE-011-auth.txt"
        Write-Host "  [OK] Da them auth-user-pass vao config" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARN] Khong tim thay AsE-011.ovpn trong Downloads!" -ForegroundColor Red
    Write-Host "         Copy file .ovpn vao: C:\Program Files\OpenVPN\config\" -ForegroundColor Yellow
}

AddShortcut "OpenVPN GUI" $ovpnGui

# ============================================================
# Mui gio + Sync time
# ============================================================
Write-Host ""
Write-Host "=== Cai mui gio UTC+7 + Sync time ===" -ForegroundColor Cyan
Set-TimeZone -Id "SE Asia Standard Time"
Write-Host "  [OK] Mui gio: $(Get-TimeZone | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Green
Start-Service w32tm -EA SilentlyContinue
w32tm /resync /force 2>&1 | Out-Null
Write-Host "  [OK] Sync time: $(Get-Date)" -ForegroundColor Green

# ============================================================
# Ket qua
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - M Rey VPS" -ForegroundColor Green
Write-Host "  1. UniKey" -ForegroundColor White
Write-Host "  2. VipTalk" -ForegroundColor White
Write-Host "  3. Signal" -ForegroundColor White
Write-Host "  4. Threema" -ForegroundColor White
Write-Host "  5. OpenVPN + AsE-011" -ForegroundColor White
Write-Host "  [!] Mo OpenVPN GUI -> Connect AsE-011 la xong" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

pause
