---
name: custom-domains
description: This skill should be used when wiring a custom domain to a supa.page site, when troubleshooting "my domain isn't working", "HTTPS isn't issuing", "DNS check failed", "what records do I add", "apex vs subdomain", "Cloudflare proxy", or any task involving `/domain-add`, `/domain-list`, `/domain-recheck`, `/domain-remove`, DNS configuration, or TLS issuance via Caddy on-demand TLS.
version: 0.1.3
---

# Custom domains on supa.page

The platform serves `<site>.supa.page` for every site by default. Customers can attach their own domains via `/domain-add` and the platform handles DNS verification + automatic HTTPS via Caddy on-demand TLS.

## The flow in one sentence

`/domain-add example.com` → customer adds DNS records at their registrar → background poller verifies DNS resolves to us → Caddy mints the TLS cert on the first request → live.

## State machine

Every custom domain row carries a status from this set:

| Status | Meaning |
|---|---|
| `pending_dns` | Domain registered; DNS hasn't been verified yet (just-added, or DNS still propagating). |
| `dns_verified` | DNS resolves to our IPs. Caddy will mint a cert on the first request. |
| `issuing_cert` | Cert issuance in flight (typically <30 seconds). |
| `active` | Cert issued, serving traffic. |
| `error_dns` | DNS resolves but points elsewhere. Records misconfigured. |
| `error_cert` | Cert issuance failed (Let's Encrypt rate limit, CAA blocking, validation timeout). |
| `disabled` | Owner paused; not serving. |

The poller runs in the background; `/domain-recheck <domain>` forces an immediate re-check.

## Apex vs subdomain

| Domain shape | DNS record type |
|---|---|
| `example.com` (apex, no subdomain) | **A** record(s) pointing to our IPs |
| `www.example.com`, `blog.example.com`, `app.example.com` (subdomain) | **CNAME** record pointing to `routing.supa.page` |

The `/domain-add` response tells you which records to add, with the right values. Don't guess — read the response.

## Each subdomain is its own registration

`example.com` and `www.example.com` are **two separate domains** in the platform. Register both if you want both. The www-pairing feature (v0.1.x adds a 301 from www → apex or vice versa automatically) is wired but each side still has to be registered.

## Auto-issued HTTPS

Caddy uses on-demand TLS for any registered + DNS-verified domain. Concretely:

- First request to `https://example.com` triggers issuance.
- Issuance takes ~5–30 seconds for Let's Encrypt.
- We never request a cert for a domain that isn't `dns_verified` (avoids burning the Let's Encrypt rate limit on misconfigured customers).
- After issuance, the cert auto-renews ~30 days before expiry.

## Why your domain might not work

### `pending_dns` for hours

DNS hasn't propagated. Common causes:
- Registrar's TTL is high (default 1 hour, sometimes 24+).
- Customer added records to a different DNS provider than the authoritative one (e.g. domain transferred but nameservers still old).
- Customer added the right records to a Cloudflare-proxied domain — Cloudflare returns its own IPs by default. Either disable the proxy (gray cloud) or use a CNAME-flattening trick.

Run `/domain-recheck <domain>` to force a re-check after fixing DNS. If still `pending_dns`, run `dig +short example.com` locally and compare with the expected IP from `/domain-add` response.

### `error_dns`

DNS resolves but to the wrong place. Look at the `observed` field in the recheck response:

```json
{
  "status": "error_dns",
  "observed": ["104.21.x.x"],
  "expected": ["178.105.150.207"]
}
```

The customer's records point somewhere else — fix them at the registrar, then `/domain-recheck`.

### `error_cert`

DNS is right but cert issuance failed. Common causes:
- **CAA blocking.** The domain's CAA record only authorises non-Let's-Encrypt CAs. Add `letsencrypt.org` to the CAA records or remove the CAA entry.
- **Let's Encrypt rate limit.** 5 duplicate certs per week per registered domain. Wait or use a different subdomain.
- **Cloudflare proxy.** Cloudflare's "Full (strict)" SSL mode requires our cert to be valid — but if Cloudflare proxies the connection, we never see the customer's actual request and can't complete the HTTP-01 challenge. Either disable the proxy or use DNS-01 (not yet supported).

### Cloudflare specifically

If the customer uses Cloudflare DNS:

- **Gray cloud (DNS only)** — simplest. Records resolve directly to our IPs; Caddy issues normally.
- **Orange cloud (proxied)** — Cloudflare terminates TLS at the edge. We never see the request. Don't use this; switch to gray cloud or expect 522s.

## /domain-remove

Removes the binding in supa.page only. DNS at the registrar is unchanged — customer cleans that up separately. Caddy may serve the old cert briefly until its cache clears (a few minutes).

This command is `disable-model-invocation` — only a human can trigger it.

## Validating domain shape before /domain-add

The bundled validator catches malformed input before hitting the API:

```bash
node ${CLAUDE_PLUGIN_ROOT}/skills/custom-domains/scripts/validate-domain.js example.com
```

Returns ok or an error message with the rule that failed (length, label format, TLD presence, etc.).

## Anti-patterns

- **Don't register `*.supa.page` hosts as custom domains.** The platform refuses with a 400. Use the `<site>.supa.page` URL the platform already provides.
- **Don't add A records for a subdomain.** It works, but CNAME is the right shape — A locks you to a specific IP. We've changed IPs once already (it'll happen again).
- **Don't run `/domain-add` from a loop.** Each call hits the platform + the customer's DNS resolver. Rate-limit yourself to manual invocations.
- **Don't share the same domain between two sites.** The platform refuses with a 409.

## Additional resources

- **`references/dns-troubleshooting.md`** — common DNS issues + what `dig` output looks like for each.
- **`references/state-machine.md`** — full state transitions + what causes each.
- **`examples/`** — sample `/domain-add` responses for apex + subdomain shapes.
- **`scripts/validate-domain.js`** — RFC 1035-ish shape check.
