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


# Load and call unset-proxy functions for each tool in proxy_tools, only if the tool is installed (file name = tool command)
$proxyToolsPath = Join-Path $PSScriptRoot 'proxy_tools'
if (Test-Path $proxyToolsPath) {
    $toolFiles = Get-ChildItem -Path $proxyToolsPath -Filter '*.ps1' | Sort-Object Name
    foreach ($toolFile in $toolFiles) {
        $toolName = $toolFile.BaseName
        if ($toolName -eq 'env') {
            # Always run env
            . $toolFile.FullName
            $unsetFunc = (Get-Content $toolFile.FullName | Select-String -Pattern 'function (Unset-[A-Za-z]+Proxy)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
            if ($unsetFunc) {
                try {
                    & $unsetFunc
                    Write-Host "Unset proxy for $toolName using $unsetFunc" -ForegroundColor Cyan
                } catch {
                Write-Host ("Failed to unset proxy for {0}: {1}" -f $toolName, $error[0]) -ForegroundColor Yellow
                }
            }
            continue
        }
        # For all other tools, check if tool exists
        if ($null -eq (Get-Command $toolName -ErrorAction SilentlyContinue)) {
            Write-Host "[$toolName] Not installed. Skipping $toolName proxy cleanup." -ForegroundColor Yellow
            continue
        }
        . $toolFile.FullName
        $unsetFunc = (Get-Content $toolFile.FullName | Select-String -Pattern 'function (Unset-[A-Za-z]+Proxy)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
        if ($unsetFunc) {
            try {
                & $unsetFunc
                Write-Host "Unset proxy for $toolName using $unsetFunc" -ForegroundColor Cyan
            } catch {
                Write-Host ("Failed to unset proxy for {0}: {1}" -f $toolName, $error[0]) -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "proxy_tools folder not found. No tool-specific proxy cleanup applied." -ForegroundColor Yellow
}

Write-Host "`nProxy cleanup completed!" -ForegroundColor Green
if ($usingNvm) {
    Write-Host "Reminder: If you switch Node.js versions via nvm, re-run this script to clear proxy for the new version." -ForegroundColor Magenta
}
Write-Host "Note: Sign out or restart your shell to ensure all changes take effect." -ForegroundColor Magenta