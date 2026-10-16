# Intune reporting catalog

This repository adds catalog reports to the existing read-only endpoint health collector. The reports use Microsoft Graph v1.0, follow collection paging, normalize selected fields, and can be exported locally as JSON and CSV. They do not change tenant state.

## Reports

| Function | Graph collection | Delegated permission | Included fields |
| --- | --- | --- | --- |
| Get-IntuneAppInventoryReport | deviceAppManagement/mobileApps | DeviceManagementApps.Read.All | ID, display name, publisher, publishing state, created/modified times |
| Get-IntuneConfigurationInventoryReport | deviceManagement/deviceConfigurations | DeviceManagementConfiguration.Read.All | ID, display name, description, created/modified times, version |

The app report does not retrieve assignment state, per-app assignment targets, or per-device install status. The configuration report does not retrieve full policy settings or device-level policy status. This keeps the first iteration small and limits the tenant data collected.

Microsoft's Intune Graph APIs require an active Intune license. Intune permission scopes require administrator consent in many tenants. Review the current API docs, tenant consent, role authorization, and data-handling requirements before connecting.

## Run an app catalog report

Requires PowerShell 7.2+, Microsoft.Graph.Authentication, and consent/authorization for the least-privilege scope used by this report.

    Import-Module ./src/EndpointManagementAutomation.psm1 -Force
    Connect-EndpointGraph -Scopes @('DeviceManagementApps.Read.All')
    $report = Get-IntuneAppInventoryReport
    $report | Select-Object GeneratedAtUtc, TotalApps
    Export-GraphCollectionReport -Report $report -Path ./reports/intune-app-inventory
    Disconnect-EndpointGraph

## Run a configuration inventory report

    Import-Module ./src/EndpointManagementAutomation.psm1 -Force
    Connect-EndpointGraph -Scopes @('DeviceManagementConfiguration.Read.All')
    $report = Get-IntuneConfigurationInventoryReport
    $report | Select-Object GeneratedAtUtc, TotalConfigurations
    Export-GraphCollectionReport -Report $report -Path ./reports/intune-configuration-inventory
    Disconnect-EndpointGraph

Export-GraphCollectionReport writes a JSON report and a CSV of the Items collection (the existing endpoint health report uses Devices). The export supports -WhatIf and -Confirm for local files. Collection functions issue GET requests only. Protect the exported files: app and configuration names/descriptions may reveal internal service or policy information.

## Authorization and least privilege

- Use only the delegated scope needed for the report being run. The separate app and configuration scopes avoid requesting both when only one inventory is needed.
- The existing endpoint health report defaults to DeviceManagementManagedDevices.Read.All and Directory.Read.All. Those defaults are unchanged.
- Do not add DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, or privileged device-operation scopes for reporting.
- Use an authorized operator, the tenant's consent and Conditional Access process, and a dedicated test tenant during initial review.
- Do not place tenant IDs, tokens, users, device identifiers, app catalogs, or policy descriptions in source control, public issue reports, or unsecured exports.

## Manual validation plan

No live-tenant query or PowerShell test was performed for this addition. Before using it, review the code and validate in a dedicated test tenant:

1. Confirm consent only for the specific delegated read scope needed.
2. Check that each collection returns all pages and that errors fail visibly rather than producing a partial report.
3. Compare record counts and selected values with the Intune admin center for a small known sample.
4. Confirm the app report contains only the documented base inventory fields; this version does not report assignment state or targets.
5. Run the export with -WhatIf and verify no local files are written; then write to a restricted temporary directory and inspect the report fields.
6. Disconnect the Graph session and securely handle/delete any test exports according to tenant policy.

## Microsoft documentation

- [Intune permission scopes](https://learn.microsoft.com/en-us/intune/developer/configure-graph-api-access)
- [List mobile apps (Microsoft Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/intune-apps-mobileapp-list?view=graph-rest-1.0)
- [List device configurations (Microsoft Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/intune-deviceconfig-deviceconfiguration-list?view=graph-rest-1.0)
