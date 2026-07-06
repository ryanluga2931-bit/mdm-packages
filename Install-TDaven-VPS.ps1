# ============================================================
# Cai app cho VPS T Daven
# UniKey, VipTalk 1.12.143, Signal,
# Cursor, VS Code, GitHub Desktop, Docker+WSL2,
# Postman, Android Studio
# (Xcode chi co tren macOS - khong co ban Windows)
# ============================================================

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\TDavenInstall"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
            Write-Host "  [WARN] File trong hoac loi, thu lai $i/3..." -ForegroundColor Yellow
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

function AddShortcut($name, $targetPath, $argList = "") {
    $publicLnk = "$env:PUBLIC\Desktop\$name.lnk"
    $userLnk   = "$env:USERPROFILE\Desktop\$name.lnk"
    if ((Test-Path $publicLnk) -or (Test-Path $userLnk)) {
        Write-Host "  [SKIP] Shortcut '$name' da co" -ForegroundColor Cyan
        return
    }
    if (-not (Test-Path $targetPath)) {
        Write-Host "  [SKIP] Shortcut '$name': khong tim thay exe" -ForegroundColor Gray
        return
    }
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($publicLnk)
    $sc.TargetPath = $targetPath
    if ($argList) { $sc.Arguments = $argList }
    $sc.Save()
    Write-Host "  [OK] Shortcut '$name' tao xong" -ForegroundColor Green
}

# --- [1] UniKey ---
Write-Host ""
Write-Host "=== [1/9] UniKey ===" -ForegroundColor Cyan
$ukExe = "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"
if (Test-Path $ukExe) {
    Write-Host "  [SKIP] UniKey da co" -ForegroundColor Cyan
} else {
    $f = "$tmp\UniKey.zip"
    Download "UniKey" "$ghBase/UniKey-Windows.zip" $f
    Expand-Archive $f -DestinationPath "C:\Program Files\UniKey" -Force
    Write-Host "  [OK] UniKey xong" -ForegroundColor Green
}
AddShortcut "UniKey" $ukExe

# --- [2] VipTalk ---
Write-Host ""
Write-Host "=== [2/9] VipTalk ===" -ForegroundColor Cyan
if (CheckReg "VipTalk") {
    Write-Host "  [SKIP] VipTalk da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VipTalk.exe"
    Download "VipTalk 1.12.143" "$ghBase/VipTalk-Setup-1.12.143.exe" $f
    RunInstaller "VipTalk" $f "/S"
}

# --- [3] Signal ---
Write-Host ""
Write-Host "=== [3/9] Signal ===" -ForegroundColor Cyan
$sigExe = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
if (Test-Path $sigExe) {
    Write-Host "  [SKIP] Signal da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\Signal.exe"
    Download "Signal 8.16.0" "$ghBase/Signal-8.16.0-x64.exe" $f
    RunInstaller "Signal" $f "--silent"
}
AddShortcut "Signal" $sigExe

# --- [4] VS Code ---
Write-Host ""
Write-Host "=== [4/9] VS Code ===" -ForegroundColor Cyan
$codeExe = if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") { "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" } else { "C:\Program Files\Microsoft VS Code\Code.exe" }
if (Test-Path $codeExe) {
    Write-Host "  [SKIP] VS Code da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\VSCode.exe"
    Download "VS Code" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" $f
    RunInstaller "VS Code" $f "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
}
AddShortcut "Visual Studio Code" $codeExe

# --- [2] Cursor ---
Write-Host ""
Write-Host "=== [5/9] Cursor ===" -ForegroundColor Cyan
if (CheckReg "Cursor") {
    Write-Host "  [SKIP] Cursor da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\CursorSetup.exe"
    Download "Cursor 3.9.8" "https://downloads.cursor.com/production/4aa8ff1b7877ed7bd01bcba308698f71a6735380/win32/x64/user-setup/CursorUserSetup-x64-3.9.8.exe" $f
    RunInstaller "Cursor" $f "/VERYSILENT /NORESTART"
}

# --- [3] GitHub Desktop ---
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
        $ghUrl = "https://github.com/desktop/desktop/releases/download/release-3.6.3-beta1/GitHubDesktopSetup-x64.exe"
        if (Download "GitHub Desktop" $ghUrl $f) {
            RunInstaller "GitHub Desktop" $f "--silent"
        } else {
            Write-Host "  [SKIP] Bo qua GitHub Desktop (tai that bai + khong co winget)" -ForegroundColor Yellow
        }
    }
}
AddShortcut "GitHub Desktop" $ghExe

# --- [4] Postman ---
Write-Host ""
Write-Host "=== [7/9] Postman ===" -ForegroundColor Cyan
$postmanExe = "$env:LOCALAPPDATA\Postman\Postman.exe"
if (Test-Path $postmanExe) {
    Write-Host "  [SKIP] Postman da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\PostmanSetup.exe"
    Download "Postman" "https://dl.pstmn.io/download/latest/win64" $f
    RunInstaller "Postman" $f "--silent"
}
AddShortcut "Postman" $postmanExe

# --- [5] Android Studio ---
Write-Host ""
Write-Host "=== [8/9] Android Studio ===" -ForegroundColor Cyan
if (CheckReg "Android Studio") {
    Write-Host "  [SKIP] Android Studio da cai" -ForegroundColor Cyan
} else {
    $f = "$tmp\AndroidStudio.exe"
    Download "Android Studio 2026.1.1" "https://edgedl.me.gvt1.com/android/studio/install/2026.1.1.10/android-studio-quail1-patch2-windows.exe" $f
    RunInstaller "Android Studio" $f "/S"
}

# --- [6] WSL2 + Docker Desktop ---
Write-Host ""
Write-Host "=== [9/9] WSL2 + Docker Desktop ===" -ForegroundColor Cyan
if (CheckReg "Docker Desktop") {
    Write-Host "  [SKIP] Docker Desktop da cai" -ForegroundColor Cyan
} else {
    Write-Host "  [.] Bat WSL + VirtualMachinePlatform..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>&1 | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>&1 | Out-Null

    $wslKernel = "$tmp\wsl_update.msi"
    Download "WSL2 Kernel" "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" $wslKernel
    RunInstaller "WSL2 Kernel" "msiexec.exe" "/i `"$wslKernel`" /qn /norestart"

    & wsl --set-default-version 2 2>&1 | Out-Null

    $f = "$tmp\DockerSetup.exe"
    Download "Docker Desktop" "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" $f
    RunInstaller "Docker Desktop" $f "install --quiet --accept-license"
    AddShortcut "Docker Desktop" "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"

    Write-Host "  [!] Restart may sau khi cai xong de WSL2 + Docker hoat dong!" -ForegroundColor Yellow
}


# --- Mui gio + Sync time ---
Write-Host ""
Write-Host "=== Cai mui gio UTC+7 + Sync time ===" -ForegroundColor Cyan
Set-TimeZone -Id "SE Asia Standard Time"
Write-Host "  [OK] Mui gio: $(Get-TimeZone | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Green
Start-Service w32tm -EA SilentlyContinue
w32tm /resync /force 2>&1 | Out-Null
Write-Host "  [OK] Sync time: $(Get-Date)" -ForegroundColor Green

# --- Kiem tra app ---
Write-Host ""
Write-Host "=== KIEM TRA APP (MO THU + CHECK HOAT DONG) ===" -ForegroundColor Magenta

function LaunchCheck($name, $exePath, $argList = "") {
    Write-Host ("  [{0,-20}] " -f $name) -ForegroundColor White -NoNewline
    if (-not (Test-Path $exePath)) {
        Write-Host "FAIL - Khong tim thay: $exePath" -ForegroundColor Red
        return "FAIL"
    }
    try {
        if ($argList) { $p = Start-Process $exePath -ArgumentList $argList -PassThru -EA Stop }
        else          { $p = Start-Process $exePath -PassThru -EA Stop }
        Start-Sleep -Seconds 4
        if ($null -eq $p) {
            Write-Host "FAIL - Khong khoi dong duoc" -ForegroundColor Red
            return "FAIL"
        }
        $p.Refresh()
        if (-not $p.HasExited) {
            $p.Kill() | Out-Null
            Write-Host "OK   - Chay binh thuong" -ForegroundColor Green
            return "OK"
        } elseif ($p.ExitCode -eq 0 -or $p.ExitCode -eq 1) {
            Write-Host "OK   - Thoat nhanh (exit $($p.ExitCode))" -ForegroundColor Green
            return "OK"
        } else {
            Write-Host "WARN - Thoat ngay, exit code: $($p.ExitCode) → co the thieu runtime" -ForegroundColor Yellow
            return "WARN"
        }
    } catch {
        Write-Host "FAIL - Loi: $($_.Exception.Message)" -ForegroundColor Red
        return "FAIL"
    }
}

$appResults = [ordered]@{}

# UniKey
$appResults["UniKey"] = LaunchCheck "UniKey" "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"

# VipTalk - tim exe trong registry hoac cac duong dan pho bien
$vtReg = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*VipTalk*" } | Select-Object -First 1
$vtExePaths = @(
    "C:\Program Files\VipTalk\VipTalk.exe",
    "C:\Program Files (x86)\VipTalk\VipTalk.exe",
    "$env:LOCALAPPDATA\Programs\VipTalk\VipTalk.exe"
)
if ($vtReg -and $vtReg.InstallLocation) {
    $vtExePaths = @(Join-Path $vtReg.InstallLocation "VipTalk.exe") + $vtExePaths
}
$vtExe = $vtExePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $vtExe) { $vtExe = "C:\Program Files\VipTalk\VipTalk.exe" }
$appResults["VipTalk"] = LaunchCheck "VipTalk" $vtExe

# Signal
$appResults["Signal"] = LaunchCheck "Signal" "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"

# VS Code
$codeExe2 = if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") {
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
} else { "C:\Program Files\Microsoft VS Code\Code.exe" }
$appResults["VS Code"] = LaunchCheck "VS Code" $codeExe2 "--version"

# Cursor
$cursorExe = @(
    "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
    "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe",
    "$env:APPDATA\Local\Programs\cursor\Cursor.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $cursorExe) { $cursorExe = "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe" }
$appResults["Cursor"] = LaunchCheck "Cursor" $cursorExe

# GitHub Desktop
$appResults["GitHub Desktop"] = LaunchCheck "GitHub Desktop" "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"

# Postman
$appResults["Postman"] = LaunchCheck "Postman" "$env:LOCALAPPDATA\Postman\Postman.exe"

# Android Studio
$asReg = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -EA SilentlyContinue | Where-Object { $_.DisplayName -like "*Android Studio*" } | Select-Object -First 1
$asExe = if ($asReg -and $asReg.InstallLocation) {
    Join-Path $asReg.InstallLocation "bin\studio64.exe"
} else { "C:\Program Files\Android\Android Studio\bin\studio64.exe" }
$appResults["Android Studio"] = LaunchCheck "Android Studio" $asExe

# Docker Desktop - check exe + service (khong launch vi can WSL2 + restart)
Write-Host ("  [{0,-20}] " -f "Docker Desktop") -ForegroundColor White -NoNewline
$dockerExe = "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
if (Test-Path $dockerExe) {
    $dockerSvc = Get-Service "com.docker.service" -EA SilentlyContinue
    if ($dockerSvc -and $dockerSvc.Status -eq "Running") {
        Write-Host "OK   - Exe co + service dang chay" -ForegroundColor Green
        $appResults["Docker Desktop"] = "OK"
    } elseif ($dockerSvc) {
        Write-Host "WARN - Exe co nhung service chua chay → Restart may de Docker hoat dong" -ForegroundColor Yellow
        $appResults["Docker Desktop"] = "WARN"
    } else {
        Write-Host "WARN - Exe co nhung chua thay service → Restart may sau WSL2" -ForegroundColor Yellow
        $appResults["Docker Desktop"] = "WARN"
    }
} else {
    Write-Host "FAIL - Khong tim thay Docker Desktop exe" -ForegroundColor Red
    $appResults["Docker Desktop"] = "FAIL"
}

# --- Bang tong ket ket qua ---
Write-Host ""
Write-Host "--- TONG KET KIEM TRA APP ---" -ForegroundColor Magenta
$okList   = @()
$warnList = @()
$failList = @()
foreach ($app in $appResults.Keys) {
    switch ($appResults[$app]) {
        "OK"   { $okList   += $app }
        "WARN" { $warnList += $app }
        "FAIL" { $failList += $app }
    }
}
foreach ($app in $okList)   { Write-Host ("  [OK  ] {0}" -f $app) -ForegroundColor Green }
foreach ($app in $warnList) { Write-Host ("  [WARN] {0}" -f $app) -ForegroundColor Yellow }
foreach ($app in $failList) { Write-Host ("  [FAIL] {0}" -f $app) -ForegroundColor Red }

if ($failList.Count -gt 0 -or $warnList.Count -gt 0) {
    Write-Host ""
    Write-Host "  [!] Cac app bi WARN/FAIL co the can:" -ForegroundColor Yellow
    Write-Host "      - Visual C++ Redistributable: https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Gray
    Write-Host "      - .NET 8 Desktop Runtime: https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Gray
    Write-Host "      - WebView2 Runtime: https://developer.microsoft.com/en-us/microsoft-edge/webview2/" -ForegroundColor Gray
    Write-Host "      - Docker: can RESTART may sau khi cai WSL2" -ForegroundColor Gray
}

# --- Ket qua ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HOAN TAT - T Daven VPS" -ForegroundColor Green
Write-Host "  1. UniKey" -ForegroundColor White
Write-Host "  2. VipTalk 1.12.143" -ForegroundColor White
Write-Host "  3. Signal 8.16.0" -ForegroundColor White
Write-Host "  4. VS Code" -ForegroundColor White
Write-Host "  5. Cursor" -ForegroundColor White
Write-Host "  6. GitHub Desktop" -ForegroundColor White
Write-Host "  7. Postman" -ForegroundColor White
Write-Host "  8. Android Studio" -ForegroundColor White
Write-Host "  9. WSL2 + Docker Desktop" -ForegroundColor White
Write-Host "  * Xcode: chi co tren macOS" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
pause
