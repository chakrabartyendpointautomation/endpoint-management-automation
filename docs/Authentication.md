# Authentication and permissions

## Supported model

The module uses interactive delegated authentication through Microsoft Graph PowerShell. The signed-in operator's identity and tenant policies apply. The project does not accept or store passwords, access tokens, client secrets, or certificates.

Install the authentication module:

    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser

Connect-EndpointGraph defaults to the scopes used by the endpoint health report. Catalog reports use separate delegated read scopes. Pass only the scope required for the report being run.

| Permission | Used for | Access level |
| --- | --- | --- |
| DeviceManagementManagedDevices.Read.All | Intune managed-device inventory and compliance/check-in properties | Read managed devices |
| Directory.Read.All | Entra device registration enrichment | Read directory objects |
| DeviceManagementApps.Read.All | Intune mobile app catalog report | Read Intune apps |
| DeviceManagementConfiguration.Read.All | Intune device configuration catalog report | Read Intune device configuration and policies |

The endpoint health scopes and the catalog scopes are not all requested by default. Example for the app catalog: Connect-EndpointGraph -Scopes @('DeviceManagementApps.Read.All'). Use DeviceManagementConfiguration.Read.All for the configuration catalog. Intune permission scopes require administrator access and may require admin consent; check current tenant and Microsoft documentation. Directory.Read.All is broad. If your tenant supports a narrower permission for the device query, review it and validate behavior before use.

## Operational guidance

- Use the minimum permissions approved for the task and remove consent when the engagement ends, following the tenant's access process.
- Do not put tenant IDs, account names, tokens, or exported client data into source control or public issue reports.
- Device, app, and configuration exports can be sensitive even though the scripts are read-only. Store them in an approved location and delete them according to the tenant's retention policy.
- Follow Conditional Access, MFA, audit, and change-control requirements in the target tenant.

## App-only authentication

App-only authentication is intentionally not implemented. If a client engagement requires unattended reporting, design a separate workload identity with a certificate or managed identity, documented ownership and rotation, admin consent, and the narrowest supported application permissions. Do not adapt this project by placing a client secret in a script or configuration file.
