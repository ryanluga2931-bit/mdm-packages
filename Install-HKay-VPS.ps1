# ============================================================
# Cai app cho VPS H Kay
# UniKey, VipTalk, Signal, Chrome, VS Code, NodeJS, Java
# + Shortcut Snipping Tool
# - Co app va chay duoc: SKIP
# - Co app nhung loi: cai lai
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\HKayInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download($name, $url, $out) {
    Write-Host "  [.] Dang tai $name..." -ForegroundColor Yellow
    Invoke-WebRequest $url -OutFile $out -UseBasicParsing
    Write-Host "  [OK] Tai xong" -ForegroundColor Green
}

function RunInstaller($name, $path, $argList = "") {
    Write-Host "  [.] Dang cai $name..." -ForegroundColor Yellow
    if ($argList) {
        $p = Start-Process $path -ArgumentList $argList -Wait -PassThru
    } else {
        $p = Start-Process $path -Wait -PassThru
    }
    if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010 -or $p.ExitCode -eq 1641) {
        Write-Host "  [OK] Cai xong: $name" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  [WARN] Exit code: $($p.ExitCode)" -ForegroundColor Yellow
        return $false
    }
}

function IsInstalled($name) {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($p in $paths) {
        if (Get-ItemProperty $p -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*$name*" }) {
            return $true
        }
    }
    return $false
}

function IsRunnable($exePath) {
    if (-not (Test-Path $exePath)) { return $false }
    try {
        $p = Start-Process $exePath -ArgumentList "--version" -Wait -PassThru -WindowStyle Hidden -EA SilentlyContinue
        return $true
    } catch { return $false }
}

# ============================================================

# --- [1] UniKey ---
Write-Host ""
Write-Host "=== [1/7] UniKey ===" -ForegroundColor Cyan
$ukExe = "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"
if (Test-Path $ukExe) {
    Write-Host "  [SKIP] UniKey da co" -ForegroundColor Cyan
} else {
    $ukZip = "$tmp\UniKey.zip"
    Download "UniKey" "$ghBase/UniKey-Windows.zip" $ukZip
    Expand-Archive $ukZip -DestinationPath "C:\Program Files\UniKey" -Force
    Write-Host "  [OK] UniKey giai nen xong" -ForegroundColor Green
}
# Shortcut
$shell = New-Object -ComObject WScript.Shell
$sc = $shell.CreateShortcut("$env:PUBLIC\Desktop\UniKey.lnk")
$sc.TargetPath = $ukExe
$sc.Save()

# --- [2] VipTalk ---
Write-Host ""
Write-Host "=== [2/7] VipTalk ===" -ForegroundColor Cyan
if (IsInstalled "VipTalk") {
    $vtExe = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*VipTalk*" } | Select-Object -First 1).InstallLocation
    $vtCheck = Get-Process "VipTalk" -EA SilentlyContinue
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $vt = "$tmp\VipTalk-Setup.exe"
    Download "VipTalk 1.12.142" "$ghBase/VipTalk-Setup-1.12.142.exe" $vt
    RunInstaller "VipTalk" $vt "/S"
}

# --- [3] Signal ---
Write-Host ""
Write-Host "=== [3/7] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $sig = "$tmp\Signal-Setup.exe"
    Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $sig
    RunInstaller "Signal" $sig "--silent"
}

# --- [4] Google Chrome ---
Write-Host ""
Write-Host "=== [4/7] Google Chrome ===" -ForegroundColor Cyan
$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromeExe) {
    Write-Host "  [SKIP] Chrome da cai" -ForegroundColor Cyan
} else {
    $chrome = "$tmp\ChromeSetup.exe"
    Download "Google Chrome" "https://dl.google.com/chrome/install/latest/chrome_installer.exe" $chrome
    RunInstaller "Chrome" $chrome "/silent /install"
}

# --- [5] VS Code ---
Write-Host ""
Write-Host "=== [5/7] VS Code ===" -ForegroundColor Cyan
$codeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
if (-not (Test-Path $codeExe)) {
    $codeExe = "C:\Program Files\Microsoft VS Code\Code.exe"
}
if (Test-Path $codeExe) {
    Write-Host "  [SKIP] VS Code da cai" -ForegroundColor Cyan
} else {
    $vscode = "$tmp\VSCodeSetup.exe"
    Download "VS Code" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" $vscode
    RunInstaller "VS Code" $vscode "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
}

# --- [6] NodeJS LTS ---
Write-Host ""
Write-Host "=== [6/7] NodeJS LTS ===" -ForegroundColor Cyan
$nodeExe = "C:\Program Files\nodejs\node.exe"
$nodeOk = $false
if (Test-Path $nodeExe) {
    try {
        $ver = & $nodeExe --version 2>&1
        Write-Host "  [SKIP] NodeJS da cai: $ver" -ForegroundColor Cyan
        $nodeOk = $true
    } catch {}
}
if (-not $nodeOk) {
    $node = "$tmp\NodeSetup.msi"
    $nodeJson = (Invoke-WebRequest "https://nodejs.org/dist/index.json" -UseBasicParsing).Content | ConvertFrom-Json
    $nodeVer = ($nodeJson | Where-Object { $_.lts -ne $false } | Select-Object -First 1).version
    Download "NodeJS $nodeVer" "https://nodejs.org/dist/$nodeVer/node-$nodeVer-x64.msi" $node
    RunInstaller "NodeJS" "msiexec.exe" "/i `"$node`" /qn /norestart"
}

# --- [7] Java JDK 21 ---
Write-Host ""
Write-Host "=== [7/7] Java JDK 21 ===" -ForegroundColor Cyan
$javaExe = "$env:ProgramFiles\Eclipse Adoptium\jdk-21*\bin\java.exe"
$javaFound = Get-Item $javaExe -EA SilentlyContinue | Select-Object -First 1
$javaOk = $false
if ($javaFound) {
    try {
        $ver = & $javaFound.FullName -version 2>&1
        Write-Host "  [SKIP] Java da cai: $($ver[0])" -ForegroundColor Cyan
        $javaOk = $true
    } catch {}
}
if (-not $javaOk) {
    $java = "$tmp\JavaSetup.msi"
    Download "Java JDK 21" "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_windows_hotspot_21.0.7_6.msi" $java
    RunInstaller "Java JDK 21" "msiexec.exe" "/i `"$java`" /qn /norestart ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome"
}

# --- Snipping Tool shortcut ---
Write-Host ""
Write-Host "=== Shortcut Snipping Tool ===" -ForegroundColor Cyan
$sc2 = $shell.CreateShortcut("$env:PUBLIC\Desktop\Snipping Tool.lnk")
$snippingExe = "C:\Windows\System32\SnippingTool.exe"
if (Test-Path $snippingExe) {
    $sc2.TargetPath = $snippingExe
} else {
    $sc2.TargetPath = "explorer.exe"
    $sc2.Arguments = "shell:AppsFolder\Microsoft.ScreenSketch_8wekyb3d8bbwe!App"
}
$sc2.Save()
Write-Host "  [OK] Shortcut Snipping Tool xong" -ForegroundColor Green

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - H Kay VPS" -ForegroundColor Green
Write-Host "  1. UniKey" -ForegroundColor White
Write-Host "  2. VipTalk 1.12.142" -ForegroundColor White
Write-Host "  3. Signal 8.16.0" -ForegroundColor White
Write-Host "  4. Google Chrome" -ForegroundColor White
Write-Host "  5. VS Code" -ForegroundColor White
Write-Host "  6. NodeJS LTS" -ForegroundColor White
Write-Host "  7. Java JDK 21" -ForegroundColor White
Write-Host "  + Shortcut Snipping Tool" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
pause
