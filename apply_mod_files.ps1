param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [switch]$DryRun,
    [switch]$CreateBackup,

    [string[]]$ExcludeRelativePaths = @(
        'apply_mod_files.ps1',
        '.DS_Store',
        'Thumbs.db'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolved = Resolve-Path -LiteralPath $Path
    return [System.IO.Path]::GetFullPath($resolved.Path)
}

function Test-IsExcluded {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string[]]$ExcludedPaths
    )

    $normalized = $RelativePath.Replace('\\', '/').TrimStart('./')
    foreach ($excluded in $ExcludedPaths) {
        $candidate = $excluded.Replace('\\', '/').TrimStart('./')
        if ($normalized -eq $candidate) {
            return $true
        }
    }

    return $false
}

function Get-FileHashSafe {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$modsRoot = [System.IO.Path]::GetFullPath((Get-Location).Path)
$targetRoot = Resolve-NormalizedPath -Path $ProjectPath

if (-not (Test-Path -LiteralPath $targetRoot -PathType Container)) {
    throw "Le dossier projet n'existe pas : $ProjectPath"
}

$backupRoot = $null
if ($CreateBackup) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupRoot = Join-Path -Path $modsRoot -ChildPath ".backup-before-apply-$timestamp"
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

$filesToCopy = Get-ChildItem -LiteralPath $modsRoot -Recurse -File | Where-Object {
    $relativePath = [System.IO.Path]::GetRelativePath($modsRoot, $_.FullName)
    -not (Test-IsExcluded -RelativePath $relativePath -ExcludedPaths $ExcludeRelativePaths)
}

if (-not $filesToCopy -or $filesToCopy.Count -eq 0) {
    Write-Host 'Aucun fichier de modification à copier.'
    exit 0
}

$copiedCount = 0
$skippedCount = 0
$createdCount = 0
$updatedCount = 0

Write-Host "Dossier des modifications : $modsRoot"
Write-Host "Dossier projet cible     : $targetRoot"
if ($DryRun) {
    Write-Host 'Mode simulation activé   : aucune écriture ne sera effectuée.'
}
if ($CreateBackup) {
    Write-Host "Sauvegarde locale        : $backupRoot"
}
Write-Host ''

foreach ($sourceFile in $filesToCopy) {
    $relativePath = [System.IO.Path]::GetRelativePath($modsRoot, $sourceFile.FullName)
    $destinationFile = Join-Path -Path $targetRoot -ChildPath $relativePath
    $destinationDir = Split-Path -Path $destinationFile -Parent

    $sourceHash = Get-FileHashSafe -Path $sourceFile.FullName
    $destinationHash = Get-FileHashSafe -Path $destinationFile

    $action = if ($null -eq $destinationHash) { 'CREATE' } elseif ($sourceHash -ne $destinationHash) { 'UPDATE' } else { 'SKIP' }

    switch ($action) {
        'SKIP' {
            Write-Host "[SKIP]   $relativePath"
            $skippedCount++
            continue
        }
        'CREATE' {
            Write-Host "[CREATE] $relativePath"
            $createdCount++
        }
        'UPDATE' {
            Write-Host "[UPDATE] $relativePath"
            $updatedCount++
        }
    }

    if ($DryRun) {
        continue
    }

    if (-not (Test-Path -LiteralPath $destinationDir -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    if ($CreateBackup -and (Test-Path -LiteralPath $destinationFile -PathType Leaf)) {
        $backupFile = Join-Path -Path $backupRoot -ChildPath $relativePath
        $backupDir = Split-Path -Path $backupFile -Parent
        if (-not (Test-Path -LiteralPath $backupDir -PathType Container)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $destinationFile -Destination $backupFile -Force
    }

    Copy-Item -LiteralPath $sourceFile.FullName -Destination $destinationFile -Force
    $copiedCount++
}

Write-Host ''
Write-Host 'Résumé'
Write-Host "- Fichiers créés   : $createdCount"
Write-Host "- Fichiers mis à jour : $updatedCount"
Write-Host "- Fichiers ignorés : $skippedCount"
Write-Host "- Fichiers copiés  : $copiedCount"

if ($DryRun) {
    Write-Host ''
    Write-Host 'Simulation terminée. Aucune modification n’a été écrite.'
}
