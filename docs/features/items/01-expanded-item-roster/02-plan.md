# 01-expanded-item-roster: Plan

| | |
|---|---|
| System / Owner | Items & Scaling / John |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

1. **Iteration 1: Item Data Architecture & Stat Scaling Pipeline:**
   - Define all 23 items across Common, Uncommon, and Rare rarities with Tier 1–3 stat scaling and cost data.
   - Refactor `stats(d)` to parse item entries with tiers and compute: HP, AD, Armor, MR, AP, AS bonus, Range bonus, Start Mana, Leech, and Crits.
2. **Iteration 2: Equipment & Duplicate Tier Merge Logic:**
   - Update unit item inventory representation to support `{"n": name, "t": tier}`.
   - Implement merge-on-unit duplicate upgrade rule: dragging an identical item onto a unit upgrades its tier from 1 $\rightarrow$ 2 $\rightarrow$ 3 without consuming an extra slot.
   - Implement safety checks (reject if 3 distinct items or already Tier 3).
   - Update 3-unit star-up merge behavior so unmerged items safely return to player inventory.
3. **Iteration 3: Combat Mitigation & Triggers System:**
   - Integrate Armor physical mitigation: $\text{Raw AD} \times \frac{100}{100 + \text{Armor}}$.
   - Integrate AP spell scaling and MR magical mitigation: $(\text{Spell Dmg}) \times \frac{100}{100 + \text{MR}}$.
   - Implement dynamic Attack Speed cooldown scaling: $\frac{1.25}{1.0 + \text{AS}}$.
   - Wire trigger hooks:
     - On-attack / HBTU (Sunder shred, Frost slow, Catalyst mana, Thunder Charm proc).
     - On-hit taken / ATU (Thorn Carapace slow, Mana Ward, Bramble Mail reflect).
     - Proximity Auras (Warhorn ally buff, Sunfire Cloak burn + anti-heal).
     - Health threshold (Barrier Gem emergency shield).
4. **Iteration 4: Shop, Inventory & HUD UI Polish:**
   - Categorize prep shop item offerings by rarity colors (Common: Gray/Green, Uncommon: Blue, Rare: Gold) with appropriate gold costs (3g / 4g / 6g).
   - Update unit stat sheet display (Armor, MR, AP, AS, item tier stars).
   - Add floating combat text popups for procs (`SHRED!`, `SLOW!`, `REFLECT!`, `SHIELD!`, `BURN!`).

---

## 2. Iterations and steps

### Iteration 1: Item Roster & Stat Scaling
- **Step 1.1:** Build `ITEM_DB` containing all 23 items with rarity, cost, descriptions, and Tier 1–3 stat dicts.
- **Step 1.2:** Implement expanded `stats(d)` pipeline supporting flat + % scaling for HP, AD, Armor, MR, AP, AS, Range, Starting Mana, and Leech.

### Iteration 2: Inventory, Equipping & Duplicate Merging
- **Step 2.1:** Implement `equip_item(unit, item_obj)` handling duplicate tier incrementing and 3-slot cap validation.
- **Step 2.2:** Update unit star-up merge function to return items from secondary units back to inventory bench.

### Iteration 3: Combat Mitigation & Triggers
- **Step 3.1:** Implement dual damage mitigation (Physical vs Armor, Magic vs MR, AP scaling) and Attack Speed cooldowns in `sim(dt)`.
- **Step 3.2:** Implement HBTU, ATU, Aura, and Emergency Shield combat trigger effects.

### Iteration 4: UI & Playtest Verification
- **Step 4.1:** Render item shop buttons with rarity color indicators and tier pricing.
- **Step 4.2:** Expand unit stat sheet to render new stats and item tier badges.
- **Step 4.3:** End-to-end playtest verification in Godot / web runtime.

---

## 3. Prompts

### Prompt 1 (Iteration 1 & 2): Item Data, Stat Pipeline & Duplicate Merging
```text
Context: Items & Scaling feature 01-expanded-item-roster. Read docs/features/items/01-expanded-item-roster/01-spec.md.
Task: Define ITEM_DB in docs/main.gd with all 23 items and their Tier 1-3 stats. Update stats(d) to compute HP, AD, Armor, MR, AP, AS bonus, Range bonus, Start Mana, and Leech. Implement duplicate merge-on-unit equipping logic.
Files: docs/main.gd.
Verification: Confirm stats() evaluates correctly for T1, T2, T3 items and duplicate equips upgrade tiers properly.
```

### Prompt 2 (Iteration 3): Combat Mitigation & Trigger Logic
```text
Context: Items & Scaling feature 01-expanded-item-roster. Read docs/features/items/01-expanded-item-roster/01-spec.md.
Task: Update combat simulation in docs/main.gd to use Armor/MR mitigation formulas, Attack Speed cooldowns, AP spell damage, and trigger effects (HBTU, ATU, Proximity Auras, Barrier Shield, Bramble Reflect).
Files: docs/main.gd.
Verification: Confirm damage numbers reflect mitigation and triggers execute during combat.
```

### Prompt 3 (Iteration 4): UI, Shop & Stat Sheet Integration
```text
Context: Items & Scaling feature 01-expanded-item-roster. Read docs/features/items/01-expanded-item-roster/01-spec.md.
Task: Update item shop UI to show rarity colors and costs. Update unit stat sheet to display Armor, MR, AP, AS, and equipped item tiers. Add combat floating text for item procs.
Files: docs/main.gd.
Verification: Test prep phase item shop, equipping, stat sheet inspection, and combat round.
```
