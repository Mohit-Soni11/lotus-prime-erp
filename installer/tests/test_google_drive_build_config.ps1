$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $projectRoot 'installer\google_drive_build_config.ps1')
$runId = [Guid]::NewGuid().ToString('N')
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "lotus-google-build-$runId"
$defaultConfig = Join-Path $testRoot 'config\google-drive.local.json'
$customConfig = Join-Path $testRoot 'custom identity.json'

function Assert-Throws([scriptblock]$Action, [string]$ExpectedMessage) {
    try {
        & $Action | Out-Null
    } catch {
        if ($_.Exception.Message.Contains($ExpectedMessage)) { return }
        throw
    }
    throw "Expected configuration validation failure: $ExpectedMessage"
}

New-Item -ItemType Directory -Path (Split-Path -Parent $defaultConfig) | Out-Null
try {
    Assert-Throws { Get-GoogleDriveBuildArguments -ProjectRoot $testRoot } 'configuration is missing'
    $localOnly = @(Get-GoogleDriveBuildArguments -ProjectRoot $testRoot -AllowLocalBackupOnly -WarningAction SilentlyContinue)
    if ($localOnly.Count -ne 0) { throw 'An intentional local-only build received Google arguments.' }

    $valid = '{"LOTUS_GOOGLE_CLIENT_ID":"test.apps.googleusercontent.com","LOTUS_GOOGLE_CLIENT_SECRET":"synthetic-test-secret"}'
    Set-Content -LiteralPath $defaultConfig -Value $valid -Encoding UTF8
    $defaultArguments = @(Get-GoogleDriveBuildArguments -ProjectRoot $testRoot)
    if ($defaultArguments.Count -ne 1 -or $defaultArguments[0] -cne "--dart-define-from-file=$defaultConfig") {
        throw 'The default Google configuration was not passed to Flutter.'
    }

    Set-Content -LiteralPath $customConfig -Value $valid -Encoding UTF8
    $customArguments = @(Get-GoogleDriveBuildArguments -ProjectRoot $testRoot -ConfigurationPath $customConfig)
    if ($customArguments.Count -ne 1 -or $customArguments[0] -cne "--dart-define-from-file=$customConfig") {
        throw 'The explicit configuration path containing spaces was not preserved.'
    }

    foreach ($invalidDocument in @(
        '{"LOTUS_GOOGLE_CLIENT_ID":"invalid"}',
        '{"LOTUS_GOOGLE_CLIENT_ID":42}',
        '{"LOTUS_GOOGLE_CLIENT_ID":"test.apps.googleusercontent.com","refresh_token":"synthetic-test-token"}',
        '{"installed":{"client_id":"test.apps.googleusercontent.com"}}'
    )) {
        Set-Content -LiteralPath $customConfig -Value $invalidDocument -Encoding UTF8
        Assert-Throws { Get-GoogleDriveBuildArguments -ProjectRoot $testRoot -ConfigurationPath $customConfig } 'Google Drive build configuration'
    }
    Write-Output 'Eight Google release-configuration checks passed. No installer was built or installed.'
} finally {
    $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
    $expectedTestRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) "lotus-google-build-$runId"))
    if ($resolvedTestRoot -ne $expectedTestRoot -or (Split-Path -Leaf $resolvedTestRoot) -cne "lotus-google-build-$runId") {
        throw 'Refusing to clean up an unexpected test directory.'
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
