# ============================================================
# Cai app cho VPS H Huda
# UniKey, VipTalk, Signal, Firefox, Opera, 1.1.1.1 WARP, Postman
# ============================================================

# Auto self-elevate neu chua phai admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\HHudaInstall"
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
Write-Host "=== [1/6] UniKey ===" -ForegroundColor Cyan
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
Write-Host "=== [2/6] VipTalk ===" -ForegroundColor Cyan
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
Write-Host "=== [3/6] Signal ===" -ForegroundColor Cyan
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
# [4] Firefox
# ============================================================
Write-Host ""
Write-Host "=== [4/6] Firefox ===" -ForegroundColor Cyan
$ffExe = "C:\Program Files\Mozilla Firefox\firefox.exe"
if (Test-Path $ffExe) {
    Write-Host "  [SKIP] Firefox da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\FirefoxSetup.exe"
    if (Download "Firefox" "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=vi" $f) {
        RunInstaller "Firefox" $f "-ms /S"
    }
}
AddShortcut "Firefox" $ffExe

# ============================================================
# [5] Opera
# ============================================================
Write-Host ""
Write-Host "=== [5/6] Opera ===" -ForegroundColor Cyan
$operaInstalled = CheckReg "Opera"
if ($operaInstalled) {
    Write-Host "  [SKIP] Opera da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Opera qua winget..." -ForegroundColor Yellow
    winget install --id Opera.Opera --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Opera cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\OperaSetup.exe"
        if (Download "Opera" "https://download.opera.com/download/get/?partner=www&opsys=Windows" $f) {
            RunInstaller "Opera" $f "/silent /norestart /allusers=1"
        }
    }
} else {
    $f = "$tmp\OperaSetup.exe"
    if (Download "Opera" "https://download.opera.com/download/get/?partner=www&opsys=Windows" $f) {
        RunInstaller "Opera" $f "/silent /norestart /allusers=1"
    }
}

# ============================================================
# [6a] 1.1.1.1 WARP (Cloudflare)
# ============================================================
Write-Host ""
Write-Host "=== [6/6] 1.1.1.1 WARP + Postman ===" -ForegroundColor Cyan
$warpExe = "C:\Program Files\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe"
if (Test-Path $warpExe) {
    Write-Host "  [SKIP] 1.1.1.1 WARP da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai 1.1.1.1 WARP qua winget..." -ForegroundColor Yellow
    winget install --id Cloudflare.Warp --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] 1.1.1.1 WARP cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\WarpSetup.exe"
        if (Download "1.1.1.1 WARP" "https://1111-releases.cloudflareclient.com/win/latest" $f) {
            RunInstaller "1.1.1.1 WARP" $f "/silent"
        }
    }
} else {
    $f = "$tmp\WarpSetup.exe"
    if (Download "1.1.1.1 WARP" "https://1111-releases.cloudflareclient.com/win/latest" $f) {
        RunInstaller "1.1.1.1 WARP" $f "/silent"
    }
}

# ============================================================
# [6b] Postman
# ============================================================
$postmanExe = "$env:LOCALAPPDATA\Postman\Postman.exe"
if (Test-Path $postmanExe) {
    Write-Host "  [SKIP] Postman da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\PostmanSetup.exe"
    if (Download "Postman" "https://dl.pstmn.io/download/latest/win64" $f) {
        RunInstaller "Postman" $f "--silent"
    }
}
AddShortcut "Postman" $postmanExe

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
Write-Host " HOAN TAT - H Huda VPS" -ForegroundColor Green
Write-Host "  1. UniKey        4. Firefox" -ForegroundColor White
Write-Host "  2. VipTalk       5. Opera" -ForegroundColor White
Write-Host "  3. Signal        6. 1.1.1.1 WARP + Postman" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
