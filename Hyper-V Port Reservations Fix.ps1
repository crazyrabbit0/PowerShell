# ==========================================
# AUTO-ELEVATION BLOCK
# ==========================================
# This checks if the script is running as Admin. 
# If not, it re-launches itself requesting Admin rights.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# ==========================================
# MAIN SCRIPT
# ==========================================
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "   Configuring Windows Dynamic Port Range" -ForegroundColor Cyan
Write-Host "   to exclude 3000-8000+ from Hyper-V" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# 1. Stop the WinNAT service
Write-Host "[1/4] Stopping Windows NAT Service (WinNAT)..." -ForegroundColor Yellow
$stopResult = cmd.exe /c "net stop winnat" 2>&1
if ($stopResult -match "The service is not started") {
    Write-Host "WinNAT was already stopped." -ForegroundColor Gray
}

# 2. Set IPv4 Dynamic Port Range
Write-Host "[2/4] Setting IPv4 Dynamic Port Range to start at 49152..." -ForegroundColor Yellow
netsh int ipv4 set dynamicport tcp start=49152 num=16384

# 3. Set IPv6 Dynamic Port Range
Write-Host "[3/4] Setting IPv6 Dynamic Port Range to start at 49152..." -ForegroundColor Yellow
netsh int ipv6 set dynamicport tcp start=49152 num=16384

# 4. Restart WinNAT
Write-Host "[4/4] Restarting Windows NAT Service..." -ForegroundColor Yellow
cmd.exe /c "net start winnat"

Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor Green
Write-Host "   SUCCESS!" -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Current Configuration (Start Port should be 49152):" -ForegroundColor White
netsh int ipv4 show dynamicport tcp

Write-Host ""
Write-Host "IMPORTANT: Please Restart Docker Desktop / WSL for these changes to apply fully." -ForegroundColor Red
Write-Host ""
Read-Host -Prompt "Press Enter to close this window"