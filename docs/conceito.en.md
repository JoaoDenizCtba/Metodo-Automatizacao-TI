# Structured Automation Concept

[Português](conceito.md) | [Español](conceito.es.md) | [English](conceito.en.md)

This method was developed in response to real automation needs in corporate environments, with an emphasis on modularity, clarity, and control.

## Method principles

- **Task-specific scripts**
- **A centralized executor that manages runs**
- **A JSON matrix as the source of truth**
- **Documentation and version control**

## Components

- `executor/Start-Inventario.cmd`, `executor/Start-Inventario.sh`, and `executor/Bootstrap-Windows.ps1`: initialize PowerShell 7 through platform-specific paths.
- `executor/bootstrap/Install-PowerShell-Linux.sh` and `executor/bootstrap/Install-PowerShell-macOS.sh`: prepare PowerShell using existing package managers or verified official packages.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: shared release lookup, download, integrity verification, and privilege handling.
- `executor/Invoke-Inventario.ps1`: orchestrates matrix and environment validation, selects the operating-system collector, and writes the result.
- `matriz/inventario.json`: contains versioned parameters for collection and reporting.
- `scripts/Inventario.Common.ps1`: shared functions for errors, native commands, dates, and networking.
- `scripts/Environment.Validation.ps1`: validates required prerequisites and identifies limitations before collection.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1`, and `scripts/Inventario.macOS.ps1`: specialized collectors for each operating system.
- `docs/inventario.md`: defines the inventory scope, report format, and known limitations.
- `tests/Test-InventorySmoke.ps1`: smoke test for the JSON structure.
- `.github/workflows/test-inventory.yml`: automated cross-platform validation.

## Initial scope

The first release is a read-only inventory for Windows, Linux, and macOS machines that are not domain-joined. By default, the report remains on the local machine. Domain/Active Directory support is outside the current scope and may be added later as a separate specialization.

This concept is continuously evolving and may be adapted to meet new needs.
