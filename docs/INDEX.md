# Serenity — Documentation Index

> **Owner:** Engineering team
> **Purpose:** Navigation guide for the Serenity documentation system. Each document has a clear owner, audience, and update trigger.
> **Related:** Every document in this system

---

## Document System Overview

The Serenity docs are organized by concern. Each document answers specific questions and should be updated only when its scope changes.

```
docs/
  INDEX.md           ← You are here. Navigation and ownership.
  PRODUCT.md         ← What are we building and why?
  ARCHITECTURE.md    ← How does it work technically?
  BUILD.md           ← How do I build and run it?
  ROADMAP.md         ← Where are we going and what's next?
  DECISIONS.md       ← Why did we make these choices?
  CHANGELOG.md       ← What has been completed?
  FUTURE.md          ← What ideas are parked for later?
```

Superseded files (kept for history):
```
  docs/decision-log.md               ← Superseded by DECISIONS.md
  docs/superpowers/plans/             ← Superseded by PRODUCt.md + ROADMAP.md + ARCHITECTURE.md
```

---

## Document Reference

### `PRODUCT.md` — Product Guide

| Field | Detail |
|-------|--------|
| **Purpose** | Single source of truth for product identity |
| **Audience** | Product managers, designers, new team members |
| **Authority** | Product decisions, feature prioritization, design philosophy |
| **Update when** | Vision changes, pillars are revised, feature is added/removed |
| **Never put here** | Implementation details, build issues, technical decisions |

### `ARCHITECTURE.md` — Architecture Guide

| Field | Detail |
|-------|--------|
| **Purpose** | Complete technical reference for the codebase |
| **Audience** | Engineers, AI agents, new contributors |
| **Authority** | System design, data flow, component relationships |
| **Update when** | New subsystem added, data flow changes, schema changes, refactors |
| **Never put here** | Product vision, build environment issues, roadmap status |

### `BUILD.md` — Build Guide

| Field | Detail |
|-------|--------|
| **Purpose** | Everything needed to build and debug the app |
| **Audience** | Engineers setting up the project |
| **Authority** | Build configuration, version requirements, known environment issues |
| **Update when** | Dependencies change, new build issues discovered, workarounds found |
| **Never put here** | Product progress, feature status, architecture decisions |

### `ROADMAP.md` — Roadmap

| Field | Detail |
|-------|--------|
| **Purpose** | Track progress by milestones with clear gates |
| **Audience** | Product team, stakeholders, contributors |
| **Authority** | Milestone definition, status, Definition of Done |
| **Update when** | Milestone completes, status changes, blockers identified |
| **Never put here** | Build environment hair, in-progress feature details, unfinished ideas |

### `DECISIONS.md` — Decision Log

| Field | Detail |
|-------|--------|
| **Purpose** | Permanent record of architectural decisions |
| **Audience** | Engineers, future selves, new contributors |
| **Authority** | Why things are the way they are |
| **Update when** | Architecture decision is made, alternative is rejected |
| **Never put here** | Implementation details (put in ARCHITECTURE.md), opinions without context |

### `FUTURE.md` — Future Ideas

| Field | Detail |
|-------|--------|
| **Purpose** | Parking lot for ideas not in the current milestone |
| **Audience** | Product team, anyone with an idea |
| **Authority** | None — ideas here are not commitments |
| **Update when** | New idea emerges, idea graduates to roadmap, idea is rejected |
| **Never put here** | Current milestone work, committed features |

### `CHANGELOG.md` — Changelog

| Field | Detail |
|-------|--------|
| **Purpose** | Track only completed, shipped work |
| **Audience** | All team members, users |
| **Authority** | What has been delivered |
| **Update when** | Feature is complete and merged, fix is shipped |
| **Never put here** | In-progress work, ideas, discussions, build environment workarounds |

---

## Document Relationships

```
                  ┌─────────────┐
                  │  PRODUCT.md  │  (the "why")
                  └──────┬──────┘
                         │ informs
          ┌──────────────┼──────────────┬──────────────┐
          ▼              ▼              ▼              ▼
   ┌───────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────┐
   │ROADMAP.md │  │ARCHITECTURE. │  │DECISIONS │  │ FUTURE.md│
   │(the when) │  │md (the how)  │  │.md       │  │(the ideas│
   └─────┬─────┘  └──────┬───────┘  │(the why) │  │  parked) │
         │               │          └──────────┘  └──────────┘
         │               │
         ▼               ▼
   ┌───────────┐  ┌──────────────┐
   │CHANGE-    │  │   BUILD.md   │
   │LOG.md     │  │  (the tool)  │
   └───────────┘  └──────────────┘
```

### Decision Authority Matrix

| Type of Decision | Authority Document | Must Also Update |
|-----------------|-------------------|-----------------|
| "Should we build this feature?" | PRODUCT.md | ROADMAP.md |
| "How should we implement this?" | ARCHITECTURE.md | DECISIONS.md (if architecture decision) |
| "Why did we choose X over Y?" | DECISIONS.md | ARCHITECTURE.md (if architecture changed) |
| "What's the build command?" | BUILD.md | — |
| "What's the current milestone status?" | ROADMAP.md | — |
| "Has this feature shipped?" | CHANGELOG.md | ROADMAP.md (update status) |

---

## Update Process

1. **Before implementing any feature:** Read PRODUCT.md. Does it fit the vision? If not, update PRODUCT.md first (with team consensus).

2. **Before changing architecture:** Read DECISIONS.md. Understand why the current design exists. If your change invalidates a past decision, add a new entry to DECISIONS.md.

3. **During implementation:** Update ARCHITECTURE.md to reflect the new system understanding.

4. **After shipping:** Update CHANGELOG.md. Update ROADMAP.md milestone status.

5. **When environment issues arise:** Document in BUILD.md only. Never change product or roadmap docs for machine issues.
