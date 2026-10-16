# Architecture

## Data flow

1. The operator signs in interactively through Microsoft.Graph.Authentication with explicitly selected delegated scopes.
2. Read-only GET requests go to Microsoft Graph v1.0 collections for Intune managed devices, Entra devices, Intune mobile apps, and Intune device configurations.
3. The shared collection helper follows @odata.nextLink for each collection and stops with a surfaced error if a request fails.
4. Results are normalized in memory into either the endpoint health summary and device rows, or a timestamped Intune catalog report with an Items collection.
5. The operator can explicitly export a report as local JSON and CSV files.

## Module responsibilities

- Connect-EndpointGraph checks for Microsoft.Graph.Authentication and establishes delegated sign-in using the requested scopes. Its default scopes remain for the endpoint health report; use the app or configuration read scope for the corresponding catalog report.
- Get-EndpointGraphCollection retrieves all pages from a Graph collection and turns Graph failures into surfaced errors.
- Get-EndpointHealthReport joins Intune managed-device data with Entra device registration data. Staleness uses the caller's threshold; missing timestamps are counted separately. The Entra match is best-effort.
- Get-IntuneAppInventoryReport collects base mobile app inventory fields: ID, display name, publisher, publishing state, and timestamps. It does not report assignment state, assignment targets, or per-device install state.
- Get-IntuneConfigurationInventoryReport collects device configuration inventory metadata. It does not collect full policy settings or device-level status.
- Export-GraphCollectionReport writes reports with Items or Devices collections as local JSON and CSV, with ShouldProcess support for file output.
- Export-EndpointHealthReport remains the existing endpoint health export function.

## Design boundaries

- Tenant calls are Graph v1.0 GET requests. No tenant mutation, device remediation, profile assignment, or policy write is included.
- Data is held in memory during the run. File output is explicit, local, and selected by the operator.
- Reported values are limited to the fields selected by each function. A summary count is not proof of inventory completeness or tenant health.
- Graph throttling and transient errors are surfaced. The current version does not retry; a failed page stops the report rather than silently treating partial results as complete.
- Device, app, and configuration exports can contain sensitive operational data. Store and retain them according to tenant policy.
- This is a small, reviewable PowerShell reporting module, not a general-purpose Microsoft Graph SDK replacement.
