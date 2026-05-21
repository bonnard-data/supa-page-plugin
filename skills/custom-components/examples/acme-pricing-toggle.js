/**
 * Example custom Lit section: acme-pricing-toggle
 *
 * Demonstrates the customer-authored-component contract:
 *   - file at <platform-root>/components/<site>/acme-pricing-toggle/acme-pricing-toggle.js
 *     (manually installed on the platform host in v0.4.0; a first-class upload
 *     tool is on the roadmap)
 *   - exports a `render({section, html})` function returning a Lit TemplateResult
 *   - references theme CSS vars (--accent, --bg-alt) so it inherits whichever preset is active
 *
 * Page row wiring (set via `upsert_page`, in the `sections[]` array):
 *
 *   {
 *     "type": "acme-pricing-toggle",
 *     "annual_discount_pct": 20,
 *     "monthly_price": 19,
 *     "currency": "$"
 *   }
 *
 * Notes:
 *  - This is SSR only — no client JS. To make it actually interactive
 *    (clickable toggle), ship a corresponding inline <script> in a sibling
 *    raw-embed section that listens for the toggle and updates the DOM.
 *  - lit's `html` is provided to the render function — no imports needed.
 */

export function render({ section, html }) {
  const monthly = Number(section.monthly_price ?? 0);
  const pct = Number(section.annual_discount_pct ?? 20);
  const annualMonthly = Math.round(monthly * (1 - pct / 100));
  const cur = String(section.currency ?? '$');

  return html`
    <style>
      .toggle {
        display: inline-flex;
        gap: 0;
        border: 1px solid var(--border, #e4e4e7);
        border-radius: 9999px;
        padding: 0.25rem;
        background: var(--bg-alt, #f4f4f5);
        font-family: var(--font-sans, sans-serif);
        font-size: 0.875rem;
      }
      .toggle button {
        padding: 0.375rem 1rem;
        border: 0;
        background: transparent;
        cursor: pointer;
        border-radius: 9999px;
        color: var(--muted, #71717a);
        font: inherit;
      }
      .toggle button[data-active] {
        background: var(--bg, #fff);
        color: var(--accent, #18181b);
        font-weight: 600;
        box-shadow: 0 1px 2px rgba(0, 0, 0, 0.08);
      }
      .price {
        font-family: var(--font-sans, sans-serif);
        font-size: 2.5rem;
        font-weight: 700;
        margin: 1rem 0 0;
      }
      .savings {
        color: var(--accent, #18181b);
        font-size: 0.875rem;
        margin-top: 0.25rem;
      }
    </style>
    <div class="toggle">
      <button data-active>Monthly</button>
      <button>Annual</button>
    </div>
    <p class="price">${cur}${monthly}<span style="font-size:0.5em;color:var(--muted)">/mo</span></p>
    <p class="savings">
      Switch to annual: ${cur}${annualMonthly}/mo (save ${pct}%)
    </p>
  `;
}
