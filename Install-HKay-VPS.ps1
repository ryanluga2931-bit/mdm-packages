# ============================================================
# Cai app cho VPS H Kay
# UniKey, VipTalk, Signal, Chrome, VS Code, NodeJS, Java
# + Shortcut Snipping Tool
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\HKayInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download($name, $url, $out) {
    Write-Host "[.] Dang tai $name..." -ForegroundColor Yellow
    Invoke-WebRequest $url -OutFile $out -UseBasicParsing
    Write-Host "[OK] Tai xong: $name" -ForegroundColor Green
}

function Run($name, $path, $argList = "") {
    Write-Host "[.] Dang cai $name..." -ForegroundColor Yellow
    if ($argList) {
        $p = Start-Process $path -ArgumentList $argList -Wait -PassThru
    } else {
        $p = Start-Process $path -Wait -PassThru
    }
    if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010 -or $p.ExitCode -eq 1641) {
        Write-Host "[OK] Cai xong: $name" -ForegroundColor Green
    } else {
        Write-Host "[WARN] $name exit code: $($p.ExitCode)" -ForegroundColor Yellow
    }
}

# --- [1] UniKey ---
Write-Host ""
Write-Host "=== [1/7] UniKey ===" -ForegroundColor Cyan
$ukZip = "$tmp\UniKey.zip"
Download "UniKey" "$ghBase/UniKey-Windows.zip" $ukZip
$ukDir = "C:\Program Files\UniKey"
Expand-Archive $ukZip -DestinationPath $ukDir -Force
$shell = New-Object -ComObject WScript.Shell
$sc = $shell.CreateShortcut("$env:PUBLIC\Desktop\UniKey.lnk")
$sc.TargetPath = "$ukDir\UniKey\UniKeyNT.exe"
$sc.Save()
Write-Host "[OK] UniKey + shortcut xong" -ForegroundColor Green

# --- [2] VipTalk ---
Write-Host ""
Write-Host "=== [2/7] VipTalk ===" -ForegroundColor Cyan
$vt = "$tmp\VipTalk-Setup.exe"
Download "VipTalk 1.12.142" "$ghBase/VipTalk-Setup-1.12.142.exe" $vt
Run "VipTalk" $vt "/S"

# --- [3] Signal ---
Write-Host ""
Write-Host "=== [3/7] Signal ===" -ForegroundColor Cyan
$sig = "$tmp\Signal-Setup.exe"
Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $sig
Run "Signal" $sig "--silent"

# --- [4] Google Chrome ---
Write-Host ""
Write-Host "=== [4/7] Google Chrome ===" -ForegroundColor Cyan
$chrome = "$tmp\ChromeSetup.exe"
Download "Google Chrome" "https://dl.google.com/chrome/install/latest/chrome_installer.exe" $chrome
Run "Chrome" $chrome "/silent /install"

# --- [5] VS Code ---
Write-Host ""
Write-Host "=== [5/7] VS Code ===" -ForegroundColor Cyan
$vscode = "$tmp\VSCodeSetup.exe"
Download "VS Code" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" $vscode
Run "VS Code" $vscode "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"

# --- [6] NodeJS LTS ---
Write-Host ""
Write-Host "=== [6/7] NodeJS LTS ===" -ForegroundColor Cyan
$node = "$tmp\NodeSetup.msi"
# Lay version LTS moi nhat
$nodeJson = (Invoke-WebRequest "https://nodejs.org/dist/index.json" -UseBasicParsing).Content | ConvertFrom-Json
$nodeVer = ($nodeJson | Where-Object { $_.lts -ne $false } | Select-Object -First 1).version
Download "NodeJS $nodeVer" "https://nodejs.org/dist/$nodeVer/node-$nodeVer-x64.msi" $node
Run "NodeJS" "msiexec.exe" "/i `"$node`" /qn /norestart"

# --- [7] Java JDK (Temurin 21 LTS) ---
Write-Host ""
Write-Host "=== [7/7] Java JDK 21 ===" -ForegroundColor Cyan
$java = "$tmp\JavaSetup.msi"
Download "Java JDK 21" "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_windows_hotspot_21.0.7_6.msi" $java
Run "Java JDK 21" "msiexec.exe" "/i `"$java`" /qn /norestart ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome"

# --- Snipping Tool shortcut ---
Write-Host ""
Write-Host "=== Shortcut Snipping Tool ===" -ForegroundColor Cyan
$snippingExe = "C:\Windows\System32\SnippingTool.exe"
if (-not (Test-Path $snippingExe)) {
    $snippingExe = "C:\Windows\SystemApps\Microsoft.ScreenSketch_8wekyb3d8bbwe\SnippingTool.exe"
}
if (Test-Path $snippingExe) {
    $sc2 = $shell.CreateShortcut("$env:PUBLIC\Desktop\Snipping Tool.lnk")
    $sc2.TargetPath = $snippingExe
    $sc2.Save()
    Write-Host "[OK] Shortcut Snipping Tool tao xong" -ForegroundColor Green
} else {
    # Windows 11 - mo qua ms-screensketch
    $sc2 = $shell.CreateShortcut("$env:PUBLIC\Desktop\Snipping Tool.lnk")
    $sc2.TargetPath = "explorer.exe"
    $sc2.Arguments = "shell:AppsFolder\Microsoft.ScreenSketch_8wekyb3d8bbwe!App"
    $sc2.Save()
    Write-Host "[OK] Shortcut Snipping Tool (Win11) tao xong" -ForegroundColor Green
}

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - H Kay VPS" -ForegroundColor Green
Write-Host "  1. UniKey" -ForegroundColor White
Write-Host "  2. VipTalk 1.12.142" -ForegroundColor White
Write-Host "  3. Signal 8.16.0" -ForegroundColor White
Write-Host "  4. Google Chrome" -ForegroundColor White
Write-Host "  5. VS Code" -ForegroundColor White
Write-Host "  6. NodeJS LTS ($nodeVer)" -ForegroundColor White
Write-Host "  7. Java JDK 21" -ForegroundColor White
Write-Host "  + Shortcut Snipping Tool" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
pause
