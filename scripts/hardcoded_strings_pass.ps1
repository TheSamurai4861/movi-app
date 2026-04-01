param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$OutDir = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "output"),
  # Par defaut: rapide et utile (code applicatif). Mettre "lib" pour une passe vraiment globale.
  [ValidateSet("lib/src","lib")]
  [string]$Scope = "lib/src"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $OutDir)) {
  New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$tsvPath = Join-Path $OutDir "hardcoded_strings_full.tsv"
$mdPath = Join-Path $OutDir "hardcoded_strings_full.md"

function Resolve-RgPath {
  $cmd = Get-Command "rg" -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $wingetLink = Join-Path $env:LOCALAPPDATA "Microsoft\\WinGet\\Links\\rg.exe"
  if (Test-Path $wingetLink) { return $wingetLink }

  return $null
}

$rgPath = Resolve-RgPath
if (-not $rgPath) {
  throw "Commande introuvable: rg. Elle est installee via winget mais ton PATH n'est probablement pas recharge. Redemarre ton terminal, ou utilise: $env:LOCALAPPDATA\\Microsoft\\WinGet\\Links\\rg.exe"
}

Push-Location $RepoRoot
try {
  # Capture toutes les string literals simples et doubles sur une seule ligne.
  # Note: cette passe est volontairement exhaustive (il y aura des faux-positifs: routes, keys, regex, etc.).
  # Pattern volontairement "fast" (pas 100% exact sur les quotes echappees),
  # sinon la regex "escape-aware" peut devenir tres lente sur gros codebase.
  $pattern = '(?:''[^''\r\n]*''|"[^"\r\n]*")'

  $args = @(
    "--no-heading",
    "--line-number",
    "--color", "never",
    "--only-matching",
    "--glob", "*.dart",
    "--glob", "!lib/l10n/**",
    "--glob", "!**/*.g.dart",
    "--glob", "!**/*.freezed.dart",
    "--glob", "!**/*.gr.dart",
    "--glob", "!**/generated/**",
    $pattern,
    $Scope
  )

  # IMPORTANT perf: streaming -> ecrit TSV au fil de l'eau (pas de gros buffer).
  $fileCounts = @{}
  $total = 0

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $writer = New-Object System.IO.StreamWriter($tsvPath, $false, $utf8NoBom)
  try {
    & $rgPath @args | ForEach-Object {
      # rg output: path:line:match
      $l = $_
      $first = $l.IndexOf(":")
      $second = $l.IndexOf(":", $first + 1)
      if ($first -lt 0 -or $second -lt 0) { return }

      $path = $l.Substring(0, $first)
      $line = $l.Substring($first + 1, $second - $first - 1)
      $match = $l.Substring($second + 1).Trim()

      $writer.WriteLine("$path`t$line`t$match")
      $total++

      if ($fileCounts.ContainsKey($path)) { $fileCounts[$path]++ } else { $fileCounts[$path] = 1 }
    }
  }
  finally {
    $writer.Dispose()
  }

  $top = $fileCounts.GetEnumerator() |
    Sort-Object Value -Descending |
    Select-Object -First 40

  $md = @()
  $md += "# Passe exhaustive - string literals ($Scope/**)"
  $md += ""
  $md += 'Fichiers exclus: lib/l10n/**, **/*.g.dart, **/*.freezed.dart, **/*.gr.dart, **/generated/**.'
  $md += ""
  $md += "- Total occurrences (matches): **$total**"
  $md += '- Export brut (TSV): output/hardcoded_strings_full.tsv'
  $md += ""
  $md += "## Top fichiers (par nombre de lignes matchées)"
  $md += ""
  $md += "| Fichier | Occurrences |"
  $md += "|---|---:|"
  foreach ($g in $top) {
    $md += "| $($g.Key) | $($g.Value) |"
  }
  $md += ""
  $md += "## Notes"
  $md += ""
  $md += "- Cette passe est **exhaustive**: elle inclut des faux-positifs (URLs, cles, route names, regex, tokens, etc.)."
  $md += "- Etape suivante typique: filtrer sur les strings reellement **affichees a l'utilisateur** (widgets, dialogs, snackbars), puis generer les cles `.arb`."

  $md | Set-Content -Encoding UTF8 $mdPath
}
finally {
  Pop-Location
}

Write-Host "OK:"
Write-Host " - $tsvPath"
Write-Host " - $mdPath"
