# Endpoint Management Automation

Read-only-first PowerShell automation for Microsoft Intune and Entra ID, built on Microsoft Graph. The repository provides endpoint health reporting plus a small catalog of Intune app and configuration objects, with repeatable local JSON/CSV exports.

> **Portfolio project:** This repository demonstrates endpoint engineering patterns. It is not a managed service or a substitute for tenant-specific security review. Review permissions and data handling before use.

## What it reports

- Intune managed-device inventory and compliance state, enriched with matching Entra device registration details.
- Stale check-ins, noncompliant devices, and devices with unknown last-sync values for human review.
- Intune mobile app inventory, including publisher, publishing state, and timestamps.
- Intune device configuration inventory, including names, descriptions, timestamps, and version.
- Timestamped JSON and CSV outputs; Graph collection calls use GET only and do not change tenant state.

The app report does not retrieve assignment targets, assignment state, or per-device installation status. The configuration report does not retrieve full policy settings or device-level policy status. See [Intune reporting](docs/IntuneReporting.md) for scope requirements, usage, and limitations.

This repo complements the focused [PowerShell Endpoint Remediation Toolkit](https://github.com/chakrabartyendpointautomation/powershell-endpoint-remediation-toolkit) and [Intune Endpoint Health Assessment](https://github.com/chakrabartyendpointautomation/intune-endpoint-health-assessment). It focuses on reusable read-only Graph reporting, not local repair scripts or a full assessment deliverable.

## Quick start: endpoint health

Requirements: PowerShell 7.2+ (Windows, macOS, or Linux), Microsoft.Graph.Authentication, and a tenant account authorized for the delegated scopes in [Authentication](docs/Authentication.md).

    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
    . ./src/EndpointManagementAutomation.psm1

    Connect-EndpointGraph
    $report = Get-EndpointHealthReport -StaleAfterDays 30
    Export-EndpointHealthReport -Report $report -Path ./reports/endpoint-health
    Disconnect-EndpointGraph

The export creates endpoint-health.json and endpoint-health.csv. No tenant create, update, delete, sync, or remediation operation is included.

## Intune app and configuration catalogs

These reports use separate delegated scopes. Request only the scope needed for the report you plan to run:

- Apps: DeviceManagementApps.Read.All
- Device configurations: DeviceManagementConfiguration.Read.All

Use the corresponding function, then export locally:

    Connect-EndpointGraph -Scopes @('DeviceManagementApps.Read.All')
    $report = Get-IntuneAppInventoryReport
    Export-GraphCollectionReport -Report $report -Path ./reports/intune-app-inventory
    Disconnect-EndpointGraph

    Connect-EndpointGraph -Scopes @('DeviceManagementConfiguration.Read.All')
    $report = Get-IntuneConfigurationInventoryReport
    Export-GraphCollectionReport -Report $report -Path ./reports/intune-configuration-inventory
    Disconnect-EndpointGraph

The shared export supports -WhatIf and -Confirm for local file output. Intune Graph APIs require an active Intune license, and Intune permission scopes require administrator consent. Review [Intune reporting](docs/IntuneReporting.md) and the current Microsoft documentation before connecting.

## Repository layout

    src/EndpointManagementAutomation.psm1  Authentication, paging, endpoint health, Intune catalogs, and exports
    examples/Collect-EndpointHealth.ps1    Minimal endpoint health operator entry point
    docs/Architecture.md                   Data flow and design decisions
    docs/Authentication.md                Graph scopes and consent guidance
    docs/IntuneReporting.md                Intune catalog reports, usage, and scope details
    docs/Usage.md                          Health report parameters, output, and operations
    samples/endpoint-health.sample.json    Synthetic example output
    LICENSE                                MIT License

## Example output

The synthetic endpoint example is [samples/endpoint-health.sample.json](samples/endpoint-health.sample.json). It contains fictional data and no tenant identifiers.

| Metric | Meaning |
| --- | --- |
| TotalManagedDevices | Intune managed-device records returned by Graph |
| NonCompliantDevices | Devices whose compliance state is noncompliant |
| StaleDevices | Devices whose last sync is older than the selected age |
| UnknownLastSyncDevices | Records without a usable last-sync timestamp |

## Safe operating model

- Graph collection uses delegated authentication and read-only scopes. No client secret, token, or certificate is stored in this project.
- The existing health report defaults to DeviceManagementManagedDevices.Read.All and Directory.Read.All. Catalog reports request their app or configuration read scope only when explicitly supplied to Connect-EndpointGraph.
- Do not add write or privileged device-operation scopes for reporting.
- Exports can contain device names, user principal names, serial numbers, app names, policy descriptions, and device identifiers. Store and share them according to your organization's data-handling and retention rules.
- Graph results are paged and request errors are surfaced rather than silently treated as a complete report.

## Validation status

The new app/configuration reports have not been tested against a live tenant or validated in this environment. See the manual validation plan in [docs/IntuneReporting.md](docs/IntuneReporting.md). No test claim is made for the new reporting functions.

## License

MIT. See [LICENSE](LICENSE).
