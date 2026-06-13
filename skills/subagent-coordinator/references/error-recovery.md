# Error Recovery

If anything goes wrong at any phase:

1. **Implementer reports FAILED** — Read the error, adjust constraints, re-delegate
2. **QA reports CRITICAL** — `git restore .` immediately, re-plan
3. **QA reports FAIL** — Determine if it's a new regression or pre-existing. New → fix. Pre-existing → document and proceed.
4. **Reviewer reports BLOCK** — Address critical findings before committing
5. **Merge conflict** — Resolve manually in the coordinator, don't delegate conflict resolution to subagents

## Worktree Merge Conflicts

When a parallel batch produces a merge conflict during the post-batch merge phase:

1. `git merge --abort`
2. Re-dispatch the conflicting unit serially against the now-merged tree
3. Do not hand-resolve silently — that discards one unit's intent
