param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$CodexHome = (Join-Path $env:USERPROFILE '.codex')
)

$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host "[fix-codex] $Message"
}

function Update-SkillFrontmatter {
    param([string]$Path)

    if (!(Test-Path -LiteralPath $Path)) {
        Write-Info "Missing skill template: $Path"
        return
    }

    $content = Get-Content -LiteralPath $Path -Raw
    $content = $content -replace '^name: \{ setup-skill-name \}$', 'name: "{ setup-skill-name }"'
    $content = $content -replace "^description: Sets up \{module-name\} module in a project\. Use when the user requests to 'install \{module-code\} module', 'configure \{module-name\}', or 'setup \{module-name\}'\.$", 'description: "Sets up {module-name} module in a project. Use when the user requests to ''install {module-code} module'', ''configure {module-name}'', or ''setup {module-name}''."'
    Set-Content -LiteralPath $Path -Value $content -Encoding utf8
    Write-Info "Updated skill frontmatter: $Path"
}

function Unlock-Path {
    param([string]$Path)

    if (!(Test-Path -LiteralPath $Path)) {
        return
    }

    $userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

    try {
        & takeown /F $Path | Out-Null
    } catch {
    }

    try {
        & icacls $Path /reset /c | Out-Null
    } catch {
    }

    try {
        & icacls $Path /inheritance:r /grant:r "*$userSid:(F)" /c | Out-Null
    } catch {
    }
}

function Ensure-ProjectCodexConfig {
    $projectCodex = Join-Path $RepoRoot '.codex'
    $placeholder = Join-Path $RepoRoot '.codex.placeholder'
    $configPath = Join-Path $projectCodex 'config.toml'

    if ((Test-Path -LiteralPath $projectCodex) -and -not (Get-Item -LiteralPath $projectCodex).PSIsContainer) {
        Rename-Item -LiteralPath $projectCodex -NewName (Split-Path $placeholder -Leaf) -Force
        Write-Info "Renamed placeholder file to $(Split-Path $placeholder -Leaf)"
    }

    if (!(Test-Path -LiteralPath $projectCodex)) {
        New-Item -ItemType Directory -Path $projectCodex | Out-Null
    }

    @'
approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "live"

[features]
view_image_tool = true
unified_exec = true

[mcp_servers.fetch]
enabled = false
'@ | Set-Content -LiteralPath $configPath -Encoding utf8

    Write-Info "Wrote project config: $configPath"
}

function Update-GlobalCodexConfig {
    $configPath = Join-Path $CodexHome 'config.toml'

    if (!(Test-Path -LiteralPath $configPath)) {
        throw "Global Codex config not found: $configPath"
    }

    $content = Get-Content -LiteralPath $configPath -Raw
    $content = [regex]::Replace($content, '(?m)^\s*web_search_request\s*=\s*true\s*\r?\n?', '')

    if ($content -notmatch '(?m)^\s*web_search\s*=') {
        $content = "web_search = `"live`"`r`n$content"
    }

    $fetchBlockPattern = '(?ms)^\[mcp_servers\.fetch\][\s\S]*?(?=^\[|\z)'
    if ($content -match $fetchBlockPattern) {
        $content = [regex]::Replace(
            $content,
            $fetchBlockPattern,
            "[mcp_servers.fetch]`r`nenabled = false`r`n`r`n"
        )
    } else {
        $content = $content.TrimEnd() + "`r`n`r`n[mcp_servers.fetch]`r`nenabled = false`r`n"
    }

    Set-Content -LiteralPath $configPath -Value $content -Encoding utf8
    Write-Info "Updated global config: $configPath"
}

$agentsSkill = Join-Path $RepoRoot '.agents\skills\bmad-module-builder\assets\setup-skill-template\SKILL.md'
$bmadSkill = Join-Path $RepoRoot '_bmad\bmb\bmad-module-builder\assets\setup-skill-template\SKILL.md'

Unlock-Path -Path $agentsSkill
Update-SkillFrontmatter -Path $agentsSkill
Update-SkillFrontmatter -Path $bmadSkill
Ensure-ProjectCodexConfig
Update-GlobalCodexConfig

Write-Info 'Codex startup fixes applied.'
