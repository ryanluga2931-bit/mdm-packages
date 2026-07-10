# ============================================================
# Cai app cho VPS Z Noor
# UniKey, VipTalk, Signal, Telegram, CapCut,
# Windows App (Remote Desktop), Bitwarden
# ============================================================

# Auto self-elevate neu chua phai admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\ZNoorInstall"
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
                Write-Host "  [WARN] Lan $i that bai, thu lai: $($_.Exception.Message)" -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            } else {
                Write-Host "  [FAIL] Tai that bai sau 3 lan: $($_.Exception.Message)" -ForegroundColor Red
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
    $userLnk   = "$env:USERPROFILE\Desktop\$name.lnk"
    if ((Test-Path $publicLnk) -or (Test-Path $userLnk)) { return }
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
Write-Host "=== [1/7] UniKey ===" -ForegroundColor Cyan
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
Write-Host "=== [2/7] VipTalk ===" -ForegroundColor Cyan
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
Write-Host "=== [3/7] Signal ===" -ForegroundColor Cyan
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
# [4] Telegram
# ============================================================
Write-Host ""
Write-Host "=== [4/7] Telegram ===" -ForegroundColor Cyan
$tgExe = "$env:APPDATA\Telegram Desktop\Telegram.exe"
if (Test-Path $tgExe) {
    Write-Host "  [SKIP] Telegram da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Telegram qua winget..." -ForegroundColor Yellow
    winget install --id Telegram.TelegramDesktop --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Telegram cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\TelegramSetup.exe"
        if (Download "Telegram" "https://telegram.org/dl/desktop/win64" $f) {
            RunInstaller "Telegram" $f "/S"
        }
    }
} else {
    $f = "$tmp\TelegramSetup.exe"
    if (Download "Telegram" "https://telegram.org/dl/desktop/win64" $f) {
        RunInstaller "Telegram" $f "/S"
    }
}
AddShortcut "Telegram" $tgExe

# ============================================================
# [5] CapCut
# ============================================================
Write-Host ""
Write-Host "=== [5/7] CapCut ===" -ForegroundColor Cyan
$ccInstalled = CheckReg "CapCut"
if ($ccInstalled) {
    Write-Host "  [SKIP] CapCut da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai CapCut qua winget..." -ForegroundColor Yellow
    winget install --id ByteDance.CapCut --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] CapCut cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\CapCutSetup.exe"
        if (Download "CapCut" "https://lf16-capcut.faceulv.com/obj/capcutpc-packages-us/packages/capcut_installer_windows_x64.exe" $f) {
            RunInstaller "CapCut" $f "/S"
        }
    }
} else {
    $f = "$tmp\CapCutSetup.exe"
    if (Download "CapCut" "https://lf16-capcut.faceulv.com/obj/capcutpc-packages-us/packages/capcut_installer_windows_x64.exe" $f) {
        RunInstaller "CapCut" $f "/S"
    }
}

# ============================================================
# [6] Windows App (Microsoft Remote Desktop)
# ============================================================
Write-Host ""
Write-Host "=== [6/7] Windows App (Remote Desktop) ===" -ForegroundColor Cyan
$rdInstalled = CheckReg "Windows App"
$rdExe = "$env:LOCALAPPDATA\Microsoft\WindowsApp\msrdcw.exe"
if ($rdInstalled -or (Test-Path $rdExe)) {
    Write-Host "  [SKIP] Windows App da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Windows App qua winget (Microsoft Store)..." -ForegroundColor Yellow
    winget install --id 9N1F85V9T8BN --source msstore --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Windows App cai xong" -ForegroundColor Green }
    else { Write-Host "  [WARN] Windows App: can login Microsoft Store de cai thu cong" -ForegroundColor Yellow }
} else {
    Write-Host "  [WARN] Windows App: can winget hoac Microsoft Store" -ForegroundColor Yellow
}

# ============================================================
# [7] Bitwarden
# ============================================================
Write-Host ""
Write-Host "=== [7/7] Bitwarden ===" -ForegroundColor Cyan
$bwInstalled = CheckReg "Bitwarden"
$bwExe = "$env:LOCALAPPDATA\Programs\Bitwarden\Bitwarden.exe"
if ($bwInstalled -or (Test-Path $bwExe)) {
    Write-Host "  [SKIP] Bitwarden da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Bitwarden qua winget..." -ForegroundColor Yellow
    winget install --id Bitwarden.Bitwarden --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Bitwarden cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\BitwardenSetup.exe"
        if (Download "Bitwarden" "https://vault.bitwarden.com/download/?app=desktop&platform=windows" $f) {
            RunInstaller "Bitwarden" $f "--silent"
        }
    }
} else {
    $f = "$tmp\BitwardenSetup.exe"
    if (Download "Bitwarden" "https://vault.bitwarden.com/download/?app=desktop&platform=windows" $f) {
        RunInstaller "Bitwarden" $f "--silent"
    }
}
AddShortcut "Bitwarden" $bwExe

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
Write-Host " HOAN TAT - Z Noor VPS" -ForegroundColor Green
Write-Host "  1. UniKey          5. CapCut" -ForegroundColor White
Write-Host "  2. VipTalk         6. Windows App" -ForegroundColor White
Write-Host "  3. Signal          7. Bitwarden" -ForegroundColor White
Write-Host "  4. Telegram" -ForegroundColor White
Write-Host "  [!] Windows App: neu loi -> vao Microsoft Store cai thu cong" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
