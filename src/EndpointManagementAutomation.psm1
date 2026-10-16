Set-StrictMode -Version Latest

function Connect-EndpointGraph {
    [CmdletBinding()]
    param([string[]] $Scopes = @('DeviceManagementManagedDevices.Read.All', 'Directory.Read.All'))
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw 'Microsoft.Graph.Authentication is required. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser'
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    try {
        Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop | Out-Null
        $context = Get-MgContext
        if (-not $context) { throw 'Graph authentication completed without an available context.' }
        Write-Verbose "Connected to Microsoft Graph as $($context.Account) in tenant $($context.TenantId)."
    }
    catch { throw "Microsoft Graph sign-in failed: $($_.Exception.Message)" }
}

function Disconnect-EndpointGraph {
    [CmdletBinding()]
    param()
    if (Get-Command Disconnect-MgGraph -ErrorAction SilentlyContinue) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }
}

function Get-EndpointGraphCollection {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Uri)
    $items = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    $pageNumber = 0
    while ($next) {
        $pageNumber++
        Write-Verbose "Requesting Graph collection page $pageNumber."
        try { $page = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject -ErrorAction Stop }
        catch { throw "Graph request failed for '$next': $($_.Exception.Message)" }
        foreach ($item in @($page.value)) { $items.Add($item) }
        $next = $page.'@odata.nextLink'
    }
    return $items.ToArray()
}

function Get-EndpointHealthReport {
    [CmdletBinding()]
    param([ValidateRange(1, 3650)][int] $StaleAfterDays = 30)
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
        throw 'Connect to Microsoft Graph first by calling Connect-EndpointGraph.'
    }
    $select = 'id,deviceName,operatingSystem,osVersion,complianceState,lastSyncDateTime,azureADDeviceId,userPrincipalName,serialNumber,manufacturer,model'
    $managedUri = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$select=' + [uri]::EscapeDataString($select) + '&$top=100'
    $directoryUri = 'https://graph.microsoft.com/v1.0/devices?$select=id,deviceId,displayName,accountEnabled,trustType&$top=100'
    $managedDevices = @(Get-EndpointGraphCollection -Uri $managedUri)
    $directoryDevices = @(Get-EndpointGraphCollection -Uri $directoryUri)
    $directoryByDeviceId = @{}
    foreach ($directoryDevice in $directoryDevices) {
        if ($directoryDevice.deviceId) { $directoryByDeviceId[[string]$directoryDevice.deviceId] = $directoryDevice }
    }

    $cutoff = [DateTimeOffset]::UtcNow.AddDays(-$StaleAfterDays)
    $devices = foreach ($device in $managedDevices) {
        $lastSync = $null
        if ($device.lastSyncDateTime) {
            try { $lastSync = [DateTimeOffset]::Parse([string]$device.lastSyncDateTime).ToUniversalTime() }
            catch { Write-Warning "Device '$($device.deviceName)' has an invalid lastSyncDateTime; reporting it as unknown." }
        }
        $entra = $null
        if ($device.azureADDeviceId -and $directoryByDeviceId.ContainsKey([string]$device.azureADDeviceId)) {
            $entra = $directoryByDeviceId[[string]$device.azureADDeviceId]
        }
        [pscustomobject]@{
            DeviceName = $device.deviceName
            OperatingSystem = $device.operatingSystem
            OSVersion = $device.osVersion
            ComplianceState = $device.complianceState
            LastSyncUtc = if ($lastSync) { $lastSync.ToString('o') } else { $null }
            IsStale = [bool]($lastSync -and $lastSync -lt $cutoff)
            LastSyncUnknown = [bool](-not $lastSync)
            UserPrincipalName = $device.userPrincipalName
            SerialNumber = $device.serialNumber
            Manufacturer = $device.manufacturer
            Model = $device.model
            IntuneManagedDeviceId = $device.id
            EntraDeviceId = if ($entra) { $entra.id } else { $null }
            EntraTrustType = if ($entra) { $entra.trustType } else { $null }
            EntraAccountEnabled = if ($entra) { $entra.accountEnabled } else { $null }
        }
    }
    $deviceList = @($devices)
    [pscustomobject]@{
        GeneratedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        StaleAfterDays = $StaleAfterDays
        TotalManagedDevices = $deviceList.Count
        NonCompliantDevices = @($deviceList | Where-Object { $_.ComplianceState -eq 'noncompliant' }).Count
        StaleDevices = @($deviceList | Where-Object IsStale).Count
        UnknownLastSyncDevices = @($deviceList | Where-Object LastSyncUnknown).Count
        Devices = $deviceList
    }
}

function Get-IntuneAppInventoryReport {
    [CmdletBinding()]
    param()
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
        throw 'Connect to Microsoft Graph first by calling Connect-EndpointGraph.'
    }
    $uri = 'https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?$select=id,displayName,publisher,createdDateTime,lastModifiedDateTime,publishingState&$top=100'
    $apps = @(Get-EndpointGraphCollection -Uri $uri)
    $items = foreach ($app in $apps) {
        [pscustomobject]@{
            Id = [string]$app.id
            DisplayName = [string]$app.displayName
            Publisher = [string]$app.publisher
            PublishingState = [string]$app.publishingState
            CreatedDateTime = [string]$app.createdDateTime
            LastModifiedDateTime = [string]$app.lastModifiedDateTime
        }
    }
    $itemList = @($items)
    [pscustomobject]@{
        GeneratedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        Source = 'Microsoft Graph v1.0 deviceAppManagement/mobileApps'
        TotalApps = $itemList.Count
        Items = $itemList
    }
}

function Get-IntuneConfigurationInventoryReport {
    [CmdletBinding()]
    param()
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
        throw 'Connect to Microsoft Graph first by calling Connect-EndpointGraph.'
    }
    $uri = 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName,description,createdDateTime,lastModifiedDateTime,version&$top=100'
    $configurations = @(Get-EndpointGraphCollection -Uri $uri)
    $items = foreach ($configuration in $configurations) {
        [pscustomobject]@{
            Id = [string]$configuration.id
            DisplayName = [string]$configuration.displayName
            Description = [string]$configuration.description
            CreatedDateTime = [string]$configuration.createdDateTime
            LastModifiedDateTime = [string]$configuration.lastModifiedDateTime
            Version = $configuration.version
        }
    }
    $itemList = @($items)
    [pscustomobject]@{
        GeneratedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        Source = 'Microsoft Graph v1.0 deviceManagement/deviceConfigurations'
        TotalConfigurations = $itemList.Count
        Items = $itemList
    }
}

function Export-GraphCollectionReport {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][psobject] $Report,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Path
    )
    $collectionProperty = $Report.PSObject.Properties['Items']
    if (-not $collectionProperty) { $collectionProperty = $Report.PSObject.Properties['Devices'] }
    if (-not $collectionProperty) { throw 'Report must contain an Items or Devices collection.' }
    $items = @($collectionProperty.Value)
    $resolved = [System.IO.Path]::GetFullPath($Path)
    $directory = [System.IO.Path]::GetDirectoryName($resolved)
    $jsonPath = "$resolved.json"
    $csvPath = "$resolved.csv"
    if ($PSCmdlet.ShouldProcess("$jsonPath and $csvPath", 'Write Graph report files')) {
        try {
            if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
                $null = New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop
            }
            $Report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding utf8 -ErrorAction Stop
            if ($items.Count -gt 0) {
                $items | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
            } else {
                Set-Content -LiteralPath $csvPath -Value '' -Encoding utf8 -ErrorAction Stop
            }
            [pscustomobject]@{ JsonPath = $jsonPath; CsvPath = $csvPath; ItemCount = $items.Count }
        }
        catch { throw "Could not write Graph report: $($_.Exception.Message)" }
    }
}

function Export-EndpointHealthReport {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][psobject] $Report,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Path
    )
    $resolved = [System.IO.Path]::GetFullPath($Path)
    $directory = [System.IO.Path]::GetDirectoryName($resolved)
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop
    }
    $jsonPath = "$resolved.json"
    $csvPath = "$resolved.csv"
    if ($PSCmdlet.ShouldProcess("$jsonPath and $csvPath", 'Write endpoint health report files')) {
        try {
            $Report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding utf8 -ErrorAction Stop
            @($Report.Devices) | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
            [pscustomobject]@{ JsonPath = $jsonPath; CsvPath = $csvPath; DeviceCount = @($Report.Devices).Count }
        }
        catch { throw "Could not write endpoint health report: $($_.Exception.Message)" }
    }
}

Export-ModuleMember -Function Connect-EndpointGraph, Disconnect-EndpointGraph, Get-EndpointHealthReport, Get-IntuneAppInventoryReport, Get-IntuneConfigurationInventoryReport, Export-GraphCollectionReport, Export-EndpointHealthReport
