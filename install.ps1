param(
    [ValidateSet("install", "uninstall")]
    [string]$Action = "install"
)

$ErrorActionPreference = "Stop"

$AgentsDir     = Join-Path $HOME ".agents"
$UpdateScript  = Join-Path $AgentsDir "update-usergenerated.ps1"
$TaskName      = "UserGeneratedAgentsUpdate"

$Repos = @(
    @{ Name = "rules";    Url = "https://github.com/UserGeneratedLLC/agent-rules.git" }
    @{ Name = "skills";   Url = "https://github.com/UserGeneratedLLC/agent-skills.git" }
    @{ Name = "docs";     Url = "https://github.com/UserGeneratedLLC/agent-docs.git" }
    @{ Name = "commands"; Url = "https://github.com/UserGeneratedLLC/agent-commands.git" }
)

function Install {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is required but not installed."
        return
    }

    New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null

    foreach ($repo in $Repos) {
        $dest = Join-Path $AgentsDir $repo.Name "usergenerated"

        if (Test-Path (Join-Path $dest ".git")) {
            Write-Host "Updating $($repo.Name)..."
            git -C $dest pull --ff-only 2>$null
            if ($LASTEXITCODE -ne 0) { Write-Host "  Warning: pull failed for $($repo.Name), skipping" }
        } else {
            Write-Host "Cloning $($repo.Name)..."
            $parent = Split-Path $dest -Parent
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            git clone --quiet $repo.Url $dest
        }
    }

    $scriptContent = @'
$ErrorActionPreference = "SilentlyContinue"
$dirs = @(
    "$HOME\.agents\rules\usergenerated"
    "$HOME\.agents\skills\usergenerated"
    "$HOME\.agents\docs\usergenerated"
    "$HOME\.agents\commands\usergenerated"
)
foreach ($dir in $dirs) {
    if (Test-Path (Join-Path $dir ".git")) {
        git -C $dir pull --ff-only 2>$null
    }
}
'@
    Set-Content -Path $UpdateScript -Value $scriptContent -Encoding UTF8
    Write-Host "Created update script at $UpdateScript"

    $existing = schtasks /query /tn $TaskName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Scheduled task already exists."
    } else {
        $pwsh = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
        schtasks /create /tn $TaskName /sc hourly /tr "$pwsh -NoProfile -ExecutionPolicy Bypass -File `"$UpdateScript`"" /f | Out-Null
        Write-Host "Added hourly scheduled task."
    }

    Write-Host "Installed to $AgentsDir"
}

function Uninstall {
    foreach ($repo in $Repos) {
        $dest = Join-Path $AgentsDir $repo.Name "usergenerated"
        if (Test-Path $dest) {
            Write-Host "Removing $dest..."
            Remove-Item -Recurse -Force $dest
        }
        $parent = Join-Path $AgentsDir $repo.Name
        if ((Test-Path $parent) -and -not (Get-ChildItem $parent)) {
            Remove-Item $parent
        }
    }

    if (Test-Path $UpdateScript) { Remove-Item -Force $UpdateScript }

    schtasks /delete /tn $TaskName /f 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "Removed scheduled task." }

    if ((Test-Path $AgentsDir) -and -not (Get-ChildItem $AgentsDir)) {
        Remove-Item $AgentsDir
    }

    Write-Host "Uninstalled."
}

if ($Action -eq "uninstall") { Uninstall } else { Install }
