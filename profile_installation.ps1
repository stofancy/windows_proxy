
$profileDir = Split-Path -Parent $PROFILE
if (!(Test-Path $profileDir)) {
    Write-Host "[INFO] Creating profile directory: $profileDir"
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
} else {
    Write-Host "[INFO] Profile directory already exists: $profileDir"
}
if (!(Test-Path $PROFILE)) {
    Write-Host "[INFO] Creating profile file: $PROFILE"
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
} else {
    Write-Host "[INFO] Profile file already exists: $PROFILE"
}


# Add the proxyoff function to the profile if not already present
$functionDefinition = @"
function proxyoff {
    & 'C:\Users\ztmdsbt\Desktop\Unset-Proxy.ps1'
}
"@
if (-not (Select-String -Path $PROFILE -Pattern 'function proxyoff' -Quiet)) {
    Write-Host "[INFO] Adding 'proxyoff' function to profile."
    Add-Content -Path $PROFILE -Value $functionDefinition
} else {
    Write-Host "[INFO] 'proxyoff' function already exists in profile."
}

# Add the proxyon function to the profile if not already present
$proxyOnDefinition = @"
function proxyon {
    & 'C:\Users\ztmdsbt\Documents\WindowsPowerShell\Set-Proxy.ps1'C:\Users\ztmdsbt\Desktop\Unset-Proxy.ps1
}
"@
if (-not (Select-String -Path $PROFILE -Pattern 'function proxyon' -Quiet)) {
    Write-Host "[INFO] Adding 'proxyon' function to profile."
    Add-Content -Path $PROFILE -Value $proxyOnDefinition
} else {
    Write-Host "[INFO] 'proxyon' function already exists in profile."
}

# Reload the profile
Write-Host "[INFO] Reloading PowerShell profile..."
. $PROFILE
Write-Host "[SUCCESS] Profile installation complete. You can now use the 'proxyon' and 'proxyoff' commands in your PowerShell sessions."