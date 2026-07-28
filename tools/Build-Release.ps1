[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$ExpectedVersion,
    [switch]$RequireCleanGit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tocPath = Join-Path $projectRoot 'RPWatcher.toc'
$validatorPath = Join-Path $PSScriptRoot 'Validate-Release.ps1'
$distPath = Join-Path $projectRoot 'dist'

$packageAllowlist = @(
    'RPWatcher.toc',
    'Locale/enUS.lua',
    'Locale/deDE.lua',
    'Localization.lua',
    'Core.lua',
    'Performance.lua',
    'Theme.lua',
    'Settings.lua',
    'UI.lua',
    'Minimap.lua',
    'Scanner.lua',
    'TRP3.lua',
    'Media/RPWatcherIcon.tga',
    'LICENSE',
    'README.md',
    'CHANGELOG.md',
    'USER_GUIDE.md',
    'PRIVACY.md',
    'SUPPORT.md',
    'THIRD_PARTY_NOTICES.md'
)

if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
    throw "TOC nicht gefunden: $tocPath"
}

$tocLines = @(Get-Content -LiteralPath $tocPath -Encoding UTF8)
$versionLine = $tocLines | Where-Object { $_ -match '^##\s+Version:\s*(.*?)\s*$' } | Select-Object -First 1
if (-not $versionLine -or $versionLine -notmatch '^##\s+Version:\s*(.*?)\s*$') {
    throw 'Version konnte nicht aus RPWatcher.toc gelesen werden.'
}
$version = $Matches[1]
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Ungültige TOC-Version: $version"
}
if ($ExpectedVersion -and $version -cne $ExpectedVersion) {
    throw "TOC-Version '$version' entspricht nicht der erwarteten Version '$ExpectedVersion'."
}

& $validatorPath -ExpectedVersion $version
if (-not $?) {
    throw 'Release-Validierung fehlgeschlagen.'
}

$gitCommand = Get-Command 'git' -ErrorAction SilentlyContinue
$sourceCommit = 'nicht verfügbar'
$sourceTreeState = 'nicht geprüft'
if ($gitCommand) {
    $gitStatus = @(& $gitCommand.Source -c "safe.directory=$projectRoot" -c 'core.excludesFile=' -C $projectRoot status --porcelain 2>$null)
    if ($LASTEXITCODE -eq 0) {
        $sourceTreeState = if ($gitStatus.Count -eq 0) { 'clean' } else { 'dirty' }
        if ($RequireCleanGit -and $gitStatus.Count -ne 0) {
            throw 'Der Git-Arbeitsbaum ist nicht sauber; Build mit -RequireCleanGit abgebrochen.'
        }
        $commitOutput = @(& $gitCommand.Source -c "safe.directory=$projectRoot" -c 'core.excludesFile=' -C $projectRoot rev-parse HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and $commitOutput.Count -gt 0) {
            $sourceCommit = $commitOutput[0].Trim()
        }
    } elseif ($RequireCleanGit) {
        throw 'Git-Status konnte für den verpflichtend sauberen Build nicht geprüft werden.'
    }
} elseif ($RequireCleanGit) {
    throw 'Git ist nicht verfügbar; sauberer Commitstand kann nicht bestätigt werden.'
}

if (-not (Test-Path -LiteralPath $distPath -PathType Container)) {
    New-Item -ItemType Directory -Path $distPath | Out-Null
}

$zipName = "RPWatcher-$version.zip"
$hashName = "RPWatcher-$version.sha256"
$manifestName = "RPWatcher-$version-manifest.txt"
$zipPath = Join-Path $distPath $zipName
$hashPath = Join-Path $distPath $hashName
$manifestPath = Join-Path $distPath $manifestName

foreach ($outputPath in @($zipPath, $hashPath, $manifestPath)) {
    $resolvedParent = [System.IO.Path]::GetFullPath((Split-Path -Parent $outputPath))
    if ($resolvedParent -cne [System.IO.Path]::GetFullPath($distPath)) {
        throw "Unsicherer Ausgabepfad: $outputPath"
    }
    if (Test-Path -LiteralPath $outputPath -PathType Leaf) {
        Remove-Item -LiteralPath $outputPath -Force
    }
}

$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\')
$tempPath = Join-Path $tempBase ("RPWatcher-release-" + [guid]::NewGuid().ToString('N'))
$stagingRoot = Join-Path $tempPath 'RPWatcher'
$fixedTimestamp = [datetime]::SpecifyKind([datetime]'2000-01-01T00:00:00', [DateTimeKind]::Utc)

try {
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

    foreach ($relativePath in $packageAllowlist) {
        $sourcePath = Join-Path $projectRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Allowlist-Datei fehlt beim Build: $relativePath"
        }
        $destinationPath = Join-Path $stagingRoot $relativePath
        $destinationDirectory = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        }
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
        (Get-Item -LiteralPath $destinationPath).LastWriteTimeUtc = $fixedTimestamp
    }

    Compress-Archive -LiteralPath $stagingRoot -DestinationPath $zipPath -CompressionLevel Optimal

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $actualFiles = @(
            $archive.Entries |
                ForEach-Object { $_.FullName.Replace('\', '/') } |
                Where-Object { -not $_.EndsWith('/') } |
                Sort-Object
        )
    } finally {
        $archive.Dispose()
    }

    $expectedFiles = @($packageAllowlist | ForEach-Object { "RPWatcher/$($_ -replace '\\', '/')" } | Sort-Object)
    $differences = @(Compare-Object -ReferenceObject $expectedFiles -DifferenceObject $actualFiles)
    if ($differences.Count -gt 0) {
        $differenceText = ($differences | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }) -join '; '
        throw "ZIP-Inhalt weicht von der Allowlist ab: $differenceText"
    }

    $rootNames = @($actualFiles | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique)
    if ($rootNames.Count -ne 1 -or $rootNames[0] -cne 'RPWatcher') {
        throw "ZIP besitzt nicht exakt den Wurzelordner RPWatcher: $($rootNames -join ', ')"
    }
    if ($actualFiles | Where-Object { $_ -match '^RPWatcher/RPWatcher/' }) {
        throw 'ZIP enthält die unzulässige Doppelverschachtelung RPWatcher/RPWatcher.'
    }

    & $validatorPath -ExpectedVersion $version -PackagePath $zipPath
    if (-not $?) {
        throw 'Release-ZIP-Validierung fehlgeschlagen.'
    }

    $zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $zipSize = (Get-Item -LiteralPath $zipPath).Length
    Set-Content -LiteralPath $hashPath -Value "$zipHash  $zipName" -Encoding ASCII

    $manifestLines = New-Object 'System.Collections.Generic.List[string]'
    $manifestLines.Add('RPWatcher Release Manifest')
    $manifestLines.Add("Version: $version")
    $manifestLines.Add("Source commit: $sourceCommit")
    $manifestLines.Add("Source tree: $sourceTreeState")
    $manifestLines.Add("Package: $zipName")
    $manifestLines.Add("ZIP bytes: $zipSize")
    $manifestLines.Add("ZIP SHA-256: $zipHash")
    $manifestLines.Add('Root folder: RPWatcher')
    $manifestLines.Add("File count: $($packageAllowlist.Count)")
    $manifestLines.Add('Files:')
    foreach ($relativePath in $packageAllowlist) {
        $stagedPath = Join-Path $stagingRoot $relativePath
        $fileSize = (Get-Item -LiteralPath $stagedPath).Length
        $fileHash = (Get-FileHash -LiteralPath $stagedPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $manifestLines.Add("- RPWatcher/$relativePath | $fileSize bytes | SHA-256 $fileHash")
    }
    Set-Content -LiteralPath $manifestPath -Value $manifestLines -Encoding UTF8

    Write-Host "[PASS] Release erstellt: $zipPath" -ForegroundColor Green
    Write-Host "[PASS] ZIP-Inhalt: $($actualFiles.Count) Dateien in genau einem Wurzelordner RPWatcher."
    Write-Host "[PASS] Dateigröße: $zipSize Bytes"
    Write-Host "[PASS] SHA-256: $zipHash"
    Write-Host "[PASS] Manifest: $manifestPath"
} finally {
    $resolvedTempPath = [System.IO.Path]::GetFullPath($tempPath)
    $safePrefix = $tempBase + '\RPWatcher-release-'
    if ($resolvedTempPath.StartsWith($safePrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTempPath).StartsWith('RPWatcher-release-', [System.StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolvedTempPath -PathType Container)) {
        Remove-Item -LiteralPath $resolvedTempPath -Recurse -Force
    }
}
