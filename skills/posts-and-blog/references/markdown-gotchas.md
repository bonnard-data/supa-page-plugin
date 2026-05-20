# Markdown gotchas on supa.page

The six pitfalls that bite most often when authoring `body` Markdown for a post.

## 1. The double-title pitfall

The renderer emits `<h1>{title}</h1>` from the post object's typed `title` column automatically. Don't repeat it in the body.

`{ "title": "My post", "body": "# My post\n\nBody text." }` ❌

`{ "title": "My post", "body": "Body text. Start subsections at `##`." }` ✅

## 2. The draft gate

`published` defaults to `false`. Forgetting it makes the post invisible on production.

```json
{ "title": "Done writing", "date": "2026-05-20", "body": "..." }   // draft — invisible
{ "title": "Done writing", "date": "2026-05-20", "published": true, "body": "..." }   // live
```

## 3. Slug confusion

The slug is part of the post object you `upsert_post`. To rename the URL, delete the old slug and create a new one — there's no rename operation.

## 4. Inline images need public URLs

```markdown
![hero](./images/hero.png)   <!-- ❌ relative path; no on-disk source tree -->
![hero](https://cdn.example.com/hero.png)   <!-- ✅ -->
```

Until native asset hosting ships, use Cloudinary / ImageKit / your own CDN.

## 5. Hard line breaks in Markdown

A single newline becomes a space (Markdown's default flow). For a real `<br>`:

```markdown
Line one\
Line two
```

(Trailing backslash on the prior line — GFM convention.)

Or two spaces at end of line (older convention; works but invisible in diffs).

## 6. Code fences need a blank line above and below

````markdown
Some prose
```js
const x = 1;
```
More prose.
````

That fails to close the fence in some parsers.

````markdown
Some prose

```js
const x = 1;
```

More prose.
````

(Blank lines around fences make the parser happy.)
