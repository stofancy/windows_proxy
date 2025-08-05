# Windows Proxy Manager

A simple PowerShell-based tool to set and unset proxy settings for environment variables and popular command-line tools on Windows. Designed for developers who frequently switch between different network environments and need to quickly configure or remove proxy settings for their development tools.

## How to Use

### Profile Installation (Required)

To enable the proxy management commands, you must add the helper functions to your PowerShell profile:

```powershell
.\profile_installation.ps1
```

After installation, **restart your PowerShell session**.

### Set Proxy

To enable proxy settings, use the following command in PowerShell:

```powershell
proxyon
```

Then follow the prompt to setup yor proxy

### Unset Proxy

To remove the proxy settings, use:

```powershell
proxyoff
```

## Supported Tools

- Environment variables (`HTTP_PROXY`, `HTTPS_PROXY`, etc.)
- Git
- npm

## Planned Support (Future)

- pnpm
- yarn
- python
- pip
- nuget
- Other commonly used package management tools for developers

## How to Contribute

Contributions are welcome! To contribute:

1. Fork this repository.
2. Create a new branch for your feature or bugfix.
3. Make your changes and add tests if applicable.
4. Submit a pull request with a clear description of your changes.

Feel free to open issues for feature requests or bug reports.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
