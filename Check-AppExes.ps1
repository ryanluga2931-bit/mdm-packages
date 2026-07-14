# ============================================================
# Check-AppExes.ps1
# Quet tat ca exe da cai tren VPS nay -> copy vao allow list
# ============================================================

$found = @()
$notFound = @()

function Check($label, $path) {
    $expanded = [System.Environment]::ExpandEnvironmentVariables($path)
    if (Test-Path $expanded) {
        $script:found += [PSCustomObject]@{ App = $label; Exe = (Split-Path $expanded -Leaf); Path = $expanded }
    } else {
        $script:notFound += $label
    }
}

# === App co ban ===
Check "UniKey"           "C:\Program Files\UniKey\UniKey\UniKeyNT.exe"
Check "VipTalk"          "C:\Program Files\VipTalk\VipTalk.exe"
Check "Signal"           "%LOCALAPPDATA%\Programs\signal-desktop\Signal.exe"
Check "Signal Helper"    "%LOCALAPPDATA%\Programs\signal-desktop\resources\app.asar.unpacked\node_modules\@signalapp\better-sqlite3\build\Release\better_sqlite3.node"

# === Dev tools ===
Check "VS Code"          "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"
Check "VS Code (System)" "C:\Program Files\Microsoft VS Code\Code.exe"
Check "Cursor"           "%LOCALAPPDATA%\Programs\cursor\Cursor.exe"
Check "GitHub Desktop"   "%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe"
Check "Postman"          "%LOCALAPPDATA%\Postman\Postman.exe"
Check "Postman Agent"    "%LOCALAPPDATA%\Postman\app-*\resources\app\extra\win\postman-agent.exe"
Check "Android Studio"   "C:\Program Files\Android\Android Studio\bin\studio64.exe"
Check "Docker Desktop"   "%LOCALAPPDATA%\Docker\Docker Desktop.exe"
Check "DBeaver"          "C:\DBeaver\dbeaver.exe"
Check "Tabby"            "%LOCALAPPDATA%\Programs\tabby\tabby.exe"
Check "SourceTree"       "%LOCALAPPDATA%\SourceTree\SourceTree.exe"
Check "OBS Studio"       "C:\Program Files\obs-studio\bin\64bit\obs64.exe"

# === Browser ===
Check "Chrome"           "C:\Program Files\Google\Chrome\Application\chrome.exe"
Check "Firefox"          "C:\Program Files\Mozilla Firefox\firefox.exe"
Check "Arc"              "%LOCALAPPDATA%\Arc\Arc.exe"

# === Runtime ===
Check "NodeJS"           "C:\Program Files\nodejs\node.exe"
Check "npm"              "C:\Program Files\nodejs\npm.cmd"
Check "Java (Temurin)"   "C:\Program Files\Eclipse Adoptium\jdk-21.0.0+0\bin\java.exe"

# === Tools ===
Check "Figma"            "%LOCALAPPDATA%\Figma\Figma.exe"
Check "Effect House"     "%LOCALAPPDATA%\Programs\ByteDance\EffectHouse\EffectHouse.exe"
Check "Ditto"            "C:\Program Files\Ditto\Ditto.exe"
Check "Bitwarden"        "%LOCALAPPDATA%\Programs\Bitwarden\Bitwarden.exe"
Check "Telegram"         "%APPDATA%\Telegram Desktop\Telegram.exe"
Check "CapCut"           "%LOCALAPPDATA%\CapCut\Apps\CapCut.exe"
Check "Chocolatey"       "C:\ProgramData\chocolatey\bin\choco.exe"
Check "Scoop"            "%USERPROFILE%\scoop\shims\scoop.ps1"

# === Exe he thong can allow cung ===
$sysExes = @(
    "node.exe",
    "java.exe",
    "javaw.exe",
    "git.exe",
    "git-remote-https.exe",
    "npm.cmd",
    "npx.cmd",
    "dockerd.exe",
    "com.docker.service",
    "wsl.exe",
    "wslhost.exe",
    "wslservice.exe",
    "adb.exe",
    "emulator.exe"
)

# === In ket qua ===
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " DA CAI ($($found.Count) app) - COPY VAO ALLOW LIST" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
foreach ($item in $found) {
    Write-Host "  [v] $($item.App.PadRight(20)) $($item.Exe)" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " EXE HE THONG CAN ALLOW THEM" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
foreach ($exe in $sysExes) {
    Write-Host "  [*] $exe" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " CHUA CAI ($($notFound.Count) app)" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
foreach ($name in $notFound) {
    Write-Host "  [ ] $name" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "--- DANH SACH EXE DE COPY (DA CAI) ---" -ForegroundColor Cyan
foreach ($item in $found) {
    Write-Host $item.Exe
}
Write-Host "--- HET ---" -ForegroundColor Cyan
Write-Host ""
pause
