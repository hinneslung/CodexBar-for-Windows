$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Exercise the production state transitions without touching installers, user data or tasks.
$source = Join-Path $PSScriptRoot 'test_windows_installer.ps1'
$tokens = $null
$parseErrors = $null
$tree = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Lifecycle script does not parse.' }
foreach ($name in @('Resolve-RegisteredUninstaller', 'Install-Payload', 'Uninstall-Payload')) {
    $definition = $tree.Find({ param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }, $true)
    if ($null -eq $definition) { throw "Missing production function: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}
$Installer = 'synthetic-setup.exe'
$work = 'synthetic-work'
$installDirectory = 'C:\synthetic\installed'
$registryPath = 'synthetic-uninstall-key'
$installCount = 0
$uninstallCount = 0
$DiagnosticsDirectory = 'synthetic-diagnostics'
$payloadInstalled = $false
$failProcess = $false
$registeredUninstallString = $null
$registrationPresent = $true
$existingFiles = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$invokedPaths = [Collections.Generic.List[string]]::new()
$key = [pscustomobject]@{}
$key | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
    param($name)
    if ($name -eq 'UninstallString') { return $script:registeredUninstallString }
}
$key | Add-Member -MemberType ScriptMethod -Name Dispose -Value {}
$registry = [pscustomobject]@{}
$registry | Add-Member -MemberType ScriptMethod -Name OpenSubKey -Value {
    param($path)
    if ($path -ne $script:registryPath -or -not $script:registrationPresent) { return $null }
    return $script:key
}
function Write-LifecycleStage([string] $Name) {}
function Test-Path {
    param([string] $LiteralPath, [string] $PathType)
    $PathType -eq 'Leaf' -and $existingFiles.Contains([IO.Path]::GetFullPath($LiteralPath))
}
function Invoke-InstallerProcess([string] $Path, [string[]] $Arguments) {
    if ($failProcess) { throw 'Synthetic process failure' }
    $invokedPaths.Add($Path)
}
$stale = Join-Path $installDirectory 'unins000.exe'
$current = Join-Path $installDirectory 'unins001.exe'
$existingFiles.Add($stale) | Out-Null
$existingFiles.Add($current) | Out-Null
$registeredUninstallString = "`"$current`""
Uninstall-Payload
if ($invokedPaths[-1] -ine $current) { throw 'Registered unins001 was not used while stale unins000 existed.' }
$changed = Join-Path $installDirectory 'unins002.exe'
$existingFiles.Add($changed) | Out-Null
$registeredUninstallString = "`"$changed`""
$payloadInstalled = $true
Uninstall-Payload
if ($invokedPaths[-1] -ine $changed) { throw 'Changed uninstall registration was not resolved freshly.' }
foreach ($case in @(
    @{ Value = "`"C:\outside\unins003.exe`""; Present = $true; Existing = 'C:\outside\unins003.exe' },
    @{ Value = "`"$current`" /SILENT"; Present = $true; Existing = $current },
    @{ Value = $null; Present = $true; Existing = $null },
    @{ Value = "`"$current`""; Present = $false; Existing = $current },
    @{ Value = "`"$(Join-Path $installDirectory 'setup.exe')`""; Present = $true;
        Existing = (Join-Path $installDirectory 'setup.exe') },
    @{ Value = "`"$(Join-Path $installDirectory 'unins004.exe')`""; Present = $true; Existing = $null }
)) {
    $registeredUninstallString = $case.Value
    $registrationPresent = $case.Present
    if ($case.Existing) { $existingFiles.Add($case.Existing) | Out-Null }
    $rejected = $false
    try { Resolve-RegisteredUninstaller } catch { $rejected = $true }
    if (-not $rejected) { throw 'Unsafe or malformed uninstall registration was accepted.' }
}
$registrationPresent = $true
$registeredUninstallString = "`"$current`""
$installCount = 0
$uninstallCount = 0
Install-Payload
if (-not $payloadInstalled) { throw 'Successful setup must retain cleanup responsibility.' }
Uninstall-Payload
if ($payloadInstalled) { throw 'Successful uninstall must prevent duplicate cleanup.' }
$failProcess = $true
try { Install-Payload } catch { if ($_.Exception.Message -ne 'Synthetic process failure') { throw } }
if (-not $payloadInstalled) { throw 'Failed setup must retain partial-install cleanup responsibility.' }
try { Uninstall-Payload } catch { if ($_.Exception.Message -ne 'Synthetic process failure') { throw } }
if (-not $payloadInstalled) { throw 'Failed uninstall must retain cleanup responsibility.' }
$failProcess = $false
Uninstall-Payload
if ($payloadInstalled) { throw 'Successful cleanup retry must clear responsibility.' }
Write-Host 'Installer cleanup and registered-uninstaller tests passed.'
