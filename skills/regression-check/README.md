# Regression Check Skill

A Claude Code skill that verifies previously shipped features still exist — before and after code changes — by checking a project's `feature-manifest.json`. It catches accidental deletions during refactors, rewrites, and large edits.

## What This Skill Does

You declare your shipped features in a `feature-manifest.json` (per feature: the file path, the exports that must exist, and content patterns that must appear). The skill checks every entry and **halts work if any feature regressed**, rather than discovering it after the fact. If no manifest exists, it skips silently — zero friction for projects that don't use one.

## The Manifest

```json
{
  "_meta": { "project": "my-app", "base_path": "." },
  "features": [
    {
      "ticket": "PROJ-101",
      "name": "Search History Panel",
      "file": "src/components/search/search-history.tsx",
      "exports": ["SearchHistoryPanel"],
      "patterns": ["loadHistory"],
      "area": "search"
    }
  ]
}
```

## Installation

```bash
# Global (all projects)
cp -r skills/regression-check ~/.claude/skills/regression-check

# Per-project
cp -r skills/regression-check .claude/skills/regression-check
```

The `SKILL.md` includes a copy-paste `tools/regression-check.sh` template for a one-command check in any project that has a manifest.
