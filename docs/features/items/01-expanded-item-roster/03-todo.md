# 01-expanded-item-roster: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [x] Synced `main` and created branch `items/01-expanded-item-roster`
- [x] `00-brainstorm.md` written
- [x] `01-spec.md` written and approved by the owner
- [x] Contract changes approved (or none)
- [x] `02-plan.md` written
- [x] `03-todo.md` written

## Iteration 1: Item Data Architecture & Stat Scaling
- [ ] Step 1.1: Build `ITEM_DB` containing all 23 items with rarity, cost, descriptions, and Tier 1–3 stat dicts
- [ ] Step 1.2: Implement expanded `stats(d)` pipeline supporting flat + % scaling for HP, AD, Armor, MR, AP, AS, Range, Starting Mana, and Leech

## Iteration 2: Inventory, Equipping & Duplicate Merging
- [ ] Step 2.1: Implement `equip_item(unit, item_obj)` handling duplicate tier incrementing and 3-slot cap validation
- [ ] Step 2.2: Update unit star-up merge function to return items from secondary units back to inventory bench

## Iteration 3: Combat Mitigation & Triggers
- [ ] Step 3.1: Implement dual damage mitigation (Physical vs Armor, Magic vs MR, AP scaling) and Attack Speed cooldowns in `sim(dt)`
- [ ] Step 3.2: Implement HBTU, ATU, Aura, and Emergency Shield combat trigger effects

## Iteration 4: UI & Playtest Verification
- [ ] Step 4.1: Render item shop buttons with rarity color indicators and tier pricing
- [ ] Step 4.2: Expand unit stat sheet to render new stats and item tier badges
- [ ] Step 4.3: End-to-end playtest verification in Godot / web runtime

## Verify
- [ ] All 23 items defined and accessible in the shop and PvE loot
- [ ] Duplicate merge-on-unit functionality confirmed working without exceeding 3 slots
- [ ] Unit stat sheet correctly displays new stats (Armor, MR, AP, AS) and item tiers
- [ ] Damage reduction from Armor and MR confirmed in combat rounds
- [ ] Combat triggers (Aura, HBTU shred/slow, ATU reflect, Barrier shield) confirmed active

## PR
- [ ] Pulled `origin/main` right before pushing; re-checked project playability
- [ ] PR opened with summary, interfaces touched, how to test, and test results
- [ ] Reviewed by teammate
- [ ] Merged
