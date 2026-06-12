# skillless

A CLI tool for installing and managing AI agent skills from categorized CSV lists via `npx skills`.

## What it does

- `skillless pack <category|all>` — install all skills in a category
- `skillless unpack <category|all>` — remove all skills in a category
- `skillless list` — show available categories and skill counts
- `skillless upgrade` — self-update to latest version
- `skillless help` — show usage

## Key commands

```bash
# Run the main tool
./skillless help

# Install skills from a category
./skillless pack python

# Install skills from a category locally (project-level)
skillless -s local pack python

# Dry-run (print commands without running)
skillless -n pack python

# List all categories
./skillless list

# Self-update
./skillless upgrade
```

## Install for regular use

```bash
# 1. Clone this repo
git clone <repo-url>
cd skillless

# 2. Add a shell alias so `skillless` is available anywhere
chmod +x skillless
echo 'alias skillless="'"'$(pwd)'"'/skillless"' >> ~/.zshrc
source ~/.zshrc

# 3. Run globally by default
skillless pack python
```

Use `-s local` only when you want skills installed into the current project instead of your global agent config.

## Project structure

- `skillless` — main bash CLI entrypoint
- `lists/` — category CSV files (20 categories)
- `scripts/install-skills.sh` — worker that processes CSV rows via `npx skills add`
- `skills-lock.json` — lockfile tracking installed skill sources and hashes
- `README.md` — project documentation
- `skillless.png` — project logo

## CSV format

Each `.csv` in `lists/` has columns:

| Column       | Description                                                          |
|--------------|----------------------------------------------------------------------|
| `repo`       | GitHub repo (owner/repo)                                             |
| `skill_name` | Skill to install (empty = all from repo)                             |
| `agents`     | Target agents (`opencode claude-code codex`, or empty = auto-detect) |

## Requirements

- `npx` (Node.js/npm)
- Bash 4+ (uses associative arrays in `install-skills.sh`)

## Useful options

- `-s, --scope <global|local>` — install scope (default: global)
- `-n, --dry-run` — print commands without running
- `-v, --verbose` — show raw `npx skills` output
- `--skip-update` — skip the staleness check (pack only)
- `-d, --lists-dir <dir>` — custom lists directory
