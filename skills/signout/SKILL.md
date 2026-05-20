---
description: Sign out of supa.page on this machine (revokes the session server-side)
allowed-tools: Bash
model: haiku
disable-model-invocation: true
---

Revoke the local session and delete `~/.config/supa-page/session.json`.

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/signout.sh`

Present the output verbatim. `disable-model-invocation` is set so background loops can't sign the user out unexpectedly — only a direct `/signout` invocation can reach this.
