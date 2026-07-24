[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$ExpectedVersion = '1.1.1',
    [string]$PackagePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tocPath = Join-Path $projectRoot 'RPWatcher.toc'
$errors = New-Object 'System.Collections.Generic.List[string]'
$runtimeIconPath = 'Media/RPWatcherIcon.tga'
$expectedIconTexture = 'Interface\AddOns\RPWatcher\Media\RPWatcherIcon'
$projectAssetFiles = @(
    'release/assets/RPWatcherIcon_1024.png',
    'release/assets/RPWatcherIcon_512.png',
    'release/assets/RPWatcherIcon_64_preview.png'
)

$packageAllowlist = @(
    'RPWatcher.toc',
    'Core.lua',
    'Performance.lua',
    'Theme.lua',
    'Settings.lua',
    'UI.lua',
    'Minimap.lua',
    'Scanner.lua',
    'TRP3.lua',
    $runtimeIconPath,
    'LICENSE',
    'README.md',
    'CHANGELOG.md',
    'USER_GUIDE.md',
    'PRIVACY.md',
    'SUPPORT.md',
    'THIRD_PARTY_NOTICES.md'
)

$expectedProjectFiles = $packageAllowlist + $projectAssetFiles + @(
    '.gitignore',
    'AGENTS.md',
    'PERFORMANCE_AUDIT.md',
    'release/PROJECT_DESCRIPTION_DE.md',
    'release/PROJECT_DESCRIPTION_EN.md',
    'release/SHORT_DESCRIPTIONS.md',
    'release/SCREENSHOT_PLAN.md',
    'release/RELEASE_NOTES_0.9.0.md',
    'release/TEST_MATRIX_0.9.0.md',
    'release/RELEASE_NOTES_1.0.0.md',
    'release/TEST_MATRIX_1.0.0.md',
    'release/RELEASE_NOTES_1.1.0.md',
    'release/TEST_MATRIX_1.1.0.md',
    'release/RELEASE_NOTES_1.1.1.md',
    'release/TEST_MATRIX_1.1.1.md',
    'release/PUBLISHING.md',
    '.github/ISSUE_TEMPLATE/bug_report.yml',
    '.github/ISSUE_TEMPLATE/feature_request.yml',
    '.github/ISSUE_TEMPLATE/config.yml',
    'tools/Validate-Release.ps1',
    'tools/Build-Release.ps1'
)

function Add-ValidationError {
    param([string]$Message)
    $errors.Add($Message)
}

function Get-TocValue {
    param(
        [string[]]$Lines,
        [string]$Key
    )

    $pattern = '^##\s+' + [regex]::Escape($Key) + ':\s*(.*?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1]
        }
    }
    return $null
}

if ((Split-Path -Leaf $projectRoot) -cne 'RPWatcher') {
    Add-ValidationError "Der Projektordner muss exakt 'RPWatcher' heißen: $projectRoot"
}

foreach ($relativePath in $expectedProjectFiles) {
    $fullPath = Join-Path $projectRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-ValidationError "Erwartete Projektdatei fehlt: $relativePath"
    }
}

if (Test-Path -LiteralPath $tocPath -PathType Leaf) {
    $tocLines = @(Get-Content -LiteralPath $tocPath -Encoding UTF8)
    $tocVersion = Get-TocValue -Lines $tocLines -Key 'Version'
    $interfaceVersion = Get-TocValue -Lines $tocLines -Key 'Interface'
    $title = Get-TocValue -Lines $tocLines -Key 'Title'
    $author = Get-TocValue -Lines $tocLines -Key 'Author'
    $license = Get-TocValue -Lines $tocLines -Key 'X-License'
    $optionalDependencies = Get-TocValue -Lines $tocLines -Key 'OptionalDeps'
    $savedVariables = Get-TocValue -Lines $tocLines -Key 'SavedVariables'
    $iconTexture = Get-TocValue -Lines $tocLines -Key 'IconTexture'

    if ([string]::IsNullOrWhiteSpace($tocVersion)) {
        Add-ValidationError 'Die TOC enthält keine Version.'
    } elseif ($tocVersion -cne $ExpectedVersion) {
        Add-ValidationError "TOC-Version '$tocVersion' entspricht nicht '$ExpectedVersion'."
    }
    if ([string]::IsNullOrWhiteSpace($interfaceVersion) -or $interfaceVersion -notmatch '^\d+$') {
        Add-ValidationError "Die Interface-Nummer ist nicht numerisch: '$interfaceVersion'."
    }
    if ($title -cne 'RPWatcher') {
        Add-ValidationError "Unerwarteter TOC-Titel: '$title'."
    }
    if ($author -cne 'Mercia') {
        Add-ValidationError "Unerwarteter TOC-Autor: '$author'."
    }
    if ($license -cne 'MIT') {
        Add-ValidationError "Unerwartete TOC-Lizenz: '$license'."
    }
    if ($optionalDependencies -cne 'totalRP3') {
        Add-ValidationError "Total RP 3 muss optionale Abhängigkeit bleiben: '$optionalDependencies'."
    }
    if ($savedVariables -cne 'RPWatcherDB') {
        Add-ValidationError "Unerwartete SavedVariables-Datenbank: '$savedVariables'."
    }
    if ($iconTexture -cne $expectedIconTexture) {
        Add-ValidationError "Unerwarteter IconTexture-Pfad: '$iconTexture'. Erwartet: '$expectedIconTexture'."
    }

    $tocLuaFiles = @(
        $tocLines |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '\.lua$' -and -not $_.StartsWith('##') }
    )
    if ($tocLuaFiles.Count -eq 0) {
        Add-ValidationError 'Die TOC enthält keine Lua-Dateien.'
    }
    foreach ($luaFile in $tocLuaFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $luaFile) -PathType Leaf)) {
            Add-ValidationError "TOC-Datei fehlt: $luaFile"
        }
        if ($packageAllowlist -notcontains $luaFile) {
            Add-ValidationError "TOC-Datei fehlt in der Paket-Allowlist: $luaFile"
        }
    }

    foreach ($line in $tocLines) {
        if ($line -match '^##\s+X-(Wago-ID|Curse-Project-ID):\s*(.*?)\s*$') {
            $platformValue = $Matches[2]
            if ([string]::IsNullOrWhiteSpace($platformValue) -or $platformValue -match '(?i)TODO|PLACEHOLDER|CHANGEME|<.+>') {
                Add-ValidationError "Leere oder erfundene Plattform-ID in der TOC: $line"
            }
        }
    }
}

$runtimeIconFullPath = Join-Path $projectRoot ($runtimeIconPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $runtimeIconFullPath -PathType Leaf) {
    $iconBytes = [System.IO.File]::ReadAllBytes($runtimeIconFullPath)
    if ($iconBytes.Length -lt 18) {
        Add-ValidationError 'Das Runtime-Icon ist zu klein für einen gültigen TGA-Header.'
    } else {
        $imageType = $iconBytes[2]
        $width = [BitConverter]::ToUInt16($iconBytes, 12)
        $height = [BitConverter]::ToUInt16($iconBytes, 14)
        $pixelDepth = $iconBytes[16]
        $isPowerOfTwo = $width -gt 0 -and $height -gt 0 -and
            (($width -band ($width - 1)) -eq 0) -and (($height -band ($height - 1)) -eq 0)

        if ($imageType -notin @(2, 10)) {
            Add-ValidationError "Das Runtime-Icon verwendet keinen unterstützten True-Color-TGA-Typ: $imageType."
        }
        if ($width -ne 256 -or $height -ne 256) {
            Add-ValidationError "Das Runtime-Icon muss 256 x 256 Pixel groß sein: $width x $height."
        }
        if (-not $isPowerOfTwo) {
            Add-ValidationError "Das Runtime-Icon besitzt keine Potenz-von-zwei-Auflösung: $width x $height."
        }
        if ($pixelDepth -notin @(24, 32)) {
            Add-ValidationError "Das Runtime-Icon besitzt eine unerwartete Farbtiefe: $pixelDepth Bit."
        }
        if ($iconBytes.Length -le (18 + $iconBytes[0])) {
            Add-ValidationError 'Das Runtime-Icon enthält keine Bilddaten.'
        }
    }
}

$expectedProjectAssetSizes = @{
    'release/assets/RPWatcherIcon_1024.png' = 1024
    'release/assets/RPWatcherIcon_512.png' = 512
    'release/assets/RPWatcherIcon_64_preview.png' = 64
}
foreach ($assetPath in $projectAssetFiles) {
    $assetFullPath = Join-Path $projectRoot ($assetPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $assetFullPath -PathType Leaf)) {
        continue
    }
    $assetBytes = [System.IO.File]::ReadAllBytes($assetFullPath)
    $pngSignature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
    $signatureValid = $assetBytes.Length -ge 24
    if ($signatureValid) {
        for ($index = 0; $index -lt $pngSignature.Length; $index++) {
            if ($assetBytes[$index] -ne $pngSignature[$index]) {
                $signatureValid = $false
                break
            }
        }
    }
    if (-not $signatureValid) {
        Add-ValidationError "Projektgrafik ist keine gültige PNG-Datei: $assetPath"
        continue
    }
    $width = [BitConverter]::ToUInt32([byte[]]@($assetBytes[19], $assetBytes[18], $assetBytes[17], $assetBytes[16]), 0)
    $height = [BitConverter]::ToUInt32([byte[]]@($assetBytes[23], $assetBytes[22], $assetBytes[21], $assetBytes[20]), 0)
    $expectedSize = $expectedProjectAssetSizes[$assetPath]
    if ($width -ne $expectedSize -or $height -ne $expectedSize) {
        Add-ValidationError "Unerwartete Abmessungen der Projektgrafik $assetPath`: $width x $height."
    }
}

$licensePath = Join-Path $projectRoot 'LICENSE'
if (Test-Path -LiteralPath $licensePath -PathType Leaf) {
    $licenseText = Get-Content -LiteralPath $licensePath -Raw -Encoding UTF8
    if ($licenseText -notmatch '(?m)^MIT License\s*$') {
        Add-ValidationError 'LICENSE enthält keinen vollständigen MIT-Kopf.'
    }
    if ($licenseText -notmatch [regex]::Escape('Copyright (c) 2026 Mercia')) {
        Add-ValidationError 'LICENSE enthält nicht den erwarteten Copyright-Hinweis.'
    }
    if ($licenseText -notmatch [regex]::Escape('Permission is hereby granted, free of charge')) {
        Add-ValidationError 'LICENSE enthält nicht den kanonischen MIT-Erlaubnistext.'
    }
}

$forbiddenPackageEntries = @(
    '.git', '.github', '.agents', '.gitignore', 'AGENTS.md', 'PERFORMANCE_AUDIT.md',
    'tools', 'release', 'dist', 'release-output'
)
foreach ($entry in $packageAllowlist) {
    $topLevel = ($entry -split '[/\\]')[0]
    if ($forbiddenPackageEntries -contains $entry -or $forbiddenPackageEntries -contains $topLevel) {
        Add-ValidationError "Entwicklungsdatei steht in der Paket-Allowlist: $entry"
    }
    if ($entry -match '(?i)\.(zip|log|tmp|bak|wsv)$') {
        Add-ValidationError "Unzulässige Laufzeitdatei steht in der Paket-Allowlist: $entry"
    }
}

$allowlistedImages = @($packageAllowlist | Where-Object { $_ -match '(?i)\.(tga|png|jpg|jpeg|gif|webp|blp)$' })
if ($allowlistedImages.Count -ne 1 -or $allowlistedImages[0] -cne $runtimeIconPath) {
    Add-ValidationError "Die Paket-Allowlist muss genau das Runtime-Icon enthalten: $($allowlistedImages -join ', ')"
}
foreach ($projectAsset in $projectAssetFiles) {
    if ($packageAllowlist -contains $projectAsset) {
        Add-ValidationError "Projektgrafik darf nicht in der Runtime-Allowlist stehen: $projectAsset"
    }
}

$nestedAddonPath = Join-Path $projectRoot 'RPWatcher'
if (Test-Path -LiteralPath $nestedAddonPath -PathType Container) {
    Add-ValidationError "Unzulässige Doppelverschachtelung gefunden: $nestedAddonPath"
}

$runtimeJunk = Get-ChildItem -LiteralPath $projectRoot -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '(?i)\.(zip|log|tmp)$' -or
    $_.Name -match '(?i)^RPWatcher\.lua(\.bak)?$' -or
    $_.Name -match '(?i)SavedVariables'
}
foreach ($file in $runtimeJunk) {
    Add-ValidationError "Unzulässige Runtime-/SavedVariables-Datei im Projektstamm: $($file.Name)"
}

$excludedRoots = @('.git', '.agents', 'dist', 'release-output') | ForEach-Object {
    [System.IO.Path]::GetFullPath((Join-Path $projectRoot $_)).TrimEnd('\') + '\'
}
$unexpectedBinaryExtensions = @('.exe', '.dll', '.bin', '.dat', '.tga', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.mp3', '.ogg', '.ttf', '.zip')
$allowedBinaryFiles = @($runtimeIconPath) + $projectAssetFiles
$credentialPatterns = @(
    'AKIA[0-9A-Z]{16}',
    'gh[pousr]_[A-Za-z0-9]{20,}',
    '-----BEGIN (RSA|OPENSSH|EC) PRIVATE KEY-----',
    '(?i)api[_-]?key\s*[:=]\s*["''][^"'']+["'']',
    '(?i)(access[_-]?token|client[_-]?secret)\s*[:=]\s*["''][^"'']+["'']'
)

$textExtensions = @('.lua', '.toc', '.md', '.ps1', '.yml', '.yaml', '.txt', '.gitignore', '')
foreach ($file in Get-ChildItem -LiteralPath $projectRoot -Recurse -File -Force) {
    $fullPath = [System.IO.Path]::GetFullPath($file.FullName)
    $relativeFilePath = $fullPath.Substring($projectRoot.Length + 1).Replace('\', '/')
    $excluded = $false
    foreach ($excludedRoot in $excludedRoots) {
        if ($fullPath.StartsWith($excludedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $excluded = $true
            break
        }
    }
    if ($excluded) {
        continue
    }

    if ($unexpectedBinaryExtensions -contains $file.Extension.ToLowerInvariant()) {
        if ($allowedBinaryFiles -notcontains $relativeFilePath) {
            Add-ValidationError "Unerwartete Binär-/Archivdatei im Projekt: $relativeFilePath"
        }
        continue
    }

    if ($textExtensions -contains $file.Extension.ToLowerInvariant() -or $file.Name -eq 'LICENSE') {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        foreach ($pattern in $credentialPatterns) {
            if ($content -match $pattern) {
                Add-ValidationError "Mögliches Zugangsdatenmuster in: $($file.FullName.Substring($projectRoot.Length + 1))"
                break
            }
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($PackagePath)) {
    $resolvedPackagePath = if ([System.IO.Path]::IsPathRooted($PackagePath)) {
        [System.IO.Path]::GetFullPath($PackagePath)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $projectRoot $PackagePath))
    }

    if (-not (Test-Path -LiteralPath $resolvedPackagePath -PathType Leaf)) {
        Add-ValidationError "Zu prüfendes ZIP fehlt: $resolvedPackagePath"
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedPackagePath)
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
            Add-ValidationError "ZIP-Inhalt weicht von der Allowlist ab: $differenceText"
        }

        $rootNames = @($actualFiles | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique)
        if ($rootNames.Count -ne 1 -or $rootNames[0] -cne 'RPWatcher') {
            Add-ValidationError "ZIP besitzt nicht exakt den Wurzelordner RPWatcher: $($rootNames -join ', ')"
        }
        if ($actualFiles | Where-Object { $_ -match '^RPWatcher/RPWatcher/' }) {
            Add-ValidationError 'ZIP enthält die unzulässige Doppelverschachtelung RPWatcher/RPWatcher.'
        }

        $zipImages = @($actualFiles | Where-Object { $_ -match '(?i)\.(tga|png|jpg|jpeg|gif|webp|blp)$' })
        if ($zipImages.Count -ne 1 -or $zipImages[0] -cne 'RPWatcher/Media/RPWatcherIcon.tga') {
            Add-ValidationError "ZIP muss genau das Runtime-Icon enthalten: $($zipImages -join ', ')"
        }
        if ($actualFiles -notcontains 'RPWatcher/RPWatcher.toc') {
            Add-ValidationError 'RPWatcher.toc liegt nicht direkt im ZIP-Wurzelordner RPWatcher.'
        }
        if ($actualFiles | Where-Object { $_ -match '^RPWatcher/release/assets/' -or $_ -match '(?i)\.png$' }) {
            Add-ValidationError 'ZIP enthält unzulässige Projekt-PNGs oder release/assets-Dateien.'
        }
    }
}

$luaCompiler = Get-Command 'luac' -ErrorAction SilentlyContinue
if ($luaCompiler -and (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
    foreach ($luaFile in $tocLuaFiles) {
        & $luaCompiler.Source -p (Join-Path $projectRoot $luaFile)
        if ($LASTEXITCODE -ne 0) {
            Add-ValidationError "Lua-Syntaxprüfung fehlgeschlagen: $luaFile"
        }
    }
    Write-Host '[INFO] Lua-Syntaxprüfung mit lokalem luac ausgeführt.'
} else {
    Write-Host '[INFO] Kein lokaler Lua-Compiler gefunden; Lua-Syntaxprüfung übersprungen.'
}

if ($errors.Count -gt 0) {
    Write-Host "[FAIL] Release-Validierung mit $($errors.Count) Fehler(n):" -ForegroundColor Red
    foreach ($validationError in $errors) {
        Write-Host "  - $validationError" -ForegroundColor Red
    }
    throw 'Release-Validierung fehlgeschlagen.'
}

Write-Host "[PASS] RPWatcher $ExpectedVersion wurde erfolgreich validiert." -ForegroundColor Green
Write-Host "[PASS] Paket-Allowlist enthält $($packageAllowlist.Count) Dateien."
