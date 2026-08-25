# ===== CÀI OpenSSH (tu GitHub) + MO PORT + bat sshd =====
# Chay QUYEN ADMIN. Tailscale khong can mo port Azure - chi mo firewall Windows noi bo.
$ErrorActionPreference="Continue"
$REL="https://github.com/ryanluga2931-bit/mdm-packages/releases/download/ssh-tools"
Write-Host "===== SETUP SSH cho Tailscale =====" -ForegroundColor Cyan

Write-Host "1. Tai OpenSSH-Win64 tu GitHub..." -ForegroundColor Cyan
$zip="$env:TEMP\OpenSSH-Win64.zip"
Invoke-WebRequest "$REL/OpenSSH-Win64.zip" -OutFile $zip -UseBasicParsing
Expand-Archive $zip "C:\Program Files\OpenSSH-Win64" -Force -EA SilentlyContinue
$sshdir="C:\Program Files\OpenSSH-Win64"

Write-Host "2. Cai sshd service..." -ForegroundColor Cyan
& "$sshdir\install-sshd.ps1"
Set-Service sshd -StartupType Automatic
Set-Service ssh-agent -StartupType Automatic -EA SilentlyContinue

Write-Host "3. MO PORT 22 tren Windows Firewall (noi bo - KHONG can Azure NSG)..." -ForegroundColor Cyan
Remove-NetFirewallRule -Name "OpenSSH-In" -EA SilentlyContinue
New-NetFirewallRule -Name "OpenSSH-In" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
# cho phep tren MOI profile (Domain/Private/Public) - Tailscale interface hay la Public
Set-NetFirewallRule -Name "OpenSSH-In" -Profile Any -EA SilentlyContinue

Write-Host "4. Start sshd..." -ForegroundColor Cyan
Start-Service sshd
Start-Service ssh-agent -EA SilentlyContinue

Write-Host "5. Kiem tra:" -ForegroundColor Cyan
Get-Service sshd | Select Name,Status,StartType | Format-Table
Write-Host "   Port 22 listening:" -NoNewline
$l=Get-NetTCPConnection -LocalPort 22 -State Listen -EA SilentlyContinue
Write-Host $(if($l){" YES ($($l.Count) listener)"}else{" NO"})

Write-Host "`n===== XONG =====" -ForegroundColor Cyan
Write-Host ">>> SSH da san sang. Lay Tailscale IP:" -ForegroundColor Yellow
tailscale ip -4 2>$null
Write-Host ">>> Gui cho IT: Tailscale IP + username Windows + password" -ForegroundColor Green
