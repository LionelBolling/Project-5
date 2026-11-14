# 01-expanded-item-roster: Brainstorm

| | |
|---|---|
| System | Items / Scaling |
| Owner | John |
| Branch | `items/01-expanded-item-roster` |
| Agent | Gemini CLI |
| Date | 2026-11-13 |
| Milestone | Demo |

## Goal

Expand the item roster with a rarity system, duplicate-based tier progression (Tiers 1–3), and deep autobattler stat scaling (Armor, Magic Resistance, Ability Power, Attack Speed, Range, and Combat Triggers).

## Grounding

What the project already fixes (quote it; don't re-decide it here):
- `main.gd`:
  - `ITEMS`: Base dictionary defining items, their stats, and descriptions.
  - `stats(d)`: Scaling pipeline: `flat -> star multiplier -> % multiplier`.
  - Max 3 items per unit (`tu.it.size() >= 3`).
  - Max 8 items in inventory bench (`items_inv.size() < 8`).
  - Items purchased in prep phase for 3 gold.
- `temp_items.md`:
  - Defines trigger terms: HBTU (hit by this unit), ATU (attacking this unit), passive buffs, debuffs, auras, reflect.

## Q&A

1. **Q:** How should duplicate items on a unit be handled with the 3-item cap?
   **A:** Merging duplicates into upgraded tiers (Tier 1 $\rightarrow$ Tier 2 $\rightarrow$ Tier 3) on the same unit slot. · *why:* Avoids wasting scarce unit slots on duplicate Tier 1 items and creates a satisfying upgrade path.
2. **Q:** How should items be categorized across rarities?
   **A:** Three rarities: Common (flat core stats), Uncommon (percentage scaling, auras, basic debuffs), Rare (high-impact combat triggers: reflect, burst, execute, shield). · *why:* Provides a clear power curve and supports tiered shop pricing and PvE loot tables.
3. **Q:** What mitigation formulas should govern Armor and Magic Resistance?
   **A:** Diminishing returns effective HP: $\text{Damage Taken} = \text{Raw Damage} \times \frac{100}{100 + \text{Resistance}}$. · *why:* Standard autobattler formula that prevents invulnerability while giving durable units high value.
4. **Q:** What debuff duration should be used for combat triggers?
   **A:** 2.0 to 3.0 seconds (refreshing on hit). · *why:* A 1.0s duration expires before the default 1.25s attack cooldown; 2.5–3.0s ensures debuffs remain active during sustained combat.
5. **Q:** How should ability damage scale?
   **A:** Add an Ability Power (AP) stat where magic/ability damage scales with AP, while basic attacks scale with AD. · *why:* Differentiates physical carries from caster carries.
6. **Q:** Should staple autobattler mechanics (Anti-heal burn, Tank-buster, Emergency Shield, Spell Crit) be included?
   **A:** Yes, all approved (Sunfire Cloak, Giant Slayer, Barrier Gem, Sorcerer's Crown). · *why:* Offers essential counterplay against extreme sustain, mega-tanks, and burst assassins.

## Decisions

- **Duplicate Merging:** Equipping an identical item onto a unit increases that item's tier (max Tier 3) without consuming an extra unit item slot.
- **Dual Damage Pipeline:** Basic attacks deal Physical damage (mitigated by Armor); Casts deal Magical damage (scaled by AP, mitigated by MR).
- **Roster Organization:** Master roster established across Common, Uncommon, and Rare rarities.
- **Combat Triggers:** Implement HBTU (hit by this unit), ATU (attacking this unit), Aura (proximity), and internal cooldown procs.

## Contract changes needed

- `stats(d)` signature and return value expanded to include `armor`, `mr`, `ap`, `as_bonus`, `rng_bonus`, `mana`, `leech`, `crit_chance`, `special_effects`.
- `make_unit` and `sim(dt)` combat loops updated to resolve mitigation, attack speed cooldowns, and on-hit/on-attacked hooks.

## Open questions

- None. Full roster, scaling tiers, and combat mechanics approved.

## Out of scope

- Recipe-based multi-component crafting (TFT style) — this system uses direct full items with duplicate tier merging.
- Consumable items / temporary potions (deferred to later milestone).
