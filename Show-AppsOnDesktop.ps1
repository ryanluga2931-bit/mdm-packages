# ============================================================
# Show-AppsOnDesktop.ps1
# Quet app da cai -> tao shortcut ra Desktop. Co roi thi SKIP.
# ============================================================

$ErrorActionPreference = "SilentlyContinue"
$desktop = "$env:PUBLIC\Desktop"
$userDesktop = "$env:USERPROFILE\Desktop"
$shell = New-Object -ComObject WScript.Shell
$made = 0; $skipped = 0; $notfound = 0

function MakeShortcut($name, $exe) {
    $pubLnk  = "$desktop\$name.lnk"
    $usrLnk  = "$userDesktop\$name.lnk"
    if ((Test-Path $pubLnk) -or (Test-Path $usrLnk)) {
        Write-Host "  [SKIP] $name (da co shortcut)" -ForegroundColor DarkGray
        $script:skipped++
        return
    }
    if (-not (Test-Path $exe)) {
        $script:notfound++
        return
    }
    $sc = $shell.CreateShortcut($pubLnk)
    $sc.TargetPath = $exe
    $sc.Save()
    Write-Host "  [OK] $name -> shortcut tao xong" -ForegroundColor Green
    $script:made++
}

# Resolve path co wildcard (vd version folder) -> exe that
function Resolve1($pattern) {
    $p = [System.Environment]::ExpandEnvironmentVariables($pattern)
    $found = Get-Item $p -EA SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }
    return $p
}

Write-Host ""
Write-Host "=== Tao shortcut app ra Desktop ===" -ForegroundColor Cyan
Write-Host ""

# Danh sach app: ten hien thi -> duong dan exe
$apps = @(
    @{ n = "UniKey";              e = "C:\Program Files\UniKey\UniKey\UniKeyNT.exe" }
    @{ n = "VipTalk";             e = "C:\Program Files\VipTalk\VipTalk.exe" }
    @{ n = "Signal";              e = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe" }
    @{ n = "Telegram";           e = "$env:APPDATA\Telegram Desktop\Telegram.exe" }
    @{ n = "Threema";             e = "$env:LOCALAPPDATA\Programs\Threema\Threema.exe" }

    # Browser
    @{ n = "Google Chrome";       e = "C:\Program Files\Google\Chrome\Application\chrome.exe" }
    @{ n = "Firefox";             e = "C:\Program Files\Mozilla Firefox\firefox.exe" }
    @{ n = "Opera";               e = "$env:LOCALAPPDATA\Programs\Opera\opera.exe" }
    @{ n = "Arc";                 e = "$env:LOCALAPPDATA\Arc\Arc.exe" }

    # Dev
    @{ n = "Visual Studio Code";  e = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" }
    @{ n = "VS Code (System)";    e = "C:\Program Files\Microsoft VS Code\Code.exe" }
    @{ n = "Cursor";              e = "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe" }
    @{ n = "GitHub Desktop";      e = "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe" }
    @{ n = "Postman";             e = "$env:LOCALAPPDATA\Postman\Postman.exe" }
    @{ n = "Android Studio";      e = "C:\Program Files\Android\Android Studio\bin\studio64.exe" }
    @{ n = "Docker Desktop";      e = "$env:LOCALAPPDATA\Docker\Docker Desktop.exe" }
    @{ n = "DBeaver";             e = "C:\DBeaver\dbeaver.exe" }
    @{ n = "Tabby";               e = "$env:LOCALAPPDATA\Programs\tabby\tabby.exe" }
    @{ n = "SourceTree";          e = "$env:LOCALAPPDATA\SourceTree\SourceTree.exe" }
    @{ n = "Git Bash";            e = "C:\Program Files\Git\git-bash.exe" }

    # Media / tools
    @{ n = "OBS Studio";          e = "C:\Program Files\obs-studio\bin\64bit\obs64.exe" }
    @{ n = "Figma";               e = "$env:LOCALAPPDATA\Figma\Figma.exe" }
    @{ n = "Effect House";        e = "$env:LOCALAPPDATA\Programs\ByteDance\EffectHouse\EffectHouse.exe" }
    @{ n = "Ditto";               e = "C:\Program Files\Ditto\Ditto.exe" }
    @{ n = "Bitwarden";           e = "$env:LOCALAPPDATA\Programs\Bitwarden\Bitwarden.exe" }
    @{ n = "AdsPower";            e = "$env:LOCALAPPDATA\Programs\adspower_global\AdsPower Global.exe" }
    @{ n = "Claude";             e = "$env:LOCALAPPDATA\AnthropicClaude\claude.exe" }
    @{ n = "ToolManager";         e = "C:\ToolManager\toolmanager-win32-x64\toolmanager.exe" }

    # VPN
    @{ n = "OpenVPN GUI";         e = "C:\Program Files\OpenVPN\bin\openvpn-gui.exe" }
    @{ n = "OpenVPN Connect";     e = "$env:LOCALAPPDATA\Programs\OpenVPN Connect\OpenVPN Connect.exe" }
    @{ n = "1.1.1.1 WARP";        e = "C:\Program Files\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe" }

    # CapCut co version folder -> resolve wildcard
    @{ n = "CapCut";              e = "$env:LOCALAPPDATA\CapCut\Apps\*\CapCut.exe" }
)

foreach ($a in $apps) {
    $exe = Resolve1 $a.e
    MakeShortcut $a.n $exe
}

# ============================================================
# Ket qua
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " XONG" -ForegroundColor Green
Write-Host "  Tao moi : $made shortcut" -ForegroundColor Green
Write-Host "  Skip    : $skipped (da co san)" -ForegroundColor DarkGray
Write-Host "  Khong co: $notfound app (chua cai)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Shortcut nam o: $desktop" -ForegroundColor Yellow
Write-Host ""
pause
