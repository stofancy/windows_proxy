
# ===============================
# Fast Proxy Setup Wizard
# ===============================
# Quickly sets HTTP/HTTPS proxy settings for Git, npm, Node.js, and environment variables.
# - Reads current environment proxy variables.
# - Prompts user to use existing or input new proxy settings.
# - Supports proxy authentication.
# - Applies proxy to Git, npm, and environment variables.
# Note: Run as Admin for system-wide changes.
# ===============================

# ===============================
# Helper Functions
# ===============================

# Read proxy environment variables
function Get-ProxyEnv {
    $envVars = @('HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy')
    $proxies = @{}
    foreach ($var in $envVars) {
        $val = [Environment]::GetEnvironmentVariable($var, 'User')
        if (-not $val) { $val = [Environment]::GetEnvironmentVariable($var, 'Process') }
        if ($val) { $proxies[$var] = $val }
    }
    return $proxies
}

# Prompt user for Yes/No
function Ask-YesNo($message, $defaultYes=$true) {
    $default = if ($defaultYes) { 'Y' } else { 'N' }
    while ($true) {
        $promptMsg = "$message [Y/N, default: $default]"
        $userInput = Read-Host $promptMsg
        if ([string]::IsNullOrWhiteSpace($userInput)) { return ($default -eq 'Y') }
        $inputUpper = $userInput.Trim().ToUpper()
        if ($inputUpper -eq 'Y') { return $true }
        if ($inputUpper -eq 'N') { return $false }
        Write-Host "  Invalid input. Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Yellow
    }
}

# Check if a command exists in PATH
function Test-CommandExists($command) {
    return $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# Clean up proxy string, optionally remove credentials
function Fix-ProxyFormat($proxy, $removeCred=$true) {
    if (-not $proxy) { return $null }
    $fixed = $proxy
    $fixed = $fixed -replace '(:@:?)+', '' # Remove repeated :@:
    if ($removeCred) {
        $fixed = $fixed -replace '^(http[s]?://)?([^@/]+:[^@/]+@)', '$1' # Remove credentials
    }
    if ($fixed -notmatch '^(http|https)://') { $fixed = "http://$fixed" } # Add protocol if missing
    $fixed = $fixed -replace '^(http|https)://(http|https)://', '$1://'
    $fixed = $fixed -replace '^@+', '' # Remove leading @
    return $fixed
}

# Validate proxy string format
function Validate-ProxyFormat($proxy) {
    return $proxy -match '^(http|https)://([^:/@]+(:[^@]+)?@)?[^:/]+(:\d+)?$' -or $proxy -match '^([^:/@]+(:[^@]+)?@)?[^:/]+(:\d+)?$'
}

# Test proxy connectivity
function Test-Proxy($proxy) {
    try {
        $testUrl = 'http://www.msftconnecttest.com/connecttest.txt'
        $wc = New-Object System.Net.WebClient
        $wc.Proxy = New-Object System.Net.WebProxy($proxy)
        $wc.DownloadString($testUrl) | Out-Null
        return $true
    } catch { return $false }
}

# Ensure proxy string has protocol
function Ensure-ProxyProtocol($proxy, $defaultProto='http') {
    if (-not $proxy) { return '' }
    if ($proxy -notmatch '^(http|https)://') {
        return "${defaultProto}://$proxy"
    }
    return $proxy
}

# Prompt for a valid proxy string
function Prompt-ValidProxy($label, $proxy) {
    while (-not (Validate-ProxyFormat $proxy)) {
        Write-Host "The $label proxy value '$proxy' is not in a valid format. Please enter a valid proxy (host:port or http[s]://host:port):" -ForegroundColor Yellow
        $proxy = Read-Host "$label proxy"
    }
    return $proxy
}

# Mask credentials in proxy URL for display
function Mask-ProxyAuth($url) {
    if ($url -match '^(http[s]?://)([^:/@]+):([^@]+)@(.+)$') {
        return "$($matches[1])$($matches[2]):******@$($matches[4])"
    } else {
        return $url
    }
}

# ===============================
# Main Script Logic
# ===============================

function Read-ProxyEnv {
    $envVars = @('HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy')
    $proxies = @{}
    foreach ($var in $envVars) {
        $val = [Environment]::GetEnvironmentVariable($var, 'User')
        if (-not $val) { $val = [Environment]::GetEnvironmentVariable($var, 'Process') }
        if ($val) { $proxies[$var] = $val }
    }
    return $proxies
}

function Ask-YesNo($message, $defaultYes=$true) {
    $default = if ($defaultYes) { 'Y' } else { 'N' }
    while ($true) {
        $promptMsg = "$message [Y/N, default: $default]"
        $userInput = Read-Host $promptMsg
        if ([string]::IsNullOrWhiteSpace($userInput)) { return ($default -eq 'Y') }
        $inputUpper = $userInput.Trim().ToUpper()
        if ($inputUpper -eq 'Y') { return $true }
        if ($inputUpper -eq 'N') { return $false }
        Write-Host "  Invalid input. Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Yellow
    }
}


# Helper: Check if a command exists in PATH
function Test-CommandExists($command) {
    return $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

Write-Host "===============================" -ForegroundColor Cyan
Write-Host "Fast Proxy Setup Wizard" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "Step 1: Check for existing proxy environment variables." -ForegroundColor Cyan
$proxies = Read-ProxyEnv
$hasProxy = $proxies.Values | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count

if ($hasProxy) {
    # Helper to mask credentials in proxy URL for display
    function Mask-ProxyAuth($url) {
        if ($url -match '^(http[s]?://)([^:/@]+):([^@]+)@(.+)$') {
            return "$($matches[1])$($matches[2]):******@$($matches[4])"
        } else {
            return $url
        }
    }
    Write-Host "  Found the following proxy environment variables:" -ForegroundColor Yellow
    foreach ($k in $proxies.Keys) { Write-Host "    $k = $(Mask-ProxyAuth $proxies[$k])" -ForegroundColor DarkGray }
    Write-Host "Step 2: Would you like to use these detected proxy settings for all tools?" -ForegroundColor Cyan
    $useEnv = Ask-YesNo "Use these detected proxy settings for all tools?", $true
} else {
    Write-Host "  No proxy environment variables detected." -ForegroundColor Yellow
    Write-Host "Step 2: You will need to enter your proxy details manually." -ForegroundColor Cyan
    $useEnv = $false
}

function Fix-ProxyFormat($proxy, $removeCred=$true) {
    if (-not $proxy) { return $null }
    $fixed = $proxy
    # Remove repeated :@:
    $fixed = $fixed -replace '(:@:?)+', ''
    # Only remove credentials if explicitly requested
    if ($removeCred) {
        # Remove username:password@ if present, but preserve host:port
        $fixed = $fixed -replace '^(http[s]?://)?([^@/]+:[^@/]+@)', '$1'
    }
    # Add protocol if missing
    if ($fixed -notmatch '^(http|https)://') { $fixed = "http://$fixed" }
    # Remove duplicate protocol
    $fixed = $fixed -replace '^(http|https)://(http|https)://', '$1://'
    # Remove leading @
    $fixed = $fixed -replace '^@+', ''
    return $fixed
}

function Validate-ProxyFormat($proxy) {
    # Accept http[s]://host:port, http[s]://user:pass@host:port, host:port, or user:pass@host:port
    return $proxy -match '^(http|https)://([^:/@]+(:[^@]+)?@)?[^:/]+(:\d+)?$' -or $proxy -match '^([^:/@]+(:[^@]+)?@)?[^:/]+(:\d+)?$'
}

function Test-Proxy($proxy) {
    try {
        $testUrl = 'http://www.msftconnecttest.com/connecttest.txt'
        $wc = New-Object System.Net.WebClient
        $wc.Proxy = New-Object System.Net.WebProxy($proxy)
        $wc.DownloadString($testUrl) | Out-Null
        return $true
    } catch { return $false }
}

if ($useEnv) {
    $proxyUrl = $proxies['HTTP_PROXY']
    if (-not $proxyUrl) { $proxyUrl = $proxies['http_proxy'] }
    $httpsProxyUrl = $proxies['HTTPS_PROXY']
    if (-not $httpsProxyUrl) { $httpsProxyUrl = $proxies['https_proxy'] }
    Write-Host "Step 3: Using detected environment proxy settings." -ForegroundColor Cyan

    # Auto-fix malformed proxy values, but do NOT remove credentials by default
    $fixedProxyUrl = Fix-ProxyFormat $proxyUrl $false
    $fixedHttpsProxyUrl = Fix-ProxyFormat $httpsProxyUrl $false
    if ($proxyUrl -ne $fixedProxyUrl -or $httpsProxyUrl -ne $fixedHttpsProxyUrl) {
        Write-Host "Detected malformed proxy values:" -ForegroundColor Yellow
        Write-Host "  HTTP_PROXY: $proxyUrl -> $fixedProxyUrl" -ForegroundColor DarkGray
        Write-Host "  HTTPS_PROXY: $httpsProxyUrl -> $fixedHttpsProxyUrl" -ForegroundColor DarkGray
        $approveFix = Ask-YesNo "Auto-fix proxy values as shown above?", $true
        if ($approveFix) {
            $proxyUrl = $fixedProxyUrl
            $httpsProxyUrl = $fixedHttpsProxyUrl
            Write-Host "Proxy values auto-fixed." -ForegroundColor Green
        } else {
            Write-Host "Keeping original proxy values." -ForegroundColor Yellow
        }
    }
} else {
    $defaultHost = ''
    $defaultPort = ''
    if ($proxies['HTTP_PROXY']) {
        # Remove credentials if present before extracting host/port
        $proxyNoCred = $proxies['HTTP_PROXY']
        # Remove protocol if present
        $proxyNoCred = $proxyNoCred -replace '^(http[s]?://)', ''
        # Remove credentials if present
        if ($proxyNoCred -match '^([^@/]+:[^@/]+)@(.+)$') {
            $proxyNoCred = $matches[2]
        }
        # Now extract host and port
        if ($proxyNoCred -match '^([^:/]+)(?::(\d+))?') {
            $defaultHost = $matches[1]
            $defaultPort = $matches[2]
        }
    }
    Write-Host "Step 3: Please enter your proxy server details below." -ForegroundColor Cyan
    $hostPrompt = if ($defaultHost) { "Enter proxy host [Default: $defaultHost]" } else { "Enter proxy host (required)" }
    $proxyHost = Read-Host $hostPrompt
    if (-not $proxyHost -and $defaultHost) { $proxyHost = $defaultHost }
    while (-not $proxyHost) {
        $proxyHost = Read-Host "Proxy host is required. Please enter proxy host:"
    }
    $portPrompt = if ($defaultPort) { "Enter proxy port [Default: $defaultPort]" } else { "Enter proxy port (required)" }
    $proxyPort = Read-Host $portPrompt
    if (-not $proxyPort -and $defaultPort) { $proxyPort = $defaultPort }
    while (-not $proxyPort) {
        $proxyPort = Read-Host "Proxy port is required. Please enter proxy port:"
    }
    $protoChoice = Ask-YesNo "Use 'http' as the proxy protocol? (Y for http, N for https)", $true
    $proxyProto = if ($protoChoice) { 'http' } else { 'https' }
    $proxyUrl = "${proxyProto}://${proxyHost}:$proxyPort"
    $httpsProxyUrl = $proxyUrl
}


# Validate and ensure protocol for proxy values
function Ensure-ProxyProtocol($proxy, $defaultProto='http') {
    if (-not $proxy) { return '' }
    if ($proxy -notmatch '^(http|https)://') {
        return "${defaultProto}://$proxy"
    }
    return $proxy
}
function Prompt-ValidProxy($label, $proxy) {
    while (-not (Validate-ProxyFormat $proxy)) {
        Write-Host "The $label proxy value '$proxy' is not in a valid format. Please enter a valid proxy (host:port or http[s]://host:port):" -ForegroundColor Yellow
        $proxy = Read-Host "$label proxy"
    }
    return $proxy
}

$proxyUrl = Prompt-ValidProxy 'HTTP' $proxyUrl
$httpsProxyUrl = Prompt-ValidProxy 'HTTPS' $httpsProxyUrl
$proxyUrl = Ensure-ProxyProtocol $proxyUrl 'http'
$httpsProxyUrl = Ensure-ProxyProtocol $httpsProxyUrl 'http'


# Test proxy connectivity with up to 3 retries, but stop immediately if successful
function Test-ProxyWithRetry($label, $proxy) {
    $maxAttempts = 3
    for ($attempts = 0; $attempts -lt $maxAttempts; $attempts++) {
        Write-Host "Testing $label proxy connectivity (attempt $($attempts+1)/$maxAttempts)..." -ForegroundColor Cyan
        if (Test-Proxy $proxy) {
            Write-Host "  $label proxy test succeeded." -ForegroundColor Green
            return @{ success = $true; value = $proxy }
        } else {
            Write-Host "  $label proxy test failed." -ForegroundColor Yellow
        }
    }
    Write-Host "  $label proxy test failed after $maxAttempts attempts." -ForegroundColor Red
    return @{ success = $false; value = $proxy }
}
$proxyUsername = Read-Host "Enter proxy username (leave blank to skip authentication)"
$proxyUrlWithAuth = $proxyUrl
$httpsProxyUrlWithAuth = $httpsProxyUrl
if ($proxyUsername) {
    $proxyPassword = Read-Host "Enter proxy password" -AsSecureString
    if (-not $proxyPassword) {
        Write-Host "  No password entered. Skipping proxy authentication." -ForegroundColor Yellow
    } else {
        $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($proxyPassword))
        $authPrefix = "${proxyUsername}:$plainPass@"
        if ($proxyUrl -match '^(http[s]?://)(.+)$') {
            $proxyUrlWithAuth = "$($matches[1])$authPrefix$($matches[2])"
        }
        if ($httpsProxyUrl -match '^(http[s]?://)(.+)$') {
            $httpsProxyUrlWithAuth = "$($matches[1])$authPrefix$($matches[2])"
        }
        Write-Host "  Proxy authentication will be used for all tools." -ForegroundColor Cyan
    }
} else {
    Write-Host "  No proxy authentication will be used." -ForegroundColor Cyan
}

# Test proxy connectivity with up to 3 retries on the final (with-auth if provided) URLs
$httpTest = Test-ProxyWithRetry 'HTTP' $proxyUrlWithAuth
$httpsTest = Test-ProxyWithRetry 'HTTPS' $httpsProxyUrlWithAuth
$proxyUrl = $httpTest.value
$httpsProxyUrl = $httpsTest.value


# Test proxy connectivity with up to 3 retries
function Test-ProxyWithRetry($label, $proxy) {
    $attempts = 0
    $maxAttempts = 3
    while ($attempts -lt $maxAttempts) {
        Write-Host "Testing $label proxy connectivity (attempt $($attempts+1)/$maxAttempts)..." -ForegroundColor Cyan
        if (Test-Proxy $proxy) {
            Write-Host "  $label proxy test succeeded." -ForegroundColor Green
            return @{ success = $true; value = $proxy }
        } else {
            Write-Host "  $label proxy test failed." -ForegroundColor Yellow
            $attempts++
        }
    }
    Write-Host "  $label proxy test failed after $maxAttempts attempts." -ForegroundColor Red
    return @{ success = $false; value = $proxy }
}




# Show final settings and ask for approval
Write-Host ""

# Helper to mask credentials in proxy URL for display
function Mask-ProxyAuth($url) {
    if ($url -match '^(http[s]?://)([^:/@]+):([^@]+)@(.+)$') {
        return "$($matches[1])$($matches[2]):******@$($matches[4])"
    } else {
        return $url
    }
}

Write-Host "Final proxy settings for all tools and environment variables:" -ForegroundColor Cyan
Write-Host "  HTTP_PROXY: $(Mask-ProxyAuth $proxyUrl)" -ForegroundColor DarkGray
Write-Host "  HTTPS_PROXY: $(Mask-ProxyAuth $httpsProxyUrl)" -ForegroundColor DarkGray

# Show Git proxy config if git is installed
if (Test-CommandExists "git") {
    Write-Host "  Git http.proxy: $(Mask-ProxyAuth $proxyUrl)" -ForegroundColor DarkGray
    Write-Host "  Git https.proxy: $(Mask-ProxyAuth $httpsProxyUrl)" -ForegroundColor DarkGray
} else {
    Write-Host "  Git: not installed or not found in PATH" -ForegroundColor DarkGray
}

# Show npm proxy config if npm is installed
if (Test-CommandExists "npm") {
    Write-Host "  npm proxy: $(Mask-ProxyAuth $proxyUrl)" -ForegroundColor DarkGray
    Write-Host "  npm https-proxy: $(Mask-ProxyAuth $httpsProxyUrl)" -ForegroundColor DarkGray
} else {
    Write-Host "  npm: not installed or not found in PATH" -ForegroundColor DarkGray
}

if (-not $httpTest.success -or -not $httpsTest.success) {
    Write-Host "Warning: One or more proxy connectivity tests failed." -ForegroundColor Yellow
    $applyAnyway = Ask-YesNo "Do you want to continue and apply these proxy settings anyway?", $false
    if (-not $applyAnyway) {
        Write-Host "Proxy setup cancelled by user." -ForegroundColor Yellow
        exit
    }
} else {
    $confirmApply = Ask-YesNo "Apply these proxy settings?", $true
    if (-not $confirmApply) {
        Write-Host "Proxy setup cancelled by user." -ForegroundColor Yellow
        exit
    }
}

# Set environment variables (User scope)
[Environment]::SetEnvironmentVariable('HTTP_PROXY', $proxyUrl, 'User')
[Environment]::SetEnvironmentVariable('HTTPS_PROXY', $httpsProxyUrl, 'User')
[Environment]::SetEnvironmentVariable('http_proxy', $proxyUrl, 'User')
[Environment]::SetEnvironmentVariable('https_proxy', $httpsProxyUrl, 'User')

# Set for current session
$env:HTTP_PROXY = $proxyUrl
$env:HTTPS_PROXY = $httpsProxyUrl
$env:http_proxy = $proxyUrl
$env:https_proxy = $httpsProxyUrl

# Git (if installed)
if (Test-CommandExists "git") {
    Write-Host "Setting Git proxy..." -ForegroundColor Cyan
    git config --global http.proxy $proxyUrl
    git config --global https.proxy $httpsProxyUrl
} else {
    Write-Host "Git not found. Skipping Git proxy setup." -ForegroundColor Yellow
}

# npm (if installed)
if (Test-CommandExists "npm") {
    Write-Host "Setting npm proxy..." -ForegroundColor Cyan
    npm config set proxy $proxyUrl
    npm config set https-proxy $httpsProxyUrl
} else {
    Write-Host "npm not found. Skipping npm proxy setup." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "Proxy setup completed successfully!" -ForegroundColor Green
Write-Host "You can now use internet-enabled tools with the configured proxy." -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host "Note: Sign out or restart your shell to ensure all changes take effect." -ForegroundColor Magenta
