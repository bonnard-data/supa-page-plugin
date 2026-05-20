---
description: List the supa.page sites the signed-in user owns
allowed-tools: Bash
model: haiku
---

The user wants to see their supa.page sites.

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/list.sh`

Present the output above to the user verbatim. If it says "Not signed in", suggest running `/signin`. If it says "No sites yet", suggest `/new <name>`.
