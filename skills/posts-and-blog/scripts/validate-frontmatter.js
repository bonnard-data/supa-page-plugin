#!/usr/bin/env node
/**
 * Pre-flight validator for supa.page post frontmatter.
 *
 * Catches the common failure modes locally before sync:
 *   - missing title
 *   - missing/false `published` on what looks like a finished post (warning)
 *   - malformed date
 *   - tags not an array of strings
 *   - slug-like fields (the field is ignored; warn)
 *   - filename slug doesn't match /^[a-z0-9-]+$/
 *
 * Usage:
 *   node validate-frontmatter.js path/to/post.md
 */

import { readFileSync } from 'node:fs';
import { basename } from 'node:path';
import { argv, exit } from 'node:process';

const SLUG_RE = /^[a-z0-9](?:[a-z0-9-]{0,128})$/i;

function warn(field, message) {
  process.stderr.write(JSON.stringify({ ok: true, warning: true, field, message }) + '\n');
}

function fail(field, message) {
  process.stderr.write(JSON.stringify({ ok: false, field, error: message }) + '\n');
  exit(1);
}

function parseFrontmatter(content) {
  // Minimal YAML-front-matter parser: split on the leading --- block and
  // do line-by-line key:value parsing. We don't pull in a YAML lib so the
  // script stays dependency-free.
  if (!content.startsWith('---')) {
    return { fm: null, body: content };
  }
  const end = content.indexOf('\n---', 3);
  if (end < 0) return { fm: null, body: content };
  const block = content.slice(3, end).trim();
  const body = content.slice(end + 4).replace(/^\n/, '');
  const fm = {};
  for (const line of block.split('\n')) {
    const m = line.match(/^([a-zA-Z_][a-zA-Z0-9_]*):\s*(.*)$/);
    if (!m) continue;
    const [, key, raw] = m;
    let value = raw.trim();
    // Strip surrounding quotes
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    // Arrays: [a, b] or [a]
    if (value.startsWith('[') && value.endsWith(']')) {
      const inner = value.slice(1, -1).trim();
      fm[key] = inner.length === 0
        ? []
        : inner.split(',').map((s) => s.trim().replace(/^["']|["']$/g, ''));
      continue;
    }
    // Booleans
    if (value === 'true') { fm[key] = true; continue; }
    if (value === 'false') { fm[key] = false; continue; }
    fm[key] = value;
  }
  return { fm, body };
}

function validate(filePath, content) {
  const { fm, body } = parseFrontmatter(content);
  if (!fm) {
    fail('', 'No YAML frontmatter found at the start of the file.');
  }

  if (typeof fm.title !== 'string' || fm.title.trim().length === 0) {
    fail('title', "Post is missing required 'title' field.");
  }

  if (fm.published === undefined) {
    warn('published', "Field 'published' is missing — post will be treated as a draft (hidden from /posts, RSS, sitemap).");
  } else if (fm.published !== true) {
    warn('published', `Post is a draft (published: ${fm.published}).`);
  }

  if (fm.date === undefined) {
    warn('date', "Field 'date' is missing — post will sort last and render without a date line.");
  } else if (typeof fm.date === 'string' && Number.isNaN(Date.parse(fm.date))) {
    fail('date', `Cannot parse 'date' as a Date (got "${fm.date}"). Use ISO 8601: 2026-05-20.`);
  }

  if (fm.tags !== undefined) {
    if (!Array.isArray(fm.tags)) {
      fail('tags', "'tags' must be an array of strings.");
    }
    for (let i = 0; i < fm.tags.length; i++) {
      if (typeof fm.tags[i] !== 'string') {
        fail(`tags[${i}]`, "Each tag must be a string.");
      }
    }
  }

  if (fm.slug !== undefined) {
    warn('slug', "Field 'slug' is ignored — the filename is the slug. To change the URL, rename the file.");
  }

  if (typeof fm.og_image === 'string' && !/^(https?:|\/)/.test(fm.og_image)) {
    fail('og_image', `'og_image' must be a public https URL or a path starting with '/'.`);
  }

  // Filename slug check
  const fname = basename(filePath, '.md');
  if (!SLUG_RE.test(fname)) {
    fail('', `Filename "${fname}.md" is not a valid slug — must match /^[a-z0-9-]+$/.`);
  }

  // Body starts with # Title?
  if (/^#\s+/.test(body)) {
    warn('body', "Body starts with '# Title' but frontmatter already provides the title. This will render two titles. Start subsections at '##'.");
  }
}

function main() {
  const file = argv[2];
  if (!file) {
    process.stderr.write('Usage: node validate-frontmatter.js <post.md>\n');
    exit(2);
  }
  let content;
  try {
    content = readFileSync(file, 'utf8');
  } catch (e) {
    process.stderr.write(`Cannot read ${file}: ${e.message}\n`);
    exit(2);
  }
  validate(file, content);
  process.stdout.write(JSON.stringify({ ok: true, file }) + '\n');
}

main();
