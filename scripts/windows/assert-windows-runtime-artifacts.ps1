param(
  [string]$ReleaseDir = "build/windows/x64/runner/Release",
  [string]$ExecutableName = "movi.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ReleaseDir -PathType Container)) {
  throw "Missing release directory: $ReleaseDir. Run 'flutter build windows --release' first."
}

$exePath = Join-Path $ReleaseDir $ExecutableName
if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
  throw "Missing executable: $exePath."
}

$requiredDlls = @(
  "vcruntime140.dll",
  "vcruntime140_1.dll",
  "msvcp140.dll"
)

foreach ($dll in $requiredDlls) {
  $dllPath = Join-Path $ReleaseDir $dll
  if (-not (Test-Path -LiteralPath $dllPath -PathType Leaf)) {
    throw "Missing required app-local VC++ runtime DLL: $dllPath."
  }
}

$vcruntimeMatches = Get-ChildItem -LiteralPath $ReleaseDir -Filter "vcruntime*.dll" -File | Select-Object -ExpandProperty Name
$msvcpMatches = Get-ChildItem -LiteralPath $ReleaseDir -Filter "msvcp*.dll" -File | Select-Object -ExpandProperty Name

if ($vcruntimeMatches.Count -eq 0) {
  throw "No runtime DLL matching pattern 'vcruntime*.dll' found in $ReleaseDir."
}

if ($msvcpMatches.Count -eq 0) {
  throw "No runtime DLL matching pattern 'msvcp*.dll' found in $ReleaseDir."
}

Write-Host "Windows runtime artifacts check passed."
Write-Host "Executable: $ExecutableName"
Write-Host "vcruntime DLLs: $($vcruntimeMatches -join ', ')"
Write-Host "msvcp DLLs: $($msvcpMatches -join ', ')"
