# ============================================================
# Cai app cho VPS S Hunt
# UniKey, VS Code, Git, NodeJS+Codex CLI, Docker+WSL2,
# Signal, Telegram, Chrome, Google Drive
# + Shortcut Google Workspace (Docs/Sheets/Slides/Gmail/Meet/Calendar)
#
# NOTE: Homebrew = macOS/Linux only, Windows KHONG co
#       (tuong duong = winget/Chocolatey/Scoop, VPS da co winget)
# ============================================================

# Auto self-elevate neu chua phai admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang tu nang cap quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Continue"
$ghBase = "https://github.com/ryanluga2931-bit/mdm-packages/releases/download/v1.0"
$tmp = "$env:TEMP\SHuntInstall"
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

function AddWebShortcut($name, $url, $chromePath) {
    $publicLnk = "$env:PUBLIC\Desktop\$name.lnk"
    if (Test-Path $publicLnk) { return }
    if (-not (Test-Path $chromePath)) { return }
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($publicLnk)
    $sc.TargetPath = $chromePath
    # Mo dang app window (khong thanh dia chi) cho giong app
    $sc.Arguments = "--app=$url"
    $sc.Save()
    Write-Host "  [OK] Shortcut web '$name' tao xong" -ForegroundColor Green
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
# [2] Google Chrome (can truoc de lam shortcut Workspace)
# ============================================================
Write-Host ""
Write-Host "=== [2/9] Google Chrome ===" -ForegroundColor Cyan
$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromeExe) {
    Write-Host "  [SKIP] Chrome da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Chrome qua winget..." -ForegroundColor Yellow
    winget install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Chrome cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\ChromeSetup.exe"
        if (Download "Chrome" "https://dl.google.com/chrome/install/latest/chrome_installer.exe" $f) {
            RunInstaller "Chrome" $f "/silent /install"
        }
    }
} else {
    $f = "$tmp\ChromeSetup.exe"
    if (Download "Chrome" "https://dl.google.com/chrome/install/latest/chrome_installer.exe" $f) {
        RunInstaller "Chrome" $f "/silent /install"
    }
}

# ============================================================
# [3] VS Code
# ============================================================
Write-Host ""
Write-Host "=== [3/9] VS Code ===" -ForegroundColor Cyan
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
# [4] Git
# ============================================================
Write-Host ""
Write-Host "=== [4/9] Git ===" -ForegroundColor Cyan
$gitExe = "C:\Program Files\Git\bin\git.exe"
if (Test-Path $gitExe) {
    Write-Host "  [SKIP] Git da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Git qua winget..." -ForegroundColor Yellow
    winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Git cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\GitSetup.exe"
        if (Download "Git" "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe" $f) {
            RunInstaller "Git" $f "/VERYSILENT /NORESTART /NOCANCEL /SP-"
        }
    }
} else {
    $f = "$tmp\GitSetup.exe"
    if (Download "Git" "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe" $f) {
        RunInstaller "Git" $f "/VERYSILENT /NORESTART /NOCANCEL /SP-"
    }
}

# ============================================================
# [5] NodeJS LTS + Codex CLI (npm)
# ============================================================
Write-Host ""
Write-Host "=== [5/9] NodeJS LTS + Codex CLI ===" -ForegroundColor Cyan
$nodeExe = "C:\Program Files\nodejs\node.exe"
if (Test-Path $nodeExe) {
    Write-Host "  [SKIP] NodeJS da co: $(& $nodeExe --version 2>&1)" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai NodeJS LTS qua winget..." -ForegroundColor Yellow
    winget install --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] NodeJS LTS cai xong" -ForegroundColor Green }
    else { Write-Host "  [WARN] winget NodeJS exit: $LASTEXITCODE" -ForegroundColor Yellow }
} else {
    $f = "$tmp\NodeSetup.msi"
    if (Download "NodeJS LTS" "https://nodejs.org/dist/lts/node-lts-x64.msi" $f) {
        RunInstaller "NodeJS" "msiexec.exe" "/i `"$f`" /qn /norestart ADDLOCAL=ALL"
    }
}

# Cai Codex CLI qua npm (npm o C:\Program Files\nodejs sau khi cai)
$npmCmd = "C:\Program Files\nodejs\npm.cmd"
if (Test-Path $npmCmd) {
    Write-Host "  [.] Cai Codex CLI (npm i -g @openai/codex)..." -ForegroundColor Yellow
    & $npmCmd install -g "@openai/codex" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Codex CLI cai xong (go 'codex' trong terminal, can login OpenAI)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] npm install codex loi - thu tay: npm i -g @openai/codex" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] Chua co npm - mo PS moi roi chay: npm i -g @openai/codex" -ForegroundColor Yellow
}

# ============================================================
# [6] Signal
# ============================================================
Write-Host ""
Write-Host "=== [6/9] Signal ===" -ForegroundColor Cyan
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
# [7] Telegram
# ============================================================
Write-Host ""
Write-Host "=== [7/9] Telegram ===" -ForegroundColor Cyan
$tgExe = "$env:APPDATA\Telegram Desktop\Telegram.exe"
if (Test-Path $tgExe) {
    Write-Host "  [SKIP] Telegram da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Telegram qua winget..." -ForegroundColor Yellow
    winget install --id Telegram.TelegramDesktop --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Telegram cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\TelegramSetup.exe"
        if (Download "Telegram" "https://telegram.org/dl/desktop/win64" $f) { RunInstaller "Telegram" $f "/S" }
    }
} else {
    $f = "$tmp\TelegramSetup.exe"
    if (Download "Telegram" "https://telegram.org/dl/desktop/win64" $f) { RunInstaller "Telegram" $f "/S" }
}
AddShortcut "Telegram" $tgExe

# ============================================================
# [8] Google Drive for Desktop
# ============================================================
Write-Host ""
Write-Host "=== [8/9] Google Drive ===" -ForegroundColor Cyan
$driveExe = "C:\Program Files\Google\Drive File Stream\*\GoogleDriveFS.exe"
if (Test-Path $driveExe) {
    Write-Host "  [SKIP] Google Drive da cai" -ForegroundColor Cyan
} elseif (Get-Command winget -EA SilentlyContinue) {
    Write-Host "  [.] Cai Google Drive qua winget..." -ForegroundColor Yellow
    winget install --id Google.Drive --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Google Drive cai xong" -ForegroundColor Green }
    else {
        $f = "$tmp\GoogleDriveSetup.exe"
        if (Download "Google Drive" "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe" $f) {
            RunInstaller "Google Drive" $f "--silent --desktop_shortcut"
        }
    }
} else {
    $f = "$tmp\GoogleDriveSetup.exe"
    if (Download "Google Drive" "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe" $f) {
        RunInstaller "Google Drive" $f "--silent --desktop_shortcut"
    }
}

# ============================================================
# [9] Docker Desktop + WSL2 (2-phase)
# ============================================================
Write-Host ""
Write-Host "=== [9/9] WSL2 + Docker Desktop ===" -ForegroundColor Cyan
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
    if (CheckReg "Docker Desktop") {
        Write-Host "  [SKIP] Docker Desktop da cai" -ForegroundColor Cyan
    } else {
        $f = "$tmp\DockerSetup.exe"
        if (Download "Docker Desktop" "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" $f) {
            RunInstaller "Docker Desktop" $f "install --quiet --accept-license --backend=wsl-2"
        }
    }
    AddShortcut "Docker Desktop" "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
}

# ============================================================
# Shortcut Google Workspace (mo bang Chrome dang app)
# ============================================================
Write-Host ""
Write-Host "=== Shortcut Google Workspace ===" -ForegroundColor Cyan
if (Test-Path $chromeExe) {
    AddWebShortcut "Gmail"            "https://mail.google.com"      $chromeExe
    AddWebShortcut "Google Docs"      "https://docs.google.com"      $chromeExe
    AddWebShortcut "Google Sheets"    "https://sheets.google.com"    $chromeExe
    AddWebShortcut "Google Slides"    "https://slides.google.com"    $chromeExe
    AddWebShortcut "Google Meet"      "https://meet.google.com"      $chromeExe
    AddWebShortcut "Google Calendar"  "https://calendar.google.com"  $chromeExe
} else {
    Write-Host "  [WARN] Chua co Chrome - bo qua shortcut Workspace" -ForegroundColor Yellow
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
Write-Host " HOAN TAT - S Hunt VPS" -ForegroundColor Green
Write-Host "  1. UniKey          6. Signal" -ForegroundColor White
Write-Host "  2. Chrome          7. Telegram" -ForegroundColor White
Write-Host "  3. VS Code         8. Google Drive" -ForegroundColor White
Write-Host "  4. Git             9. WSL2 + Docker" -ForegroundColor White
Write-Host "  5. NodeJS + Codex CLI" -ForegroundColor White
Write-Host "  + Shortcut Workspace: Gmail/Docs/Sheets/Slides/Meet/Calendar" -ForegroundColor White
Write-Host "  * Homebrew: macOS only (Windows dung winget thay the)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [!] Codex: mo terminal go 'codex' -> login OpenAI lan dau" -ForegroundColor Yellow
Write-Host "  [!] Docker WSL loi -> restart may + chay lai script" -ForegroundColor Yellow
Write-Host ""
pause
