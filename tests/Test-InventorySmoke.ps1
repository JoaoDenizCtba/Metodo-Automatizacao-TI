$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$executorPath = Join-Path $repositoryRoot 'executor/Invoke-Inventario.ps1'
$matrixPath = Join-Path $repositoryRoot 'matriz/inventario.json'
$reportPath = Join-Path ([System.IO.Path]::GetTempPath()) "inventory-smoke-$([guid]::NewGuid().ToString('N')).json"

try {
    & $executorPath -ConfigPath $matrixPath -OutputPath $reportPath | Out-Null
    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
        throw 'O executor não criou o relatório de inventário.'
    }

    $report = Get-Content -LiteralPath $reportPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    foreach ($field in @('schemaVersion', 'collectedAtUtc', 'collectorVersion', 'environmentValidation', 'device', 'users', 'activity', 'issues')) {
        if (-not $report.ContainsKey($field)) {
            throw "Campo obrigatório ausente no relatório: $field"
        }
    }

    if ($report.environmentValidation.status -eq 'failed') {
        throw 'O relatório foi gerado apesar de a validação do ambiente falhar.'
    }

    . (Join-Path $repositoryRoot 'scripts/Environment.Validation.ps1')
    $failedEnvironment = Test-InventoryEnvironment -AdditionalRequiredCommands @('__inventory_test_missing_command__')
    $simulatedMissingCommand = $failedEnvironment.checks |
        Where-Object { $_.name -eq 'command.__inventory_test_missing_command__' }
    if ($null -eq $simulatedMissingCommand -or $simulatedMissingCommand.status -ne 'failed') {
        throw 'A validação não marcou uma dependência obrigatória simulada como falha.'
    }

    foreach ($check in $report.environmentValidation.checks) {
        if ($check.status -eq 'failed') {
            throw "A validação deveria ter bloqueado a coleta: $($check.name)"
        }
    }

    foreach ($field in @('hostname', 'operatingSystem', 'hardware', 'networkAdapters')) {
        if (-not $report.device.Contains($field)) {
            throw "Campo obrigatório ausente em device: $field"
        }
    }

    foreach ($field in @('name', 'version', 'architecture')) {
        if (-not $report.device.operatingSystem.Contains($field)) {
            throw "Campo obrigatório ausente em device.operatingSystem: $field"
        }
    }

    foreach ($field in @('manufacturer', 'model', 'serialNumber', 'cpu', 'memoryBytes', 'storage')) {
        if (-not $report.device.hardware.Contains($field)) {
            throw "Campo obrigatório ausente em device.hardware: $field"
        }
    }

    foreach ($field in @('currentUser', 'localAccounts', 'activeSessions')) {
        if (-not $report.users.Contains($field)) {
            throw "Campo obrigatório ausente em users: $field"
        }
    }

    foreach ($field in @('username', 'displayName', 'identifier')) {
        if (-not $report.users.currentUser.Contains($field)) {
            throw "Campo obrigatório ausente em users.currentUser: $field"
        }
    }

    foreach ($account in $report.users.localAccounts) {
        foreach ($field in @('username', 'displayName', 'identifier', 'isAdministrator', 'lastLogonAt', 'lastLogonStatus')) {
            if (-not $account.Contains($field)) {
                throw "Campo obrigatório ausente em users.localAccounts: $field"
            }
        }
    }

    foreach ($session in $report.users.activeSessions) {
        foreach ($field in @('username', 'loginTime', 'durationSeconds')) {
            if (-not $session.Contains($field)) {
                throw "Campo obrigatório ausente em users.activeSessions: $field"
            }
        }
    }

    foreach ($field in @('uptimeSeconds', 'currentSessionStartedAt', 'currentSessionDurationSeconds')) {
        if (-not $report.activity.Contains($field)) {
            throw "Campo obrigatório ausente em activity: $field"
        }
    }

    if ($report.schemaVersion -ne 1) {
        throw "Versão inesperada do relatório: $($report.schemaVersion)"
    }

    Write-Output 'Inventory smoke test passed.'
}
finally {
    if (Test-Path -LiteralPath $reportPath -PathType Leaf) {
        Remove-Item -LiteralPath $reportPath -Force -ErrorAction Stop
    }
}
