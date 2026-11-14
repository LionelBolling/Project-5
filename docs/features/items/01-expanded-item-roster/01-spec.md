# 01-expanded-item-roster: Spec

| | |
|---|---|
| System / Owner | Items & Scaling / John |
| Branch | `items/01-expanded-item-roster` |
| Status | Approved (2026-11-13) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo |

## 1. Overview

This feature delivers an expanded, tactical item roster with a rarity structure, a duplicate-based tier progression (Tiers 1–3), and autobattler stat scaling. Items introduce Armor, Magic Resistance, Ability Power (AP), Attack Speed, Range modifiers, and dynamic triggers (Hit-By-This-Unit, Attacking-This-Unit, Auras, and internal cooldown procs). It integrates directly into the prep phase item shop, inventory bench, unit equipment, and combat resolution loop.

## 2. Player-facing behavior

1. **Purchasing & Rarity:** The prep phase item shop displays available items categorized with colored borders or tags (Common: White/Green, Uncommon: Blue, Rare: Gold). Common items cost 3g, Uncommon cost 4g, and Rare cost 6g.
2. **Equipping & Stacking:**
   - Clicking an item in the 8-slot inventory bench and clicking a unit equips it.
   - If the unit does not have the item, it occupies one of the unit's 3 item slots at **Tier 1** (indicated with `★`).
   - If the unit *already has* that item at Tier 1 or Tier 2, dragging an additional copy onto the unit automatically merges and upgrades it to **Tier 2** (`★★`) or **Tier 3** (`★★★`), consuming the duplicate from inventory without taking an additional unit slot.
   - If all 3 slots are occupied by different items and an incompatible item is dragged, feedback reads: *"Unit item slots full."*
3. **Stat Sheet Inspection:** Selecting a unit opens the stat sheet displaying base + item-modified HP, AD, Armor, MR, AP, Attack Speed, Range, Starting Mana, Lifesteal, and equipped items with their tier stars.
4. **Combat Feedback:** Floating combat text and visual effects reflect:
   - Physical attacks mitigated by target's Armor.
   - Ability casts dealing magic damage amplified by AP and mitigated by target's MR.
   - Visual popups for triggers: `BURN!`, `SHRED!`, `SLOW!`, `REFLECT!`, `SHIELD!`, `BURST!`.

## 3. Rules and numbers

### Damage Mitigation Formulas
- **Physical Damage (Attacks):**
  $$\text{Damage Dealt} = \text{Raw AD} \times \frac{100}{100 + \max(0, \text{Target Armor})}$$
- **Magic Damage (Abilities):**
  $$\text{Base Spell Damage} = \text{Unit Base AD} \times 2.5 \times \left(1.0 + \frac{\text{AP}}{100}\right) \times (1.0 + \text{QTE bonus})$$
  $$\text{Damage Dealt} = \text{Base Spell Damage} \times \frac{100}{100 + \max(0, \text{Target MR})}$$
- **Attack Cooldown:**
  $$\text{Attack CD} = \frac{1.25}{1.0 + \text{Bonus Attack Speed}}$$

---

### Master Item Roster & Tier Values

#### Common Items (Cost: 3g)
| Item | Stat / Effect | Tier 1 (1 copy) | Tier 2 (2 copies) | Tier 3 (3 copies) |
| :--- | :--- | :--- | :--- | :--- |
| **Sword** | Flat AD | +10 AD | +24 AD | +55 AD |
| **Vest** | Flat HP | +150 HP | +350 HP | +750 HP |
| **Chainmail** | Flat Armor | +30 Armor | +70 Armor | +150 Armor |
| **Null Cloak** | Flat MR | +30 MR | +70 MR | +150 MR |
| **Swift Blade** | Flat Attack Speed | +20% AS | +45% AS | +95% AS |

#### Uncommon Items (Cost: 4g)
| Item | Stat / Effect | Tier 1 | Tier 2 | Tier 3 |
| :--- | :--- | :--- | :--- | :--- |
| **Amp** | % AD | +20% AD | +45% AD | +95% AD |
| **Reinforced Plate** | % Armor | +25% Armor | +55% Armor | +110% Armor |
| **Rune Cloak** | % MR | +25% MR | +55% MR | +110% MR |
| **Longbow** | Attack Range | +30% (+1 tile) | +60% (+1 tile) | +120% (+2 tiles) |
| **Orb** | Starting Mana | +40 Start Mana | +70 Start Mana | +100 Start Mana |
| **Catalyst** | Mana on Attack | +5 Mana / atk | +10 Mana / atk | +18 Mana / atk |
| **Mana Ward** | Mana on Hit Taken | +5 Mana / hit | +10 Mana / hit | +18 Mana / hit |
| **Leech** | Lifesteal & Spellvamp | 20% Leech | 40% Leech | 75% Leech |
| **Warhorn** | Proximity Aura (1 tile) | +15% AD/AP/AS | +25% AD/AP/AS | +45% AD/AP/AS |
| **Sunder Dagger** | HBTU: Shred (3s) | -20% Armor & MR | -35% Armor & MR | -55% Armor & MR |
| **Frost Shard** | HBTU: Attack Slow (2.5s)| -25% AS | -40% AS | -60% AS |
| **Thorn Carapace** | ATU: Attacker Slow (2.5s)| -20% AS | -35% AS | -50% AS |
| **Sunfire Cloak** | Aura: Burn & Heal Cut | 3% max HP/s, 50% anti-heal | 5% max HP/s | 8% max HP/s |

#### Rare Items (Cost: 6g)
| Item | Stat / Effect | Tier 1 | Tier 2 | Tier 3 |
| :--- | :--- | :--- | :--- | :--- |
| **Thunder Charm** | On-Hit Magic Burst (3s CD)| +60 Magic Damage | +140 Magic Damage | +260 Magic Damage |
| **Bramble Mail** | ATU: Reflect (1s CD) | Reflect 35% damage taken | Reflect 65% damage | Reflect 100% damage |
| **Giant Slayer** | Tank Buster | +20% Dmg (+50% vs >1000 HP)| +35% (+75% vs >1000 HP) | +55% (+120% vs >1000 HP)|
| **Barrier Gem** | Emergency Shield (<30% HP)| 35% max HP shield (4s) | 60% max HP shield (4s) | 100% max HP shield (4s)|
| **Sorcerer's Crown**| AP & Spell Crit | +35 AP, Spells can Crit | +75 AP, Spells can Crit | +140 AP, Spells can Crit |

---

## 4. Interfaces

**Uses (from other systems):**
- Unit Definitions (`DEFS`): Uses unit base stats and ranged flag.
- Gold & Economy (`gold`): Debits item purchase price (3g / 4g / 6g) upon shop purchase.

**Provides / Emits:**
- `stats(d)`: Returns resolved stat dictionary for any unit dictionary `d`.
  - Keys: `hp`, `ad`, `armor`, `mr`, `ap`, `as_bonus`, `rng_bonus`, `mana`, `leech`, `crit_chance`, `special_effects`.
- `equip_item(unit, item_name, tier)`: Equips or upgrades item on the target unit.
- `item_def(name, tier)`: Helper returning all stats/effects for a named item at a given tier.

**Contract changes:**
- Expansion of unit data dictionary `d.it`: Each element is a dictionary `{"n": item_name, "t": tier}` (or backward-compatible `[name, tier]`).
- Combat damage calculation in `sim(dt)` now requires target armor and magic resist.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `docs/main.gd` | Changed | Implementation of expanded item database, tier merge logic, stat pipeline, combat mitigation, and triggers |
| `docs/features/items/01-expanded-item-roster/` | New | Feature specification, plans, and tracking documentation |

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Unit already has Tier 3 item and player drags another copy | Operation is rejected with message: *"Item already max tier (★3)."* Duplicate remains in inventory. |
| Unit has 3 distinct items and player drags a duplicate of one of them | Duplicate is accepted and merges into the existing item, upgrading it to Tier 2/3. Total equipped slots remains 3. |
| Unit has 3 distinct items and player drags a 4th distinct item | Rejected with message: *"Unit item slots full."* |
| Star-up merge of 3 units with multiple items | Primary unit keeps items; excess items from 2nd/3rd units return to inventory. If inventory is full (8 slots), excess items dropped to board or converted to gold. |
| Resistance exceeds 100 | Diminishing returns formula smoothly handles high values (e.g. 150 Armor = 60% reduction, 300 Armor = 75% reduction). Zero division or negative mitigation is clamped. |
| Anti-heal burn applied while unit is lifestealing | Unit healing received is reduced by 50% for the debuff duration. |

## 7. Test plan

**Functional & Unit Verification:**
- [ ] Item dictionary lookup returns valid values for all 23 items at Tier 1, 2, and 3.
- [ ] Equipping duplicate item upgrades tier from 1 to 2, and 2 to 3.
- [ ] Attempting to upgrade beyond Tier 3 fails gracefully.
- [ ] Equipping 4th distinct item is blocked when unit has 3 items.
- [ ] `stats(d)` correctly calculates flat armor/MR and percentage amplifiers.
- [ ] Physical damage applies Armor reduction: $100 \times \frac{100}{100 + \text{Armor}}$.
- [ ] Magic damage applies MR reduction and AP scaling.
- [ ] Attack cooldown decreases with Attack Speed.
- [ ] HBTU / ATU debuff application triggers and expires after duration.
- [ ] Barrier Gem triggers shield once per battle when HP drops below 30%.

**Playtest Checks:**
- [ ] Verify item shop displays items with clear rarity/cost indication.
- [ ] Drag item from inventory to unit on bench or board.
- [ ] Inspect unit stat sheet to verify updated stats and star levels.
- [ ] Run combat round and observe damage popups, mitigation, and trigger effects.

## 8. Out of scope

- Dynamic drag-to-combine item recipes (TFT style).
- Consumable single-use potions.

## 9. Done when

- [ ] All 23 items defined with full Tier 1–3 scaling and rarity classifications.
- [ ] Duplicate merge-on-unit functionality working without consuming extra unit item slots.
- [ ] Expanded stat pipeline in `stats(d)` computes Armor, MR, AP, AS, Range, Mana, Leech, and Crits.
- [ ] Combat simulation applies physical and magical mitigation formulas.
- [ ] Trigger effects (HBTU, ATU, Auras, Shield, Burn) function in combat.
- [ ] Playable directly in `docs/main.gd` with clean UI feedback and stat sheet updates.
