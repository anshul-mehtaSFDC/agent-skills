---
name: system-discovery
description: "Use before diagramming, documenting, reviewing, or planning a system you don't yet fully understand — when you need to map what the components/entities are, how they connect, and where the boundaries lie. Produces a structured, source-grounded inventory (entities + connections + boundaries) and an explicit gap/open-questions pass, so downstream work (a diagram, a design doc, a review) is built on what's actually there, not a guess. Trigger words: understand the system, map the architecture, what connects to what, how does X flow, requirements, before you draw."
---

# System Discovery

## Overview

Map a system **before** you build anything on top of it (a diagram, a doc, a review, a plan). The failure this prevents: producing a confident artifact that's missing components, missing connections, or invents ones that don't exist — because you started from a shallow read or from memory.

**Core principle:** **Inventory before interpretation.** Read the real sources, extract *every* entity and *every* connection as a structured list, hunt for what's missing, and confirm with the user — then hand that inventory to whatever comes next.

## When to Use

- Before **diagramming** a system (required hook from `diagram-architect`).
- Before writing a **design/architecture doc**, a **review**, or a **migration/plan** for a system you don't fully hold in your head.
- Whenever the task depends on "what connects to what" and you're not certain you have it complete.

**When NOT to use:** you already have a verified inventory; or the system is trivial (2–3 components you can see in one file). Don't ceremony-ize the obvious.

## The Discovery Workflow

### 1. Gather ALL relevant sources (not just the one named)
A single file rarely holds the whole system. Cast wider:
- The file/doc the user named — **and** what it references (imports, linked docs, runbooks, configs).
- Code: entry points, interfaces, callers/callees, config, IaC/manifests.
- Live system where available: query metadata, list objects, inspect connections.
- Prior diagrams/docs, tickets, READMEs.

State which sources you read. If you only had one and suspect more exist, **say so** — an inventory from one source is provisional.

### 2. Build the ENTITY inventory
List every component/system/service/object/actor. For each:

| Field | Example |
|---|---|
| name | `OSS_HttpCalloutService` |
| kind | service / DB / queue / external system / actor / DMO / org |
| role | one line: what it does |
| source | where you found it (file:line / doc / query) |
| status | as-built · proposed · inferred (flag guesses) |

### 3. Build the CONNECTION inventory (the part most often missed)
List every relationship as a directed edge — this is what makes a diagram *correct*:

| Field | Example |
|---|---|
| from → to | `IntegrationProcedure → OSS_HttpCalloutService` |
| what flows | ProductOrder JSON / OAuth token / event |
| mechanism | REST callout · Platform Event · DB write · queue · sync/async |
| trigger / cadence | on submit · nightly batch · on record change |
| direction | one-way / request-response / bidirectional |
| source | where you found it |

Prefer **too many rows over too few** — a missing edge is the #1 diagram defect.

### 4. Establish BOUNDARIES & context
- What's **in scope** vs external (systems you touch but don't own).
- Trust/ownership/org boundaries (which org, which team, which cloud).
- Where data crosses a boundary (those edges matter most).

### 5. Gap-hunt (the pass people skip)
Explicitly look for what's missing or uncertain — don't wait to be corrected:
- **Dangling entities** — a component with no connections (real, or did you miss its edges?).
- **Implied-but-unlisted edges** — "A calls B" mentioned in prose but not captured; a caller with no callee.
- **Unverified claims** — anything you inferred vs. confirmed in a source; mark it.
- **Asymmetries** — a request with no response path; a write with no reader.
- **Coverage** — did you read every source that exists, or just the handy one?

Produce an **Open Questions** list from this pass.

### 6. Confirm with the user BEFORE building on it
Present the inventory compactly (entity count, connection count, boundaries) + the Open Questions. Ask them to correct/fill gaps. **Do not proceed to the diagram/doc/review until the inventory is confirmed or the user says "good enough."** This is the checkpoint that stops a wrong artifact.

## Output — the Discovery Inventory

Hand downstream work a compact structured object, e.g.:

```
ENTITIES (n=…): [{name, kind, role, source, status}, …]
CONNECTIONS (n=…): [{from, to, flows, mechanism, trigger, direction, source}, …]
BOUNDARIES: in-scope […]; external […]; crossings […]
OPEN QUESTIONS: […]
CONFIDENCE: which parts are as-built vs inferred
```

A diagram then draws nodes from ENTITIES and edges from CONNECTIONS — nothing invented, nothing missed.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Reading one file and calling it the system | Follow references; list sources read; flag if more likely exist |
| Entities without connections | Every listed component needs its edges found — or an Open Question |
| Capturing nodes, forgetting edges | The connection inventory is the point; over-list edges |
| Inferring silently | Mark as-built vs inferred; put guesses in Open Questions |
| Skipping the gap-hunt | Run step 5 explicitly — asymmetries and missing callees hide there |
| Building the artifact before confirming | Confirm the inventory with the user first (step 6) |
| Treating the user's framing as complete | They may not know every connection either — hunt anyway |

## Real-World Impact

Diagrams fail most often not on looks but on **missing or wrong connections** — an edge that doesn't exist, or a real integration left off. A structured connection inventory + a gap-hunt pass, confirmed before drawing, converts "plausible-looking" into "correct." The same inventory feeds a design doc or review without redoing the legwork.
