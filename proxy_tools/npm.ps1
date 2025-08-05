function Set-NpmProxy {
    param(
        [string]$ProxyUrl
    )
    npm config set proxy $ProxyUrl
    npm config set https-proxy $ProxyUrl
}

function Unset-NpmProxy {
    npm config delete proxy
    npm config delete https-proxy
}
