. (Join-Path $PSScriptRoot 'Inventario.Common.ps1')

function Get-PlatformInventory {
    $issues = [System.Collections.Generic.List[object]]::new()
    $productName = Invoke-InventoryCommand -FilePath 'sw_vers' -Arguments @('-productName') -Field 'device.operatingSystem.name' -Issues $issues
    $productVersion = Invoke-InventoryCommand -FilePath 'sw_vers' -Arguments @('-productVersion') -Field 'device.operatingSystem.version' -Issues $issues
    $hardwareText = Invoke-InventoryCommand -FilePath 'system_profiler' -Arguments @('-json', 'SPHardwareDataType') -Field 'device.hardware' -Issues $issues
    $hardware = $null
    if (-not [string]::IsNullOrWhiteSpace($hardwareText)) {
        try {
            $hardware = ($hardwareText | ConvertFrom-Json -ErrorAction Stop).SPHardwareDataType |
                Select-Object -First 1
        }
        catch {
            Add-InventoryIssue -Issues $issues -Field 'device.hardware' -Message "A saída de system_profiler não é JSON válido: $($_.Exception.Message)"
        }
    }

    $memoryBytes = $null
    if ($null -ne $hardware -and $hardware.physical_memory -match '([\d.]+)\s*(GB|MB|TB)') {
        $memoryValue = [double]::Parse($matches[1], [System.Globalization.CultureInfo]::InvariantCulture)
        $memoryMultiplier = switch ($matches[2]) {
            'TB' { 1TB }
            'GB' { 1GB }
            'MB' { 1MB }
        }
        $memoryBytes = [uint64]($memoryValue * $memoryMultiplier)
    }

    $storage = @()
    $dfOutput = Invoke-InventoryCommand -FilePath 'df' -Arguments @('-Pk') -Field 'device.hardware.storage' -Issues $issues
    if (-not [string]::IsNullOrWhiteSpace($dfOutput)) {
        $storage = @(
            ($dfOutput -split '\r?\n' | Select-Object -Skip 1) |
                ForEach-Object {
                    $columns = $_ -split '\s+'
                    if ($columns.Count -ge 6 -and $columns[1] -match '^\d+$') {
                        [ordered]@{
                            name = $columns[0]
                            sizeBytes = [uint64]$columns[1] * 1KB
                            freeBytes = [uint64]$columns[3] * 1KB
                            mountPoint = ($columns[5..($columns.Count - 1)] -join ' ')
                        }
                    }
                } |
                Where-Object { $null -ne $_ }
        )
    }
    if ($storage.Count -eq 0) {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware.storage' -Message 'Nenhum volume montado pôde ser interpretado na saída de df.'
    }

    $adminUsers = @{}
    $adminGroupAvailable = $false
    $adminText = Invoke-InventoryCommand -FilePath 'dscl' -Arguments @('.', '-read', '/Groups/admin', 'GroupMembership') -Field 'users.localAccounts.isAdministrator' -Issues $issues
    if ($null -ne $adminText) {
        $adminGroupAvailable = $true
    }
    if ($adminText -match '(?s)GroupMembership:\s*(.+)$') {
        foreach ($member in $matches[1] -split '\s+') {
            $adminUsers[$member] = $true
        }
    }

    $accountText = Invoke-InventoryCommand -FilePath 'dscl' -Arguments @('.', '-list', '/Users', 'UniqueID') -Field 'users.localAccounts' -Issues $issues
    $accounts = @()
    if (-not [string]::IsNullOrWhiteSpace($accountText)) {
        foreach ($line in ($accountText -split '\r?\n')) {
            if ($line -notmatch '^\s*(\S+)\s+(\d+)\s*$') {
                continue
            }

            $username = $matches[1]
            $userId = $matches[2]
            $displayName = $null
            $realNameText = Invoke-InventoryCommand -FilePath 'dscl' -Arguments @('.', '-read', "/Users/$username", 'RealName') -Field 'users.localAccounts.displayName' -Issues $issues
            if ($realNameText -match '(?s)RealName:\s*(.+)$') {
                $displayName = ($matches[1] -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join ' '
            }

            $lastLogonAt = $null
            $lastLogonStatus = 'unavailable'
            $lastText = Invoke-InventoryCommand -FilePath 'last' -Arguments @('-F', '-1', $username) -Field 'users.localAccounts.lastLogonAt' -Issues $issues
            if (-not [string]::IsNullOrWhiteSpace($lastText)) {
                $lastLine = ($lastText -split '\r?\n' | Select-Object -First 1).Trim()
                if ($lastLine -match 'wtmp begins|never logged in') {
                    $lastLogonStatus = 'noRecord'
                }
                elseif ($lastLine -match '^\S+\s+\S+\s+(?<date>\p{L}{3}\s+\p{L}{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\d{4})') {
                    $dateText = $matches['date']
                    $lastLogonAt = ConvertTo-InventoryDate -Value $dateText
                    if ($null -ne $lastLogonAt) {
                        $lastLogonStatus = 'recorded'
                    }
                    else {
                        Add-InventoryIssue -Issues $issues -Field "users.localAccounts[$username].lastLogonAt" -Message "A data do último logon '$dateText' não pôde ser interpretada."
                    }
                }
                else {
                    Add-InventoryIssue -Issues $issues -Field "users.localAccounts[$username].lastLogonAt" -Message 'A saída de last não continha uma data de logon reconhecível.'
                }
            }
            else {
                Add-InventoryIssue -Issues $issues -Field "users.localAccounts[$username].lastLogonAt" -Message 'O comando last não retornou dados para a conta.'
            }

            $isAdministrator = if ([int]$userId -eq 0) {
                $true
            }
            elseif ($adminGroupAvailable) {
                $adminUsers.ContainsKey($username)
            }
            else {
                $null
            }

            $accounts += [ordered]@{
                username = $username
                displayName = $displayName
                identifier = $userId
                isAdministrator = $isAdministrator
                lastLogonAt = $lastLogonAt
                lastLogonStatus = $lastLogonStatus
            }
        }
    }
    else {
        Add-InventoryIssue -Issues $issues -Field 'users.localAccounts' -Message 'dscl não retornou contas locais.'
    }

    $currentUsername = [Environment]::UserName
    $currentAccount = $accounts | Where-Object { $_.username -eq $currentUsername } | Select-Object -First 1
    if ($null -eq $currentAccount) {
        Add-InventoryIssue -Issues $issues -Field 'users.currentUser' -Message 'O usuário atual não foi encontrado na lista local de contas.'
    }
    $whoOutput = Invoke-InventoryCommand -FilePath 'who' -Arguments @() -Field 'users.activeSessions' -Issues $issues
    $activeSessions = @()
    if (-not [string]::IsNullOrWhiteSpace($whoOutput)) {
        foreach ($line in ($whoOutput -split '\r?\n')) {
            if ($line -match '^(\S+)\s+(\S+)\s+(?<date>\p{L}{3}\s+\p{L}{3}\s+\d{1,2}\s+\d{2}:\d{2}|\p{L}{3}\s+\d{1,2}\s+\d{2}:\d{2})') {
                $dateText = '{0} {1}' -f $matches['date'], [datetime]::Now.Year
                $loginDate = ConvertTo-InventoryDate -Value $dateText
                $activeSessions += [ordered]@{
                    username = $matches[1]
                    terminal = $matches[2]
                    loginTime = $loginDate
                    durationSeconds = if ($null -ne $loginDate -and $matches[1] -eq $currentUsername) {
                        [math]::Max(0, [int64]([datetime]::UtcNow - [datetime]::Parse($loginDate).ToUniversalTime()).TotalSeconds)
                    } else { $null }
                }
            }
            elseif (-not [string]::IsNullOrWhiteSpace($line)) {
                Add-InventoryIssue -Issues $issues -Field 'users.activeSessions' -Message "Não foi possível interpretar a sessão '$line'."
            }
        }
    }
    if ($activeSessions.Count -eq 0) {
        Add-InventoryIssue -Issues $issues -Field 'users.activeSessions' -Message 'Nenhuma sessão ativa pôde ser interpretada na saída de who.'
    }
    if (-not ($activeSessions | Where-Object { $_.username -eq $currentUsername })) {
        Add-InventoryIssue -Issues $issues -Field 'activity.currentSessionStartedAt' -Message 'A sessão atual não foi identificada na saída de who.'
    }

    $bootTimeText = Invoke-InventoryCommand -FilePath 'sysctl' -Arguments @('-n', 'kern.boottime') -Field 'activity.uptimeSeconds' -Issues $issues
    $uptimeSeconds = $null
    if ($bootTimeText -match 'sec\s*=\s*(\d+)') {
        $bootTime = [datetimeoffset]::FromUnixTimeSeconds([int64]$matches[1])
        $uptimeSeconds = [math]::Max(0, [int64]([datetimeoffset]::UtcNow - $bootTime).TotalSeconds)
    }
    else {
        Add-InventoryIssue -Issues $issues -Field 'activity.uptimeSeconds' -Message 'Não foi possível interpretar o horário de inicialização retornado por sysctl.'
    }

    if ($null -eq $hardware) {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware' -Message 'Os dados de hardware não foram disponibilizados por system_profiler.'
    }
    if ([string]::IsNullOrWhiteSpace($productName)) {
        Add-InventoryIssue -Issues $issues -Field 'device.operatingSystem.name' -Message 'sw_vers não retornou o nome do sistema operacional.'
    }
    if ([string]::IsNullOrWhiteSpace($productVersion)) {
        Add-InventoryIssue -Issues $issues -Field 'device.operatingSystem.version' -Message 'sw_vers não retornou a versão do sistema operacional.'
    }
    else {
        foreach ($hardwareField in @('machine_model', 'serial_number')) {
            if ([string]::IsNullOrWhiteSpace([string]$hardware.$hardwareField)) {
                Add-InventoryIssue -Issues $issues -Field "device.hardware.$hardwareField" -Message "system_profiler não retornou '$hardwareField'."
            }
        }
        if ($hardware.serial_number -match '^(not available|unknown|0+)$') {
            Add-InventoryIssue -Issues $issues -Field 'device.hardware.serialNumber' -Message 'system_profiler retornou um valor genérico em vez de um número de série.'
            $hardware.serial_number = $null
        }
        if ($null -eq $memoryBytes) {
            Add-InventoryIssue -Issues $issues -Field 'device.hardware.memoryBytes' -Message 'system_profiler não retornou uma quantidade de memória interpretável.'
        }
        $cpuNames = @($hardware.chip_type, $hardware.processor_name) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
        if ($cpuNames.Count -eq 0) {
            Add-InventoryIssue -Issues $issues -Field 'device.hardware.cpu' -Message 'system_profiler não retornou o modelo da CPU.'
        }
    }

    return [ordered]@{
        device = [ordered]@{
            hostname = [Environment]::MachineName
            operatingSystem = [ordered]@{
                name = $productName
                version = $productVersion
                architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
            }
            hardware = [ordered]@{
                manufacturer = 'Apple'
                model = if ($null -ne $hardware) { $hardware.machine_model } else { $null }
                serialNumber = if ($null -ne $hardware) { $hardware.serial_number } else { $null }
                cpu = if ($null -ne $hardware) { @($hardware.chip_type, $hardware.processor_name) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique } else { @() }
                memoryBytes = $memoryBytes
                storage = $storage
            }
            networkAdapters = Get-InventoryNetworkAdapters -Issues $issues
        }
        users = [ordered]@{
            currentUser = [ordered]@{
                username = $currentUsername
                displayName = if ($null -ne $currentAccount) { $currentAccount.displayName } else { $null }
                identifier = if ($null -ne $currentAccount) { $currentAccount.identifier } else { $null }
            }
            localAccounts = $accounts
            activeSessions = $activeSessions
        }
        activity = [ordered]@{
            uptimeSeconds = $uptimeSeconds
            currentSessionStartedAt = ($activeSessions | Where-Object { $_.username -eq $currentUsername } | Select-Object -First 1).loginTime
            currentSessionDurationSeconds = ($activeSessions | Where-Object { $_.username -eq $currentUsername } | Select-Object -First 1).durationSeconds
        }
        issues = @($issues)
    }
}
