---
description: Show the current site's name, server, sign-in state, and basic health
allowed-tools: Bash
model: haiku
---

Show the user the status of the supa.page site they're working in.

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/status.sh`

Present the output above verbatim. If the user isn't in a site directory or isn't signed in, the script handles the messaging — pass it through.
