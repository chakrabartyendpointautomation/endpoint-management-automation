# Authentication and permissions

## Supported model

The module uses interactive delegated authentication through Microsoft Graph PowerShell. The signed-in operator's identity and tenant policies apply. The project does not accept or store passwords, access tokens, client secrets, or certificates.

Install the authentication module:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

`Connect-EndpointGraph` requests these delegated permissions:

| Permission | Used for | Access level |
| --- | --- | --- |
| `DeviceManagementManagedDevices.Read.All` | Intune managed-device inventory and compliance/check-in properties | Read all managed devices |
| `Directory.Read.All` | Entra device registration enrichment | Read directory objects |

These are tenant-wide read permissions and require administrator consent in many tenants. Use a dedicated test tenant first, have an administrator review the consent request, and use an appropriately governed operator account. Directory read access is broad; if your tenant supports the needed device query with a narrower permission, adjust the requested scopes and validate the behavior before client use.

## Operational guidance

- Use the minimum permissions approved for the task and remove consent when the engagement ends, following the tenant's access process.
- Do not put tenant IDs, account names, tokens, or exported client data into source control or public issue reports.
- Device exports can be sensitive even though the scripts are read-only. Store them in an approved location and delete them according to the client's retention policy.
- Follow conditional access, MFA, audit, and change-control requirements in the target tenant.

## App-only authentication

App-only authentication is intentionally not implemented. If a client engagement requires unattended reporting, design a separate workload identity with a certificate or managed identity, documented ownership and rotation, admin consent, and the narrowest supported application permissions. Do not adapt this project by placing a client secret in a script or configuration file.
