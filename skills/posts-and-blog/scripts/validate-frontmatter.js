#!/usr/bin/env node
/**
 * Pre-flight validator for supa.page post objects.
 *
 * Mirrors the check the server runs inside `upsert_post`. Catches the
 * common failure modes locally before the upsert:
 *   - missing title
 *   - missing/false `published` on what looks like a finished post (warning)
 *   - malformed date
 *   - tags not an array of strings
 *   - slug doesn't match /^[a-z0-9-]+$/
 *   - og_image not a public URL or absolute path
 *   - body starts with '# Title' (would render two titles)
 *
 * Usage:
 *   node validate-frontmatter.js path/to/post.json
 *
 * The argument is a JSON file containing the post object passed to
 * `upsert_post`:
 *
 *   { "slug": "...", "title": "...", "date": "...", "published": true,
 *     "tags": [...], "body": "..." }
 *
 * Exits 0 on valid (+ optional warning lines on stderr); 1 with a
 * single-line `{ok:false, field, error}` JSON to stderr on failure.
 */

import { readFileSync } from 'node:fs';
import { argv, exit } from 'node:process';

const SLUG_RE = /^[a-z0-9](?:[a-z0-9-]{0,128})$/i;

function warn(field, message) {
  process.stderr.write(JSON.stringify({ ok: true, warning: true, field, message }) + '\n');
}

function fail(field, message) {
  process.stderr.write(JSON.stringify({ ok: false, field, error: message }) + '\n');
  exit(1);
}

function validate(post) {
  if (typeof post !== 'object' || post === null || Array.isArray(post)) {
    fail('', 'Post must be a JSON object.');
  }

  if (typeof post.slug !== 'string' || post.slug.trim().length === 0) {
    fail('slug', "Post is missing required 'slug' field.");
  }
  if (!SLUG_RE.test(post.slug)) {
    fail('slug', `Slug "${post.slug}" is not valid — must match /^[a-z0-9-]+$/.`);
  }

  if (typeof post.title !== 'string' || post.title.trim().length === 0) {
    fail('title', "Post is missing required 'title' field.");
  }

  if (post.published === undefined) {
    warn('published', "Field 'published' is missing — post will be treated as a draft (hidden from /posts, RSS, sitemap).");
  } else if (post.published !== true) {
    warn('published', `Post is a draft (published: ${JSON.stringify(post.published)}).`);
  }

  if (post.date === undefined) {
    warn('date', "Field 'date' is missing — post will sort last and render without a date line.");
  } else if (typeof post.date === 'string' && Number.isNaN(Date.parse(post.date))) {
    fail('date', `Cannot parse 'date' as a Date (got "${post.date}"). Use ISO 8601: 2026-05-20.`);
  }

  if (post.tags !== undefined) {
    if (!Array.isArray(post.tags)) {
      fail('tags', "'tags' must be an array of strings.");
    }
    for (let i = 0; i < post.tags.length; i++) {
      if (typeof post.tags[i] !== 'string') {
        fail(`tags[${i}]`, 'Each tag must be a string.');
      }
    }
  }

  if (typeof post.og_image === 'string' && !/^(https?:|\/)/.test(post.og_image)) {
    fail('og_image', `'og_image' must be a public https URL or a path starting with '/'.`);
  }

  if (typeof post.body === 'string' && /^#\s+/.test(post.body)) {
    warn('body', "Body starts with '# Title' but the typed 'title' field already provides one. This will render two titles. Start subsections at '##'.");
  }
}

function main() {
  const file = argv[2];
  if (!file) {
    process.stderr.write('Usage: node validate-frontmatter.js <post.json>\n');
    exit(2);
  }
  let raw;
  try {
    raw = readFileSync(file, 'utf8');
  } catch (e) {
    process.stderr.write(`Cannot read ${file}: ${e.message}\n`);
    exit(2);
  }
  let post;
  try {
    post = JSON.parse(raw);
  } catch (e) {
    fail('', `Invalid JSON: ${e.message}`);
  }
  validate(post);
  process.stdout.write(JSON.stringify({ ok: true, file }) + '\n');
}

main();
