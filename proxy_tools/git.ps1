function Set-GitProxy {
    param(
        [string]$ProxyUrl
    )
    git config --global http.proxy $ProxyUrl
    git config --global https.proxy $ProxyUrl
}

function Unset-GitProxy {
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}
