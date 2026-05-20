#!/usr/bin/env node
/**
 * Pre-flight validator for site.json `theme_overrides`.
 *
 * Mirrors the runtime emitter at src/themes.ts `renderOverrides`:
 *   - Only the 8 allow-listed tokens are emitted
 *   - Unknown tokens are silently dropped (we *warn* here, the server stays silent)
 *   - Values containing ;, {, } are rejected (stylesheet escape)
 *   - Values > 200 chars are rejected (giant data URLs)
 *
 * Usage:
 *   node validate-theme-overrides.js path/to/site.json
 */

import { readFileSync } from 'node:fs';
import { argv, exit } from 'node:process';

const ALLOW = new Set([
  '--accent',
  '--accent-fg',
  '--radius',
  '--font-sans',
  '--font-serif',
  '--font-mono',
  '--border',
  '--width-prose',
]);

const VALID_PRESETS = new Set(['default', 'editorial']);

function warn(field, message) {
  process.stderr.write(JSON.stringify({ ok: true, warning: true, field, message }) + '\n');
}

function fail(field, message) {
  process.stderr.write(JSON.stringify({ ok: false, field, error: message }) + '\n');
  exit(1);
}

function main() {
  const file = argv[2];
  if (!file) {
    process.stderr.write('Usage: node validate-theme-overrides.js <site.json>\n');
    exit(2);
  }

  let content;
  try {
    content = readFileSync(file, 'utf8');
  } catch (e) {
    process.stderr.write(`Cannot read ${file}: ${e.message}\n`);
    exit(2);
  }

  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (e) {
    fail('', `Invalid JSON in ${file}: ${e.message}`);
  }

  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    fail('', 'site.json must be an object.');
  }

  if (parsed.theme !== undefined) {
    if (typeof parsed.theme !== 'string') {
      fail('theme', "'theme' must be a string.");
    }
    if (!VALID_PRESETS.has(parsed.theme)) {
      warn('theme', `Unknown preset "${parsed.theme}" — renderer will fall back to "default".`);
    }
  }

  const overrides = parsed.theme_overrides;
  if (overrides === undefined) {
    process.stdout.write(JSON.stringify({ ok: true, file, overrides: 0 }) + '\n');
    return;
  }
  if (typeof overrides !== 'object' || overrides === null || Array.isArray(overrides)) {
    fail('theme_overrides', "'theme_overrides' must be an object.");
  }

  let emitted = 0;
  let dropped = 0;
  for (const [key, value] of Object.entries(overrides)) {
    if (!ALLOW.has(key)) {
      warn(`theme_overrides.${key}`, `"${key}" is not in the override allow-list — silently dropped at render time.`);
      dropped++;
      continue;
    }
    if (typeof value !== 'string') {
      fail(`theme_overrides.${key}`, `Value must be a string (got ${typeof value}).`);
    }
    if (value.length === 0) {
      fail(`theme_overrides.${key}`, 'Value is empty.');
    }
    if (value.length > 200) {
      fail(`theme_overrides.${key}`, `Value is > 200 chars (got ${value.length}).`);
    }
    if (value.includes(';') || value.includes('}') || value.includes('{')) {
      fail(`theme_overrides.${key}`, "Value contains stylesheet-escape characters ('; { }') — rejected at render time.");
    }
    emitted++;
  }

  process.stdout.write(JSON.stringify({ ok: true, file, overrides: emitted, dropped }) + '\n');
}

main();
