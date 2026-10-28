# Local Inventory — First Version

[Português](inventario.md) | [Español](inventario.es.md) | [English](inventario.en.md)

## Objective

Collect local information from Windows, Linux, and macOS machines that are not domain-joined, using PowerShell 7 or later. The executor selects an operating-system-specific collector and writes a JSON file; the project does not send data over the network or change system configuration during collection.

## Prerequisites

- PowerShell 7 or later (`pwsh`).
- The launcher may download the stable release from the official PowerShell repository; MSI/PKG packages require administrative authorization, while the Linux fallback installs per user.
- On Windows, access to the CIM and LocalAccounts cmdlets, which are normally included with the system.
- On Linux, read access to `/etc/passwd`, `/etc/group`, and `/proc`; the `df`, `who`, and `lastlog` commands are used when available.
- On macOS, availability of `sw_vers`, `system_profiler`, `dscl`, `last`, `who`, `sysctl`, and `df`.
- On Linux, `df` and `who` are required prerequisites; if either is missing, the validator attempts to install `coreutils` through an existing supported package manager.
- Some information may depend on permissions and installed commands.

## Running

Use the native launchers, which check for or install PowerShell 7 before invoking the orchestrator:

**Windows**

```powershell
.\executor\Start-Inventario.cmd
```

**Linux and macOS**

```sh
sh ./executor/Start-Inventario.sh
```

The launcher uses a supported package manager that is already available and provides PowerShell. If no suitable manager is available, it downloads the official stable PowerShell release, compares its SHA-256 with the value published by the releases API, and verifies the installer signature for MSI/PKG formats. On Windows, WinGet is tried before MSI. On macOS, Homebrew is tried before PKG. On Linux, APT, DNF, YUM, Zypper, or APK is used only when the configured repository offers the package; otherwise, the verified official archive is installed in the user's profile. System installations may require administrator authorization.

The test and direct execution are also available when PowerShell 7 is already installed:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

By default, the file is written to a local user data directory. You can override the path:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

The default directories are `%LOCALAPPDATA%\Metodo-Automatizacao-TI\inventarios` on Windows, `~/Library/Application Support/Metodo-Automatizacao-TI/inventarios` on macOS, and `~/.local/share/Metodo-Automatizacao-TI/inventarios` on Linux.

`-WhatIf` previews the write operation without creating the file. `-ConfigPath` lets you specify another matrix compatible with version 1.

Run the smoke test for the current system with:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

Before collection, `scripts/Environment.Validation.ps1` checks the PowerShell version, supported platform, required native commands, and, on Linux, read access to files used by the collector. If `df` or `who` is missing on Linux, the validator attempts to install `coreutils` through an existing supported package manager; this may require `sudo`. It does not install or configure package managers. Unavailable optional dependencies (for example, `lastlog` on some Linux distributions) are reported as warnings; missing other required native dependencies block collection with a diagnostic. In the current scope, the collectors use operating-system facilities and do not require third-party PowerShell modules.

## Report data

- `schemaVersion`, `collectedAtUtc`, and `collectorVersion`.
- `environmentValidation`: platform, PowerShell version, and required checks and warnings completed before collection.
- `device`: hostname, operating system, architecture, manufacturer/model/serial number when available, CPU, memory, storage, and network interfaces.
- `users.currentUser`: the user running the collector, local display name when available, and local identifier (SID/UID).
- `users.localAccounts`: local accounts, identifier, administrative-privilege indicator, and last logon when provided by the platform. `lastLogonStatus` distinguishes `recorded`, `noRecord`, and `unavailable`; `noRecord` means the queried source returned no record, not that the account has never been used.
- `users.activeSessions`: sessions the system can enumerate, with start time and duration when interpretable.
- `activity`: system uptime and current session start/duration when available.
- `issues`: fields that could not be obtained or interpreted. Missing values must not be treated as zero or as proof that something does not exist.

Account lists include service and system accounts when the platform exposes them as local accounts. The administrator classification reflects local groups recognized by the collector and may vary with the distribution or machine configuration.

## Limitations and privacy

Operating-system APIs and commands differ. As a result, full name, last logon, administrative accounts, and session times may be unavailable or use different formats. The first version reports limitations in `issues` rather than claiming that unavailable data was collected.

The report may contain usernames, SID/UID values, serial numbers, MAC addresses, and IP addresses. Store and share these files according to your organization's privacy rules. The executor does not collect passwords, tokens, or credentials and does not send data off the machine.

## Out of scope

- Active Directory or other directory integration.
- Centralized inventory, automatic submission, scheduling, and remote installation or remediation.
- Guaranteeing collection of data that the operating system does not expose to the current user.
