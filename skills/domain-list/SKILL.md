---
description: List custom domains for the current site with DNS + cert status
allowed-tools: Bash
model: haiku
---

Show the user the custom domains registered for this site.

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/domain-list.sh`

Present the output verbatim. Icons in the output: `✓` active, `⏳` propagating, `⚠` error, `🔒` password-protected, `–` disabled.
