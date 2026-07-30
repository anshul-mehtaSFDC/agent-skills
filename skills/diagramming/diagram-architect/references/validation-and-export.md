# Render Validation, Showing the User, and Export

## Showing the user (the honest loop)
You (an agent) usually **can't drive a live in-IDE preview** — so the real loop is primary:
**headless-screenshot → Read the PNG → judge it (validation below) → write the file & open it for the user.**
1. Screenshot + inspect — catch messiness *before* showing.
2. Write the `.html` to disk, open it for the user: `code <file>` (VS Code/Cursor; Live Preview/Simple Browser side panel if available), JetBrains browser preview, else system browser (`open`/`xdg-open`/`start`). Hand back the path.
3. If you **can't** screenshot AND can't open a preview: say so plainly — *"couldn't visually verify; open `<path>` and check layout/contrast"*. Never present an unseen file as validated or fake a screenshot.

## Render Validation — catch clipping & artifacts before showing
Validate pixels, not source. **Screenshot headless and Read the PNG.** **Check layout legibility FIRST (crossings, back-edges, aspect ratio — see layout.md), then clipping/contrast.** Messy layout is a re-layout, not a re-style.

Capture: `chrome --headless --screenshot=/tmp/diag.png --window-size=1600,900 --default-background-color=FFFFFFFF --virtual-time-budget=3000 file:///abs/path.html` (the budget lets JS frameworks finish), then Read the PNG.

| Artifact | Look for | Fix |
|---|---|---|
| **Edge crossings / messy flow** | Lines crisscross; can't follow order | Re-layout: `considerModelOrder`, LAYER_SWEEP, feed nodes in exec order |
| **Back-edge cutting across** | Retry/async edge slices the canvas | Style dashed+curved+labelled, or split into stub+marker |
| **Bad aspect ratio** | Too wide/tall; fights fitView | Switch RIGHT↔DOWN; split if L3-dense |
| **Text clipping** | Labels cut off by node edges | Widen nodes, wrap, size-to-text |
| **Canvas clipping** | Nodes/edges cut at outer edge | `fitView`; padding; grow viewBox |
| **Node overlap** | Boxes on top of each other | Increase ELK `spacing.nodeNode` / `nodeNodeBetweenLayers` |
| **Overflow / scrollbars** | Content exceeds viewport | Size container to content; scale down; paginate |
| **Truncated on export** | PDF/PNG cuts right/bottom | Set page size; `fitView`; export true bounds not window |
| **Legend/logo collision** | Overlapping nodes | Reserve a margin lane / empty corner |
| **Contrast/invisibility** | Light text on light fill | Fix per theming.md (WCAG AA) |
| **Font not loaded** | Boxed/fallback glyphs | Embed/CDN the font + web-safe fallback |

**Contrast:** don't eyeball — use the `checkContrast()` snippet in `../reactflow-template.html` (fill in your text/bg token pairs; logs any pair <4.5:1). Set every text color explicitly.

## Export (ask AFTER approval)
**First ask: bare diagram or framed page?** The preview HTML often has chrome (title, legend, headers).
- **Diagram only (bare)** — just the graphic *(default for slides/embeds)*.
- **Framed** — diagram + surrounding page/labels/legend.

**Match format to detail level:** **L1/L2 → PNG/PDF** fine for a slide. **L3 (dense) → SVG or interactive HTML, NOT a deck PNG** (a detailed graph shrunk to a slide PNG is unreadable — give zoomable SVG/HTML). If they insist on a PNG for L3, warn it'll be unreadable and offer to split.

| Export | How |
|---|---|
| PNG/JPG | headless-Chrome render / library `toPng()` |
| SVG | React Flow `toSvg`; D3/Cytoscape serialize `<svg>` |
| PDF | headless Chrome `--print-to-pdf` |
| Standalone HTML | the preview file itself |
| Embed | hand back SVG/PNG or iframe-able HTML |

**Diagram-only (strip chrome):** export the diagram element, not `document.body` — React Flow `toSvg`/`toPng` on `.react-flow__viewport` (fitView first; hide Panel/Controls/MiniMap/Background); D3/Cytoscape serialize the `<svg>` / `cy.png({full:true})`. Or render a minimal HTML containing only the diagram (or `@media print{.chrome{display:none}}`) and capture the clipped bounds. Trim to the true bounding box. **Re-validate the exported artifact** — it can clip or capture chrome even when the HTML looked fine.
