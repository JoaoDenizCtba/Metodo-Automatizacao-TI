[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../matriz/inventario.json'),
    [string]$OutputPath
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Este executor requer PowerShell 7 ou superior.'
}

$configFullPath = [System.IO.Path]::GetFullPath($ConfigPath)
if (-not (Test-Path -LiteralPath $configFullPath -PathType Leaf)) {
    throw "Arquivo de configuração não encontrado: $configFullPath"
}

try {
    $config = Get-Content -LiteralPath $configFullPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable -ErrorAction Stop
}
catch {
    throw "Não foi possível carregar a matriz JSON '$configFullPath': $($_.Exception.Message)"
}

if ($config.schemaVersion -ne 1) {
    throw "Versão de matriz não suportada: '$($config.schemaVersion)'."
}

if ([string]::IsNullOrWhiteSpace($config.fileNamePrefix)) {
    throw 'A matriz precisa definir fileNamePrefix com um valor não vazio.'
}

$collectorPath = if ($IsWindows) {
    Join-Path $PSScriptRoot '../scripts/Inventario.Windows.ps1'
}
elseif ($IsLinux) {
    Join-Path $PSScriptRoot '../scripts/Inventario.Linux.ps1'
}
elseif ($IsMacOS) {
    Join-Path $PSScriptRoot '../scripts/Inventario.macOS.ps1'
}
else {
    throw "Sistema operacional não suportado: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)"
}

$collectorFullPath = [System.IO.Path]::GetFullPath($collectorPath)
if (-not (Test-Path -LiteralPath $collectorFullPath -PathType Leaf)) {
    throw "Coletor do sistema operacional não encontrado: $collectorFullPath"
}

. $collectorFullPath
$inventory = Get-PlatformInventory

$collectedAt = [datetime]::UtcNow
$report = [ordered]@{
    schemaVersion = 1
    collectedAtUtc = $collectedAt.ToString('o')
    collectorVersion = '0.1.0'
    device = $inventory.device
    users = $inventory.users
    activity = $inventory.activity
    issues = @($inventory.issues)
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if ($config.outputDirectory -ne 'userLocalData') {
        throw "Valor de outputDirectory não suportado: '$($config.outputDirectory)'."
    }

    $baseDirectory = if ($IsWindows) {
        $env:LOCALAPPDATA
    }
    else {
        Join-Path $HOME '.local/share'
    }

    if ([string]::IsNullOrWhiteSpace($baseDirectory)) {
        throw 'Não foi possível determinar o diretório local do usuário para salvar o inventário.'
    }

    $outputDirectory = Join-Path (Join-Path $baseDirectory 'Metodo-Automatizacao-TI') 'inventarios'
    $safePrefix = [string]$config.fileNamePrefix -replace '[^a-zA-Z0-9._-]', '_'
    $safeHostName = [string]$inventory.device.hostname -replace '[^a-zA-Z0-9._-]', '_'
    $fileName = '{0}-{1}-{2}.json' -f $safePrefix, $safeHostName, $collectedAt.ToString('yyyyMMddTHHmmssfffZ')
    $OutputPath = Join-Path $outputDirectory $fileName
}
else {
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Parent $OutputPath
}

if ([string]::IsNullOrWhiteSpace($outputDirectory)) {
    throw 'O caminho de saída precisa incluir um diretório.'
}

$json = $report | ConvertTo-Json -Depth 12
if ($PSCmdlet.ShouldProcess($OutputPath, 'Salvar relatório de inventário local')) {
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $outputDirectory -Force -ErrorAction Stop
    }

    Set-Content -LiteralPath $OutputPath -Value $json -Encoding utf8NoBOM -ErrorAction Stop
    Write-Output $OutputPath
}
