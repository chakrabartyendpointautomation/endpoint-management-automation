# Usage

## Run the example

From the repository root in PowerShell 7.2 or later:

```powershell
./examples/Collect-EndpointHealth.ps1 -StaleAfterDays 30 -OutputPath ./reports/endpoint-health
```

The first run opens Microsoft Graph's interactive sign-in. After consent and authentication, the script prints a summary and writes `endpoint-health.json` and `endpoint-health.csv`. Use `-Verbose` to see connection diagnostics.

## Use the functions directly

```powershell
Import-Module ./src/EndpointManagementAutomation.psm1 -Force
Connect-EndpointGraph
$report = Get-EndpointHealthReport -StaleAfterDays 45
$report | Select-Object GeneratedAtUtc, TotalManagedDevices, NonCompliantDevices, StaleDevices
Export-EndpointHealthReport -Report $report -Path ./reports/monthly-health
Disconnect-EndpointGraph
```

Preview the local export without writing files:

```powershell
Export-EndpointHealthReport -Report $report -Path ./reports/monthly-health -WhatIf
```

`-WhatIf` applies to local file writing. The collection functions make read-only Graph requests, so no tenant change is possible through this module.

## Parameters and interpretation

| Function | Parameter | Details |
| --- | --- | --- |
| `Connect-EndpointGraph` | `-Scopes` | Defaults to the two documented read scopes; change only after validating permissions and API behavior. |
| `Get-EndpointHealthReport` | `-StaleAfterDays` | Integer from 1 to 3650; a device is stale when its last sync is older than this many days. |
| `Export-EndpointHealthReport` | `-Report`, `-Path` | Writes `<Path>.json` and `<Path>.csv`; directory creation is local and file output supports `-WhatIf`. |

`NonCompliantDevices` counts the Graph value `noncompliant`. Other compliance values remain visible on each row and are not silently classified. A missing or unparsable last-sync date is marked `LastSyncUnknown` and counted separately.

## Output fields

The JSON document includes `GeneratedAtUtc`, the threshold, aggregate counts, and `Devices`. CSV contains the device rows. Fields include name, OS/version, compliance, check-in timestamp, stale/unknown flags, assigned user, hardware metadata, Intune ID, and matched Entra ID/trust/account state. Tenant data can be sensitive; use approved storage and retention controls.

## Troubleshooting

- **Authentication module missing:** install `Microsoft.Graph.Authentication` for the current user.
- **Consent or authorization error:** ask the tenant administrator to review and consent to the required delegated scopes; verify the operator is permitted by tenant policy.
- **403 from Graph:** the signed-in user or granted scopes cannot read the requested resource. Do not work around this by adding broad permissions without review.
- **Throttling or network failure:** rerun after resolving the reported condition; the current version fails visibly rather than exporting a partial report as complete.
- **No Entra match:** registration may be absent or IDs may not align; the report preserves null Entra fields for review.
