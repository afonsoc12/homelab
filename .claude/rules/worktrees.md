# Worktrees

Always create and manage git worktrees for this repo with **GTR** (`git gtr`), never the
built-in EnterWorktree tool.

- Before creating a worktree, always pull the latest `master` first, unless told otherwise.
  `git gtr new` fetches and branches from `origin/master`, so a local `git pull` isn't strictly
  required for the worktree itself — but keep the main checkout up to date anyway so it doesn't
  drift and cause conflicts later.
- Create: `git gtr new <branch>` — lands in `../homelab-worktrees/<branch>`
- Never use `.claude/worktrees/` — it is gitignored and not part of the accepted workflow.
