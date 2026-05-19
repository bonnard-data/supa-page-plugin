---
name: status
description: Show the current supa.page site's name, server, and basic health
---

Show the user the status of the supa.page site they're working in.

## What to do

1. Find the nearest `.supa-page.json` by walking up from the current working directory.
2. If none, tell the user "Not in a supa.page site directory. Run `/site-new` to create one."
3. Otherwise, read it and print:
   - Site name
   - Server URL
   - Local preview URL: `<server>/?site=<name>`
4. Hit `<server>/health` with curl. If 200, print "Server: ok". If not, print "Server: unreachable".
