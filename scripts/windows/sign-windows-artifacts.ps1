param(
  [string]$ReleaseDir = "build/windows/x64/runner/Release",
  [string]$ExecutableName = "movi.exe",
  [string]$SetupPattern = "build/inno/Movi-Setup-*.exe",
  [Parameter(Mandatory = $true)]
  [string]$CertificatePath,
  [Parameter(Mandatory = $true)]
  [string]$CertificatePassword,
  [string[]]$TimestampUrls = @(
    "http://timestamp.digicert.com",
    "http://timestamp.sectigo.com"
  ),
  [string]$ArtifactVersion = ""
)

$ErrorActionPreference = "Stop"

function Assert-PathExists {
  param(
    [string]$TargetPath,
    [string]$Label
  )
  if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
    throw "Missing ${Label}: $TargetPath."
  }
}

function Invoke-SignWithTimestampFallback {
  param(
    [string]$FilePath
  )

  foreach ($timestampUrl in $TimestampUrls) {
    Write-Host "Signing '$FilePath' with timestamp server '$timestampUrl'..."
    & signtool sign `
      /fd SHA256 `
      /f $CertificatePath `
      /p $CertificatePassword `
      /td SHA256 `
      /tr $timestampUrl `
      /v `
      $FilePath
    if ($LASTEXITCODE -eq 0) {
      return
    }
    Write-Warning "Signing failed for '$FilePath' with '$timestampUrl'. Trying next timestamp server."
  }

  throw "Failed to sign '$FilePath' with all configured timestamp servers."
}

function Write-SignatureReport {
  param(
    [string]$FilePath
  )

  $signature = Get-AuthenticodeSignature -FilePath $FilePath
  if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
    throw "Authenticode signature is not valid for '$FilePath'. Status: $($signature.Status)."
  }

  $fileHash = Get-FileHash -Algorithm SHA256 -Path $FilePath
  $signer = $signature.SignerCertificate
  $timeStamper = $signature.TimeStamperCertificate
  $timestampState = if ($null -ne $timeStamper) { "present" } else { "missing" }

  Write-Host "----- Signature report: $FilePath -----"
  Write-Host "Version: $ArtifactVersion"
  Write-Host "Signer subject: $($signer.Subject)"
  Write-Host "Signer thumbprint (SHA1): $($signer.Thumbprint)"
  Write-Host "Signer cert hash (SHA256): $([System.Convert]::ToHexString($signer.GetCertHash('SHA256')))"
  Write-Host "Timestamp: $timestampState"
  if ($null -ne $timeStamper) {
    Write-Host "Timestamp signer: $($timeStamper.Subject)"
  }
  Write-Host "File hash (SHA256): $($fileHash.Hash)"
}

if (-not (Get-Command signtool -ErrorAction SilentlyContinue)) {
  throw "signtool is not available on PATH."
}

Assert-PathExists -TargetPath $CertificatePath -Label "certificate"

$moviExePath = Join-Path $ReleaseDir $ExecutableName
Assert-PathExists -TargetPath $moviExePath -Label "application executable"

$setupCandidates = @(Get-ChildItem -Path $SetupPattern -File | Sort-Object LastWriteTimeUtc -Descending)
if ($setupCandidates.Count -eq 0) {
  throw "No setup executable found for pattern '$SetupPattern'."
}

$setupPath = $setupCandidates[0].FullName
Write-Host "Selected setup artifact: $setupPath"

$filesToSign = @($moviExePath, $setupPath)

foreach ($filePath in $filesToSign) {
  Invoke-SignWithTimestampFallback -FilePath $filePath
  & signtool verify /pa /all /v $filePath
  if ($LASTEXITCODE -ne 0) {
    throw "signtool verify failed for '$filePath'."
  }
  Write-SignatureReport -FilePath $filePath
}
