function Add-InventoryIssue {
    param(
        [System.Collections.Generic.List[object]]$Issues,
        [string]$Field,
        [string]$Message
    )

    $Issues.Add([ordered]@{
        field = $Field
        message = $Message
    })
}

function Invoke-InventoryCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$Field,
        [System.Collections.Generic.List[object]]$Issues
    )

    $command = Get-Command -Name $FilePath -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Add-InventoryIssue -Issues $Issues -Field $Field -Message "Comando '$FilePath' não encontrado."
        return $null
    }

    try {
        $result = & $command.Source @Arguments 2>$null
        if ($LASTEXITCODE -ne 0) {
            Add-InventoryIssue -Issues $Issues -Field $Field -Message "Comando '$FilePath' terminou com código $LASTEXITCODE."
            return $null
        }

        return ($result -join [Environment]::NewLine).Trim()
    }
    catch {
        Add-InventoryIssue -Issues $Issues -Field $Field -Message $_.Exception.Message
        return $null
    }
}

function Get-InventoryNetworkAdapters {
    param([System.Collections.Generic.List[object]]$Issues)

    try {
        return @(
            [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                ForEach-Object {
                    [ordered]@{
                        name = $_.Name
                        description = $_.Description
                        status = $_.OperationalStatus.ToString()
                        macAddress = $_.GetPhysicalAddress().ToString()
                        addresses = @(
                            $_.GetIPProperties().UnicastAddresses |
                                ForEach-Object { $_.Address.ToString() }
                        )
                    }
                }
        )
    }
    catch {
        Add-InventoryIssue -Issues $Issues -Field 'device.networkAdapters' -Message $_.Exception.Message
        return @()
    }
}

function Get-InventoryFileLines {
    param(
        [string]$Path,
        [string]$Field,
        [System.Collections.Generic.List[object]]$Issues
    )

    try {
        $lines = @(Get-Content -LiteralPath $Path -ErrorAction Stop)
        return ,$lines
    }
    catch {
        Add-InventoryIssue -Issues $Issues -Field $Field -Message "Não foi possível ler '$Path': $($_.Exception.Message)"
        return ,@()
    }
}

function ConvertTo-InventoryDate {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    foreach ($culture in @(
        [System.Globalization.CultureInfo]::CurrentCulture,
        [System.Globalization.CultureInfo]::InvariantCulture
    )) {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParse(
                $Value,
                $culture,
                [System.Globalization.DateTimeStyles]::AssumeLocal,
                [ref]$parsed
            )) {
            return $parsed.ToUniversalTime().ToString('o')
        }
    }

    return $null
}
