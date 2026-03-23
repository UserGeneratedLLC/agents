param(
    [ValidateSet("install", "uninstall")]
    [string]$Action = "install"
)

$ErrorActionPreference = "Stop"

$AgentsDir     = Join-Path $HOME ".cursor"
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

        try {
            if (Test-Path (Join-Path $dest ".git")) {
                Write-Host "Updating $($repo.Name)..."
                $ErrorActionPreference = "Continue"
                git -C $dest fetch --depth 1 2>$null
                if ($LASTEXITCODE -eq 0) { git -C $dest reset --hard origin/HEAD 2>$null }
                $ErrorActionPreference = "Stop"
                if ($LASTEXITCODE -ne 0) { Write-Host "  Warning: pull failed for $($repo.Name), skipping" }
            } else {
                if (Test-Path $dest) {
                    Write-Host "Repairing $($repo.Name) (removing incomplete clone)..."
                    Remove-Item -Recurse -Force $dest
                }
                Write-Host "Cloning $($repo.Name)..."
                $parent = Split-Path $dest -Parent
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                $ErrorActionPreference = "Continue"
                git clone --quiet --depth 1 $repo.Url $dest
                $ErrorActionPreference = "Stop"
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  Warning: clone failed for $($repo.Name), skipping"
                    continue
                }
            }
        } catch {
            $ErrorActionPreference = "Stop"
            Write-Host "  Warning: failed to process $($repo.Name): $_"
            continue
        }
    }

    $scriptContent = @'
$ErrorActionPreference = "SilentlyContinue"
$dirs = @(
    "$HOME\.cursor\rules\usergenerated"
    "$HOME\.cursor\skills\usergenerated"
    "$HOME\.cursor\docs\usergenerated"
    "$HOME\.cursor\commands\usergenerated"
)
foreach ($dir in $dirs) {
    if (Test-Path (Join-Path $dir ".git")) {
        git -C $dir fetch --depth 1 2>$null
        if ($LASTEXITCODE -eq 0) { git -C $dir reset --hard origin/HEAD 2>$null }
    }
}
'@
    Set-Content -Path $UpdateScript -Value $scriptContent -Encoding UTF8
    Write-Host "Created update script at $UpdateScript"

    $pwsh = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
    $ErrorActionPreference = "Continue"
    schtasks /create /tn $TaskName /sc hourly /tr "$pwsh -NoProfile -ExecutionPolicy Bypass -File `"$UpdateScript`"" /f 2>$null | Out-Null
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installed hourly scheduled task."
    } else {
        Write-Host "Warning: failed to create scheduled task."
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
        try {
            if ((Test-Path $parent) -and -not (Get-ChildItem -Force $parent)) {
                Remove-Item -Force $parent
            }
        } catch { }
    }

    if (Test-Path $UpdateScript) { Remove-Item -Force $UpdateScript }

    $ErrorActionPreference = "Continue"
    schtasks /delete /tn $TaskName /f 2>$null | Out-Null
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -eq 0) { Write-Host "Removed scheduled task." }

    try {
        if ((Test-Path $AgentsDir) -and -not (Get-ChildItem -Force $AgentsDir)) {
            Remove-Item -Force $AgentsDir
        }
    } catch { }

    Write-Host "Uninstalled."
}

if ($Action -eq "uninstall") { Uninstall } else { Install }
