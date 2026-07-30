---
name: diagram-architect
description: "Use when the user asks to create, draw, generate, or design any diagram — data architecture, solution/system architecture, data flow, sequence, ER/data model, deployment topology, network, state machine, org/entity relationship, RAG/AI pipeline, or process/flow chart. Also use when they want diagrams styled/branded to a company theme (brand colors, fonts, logo extracted from a website/logo/repo), or rendered as polished HTML with React Flow + ELK / D3 / Cytoscape. Runs a short intake interview (type, detail, grounding, theme), renders an HTML preview (in-IDE where possible) for approval, then exports to the format they choose — so the diagram is presentation-grade and on-brand, not an auto-generated template."
---

# Diagram Architect

## Overview

Produce **accurate, presentation-quality diagrams** by interviewing the user first, grounding the content in a real source, rendering with the best-fit JS framework into a live HTML preview, and only asking about **export format after the user approves the look**. The failure mode this skill prevents is **guessing** — drawing a plausible-looking architecture that doesn't match what was built, or exporting before the user has seen and approved it.

**Core principle:** Ground first, draw second, **preview → approve → then export**. Don't ask export format up front — ask it only once the user likes the rendered diagram.

**REQUIRED SUB-SKILL:** For any non-trivial system (more than a handful of obvious boxes), run **`system-discovery` first** to produce a confirmed entity + connection inventory. A diagram's #1 defect is a missing or wrong *connection* — discovery is what prevents it. Draw nodes from the inventory's ENTITIES and edges from its CONNECTIONS; don't invent, don't omit. Skip discovery only for a trivial diagram you can ground in one glance.

**The deliverable is the diagram — keep everything else minimal.** The output HTML should be the diagram (plus at most a title and, only if edge types differ, a small legend). Do NOT pad the page with talking points, narrative paragraphs, bullet summaries, or restated requirements. In chat, keep prose to a few lines (what type + why, the palette source, the preview path) — the diagram carries the content, not the text around it.

## When to Use

- User says: "create a diagram", "draw the architecture", "flow chart", "data flow", "sequence diagram", "ER diagram", "deployment topology", "generate a diagram for X".
- Any request to visualize flow, structure, relationships, sequence, state, or topology.
- Documenting an implemented system, a proposed design, or a process.

**When NOT to use:** simple data charts/plots (bar/line/pie/dashboards) — use the `dataviz` skill. Rendering one trivial box-and-arrow inline in a chat answer needs no interview — just draw it.

## The Intake Interview (REQUIRED — ask before drawing)

Ask these **four questions** in a single batch (use the AskUserQuestion tool if available). Do not start drawing until answered. If the user already answered some in their request, only ask the rest. **Do NOT ask export format here** — that comes after the user approves the preview (see Workflow).

### 1. Diagram type — recommend, don't just accept
**If the user forced a specific type** ("make a sequence diagram"), use it. **Otherwise, YOU recommend the best-fit type** from the request and (once available) the discovery inventory — don't make the user pick blind. Say which and why, e.g. *"This is about order flow over time → I'd suggest a **sequence** diagram, not architecture. Good?"* Base it on what the content is:
- Ordering / "over time" / request-response / handshake → **sequence**
- Steps + decisions / a process → **flowchart**
- Components + how they connect / "the system" → **architecture**
- Entities + relationships → **ERD**
- States + transitions → **state machine**
- Where things run → **deployment/topology**

Offer the recommendation, let them override. Common types and when each fits:

| Type | Shows | Use for |
|---|---|---|
| **Solution / system architecture** | Components + how they connect across layers/zones | "the whole system", hero slide |
| **Data flow** | How data moves source → transform → destination | ETL, ingestion, unification pipelines |
| **Data model / ERD** | Entities/objects + relationships + cardinality | schemas, DMOs, table relationships |
| **Sequence** | Ordered message exchange between actors over time | API calls, auth handshakes, request/response |
| **Deployment / topology** | Where things physically run (orgs, clouds, envs) | infra, multi-org, network |
| **State machine** | States + transitions | lifecycles, status flows |
| **Process / flowchart** | Steps + decisions | runbooks, business processes |
| **AI / RAG pipeline** | Ingest → index → retrieve → generate → guardrail | LLM/agent grounding flows |

### 2. Detail level
- **High-level (L1)** — zones/layers, ~5–10 boxes, one slide. For executives/overview.
- **Component (L2)** — named components + key connections + a few labels/metrics. For architects/panels.
- **Detailed (L3)** — every object/field/endpoint, cardinalities, protocols, counts. For build/handoff/deep review.

### 3. Grounding — where does the information come from?
The single most important question. Options:
- **A specific file/doc** (e.g. an architecture .md, PLAN, runbook) → **read it before drawing.**
- **The live system** (query the org/cloud, inspect metadata) → gather facts first.
- **A prior diagram** to match/extend.
- **The user will describe it** verbally.
- **Design-only / hypothetical** (nothing to ground on yet — mark it as proposed, not as-built).

**If a grounding source exists, you MUST read/gather it before drawing.** A diagram of an implemented system that wasn't grounded is a guess — say so explicitly if the user declines to provide a source.

### 4. Visual theme / branding
How should it look? Ground the theme the same way you ground the content:
- **Company brand** — a company website URL, brand-guide URL, an existing branded deck/screenshot, a logo image, or a repo path with brand assets/CSS. → **You MUST extract the theme (Company Theming) before drawing.**
- **A prior diagram / this project's existing style** (e.g. a `Diagram_Prompts.html` or a previous slide) → reuse its palette.
- **Neutral / default** — clean modern default (one dark heading color + one bright accent).
- **User specifies** — explicit hex colors / font.

**MANDATORY when a brand is chosen — extract, don't guess, don't silently use neutral.** Source priority (reuse beats re-extraction):
1. **Check the repo / prior diagrams FIRST** — an existing HTML/slide often already has the palette baked in (`:root` vars, hex codes, font). Grep the repo for hex colors / `--primary` / font-family before anything else.
2. **Logo or screenshot image** → Read it and sample the colors.
3. **Website URL** → WebFetch — but ⚠️ **WebFetch returns rendered prose, not CSS**, so it often can't give hex codes. If it fails, fall back to reading a logo, a brand-palette site (brandcolors.net etc.), or **ask the user for the hex list.**
4. A company *name alone* is not a source — ask, or state you're using neutral and why. **Never guess a palette from memory.**

Then **echo the palette + its source back** ("#D61D23 / Montserrat ← repo's prior HTML") and apply it to every diagram. If a brand was requested, the render MUST visibly use those colors — defaulting to neutral without saying so is the #1 branding failure.

## Pre-Render Gate (STOP — answer these out loud before writing any HTML)

Do not write a single line of diagram HTML until you have **typed answers to all four** in your reply. This is a gate, not a reminder — skipping it is the failure mode this skill exists to prevent. Iteration 3 is too late.

1. **Type sanity check.** Does the chosen diagram type match the *request word*? If the user said "flow", "ordering", "sequence", "steps", "over time", "handshake" but you're about to draw an **architecture graph**, STOP — a **sequence or flowchart** is probably right. State: *"Request says '<word>' → using <type> because <reason>."* Challenge the initial type; don't treat it as settled.
2. **Theme grounding.** Write the literal palette you will use AND where each value came from: *"--primary #E31937 ← fetched tesla.com/…"*. If any value is from memory/guess → you have NOT grounded it: go WebFetch/Read the source now, or explicitly say "using neutral, no brand source given." **You may not proceed with guessed brand colors.**
3. **Inventory confirmed.** State the entity count and connection count from `system-discovery`, and that the user confirmed it (or explicitly waived discovery for a trivial diagram). Every node/edge you draw traces to a row in that inventory — no invented components, no dropped connections.
4. **Engine + detail level** chosen (per tables below).

If you cannot fill in #1 and #2 concretely, you are not ready to draw. No exceptions, no "I'll fix it on the next pass."

## Render Engine — pick the best framework (do NOT use Mermaid)

**Mermaid is banned in this skill.** Its auto-layout produces non-presentable output — cavernous whitespace, edges crossing the whole canvas, and clipped node titles. Always render an interactive, self-contained HTML with a real layout/graphics library. **React Flow + ELK is the workhorse for anything structural.** Load libraries from a CDN (esm.sh / unpkg / jsdelivr).

| Diagram type | Use this | Why |
|---|---|---|
| **Solution/system architecture, data flow, deployment, RAG pipeline, process — any node+edge diagram** | **React Flow + ELK** (`@xyflow/react` + `elkjs`) | Custom styled nodes, grouped zone containers, ELK layered layout, orthogonal edge routing, `fitView` — looks designed |
| **Large graphs / networks** (many nodes, dense relationships) | **Cytoscape.js** + ELK/cola layout | Scales to hundreds of nodes with real graph layouts |
| **Data model / ERD** | **React Flow** (custom table nodes w/ field rows + FK edges) or **D3** | Full control of table styling + cardinality markers |
| **Sequence** | **D3** (or hand-authored SVG) — lifelines + activation bars + arrows | Precise ordered layout |
| **State machine** | **React Flow + ELK** (states as nodes, labeled transition edges) | Same node/edge model, styled |
| **Timeline / Gantt** | **vis-timeline** or **D3** | Real time axis |
| **Org chart / tree / mind map** | **D3 hierarchy (tree/cluster)** | Proper hierarchical layout |

**Decision rule:** if it's nodes-and-edges → **React Flow + ELK**. If it's a huge graph → **Cytoscape + ELK**. If it's time/hierarchy/sequence → the dedicated lib above. Never fall back to Mermaid, even for a "quick" diagram — a small React Flow diagram is just as fast to author and looks far better.

**Styling** (secondary to layout — do this, but don't over-invest): branded custom nodes (rounded card, colored header bar, soft shadow) sized to their text so titles never clip; tinted zone/parent nodes with a label; every edge `smoothstep` + arrowhead + a labelled background chip; `fitView` with padding; theme tokens from Company Theming. Start from [`reactflow-template.html`](reactflow-template.html) — don't hand-roll boilerplate.

## Layout Legibility — the thing that makes or breaks a flow

**Readability beats branding.** A crossing-free flow in flat gray reads better than a beautifully-themed tangle. Layout is where most diagrams fail; spend your effort here.

**Decision table — depth × size → direction + spacing (start here, one pass instead of three):**

| Diagram | Direction | `nodeNodeBetweenLayers` / `spacing.nodeNode` | Notes |
|---|---|---|---|
| **L1** (≤10 nodes, ≤4 deep) | RIGHT | 80 / 55 | fits a slide easily |
| **L2** (10–25 nodes) | RIGHT, or DOWN if >6 deep | 90 / 60 | watch aspect ratio |
| **L3** (>25 nodes or ~10-deep pipeline) | **DOWN** | 70 / 45 | expect `fitView` shrink; budget a 2nd layout pass; **>40 edges → split feedback edges**; consider splitting into multiple diagrams |

**1. Direction is the single biggest lever:** wide-and-shallow → **RIGHT** (reads like a timeline); tall/deep (>~6 layers) or many nodes → **DOWN** (scrolls naturally, keeps aspect ratio near the 16:9 target instead of 4× too wide).

**2. Preserve execution order & cut crossings** (ELK layered options):
```
'elk.layered.crossingMinimization.strategy':'LAYER_SWEEP',
'elk.layered.nodePlacement.strategy':'NETWORK_SIMPLEX',
'elk.layered.considerModelOrder.strategy':'NODES_AND_EDGES',  // keep input order → predictable reading sequence
'elk.edgeRouting':'ORTHOGONAL',
'elk.layered.spacing.nodeNodeBetweenLayers':'90',
'elk.spacing.nodeNode':'60', 'elk.spacing.edgeNode':'25',
```
`considerModelOrder` is what stops ELK from scrambling steps — feed nodes/edges in execution order and it lays them out in that order.

**3. Feedback / back edges (retry, loop, callback, async result)** are the #1 clutter source — a back-edge drawn like a forward one cuts across the whole graph. Handle them:
- **Style them distinctly** — dashed, a muted/secondary color, curved (not orthogonal), labelled ("retry"/"async result"). Signals "this goes backward."
- **If ≥2 long back-edges make it messy → split them:** replace the edge with a small labelled "return" stub at the source and a matching marker at the target (an off-page-style connector) instead of one long line across the canvas. Note the pairing in the label.
- Keep ELK's default cycle-breaking; don't fight it with manual positions.

**4. Density (L3):** L3 + >~25 nodes or a ~10-deep pipeline will always fight `fitView`. Options, in order: go **DOWN**; **split feedback edges** (#3); **group into zones** and collapse detail; or **split into multiple diagrams** (one per subsystem) rather than one unreadable megagraph. Tell the user when you split and why.

**5. Verify layout, not just pixels:** in Render Validation, explicitly check **edge crossings, back-edges cutting across, and aspect ratio** — not only clipping/contrast. If it reads messy, re-layout (change direction / split feedback edges) before re-styling.

## Workflow — preview → approve → export

1. **Interview** (the 4 questions above). Batch them. Do NOT ask export format yet.
1b. **Discover the system** (non-trivial diagrams) — run **`system-discovery`**: read all relevant sources, build the entity + connection inventory, gap-hunt, and **confirm it with the user.** The diagram draws from this inventory. Skip only for a trivially small diagram.
1c. **Diff mode (if a diagram already exists)** — do NOT blindly re-emit it. Re-verify each node and edge against the *current* source, and surface what changed (added/removed/wrong/unverified). Re-drawing an existing diagram is a chance to catch drift, not a copy job — the discovery pass often finds the old diagram was already wrong.
2. **Ground the CONTENT** — this is satisfied by the discovery inventory (entities/connections with their sources). If you skipped discovery, still read the named file / query the system; never proceed on memory when a source exists.
2b. **Ground the THEME (if a brand was chosen)** — **actually call WebFetch on the URL, or Read the logo/repo/CSS.** Extract hex colors + font + logo and **echo them back to the user.** Do NOT skip this and do NOT silently fall back to neutral (see Company Theming). If no source was given, ask for one or state you're using neutral.
2c. **Clear the Pre-Render Gate** — post typed answers to all four gate items (type sanity, grounded palette, content source, engine+detail). Do not write HTML until this is in your reply.
3. **Pick the render engine** for the diagram type (table above).
4. **Build a self-contained HTML** rendering the diagram with that framework + the extracted theme spec (the brand colors/font must be visibly applied). **Label edges** with what flows (protocol, trigger, cadence, "batch" vs "live") — unlabeled arrows are the #1 clarity loss.
5. **Verify against the source** — every box/edge traces to a grounded fact; the brand palette is actually applied. Flag anything inferred or proposed-vs-built.
6. **Validate the render for clipping & artifacts** (see Render Validation) — screenshot the HTML headless, inspect for cut-off text/nodes, overflow, overlaps, broken edges. Fix before showing the user. Do NOT surface a preview you haven't visually checked.
7. **Show the user the HTML output** — write the file and **open a live preview in the IDE where possible** (see IDE Preview), else open in the browser / tell them the path. Present it as a **preview for approval**, not a final deliverable.
8. **Iterate** on their feedback (layout, labels, colors, detail) — re-render **and re-validate** the HTML until they approve.
9. **Only after approval, ask what to export as** — including **bare diagram vs framed page** (see Export options) — produce it, then **re-validate the exported artifact** (a PDF/PNG can clip, or capture unwanted page chrome/frontmatter, even when the HTML looked fine).

### Export options (ask AFTER approval)

**First ask: bare diagram, or the framed page?** The preview HTML often has chrome —
page title, talking points, headers, legends, and the source may carry frontmatter.
Always ask whether they want:
- **Diagram only (bare)** — just the diagram graphic, nothing else. *(default for slides/embeds)*
- **Framed** — diagram plus its surrounding page/labels/legend.

Then the format:

| Export | Best for | How |
|---|---|---|
| **PNG / JPG** | Slides, docs, Slack | Headless-Chrome render / library `toPng()` |
| **SVG** | Crisp scaling, Figma, print | React Flow `toSvg`; D3/Cytoscape serialize `<svg>` |
| **PDF** | Handout, one-pager | Headless Chrome `--print-to-pdf` on the HTML |
| **Standalone HTML** | Interactive share, living doc | The preview file itself |
| **Embed in deck/site** | Presentation | Hand back the SVG/PNG or an iframe-able HTML |

**Match format to detail level:** **L1/L2 → PNG/PDF** is fine for a slide. **L3 (dense) → SVG or interactive HTML, NOT a deck PNG** — a detailed graph shrunk to a slide PNG is unreadable; give a zoomable SVG or the HTML so the viewer can pan/zoom. If they insist on a PNG for an L3, warn it'll be unreadable and offer to split it.

**How to export the DIAGRAM ONLY (strip all chrome):**
- **Isolate the element, not the page.** Export the diagram node itself, not `document.body`:
  - React Flow → `toSvg`/`toPng` (from `html-to-image`, which React Flow uses) targeting the `.react-flow__viewport` (call `fitView` first); hide `Panel`/`Controls`/`MiniMap`/`Background` before capture.
  - D3/Cytoscape → serialize the `<svg>` / `cy.png({full:true})` — the graphic only.
- **Bare-page render for PDF/PNG:** render the diagram into a minimal HTML that contains *only* the diagram element (no `<h1>`, talking points, or legend) — or set `@media print { .chrome { display:none } }` and print just the diagram container — then headless-Chrome capture the clipped bounds, not the window.
- **Trim whitespace/margins** to the diagram's true bounding box (`fitView`, tight `viewBox`, `--force-device-scale-factor` for crisp PNG). Re-validate the exported file for clipping (Render Validation).

## Showing the user (the honest loop)

You (an agent) usually **can't drive a live in-IDE preview** — so the real loop is: **headless-screenshot → Read the PNG → judge it yourself (Render Validation) → write the file and open it for the user.** Treat that as primary.

1. Screenshot + inspect (Render Validation) — this is how you catch messiness *before* showing.
2. Write the `.html` to disk and open it for the user: VS Code/Cursor `code <file>` (or Live Preview/Simple Browser side panel if available), JetBrains browser preview, else system browser (`open`/`xdg-open`/`start`). Hand back the path.
3. If you **cannot** screenshot AND cannot open a preview, say so plainly — *"I couldn't visually verify this; open `<path>` and check layout/contrast"* — never present an unseen file as validated or fake a screenshot.

That's the approval gate (workflow step 7).

## Render Validation — catch clipping & artifacts before showing

A diagram that renders "mostly right" but clips a label, overlaps nodes, or has edges crossing everywhere reads as broken. Validate the actual pixels, not just the source. **Screenshot the HTML headless and inspect it** — don't trust that valid source = clean render. **Check layout legibility first (crossings, back-edges, aspect ratio — see Layout Legibility), then clipping/contrast.** Messy layout is a re-layout, not a re-style.

**How to capture a screenshot to inspect:**
- Headless Chrome: `chrome --headless --screenshot=/tmp/diag.png --window-size=1600,900 --default-background-color=FFFFFFFF file:///abs/path.html` (give the page a moment / use `--virtual-time-budget=3000` so JS-rendered frameworks finish).
- Or a browser-automation tool (screenshot the opened file). Then **Read the PNG** and look at it.

**Checklist — look for each:**

| Artifact | What to look for | Typical fix |
|---|---|---|
| **Text clipping** | Labels cut off by node/box edges; ellipsis where there shouldn't be | Widen nodes, reduce font, wrap text, `overflow: visible` |
| **Edge crossings / messy flow** | Lines crisscrossing; can't follow execution order | Re-layout: `considerModelOrder`, LAYER_SWEEP; feed nodes in execution order (Layout Legibility) |
| **Back-edge cutting across** | A retry/async/loop edge slices the whole canvas | Style it dashed+curved+labelled, or split it into stub+marker |
| **Bad aspect ratio** | Too wide (RIGHT) or too tall — fights the slide/fitView | Switch direction (RIGHT↔DOWN); split into multiple diagrams if L3-dense |
| **Canvas clipping** | Nodes/edges cut at the diagram's outer edge | Fit-to-view (`fitView` / `d3 zoom-to-fit`); add padding/margin; grow viewBox |
| **Node overlap** | Boxes on top of each other; unreadable | Increase ELK spacing (`spacing.nodeNode`, `layered.spacing.nodeNodeBetweenLayers`) |
| **Edge issues** | Arrows crossing through nodes, missing arrowheads, overlapping labels | Reroute (orthogonal/curved), bump edge separation, offset edge labels |
| **Cut edge labels** | Text on a line running off-canvas or under a node | Shorten label, add background, reposition |
| **Overflow / scrollbars** | HTML shows scrollbars = content exceeds viewport | Size container to content; scale down; paginate an L3 into sections |
| **Truncated on export** | PDF/PNG cuts the right/bottom that HTML showed | Set page size/orientation; `fitView`; export at the diagram's true bounds not the window's |
| **Legend/logo collision** | Legend or logo overlapping nodes | Reserve a margin lane; move to an empty corner |
| **Contrast/invisibility** | Light text on light fill; edges invisible on background | Fix per theme accessibility rule (WCAG AA) |
| **Font not loaded** | Fallback/boxed glyphs (brand font failed to load) | Embed/CDN the font; add web-safe fallback |
| **Overlapping at small sizes** | Fine at full size, collides in the slide thumbnail | Test at target display size, not just full res |

**Contrast:** don't eyeball it — use the **`checkContrast()` WCAG snippet in `reactflow-template.html`** (fill it with your actual text/bg token pairs; it logs any pair below 4.5:1 to the console). And **set every text color explicitly** (node header, body, edge label, zone label) — React Flow/D3/Cytoscape all have default-color surprises, so a themed background + unset label color = invisible text.

## Company Theming — ground the look on a brand

You can theme an entire diagram set to a company's brand so it looks like it came from their design team. Steps:

**1. Extract a theme spec.** Pull brand attributes from whatever the user provides:
- **Website URL / brand guide** → WebFetch it; read the CSS/brand page for hex colors and font family.
- **Logo or screenshot image** → Read the image; sample the dominant/accent colors and note the typeface style.
- **Existing branded deck / prior diagram** → reuse its exact palette and fonts.
- **Just a company name** → use its well-known brand colors if you know them confidently; otherwise ask for a source rather than guessing (a wrong brand color is worse than a neutral one).

**2. Record it as a reusable theme spec** — then apply the SAME spec to every diagram:

| Token | Example | Use |
|---|---|---|
| `--primary` | brand core color | headings, primary boxes |
| `--accent` | bright brand secondary | connectors/arrows, emphasis |
| `--zone-bg` | light tint of primary | group/zone containers |
| `--card` | white / off-white | component cards |
| `--text` | near-black | body text (check contrast) |
| `--font` | brand typeface (web-safe fallback) | all labels |
| `logo` | logo file/URL | corner of HTML/SVG output |

**3. Apply consistently:** white rounded cards + soft shadows; `--primary` headings; `--accent` arrowheads on **every** edge; `--zone-bg` containers; brand font; left-to-right or top-down flow; 16:9-friendly; a legend when edge types differ (batch vs live, sync vs async). Place the logo discreetly (a corner), never overpowering the content.

**4. Accessibility:** verify text/background contrast meets ~WCAG AA even in brand colors; if a brand color fails on white, darken it for text and keep the true brand color for fills only.

**5. Reuse:** save the theme spec as a CSS `:root` block (custom properties) and reference the tokens in the React Flow node/edge styles, so the whole set — and future diagrams — stay identical.

```css
:root {
  --primary:#0b3d6b; --accent:#1b7ce0; --zone-bg:#e8f2ff;
  --card:#ffffff; --text:#12222f; --font:'BrandFont', Arial, sans-serif;
}
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Drawing before grounding | Read the source / query the system first — always |
| Skipping the detail-level question | L1 vs L3 are totally different diagrams; ask |
| Unlabeled arrows | Label every edge with what flows + how (protocol/trigger/cadence) |
| Presenting a guess as as-built | Mark inferred/proposed elements explicitly |
| Wrong tool for charts | Bar/line/pie → use `dataviz`, not this skill |
| One giant L3 when they wanted L1 | Match altitude to audience; offer to drill down separately |
| Inventing component/object names | Use exact names from the grounding source |
| Guessing a company's brand colors | Extract from URL/logo/deck; if unknown, ask — a wrong brand color is worse than neutral |
| Brand color fails contrast on white | Darken for text; keep true brand color for fills only (WCAG AA) |
| Inconsistent theme across a set | Save one theme spec; apply identically to every diagram |
| Asking export format up front | Ask it only AFTER the user approves the HTML preview |
| Exporting before the user has seen it | Always show the HTML preview and get approval first |
| Using Mermaid at all | Banned — its auto-layout isn't presentable. Use React Flow + ELK (or Cytoscape/D3). Start from `reactflow-template.html` |
| Theming from memory / guessed brand colors | Clear the Pre-Render Gate: every palette value must name its source; guessed = not grounded, go fetch it |
| Drawing the type the user first named without challenge | Pre-Render Gate #1: if the request word ("flow"/"sequence") conflicts with the type, propose the better one |
| Drawing before mapping the system | Run `system-discovery` first; draw from its confirmed entity + connection inventory |
| Missing a real connection / inventing one | Every edge traces to a CONNECTION row; every node to an ENTITY row — discovery's gap-hunt catches omissions |
| Passing Render Validation with a skim | Do the per-element contrast pass — list every text element's fill vs background; fix every ✗ |
| Unset text color on a themed background (invisible text) | Set text fill/color EXPLICITLY for node header/body, edge labels, zone labels — never rely on library defaults |
| Claiming validated when preview tooling was down | Say you couldn't verify; hand back the path with "please open to check" — don't fake a screenshot |
| Brand requested but render came out neutral | You didn't extract the theme — MUST WebFetch the URL / Read the logo/repo, echo the palette, then apply it |
| Extracted a theme but didn't apply it | The render must visibly use the brand hex/font; verify in step 5 |
| Assuming valid source = clean render | Screenshot and inspect pixels; validate for clipping/overlap before showing |
| Clipped/overlapping nodes shipped as final | Run Render Validation; fit-to-view + auto-layout spacing |
| Export clips what HTML showed | Re-validate the exported PDF/PNG; set page size + export true bounds |
| Claiming "looks good" without seeing it | If you can't screenshot, say so and ask the user to check clipping/overlap |
| Export captured page chrome (title/talking points/legend) | Offer "diagram only (bare)" export; isolate the diagram element, not the page |
| Emitted source with YAML frontmatter | Strip the `---` frontmatter + prose; output only the diagram graphic or raw SVG |
| Padding the page/chat with talking points or restated requirements | Deliverable is the diagram; page = diagram + title + optional small legend; chat prose = a few lines |
| Accepting the user's type without recommending | If not forced, recommend the best-fit type from context and say why (gate #1) |

## Real-World Impact

Grounding an end-to-end data architecture diagram in the actual PLAN/runbooks (not memory) surfaced real specifics — exact object names, record counts, cross-org boundaries — that a generic template would have gotten wrong. The interview also prevents wasted renders: knowing "L1 for a 15-min exec talk" vs "L3 for engineering handoff" up front means one correct diagram instead of three revisions.
