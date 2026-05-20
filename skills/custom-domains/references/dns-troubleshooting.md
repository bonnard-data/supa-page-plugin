# DNS troubleshooting

The five most common DNS issues + what to look for.

## 1. "Still `pending_dns` after 30 minutes"

```
$ dig +short example.com
```

If the output is **empty**:
- Records weren't saved at the registrar (refresh the registrar dashboard, confirm they're persisted).
- Customer added them to a different DNS provider than the authoritative one — check `whois example.com` for the nameservers and confirm they match where the records were added.

If the output is **the wrong IP**:
- See "error_dns" below.

If the output is **the right IP**, `/domain-recheck <domain>` should flip to `dns_verified` immediately. If it doesn't, the customer's local DNS cache might be tainted — try `dig +short @1.1.1.1 example.com` (use Cloudflare's public resolver directly).

## 2. "error_dns — points to Cloudflare's IPs"

```
$ dig +short example.com
104.21.x.x
172.67.x.x
```

The customer's domain is behind Cloudflare with the orange-cloud (proxied) toggle ON. Cloudflare returns its own IPs and terminates TLS at the edge. The platform can't issue a cert because the HTTP-01 challenge never reaches us.

Two fixes:
- **Recommended:** switch the relevant record to "DNS only" (gray cloud) at Cloudflare. Records resolve directly to our IPs; Caddy issues normally.
- **Workaround:** keep the proxy ON but switch Cloudflare's SSL mode to "Off" — defeats the whole point of Cloudflare. Don't do this.

## 3. "error_cert — CAA blocked"

```
$ dig CAA example.com
example.com.  3600  IN  CAA  0 issue "digicert.com"
```

The customer's CAA records only authorise DigiCert. Let's Encrypt can't issue.

Fix at the registrar:
- Add `0 issue "letsencrypt.org"` as an additional CAA record (don't remove the existing one if they still want DigiCert for other purposes), OR
- Remove the CAA records entirely if they don't actually need to constrain CAs.

After the change: wait for the CAA TTL to expire (usually 1 hour), then `/domain-recheck`.

## 4. "error_cert — Let's Encrypt rate limit"

> Error creating new account: too many new orders recently

LE limits to 5 duplicate certs per registered domain per week. If the customer has been thrashing `/domain-add` and `/domain-remove` on the same domain, they may have burned through it.

Options:
- Wait for the rate limit to reset (rolling 7-day window).
- Use a different subdomain temporarily.
- Contact Let's Encrypt for an exemption (rare).

## 5. "DNS resolves, cert issued, but the site 404s"

DNS is fine, TLS is fine, but the site renders nothing.

Two causes:
- **`current.json` is missing** for the bound site. The customer ran `/new` but `/publish` was interrupted before the initial scaffold landed. Run `/publish` once to seed.
- **The bound site is `visibility=private`** and the visitor isn't an org member. The custom domain inherits the same visibility gate as `<site>.supa.page`. Either `/visibility public` or accept that custom-domain requires sign-in.

## Useful `dig` recipes

```bash
# What does the world see for your apex?
dig +short example.com

# What does Cloudflare's public resolver see?
dig +short @1.1.1.1 example.com

# CAA records (blocks LE?)
dig CAA example.com

# Nameservers — confirm DNS is hosted where you think
dig NS example.com

# Full trace from root nameservers
dig +trace example.com
```

## When in doubt

`/domain-recheck <domain>` returns the platform's view of `observed` vs `expected`. That's the canonical answer — if it disagrees with your local `dig`, the issue is most likely a propagation delay or a cache somewhere between you and the customer's authoritative DNS.
