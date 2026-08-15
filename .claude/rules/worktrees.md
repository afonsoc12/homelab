# Worktrees

Always create and manage git worktrees for this repo with **GTR** (`git gtr`), never the
built-in EnterWorktree tool.

- Create: `git gtr new <branch>` — lands in `../homelab-worktrees/<branch>`
- Never use `.claude/worktrees/` — it is gitignored and not part of the accepted workflow.
