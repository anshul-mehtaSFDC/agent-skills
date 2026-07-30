---
name: diagram-architect
description: "Use when the user asks to create, draw, generate, or design any diagram — data architecture, solution/system architecture, data flow, sequence, ER/data model, deployment topology, network, state machine, org/entity relationship, RAG/AI pipeline, or process/flow chart. Also use when they want diagrams styled/branded to a company theme (colors, fonts, logo from a website/logo/repo), or rendered as polished HTML with React Flow + ELK / D3 / Cytoscape. Runs a short intake interview, maps the system, renders an HTML preview for approval, then exports — presentation-grade and on-brand, not an auto-generated template."
---

# Diagram Architect

Produce **accurate, presentation-quality diagrams**: interview → ground → draw with a real framework → validate the pixels → preview for approval → export. The failure this prevents is **guessing** — a plausible diagram that doesn't match what was built, is unreadable, or ships unseen.

**Core principle:** Ground first, draw second, **preview → approve → then export.** Readability beats branding. Mermaid is banned (see [render-engine](references/render-engine.md)).

**REQUIRED SUB-SKILL:** for any non-trivial system, run **`system-discovery` first** — draw nodes from its confirmed ENTITIES and edges from its CONNECTIONS; don't invent, don't omit. A missing/wrong *connection* is a diagram's #1 defect.

**Deliverable = the diagram.** Output HTML is the diagram + at most a title and (if edge types differ) a small legend. No talking points, narrative, or restated requirements on the page. In chat, a few lines (type+why, palette+source, preview path) — the diagram carries the content.

## Reference files — load the one you need, when you need it

| Read this file | When |
|---|---|
| [references/render-engine.md](references/render-engine.md) | choosing the framework / how to build the HTML (React Flow+ELK, etc.) |
| [references/layout.md](references/layout.md) | **before drawing a flow** — direction, crossing reduction, feedback edges, density (the #1 quality lever) |
| [references/theming.md](references/theming.md) | any brand/theme work — extraction sources, WebFetch-can't-read-CSS caveat, contrast |
| [references/validation-and-export.md](references/validation-and-export.md) | before showing (screenshot loop + validation checklist) and for export options |
| [reactflow-template.html](reactflow-template.html) | starting the render — adapt it, don't hand-roll |

## When NOT to use
Simple data charts/plots (bar/line/pie/dashboards) → use the `dataviz` skill. A trivial inline box-and-arrow → just draw it.

## Intake Interview (ask before drawing, batch the questions)
Ask these in one batch (AskUserQuestion if available). **Do NOT ask export format yet** — that's post-approval.

1. **Diagram type — recommend, don't just accept.** If the user forced a type, use it. Otherwise **recommend the best-fit** from the request + discovery inventory and say why: ordering/"over time"/request-response → **sequence**; steps+decisions → **flowchart**; components+connections → **architecture**; entities+relationships → **ERD**; states+transitions → **state machine**; where things run → **deployment**. Offer it; let them override.
2. **Detail level.** L1 (zones, ≤10 boxes, exec) · L2 (named components + key connections) · L3 (every object/endpoint/count, for handoff).
3. **Grounding source.** File/doc · live system · prior diagram · verbal · design-only (mark proposed). If a source exists you MUST read it — never draw from memory.
4. **Theme.** Brand (→ [theming.md](references/theming.md), extract before drawing) · prior diagram's palette · neutral · explicit hex.

## Workflow
1. **Interview** (above).
1b. **Discover** (non-trivial) — run `system-discovery`: sources → entity+connection inventory → gap-hunt → **confirm with user**. Draw from it.
1c. **Diff mode** (diagram already exists) — don't re-emit; re-verify each node/edge vs current source, surface what changed.
2. **Ground content** (satisfied by the inventory) **+ theme** (extract per [theming.md](references/theming.md); echo palette+source).
3. **Clear the Pre-Render Gate** (below) — post the answers in your reply.
4. **Read [layout.md](references/layout.md) + [render-engine.md](references/render-engine.md)**, build a self-contained HTML from [reactflow-template.html](reactflow-template.html). Label every edge (what flows / trigger / cadence).
5. **Validate** per [validation-and-export.md](references/validation-and-export.md) — screenshot, Read the PNG, check **layout first** (crossings/back-edges/aspect), then clipping/contrast. Fix before showing.
6. **Show** via the honest loop (screenshot→judge→open file); it's the approval gate.
7. **Iterate** — re-render **and re-validate** until approved.
8. **After approval, ask export** (bare vs framed, format by detail level) → produce → **re-validate the artifact**.

## Pre-Render Gate (STOP — type these answers before writing any HTML)
Not a reminder — a gate. Skipping it is the failure this skill exists to prevent; iteration 3 is too late.
1. **Type sanity** — does the type match the request word? If they said "flow"/"sequence" but you're drawing architecture, STOP and reconsider. State: *"Request says '<word>' → <type> because <reason>."*
2. **Theme grounded** — write the literal palette + where each value came from. Any value from memory = not grounded: go extract it, or say "neutral, no source." **No guessed brand colors.**
3. **Inventory confirmed** — entity count + connection count from `system-discovery`, user-confirmed (or discovery explicitly waived as trivial). Every node/edge traces to a row.
4. **Engine + detail level** chosen.

If you can't fill in #1 and #2 concretely, you're not ready to draw.

## Common Mistakes
| Mistake | Fix |
|---|---|
| Using Mermaid | Banned — React Flow+ELK / Cytoscape / D3. Start from `reactflow-template.html` |
| Messy layout / crossings / back-edges cutting across | Layout is the #1 lever — read [layout.md](references/layout.md); fix layout before styling |
| Drawing before mapping the system | Run `system-discovery`; draw from the confirmed inventory |
| Missing/invented connection | Every edge = a CONNECTION row, every node = an ENTITY row |
| Blindly re-emitting an existing diagram | Diff mode — re-verify vs current source, surface changes |
| Theming from memory / guessed colors | Gate #2: every value names its source ([theming.md](references/theming.md)) |
| Brand requested but render came out neutral | You didn't extract — repo→logo→WebFetch(fails on CSS)→ask; echo + apply |
| Accepting the user's type without recommending | Recommend best-fit + why (interview #1) |
| Claiming validated when you couldn't see it | Screenshot+Read the PNG; if impossible, say so — never fake it |
| Export clips / captures page chrome | Re-validate the artifact; bare-diagram export strips chrome |
| Padding the page/chat with prose | Deliverable is the diagram; keep text minimal |
