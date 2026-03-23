# agents

Shared Cursor rules, commands, skills, and docs distributed as standalone git repos.

## Repository Structure

```
agents/
├── commands/   # UserGeneratedLLC/agent-commands
├── skills/     # UserGeneratedLLC/agent-skills
├── rules/      # UserGeneratedLLC/agent-rules
└── docs/       # UserGeneratedLLC/agent-docs
```

## Install

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/UserGeneratedLLC/agents/master/install.sh | bash
```

Windows (PowerShell):

```powershell
iex "& { $(irm https://raw.githubusercontent.com/UserGeneratedLLC/agents/master/install.ps1) }"
```

Repos are cloned to `~/.cursor/{rules,skills,docs,commands}/usergenerated` and updated hourly via cron (Linux/macOS) or scheduled task (Windows). Run the update script manually any time:

```bash
~/.cursor/update-usergenerated.sh
```

```powershell
~/.cursor/update-usergenerated.ps1
```

## Uninstall

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/UserGeneratedLLC/agents/master/install.sh | bash -s -- uninstall
```

Windows (PowerShell):

```powershell
iex "& { $(irm https://raw.githubusercontent.com/UserGeneratedLLC/agents/master/install.ps1) } -Action uninstall"
```

## Guidelines for Changes

Every file here is consumed across multiple projects. Keep rules, commands, and skills general-purpose, prefer additive changes, and use clear naming.

## Submodule Workflow

Each subdirectory is an independent git submodule. Commit inside the submodule first, then update the parent:

```bash
git submodule update --remote --merge --recursive
git add <submodule-dir>
git commit -m "update <submodule> to latest"
```
