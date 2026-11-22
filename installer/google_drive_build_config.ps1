function Get-GoogleDriveBuildArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$ConfigurationPath
    )

    if (-not $ConfigurationPath) {
        $defaultConfig = Join-Path $ProjectRoot 'config\google-drive.local.json'
        if (Test-Path -LiteralPath $defaultConfig) {
            $ConfigurationPath = $defaultConfig
        } else {
            Write-Warning 'Google account connection will be unavailable in this build. Local backup and restore remain available. Configure the application identity before releasing Google Drive backup.'
            return
        }
    }
    $configPath = (Resolve-Path -LiteralPath $ConfigurationPath).Path
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    $allowedKeys = @('LOTUS_GOOGLE_CLIENT_ID', 'LOTUS_GOOGLE_CLIENT_SECRET')
    if (-not $config -or $config -isnot [PSCustomObject]) {
        throw 'Google Drive build configuration must be a JSON object.'
    }
    foreach ($property in $config.PSObject.Properties) {
        if ($property.Name -cnotin $allowedKeys -or $property.Value -isnot [string]) {
            throw 'Google Drive build configuration must contain only application client ID and client secret strings. Do not include account credentials, tokens or business data.'
        }
    }
    $clientId = $config.PSObject.Properties['LOTUS_GOOGLE_CLIENT_ID']
    if (-not $clientId -or $clientId.Value -cnotmatch '^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$') {
        throw 'Google Drive build configuration requires a valid Desktop application client ID.'
    }
    Write-Output "--dart-define-from-file=$configPath"
}
