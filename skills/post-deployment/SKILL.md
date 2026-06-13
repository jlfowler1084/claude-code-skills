---
name: post-deployment
description: >
  Use after any deployment that writes files to live paths — deploying a skill,
  pushing a global config, installing a hook, or copying a script to a target
  directory. Trigger when the user says "verify the deployment", "check it landed",
  "run post-deploy checks", or after any session that ends with a deploy command
  or a file-copy to a live destination. Runs silent structural checks first, then
  proposes an interactive smoke test. Does NOT apply to draft edits or work-in-progress
  commits that haven't been deployed to a live path yet. Do NOT generate manual
  verification checklists — all checks are programmatic or interactive.
---

# Post-Deployment Verification

**Do NOT generate manual verification checklists.** They are redundant — Claude Code wrote the files and can verify them programmatically.

## Phase 1: Structural Checks (Silent)

Run these automatically at the end of every deployment. Do not output results unless something fails.

- File existence: verify every deployed file exists at its target path
- Canonical sync: diff live config against repo canonical copy
- Git state: confirm committed, pushed, clean working tree
- Cross-project: verify gitignore entries or config changes landed in affected projects

If all pass: report only "Deployed cleanly" with the commit hash. Do not list what was checked.

If any fail: stop and report the specific failure with enough context to fix it.

## Phase 2: Functional Smoke Test (Interactive)

After structural checks pass, propose a real-world exercise that proves the deployed feature works end-to-end. This is where bugs actually surface.

Guidelines:
- Pick a task from the Jira backlog that would naturally use the new feature, or propose a realistic scenario
- Walk through it interactively with the user — do not generate instructions to run later
- The smoke test should exercise the happy path and at least one edge case
- If bugs are found, fix them in the same session

Examples of good smoke tests:
- Deployed a worktree skill → use it on a real backlog ticket
- Deployed a new agent → run it against actual project code
- Deployed a config change → start a new session and verify behavior changed

Examples of bad smoke tests:
- "Run `cat file.md | head -1` to confirm the file exists" — that's a structural check
- "Open the folder and verify the files are there" — that's busywork
- A checklist of commands to run after the session — defeats the purpose

## Phase 3: Blocker Reporting

Only surface items that require user attention:
- Failures or unexpected states
- Decisions needed (e.g., "another project has the same issue — fix now or separate ticket?")
- Dependencies that block further work

Do not surface:
- Confirmations that things worked as expected
- File paths that were successfully written
- Git operations that completed normally
