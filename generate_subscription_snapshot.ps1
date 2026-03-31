param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$OutputFile = "subscription_target_snapshot.md"
)

$ErrorActionPreference = "Stop"

$targetFiles = @(
  "lib/src/features/settings/presentation/pages/settings_page.dart",
  "lib/src/features/library/presentation/pages/library_page.dart",
  "lib/src/core/router/app_routes.dart",
  "lib/src/core/router/app_router.dart",
  "lib/src/features/auth/presentation/auth_otp_page.dart",
  "lib/src/features/home/presentation/widgets/home_continue_watching_section.dart",
  "lib/src/features/person/presentation/pages/person_detail_page.dart",
  "lib/src/features/saga/presentation/pages/saga_detail_page.dart",
  "lib/src/core/profile/presentation/ui/dialogs/create_profile_dialog.dart",
  "lib/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart",
  "lib/src/core/parental/presentation/providers/parental_providers.dart",
  "lib/src/core/parental/presentation/providers/parental_access_providers.dart"
)

function Get-NormalizedFullPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BasePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  return [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine($BasePath, $RelativePath)
  )
}

function Get-FileSnapshotBlock {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $absolutePath = Get-NormalizedFullPath -BasePath $ProjectRoot -RelativePath $RelativePath

  if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    return @"
## $RelativePath

- Absolute path: $absolutePath
- Status: MISSING

~~~text
[File not found]
~~~

"@
  }

  $fileItem = Get-Item -LiteralPath $absolutePath
  $content = Get-Content -LiteralPath $absolutePath -Raw -Encoding UTF8

  return @"
## $RelativePath

- Absolute path: $absolutePath
- Size: $($fileItem.Length) bytes

~~~text
$content
~~~

"@
}

$resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

$resolvedOutputFile = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
  $OutputFile
} else {
  [System.IO.Path]::Combine($resolvedProjectRoot, $OutputFile)
}

$header = @"
# Subscription target snapshot

Root analyzed: $resolvedProjectRoot

## Requested files

~~~text
$($targetFiles -join "`r`n")
~~~

## File snapshots

"@

$blocks = foreach ($relativePath in $targetFiles) {
  Get-FileSnapshotBlock -ProjectRoot $resolvedProjectRoot -RelativePath $relativePath
}

$finalContent = $header + ($blocks -join "`r`n")

$parentDir = Split-Path -Path $resolvedOutputFile -Parent
if (
  -not [string]::IsNullOrWhiteSpace($parentDir) -and
  -not (Test-Path -LiteralPath $parentDir)
) {
  New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

Set-Content -LiteralPath $resolvedOutputFile -Value $finalContent -Encoding UTF8

Write-Host ""
Write-Host "Snapshot generated: $resolvedOutputFile"
Write-Host ""

Get-Content -LiteralPath $resolvedOutputFile -Raw -Encoding UTF8
