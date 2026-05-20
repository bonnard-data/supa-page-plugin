# Markdown gotchas on supa.page

The six pitfalls that bite most often.

## 1. The double-title pitfall

The renderer emits `<h1>{title}</h1>` from frontmatter automatically.
Don't repeat it in the body:

❌
```markdown
---
title: My post
---

# My post

Body text.
```

✅
```markdown
---
title: My post
---

Body text. Start subsections at `##`.
```

## 2. The draft gate

`published` defaults to `false`. Forgetting it makes the post invisible
on production:

❌
```markdown
---
title: Done writing
date: 2026-05-20
---

This will not show up.
```

✅
```markdown
---
title: Done writing
date: 2026-05-20
published: true
---

This shows up.
```

## 3. Slug confusion

The slug is the filename. `slug:` in frontmatter is ignored:

❌
```markdown
---
slug: my-cool-url
---
```

This file is still at `/posts/<filename-without-md>`. To get the URL
you want, rename the file.

## 4. Inline images need public URLs (pre-v0.2)

❌
```markdown
![hero](./images/hero.png)
```

The local relative path won't resolve because the sync hook doesn't ship
binary files. Native asset hosting lands in v0.2.

✅
```markdown
![hero](https://cdn.example.com/hero.png)
```

Use Cloudinary / ImageKit / your own CDN until v0.2.

## 5. Hard line breaks in Markdown

A single newline becomes a space (Markdown's default flow). For a real
`<br>`:

```markdown
Line one\
Line two
```

(Trailing backslash on the prior line — GFM convention.)

Or two spaces at end of line (older convention; works but invisible in
diffs).

## 6. Code fences need a blank line above and below

❌
```markdown
Some prose
```js
const x = 1;
```
More prose.
```

That fails to close the fence in some parsers.

✅
```markdown
Some prose

```js
const x = 1;
```

More prose.
```

(Blank lines around fences make the parser happy.)
