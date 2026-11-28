param(
    [string]$GoogleDriveConfig,
    [switch]$AllowLocalBackupOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$pubspec = Get-Content -LiteralPath $pubspecPath -Raw
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$')
if (-not $versionMatch.Success) {
    throw 'pubspec.yaml must contain version: major.minor.patch+build.'
}
$appVersion = $versionMatch.Groups[1].Value
$appBuild = $versionMatch.Groups[2].Value

. (Join-Path $PSScriptRoot 'google_drive_build_config.ps1')
$flutterBuildArguments = @('build', 'windows', '--release', '--no-pub')
$flutterBuildArguments += @(Get-GoogleDriveBuildArguments -ProjectRoot $projectRoot -ConfigurationPath $GoogleDriveConfig -AllowLocalBackupOnly:$AllowLocalBackupOnly)
$emailRecoveryConfigPath = Join-Path $projectRoot 'config\email-recovery.json'
if (-not (Test-Path -LiteralPath $emailRecoveryConfigPath)) {
    throw 'Email recovery build configuration is missing.'
}
$emailRecoveryConfig = Get-Content -LiteralPath $emailRecoveryConfigPath -Raw | ConvertFrom-Json
if ($emailRecoveryConfig.LOTUS_RECOVERY_API_KEY -isnot [string] -or
    [string]::IsNullOrWhiteSpace($emailRecoveryConfig.LOTUS_RECOVERY_API_KEY) -or
    $emailRecoveryConfig.LOTUS_RECOVERY_CONTINUE_URL -isnot [string] -or
    -not $emailRecoveryConfig.LOTUS_RECOVERY_CONTINUE_URL.StartsWith('https://', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Email recovery build configuration requires a Firebase API key and HTTPS continuation URL.'
}
$flutterBuildArguments += "--dart-define-from-file=$emailRecoveryConfigPath"

$compilerCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $compiler) {
    throw 'Inno Setup 6 is required. Install JRSoftware.InnoSetup with winget.'
}

Push-Location -LiteralPath $projectRoot
try {
    $releaseDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
    $expectedReleaseDir = [IO.Path]::GetFullPath((Join-Path $projectRoot 'build\windows\x64\runner\Release'))
    $actualReleaseDir = [IO.Path]::GetFullPath($releaseDir)
    if ($actualReleaseDir -ne $expectedReleaseDir -or
        -not $actualReleaseDir.StartsWith([IO.Path]::GetFullPath($projectRoot) + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Release directory is outside the project build folder.'
    }
    if (Test-Path -LiteralPath $releaseDir) {
        $existingBusinessData = Get-ChildItem -LiteralPath $releaseDir -File -Recurse |
            Where-Object { $_.Extension -in @('.db', '.sqlite', '.sqlite3', '.lotusbackup') }
        if ($existingBusinessData) {
            throw 'Release output contains business data or a backup. Clean build stopped to protect data.'
        }
        Remove-Item -LiteralPath $releaseDir -Recurse -Force
    }

    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }

    & flutter @flutterBuildArguments
    if ($LASTEXITCODE -ne 0) { throw 'Windows release build failed.' }

    foreach ($required in @('lotus_erp.exe', 'flutter_windows.dll', 'data')) {
        if (-not (Test-Path -LiteralPath (Join-Path $releaseDir $required))) {
            throw "Release package is missing $required."
        }
    }
    $compiledVersion = (Get-Item -LiteralPath (Join-Path $releaseDir 'lotus_erp.exe')).VersionInfo.FileVersion
    if ($compiledVersion -ne "$appVersion+$appBuild") {
        throw "Release version mismatch: expected $appVersion+$appBuild, found $compiledVersion."
    }
    if (-not [Environment]::Is64BitProcess) {
        throw 'Use 64-bit PowerShell to bundle the x64 Visual C++ runtime.'
    }
    foreach ($runtimeName in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
        $source = Join-Path (Join-Path $env:WINDIR 'System32') $runtimeName
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Visual C++ runtime file is missing: $runtimeName"
        }
        Copy-Item -LiteralPath $source -Destination (Join-Path $releaseDir $runtimeName) -Force
    }
    $unexpectedData = Get-ChildItem -LiteralPath $releaseDir -File -Recurse |
        Where-Object {
            $_.Extension -in @('.db', '.sqlite', '.sqlite3', '.lotusbackup', '.env', '.bak', '.log') -or
            $_.Name -eq 'google-drive.local.json' -or
            $_.FullName -match '[\\/](?:test|DevelopmentBackups|Debug)[\\/]'
        }
    if ($unexpectedData) {
        throw 'Release directory contains business data or development files. Packaging stopped.'
    }

    $scriptPath = Join-Path $PSScriptRoot 'lotus_erp.iss'
    & $compiler "/DAppVersion=$appVersion" $scriptPath
    if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }

    $installer = Join-Path $projectRoot "dist\Lotus-ERP-Setup-$appVersion-x64.exe"
    if (-not (Test-Path -LiteralPath $installer)) {
        throw 'Installer output was not created.'
    }
    $digest = (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash
    $checksumFile = "$installer.sha256"
    Set-Content -LiteralPath $checksumFile -Value "$digest *$(Split-Path -Leaf $installer)" -Encoding Ascii
    $instructions = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'UPDATE-INSTRUCTIONS.txt') -Raw).Replace('{{VERSION}}', $appVersion)
    Set-Content -LiteralPath (Join-Path $projectRoot "dist\Lotus-ERP-Update-$appVersion-Instructions.txt") -Value $instructions -Encoding UTF8
    Write-Output "Installer: $installer"
    Write-Output "SHA256: $digest"
} finally {
    Pop-Location
}
