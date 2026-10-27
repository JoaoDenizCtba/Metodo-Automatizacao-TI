function New-InventoryEnvironmentCheck {
    param(
        [string]$Name,
        [bool]$Required,
        [bool]$Passed,
        [string]$Message
    )

    [ordered]@{
        name = $Name
        required = $Required
        status = if ($Passed) { 'passed' } elseif ($Required) { 'failed' } else { 'warning' }
        message = $Message
    }
}

function Test-InventoryEnvironment {
    param([string[]]$AdditionalRequiredCommands = @())

    $checks = [System.Collections.Generic.List[object]]::new()
    $isSupportedOperatingSystem = $IsWindows -or $IsLinux -or $IsMacOS

    $checks.Add((New-InventoryEnvironmentCheck `
        -Name 'powershell.version' `
        -Required $true `
        -Passed ($PSVersionTable.PSVersion.Major -ge 7) `
        -Message "Versão detectada: $($PSVersionTable.PSVersion.ToString()); mínimo requerido: 7.0."))

    $checks.Add((New-InventoryEnvironmentCheck `
        -Name 'operatingSystem.supported' `
        -Required $true `
        -Passed $isSupportedOperatingSystem `
        -Message "Plataforma detectada: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)"))

    $requiredCommands = if ($IsWindows) {
        @('Get-CimInstance', 'Get-LocalUser', 'Get-LocalGroup', 'Get-LocalGroupMember', 'quser.exe')
    }
    elseif ($IsLinux) {
        @('df', 'who')
    }
    elseif ($IsMacOS) {
        @('sw_vers', 'system_profiler', 'dscl', 'last', 'who', 'sysctl', 'df')
    }
    else {
        @()
    }

    foreach ($commandName in @($requiredCommands) + @($AdditionalRequiredCommands)) {
        $command = Get-Command -Name $commandName -ErrorAction SilentlyContinue
        $checks.Add((New-InventoryEnvironmentCheck `
            -Name "command.$commandName" `
            -Required $true `
            -Passed ($null -ne $command) `
            -Message $(if ($null -ne $command) { "Comando disponível em '$($command.Source)'." } else { "Comando obrigatório '$commandName' não está disponível." })))
    }

    if ($IsLinux) {
        $lastLogonCommand = Get-Command -Name 'lastlog' -ErrorAction SilentlyContinue
        $checks.Add((New-InventoryEnvironmentCheck `
            -Name 'command.lastlog' `
            -Required $false `
            -Passed ($null -ne $lastLogonCommand) `
            -Message $(if ($null -ne $lastLogonCommand) { "Comando disponível em '$($lastLogonCommand.Source)'." } else { "Comando 'lastlog' indisponível; último logon das contas não será coletado." })))

        foreach ($path in @('/etc/os-release', '/etc/passwd', '/etc/group', '/proc/cpuinfo', '/proc/meminfo', '/proc/uptime')) {
            $readable = $false
            $readError = $null
            try {
                if (Test-Path -LiteralPath $path -PathType Leaf) {
                    $null = Get-Content -LiteralPath $path -TotalCount 1 -ErrorAction Stop
                    $readable = $true
                }
                else {
                    $readError = "Arquivo '$path' não existe."
                }
            }
            catch {
                $readError = $_.Exception.Message
            }

            $checks.Add((New-InventoryEnvironmentCheck `
                -Name "file.$path" `
                -Required $true `
                -Passed $readable `
                -Message $(if ($readable) { "Arquivo '$path' pode ser lido." } else { "Arquivo obrigatório '$path' ausente ou sem permissão de leitura. $readError" })))
        }
    }

    $failedChecks = @($checks | Where-Object { $_.status -eq 'failed' })
    $warnings = @($checks | Where-Object { $_.status -eq 'warning' })

    [ordered]@{
        status = if ($failedChecks.Count -gt 0) { 'failed' } elseif ($warnings.Count -gt 0) { 'warning' } else { 'passed' }
        checkedAtUtc = [datetime]::UtcNow.ToString('o')
        powershellVersion = $PSVersionTable.PSVersion.ToString()
        operatingSystem = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        checks = @($checks)
    }
}

function Install-InventoryLinuxCoreUtilities {
    $packageInstallations = @(
        @{ command = 'apt-get'; arguments = @('install', '-y', 'coreutils') },
        @{ command = 'dnf'; arguments = @('install', '-y', 'coreutils') },
        @{ command = 'yum'; arguments = @('install', '-y', 'coreutils') },
        @{ command = 'zypper'; arguments = @('--non-interactive', 'install', '-y', 'coreutils') },
        @{ command = 'apk'; arguments = @('add', 'coreutils') }
    )

    $packageManager = $packageInstallations |
        Where-Object { $null -ne (Get-Command -Name $_.command -ErrorAction SilentlyContinue) } |
        Select-Object -First 1

    if ($null -eq $packageManager) {
        throw 'df/who estão ausentes e nenhum gerenciador Linux suportado foi encontrado; instale o pacote coreutils pela distribuição e execute novamente.'
    }

    $commandPath = (Get-Command -Name $packageManager.command -ErrorAction Stop).Source
    $installArguments = @($packageManager.arguments)
    $isRoot = [Environment]::UserName -eq 'root'
    if ($isRoot) {
        & $commandPath @installArguments
    }
    else {
        $sudo = Get-Command -Name 'sudo' -ErrorAction SilentlyContinue
        if ($null -eq $sudo) {
            throw "O pacote coreutils precisa ser instalado por '$($packageManager.command)', mas sudo não está disponível. Execute a instalação como administrador e tente novamente."
        }

        & $sudo.Source $commandPath @installArguments
    }

    if ($LASTEXITCODE -ne 0) {
        throw "A instalação automática de coreutils terminou com código $LASTEXITCODE."
    }
}

function Ensure-InventoryEnvironment {
    if ($IsLinux) {
        $missingCoreUtilities = @('df', 'who') |
            Where-Object { $null -eq (Get-Command -Name $_ -ErrorAction SilentlyContinue) }

        if ($missingCoreUtilities.Count -gt 0) {
            Write-Host 'Dependências obrigatórias ausentes: coreutils. Tentando instalar pelo gerenciador já configurado.'
            Install-InventoryLinuxCoreUtilities
        }
    }

    Test-InventoryEnvironment
}
