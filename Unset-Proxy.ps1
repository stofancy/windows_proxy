<#
.SYNOPSIS
    Quickly removes HTTP/HTTPS proxy settings for Git, npm, Node.js, and environment variables.
.DESCRIPTION
    - Checks for dependencies (Git, npm) before running.
    - Uses fast registry edits to minimize delay.
    - Warns if Node.js is missing and suggests nvm-windows.
    - Prompts user to re-run after switching Node versions.
    - Advises restarting the shell for changes to fully apply.
.NOTES
    Run as Admin for system-wide changes.
#>

function Test-CommandExists($command) {
    return $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

Write-Host "=== Fast Proxy Cleanup ===" -ForegroundColor Cyan

# Git (if installed)
if (Test-CommandExists "git") {
    Write-Host "Removing Git proxy settings..." -ForegroundColor Cyan
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}
else {
    Write-Host "Git not found. Skipping Git proxy cleanup." -ForegroundColor Yellow
}

# npm (if installed)
$usingNvm = $false
if (Test-CommandExists "npm") {
    Write-Host "Removing npm proxy settings..." -ForegroundColor Cyan
    npm config delete proxy
    npm config delete https-proxy
}
elseif (Test-CommandExists "nvm") {
    $usingNvm = $true
    Write-Host "npm not found, but nvm is installed." -ForegroundColor Yellow
    Write-Host "Tip: Proxy settings are per-Node-version. Re-run this script after switching versions." -ForegroundColor Magenta
}
else {
    Write-Host "Node.js/npm not found. Skipping npm proxy cleanup." -ForegroundColor Yellow
    Write-Host "Tip: Install Node.js or use nvm-windows to manage versions:" -ForegroundColor DarkGray
    Write-Host "  winget install nvm-windows" -ForegroundColor Magenta
    Write-Host "  nvm install {{version}}" -ForegroundColor Magenta
    Write-Host "  nvm use {{version}}" -ForegroundColor Magenta
}

# Clear session variables (instant)
$proxyVars = @("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy")
foreach ($var in $proxyVars) {
    Remove-Item "Env:\$var" -ErrorAction SilentlyContinue
}

# Fast User/Machine cleanup (registry-based)
foreach ($var in $proxyVars) {
    # User scope
    if ($null -ne [Environment]::GetEnvironmentVariable($var, "User")) {
        Set-ItemProperty -Path "HKCU:\Environment" -Name $var -Value $null -ErrorAction SilentlyContinue
    }
    # Machine scope (Admin only)
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
        if (Get-ItemProperty -Path $regPath -Name $var -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $regPath -Name $var -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`nProxy cleanup completed!" -ForegroundColor Green
if ($usingNvm) {
    Write-Host "Reminder: If you switch Node.js versions via nvm, re-run this script to clear proxy for the new version." -ForegroundColor Magenta
}
Write-Host "Note: Sign out or restart your shell to ensure all changes take effect." -ForegroundColor Magenta