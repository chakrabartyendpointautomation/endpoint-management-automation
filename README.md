# Endpoint Management Automation

Practical, read-only-first PowerShell automation for Microsoft Intune and Entra ID, built on Microsoft Graph. The project turns routine endpoint operations into repeatable inventory and health reporting that an IT team or MSP can review before taking action.

> **Portfolio project:** This repository demonstrates endpoint engineering patterns and is not a managed service or a substitute for a tenant-specific security review. Start in a test tenant and review every permission before use.

## What it does

- Collects managed-device inventory and compliance state from Intune.
- Enriches device records with matching Entra device registration details.
- Flags stale check-ins and noncompliant devices for human review.
- Produces timestamped JSON and CSV reports without changing tenant state.
- Uses Microsoft Graph PowerShell authentication with explicit delegated scopes.

This repo complements the focused **[PowerShell Endpoint Remediation Toolkit](https://github.com/chakrabartyendpointautomation/powershell-endpoint-remediation-toolkit)** and **[Intune Endpoint Health Assessment](https://github.com/chakrabartyendpointautomation/intune-endpoint-health-assessment)** projects. It focuses on reusable Graph inventory/reporting workflows; it does not duplicate local device repair scripts or the full assessment deliverable.

## Quick start

Requirements: PowerShell 7.2+ (Windows, macOS, or Linux), Microsoft.Graph.Authentication, and a tenant account authorized for the read-only scopes listed in [Authentication](docs/Authentication.md).

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
. ./src/EndpointManagementAutomation.psm1

Connect-EndpointGraph
$report = Get-EndpointHealthReport -StaleAfterDays 30
Export-EndpointHealthReport -Report $report -Path ./reports/endpoint-health
Disconnect-EndpointGraph
```

The export creates `.json` and `.csv` files. No create, update, delete, sync, or remediation Graph operation is included. See [Usage](docs/Usage.md) and [Architecture](docs/Architecture.md) before connecting to a production tenant.

## Repository layout

```text
src/EndpointManagementAutomation.psm1  Authentication, paging, inventory, report and export functions
examples/Collect-EndpointHealth.ps1    Minimal operator entry point
docs/Architecture.md                   Data flow and design decisions
docs/Authentication.md                 Graph scopes and consent guidance
docs/Usage.md                           Parameters, output fields and operations
samples/endpoint-health.sample.json     Synthetic example output
LICENSE                                MIT License
```

## Example report

For a small synthetic example, see [`samples/endpoint-health.sample.json`](samples/endpoint-health.sample.json). Sample data is fictional and contains no tenant identifiers.

| Metric | Meaning |
| --- | --- |
| `TotalManagedDevices` | Intune managed-device records returned by Graph |
| `NonCompliantDevices` | Devices whose compliance state is `noncompliant` |
| `StaleDevices` | Devices with a last sync older than the requested age |
| `UnknownLastSyncDevices` | Records without a usable last-sync timestamp |

## Safe operating model

- Collection and export are read-only. `-WhatIf`/`-Confirm` are not relevant because this project has no tenant-mutating commands.
- Authentication is delegated and interactive. No client secret, certificate, token, or tenant data is stored by this project.
- Output can contain device names, user principal names, serial numbers, and device identifiers from your tenant. Store and share reports according to your organization's data-handling rules.
- Graph results are paged, errors are surfaced, and report timestamps use UTC.

## Contributing and support

Issues and pull requests are welcome. Before using this in a client tenant, validate consent, data handling, and API behavior against that tenant's requirements. This portfolio repository is provided as-is under the MIT License.

## License

MIT. See [`LICENSE`](LICENSE).
