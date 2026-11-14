# Team Progress Tracking

Track status and handoffs across systems according to `WORKFLOW.md`.

---

## John: Items & Scaling
- **Status:** Complete (Ready for Verification / PR)
- **Branch:** `items/01-expanded-item-roster`
- **Current feature:** `01-expanded-item-roster` (Full Feature)
- **Updated:** 2026-11-13 (Gemini CLI)
- **Done:**
  - Audited existing items and stat pipeline in `docs/main.gd`.
  - Finalized item roster: 23 items across Common, Uncommon, and Rare with Tier 1–3 stat scaling.
  - Authored spec and plan docs (`00-brainstorm.md`, `01-spec.md`, `02-plan.md`, `03-todo.md`).
  - Implemented `ITEM_DB` with all 23 items, rarity color palettes, and tier costs in `docs/main.gd`.
  - Implemented `stats(d)` pipeline supporting Armor, MR, AP, AS, Range, Starting Mana, Mana-on-hit, Mana-taken, and special effects.
  - Implemented duplicate merge-on-unit rule in `click_loc` (merges duplicate items into Tier 2 and Tier 3 without consuming extra slots, rejects duplicates if already Tier 3, enforces 3-item limit).
  - Implemented dynamic item shop with level-based rarity rolling, Tier 2 direct offer chances, and `buy_item(i)`.
  - Implemented damage mitigation in `apply_damage()`: physical damage mitigated by Armor, magical damage mitigated by MR, damage absorption via shields.
  - Implemented combat triggers in `sim()` and `apply_cast()`: Emergency shield from Barrier Gem, damage reflect from Bramble Mail, Sunder armor/MR shred, Frost AS slow, Thunder magic burst, Thorn Carapace slow, and 1-second Proximity Auras (Sunfire Cloak burn + anti-heal, Warhorn buffs).
  - Implemented UI enhancements: rarity indicators in the item shop, item tier stars in inventory and stat sheet, and combat shield health bar overlays.
  - Added automated test suite `docs/test_items.gd` with 100% pass rate in headless Godot 4.7.2.
- **In progress:** Verification & Hand-check.
- **Next:** Teammate review & PR merge into `main`.
- **Needs from others:** None.
- **Handoff notes:**
  - `stats(d)` now returns: `hp`, `ad`, `armor`, `mr`, `ap`, `as_bonus`, `rng`, `mana`, `leech`, `mana_hit`, `mana_taken`, `crit_chance`, `spells_can_crit`, `effects`.
  - Equipped items on unit dictionaries `d.it` are stored as `{"n": name, "t": tier}` (backwards compatible with plain string name or legacy dictionaries).
  - `apply_damage(victim, attacker, raw_dmg, is_magic)` is available for any combat damage calculations with built-in Armor/MR formulas and shield consumption.

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
