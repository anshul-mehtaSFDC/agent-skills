# Company Theming — ground the look on a brand

Theme a diagram set to a brand so it looks like it came from their design team. **Extract, don't guess.**

## Extract a theme spec — source priority (reuse beats re-extraction)
1. **Check the repo / prior diagrams FIRST** — an existing HTML/slide often already has the palette baked in (`:root` vars, hex codes, font). Grep for hex colors / `--primary` / `font-family` before anything else.
2. **Logo or screenshot image** → Read it and sample the dominant/accent colors + typeface style.
3. **Website URL** → WebFetch — but ⚠️ **WebFetch returns rendered prose, not CSS**, so it often can't give hex codes. If it fails: read a logo, use a brand-palette site (brandcolors.net etc.), or **ask the user for the hex list.**
4. A company *name alone* is not a source — ask, or say you're using neutral and why. **Never guess a palette from memory.**

Then **echo the palette + its source back** ("#D61D23 / Montserrat ← repo's prior HTML"). If a brand was requested, the render MUST visibly use those colors — silently defaulting to neutral is the #1 branding failure.

## Theme spec — apply the SAME tokens to every diagram

| Token | Use |
|---|---|
| `--primary` | headings, node header bar |
| `--accent` | edges/arrows, emphasis |
| `--zone-bg` | group/zone containers (light tint of primary) |
| `--card` | node body (white/off-white) |
| `--text` | body text (check contrast) |
| `--font` | brand typeface + web-safe fallback |
| `logo` | discreet corner of the output |

```css
:root{ --primary:#0b3d6b; --accent:#1b7ce0; --zone-bg:#e8f2ff;
  --card:#ffffff; --text:#12222f; --font:'BrandFont',Arial,sans-serif; }
```

## Accessibility
Verify text/background contrast meets WCAG AA even in brand colors — use the `checkContrast()` helper in `../reactflow-template.html`. If a brand color fails on white, **darken it for text** and keep the true brand color for **fills only**. **Set every text color explicitly** (node header, body, edge label, zone label) — React Flow/D3/Cytoscape have default-color surprises, so a themed background + unset label color = invisible text.
