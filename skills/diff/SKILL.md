---
description: Show changes between staging (source) and the current publish
allowed-tools: Bash
model: haiku
---

Show changes vs. the live publish.

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/diff.sh`

Present the output verbatim. If the user expected changes but none are reported, remind them that auto-sync sends every edit to the server — they may want to check the sync hook is firing (the PostToolUse hook on Write/Edit/MultiEdit inside `source/`).
