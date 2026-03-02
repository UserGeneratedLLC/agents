# AGENTS.md

This repository manages shared Cursor project files (rules, commands, skills, docs) that are distributed across multiple projects via Git submodules.

## Repository Structure

```
agents/                  # This repo (parent)
├── commands/            # Submodule: UserGeneratedLLC/agent-commands
├── skills/              # Submodule: UserGeneratedLLC/agent-skills
├── rules/               # Submodule: UserGeneratedLLC/agent-rules
└── docs/                # Submodule: UserGeneratedLLC/agent-docs
```

Each directory is an independent Git submodule with its own repository.

## How This Is Used in Consumer Projects

Each submodule is cloned into a consumer project under `.cursor/` as a `shared` subdirectory:

```
my-project/
├── .cursor/
│   ├── rules/
│   │   ├── shared/      ← submodule: agent-rules
│   │   └── my-rule.mdc  ← project-specific
│   ├── commands/
│   │   ├── shared/      ← submodule: agent-commands
│   │   └── my-cmd.md    ← project-specific
│   ├── skills/
│   │   ├── shared/      ← submodule: agent-skills
│   │   └── my-skill/    ← project-specific
│   └── docs/
│       └── shared/      ← submodule: agent-docs
└── ...
```

This lets users maintain their own project-specific rules, commands, skills, and docs alongside the shared versions, while pulling updates to the shared set independently.

### Adding to a Project

Run these from the root of the consumer project. Add all four or pick only the ones you need:

```bash
git submodule add https://github.com/UserGeneratedLLC/agent-rules.git .cursor/rules/shared
git submodule add https://github.com/UserGeneratedLLC/agent-commands.git .cursor/commands/shared
git submodule add https://github.com/UserGeneratedLLC/agent-skills.git .cursor/skills/shared
git submodule add https://github.com/UserGeneratedLLC/agent-docs.git .cursor/docs/shared
# git config submodule.recurse true
```

After cloning a project that already has these submodules, initialize them with:

```bash
git submodule update --init --recursive
```

### Updating to the Latest Versions

To pull the latest versions of all shared rules, commands, skills, and docs:

```bash
git submodule update --remote --merge --recursive
```

The following are optional convenience setups to automate this:

**Auto-sync pinned commits on pull** -- run once per project to have `git pull`, `git checkout`, and `git switch` automatically update submodules to the commit your project has pinned:

```bash
git config submodule.recurse true
```

**Auto-pull latest from upstream on pull** -- install a post-merge hook that fetches the newest shared content after every pull, even if your project hasn't pinned a newer commit yet:

Bash:

```bash
printf '#!/bin/sh\ngit submodule update --remote --merge --recursive\n' > .git/hooks/post-merge && chmod +x .git/hooks/post-merge
```

PowerShell:

```powershell
Set-Content -Path .git/hooks/post-merge -Value "#!/bin/sh`ngit submodule update --remote --merge --recursive"
```

## Guidelines for Changes

### Shared files affect many projects

Every file in this repository (and its submodules) is consumed across multiple projects. Treat changes here like changes to a shared library:

- Keep rules, commands, and skills **general-purpose** -- avoid project-specific assumptions
- Prefer additive changes over breaking modifications
- Use clear, descriptive naming so files are self-documenting in any project context

For details on the file formats for rules, commands, skills, and docs, see the [Cursor documentation](https://docs.cursor.com).

## Submodule Workflow

When working in this parent repository, remember that each subdirectory is an independent repo. Changes to submodule contents must be committed within the submodule first, then the parent updated to track the new submodule commit.

```bash
# Update all submodules to latest
git submodule update --remote --merge --recursive

# After committing inside a submodule, update the parent reference
git add <submodule-dir>
git commit -m "update <submodule> to latest"
```
