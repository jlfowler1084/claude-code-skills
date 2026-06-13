# Post-Deployment Verification Skill

A Claude Code skill for verifying that a deployment actually landed and works — without generating a manual checklist nobody runs. Use it after writing files to live paths: installing a skill or hook, pushing a config, or copying a script to a target directory.

## What This Skill Does

- **Phase 1 — structural checks (silent):** file existence at target paths, live-vs-canonical diff, clean/committed git state. Reports only on failure.
- **Phase 2 — functional smoke test (interactive):** a real-world exercise that drives the deployed feature end-to-end, where bugs actually surface — not a list of commands to run later.
- **Phase 3 — blocker reporting:** surfaces only failures and decisions, never confirmations of things that worked.

The core idea: Claude wrote the files, so it can verify them programmatically and then *prove* them with a real task — manual checklists are redundant busywork.

## Installation

```bash
# Global (all projects)
cp -r skills/post-deployment ~/.claude/skills/post-deployment

# Per-project
cp -r skills/post-deployment .claude/skills/post-deployment
```
