# Layout Legibility — what makes or breaks a flow

**Readability beats branding.** A crossing-free flow in flat gray reads better than a beautifully-themed tangle. Layout is where most diagrams fail — spend the effort here, and verify layout (crossings, back-edges, aspect ratio) *before* styling.

## Decision table — depth × size → direction + spacing (start here; one pass, not three)

| Diagram | Direction | `nodeNodeBetweenLayers` / `spacing.nodeNode` | Notes |
|---|---|---|---|
| **L1** (≤10 nodes, ≤4 deep) | RIGHT | 80 / 55 | fits a slide easily |
| **L2** (10–25 nodes) | RIGHT, or DOWN if >6 deep | 90 / 60 | watch aspect ratio |
| **L3** (>25 nodes or ~10-deep pipeline) | **DOWN** | 70 / 45 | expect `fitView` shrink; budget a 2nd pass; **>40 edges → split feedback edges**; consider splitting into multiple diagrams |

## 1. Direction is the single biggest lever
Wide-and-shallow → **RIGHT** (reads like a timeline). Tall/deep (>~6 layers) or many nodes → **DOWN** (scrolls naturally, keeps aspect ratio near the 16:9 target instead of 4× too wide).

## 2. Preserve execution order & cut crossings (ELK layered options)
```
'elk.algorithm':'layered',
'elk.direction':'RIGHT',                                        // or 'DOWN'
'elk.layered.crossingMinimization.strategy':'LAYER_SWEEP',
'elk.layered.nodePlacement.strategy':'NETWORK_SIMPLEX',
'elk.layered.considerModelOrder.strategy':'NODES_AND_EDGES',   // keep input order → predictable reading sequence
'elk.edgeRouting':'ORTHOGONAL',
'elk.layered.spacing.nodeNodeBetweenLayers':'90',
'elk.spacing.nodeNode':'60','elk.spacing.edgeNode':'25',
```
`considerModelOrder` stops ELK scrambling steps — **feed nodes/edges in execution order** and it lays them out in that order.

## 3. Feedback / back edges (retry, loop, callback, async result) — the #1 clutter source
A back-edge drawn like a forward one slices across the whole graph. Handle it:
- **Style distinctly** — dashed, muted/secondary color, curved (not orthogonal), labelled ("retry"/"async result"). Signals "goes backward."
- **≥2 long back-edges getting messy → split them:** replace the long line with a small labelled "return" stub at the source + a matching marker at the target (off-page-style connector). Note the pairing in the label.
- Keep ELK's default cycle-breaking; don't fight it with manual positions.

## 4. Density (L3)
L3 + >~25 nodes or a ~10-deep pipeline always fights `fitView`. In order: go **DOWN** → **split feedback edges** → **group into zones** and collapse detail → **split into multiple diagrams** rather than one unreadable megagraph. **Pick the seams from the `system-discovery` BOUNDARIES list** — split at the zone/subsystem/ownership boundaries it already identified (each becomes one diagram, with the cross-boundary CONNECTIONS shown as labelled off-page connectors between them). That keeps the split principled instead of arbitrary. Tell the user when you split and why.

## 5. Verify layout, not just pixels
In Render Validation, explicitly check **edge crossings, back-edges cutting across, aspect ratio** — not only clipping/contrast. If it reads messy, **re-layout** (change direction / split feedback edges) before re-styling.
