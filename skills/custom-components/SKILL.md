---
name: custom-components
description: This skill should be used as a LAST RESORT when the user wants custom UI that the 15-section catalogue + theme overrides + raw-embed can't express — e.g. "add a custom Lit component", "build a custom interactive widget", "add a price calculator", "author a custom section type", "add an animated mockup". Read this skill before writing JS; in 90% of cases the right answer is `raw-embed` or a token override, not a custom component.
version: 0.1.3
---

# Custom Lit components on supa.page

This is the **last rung** of the customization ladder. Almost everything customers ask for has a better answer elsewhere — read this skill before writing JavaScript.

## The ladder

When the customer asks for something the catalogue doesn't cover, climb in this order:

1. **Edit a section prop.** New eyebrow? `eyebrow: "..."`. New CTA? `cta: {...}`.
2. **Edit `theme_overrides` in site.json.** (See the `theme-tokens` skill.) Different brand color, font, border radius — these are token overrides, not new components.
3. **Edit `header`/`footer` in site.json.** Custom nav, footer links.
4. **Add a `raw-embed` section.** One-off HTML+CSS, shadow-DOM scoped. Covers ~95% of "we need something the catalogue doesn't have."
5. **Author a custom Lit component.** This skill. Rare. Real interactive widgets only.

Reach for level 5 only after eliminating levels 1–4. If the customer says "I want a price calculator that updates based on input", that's a Lit component. If they say "I want my hero CTA to be pink", that's a theme override.

## When raw-embed is the right answer instead

`raw-embed` can hold:
- Static custom layouts
- Newsletter signup forms (ConvertKit, Mailerlite)
- Calendly embeds, third-party widgets
- Hand-crafted HTML/CSS for a single page section
- Codepen-style demos
- Marquee text, manual animations

`raw-embed` is **shadow-DOM scoped** — the CSS can't leak. The content can't reach the page's JS. It's the right escape hatch for one-offs.

You only need a custom Lit component when:
- You need **reusable state across multiple instances** of the section type on different pages.
- You need **real reactivity** (component re-renders when state changes — not just on initial load).
- You need to **interact with the platform's CSS tokens** the way the built-in components do (e.g. `var(--accent)` should bind to whatever theme is active).

## How customer-authored Lit works

The renderer in `src/custom-sections.ts` dynamically imports each unknown section type from:

```
<site-dir>/source/components/<type>/<type>.js
```

The file must `export default` (or named `export`) a function with this signature:

```js
export function render({ section, html }) {
  return html`<sp-my-section ...></sp-my-section>`;
}
```

Where:
- `section` is the section object from the page JSON
- `html` is `lit`'s html tagged-template — you don't need to import it
- The return value is a Lit `TemplateResult`

The component renders via the same `@lit-labs/ssr` pipeline that powers the built-in sections. Theme CSS vars cascade through automatically.

## Security caveats

**The component runs in the same Bun process that serves all customer sites.** Reading customer-authored JS is a real footgun for multi-tenant deployments:

- **Right now (v0.1.3):** single-tenant alpha — the only people writing custom components are people you trust (you, your team).
- **Future (post-v0.2):** multi-tenant requires sandboxing — `isolated-vm` per-component or per-site Bun subprocesses. Track issue [tbd] on the roadmap.

Don't ship customer-authored components on a multi-tenant production until the sandbox lands. The current implementation will refuse to load components from sites whose org is not yours.

## Author flow

1. Create the directory: `<site-dir>/source/components/<type>/`
2. Author `<type>.js` exporting a `render` function.
3. Reference it in page JSON:

   ```json
   { "type": "price-calculator", "starting": 0, "rate": 9 }
   ```

   The renderer dispatches `type: "price-calculator"` → imports `source/components/price-calculator/price-calculator.js`.

4. Sync. Publish. The component renders.

## Naming rules

- Lowercase, kebab-case, 1–30 chars.
- Don't collide with built-in section types (`hero`, `feature-grid`, `cta`, etc.). The renderer prefers built-ins; your custom code never runs.
- Convention: use a project prefix you control (`acme-pricing-card`) to make collisions impossible.

## Limits

- **One file per component.** No multi-file imports yet. Inline whatever you need.
- **No `node_modules`** at the per-site path. `lit` and other deps are provided by the platform; everything else, you bring inline.
- **No fetch on the server.** Component code runs at SSR time; it should be pure-function given `section`.
- **Hydration is opt-in.** If the component needs to be interactive in the browser, ship a corresponding `<script>` in a `raw-embed` section. The platform doesn't auto-hydrate customer Lit components.

## Anti-patterns

### "I'll use a custom component to change the hero color"

No — `theme_overrides` change colors. A custom component is the wrong tool.

### "I'll write my own pricing component because pricing doesn't have a billing-toggle"

The `pricing` section type doesn't ship a monthly/yearly billing toggle in v0.1.3 (deferred per the audit). The right paths are:

- Use the `billing_note` field to set context ("Monthly. Switch to annual for 20% off → /pricing-annual"), and use two separate pages.
- File a feature request for native billing toggle.

Don't write a one-off custom component for what should be a section enhancement.

### "I'll embed a third-party widget via custom component"

If it's `<script src="...">` + a target div, that's a `raw-embed`. Custom components are for things you author top-to-bottom in Lit.

### "I'll use a custom component to add JS to every page"

That's a global-script injection problem. The right answer is the future Site-wide chrome scripts feature; until then, put it in every page's `raw-embed`.

## Additional resources

- **`examples/`** — one canonical custom-component example (`acme-pricing-toggle`) showing the file layout, the render-function signature, and the page-JSON wiring.
