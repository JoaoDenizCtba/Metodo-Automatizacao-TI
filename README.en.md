# Personal IT Task Automation Method

[Português](README.md) | [Español](README.es.md) | [English](README.en.md)

This repository presents a modular method for automating IT tasks on Windows, Linux, and macOS using PowerShell 7+, specialized scripts, and JSON files.

> **Current scope:** the available implementation is the initial local inventory module. Software verification, authentication, Active Directory, and remote automation are potential future additions, not currently provided features.

## Organizational principles

- **Separation of responsibilities:** setup, environment validation, orchestration, and operating-system-specific collection are handled by distinct components.
- **Central orchestrator:** loads and validates the configuration, selects the appropriate collector, and writes the report.
- **Versioned configuration:** `matriz/inventario.json` stores parameters used by the inventory; it is not a device or software catalog.
- **Validation and documentation:** local tests and continuous integration verify aspects of the implementation across multiple operating systems.

## Current components

- `executor/Invoke-Inventario.ps1`: orchestrates validation, data collection, and JSON report output.
- `executor/Start-Inventario.cmd` and `executor/Start-Inventario.sh`: launchers that check for or prepare PowerShell 7 before running the orchestrator.
- `executor/Bootstrap-Windows.ps1`: Windows PowerShell 5.1 launcher; tries WinGet and validates the official installer as a fallback.
- `executor/bootstrap/Install-PowerShell-Linux.sh` and `executor/bootstrap/Install-PowerShell-macOS.sh`: prepare PowerShell using compatible package managers already available or verified official packages.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: shared release lookup, download, SHA-256 verification, and privilege-handling functions.
- `matriz/inventario.json`: contains the configuration version and inventory output parameters.
- `scripts/Inventario.Common.ps1`: functions shared by the collectors.
- `scripts/Environment.Validation.ps1`: checks the platform, PowerShell version, and collection prerequisites. On Linux, it attempts to install `coreutils` if `df` or `who` is missing.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1`, and `scripts/Inventario.macOS.ps1`: collectors for their respective operating systems.
- `tests/Test-InventorySmoke.ps1`: smoke test for the report structure.
- `tests/Test-BootstrapMetadata.sh`: POSIX launcher metadata test.
- `.github/workflows/test-inventory.yml`: automated validation on Windows, Linux, and macOS.

## First run

The native launchers check for or prepare PowerShell 7 when needed.

**Windows**

```powershell
.\executor\Start-Inventario.cmd
```

**Linux and macOS**

```sh
sh ./executor/Start-Inventario.sh
```

When possible, the launcher uses a compatible package manager that is already available. Otherwise, it may download the official PowerShell release and verify integrity metadata and the installer signature for supported package formats. A system-wide installation may require administrator privileges; the Linux file-based fallback installs to the user's profile.

On Linux, validation may try to install `coreutils` through an existing supported package manager if `df` or `who` is missing. This may require `sudo`; the project does not install or configure a new package manager. If other required prerequisites are missing, collection stops with a diagnostic.

If PowerShell 7 is already installed, you can run the orchestrator directly:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

By default, the report is written to a local user data directory. To choose another path:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

The `-WhatIf` parameter previews the write without creating the file. `-ConfigPath` lets you specify another matrix compatible with version 1.

## Data and privacy

The report may contain device identifiers, local account information, and network addresses. Review [docs/inventario.md](docs/inventario.md) and your organization's privacy requirements before storing or sharing reports.

The inventory collection does not send the report to external services. However, launchers may access the internet to obtain PowerShell when it is unavailable. Installing dependencies may also modify the machine, depending on the package manager used.

## Tests

To validate collection on the current machine, with PowerShell 7 installed:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

The GitHub Actions workflow also checks launcher syntax and runs tests on Windows, Linux, and macOS.

## Limitations and documentation

The current scope is local inventory, with no Active Directory integration, centralized report submission, scheduling, or remote installation and remediation. The availability of some data depends on the operating system, installed commands, and the user's permissions.

- [Inventory scope, format, and limitations](docs/inventario.md) — available in Portuguese.
- [Structured automation concept](docs/conceito.md) — available in Portuguese.

The Spanish and English translations of this README are separate; the detailed documents in `docs/` have not yet been translated.

## Author

João Alberto R. Deniz Junior – Senior Infrastructure Analyst
