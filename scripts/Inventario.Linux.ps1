. (Join-Path $PSScriptRoot 'Inventario.Common.ps1')

function Get-PlatformInventory {
    $issues = [System.Collections.Generic.List[object]]::new()
    $osRelease = @{}
    $osReleaseLines = Get-InventoryFileLines -Path '/etc/os-release' -Field 'device.operatingSystem' -Issues $issues
    foreach ($line in $osReleaseLines) {
        if ($line -match '^([^=]+)=(.*)$') {
            $osRelease[$matches[1]] = $matches[2].Trim('"')
        }
    }
    if ([string]::IsNullOrWhiteSpace($osRelease['PRETTY_NAME'])) {
        Add-InventoryIssue -Issues $issues -Field 'device.operatingSystem.name' -Message 'PRETTY_NAME não foi encontrado em /etc/os-release.'
    }
    if ([string]::IsNullOrWhiteSpace($osRelease['VERSION_ID'])) {
        Add-InventoryIssue -Issues $issues -Field 'device.operatingSystem.version' -Message 'VERSION_ID não foi encontrado em /etc/os-release.'
    }

    $cpuName = $null
    $cpuLines = Get-InventoryFileLines -Path '/proc/cpuinfo' -Field 'device.hardware.cpu' -Issues $issues
    $cpuLine = $cpuLines | Where-Object { $_ -match '^model name\s*:' } | Select-Object -First 1
    if ($cpuLine -match '^model name\s*:\s*(.+)$') {
        $cpuName = $matches[1].Trim()
    }

    $memoryBytes = $null
    $memoryLines = Get-InventoryFileLines -Path '/proc/meminfo' -Field 'device.hardware.memoryBytes' -Issues $issues
    $memoryLine = $memoryLines | Where-Object { $_ -match '^MemTotal:' } | Select-Object -First 1
    if ($memoryLine -match '^MemTotal:\s+(\d+)\s+kB') {
        $memoryBytes = [uint64]$matches[1] * 1KB
    }
    if ($null -eq $memoryBytes) {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware.memoryBytes' -Message 'A memória física não pôde ser lida em /proc/meminfo.'
    }
    if ([string]::IsNullOrWhiteSpace($cpuName)) {
        Add-InventoryIssue -Issues $issues -Field 'device.hardware.cpu' -Message 'O modelo da CPU não pôde ser lido em /proc/cpuinfo.'
    }

    $manufacturer = $null
    $model = $null
    $serialNumber = $null
    foreach ($dmiField in @(
        @{ path = '/sys/class/dmi/id/sys_vendor'; key = 'manufacturer' },
        @{ path = '/sys/class/dmi/id/product_name'; key = 'model' },
        @{ path = '/sys/class/dmi/id/product_serial'; key = 'serialNumber' }
    )) {
        $valueLines = Get-InventoryFileLines -Path $dmiField.path -Field "device.hardware.$($dmiField.key)" -Issues $issues
        $value = ($valueLines | Select-Object -First 1)
        if ([string]::IsNullOrWhiteSpace($value) -or $value -match '^(none|unknown|not specified|to be filled by o\.e\.m\.|0+)$') {
            Add-InventoryIssue -Issues $issues -Field "device.hardware.$($dmiField.key)" -Message "O campo DMI '$($dmiField.key)' não retornou valor."
        }
        else {
            switch ($dmiField.key) {
                'manufacturer' { $manufacturer = $value.Trim() }
                'model' { $model = $value.Trim() }
                'serialNumber' { $serialNumber = $value.Trim() }
            }
        }
    }

    $storage = @()
    $dfOutput = Invoke-InventoryCommand -FilePath 'df' -Arguments @('-Pk', '-x', 'tmpfs', '-x', 'devtmpfs') -Field 'device.hardware.storage' -Issues $issues
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
    $adminGroupIds = @{}
    $groupLines = Get-InventoryFileLines -Path '/etc/group' -Field 'users.localAccounts.isAdministrator' -Issues $issues
    $adminGroupsAvailable = $groupLines.Count -gt 0
    foreach ($line in $groupLines) {
        if ($line -match '^(sudo|wheel):[^:]*:(\d+):([^:]*)$') {
            $adminGroupIds[$matches[2]] = $true
            foreach ($member in $matches[3] -split ',') {
                if (-not [string]::IsNullOrWhiteSpace($member)) {
                    $adminUsers[$member] = $true
                }
            }
        }
    }

    $accounts = @()
    $lastLogonCommandAvailable = $null -ne (Get-Command -Name 'lastlog' -ErrorAction SilentlyContinue)
    if (-not $lastLogonCommandAvailable) {
        Add-InventoryIssue -Issues $issues -Field 'users.localAccounts.lastLogonAt' -Message "Comando 'lastlog' não encontrado."
    }
    $accountLines = Get-InventoryFileLines -Path '/etc/passwd' -Field 'users.localAccounts' -Issues $issues
    foreach ($line in $accountLines) {
        $columns = $line -split ':'
        if ($columns.Count -lt 7) {
            Add-InventoryIssue -Issues $issues -Field 'users.localAccounts' -Message 'Uma linha de /etc/passwd não pôde ser interpretada.'
            continue
        }

        $lastLogonAt = $null
        $lastLogonStatus = 'unavailable'
        if ($lastLogonCommandAvailable) {
            $lastLogonText = Invoke-InventoryCommand -FilePath 'lastlog' -Arguments @('-u', $columns[0]) -Field "users.localAccounts[$($columns[0])].lastLogonAt" -Issues $issues
        }
        if ($lastLogonCommandAvailable -and -not [string]::IsNullOrWhiteSpace($lastLogonText)) {
                $lastLogonLine = ($lastLogonText -split '\r?\n' | Select-Object -Last 1).Trim()
                if ($lastLogonLine -match '\*{0,2}Never logged in\*{0,2}') {
                    $lastLogonStatus = 'noRecord'
                }
                else {
                    $dateMatch = [regex]::Match($lastLogonLine, '(?<date>\p{L}{3}\s+\p{L}{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}(?:\s+\S+)?\s+\d{4})')
                    if ($dateMatch.Success) {
                        $lastLogonAt = ConvertTo-InventoryDate -Value $dateMatch.Groups['date'].Value
                    }
                    if ($null -ne $lastLogonAt) {
                        $lastLogonStatus = 'recorded'
                    }
                    else {
                        Add-InventoryIssue -Issues $issues -Field "users.localAccounts[$($columns[0])].lastLogonAt" -Message 'A data do último logon não pôde ser interpretada.'
                    }
                }
        }
        elseif ($lastLogonCommandAvailable) {
                Add-InventoryIssue -Issues $issues -Field "users.localAccounts[$($columns[0])].lastLogonAt" -Message 'lastlog não retornou um registro para esta conta.'
        }

        $accounts += [ordered]@{
                username = $columns[0]
                displayName = (($columns[4] -split ',')[0])
                identifier = $columns[2]
                isAdministrator = if ([int]$columns[2] -eq 0) {
                    $true
                }
                elseif ($adminGroupsAvailable) {
                    $adminGroupIds.ContainsKey($columns[3]) -or $adminUsers.ContainsKey($columns[0])
                }
                else {
                    $null
                }
            lastLogonAt = $lastLogonAt
            lastLogonStatus = $lastLogonStatus
        }
    }

    $currentUsername = [Environment]::UserName
    $currentAccount = $accounts | Where-Object { $_.username -eq $currentUsername } | Select-Object -First 1
    if ($null -eq $currentAccount) {
        Add-InventoryIssue -Issues $issues -Field 'users.currentUser' -Message 'O usuário atual não foi encontrado em /etc/passwd.'
    }
    $activeSessions = @()
    $whoOutput = Invoke-InventoryCommand -FilePath 'who' -Arguments @('-u') -Field 'users.activeSessions' -Issues $issues
    if (-not [string]::IsNullOrWhiteSpace($whoOutput)) {
        foreach ($line in ($whoOutput -split '\r?\n')) {
            if ($line -match '^(\S+)\s+(\S+)\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})(?:\s+(\S+))?(?:\s+(\d+))?') {
                $loginDate = ConvertTo-InventoryDate -Value $matches[3]
                $activeSessions += [ordered]@{
                    username = $matches[1]
                    terminal = $matches[2]
                    loginTime = $loginDate
                    durationSeconds = if ($null -ne $loginDate -and $matches[1] -eq $currentUsername) {
                        [math]::Max(0, [int64]([datetime]::UtcNow - [datetime]::Parse($loginDate).ToUniversalTime()).TotalSeconds)
                    } else { $null }
                }
            }
        }
    }
    if ($activeSessions.Count -eq 0) {
        Add-InventoryIssue -Issues $issues -Field 'users.activeSessions' -Message 'Nenhuma sessão ativa pôde ser interpretada na saída de who.'
    }
    if (-not ($activeSessions | Where-Object { $_.username -eq $currentUsername })) {
        Add-InventoryIssue -Issues $issues -Field 'activity.currentSessionStartedAt' -Message 'A sessão atual não foi identificada na saída de who.'
    }

    $uptimeSeconds = $null
    $uptimeLines = Get-InventoryFileLines -Path '/proc/uptime' -Field 'activity.uptimeSeconds' -Issues $issues
    if ($uptimeLines.Count -gt 0) {
        $uptimeText = $uptimeLines[0] -split '\s+' | Select-Object -First 1
        $uptimeValue = 0.0
        if ([double]::TryParse(
                $uptimeText,
                [System.Globalization.NumberStyles]::Float,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [ref]$uptimeValue
            )) {
            $uptimeSeconds = [int64]$uptimeValue
        }
            else {
                Add-InventoryIssue -Issues $issues -Field 'activity.uptimeSeconds' -Message 'O valor de /proc/uptime não pôde ser interpretado.'
            }
    }

    return [ordered]@{
        device = [ordered]@{
            hostname = [Environment]::MachineName
            operatingSystem = [ordered]@{
                name = $osRelease['PRETTY_NAME']
                version = $osRelease['VERSION_ID']
                architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
            }
            hardware = [ordered]@{
                manufacturer = $manufacturer
                model = $model
                serialNumber = $serialNumber
                cpu = @($cpuName)
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
