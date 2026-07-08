# ============================================================
# Cai app cho VPS V Gray
# UniKey, VipTalk, Signal, VS Code, OBS Studio,
# Docker+WSL2, Postman, SourceTree
# NOTE: Xcode + Homebrew = macOS only, khong co tren Windows
# ============================================================

# Auto self-elevate neu chua phai admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\VGrayInstall"
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
# [0] Prerequisites
# ============================================================
Write-Host ""
Write-Host "=== [0] Prerequisites (VC++, .NET 8, WebView2) ===" -ForegroundColor Cyan

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

$dotnet8Path = Get-Item "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\8.*" -EA SilentlyContinue | Select-Object -Last 1
if ($dotnet8Path) {
    Write-Host "  [SKIP] .NET 8 Desktop Runtime: $($dotnet8Path.Name)" -ForegroundColor Cyan
} else {
    try {
        $dotnetVer = (Invoke-WebRequest "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/8.0/latest.version" -UseBasicParsing).Content.Trim()
        $f = "$tmp\dotnet8-runtime.exe"
        if (Download ".NET 8 Runtime $dotnetVer" "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/$dotnetVer/windowsdesktop-runtime-$dotnetVer-win-x64.exe" $f) {
            RunInstaller ".NET 8 Runtime" $f "/install /quiet /norestart"
        }
    } catch { Write-Host "  [WARN] Khong lay duoc version .NET" -ForegroundColor Yellow }
}

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
Write-Host "=== [1/8] UniKey ===" -ForegroundColor Cyan
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
Write-Host "=== [2/8] VipTalk ===" -ForegroundColor Cyan
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
Write-Host "=== [3/8] Signal ===" -ForegroundColor Cyan
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
Write-Host "=== [4/8] VS Code ===" -ForegroundColor Cyan
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
# [5] OBS Studio
# ============================================================
Write-Host ""
Write-Host "=== [5/8] OBS Studio ===" -ForegroundColor Cyan
$obsInstalled = CheckReg "OBS Studio"
if ($obsInstalled) {
    Write-Host "  [SKIP] OBS Studio da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai OBS qua winget..." -ForegroundColor Yellow
    winget install --id OBSProject.OBSStudio --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] OBS Studio cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\OBSSetup.exe"
        if (Download "OBS Studio" "https://github.com/obsproject/obs-studio/releases/latest/download/OBS-Studio-31.0.3-Windows-Installer.exe" $f) {
            RunInstaller "OBS Studio" $f "/S"
        }
    }
} else {
    $f = "$tmp\OBSSetup.exe"
    if (Download "OBS Studio" "https://github.com/obsproject/obs-studio/releases/latest/download/OBS-Studio-31.0.3-Windows-Installer.exe" $f) {
        RunInstaller "OBS Studio" $f "/S"
    }
}

# ============================================================
# [6] Postman
# ============================================================
Write-Host ""
Write-Host "=== [6/8] Postman ===" -ForegroundColor Cyan
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
# [7] SourceTree
# ============================================================
Write-Host ""
Write-Host "=== [7/8] SourceTree ===" -ForegroundColor Cyan
$stInstalled = CheckReg "Sourcetree"
$stExe = "$env:LOCALAPPDATA\SourceTree\SourceTree.exe"
if ($stInstalled -or (Test-Path $stExe)) {
    Write-Host "  [SKIP] SourceTree da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai SourceTree qua winget..." -ForegroundColor Yellow
    winget install --id Atlassian.Sourcetree --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] SourceTree cai xong" -ForegroundColor Green }
    else { Write-Host "  [WARN] winget exit: $LASTEXITCODE" -ForegroundColor Yellow }
} else {
    $f = "$tmp\SourceTreeSetup.exe"
    if (Download "SourceTree" "https://product-downloads.atlassian.com/software/sourcetree/windows/ga/SourceTreeSetup-3.4.21.exe" $f) {
        RunInstaller "SourceTree" $f "/S"
    }
}

# ============================================================
# [8] WSL2 + Docker Desktop
# ============================================================
Write-Host ""
Write-Host "=== [8/8] WSL2 + Docker Desktop ===" -ForegroundColor Cyan

$wslFeature = dism /online /Get-FeatureInfo /featurename:Microsoft-Windows-Subsystem-Linux 2>&1 | Where-Object { $_ -match "State" }
$vmFeature  = dism /online /Get-FeatureInfo /featurename:VirtualMachinePlatform 2>&1 | Where-Object { $_ -match "State" }
$featuresOn = ($wslFeature -match "Enabled") -and ($vmFeature -match "Enabled")

if (-not $featuresOn) {
    Write-Host "  [.] Bat Windows features WSL + VirtualMachinePlatform..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>&1 | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>&1 | Out-Null
    Write-Host "  [!] Da bat features. RESTART MAY ROI CHAY LAI SCRIPT NAY de cai Docker!" -ForegroundColor Red
} else {
    Write-Host "  [OK] Windows features WSL da bat" -ForegroundColor Green
    wsl --update 2>&1 | Out-Null
    wsl --set-default-version 2 2>&1 | Out-Null
    Write-Host "  [.] WSL version: $((wsl --version 2>&1) | Select-Object -First 1)" -ForegroundColor Gray

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
# Ket qua
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - V Gray VPS" -ForegroundColor Green
Write-Host "  Prerequisites: VC++ | .NET 8 | WebView2" -ForegroundColor White
Write-Host "  1. UniKey        5. OBS Studio" -ForegroundColor White
Write-Host "  2. VipTalk       6. Postman" -ForegroundColor White
Write-Host "  3. Signal        7. SourceTree" -ForegroundColor White
Write-Host "  4. VS Code       8. WSL2 + Docker" -ForegroundColor White
Write-Host "  * Xcode + Homebrew: macOS only" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [!] Neu Docker bao WSL not installed:" -ForegroundColor Yellow
Write-Host "      1. Restart may" -ForegroundColor Yellow
Write-Host "      2. Chay lai script nay" -ForegroundColor Yellow
Write-Host ""
pause
