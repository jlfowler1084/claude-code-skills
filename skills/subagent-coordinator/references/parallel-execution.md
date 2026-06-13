# Parallel Execution

For independent tasks that don't share files, you CAN delegate to multiple implementer
instances in parallel. Rules:

- Tasks MUST NOT touch overlapping files
- Each task gets its own feature branch (or the tasks are truly independent)
- Run QA verification after ALL parallel tasks complete
- Merge one branch at a time, testing after each merge

## Worktree-Isolated Parallel Dispatch

When using `isolation: "worktree"` (Claude Code Agent tool), each parallel subagent
works in its own branch. The coordinator:

1. Waits for all subagents in the current batch to finish
2. Reviews each worktree diff in dependency order
3. Merges each subagent branch into the coordinator's branch sequentially
4. Runs the test suite after each merge
5. Removes the worktree and deletes the branch after a clean merge
