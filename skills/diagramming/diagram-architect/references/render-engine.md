# Render Engine — pick the framework (do NOT use Mermaid)

**Mermaid is banned.** Its auto-layout produces non-presentable output — cavernous whitespace, edges crossing the whole canvas, clipped titles. Always render a self-contained interactive HTML with a real layout/graphics library, loaded from a CDN (esm.sh / unpkg / jsdelivr). **React Flow + ELK is the workhorse.**

| Diagram type | Use this |
|---|---|
| Architecture, data flow, deployment, RAG pipeline, process — any node+edge diagram | **React Flow + ELK** (`@xyflow/react` + `elkjs`) |
| Large graphs / networks (many nodes) | **Cytoscape.js** + ELK/cola layout |
| Data model / ERD | **React Flow** custom table nodes + FK edges, or **D3** |
| Sequence | **D3** or hand-authored SVG — lifelines + activation bars + arrows |
| State machine | **React Flow + ELK** (states = nodes, labelled transition edges) |
| Timeline / Gantt | **vis-timeline** or **D3** |
| Org chart / tree / mind map | **D3 hierarchy (tree/cluster)** |

**Decision rule:** nodes-and-edges → React Flow + ELK; huge graph → Cytoscape + ELK; time/hierarchy/sequence → the dedicated lib. Never fall back to Mermaid, even for a "quick" one — a small React Flow diagram is just as fast and looks far better.

**Styling** (secondary to layout — do it, don't over-invest): branded custom nodes (rounded card, colored header bar, soft shadow) **sized to their text so titles never clip**; tinted zone/parent nodes with a label; every edge `smoothstep` + arrowhead + labelled background chip; `fitView` with padding; theme tokens from theming.md.

**Start from [`../reactflow-template.html`](../reactflow-template.html)** — CDN imports, ELK layout, branded custom node, zone groups, and a `checkContrast()` WCAG helper. Adapt it (swap theme tokens, nodes, edges); don't hand-roll boilerplate.
