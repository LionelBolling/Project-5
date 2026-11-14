# Team Progress Tracking

Track status and handoffs across systems according to `WORKFLOW.md`.

---

## John: Items & Scaling
- **Status:** In Progress
- **Branch:** `items/01-expanded-item-roster`
- **Current feature:** `01-expanded-item-roster` (Full Feature)
- **Updated:** 2026-11-13 (Gemini CLI)
- **Done:**
  - Audited existing items and stat pipeline in `docs/main.gd`.
  - Finalized item roster: 23 items across Common, Uncommon, and Rare.
  - Specified merge-on-unit duplicate rule (Tier 1 $\rightarrow$ Tier 2 $\rightarrow$ Tier 3).
  - Authored spec and plan docs (`00-brainstorm.md`, `01-spec.md`, `02-plan.md`, `03-todo.md`).
- **In progress:** Iteration 1 (Item Data Architecture & Stat Scaling Pipeline).
- **Next:**
  - Implement expanded `ITEM_DB` and `stats(d)` pipeline for Armor, MR, AP, AS, Range, Leech, Mana.
  - Implement duplicate merge logic on units.
  - Wire combat mitigation and triggers (HBTU, ATU, Auras, Emergency Shield).
- **Needs from others:** None.
- **Handoff notes:**
  - `stats(d)` will provide `armor`, `mr`, `ap`, `as_bonus`, `rng_bonus`, `mana`, `leech`, `crit_chance`, and `special_effects`.
  - Item dictionary entries on units `d.it` will support `{"n": name, "t": tier}` format (with backwards compatibility for `[name, tier]` or string name).

---

## Lionel: Units & Shop
- **Status:** Pending
- **Branch:** `main`
- **Current feature:** None

---

## Jeremiah: Battle & QTE
- **Status:** Pending
- **Branch:** `main`
- **Current feature:** None

---

## Kai: Economy & Progression
- **Status:** Pending
- **Branch:** `main`
- **Current feature:** None
