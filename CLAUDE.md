# skillless

A CLI tool for installing and managing AI agent skills from categorized CSV lists via `npx skills`.

## What it does

- `skillless pack <category>` — install all skills in a category (e.g. `react`, `python`)
- `skillless unpack <category>` — remove all skills in a category
- `skillless list` — show available categories and skill counts
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
```

## Install for regular use

```bash
# 1. Clone this repo
git clone <repo-url>
cd skillless

# 2. Add a shell alias so `skillless` is available anywhere
echo 'alias skillless="'"'$(pwd)'"'/skillless"' >> ~/.zshrc
source ~/.zshrc

# 3. Run globally by default
skillless pack python
```

Use `-s local` only when you want skills installed into the current project instead of your global agent config.

## Project structure

- `skillless` — main bash CLI entrypoint
- `lists/` — category CSV files (e.g. `default.csv`, `python.csv`, `react.csv`)
- `scripts/install-skills.sh` — worker that processes CSV rows via `npx skills add`
- `skills-lock.json` — lockfile tracking installed skill sources and hashes

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
- `-d, --lists-dir <dir>` — custom lists directory
