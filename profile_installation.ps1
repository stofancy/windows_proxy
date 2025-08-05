
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



# Copy Set-Proxy.ps1, Unset-Proxy.ps1, and proxy_tools folder to the user's WindowsPowerShell directory (overwrite)
$targetDir = Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell'
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$setProxySource = Join-Path $repoDir 'Set-Proxy.ps1'
$unsetProxySource = Join-Path $repoDir 'Unset-Proxy.ps1'
$proxyToolsSource = Join-Path $repoDir 'proxy_tools'
$setProxyTarget = Join-Path $targetDir 'Set-Proxy.ps1'
$unsetProxyTarget = Join-Path $targetDir 'Unset-Proxy.ps1'
$proxyToolsTarget = Join-Path $targetDir 'proxy_tools'

if (Test-Path $setProxySource) {
    Copy-Item -Path $setProxySource -Destination $setProxyTarget -Force
    Write-Host "[INFO] Copied Set-Proxy.ps1 to $setProxyTarget"
} else {
    Write-Host "[WARNING] Set-Proxy.ps1 not found in repo directory."
}
if (Test-Path $unsetProxySource) {
    Copy-Item -Path $unsetProxySource -Destination $unsetProxyTarget -Force
    Write-Host "[INFO] Copied Unset-Proxy.ps1 to $unsetProxyTarget"
} else {
    Write-Host "[WARNING] Unset-Proxy.ps1 not found in repo directory."
}
if (Test-Path $proxyToolsSource) {
    if (Test-Path $proxyToolsTarget) {
        Remove-Item -Path $proxyToolsTarget -Recurse -Force
    }
    Copy-Item -Path $proxyToolsSource -Destination $proxyToolsTarget -Recurse -Force
    Write-Host "[INFO] Copied proxy_tools folder to $proxyToolsTarget (overwrite)"
} else {
    Write-Host "[WARNING] proxy_tools folder not found in repo directory."
}

# Add the proxyoff function to the profile if not already present
$functionDefinition = @"
function proxyoff {
    & (Join-Path $env:USERPROFILE 'Documents\\WindowsPowerShell\\Unset-Proxy.ps1')
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
    & (Join-Path $env:USERPROFILE 'Documents\\WindowsPowerShell\\Set-Proxy.ps1')
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