<#
.SYNOPSIS
  Sync selected Windows workflow artifacts to the WORKSTATION1 workflow backup SMB share.

.DESCRIPTION
  Intended to be launched from WSL by scripts/workflow-backup.sh. Uses robocopy.exe
  for Windows-owned paths instead of copying large Windows trees through DrvFS.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\\\\[^\\]+\\[^\\]+')]
    [string]$NasRoot,

    [string]$DestinationSubdir = 'current\windows',

    [string]$LocalManifestCopy,

    [switch]$DryRun,

    [switch]$VerboseLog
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function New-Directory([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Write-JsonFile([string]$Path, [object]$Value) {
    $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Add-Result([System.Collections.ArrayList]$Results, [object]$Value) {
    [void]$Results.Add($Value)
}

if (-not (Get-Command robocopy.exe -ErrorAction SilentlyContinue)) {
    throw 'Required command not found: robocopy.exe'
}
if (-not (Test-Path -LiteralPath $NasRoot)) {
    throw "NAS SMB root is not reachable: $NasRoot"
}

$profile = $env:USERPROFILE
$profileName = Split-Path -Leaf $profile
$localAppData = $env:LOCALAPPDATA
$appData = $env:APPDATA
$backupRoot = Join-Path $NasRoot $DestinationSubdir
$logDir = Join-Path $backupRoot '_logs'
$manifestDir = Join-Path $backupRoot '_manifests'
New-Directory $backupRoot
New-Directory $logDir
New-Directory $manifestDir

$started = Get-Date
$results = New-Object System.Collections.ArrayList
$roboLog = Join-Path $logDir ('robocopy-windows-critical-' + $started.ToString('yyyyMMdd-HHmmss') + '.log')

$directoryItems = @(
    @{ Name = 'Desktop'; Path = (Join-Path $profile 'Desktop'); Dest = "Users\$profileName\Desktop"; Required = $true },
    @{ Name = 'Documents'; Path = (Join-Path $profile 'Documents'); Dest = "Users\$profileName\Documents"; Required = $true },
    @{ Name = 'Downloads'; Path = (Join-Path $profile 'Downloads'); Dest = "Users\$profileName\Downloads"; Required = $true },
    @{ Name = 'WindowsUserSsh'; Path = (Join-Path $profile '.ssh'); Dest = "Users\$profileName\.ssh"; Required = $false },
    @{ Name = 'WindowsTerminalLocalState'; Path = (Join-Path $localAppData 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'); Dest = "Users\$profileName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"; Required = $false },
    @{ Name = 'VSCodeUser'; Path = (Join-Path $appData 'Code\User'); Dest = "Users\$profileName\AppData\Roaming\Code\User"; Required = $false },
    @{ Name = 'PowerShellProfile'; Path = (Join-Path $profile 'Documents\PowerShell'); Dest = "Users\$profileName\Documents\PowerShell"; Required = $false },
    @{ Name = 'WindowsPowerShellProfile'; Path = (Join-Path $profile 'Documents\WindowsPowerShell'); Dest = "Users\$profileName\Documents\WindowsPowerShell"; Required = $false },
    @{ Name = 'StartupFolder'; Path = (Join-Path $appData 'Microsoft\Windows\Start Menu\Programs\Startup'); Dest = "Users\$profileName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"; Required = $false }
)

$fileItems = @(
    @{ Name = 'WslConfig'; Path = (Join-Path $profile '.wslconfig'); Dest = "Users\$profileName\.wslconfig"; Required = $false },
    @{ Name = 'ChromeBookmarks'; Path = (Join-Path $localAppData 'Google\Chrome\User Data\Default\Bookmarks'); Dest = "Users\$profileName\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"; Required = $false },
    @{ Name = 'ChromePreferences'; Path = (Join-Path $localAppData 'Google\Chrome\User Data\Default\Preferences'); Dest = "Users\$profileName\AppData\Local\Google\Chrome\User Data\Default\Preferences"; Required = $false },
    @{ Name = 'ChromeSecurePreferences'; Path = (Join-Path $localAppData 'Google\Chrome\User Data\Default\Secure Preferences'); Dest = "Users\$profileName\AppData\Local\Google\Chrome\User Data\Default\Secure Preferences"; Required = $false }
)

$excludeDirs = @(
    '.git', '.hg', '.svn',
    'node_modules', '.venv', 'venv', '__pycache__', '.pytest_cache', '.mypy_cache', '.ruff_cache',
    '.cache', 'Cache', 'Code Cache', 'GPUCache', 'DawnGraphiteCache', 'GrShaderCache', 'ShaderCache',
    'AppData\Local\Temp', 'AppData\Local\Microsoft\Windows\INetCache', 'AppData\Local\Microsoft\Windows\WebCache'
)
$excludeFiles = @('*.tmp', 'thumbcache_*.db', 'IconCache.db')

foreach ($item in $directoryItems) {
    $src = [string]$item.Path
    $dest = Join-Path $backupRoot ([string]$item.Dest)
    if (-not (Test-Path -LiteralPath $src)) {
        if ([bool]$item.Required) { throw "Required Windows backup path is missing: $src" }
        Add-Result $results ([ordered]@{ name = $item.Name; kind = 'dir'; source = $src; destination = $dest; status = 'missing_optional' })
        continue
    }
    New-Directory $dest
    $args = @(
        $src, $dest,
        '/MIR', '/XJ', '/COPY:DAT', '/DCOPY:DAT', '/R:1', '/W:2', '/FFT', '/Z', '/XA:O', '/MT:8',
        '/NP', '/NFL', '/NDL', '/XD'
    ) + $excludeDirs + @('/XF') + $excludeFiles + @("/LOG+:$roboLog")
    if ($DryRun) { $args += '/L' }
    & robocopy.exe @args | Out-Null
    $code = $LASTEXITCODE
    $status = if ($code -lt 8) { 'ok' } else { 'failed' }
    Add-Result $results ([ordered]@{ name = $item.Name; kind = 'dir'; source = $src; destination = $dest; robocopy_exit_code = $code; status = $status })
    if ($code -ge 8) { throw "robocopy failed for $src with exit code $code. See $roboLog" }
}

foreach ($item in $fileItems) {
    $src = [string]$item.Path
    $destRel = [string]$item.Dest
    $destDirRel = Split-Path -Parent $destRel
    $destDir = Join-Path $backupRoot $destDirRel
    $fileName = Split-Path -Leaf $src
    if (-not (Test-Path -LiteralPath $src)) {
        if ([bool]$item.Required) { throw "Required Windows backup file is missing: $src" }
        Add-Result $results ([ordered]@{ name = $item.Name; kind = 'file'; source = $src; destination = (Join-Path $destDir $fileName); status = 'missing_optional' })
        continue
    }
    New-Directory $destDir
    $parent = Split-Path -Parent $src
    $args = @(
        $parent, $destDir, $fileName,
        '/COPY:DAT', '/R:1', '/W:2', '/FFT', '/Z', '/XA:O', '/NP', '/NFL', '/NDL', "/LOG+:$roboLog"
    )
    if ($DryRun) { $args += '/L' }
    & robocopy.exe @args | Out-Null
    $code = $LASTEXITCODE
    $status = if ($code -lt 8) { 'ok' } else { 'failed' }
    Add-Result $results ([ordered]@{ name = $item.Name; kind = 'file'; source = $src; destination = (Join-Path $destDir $fileName); robocopy_exit_code = $code; status = $status })
    if ($code -ge 8) { throw "robocopy failed for $src with exit code $code. See $roboLog" }
}

$finished = Get-Date
$manifest = [ordered]@{
    kind = 'windows-critical-workflow-sync'
    started_at = $started.ToString('o')
    finished_at = $finished.ToString('o')
    duration_seconds = [math]::Round(($finished - $started).TotalSeconds, 3)
    computer = $env:COMPUTERNAME
    user = $env:USERNAME
    user_profile = $profile
    nas_root = $NasRoot
    destination = $backupRoot
    dry_run = [bool]$DryRun
    robocopy_log = $roboLog
    results = $results
}
$nasManifest = Join-Path $manifestDir 'windows-sync-finish.json'
Write-JsonFile -Path $nasManifest -Value $manifest
if ($LocalManifestCopy) {
    $localManifestDir = Split-Path -Parent $LocalManifestCopy
    if ($localManifestDir) { New-Directory $localManifestDir }
    Write-JsonFile -Path $LocalManifestCopy -Value $manifest
}

if ($VerboseLog) {
    Write-Host "Windows critical sync completed. Manifest: $nasManifest"
    if ($LocalManifestCopy) { Write-Host "Local manifest copy: $LocalManifestCopy" }
}
