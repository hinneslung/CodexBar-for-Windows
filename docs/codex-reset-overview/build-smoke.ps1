# Builds the real Windows app with a fixture-only entry point; does not change production sources.
$ErrorActionPreference = 'Stop'
$repoDirectory = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$qaDirectory = Join-Path $env:TEMP 'CodexBar/qa/reset-overview'
New-Item -ItemType Directory -Path $qaDirectory -Force | Out-Null
$appBinaryDirectory = (swift build --product CodexBar --show-bin-path).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Could not resolve SwiftPM output.' }
$accessor = Join-Path $appBinaryDirectory 'CodexBarWindows.build/DerivedSources/resource_bundle_accessor.swift'
if (-not (Test-Path -LiteralPath $accessor)) { throw 'Build CodexBar with SwiftPM first.' }
$sourceFiles = Get-ChildItem -LiteralPath (Join-Path $repoDirectory 'Sources/CodexBarWindows') -Filter '*.swift' |
    Where-Object Name -ne 'WindowsMain.swift' | ForEach-Object FullName
$smokeExecutable = Join-Path $qaDirectory 'CodexBarResetSmoke.exe'
& swiftc -parse-as-library -module-name CodexBarWindows -swift-version 6 -warnings-as-errors `
    -enable-upcoming-feature StrictConcurrency @sourceFiles $accessor `
    (Join-Path $PSScriptRoot 'SmokeMain.swift') -o $smokeExecutable `
    -Xlinker /SUBSYSTEM:WINDOWS -Xlinker /ENTRY:mainCRTStartup -ldwmapi -luxtheme
if ($LASTEXITCODE -ne 0) { throw 'Offline smoke fixture build failed.' }
Copy-Item -LiteralPath (Join-Path $appBinaryDirectory 'CodexBar_CodexBarWindows.resources') `
    -Destination $qaDirectory -Recurse -Force
# launch_app runs in the interactive desktop daemon; put Swift DLLs beside the fixture executable.
$runtimeInfo = swiftc -print-target-info | ConvertFrom-Json
foreach ($runtimePath in $runtimeInfo.paths.runtimeLibraryPaths) {
    if (Test-Path -LiteralPath $runtimePath) {
        Get-ChildItem -LiteralPath $runtimePath -Filter '*.dll' |
            Copy-Item -Destination $qaDirectory -Force
    }
}
Write-Output $smokeExecutable
