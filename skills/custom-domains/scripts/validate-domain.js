#!/usr/bin/env node
/**
 * Pre-flight validator for custom-domain shape.
 *
 * Catches malformed input before it hits /api/domains. Same regex shape
 * the server uses, plus a few extra checks for common typos.
 *
 * Usage:
 *   node validate-domain.js example.com
 *   node validate-domain.js www.example.co.uk
 */

import { argv, exit } from 'node:process';

// RFC 1035-ish: each label is [a-z0-9](-?[a-z0-9])* up to 63 chars, total
// length ≤ 253, at least two labels, TLD is 2+ alpha chars.
const DOMAIN_RE =
  /^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$/i;

function fail(message) {
  process.stderr.write(JSON.stringify({ ok: false, error: message }) + '\n');
  exit(1);
}

function main() {
  const raw = argv[2];
  if (!raw) {
    process.stderr.write('Usage: node validate-domain.js <domain>\n');
    exit(2);
  }
  const domain = raw.trim().toLowerCase();

  if (domain.length === 0) fail('Domain is empty.');
  if (domain.length > 253) fail(`Domain is ${domain.length} chars (max 253).`);
  if (domain.startsWith('http://') || domain.startsWith('https://')) {
    fail(`Strip the scheme. Use the bare domain (got "${raw}").`);
  }
  if (domain.includes('/')) fail('Path component not allowed — use just the host.');
  if (domain.includes(' ')) fail('Spaces not allowed.');
  if (domain.startsWith('-') || domain.endsWith('-')) {
    fail('Domain cannot start or end with a hyphen.');
  }
  if (domain.startsWith('.') || domain.endsWith('.')) {
    fail('Domain cannot start or end with a dot.');
  }
  if (!DOMAIN_RE.test(domain)) {
    fail(`"${domain}" doesn't look like a valid domain. Examples: example.com, www.example.com, blog.acme.io`);
  }
  if (/\.supa\.page$/i.test(domain)) {
    fail("Cannot register a *.supa.page host as a custom domain — the platform owns this apex.");
  }

  // Classify: apex (one dot after the registrable part) vs subdomain.
  const labelCount = domain.split('.').length;
  const kind =
    labelCount === 2 ? 'apex' :
    /^(co|com|net|org|gov|edu|ac)\.[a-z]{2}$/.test(domain.split('.').slice(-2).join('.'))
      ? 'apex' // best-effort detection for double-barrel TLDs
      : 'subdomain';

  process.stdout.write(JSON.stringify({
    ok: true,
    domain,
    kind,
    record_type: kind === 'apex' ? 'A' : 'CNAME',
  }) + '\n');
}

main();
