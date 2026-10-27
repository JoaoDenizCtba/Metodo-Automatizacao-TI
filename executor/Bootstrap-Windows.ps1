[CmdletBinding()]
param(
    [string]$ConfigPath,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-PowerShell7Path {
    $command = Get-Command -Name 'pwsh.exe' -ErrorAction SilentlyContinue
    $candidates = @()
    if ($null -ne $command) {
        $candidates += $command.Source
    }

    $candidates += @(
        (Join-Path $env:ProgramFiles 'PowerShell/7/pwsh.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs/PowerShell/7/pwsh.exe')
    )

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            try {
                $version = & $candidate -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.Major' 2>$null
                if ($LASTEXITCODE -eq 0 -and [int]($version | Select-Object -Last 1) -ge 7) {
                    return $candidate
                }
            }
            catch {
                continue
            }
        }
    }

    return $null
}

$pwshPath = Get-PowerShell7Path
if ($null -eq $pwshPath) {
    $winget = Get-Command -Name 'winget.exe' -ErrorAction SilentlyContinue
    if ($null -ne $winget) {
        Write-Output 'PowerShell 7 ausente. Tentando instalar pelo WinGet disponível no sistema.'
        & $winget.Source install --id Microsoft.PowerShell --exact --source winget --scope user --accept-source-agreements --accept-package-agreements --disable-interactivity
        $wingetExitCode = $LASTEXITCODE
        $pwshPath = Get-PowerShell7Path
        if ($null -eq $pwshPath) {
            Write-Warning "WinGet não concluiu a instalação do PowerShell 7 (código $wingetExitCode); tentando o instalador oficial assinado."
        }
    }

    if ($null -eq $pwshPath) {
        $architecture = if ($env:PROCESSOR_ARCHITEW6432) {
            $env:PROCESSOR_ARCHITEW6432.ToLowerInvariant()
        }
        else {
            $env:PROCESSOR_ARCHITECTURE.ToLowerInvariant()
        }

        $assetArchitecture = switch -Regex ($architecture) {
            '^(amd64|x86_64)$' { 'x64'; break }
            '^(arm64|aarch64)$' { 'arm64'; break }
            '^(x86|i386|i686)$' { 'x86'; break }
            default { throw "Arquitetura Windows não suportada para instalação automática: $architecture" }
        }

        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -Headers @{
            'User-Agent' = 'Metodo-Automatizacao-TI'
            Accept = 'application/vnd.github+json'
        } -ErrorAction Stop
        $asset = $release.assets |
            Where-Object { $_.name -match "^PowerShell-[\d.]+-win-$assetArchitecture\.msi$" } |
            Select-Object -First 1
        if ($null -eq $asset -or $asset.digest -notmatch '^sha256:[a-fA-F0-9]{64}$') {
            throw "A versão estável publicada não contém MSI e SHA-256 válidos para Windows $assetArchitecture."
        }

        $temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "metodo-inventario-bootstrap-$([guid]::NewGuid().ToString('N'))"
        $null = New-Item -ItemType Directory -Path $temporaryDirectory -ErrorAction Stop
        try {
            $installerPath = Join-Path $temporaryDirectory $asset.name
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath -UseBasicParsing -ErrorAction Stop

            $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256 -ErrorAction Stop).Hash
            $expectedHash = $asset.digest.Substring('sha256:'.Length)
            if ($actualHash -ne $expectedHash) {
                throw 'O hash SHA-256 do instalador não corresponde ao digest publicado pela release oficial.'
            }

            $signature = Get-AuthenticodeSignature -FilePath $installerPath
            if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
                $signature.SignerCertificate.Subject -notmatch 'CN=Microsoft Corporation') {
                throw 'O instalador baixado não possui assinatura Authenticode válida da Microsoft.'
            }

            Write-Output "Instalando PowerShell 7 $($release.tag_name) pelo MSI oficial; o Windows poderá solicitar autorização administrativa."
            $installProcess = Start-Process -FilePath 'msiexec.exe' `
                -ArgumentList @('/i', "`"$installerPath`"", '/quiet', '/norestart', 'ADD_PATH=1') `
                -Verb RunAs -Wait -PassThru
            if ($installProcess.ExitCode -notin @(0, 3010)) {
                throw "O MSI oficial terminou com código $($installProcess.ExitCode)."
            }
        }
        finally {
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }

        $pwshPath = Get-PowerShell7Path
        if ($null -eq $pwshPath) {
            throw 'O instalador terminou, mas pwsh.exe não foi localizado. Reinicie o terminal e execute novamente.'
        }
    }
}

$inventoryPath = Join-Path $PSScriptRoot 'Invoke-Inventario.ps1'
$arguments = @('-NoLogo', '-NoProfile', '-File', $inventoryPath)
if (-not [string]::IsNullOrWhiteSpace($ConfigPath)) {
    $arguments += @('-ConfigPath', $ConfigPath)
}
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $arguments += @('-OutputPath', $OutputPath)
}

& $pwshPath @arguments
exit $LASTEXITCODE
