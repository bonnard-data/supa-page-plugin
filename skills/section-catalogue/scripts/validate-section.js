#!/usr/bin/env node
/**
 * Pre-flight validator for supa.page page JSON.
 *
 * Mirrors the same check that runs on the server at /api/sync — see
 * src/validate.ts in the supa-page repo. Catch malformed pages locally
 * so you don't waste an API call.
 *
 * Usage:
 *   node validate-section.js <file.json>
 *   node validate-section.js path/to/site/source/pages/index.json
 *
 * Exits 0 if valid; 1 with a single-line `{error, field}` JSON to stderr
 * if not.
 */

import { readFileSync } from 'node:fs';
import { argv, exit } from 'node:process';

const KNOWN_TYPES = new Set([
  'hero',
  'feature-grid',
  'cta',
  'quote',
  'testimonials',
  'faq',
  'text',
  'post-feed',
  'pricing',
  'logos',
  'announcement-bar',
  'stats',
  'steps',
  'team',
  'raw-embed',
]);

const TYPE_RE = /^[a-z][a-z0-9-]{0,30}$/;
const TITLE_MAX = 200;
const WIDTH_VALUES = new Set(['prose', 'default', 'wide', 'full']);
const BG_VALUES = new Set(['bg', 'fg', 'accent', 'muted']);

function fail(field, message) {
  process.stderr.write(JSON.stringify({ ok: false, field, error: message }) + '\n');
  exit(1);
}

function validate(content, sourcePath) {
  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (e) {
    fail('', `Invalid JSON in ${sourcePath}: ${e.message}`);
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    fail('', 'Page JSON must be an object.');
  }

  if (typeof parsed.title !== 'string' || parsed.title.trim().length === 0) {
    fail('title', "Page is missing required field 'title' (non-empty string).");
  }
  if (parsed.title.length > TITLE_MAX) {
    fail('title', `'title' exceeds ${TITLE_MAX} chars.`);
  }

  if (parsed.sections === undefined) return; // empty page is legal
  if (!Array.isArray(parsed.sections)) {
    fail('sections', "'sections' must be an array.");
  }

  for (let i = 0; i < parsed.sections.length; i++) {
    const s = parsed.sections[i];
    const path = `sections[${i}]`;
    if (typeof s !== 'object' || s === null || Array.isArray(s)) {
      fail(path, 'Section must be an object.');
    }
    if (typeof s.type !== 'string') {
      fail(`${path}.type`, "Section 'type' must be a string.");
    }
    if (!TYPE_RE.test(s.type)) {
      fail(`${path}.type`, `Section 'type' must match /^[a-z][a-z0-9-]{0,30}$/ (got "${s.type}").`);
    }
    if (s.width !== undefined && !WIDTH_VALUES.has(s.width)) {
      fail(`${path}.width`, `width must be one of: ${[...WIDTH_VALUES].join(', ')}.`);
    }
    if (s.background !== undefined && !BG_VALUES.has(s.background)) {
      fail(`${path}.background`, `background must be one of: ${[...BG_VALUES].join(', ')}.`);
    }
    if (!KNOWN_TYPES.has(s.type)) {
      // Not fatal — unknown types render as hidden divs at runtime — but warn.
      process.stderr.write(
        JSON.stringify({
          ok: true,
          warning: true,
          field: `${path}.type`,
          message: `Type "${s.type}" is not in the v0.1.3 catalogue. It will render as a hidden div unless a custom Lit component supplies it.`,
        }) + '\n',
      );
    }
  }
}

function main() {
  const file = argv[2];
  if (!file) {
    process.stderr.write('Usage: node validate-section.js <file.json>\n');
    exit(2);
  }
  let content;
  try {
    content = readFileSync(file, 'utf8');
  } catch (e) {
    process.stderr.write(`Cannot read ${file}: ${e.message}\n`);
    exit(2);
  }
  validate(content, file);
  process.stdout.write(JSON.stringify({ ok: true, file }) + '\n');
}

main();
