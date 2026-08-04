#!/usr/bin/env bash
# Safe one-touch doc sync. Adds ONLY avo-redteam-docs/, commits if changed, then ALWAYS pushes any
# unpushed commits. Plain push, NEVER --force. If the remote moved, rebase then push.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git add avo-redteam-docs/
if ! git diff --cached --quiet; then
  git commit -m "${1:-docs: update avo-redteam-docs}"
else
  echo "no new doc changes to commit"
fi
git pull --rebase origin main
git push origin main
echo "synced."
