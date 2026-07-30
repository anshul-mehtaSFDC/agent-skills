---
name: diagram-architect
description: "Use when the user asks to create, draw, generate, or design any diagram — data architecture, solution/system architecture, data flow, sequence, ER/data model, deployment topology, network, state machine, org/entity relationship, RAG/AI pipeline, or process/flow chart. Also use when they want diagrams styled/branded to a company theme (brand colors, fonts, logo), or rendered as polished HTML with React Flow / Mermaid / D3. Runs a short intake interview (type, detail, grounding, theme), renders an HTML preview for approval, then exports to the format they choose — so the diagram matches what was built and the brand, not a generic template."
---

# Diagram Architect

## Overview

Produce **accurate, presentation-quality diagrams** by interviewing the user first, grounding the content in a real source, rendering with the best-fit JS framework into a live HTML preview, and only asking about **export format after the user approves the look**. The failure mode this skill prevents is **guessing** — drawing a plausible-looking architecture that doesn't match what was built, or exporting before the user has seen and approved it.

**Core principle:** Ground first, draw second, **preview → approve → then export**. Don't ask export format up front — ask it only once the user likes the rendered diagram.

## When to Use

- User says: "create a diagram", "draw the architecture", "flow chart", "data flow", "sequence diagram", "ER diagram", "deployment topology", "generate a diagram for X".
- Any request to visualize flow, structure, relationships, sequence, state, or topology.
- Documenting an implemented system, a proposed design, or a process.

**When NOT to use:** simple data charts/plots (bar/line/pie/dashboards) — use the `dataviz` skill. Rendering one trivial box-and-arrow inline in a chat answer needs no interview — just draw it.

## The Intake Interview (REQUIRED — ask before drawing)

Ask these **four questions** in a single batch (use the AskUserQuestion tool if available). Do not start drawing until answered. If the user already answered some in their request, only ask the rest. **Do NOT ask export format here** — that comes after the user approves the preview (see Workflow).

### 1. Diagram type
What kind of diagram? Common types and when each fits:

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
- **Company brand** — name a company or paste a brand guide / website URL / an existing branded deck or screenshot / a logo image. → **Extract the theme before drawing** (see Company Theming below). Build a reusable theme spec so *every* diagram in the set looks identical.
- **A prior diagram / this project's existing style** (e.g. a `Diagram_Prompts.html` or a previous slide) → reuse its palette.
- **Neutral / default** — clean modern default (one dark heading color + one bright accent).
- **User specifies** — explicit hex colors / font.

Apply the chosen theme consistently across a whole diagram set — a mismatched palette between slides reads as unfinished.

## Render Engine — pick the best JS framework for the diagram type

For **visually appealing** output, render an interactive HTML using the framework best suited to the diagram type. Default to **Mermaid** (fast, no build step, themable) unless the type below calls for a richer library. Load libraries from a CDN in a self-contained HTML file.

| Diagram type | Best framework | Why | CDN |
|---|---|---|---|
| Solution/system architecture, node-graphs, custom nodes | **React Flow** | Beautiful custom node components, handles, auto-layout, pan/zoom; best for polished architecture | `reactflow` (+ React) via esm.sh/unpkg |
| Data flow, process, RAG pipeline, quick architecture | **Mermaid** | Zero-build, text-driven, themable; great default | `mermaid` (jsdelivr) |
| Data model / ERD | **Mermaid `erDiagram`** or **dbdiagram-style** | Native entities + cardinality | `mermaid` |
| Sequence | **Mermaid `sequenceDiagram`** | Purpose-built, clean | `mermaid` |
| State machine | **Mermaid `stateDiagram-v2`** or **XState viz** | Transitions; XState if it's a real state machine spec | `mermaid` |
| Large graphs, network, force/relationship maps | **Cytoscape.js** or **D3** | Handles many nodes, layouts, interactivity | `cytoscape` / `d3` |
| Timeline / Gantt | **Mermaid `gantt`** or **vis-timeline** | Time axes | `mermaid` / `vis-timeline` |
| Org chart / tree / mind map | **Mermaid `mindmap`** or **D3 tree** | Hierarchies | `mermaid` / `d3` |

Rule of thumb: **Mermaid for speed and standard types; React Flow for a premium, custom-styled architecture hero diagram; Cytoscape/D3 when node count or interactivity is high.** Match the chosen theme spec (Company Theming) into the framework's styling.

## Workflow — preview → approve → export

1. **Interview** (the 4 questions above). Batch them. Do NOT ask export format yet.
2. **Ground:** read the named file / query the system / review the prior diagram. Extract real names, counts, relationships. Do not proceed on memory if a source exists. **If a company theme was named, extract the theme spec now** (see Company Theming).
3. **Pick the render engine** for the diagram type (table above).
4. **Build a self-contained HTML** rendering the diagram with that framework + the theme spec. **Label edges** with what flows (protocol, trigger, cadence, "batch" vs "live") — unlabeled arrows are the #1 clarity loss.
5. **Verify against the source** — every box/edge traces to a grounded fact. Flag anything inferred or proposed-vs-built.
6. **Validate the render for clipping & artifacts** (see Render Validation) — screenshot the HTML headless, inspect for cut-off text/nodes, overflow, overlaps, broken edges. Fix before showing the user. Do NOT surface a preview you haven't visually checked.
7. **Show the user the HTML output** (write the file, tell them to open it / open it for them). Present it as a **preview for approval**, not a final deliverable.
8. **Iterate** on their feedback (layout, labels, colors, detail) — re-render **and re-validate** the HTML until they approve.
9. **Only after approval, ask what to export as** (see Export options) and produce it — then **re-validate the exported artifact** (a PDF/PNG can clip even when the HTML looked fine).

### Export options (ask AFTER approval)
| Export | Best for | How |
|---|---|---|
| **PNG / JPG** | Slides, docs, Slack | Screenshot the HTML / headless-Chrome render / library `toImage()` |
| **SVG** | Crisp scaling, Figma, print | Mermaid/D3/Cytoscape export SVG; React Flow via `toSvg` |
| **PDF** | Handout, one-pager | Headless Chrome `--print-to-pdf` on the HTML |
| **Standalone HTML** | Interactive share, living doc | The preview file itself |
| **Mermaid/source in .md** | Editable living docs, GitHub | Emit the source block |
| **Embed in deck/site** | Presentation | Hand back the SVG/PNG or an iframe-able HTML |

## Quick Reference — Mermaid types

```
flowchart LR / TD      → architecture, data flow, process, RAG pipeline
sequenceDiagram        → API calls, handshakes, request/response
erDiagram              → data model / ERD (entities + cardinality)
stateDiagram-v2        → state machines / lifecycles
C4Context / C4Container→ formal architecture (if C4 wanted)
```

Minimal grounded example (component-level data flow):
```mermaid
flowchart LR
  subgraph SRC["Sources"]
    A["System A<br/>(real name · count)"]
  end
  subgraph HUB["Processing"]
    T["Transform"]
  end
  A -->|"batch · nightly"| T --> OUT["Destination"]
```

## Render Validation — catch clipping & artifacts before showing

A diagram that renders "mostly right" but clips a label or overlaps two nodes reads as broken. Validate the actual pixels, not just the source. **Screenshot the HTML headless and inspect it** — don't trust that valid source = clean render.

**How to capture a screenshot to inspect:**
- Headless Chrome: `chrome --headless --screenshot=/tmp/diag.png --window-size=1600,900 --default-background-color=FFFFFFFF file:///abs/path.html` (give the page a moment / use `--virtual-time-budget=3000` so JS-rendered frameworks finish).
- Or a browser-automation tool (screenshot the opened file). Then **Read the PNG** and look at it.

**Checklist — look for each:**

| Artifact | What to look for | Typical fix |
|---|---|---|
| **Text clipping** | Labels cut off by node/box edges; ellipsis where there shouldn't be | Widen nodes, reduce font, wrap text, `overflow: visible` |
| **Canvas clipping** | Nodes/edges cut at the diagram's outer edge | Fit-to-view (`fitView` / `d3 zoom-to-fit`); add padding/margin; grow viewBox |
| **Node overlap** | Boxes on top of each other; unreadable | Increase layout spacing (rank/node sep); use auto-layout (dagre/elk) |
| **Edge issues** | Arrows crossing through nodes, missing arrowheads, overlapping labels | Reroute (orthogonal/curved), bump edge separation, offset edge labels |
| **Cut edge labels** | Text on a line running off-canvas or under a node | Shorten label, add background, reposition |
| **Overflow / scrollbars** | HTML shows scrollbars = content exceeds viewport | Size container to content; scale down; paginate an L3 into sections |
| **Truncated on export** | PDF/PNG cuts the right/bottom that HTML showed | Set page size/orientation; `fitView`; export at the diagram's true bounds not the window's |
| **Legend/logo collision** | Legend or logo overlapping nodes | Reserve a margin lane; move to an empty corner |
| **Contrast/invisibility** | Light text on light fill; edges invisible on background | Fix per theme accessibility rule (WCAG AA) |
| **Font not loaded** | Fallback/boxed glyphs (brand font failed to load) | Embed/CDN the font; add web-safe fallback |
| **Overlapping at small sizes** | Fine at full size, collides in the slide thumbnail | Test at target display size, not just full res |

**Rule:** if you can't screenshot/inspect in this environment, say so and ask the user to eyeball the preview specifically for clipping/overlap — don't claim it's clean unseen.

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

**5. Reuse:** save the theme spec (e.g. as a CSS `:root` block or a Mermaid `themeVariables` object) so the whole set — and future diagrams — stay identical. For a reusable style-header + per-diagram-prompt pattern, mirror the project's `data/presentation/Diagram_Prompts.html` if present.

Mermaid honors a theme inline:
```
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#0b3d6b','primaryTextColor':'#fff','lineColor':'#1b7ce0','fontFamily':'BrandFont, Arial'}}}%%
flowchart LR
  ...
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
| Defaulting to Mermaid for a premium hero diagram | Use React Flow (or D3/Cytoscape) when the look/interactivity warrants it |
| Assuming valid source = clean render | Screenshot and inspect pixels; validate for clipping/overlap before showing |
| Clipped/overlapping nodes shipped as final | Run Render Validation; fit-to-view + auto-layout spacing |
| Export clips what HTML showed | Re-validate the exported PDF/PNG; set page size + export true bounds |
| Claiming "looks good" without seeing it | If you can't screenshot, say so and ask the user to check clipping/overlap |

## Real-World Impact

Grounding an end-to-end data architecture diagram in the actual PLAN/runbooks (not memory) surfaced real specifics — exact object names, record counts, cross-org boundaries — that a generic template would have gotten wrong. The interview also prevents wasted renders: knowing "L1 for a 15-min exec talk" vs "L3 for engineering handoff" up front means one correct diagram instead of three revisions.
