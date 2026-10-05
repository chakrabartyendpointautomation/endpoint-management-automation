[CmdletBinding()]
param(
    [ValidateRange(1, 3650)][int] $StaleAfterDays = 30,
    [ValidateNotNullOrEmpty()][string] $OutputPath = './reports/endpoint-health'
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '../src/EndpointManagementAutomation.psm1'
Import-Module $modulePath -Force

try {
    Connect-EndpointGraph -Verbose
    $report = Get-EndpointHealthReport -StaleAfterDays $StaleAfterDays
    $files = Export-EndpointHealthReport -Report $report -Path $OutputPath -Confirm:$false
    $report | Select-Object GeneratedAtUtc, TotalManagedDevices, NonCompliantDevices, StaleDevices, UnknownLastSyncDevices | Format-List
    $files | Format-List
}
finally {
    Disconnect-EndpointGraph
}
