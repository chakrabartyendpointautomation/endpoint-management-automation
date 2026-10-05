# Architecture

## Data flow

```text
Operator
  │ Interactive delegated sign-in
  ▼
Microsoft.Graph.Authentication
  │ GET requests to Graph v1.0; follows @odata.nextLink
  ├── /deviceManagement/managedDevices  (Intune inventory)
  └── /devices                          (Entra device registration)
  ▼
In-memory join on Intune azureADDeviceId ↔ Entra deviceId
  ▼
Health summary + device rows
  ├── JSON (summary and rows)
  └── CSV  (one row per managed device)
```

## Module responsibilities

- `Connect-EndpointGraph`: checks dependency and establishes delegated sign-in with explicit scopes.
- `Get-EndpointGraphCollection`: retrieves every page and turns Graph failures into actionable errors.
- `Get-EndpointHealthReport`: collects, joins and summarizes read-only inventory. Staleness is based on the caller's threshold and last sync timestamp; missing timestamps are counted separately.
- `Export-EndpointHealthReport`: writes local JSON and CSV files and supports `-WhatIf`/`-Confirm` for file output.

## Design boundaries

- All tenant calls use Graph `v1.0` GET endpoints. No tenant mutation or device remediation is implemented.
- Data is held in memory only during the run. The export is explicit and local; paths are chosen by the operator.
- The Entra join is best-effort: a missing registration match is represented with null fields, not treated as proof of device health or failure.
- Graph throttling and transient errors are surfaced to the operator. Retry policy is left to a future iteration so operators do not mistake partial data for a complete report.
- This is a small, reviewable portfolio module rather than a general-purpose Graph SDK replacement.
