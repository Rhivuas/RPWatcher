[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$ExpectedVersion = '0.9.0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tocPath = Join-Path $projectRoot 'RPWatcher.toc'
$errors = New-Object 'System.Collections.Generic.List[string]'

$packageAllowlist = @(
    'RPWatcher.toc',
    'Core.lua',
    'Performance.lua',
    'Theme.lua',
    'Settings.lua',
    'UI.lua',
    'Scanner.lua',
    'TRP3.lua',
    'LICENSE',
    'README.md',
    'CHANGELOG.md',
    'USER_GUIDE.md',
    'PRIVACY.md',
    'SUPPORT.md',
    'THIRD_PARTY_NOTICES.md'
)

$expectedProjectFiles = $packageAllowlist + @(
    '.gitignore',
    'AGENTS.md',
    'PERFORMANCE_AUDIT.md',
    'release/PROJECT_DESCRIPTION_DE.md',
    'release/PROJECT_DESCRIPTION_EN.md',
    'release/SHORT_DESCRIPTIONS.md',
    'release/SCREENSHOT_PLAN.md',
    'release/RELEASE_NOTES_0.9.0.md',
    'release/TEST_MATRIX_0.9.0.md',
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
$unexpectedBinaryExtensions = @('.exe', '.dll', '.bin', '.dat', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.mp3', '.ogg', '.ttf', '.zip')
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
        Add-ValidationError "Unerwartete Binär-/Archivdatei im Projekt: $($file.FullName.Substring($projectRoot.Length + 1))"
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
