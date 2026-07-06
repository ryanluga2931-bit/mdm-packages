# ============================================================
# Cai app cho VPS T Daven
# UniKey, VipTalk 1.12.143, Signal, VS Code, Cursor,
# GitHub Desktop, Postman, Android Studio, WSL2+Docker
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\TDavenInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -------- Helper functions --------

function Download($name, $url, $out) {
    Write-Host "  [.] Dang tai $name..." -ForegroundColor Yellow
    for ($i = 1; $i -le 3; $i++) {
        try {
            Remove-Item $out -EA SilentlyContinue
            $curlExe = "$env:SystemRoot\System32\curl.exe"
            if (Test-Path $curlExe) {
                & $curlExe -L -s -o $out $url
            } else {
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
        return $true
    } else {
        Write-Host "  [WARN] $name exit code: $($p.ExitCode)" -ForegroundColor Yellow
        return $false
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
# [0] Prerequisites: VC++, .NET 8, WebView2
# ============================================================
Write-Host ""
Write-Host "=== [0] Prerequisites (VC++, .NET 8, WebView2) ===" -ForegroundColor Cyan

# Visual C++ Redistributable 2022
$vcInstalled = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -EA SilentlyContinue | Where-Object {
        $_.DisplayName -like "*Visual C++*" -and $_.DisplayVersion -ge "14.30"
    } | Select-Object -First 1
if ($vcInstalled) {
    Write-Host "  [SKIP] VC++ Redistributable: $($vcInstalled.DisplayVersion)" -ForegroundColor Cyan
} else {
    $f = "$tmp\vc_redist.exe"
    if (Download "VC++ Redistributable 2022" "https://aka.ms/vs/17/release/vc_redist.x64.exe" $f) {
        RunInstaller "VC++ Redistributable" $f "/install /quiet /norestart"
    }
}

# .NET 8 Desktop Runtime
$dotnet8Path = Get-Item "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\8.*" -EA SilentlyContinue | Select-Object -Last 1
if ($dotnet8Path) {
    Write-Host "  [SKIP] .NET 8 Desktop Runtime: $($dotnet8Path.Name)" -ForegroundColor Cyan
} else {
    try {
        $dotnetVer = (Invoke-WebRequest "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/8.0/latest.version" -UseBasicParsing).Content.Trim()
        $dotnetUrl = "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/$dotnetVer/windowsdesktop-runtime-$dotnetVer-win-x64.exe"
        $f = "$tmp\dotnet8-runtime.exe"
        if (Download ".NET 8 Desktop Runtime $dotnetVer" $dotnetUrl $f) {
            RunInstaller ".NET 8 Runtime" $f "/install /quiet /norestart"
        }
    } catch {
        Write-Host "  [WARN] Khong lay duoc version .NET: $_" -ForegroundColor Yellow
    }
}

# WebView2 Runtime
$wv2 = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -EA SilentlyContinue
if ($wv2 -and $wv2.pv -and $wv2.pv -ne "0.0.0.0") {
    Write-Host "  [SKIP] WebView2 Runtime: $($wv2.pv)" -ForegroundColor Cyan
} else {
    $f = "$tmp\webview2.exe"
    if (Download "WebView2 Runtime" "https://go.microsoft.com/fwlink/p/?LinkId=2124703" $f) {
        RunInstaller "WebView2" $f "/silent /install"
    }
}

# ============================================================
# [1] UniKey
# ============================================================
Write-Host ""
Write-Host "=== [1/9] UniKey ===" -ForegroundColor Cyan
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
Write-Host "=== [2/9] VipTalk ===" -ForegroundColor Cyan
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
Write-Host "=== [3/9] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    if (Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $f) {
        RunInstaller "Signal" $f "--silent"
    }
}
AddShortcut "Signal" $sigExe

# ============================================================
# [4] VS Code
# ============================================================
Write-Host ""
Write-Host "=== [4/9] VS Code ===" -ForegroundColor Cyan
$codeExe = if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") {
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
} else { "C:\Program Files\Microsoft VS Code\Code.exe" }
if (Test-Path $codeExe) {
    Write-Host "  [SKIP] VS Code da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VSCode.exe"
    if (Download "VS Code" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" $f) {
        RunInstaller "VS Code" $f "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
    }
}
AddShortcut "Visual Studio Code" $codeExe

# ============================================================
# [5] Cursor
# ============================================================
Write-Host ""
Write-Host "=== [5/9] Cursor ===" -ForegroundColor Cyan
if (CheckReg "Cursor") {
    Write-Host "  [SKIP] Cursor da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\CursorSetup.exe"
    if (Download "Cursor" "https://downloads.cursor.com/production/4aa8ff1b7877ed7bd01bcba308698f71a6735380/win32/x64/user-setup/CursorUserSetup-x64-3.9.8.exe" $f) {
        RunInstaller "Cursor" $f "/VERYSILENT /NORESTART"
    }
}

# ============================================================
# [6] GitHub Desktop
# ============================================================
Write-Host ""
Write-Host "=== [6/9] GitHub Desktop ===" -ForegroundColor Cyan
$ghExe = "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"
if (Test-Path $ghExe) {
    Write-Host "  [SKIP] GitHub Desktop da cai" -ForegroundColor Cyan
} else {
    if (Get-Command winget -EA SilentlyContinue) {
        Write-Host "  [.] Cai GitHub Desktop qua winget..." -ForegroundColor Yellow
        winget install --id GitHub.GitHubDesktop --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] GitHub Desktop cai xong" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] winget exit: $LASTEXITCODE" -ForegroundColor Yellow
        }
    } else {
        $f = "$tmp\GitHubDesktop.exe"
        if (Download "GitHub Desktop" "https://github.com/desktop/desktop/releases/download/release-3.6.3-beta1/GitHubDesktopSetup-x64.exe" $f) {
            RunInstaller "GitHub Desktop" $f "--silent"
        } else {
            Write-Host "  [SKIP] Bo qua GitHub Desktop (khong tai duoc)" -ForegroundColor Yellow
        }
    }
}
AddShortcut "GitHub Desktop" $ghExe

# ============================================================
# [7] Postman
# ============================================================
Write-Host ""
Write-Host "=== [7/9] Postman ===" -ForegroundColor Cyan
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
# [8] Android Studio
# ============================================================
Write-Host ""
Write-Host "=== [8/9] Android Studio ===" -ForegroundColor Cyan
if (CheckReg "Android Studio") {
    Write-Host "  [SKIP] Android Studio da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\AndroidStudio.exe"
    if (Download "Android Studio 2026.1.1" "https://edgedl.me.gvt1.com/android/studio/install/2026.1.1.10/android-studio-quail1-patch2-windows.exe" $f) {
        RunInstaller "Android Studio" $f "/S"
    }
}

# ============================================================
# [9] WSL2 + Docker Desktop  (2-phase: bat feature → restart → cai)
# ============================================================
Write-Host ""
Write-Host "=== [9/9] WSL2 + Docker Desktop ===" -ForegroundColor Cyan

# Kiem tra WSL da hoat dong chua
$wslOk = $false
try {
    $wslStatus = wsl --status 2>&1
    $wslOk = ($wslStatus -match "Default Version\s*:\s*2" -or (wsl --list 2>&1) -notmatch "not installed")
} catch {}

# Kiem tra Windows features da bat chua
$wslFeature = dism /online /Get-FeatureInfo /featurename:Microsoft-Windows-Subsystem-Linux 2>&1 | Where-Object { $_ -match "State" }
$vmFeature  = dism /online /Get-FeatureInfo /featurename:VirtualMachinePlatform 2>&1 | Where-Object { $_ -match "State" }
$featuresOn = ($wslFeature -match "Enabled") -and ($vmFeature -match "Enabled")

if (-not $featuresOn) {
    # Phase 1: Bat features, yeu cau restart
    Write-Host "  [.] Bat Windows features WSL + VirtualMachinePlatform..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>&1 | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>&1 | Out-Null
    Write-Host "  [!] Da bat features. RESTART MAY ROI CHAY LAI SCRIPT NAY de cai WSL + Docker!" -ForegroundColor Red
} else {
    # Phase 2: Features da bat, cai WSL kernel + Docker
    Write-Host "  [OK] Windows features WSL da bat" -ForegroundColor Green

    # Cai WSL kernel moi nhat
    Write-Host "  [.] Cap nhat WSL kernel..." -ForegroundColor Yellow
    wsl --update 2>&1 | Out-Null
    wsl --set-default-version 2 2>&1 | Out-Null

    # Kiem tra WSL sau update
    $wslCheck = wsl --status 2>&1
    if ($wslCheck -match "not installed" -or $LASTEXITCODE -ne 0) {
        # Thu cai WSL bang MSI offline
        Write-Host "  [.] WSL chua co, cai WSL kernel MSI..." -ForegroundColor Yellow
        $wslMsi = "$tmp\wsl_update.msi"
        if (Download "WSL2 Kernel" "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" $wslMsi) {
            RunInstaller "WSL2 Kernel" "msiexec.exe" "/i `"$wslMsi`" /qn /norestart"
            wsl --set-default-version 2 2>&1 | Out-Null
        }
    }

    # Kiem tra WSL version lan cuoi
    $wslVer = wsl --version 2>&1
    Write-Host "  [.] WSL version: $($wslVer | Select-Object -First 1)" -ForegroundColor Gray

    # Cai Docker Desktop
    if (CheckReg "Docker Desktop") {
        Write-Host "  [SKIP] Docker Desktop da cai" -ForegroundColor Cyan
    } else {
        $f = "$tmp\DockerSetup.exe"
        if (Download "Docker Desktop" "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" $f) {
            RunInstaller "Docker Desktop" $f "install --quiet --accept-license --backend=wsl-2"
        }
    }
    AddShortcut "Docker Desktop" "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
    Write-Host "  [!] Neu Docker bao loi WSL: restart may 1 lan nua la OK" -ForegroundColor Yellow
}

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
# Kiem tra app
# ============================================================
Write-Host ""
Write-Host "=== KIEM TRA APP ===" -ForegroundColor Magenta

function LaunchCheck($name, $exePath, $argList = "") {
    Write-Host ("  [{0,-20}] " -f $name) -ForegroundColor White -NoNewline
    if (-not (Test-Path $exePath)) {
        Write-Host "FAIL - Khong tim thay exe" -ForegroundColor Red
        return "FAIL"
    }
    try {
        if ($argList) { $p = Start-Process $exePath -ArgumentList $argList -PassThru -EA Stop }
        else          { $p = Start-Process $exePath -PassThru -EA Stop }
        Start-Sleep -Seconds 4
        $p.Refresh()
        if (-not $p.HasExited) {
            $p.Kill() | Out-Null
            Write-Host "OK   - Chay binh thuong" -ForegroundColor Green
            return "OK"
        } elseif ($p.ExitCode -eq 0 -or $p.ExitCode -eq 1) {
            Write-Host "OK   - Thoat nhanh (exit $($p.ExitCode))" -ForegroundColor Green
            return "OK"
        } else {
            Write-Host "WARN - exit $($p.ExitCode), co the thieu runtime" -ForegroundColor Yellow
            return "WARN"
        }
    } catch {
        Write-Host "FAIL - $($_.Exception.Message)" -ForegroundColor Red
        return "FAIL"
    }
}

$appResults = [ordered]@{}

$appResults["UniKey"]  = LaunchCheck "UniKey" "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"

$vtExe = @(
    "C:\Program Files\VipTalk\VipTalk.exe",
    "C:\Program Files (x86)\VipTalk\VipTalk.exe",
    "$env:LOCALAPPDATA\Programs\VipTalk\VipTalk.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $vtExe) { $vtExe = "C:\Program Files\VipTalk\VipTalk.exe" }
$appResults["VipTalk"] = LaunchCheck "VipTalk" $vtExe

$appResults["Signal"]  = LaunchCheck "Signal" "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"

$codeExe2 = if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") {
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
} else { "C:\Program Files\Microsoft VS Code\Code.exe" }
$appResults["VS Code"] = LaunchCheck "VS Code" $codeExe2 "--version"

$cursorExe = @(
    "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
    "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $cursorExe) { $cursorExe = "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe" }
$appResults["Cursor"]  = LaunchCheck "Cursor" $cursorExe

$appResults["GitHub Desktop"] = LaunchCheck "GitHub Desktop" "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"
$appResults["Postman"] = LaunchCheck "Postman" "$env:LOCALAPPDATA\Postman\Postman.exe"

$asReg = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*Android Studio*" } | Select-Object -First 1
$asExe = if ($asReg -and $asReg.InstallLocation) {
    Join-Path $asReg.InstallLocation "bin\studio64.exe"
} else { "C:\Program Files\Android\Android Studio\bin\studio64.exe" }
$appResults["Android Studio"] = LaunchCheck "Android Studio" $asExe

# Docker - check service
Write-Host ("  [{0,-20}] " -f "Docker Desktop") -ForegroundColor White -NoNewline
$dockerExe = "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
if (Test-Path $dockerExe) {
    $svc = Get-Service "com.docker.service" -EA SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "OK   - Exe + service dang chay" -ForegroundColor Green
        $appResults["Docker Desktop"] = "OK"
    } else {
        Write-Host "WARN - Exe co, service chua chay → Restart may" -ForegroundColor Yellow
        $appResults["Docker Desktop"] = "WARN"
    }
} else {
    Write-Host "FAIL - Chua cai hoac features chua bat (restart may)" -ForegroundColor Red
    $appResults["Docker Desktop"] = "FAIL"
}

# Tong ket
Write-Host ""
Write-Host "--- TONG KET ---" -ForegroundColor Magenta
foreach ($app in $appResults.Keys) {
    $s = $appResults[$app]
    $c = if ($s -eq "OK") { "Green" } elseif ($s -eq "WARN") { "Yellow" } else { "Red" }
    Write-Host ("  [{0}] {1}" -f $s.PadRight(4), $app) -ForegroundColor $c
}

# ============================================================
# Ket qua
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - T Daven VPS" -ForegroundColor Green
Write-Host "  Prerequisites: VC++ | .NET 8 | WebView2" -ForegroundColor White
Write-Host "  1. UniKey      5. Cursor" -ForegroundColor White
Write-Host "  2. VipTalk     6. GitHub Desktop" -ForegroundColor White
Write-Host "  3. Signal      7. Postman" -ForegroundColor White
Write-Host "  4. VS Code     8. Android Studio" -ForegroundColor White
Write-Host "  9. WSL2 + Docker Desktop" -ForegroundColor White
Write-Host "  * Xcode: chi co tren macOS" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [!] Neu Docker bao WSL not installed:" -ForegroundColor Yellow
Write-Host "      1. Restart may" -ForegroundColor Yellow
Write-Host "      2. Chay lai script nay" -ForegroundColor Yellow
Write-Host "      3. Docker se cai o lan 2" -ForegroundColor Yellow
Write-Host ""
pause
