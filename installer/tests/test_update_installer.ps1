$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$runId = [Guid]::NewGuid().ToString('N')
$productName = "Lotus ERP Update Test $runId"
$productId = "LotusERP.UpdateTest.$runId"
$testRoot = Join-Path $projectRoot "tmp\installer-$runId"
$payload = Join-Path $testRoot 'payload'
$output = Join-Path $testRoot 'packages'
$installDir = Join-Path $testRoot 'installed'
$dataParent = Join-Path $env:LOCALAPPDATA $productName
$settingsParent = Join-Path $env:APPDATA $productName
$dataDir = Join-Path $dataParent 'Data'
$settingsDir = Join-Path $settingsParent $productName
$backupRoot = Join-Path $dataParent 'Backups'
$compiler = Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'
$scriptPath = Join-Path $projectRoot 'installer\lotus_erp.iss'

function Invoke-Package([string]$Version) {
    Set-Content -LiteralPath (Join-Path $payload 'lotus_erp.exe') -Value "fixture-$Version"
    & $compiler '/Q' "/DAppVersion=$Version" "/DProductName=$productName" "/DProductId=$productId" "/DReleaseDir=$payload" "/DInstallerOutputDir=$output" $scriptPath
    if ($LASTEXITCODE -ne 0) { throw 'Fixture setup compilation failed.' }
    return (Join-Path $output "Lotus-ERP-Setup-$Version-x64.exe")
}

function Invoke-Setup([string]$File, [string]$LogName, [bool]$SpecifyDirectory, [string]$Directory = $installDir) {
    $arguments = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOICONS', "/LOG=`"$(Join-Path $testRoot $LogName)`"")
    if ($SpecifyDirectory) { $arguments += "/DIR=`"$Directory`"" }
    $process = Start-Process -FilePath $File -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru
    return $process.ExitCode
}

function Assert-Condition([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Remove-TestTree([string]$Directory, [string]$Expected) {
    $resolved = [IO.Path]::GetFullPath($Directory)
    if ($resolved -ne [IO.Path]::GetFullPath($Expected) -or -not $resolved.Contains($runId)) {
        throw 'Refusing to remove a path outside the isolated test namespace.'
    }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}

New-Item -ItemType Directory -Path (Join-Path $payload 'data'), $output -Force | Out-Null
Set-Content -LiteralPath (Join-Path $payload 'flutter_windows.dll') -Value 'fixture DLL'
Set-Content -LiteralPath (Join-Path $payload 'data\icudtl.dat') -Value 'fixture assets'
$guardWindow = $null
try {
    $oldSetup = Invoke-Package '1.0.1'
    Assert-Condition ((Invoke-Setup $oldSetup 'initial.log' $true) -eq 0) 'Initial test install failed.'
    New-Item -ItemType Directory -Path (Join-Path $dataDir 'attachments'), (Join-Path $dataDir 'empty-folder'), $settingsDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dataDir 'business.sqlite') -Value 'synthetic database fixture'
    Set-Content -LiteralPath (Join-Path $dataDir 'attachments\invoice.pdf') -Value 'synthetic invoice fixture'
    Set-Content -LiteralPath (Join-Path $settingsDir 'preferences.json') -Value '{"fixture":true}'
    $dataHash = (Get-FileHash -LiteralPath (Join-Path $dataDir 'business.sqlite')).Hash
    $settingsHash = (Get-FileHash -LiteralPath (Join-Path $settingsDir 'preferences.json')).Hash
    $newSetup = Invoke-Package '1.0.2'

    Set-Content -LiteralPath $backupRoot -Value 'block backup directory creation'
    Assert-Condition ((Invoke-Setup $newSetup 'blocked-backup.log' $false) -ne 0) 'Setup continued after backup failure.'
    Assert-Condition ((Get-Content -LiteralPath (Join-Path $installDir 'lotus_erp.exe') -Raw).Trim() -eq 'fixture-1.0.1') 'Backup failure replaced the old application.'
    Remove-Item -LiteralPath $backupRoot

    Assert-Condition ((Invoke-Setup $newSetup 'blocked-data-folder.log' $true $dataParent) -ne 0) 'Setup accepted a program folder containing business data.'
    $lockedData = [IO.File]::Open((Join-Path $dataDir 'business.sqlite'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        Assert-Condition ((Invoke-Setup $newSetup 'blocked-locked-data.log' $false) -ne 0) 'Setup continued after a data file could not be copied.'
    } finally { $lockedData.Dispose() }

    Add-Type -AssemblyName System.Windows.Forms
    $guardWindow = New-Object System.Windows.Forms.Form
    $guardWindow.Text = $productName
    $null = $guardWindow.Handle
    Assert-Condition ((Invoke-Setup $newSetup 'blocked-running.log' $false) -ne 0) 'Setup continued while the app window was open.'
    Assert-Condition ((Get-Content -LiteralPath (Join-Path $installDir 'lotus_erp.exe') -Raw).Trim() -eq 'fixture-1.0.1') 'Open-app guard replaced the old application.'
    $guardWindow.Dispose()
    $guardWindow = $null

    # No /DIR: the update must recover the previous install location itself.
    Assert-Condition ((Invoke-Setup $newSetup 'updated.log' $false) -eq 0) 'Test update failed.'
    Assert-Condition ((Get-Content -LiteralPath (Join-Path $installDir 'lotus_erp.exe') -Raw).Trim() -eq 'fixture-1.0.2') 'The existing installation was not updated.'
    $completed = @(Get-ChildItem -LiteralPath $backupRoot -Filter 'backup-complete.txt' -File -Recurse)
    Assert-Condition ($completed.Count -eq 1) 'A verified backup completion record is missing.'
    $backup = $completed[0].DirectoryName
    Assert-Condition ((Get-FileHash -LiteralPath (Join-Path $backup 'Data\business.sqlite')).Hash -eq $dataHash) 'Database backup differs.'
    Assert-Condition ((Get-FileHash -LiteralPath (Join-Path $backup 'Settings\preferences.json')).Hash -eq $settingsHash) 'Settings backup differs.'
    Assert-Condition ((Get-FileHash -LiteralPath (Join-Path $dataDir 'business.sqlite')).Hash -eq $dataHash) 'Original data changed.'
    Assert-Condition ((Get-FileHash -LiteralPath (Join-Path $settingsDir 'preferences.json')).Hash -eq $settingsHash) 'Original settings changed.'
    Assert-Condition ((Get-Content -LiteralPath (Join-Path $backup 'Data\attachments\invoice.pdf') -Raw).Trim() -eq 'synthetic invoice fixture') 'Nested attachments were not backed up.'
    Assert-Condition (Test-Path -LiteralPath (Join-Path $backup 'Data\empty-folder')) 'Empty data folders were not preserved.'
    Write-Output 'PASS: failed/locked backups and unsafe install folders are blocked; running app is blocked; update reuses the install folder; data/settings/attachments verified; original data unchanged.'
} finally {
    if ($null -ne $guardWindow) { $guardWindow.Dispose() }
    $uninstaller = Join-Path $installDir 'unins000.exe'
    if (Test-Path -LiteralPath $uninstaller) {
        $cleanup = Start-Process -FilePath $uninstaller -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -WindowStyle Hidden -Wait -PassThru
        if ($cleanup.ExitCode -ne 0) { throw 'Isolated test uninstall failed.' }
    }
    Remove-TestTree $dataParent (Join-Path $env:LOCALAPPDATA $productName)
    Remove-TestTree $settingsParent (Join-Path $env:APPDATA $productName)
}
