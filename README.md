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

## Working in Process

1. The `reviewing before setting proxy` step should to be moved after all tool files are read, so that we know which tools will be setup for better summarize, which means the logic should be dynamically, currently it's hardcoded for only several tools.
2. Test the tools is existing(installed) or not before apply the proxy set/unset.
   1. skip set/unset if the tool not existing(installed).
   2. continue only if the tool is existing.
3. Enhance the final summarize message.

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
3. To add support for a new tool, create a new file in the `proxy_tools/` folder (e.g., `pnpm.ps1`) and implement two functions: `Set-<Tool>Proxy` and `Unset-<Tool>Proxy`.
   - Each function should handle setting or unsetting the proxy for that tool only.
   - If a tool should not be managed, simply remove its file from `proxy_tools/`.
4. Make any other necessary changes and add tests if applicable.
5. Submit a pull request with a clear description of your changes.

Feel free to open issues for feature requests or bug reports.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
