. (Join-Path $PSScriptRoot 'Inventario.Common.ps1')

function Get-PlatformInventory {
    $issues = [System.Collections.Generic.List[object]]::new()
    $operatingSystem = $null
    $computerSystem = $null
    $processors = @()
    $physicalMemory = @()
    $storage = @()

    try {
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    }
    catch {
        Add-InventoryIssue -Issues $issues -Field 'device.operatingSystem' -Message $_.Exception.Message
    }

    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
        $physicalMemory = @(Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop)
        $storage = @(
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop |
                ForEach-Object {
                    [ordered]@{
                        name = $_.DeviceID
                        sizeBytes = [uint64]$_.Size
                        freeBytes = [uint64]$_.FreeSpace
                    }
                }
        )
    }
    catch {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware' -Message $_.Exception.Message
    }

    $accounts = @()
    $adminSids = @{}
    $adminGroupAvailable = $false
    try {
        $adminGroup = Get-LocalGroup -SID 'S-1-5-32-544' -ErrorAction Stop
        Get-LocalGroupMember -Group $adminGroup -ErrorAction Stop |
            ForEach-Object { $adminSids[$_.SID.Value] = $true }
        $adminGroupAvailable = $true
    }
    catch {
        Add-InventoryIssue -Issues $issues -Field 'users.localAccounts.isAdministrator' -Message $_.Exception.Message
    }

    try {
        $accounts = @(
            Get-LocalUser -ErrorAction Stop |
                ForEach-Object {
                    $lastLogon = $null
                    $lastLogonStatus = 'noRecord'
                    if ($null -ne $_.LastLogon) {
                        $lastLogon = $_.LastLogon.ToUniversalTime().ToString('o')
                        $lastLogonStatus = 'recorded'
                    }

                    [ordered]@{
                        username = $_.Name
                        displayName = $_.FullName
                        identifier = $_.SID.Value
                        isAdministrator = if ($adminGroupAvailable) { $adminSids.ContainsKey($_.SID.Value) } else { $null }
                        lastLogonAt = $lastLogon
                        lastLogonStatus = $lastLogonStatus
                    }
                }
        )
    }
    catch {
        Add-InventoryIssue -Issues $issues -Field 'users.localAccounts' -Message $_.Exception.Message
    }

    $activeSessions = @()
    $sessionText = Invoke-InventoryCommand -FilePath 'quser.exe' -Arguments @() -Field 'users.activeSessions' -Issues $issues
    if (-not [string]::IsNullOrWhiteSpace($sessionText)) {
        $lines = $sessionText -split '\r?\n' | Select-Object -Skip 1
        foreach ($line in $lines) {
            $columns = ($line.Trim() -replace '^>', '') -split '\s{2,}'
            if ($columns.Count -lt 5) {
                Add-InventoryIssue -Issues $issues -Field 'users.activeSessions' -Message "Não foi possível interpretar uma linha retornada por quser."
                continue
            }

            $loginText = $columns[-1]
            $loginDate = $null
            $loginDateObject = [datetime]::MinValue
            if ([datetime]::TryParse(
                    $loginText,
                    [System.Globalization.CultureInfo]::CurrentCulture,
                    [System.Globalization.DateTimeStyles]::AssumeLocal,
                    [ref]$loginDateObject
                )) {
                $loginDateObject = $loginDateObject.ToUniversalTime()
                $loginDate = $loginDateObject.ToString('o')
            }
            else {
                Add-InventoryIssue -Issues $issues -Field 'users.activeSessions.loginTime' -Message "Não foi possível interpretar o horário de sessão '$loginText'."
            }

            $activeSessions += [ordered]@{
                username = $columns[0]
                sessionName = if ($columns.Count -ge 6) { $columns[1] } else { $null }
                state = $columns[-3]
                loginTime = $loginDate
                durationSeconds = if ($null -ne $loginDate -and $columns[0] -eq $env:USERNAME) {
                    [math]::Max(0, [int64]([datetime]::UtcNow - $loginDateObject).TotalSeconds)
                } else { $null }
            }
        }
        if (-not ($activeSessions | Where-Object { $_.username -eq $env:USERNAME })) {
            Add-InventoryIssue -Issues $issues -Field 'activity.currentSessionStartedAt' -Message 'A sessão atual não foi identificada na saída de quser.'
        }
    }

    $currentUserId = $null
    try {
        $currentUserId = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    }
    catch {
        Add-InventoryIssue -Issues $issues -Field 'users.currentUser.identifier' -Message $_.Exception.Message
    }

    $uptimeSeconds = $null
    if ($null -ne $operatingSystem -and $null -ne $operatingSystem.LastBootUpTime) {
        $uptimeSeconds = [math]::Max(0, [int64]([datetime]::Now - $operatingSystem.LastBootUpTime).TotalSeconds)
    }
    else {
        Add-InventoryIssue -Issues $issues -Field 'activity.uptimeSeconds' -Message 'O horário de inicialização não foi disponibilizado pelo sistema.'
    }

    $memoryBytes = $null
    if ($physicalMemory.Count -gt 0) {
        $memoryBytes = [uint64](($physicalMemory | Measure-Object -Property Capacity -Sum).Sum)
    }
    else {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware.memoryBytes' -Message 'A memória física não foi disponibilizada pelo sistema.'
    }

    $cpuNames = @($processors | ForEach-Object { $_.Name.Trim() } | Select-Object -Unique)
    if ($cpuNames.Count -eq 0) {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware.cpu' -Message 'O modelo da CPU não foi disponibilizado pelo sistema.'
    }

    $serialNumber = $null
    try {
        $serialNumber = (Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop).SerialNumber
        if ($serialNumber -match '^(none|unknown|not specified|to be filled by o\.e\.m\.|default string|0+)$') {
            $serialNumber = $null
            Add-InventoryIssue -Issues $issues -Field 'device.hardware.serialNumber' -Message 'O BIOS retornou um valor genérico em vez de um número de série.'
        }
    }
    catch {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware.serialNumber' -Message $_.Exception.Message
    }

    $operatingSystemInfo = $null
    if ($null -ne $operatingSystem) {
        $operatingSystemInfo = [ordered]@{
            name = $operatingSystem.Caption
            version = $operatingSystem.Version
            architecture = $operatingSystem.OSArchitecture
        }
        if ([string]::IsNullOrWhiteSpace($operatingSystemInfo.name)) {
            Add-InventoryIssue -Issues $issues -Field 'device.operatingSystem.name' -Message 'O sistema não retornou o nome do sistema operacional.'
        }
    }

    if ($null -ne $computerSystem) {
        if ([string]::IsNullOrWhiteSpace($computerSystem.Manufacturer)) {
            Add-InventoryIssue -Issues $issues -Field 'device.hardware.manufacturer' -Message 'O sistema não retornou o fabricante do equipamento.'
        }
        if ([string]::IsNullOrWhiteSpace($computerSystem.Model)) {
            Add-InventoryIssue -Issues $issues -Field 'device.hardware.model' -Message 'O sistema não retornou o modelo do equipamento.'
        }
    }

    $currentLocalUser = $accounts | Where-Object { $_.username -eq $env:USERNAME } | Select-Object -First 1
    $currentSession = $activeSessions | Where-Object { $_.username -eq $env:USERNAME } | Select-Object -First 1

    return [ordered]@{
        device = [ordered]@{
            hostname = $env:COMPUTERNAME
            operatingSystem = $operatingSystemInfo
            hardware = [ordered]@{
                manufacturer = if ($null -ne $computerSystem) { $computerSystem.Manufacturer } else { $null }
                model = if ($null -ne $computerSystem) { $computerSystem.Model } else { $null }
                serialNumber = $serialNumber
                cpu = $cpuNames
                memoryBytes = $memoryBytes
                storage = $storage
            }
            networkAdapters = Get-InventoryNetworkAdapters -Issues $issues
        }
        users = [ordered]@{
            currentUser = [ordered]@{
                username = $env:USERNAME
                displayName = if ($null -ne $currentLocalUser) { $currentLocalUser.displayName } else { $null }
                identifier = $currentUserId
            }
            localAccounts = $accounts
            activeSessions = $activeSessions
        }
        activity = [ordered]@{
            uptimeSeconds = $uptimeSeconds
            currentSessionStartedAt = if ($null -ne $currentSession) { $currentSession.loginTime } else { $null }
            currentSessionDurationSeconds = if ($null -ne $currentSession) { $currentSession.durationSeconds } else { $null }
        }
        issues = @($issues)
    }
}
