extends Node2D
# Paper Tactics playtest: shop, placement, merge, money, XP, auto-battle, QTE.
# Includes Items, Scaling pipeline (flat -> star mult -> % mult), PvE loot.

const CELL := 64
const BO := Vector2(360, 40)
const COLS := 7
const ROWS := 6
const PARCH := Color("E8D8C1")
const KRAFT := Color("D1BE9B")
const INK := Color("1A1617")
const PURPLE := Color("893BFF")
const GOLD := Color("E69A2B")
const RED := Color("D9381E")
const PAPER_HIGHLIGHT := Color("FFF2DA")
const PAPER_EDGE := Color("967550")
const TOAST_DURATION := 4.0
const GUIDE_BUBBLE := Rect2(69, 317, 173, 58)
const GUIDE_MODEL := Rect2(17, 317, 45, 58)
const GUIDE_TIPS := [
	["Put melee units up front.", "Keep ranged units back.", "Click me for another tip."],
	["Buy XP to field more units.", "A bigger team helps you", "survive later rounds."],
	["Three matching units", "can merge into a stronger", "unit with one more star."],
	["Tier 4 and 5 units need", "two tiles side by side.", "Leave room next to them."],
	["Give defensive items", "to front-line units.", "Equip damage in back."],
	["Hover over enemies", "before battle to plan", "where to place your team."]
]
enum Tutorial {
	BUY, SELECT, PLACE, START, FIGHT, LESSON, XP, BUY_ITEM, SELECT_ITEM, EQUIP,
	MERGE, LOOT, DONE
}
const TRAINING_TILE := Vector2i(3, 5)
const STARTING_GOLD := 12
const STARTING_HP := 50
const LESSON_NEXT := Rect2(734, 98, 114, 30)
const SKIP_TUTORIAL := Rect2(904, 14, 222, 33)
const TUTORIAL_LINES := [
	["Buy the highlighted Archer. Shop units go to your bench.",
		"Hover over a shop card to see the character, stats, and price."],
	["Click the Archer on your bench to select it.",
		"Click another unit to swap positions, or click Sell (E) to sell it."],
	["Move the Archer onto the highlighted tile in your back row.",
		"Place melee units in front. Tier 4 and 5 units need two adjacent tiles."],
	["Click Start Battle or press Enter. You can see the enemy lineup now.",
		"Hover over any unit to inspect its stats."],
	["Units fight automatically. The bars show health and mana.",
		"When the spell marker reaches the gold zone, press Space for a boost."],
	[],
	["Click Buy XP (F). Higher levels let you field more units",
		"and improve the odds of finding higher-tier units in the shop."],
	["Buy the highlighted Sword from the Item Shop.",
		"Hover over items to compare their bonuses and upgrade tiers."],
	["Click the Sword in your inventory to select it.",
		"Hover over a unit with an item selected to preview the upgrade."],
	["Click your Archer to equip the Sword. Each unit can hold three items.",
		"Equip another copy of an item on the same unit to upgrade it."],
	["Use Merge to choose three units of the same type and star level.",
		"The first unit stays and gains a star. Confirm when you're ready."],
	["Wait for the warning ring, then click the gold orb to collect it.",
		"Stage 1 starts with a fresh board, shop, gold, and health."]
]
const LESSONS := [
	["Reroll (D) spends gold to refresh both shops. Lock keeps the current",
		"offers for the next round. The odds panel shows unit tiers at your level."],
	["You earn gold and XP after each round. Saved gold earns interest.",
		"Win or loss streaks add gold. Victories can drop collectible gold orbs."],
	["Win all ten stages to finish. On a loss you take damage and retry",
		"the same lineup. Monster rounds can also drop an item when you win."],
	["The next practice round covers leveling, items, merging, and loot.",
		"Your practice purchases and upgrades will reset when training ends."]
]
const LOOT_WARNING_TIME := 0.9
const QTE_DURATION := 0.75
const QTE_GOLD_START := 0.275
const QTE_GOLD_END := 0.475
const MERGE_BUTTON := Rect2(900, 490, 230, 32)
const MERGE_SELECT_PANEL := Rect2(430, 144, 420, 80)
const MERGE_CONFIRM_PANEL := Rect2(430, 298, 420, 124)
const MERGE_ACCEPT := Rect2(454, 376, 174, 32)
const MERGE_CANCEL := Rect2(652, 376, 174, 32)
const TIER_COL := [Color("8a7a5c"), Color("E69A2B"), Color("893BFF"), Color("D9381E"), Color("1A1617")]
const DEFS := [["Squire",1,false],["Archer",1,true],["Knight",2,false],["Mage",2,true],
	["Rogue",3,false],["Cleric",3,true],["Golem",4,false],["Witch",4,true],["Dragon",5,false],["Sage",5,true]]
const ODDS := {3:[75,25,0,0,0],4:[55,30,15,0,0],5:[45,33,20,2,0],6:[30,40,25,5,0],
	7:[19,30,35,15,1],8:[16,20,35,25,4],9:[9,15,30,30,16]}
const XPN := {3:4,4:8,5:12,6:18,7:24,8:32}

const RARITY_COLS := {
	"common": Color("4e8752"),
	"uncommon": Color("2e72cb"),
	"rare": Color("d49222")
}

const ITEM_DB := {
	# Common Items (3g base)
	"Sword": {"rarity": "common", "cost": 3, "tiers": [
		{"ad": 10.0, "d": "+10 AD"},
		{"ad": 24.0, "d": "+24 AD"},
		{"ad": 55.0, "d": "+55 AD"}
	]},
	"Vest": {"rarity": "common", "cost": 3, "tiers": [
		{"hp": 150.0, "d": "+150 HP"},
		{"hp": 350.0, "d": "+350 HP"},
		{"hp": 750.0, "d": "+750 HP"}
	]},
	"Chainmail": {"rarity": "common", "cost": 3, "tiers": [
		{"armor": 30.0, "d": "+30 Armor"},
		{"armor": 70.0, "d": "+70 Armor"},
		{"armor": 150.0, "d": "+150 Armor"}
	]},
	"Null Cloak": {"rarity": "common", "cost": 3, "tiers": [
		{"mr": 30.0, "d": "+30 MR"},
		{"mr": 70.0, "d": "+70 MR"},
		{"mr": 150.0, "d": "+150 MR"}
	]},
	"Swift Blade": {"rarity": "common", "cost": 3, "tiers": [
		{"as": 0.20, "d": "+20% Attack Spd"},
		{"as": 0.45, "d": "+45% Attack Spd"},
		{"as": 0.95, "d": "+95% Attack Spd"}
	]},

	# Uncommon Items (4g base)
	"Amp": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"pad": 0.20, "d": "+20% AD"},
		{"pad": 0.45, "d": "+45% AD"},
		{"pad": 0.95, "d": "+95% AD"}
	]},
	"Reinforced Plate": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"parmor": 0.25, "d": "+25% Armor"},
		{"parmor": 0.55, "d": "+55% Armor"},
		{"parmor": 1.10, "d": "+110% Armor"}
	]},
	"Rune Cloak": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"pmr": 0.25, "d": "+25% MR"},
		{"pmr": 0.55, "d": "+55% MR"},
		{"pmr": 1.10, "d": "+110% MR"}
	]},
	"Longbow": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"rng": 1.0, "d": "+1 Tile Range"},
		{"rng": 1.0, "d": "+1 Tile Range"},
		{"rng": 2.0, "d": "+2 Tiles Range"}
	]},
	"Orb": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"mana": 40.0, "d": "+40 Start Mana"},
		{"mana": 70.0, "d": "+70 Start Mana"},
		{"mana": 100.0, "d": "+100 Start Mana"}
	]},
	"Catalyst": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"mana_hit": 5.0, "d": "+5 Mana on Atk"},
		{"mana_hit": 10.0, "d": "+10 Mana on Atk"},
		{"mana_hit": 18.0, "d": "+18 Mana on Atk"}
	]},
	"Mana Ward": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"mana_taken": 5.0, "d": "+5 Mana on Hit"},
		{"mana_taken": 10.0, "d": "+10 Mana on Hit"},
		{"mana_taken": 18.0, "d": "+18 Mana on Hit"}
	]},
	"Leech": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"leech": 0.20, "d": "20% Lifesteal"},
		{"leech": 0.40, "d": "40% Lifesteal"},
		{"leech": 0.75, "d": "75% Lifesteal"}
	]},
	"Warhorn": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"warhorn": 0.15, "d": "Aura: +15% Stats"},
		{"warhorn": 0.25, "d": "Aura: +25% Stats"},
		{"warhorn": 0.45, "d": "Aura: +45% Stats"}
	]},
	"Sunder Dagger": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"sunder": 0.20, "d": "HBTU: -20% Resists"},
		{"sunder": 0.35, "d": "HBTU: -35% Resists"},
		{"sunder": 0.55, "d": "HBTU: -55% Resists"}
	]},
	"Frost Shard": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"frost": 0.25, "d": "HBTU: -25% AS"},
		{"frost": 0.40, "d": "HBTU: -40% AS"},
		{"frost": 0.60, "d": "HBTU: -60% AS"}
	]},
	"Thorn Carapace": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"thorn": 0.20, "d": "ATU: Attacker -20% AS"},
		{"thorn": 0.35, "d": "ATU: Attacker -35% AS"},
		{"thorn": 0.50, "d": "ATU: Attacker -50% AS"}
	]},
	"Sunfire Cloak": {"rarity": "uncommon", "cost": 4, "tiers": [
		{"sunfire": 0.03, "hp": 100.0, "d": "Aura: 3% Burn+Antiheal"},
		{"sunfire": 0.05, "hp": 250.0, "d": "Aura: 5% Burn+Antiheal"},
		{"sunfire": 0.08, "hp": 500.0, "d": "Aura: 8% Burn+Antiheal"}
	]},

	# Rare Items (6g base)
	"Thunder Charm": {"rarity": "rare", "cost": 6, "tiers": [
		{"thunder": 60.0, "d": "On-Hit: 60 Magic (3s CD)"},
		{"thunder": 140.0, "d": "On-Hit: 140 Magic"},
		{"thunder": 260.0, "d": "On-Hit: 260 Magic"}
	]},
	"Bramble Mail": {"rarity": "rare", "cost": 6, "tiers": [
		{"bramble": 0.35, "armor": 40.0, "d": "ATU: Reflect 35% Dmg"},
		{"bramble": 0.65, "armor": 90.0, "d": "ATU: Reflect 65% Dmg"},
		{"bramble": 1.00, "armor": 180.0, "d": "ATU: Reflect 100% Dmg"}
	]},
	"Giant Slayer": {"rarity": "rare", "cost": 6, "tiers": [
		{"gs_base": 0.20, "gs_giant": 0.50, "ad": 10.0, "d": "+20% Dmg (+50% vs Tank)"},
		{"gs_base": 0.35, "gs_giant": 0.75, "ad": 25.0, "d": "+35% Dmg (+75% vs Tank)"},
		{"gs_base": 0.55, "gs_giant": 1.20, "ad": 55.0, "d": "+55% Dmg (+120% vs Tank)"}
	]},
	"Barrier Gem": {"rarity": "rare", "cost": 6, "tiers": [
		{"barrier": 0.35, "hp": 100.0, "d": "Shield 35% HP at <30%"},
		{"barrier": 0.60, "hp": 250.0, "d": "Shield 60% HP at <30%"},
		{"barrier": 1.00, "hp": 500.0, "d": "Shield 100% HP at <30%"}
	]},
	"Sorcerer's Crown": {"rarity": "rare", "cost": 6, "tiers": [
		{"ap": 35.0, "crit": 0.25, "spell_crit": true, "d": "+35 AP, Spell Crit"},
		{"ap": 75.0, "crit": 0.40, "spell_crit": true, "d": "+75 AP, Spell Crit"},
		{"ap": 140.0, "crit": 0.60, "spell_crit": true, "d": "+140 AP, Spell Crit"}
	]}
}

const ITEMS := ITEM_DB # Backward-compatibility alias
const ITEM_NAMES := ["Sword", "Vest", "Chainmail", "Null Cloak", "Swift Blade", "Amp", "Reinforced Plate", "Rune Cloak", "Longbow", "Orb", "Catalyst", "Mana Ward", "Leech", "Warhorn", "Sunder Dagger", "Frost Shard", "Thorn Carapace", "Sunfire Cloak", "Thunder Charm", "Bramble Mail", "Giant Slayer", "Barrier Gem", "Sorcerer's Crown"]
const PVE_STAGES := [1, 4, 7]
const BTNS := ["Reroll (D) 2g", "Lock shop", "Buy XP (F) 4g", "Sell (E)", "START BATTLE (Enter)"]

var gold := STARTING_GOLD
var tutorial_step := Tutorial.BUY
var practice_round := 1
var tutorial_lesson := 0
var guide_tip_index := -1
var level := 3
var xp := 0
var hp := STARTING_HP
var stage := 1
var streak := 0
var phase := "prep"
var locked := false
var notification_time := TOAST_DURATION
var msg := "Practice battle. Follow the wizard's instructions.":
	set(value):
		msg = value
		notification_time = TOAST_DURATION
var shop := []
var item_shop := []
var bench := []
var board := {}
var sel = null
var units := []
var enemy_formation := []
var selecting_merge := false
var merge_locs := []
var merge_hint := ""
var texts := []
var ctime := 0.0
var qte = null
var items_inv := []
var sel_item := -1
var orbs := []
var loot_warning_time := 0.0
var cur_pve := false
var aura_timer := 0.0
var mouse_pos := Vector2.ZERO
var projectiles := []
var hover_amounts := {}
var pressed_rect := Rect2()
var press_time := 0.0

func spawn_projectile(from_pos: Vector2, to_pos: Vector2, u_name: String):
	var p_type = "arrow"
	var col = Color("e0d8c8")
	match u_name:
		"Archer":
			p_type = "arrow"
			col = Color("7a5328")
		"Mage":
			p_type = "arcane"
			col = Color("38d9ff")
		"Witch":
			p_type = "dark"
			col = Color("bf36ff")
		"Cleric":
			p_type = "holy"
			col = Color("ffd700")
		"Sage":
			p_type = "star"
			col = Color("5cffb0")
		_:
			p_type = "arcane"
			col = Color("e0d8c8")
	projectiles.append({
		"from": from_pos, "to": to_pos, "t": 0.0, "dur": 0.22,
		"type": p_type, "col": col
	})

func _ready():
	randomize()
	hover_amounts[GUIDE_MODEL] = 0.0
	hover_amounts[GUIDE_BUBBLE] = 0.0
	hover_amounts[SKIP_TUTORIAL] = 0.0
	hover_amounts[MERGE_BUTTON] = 0.0
	hover_amounts[MERGE_ACCEPT] = 0.0
	hover_amounts[MERGE_CANCEL] = 0.0
	for i in 8:
		bench.append(null)
		hover_amounts[bench_rect(i)] = 0.0
		hover_amounts[item_slot_rect(i)] = 0.0
	for i in 5:
		hover_amounts[card_rect(i)] = 0.0
		hover_amounts[btn_rect(i)] = 0.0
	for y in range(3, ROWS):
		for x in COLS:
			hover_amounts[Rect2(BO + Vector2(x, y) * CELL, Vector2(CELL, CELL))] = 0.0
	roll_shop()
	roll_item_shop()
	shop[0] = {"n": "Archer", "t": 1, "r": true, "s": 1, "it": []}
	enemy_formation = [{"d": {"n": "Squire", "t": 1, "r": false, "s": 1, "it": []}, "pos": Vector2(3, 2)}]
	for i in item_shop.size():
		hover_amounts[item_btn_rect(i)] = 0.0

# ---------- item & stat helpers ----------
func get_it_name(it):
	if it is Dictionary: return it.get("n", "")
	return str(it)

func get_it_tier(it):
	if it is Dictionary: return int(it.get("t", 1))
	return 1

func get_it_desc(name, tier):
	if not ITEM_DB.has(name): return ""
	var t = clampi(tier, 1, 3)
	return ITEM_DB[name].tiers[t - 1].d

# Scaling pipeline: base stats (with tier scaling) + flat item stats, star multiplier, then % multipliers.
func stats(d):
	var fh = 0.0
	var fa = 0.0
	var pa = 0.0
	var farmor = 0.0
	var parmor = 0.0
	var fmr = 0.0
	var pmr = 0.0
	var ap = 0.0
	var as_bonus = 0.0
	var rng_bonus = 0.0
	var m0 = 0.0
	var m_hit = 0.0
	var m_taken = 0.0
	var lc = 0.0
	var crit_ch = 0.0
	var spells_can_crit = false
	var effects = {}

	for it in d.get("it", []):
		var n = get_it_name(it)
		var t = get_it_tier(it)
		if not ITEM_DB.has(n): continue
		var t_data = ITEM_DB[n].tiers[clampi(t, 1, 3) - 1]

		fh += t_data.get("hp", 0.0)
		fa += t_data.get("ad", 0.0)
		pa += t_data.get("pad", 0.0)
		farmor += t_data.get("armor", 0.0)
		parmor += t_data.get("parmor", 0.0)
		fmr += t_data.get("mr", 0.0)
		pmr += t_data.get("pmr", 0.0)
		ap += t_data.get("ap", 0.0)
		as_bonus += t_data.get("as", 0.0)
		rng_bonus += t_data.get("rng", 0.0)
		m0 += t_data.get("mana", 0.0)
		m_hit += t_data.get("mana_hit", 0.0)
		m_taken += t_data.get("mana_taken", 0.0)
		lc += t_data.get("leech", 0.0)
		crit_ch += t_data.get("crit", 0.0)
		if t_data.get("spell_crit", false): spells_can_crit = true

		effects[n] = t_data

	var bh = (300.0 + 130.0 * d.t) * (0.7 if d.r else 1.0)
	var ba = 25.0 + 10.0 * d.t
	var b_arm = 20.0 + 5.0 * d.t
	var b_mr = 20.0 + 5.0 * d.t
	var sm = pow(1.8, d.s - 1)
	return {
		"hp": (bh + fh) * sm,
		"ad": (ba + fa) * sm * (1.0 + pa),
		"armor": (b_arm + farmor) * (1.0 + parmor),
		"mr": (b_mr + fmr) * (1.0 + pmr),
		"ap": ap,
		"as_bonus": as_bonus,
		"rng": (3.0 if d.r else 1.0) + rng_bonus,
		"mana": m0,
		"leech": lc,
		"mana_hit": m_hit,
		"mana_taken": m_taken,
		"crit_chance": crit_ch,
		"spells_can_crit": spells_can_crit,
		"effects": effects
	}

func u_hp(d): return stats(d).hp
func u_ad(d): return stats(d).ad
func item_btn_rect(i): return Rect2(20, 410 + i * 36, 220, 32)
func item_slot_rect(i): return Rect2(900 + (i % 4) * 58, 372 + (i / 4) * 58, 52, 52)
func card_rect(i): return Rect2(250 + i * 150, 530, 140, 120)
func bench_rect(i): return Rect2(384 + i * 64, 446, 56, 56)
func btn_rect(i): return Rect2(900, 60 + i * 56, 230, 46)
func xp_need(): return XPN.get(level, 9999)
func round_income() -> int:
	return 7 + floori(stage / 2.0)

func tutorial_target() -> Rect2:
	match tutorial_step:
		Tutorial.BUY: return card_rect(0)
		Tutorial.SELECT: return bench_rect(0)
		Tutorial.PLACE: return Rect2(BO + Vector2(TRAINING_TILE) * CELL, Vector2(CELL, CELL))
		Tutorial.START: return btn_rect(4)
		Tutorial.LESSON: return LESSON_NEXT
		Tutorial.XP: return btn_rect(2)
		Tutorial.BUY_ITEM: return item_btn_rect(0)
		Tutorial.SELECT_ITEM: return item_slot_rect(0)
		Tutorial.EQUIP: return unit_footprint(Vector2(TRAINING_TILE), board[TRAINING_TILE])
		Tutorial.MERGE:
			if not selecting_merge: return MERGE_BUTTON
			if merge_locs.size() == 3: return MERGE_ACCEPT
			return (
				unit_footprint(Vector2(TRAINING_TILE), board[TRAINING_TILE])
				if merge_locs.is_empty() else bench_rect(merge_locs.size() - 1)
			)
		Tutorial.LOOT:
			var center := BO + Vector2(3.5, 2.5) * CELL
			return Rect2(center - Vector2(20, 20), Vector2(40, 40))
	return Rect2()

func tutorial_click(p: Vector2):
	if not tutorial_target().has_point(p):
		return
	match tutorial_step:
		Tutorial.BUY:
			buy(0)
			tutorial_step = Tutorial.SELECT
		Tutorial.SELECT:
			click_loc(["b", 0])
			tutorial_step = Tutorial.PLACE
		Tutorial.PLACE:
			click_loc(["g", TRAINING_TILE])
			tutorial_step = Tutorial.START
		Tutorial.START:
			start_battle()
		Tutorial.LESSON:
			tutorial_lesson += 1
			if tutorial_lesson == LESSONS.size():
				practice_round = 2
				enemy_formation.append({
					"d": {"n": "Archer", "t": 1, "r": true, "s": 1, "it": []},
					"pos": Vector2(4, 2)
				})
				item_shop[0] = {"n": "Sword", "t": 1, "rarity": "common", "cost": 3}
				bench[0] = board[TRAINING_TILE].duplicate(true)
				bench[1] = board[TRAINING_TILE].duplicate(true)
				tutorial_step = Tutorial.XP
		Tutorial.XP:
			do_btn(2)
			tutorial_step = Tutorial.BUY_ITEM
		Tutorial.BUY_ITEM:
			buy_item(0)
			tutorial_step = Tutorial.SELECT_ITEM
		Tutorial.SELECT_ITEM:
			sel_item = 0
			tutorial_step = Tutorial.EQUIP
		Tutorial.EQUIP:
			click_loc(["g", TRAINING_TILE])
			tutorial_step = Tutorial.MERGE
		Tutorial.MERGE:
			if not selecting_merge:
				set_merge_selection(true)
			elif merge_locs.size() == 3:
				confirm_merge()
				tutorial_step = Tutorial.START
			elif merge_locs.is_empty():
				select_merge_unit(["g", TRAINING_TILE])
			else:
				select_merge_unit(["b", merge_locs.size() - 1])
		Tutorial.LOOT:
			if loot_warning_time <= 0.0:
				finish_tutorial()

func finish_tutorial(skipped: bool = false):
	tutorial_step = Tutorial.DONE
	phase = "prep"
	qte = null
	cur_pve = false
	board.clear()
	bench.fill(null)
	items_inv.clear()
	orbs.clear()
	units.clear()
	texts.clear()
	projectiles.clear()
	loot_warning_time = 0.0
	ctime = 0.0
	aura_timer = 0.0
	gold = STARTING_GOLD
	hp = STARTING_HP
	stage = 1
	level = 3
	xp = 0
	streak = 0
	locked = false
	sel = null
	sel_item = -1
	set_merge_selection(false)
	start_prep(true)
	msg = "Tutorial skipped. Stage 1 is ready!" if skipped else "Practice complete. Stage 1 is ready!"

func pick_tier():
	var o = ODDS[level]
	var r = randi_range(1, 100)
	var acc = 0
	for i in 5:
		acc += o[i]
		if r <= acc: return i + 1
	return 1

func pick_item_rarity():
	var r = randi_range(1, 100)
	var com_weight = 80 - (level - 3) * 10
	var unc_weight = 20 + (level - 3) * 5
	com_weight = clampi(com_weight, 25, 80)
	unc_weight = clampi(unc_weight, 20, 50)
	if r <= com_weight: return "common"
	elif r <= com_weight + unc_weight: return "uncommon"
	return "rare"

func roll_item_shop():
	item_shop = []
	var pool_common = []
	var pool_uncommon = []
	var pool_rare = []
	for k in ITEM_DB.keys():
		var rar = ITEM_DB[k].rarity
		if rar == "common": pool_common.append(k)
		elif rar == "uncommon": pool_uncommon.append(k)
		else: pool_rare.append(k)

	for i in 5:
		var rar = pick_item_rarity()
		var chosen_pool = pool_common if rar == "common" else (pool_uncommon if rar == "uncommon" else pool_rare)
		var item_name = chosen_pool.pick_random()
		var it_data = ITEM_DB[item_name]
		var tier = 1
		if randf() < 0.08 and level >= 5:
			tier = 2
		var cost = it_data.cost * tier
		item_shop.append({"n": item_name, "t": tier, "cost": cost, "rarity": it_data.rarity})

func roll_shop():
	shop = []
	for i in 5:
		var t = pick_tier()
		var pool = DEFS.filter(func(x): return x[1] == t)
		var p = pool.pick_random()
		shop.append({"n": p[0], "t": p[1], "r": p[2], "s": 1, "it": []})

func start_prep(advance: bool):
	if not locked:
		roll_shop()
		roll_item_shop()
	locked = false
	if advance:
		roll_enemy_formation()
		guide_tip_index = (stage - 2) % GUIDE_TIPS.size()

func loc_get(l):
	if l[0] == "b": return bench[l[1]]
	return board.get(l[1])

func loc_set(l, u):
	if l[0] == "b": bench[l[1]] = u
	elif u == null: board.erase(l[1])
	else: board[l[1]] = u

func unit_width(unit: Dictionary) -> int:
	return 2 if unit.t >= 4 else 1

func board_anchor(cell: Vector2i) -> Vector2i:
	var left := cell - Vector2i(1, 0)
	if not board.has(cell) and board.has(left) and unit_width(board[left]) == 2:
		return left
	return cell

func board_fits() -> bool:
	for cell in board:
		if unit_width(board[cell]) == 2 and (cell.x == COLS - 1 or board.has(cell + Vector2i(1, 0))):
			return false
	return true

func merge_prompt_for(unit: Dictionary) -> String:
	if unit.s >= 3:
		return ""
	var count := 0
	for other in bench + board.values():
		if other != null and other.n == unit.n and other.s == unit.s:
			count += 1
	if count >= 3:
		return "%s merge available. Use the Merge button." % unit.n
	return ""

func set_merge_selection(active: bool):
	selecting_merge = active
	merge_locs.clear()
	merge_hint = ""
	if active:
		sel = null
		sel_item = -1

func select_merge_unit(loc: Array):
	var unit = loc_get(loc)
	if unit == null:
		return
	if merge_locs.has(loc):
		merge_locs.erase(loc)
	elif unit.s >= 3:
		merge_hint = "That unit is already at three stars."
		return
	elif not merge_locs.is_empty():
		var first = loc_get(merge_locs[0])
		if unit.n != first.n or unit.s != first.s:
			merge_hint = "Choose units of the same type and star level."
			return
		merge_locs.append(loc)
	else:
		merge_locs.append(loc)
	merge_hint = ""

func confirm_merge():
	if merge_locs.size() != 3:
		return
	var survivor = loc_get(merge_locs[0])
	survivor.s += 1
	for i in range(1, 3):
		var loc = merge_locs[i]
		for item in loc_get(loc).get("it", []):
			if items_inv.size() < 8:
				items_inv.append(item)
			else:
				gold += 3
		loc_set(loc, null)
	set_merge_selection(false)
	msg = "%s upgraded to %d stars!" % [survivor.n, survivor.s]
	var next_merge := merge_prompt_for(survivor)
	if not next_merge.is_empty():
		msg += " " + next_merge

func sell_value(u): return u.t * int(pow(3, u.s - 1)) - (1 if u.s > 1 else 0)

# ---------- input ----------
func _input(e):
	if e is InputEventMouseMotion:
		mouse_pos = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		mouse_pos = e.position
		if phase == "prep":
			for rect in hover_amounts:
				if rect.has_point(mouse_pos):
					animate_press(rect)
					break
		click(e.position)
	elif e is InputEventKey and e.pressed and not e.echo:
		if tutorial_step != Tutorial.DONE:
			if e.keycode == KEY_ENTER and tutorial_step == Tutorial.START:
				tutorial_click(btn_rect(4).get_center())
			elif e.keycode == KEY_F and tutorial_step == Tutorial.XP:
				tutorial_click(btn_rect(2).get_center())
			elif e.keycode == KEY_SPACE and tutorial_step == Tutorial.FIGHT:
				qte_press()
			return
		if selecting_merge:
			if e.keycode == KEY_ESCAPE:
				set_merge_selection(false)
			elif e.keycode == KEY_ENTER:
				confirm_merge()
			return
		match e.keycode:
			KEY_SPACE: qte_press()
			KEY_D: do_btn(0)
			KEY_F: do_btn(2)
			KEY_E: do_btn(3)
			KEY_ENTER: do_btn(4)

func click(p):
	if phase == "over":
		get_tree().reload_current_scene()
		return
	if tutorial_step != Tutorial.DONE and SKIP_TUTORIAL.has_point(p):
		finish_tutorial(true)
		return
	if phase != "prep": return
	if tutorial_step != Tutorial.DONE:
		tutorial_click(p)
		return
	if MERGE_BUTTON.has_point(p):
		animate_press(MERGE_BUTTON)
		set_merge_selection(not selecting_merge)
		return
	if selecting_merge:
		if merge_locs.size() == 3:
			if MERGE_ACCEPT.has_point(p):
				confirm_merge()
			elif MERGE_CANCEL.has_point(p):
				set_merge_selection(false)
			return
		for i in 8:
			if bench_rect(i).has_point(p):
				select_merge_unit(["b", i])
				return
		var cell := Vector2i(((Vector2(p) - BO) / CELL).floor())
		if cell.x >= 0 and cell.x < COLS and cell.y >= 3 and cell.y < ROWS:
			select_merge_unit(["g", board_anchor(cell)])
		return
	if GUIDE_MODEL.has_point(p) or GUIDE_BUBBLE.has_point(p):
		guide_tip_index = (guide_tip_index + 1) % GUIDE_TIPS.size()
		return
	for i in items_inv.size():
		if item_slot_rect(i).has_point(p):
			sel_item = -1 if sel_item == i else i
			sel = null
			return
	for i in item_shop.size():
		if item_btn_rect(i).has_point(p):
			buy_item(i)
			return
	for o in orbs:
		if loot_warning_time > 0.0:
			break
		if (BO + o * CELL + Vector2(32, 32)).distance_to(p) < 20:
			orbs.erase(o)
			gold += 1
			msg = "Loot orb: +1 gold."
			return
	for i in 5:
		if card_rect(i).has_point(p):
			buy(i)
			return
	for i in 5:
		if btn_rect(i).has_point(p):
			do_btn(i)
			return
	for i in 8:
		if bench_rect(i).has_point(p):
			click_loc(["b", i])
			return
	var c = (p - BO) / CELL
	var cx = int(floor(c.x))
	var cy = int(floor(c.y))
	if c.x >= 0 and c.y >= 0 and cx < COLS and cy >= 3 and cy < ROWS:
		click_loc(["g", board_anchor(Vector2i(cx, cy))])
	else:
		sel = null

func buy_item(i):
	var it = item_shop[i]
	if it == null: return
	if gold < it.cost:
		msg = "Not enough gold (need %dg)." % it.cost
		return
	if items_inv.size() >= 8:
		msg = "Item bench full (max 8 items)."
		return
	gold -= it.cost
	items_inv.append({"n": it.n, "t": it.t})
	item_shop[i] = null
	msg = "Bought %s (%s) for %dg!" % [it.n, "*".repeat(it.t), it.cost]

func click_loc(l):
	if sel_item >= 0:
		var tu = loc_get(l)
		if tu == null: return
		if not tu.has("it"): tu["it"] = []
		var it_to_equip = items_inv[sel_item]
		var iname = get_it_name(it_to_equip)
		var itier = get_it_tier(it_to_equip)

		var match_idx = -1
		for idx in tu.it.size():
			if get_it_name(tu.it[idx]) == iname:
				match_idx = idx
				break

		if match_idx != -1:
			var cur_t = get_it_tier(tu.it[match_idx])
			if cur_t >= 3:
				msg = "%s is already max tier (★3) on this unit." % iname
				return
			var new_t = mini(cur_t + itier, 3)
			tu.it[match_idx] = {"n": iname, "t": new_t}
			items_inv.remove_at(sel_item)
			sel_item = -1
			msg = "%s upgraded to Tier %d (%s)!" % [iname, new_t, "*".repeat(new_t)]
			return

		if tu.it.size() >= 3:
			msg = "Unit item slots full (max 3 items)."
			return

		tu.it.append({"n": iname, "t": itier})
		items_inv.remove_at(sel_item)
		sel_item = -1
		msg = "Equipped %s (%s)!" % [iname, "*".repeat(itier)]
		return
	if sel == null:
		if loc_get(l) != null: sel = l
		return
	if sel == l:
		sel = null
		return
	var a = loc_get(sel)
	var b = loc_get(l)
	loc_set(sel, b)
	loc_set(l, a)
	if board.size() > level or not board_fits():
		var full := board.size() > level
		loc_set(sel, a)
		loc_set(l, b)
		if full:
			msg = "Board full: you can field %d units at level %d." % [level, level]
		else:
			msg = "That placement needs two free tiles side by side."
	sel = null

func buy(i):
	var c = shop[i]
	if c == null: return
	if gold < c.t:
		msg = "Not enough gold."
		return
	var idx = bench.find(null)
	if idx == -1:
		msg = "Bench full."
		return
	gold -= c.t
	bench[idx] = c.duplicate()
	shop[i] = null
	var prompt := merge_prompt_for(bench[idx])
	if not prompt.is_empty():
		msg = prompt

func do_btn(i):
	if phase != "prep": return
	animate_press(btn_rect(i))
	match i:
		0:
			if gold >= 2:
				gold -= 2
				roll_shop()
				roll_item_shop()
			else: msg = "Need 2 gold."
		1:
			locked = not locked
			msg = "Shop will be kept next round." if locked else "Shop unlocked."
		2:
			if gold >= 4 and level < 9:
				gold -= 4
				add_xp(4)
			else: msg = "Need 4 gold (or already max level)."
		3:
			if sel != null:
				gold += sell_value(loc_get(sel))
				loc_set(sel, null)
				sel = null
		4: start_battle()

func add_xp(n):
	xp += n
	while level < 9 and xp >= xp_need():
		xp -= xp_need()
		level += 1
		msg = "Level up! Now level %d." % level

# ---------- battle ----------
func make_unit(d, team, pos, mult):
	var st = stats(d)
	units.append({
		"d": d, "team": team, "pos": pos,
		"radius": 0.70 if unit_width(d) == 2 else 0.30,
		"hp": st.hp * mult, "mx": st.hp * mult, "shield": 0.0,
		"ad": st.ad * mult, "base_ad": st.ad * mult,
		"armor": st.armor, "mr": st.mr, "ap": st.ap,
		"as_bonus": st.as_bonus, "mana": st.mana, "leech": st.leech,
		"mana_hit": st.mana_hit, "mana_taken": st.mana_taken,
		"crit_chance": st.crit_chance, "spells_can_crit": st.spells_can_crit,
		"effects": st.effects, "cd": 0.5, "rng": st.rng, "cast": false,
		"debuffs": [], "internal_cds": {}, "barrier_used": false,
		"anim_state": "idle", "anim_timer": randf() * 5.0, "attack_anim": 0.0,
		"facing": (1.0 if team == 0 else -1.0)
	})

func roll_enemy_formation():
	enemy_formation.clear()
	var cells = []
	for y in 3:
		for x in COLS: cells.append(Vector2(x, y))
	cells.shuffle()
	var n = mini(2 + floori((stage - 1) * 0.6), 7)
	var maxt = clampi(1 + floori(stage / 2.5), 1, 5)
	for i in n:
		var p = DEFS.pick_random()
		while p[1] > maxt: p = DEFS.pick_random()
		var s = 1
		if stage >= 7 and randf() < 0.22: s = 2
		var unit := {"n": p[0], "t": p[1], "r": p[2], "s": s, "it": []}
		var width := unit_width(unit)
		for cell in cells:
			var right = cell + Vector2(1, 0)
			if width == 2 and not cells.has(right):
				continue
			enemy_formation.append({"d": unit, "pos": cell})
			cells.erase(cell)
			if width == 2:
				cells.erase(right)
			break

func start_battle():
	if board.is_empty():
		msg = "Place at least one unit on the board first."
		return
	sel = null
	sel_item = -1
	orbs.clear()
	loot_warning_time = 0.0
	var practice := tutorial_step == Tutorial.START
	cur_pve = not practice and stage in PVE_STAGES
	phase = "combat"
	units = []
	texts = []
	projectiles = []
	ctime = 0.0
	aura_timer = 0.0
	qte = null
	for k in board:
		make_unit(board[k], 0, Vector2(k) + Vector2((unit_width(board[k]) - 1) * 0.5, 0), 1.0)
	for enemy in enemy_formation:
		var center: Vector2 = enemy.pos + Vector2((unit_width(enemy.d) - 1) * 0.5, 0)
		make_unit(enemy.d, 1, center, 0.25 if practice else 0.70 + 0.045 * stage)
	if practice:
		tutorial_step = Tutorial.FIGHT
		units[0].mana = 100.0
		notification_time = 0.0
	else:
		msg = ("PvE monsters! " if cur_pve else "") + "Fight! Press SPACE when a unit's prompt appears."

func nearest(u):
	var best = null
	var bd = 9999.0
	for e in units:
		if e.team != u.team and e.hp > 0:
			var d = u.pos.distance_to(e.pos)
			if d < bd:
				bd = d
				best = e
	return best

func pop(p, s, c):
	texts.append({"p": p, "s": s, "t": 0.8, "c": c})

func _process(dt):
	if phase == "combat": sim(dt)
	if qte == null:
		notification_time = maxf(0.0, notification_time - dt)
	loot_warning_time = maxf(0.0, loot_warning_time - dt)
	press_time = maxf(0.0, press_time - dt)
	mouse_pos = get_viewport().get_mouse_position()
	var can_hover: bool = phase == "prep" and get_viewport().get_visible_rect().has_point(mouse_pos)
	for rect in hover_amounts:
		var active := can_hover
		if rect == SKIP_TUTORIAL:
			active = tutorial_step != Tutorial.DONE
		var target := 1.0 if active and rect.has_point(mouse_pos) else 0.0
		hover_amounts[rect] = move_toward(hover_amounts[rect], target, dt * 7.0)
	for t in texts: t.t -= dt
	texts = texts.filter(func(t): return t.t > 0)
	for p in projectiles: p.t += dt
	projectiles = projectiles.filter(func(p): return p.t < p.dur)
	queue_redraw()

func apply_damage(victim, attacker, raw_dmg, is_magic) -> float:
	if victim == null or victim.hp <= 0: return 0.0
	var res = victim.mr if is_magic else victim.armor
	for deb in victim.debuffs:
		if is_magic and deb.type == "mr_shred": res *= (1.0 - deb.val)
		elif not is_magic and deb.type == "armor_shred": res *= (1.0 - deb.val)
	var mult = 100.0 / (100.0 + maxf(0.0, res))
	var dmg = maxf(1.0, raw_dmg * mult)

	if victim.shield > 0.0:
		if victim.shield >= dmg:
			victim.shield -= dmg
			dmg = 0.0
		else:
			dmg -= victim.shield
			victim.shield = 0.0

	victim.hp -= dmg
	victim.mana = minf(100.0, victim.mana + 6.0 + victim.mana_taken)

	# Barrier Gem check
	if victim.effects.has("Barrier Gem") and not victim.barrier_used and victim.hp > 0:
		if (victim.hp / victim.mx) <= 0.30:
			victim.barrier_used = true
			var bg = victim.effects["Barrier Gem"]
			victim.shield += victim.mx * bg.barrier
			pop(victim.get("pos", Vector2.ZERO), "SHIELD!", GOLD)

	# Bramble Mail reflect check
	if not is_magic and victim.effects.has("Bramble Mail") and attacker != null and attacker.hp > 0:
		var bm = victim.effects["Bramble Mail"]
		var b_cd = victim.internal_cds.get("bramble", 0.0)
		if b_cd <= 0.0:
			victim.internal_cds["bramble"] = 1.0
			var ref_dmg = raw_dmg * bm.bramble * 0.4
			apply_damage(attacker, victim, ref_dmg, true)
			pop(victim.get("pos", Vector2.ZERO), "REFLECT!", PURPLE)

	return dmg

func check_auras():
	for u in units:
		if u.hp <= 0: continue
		if u.effects.has("Sunfire Cloak"):
			var sc = u.effects["Sunfire Cloak"]
			for e in units:
				if e.team != u.team and e.hp > 0 and u.pos.distance_to(e.pos) <= 1.5:
					apply_damage(e, u, e.mx * sc.sunfire, true)
					e.debuffs.append({"type": "anti_heal", "val": 0.50, "t": 3.0})
					pop(e.pos, "BURN!", RED)
		if u.effects.has("Warhorn"):
			var wh = u.effects["Warhorn"]
			for a in units:
				if a.team == u.team and a.hp > 0 and u.pos.distance_to(a.pos) <= 1.5:
					a.debuffs.append({"type": "as_buff", "val": wh.warhorn, "t": 1.2})

func sim(dt):
	ctime += dt
	aura_timer += dt
	if aura_timer >= 1.0:
		aura_timer = 0.0
		check_auras()

	var a0 = 0
	var a1 = 0
	for u in units:
		if u.hp > 0:
			if u.team == 0: a0 += 1
			else: a1 += 1
	if a0 == 0 or a1 == 0 or ctime > 40.0:
		end_combat(a0, a1)
		return

	if qte != null:
		qte.t += dt * (0.4 if tutorial_step == Tutorial.FIGHT else 1.0)
		if qte.t > QTE_DURATION: resolve_qte(0.0, "")

	for u in units:
		if u.hp <= 0: continue
		for k in u.internal_cds.keys():
			u.internal_cds[k] = maxf(0.0, u.internal_cds[k] - dt)
		for deb in u.debuffs:
			deb.t -= dt
		u.debuffs = u.debuffs.filter(func(d): return d.t > 0)
		if u.attack_anim > 0.0:
			u.attack_anim = maxf(0.0, u.attack_anim - dt)
			if u.attack_anim <= 0.0:
				u.anim_state = "idle"
		else:
			u.anim_timer += dt * (6.0 if u.anim_state == "move" else 3.0)

	for u in units:
		if u.hp <= 0 or u.cast: continue
		var tgt = nearest(u)
		if tgt == null: continue
		if u.mana >= 100.0:
			do_cast(u, tgt)
			continue

		var as_mod = u.as_bonus
		for deb in u.debuffs:
			if deb.type == "as_slow": as_mod -= deb.val
			elif deb.type == "as_buff": as_mod += deb.val
		var attack_cd = 1.25 / maxf(0.25, 1.0 + as_mod)

		if u.pos.distance_to(tgt.pos) <= u.rng + 0.45:
			u.facing = 1.0 if (tgt.pos.x >= u.pos.x) else -1.0
			u.cd -= dt
			if u.cd <= 0:
				u.cd = attack_cd
				u.anim_state = "attack"
				u.attack_anim = 0.35
				if u.d.r:
					spawn_projectile(u.pos, tgt.pos, u.d.n)

				var raw_ad = u.ad
				if u.effects.has("Giant Slayer"):
					var gs = u.effects["Giant Slayer"]
					var bonus_p = gs.gs_giant if tgt.mx > 1000.0 else gs.gs_base
					raw_ad *= (1.0 + bonus_p)

				var dealt = apply_damage(tgt, u, raw_ad, false)

				var heal_mod = 1.0
				for deb in u.debuffs:
					if deb.type == "anti_heal": heal_mod *= (1.0 - deb.val)
				u.hp = minf(u.mx, u.hp + dealt * u.leech * heal_mod)
				u.mana = minf(100.0, u.mana + 10.0 + u.mana_hit)

				if u.effects.has("Sunder Dagger"):
					var sd = u.effects["Sunder Dagger"]
					tgt.debuffs.append({"type": "armor_shred", "val": sd.sunder, "t": 3.0})
					tgt.debuffs.append({"type": "mr_shred", "val": sd.sunder, "t": 3.0})
					pop(tgt.pos, "SHRED!", Color("4aa3df"))
				if u.effects.has("Frost Shard"):
					var fs = u.effects["Frost Shard"]
					tgt.debuffs.append({"type": "as_slow", "val": fs.frost, "t": 2.5})
					pop(tgt.pos, "SLOW!", Color("4aa3df"))
				if u.effects.has("Thunder Charm"):
					var tc = u.effects["Thunder Charm"]
					if u.internal_cds.get("thunder", 0.0) <= 0.0:
						u.internal_cds["thunder"] = 3.0
						apply_damage(tgt, u, tc.thunder, true)
						pop(tgt.pos, "BURST!", GOLD)

				if tgt.effects.has("Thorn Carapace"):
					var tc = tgt.effects["Thorn Carapace"]
					u.debuffs.append({"type": "as_slow", "val": tc.thorn, "t": 2.5})
					pop(u.pos, "SLOW!", Color("4aa3df"))

				pop(tgt.pos, str(int(dealt)), INK)
		else:
			u.anim_state = "move"
			u.facing = 1.0 if (tgt.pos.x >= u.pos.x) else -1.0
			u.pos += (tgt.pos - u.pos).normalized() * 1.6 * dt
			for o in units:
				if o == u or o.hp <= 0:
					continue
				var delta: Vector2 = u.pos - o.pos
				var gap: float = u.radius + o.radius
				if delta.length() < gap:
					var away := Vector2.RIGHT if delta.is_zero_approx() else delta.normalized()
					u.pos = o.pos + away * gap
			u.pos = u.pos.clamp(Vector2.ZERO, Vector2(COLS - 1, ROWS - 1))

func do_cast(u, tgt):
	u.mana = 0.0
	if u.team == 0 and qte == null:
		u.cast = true
		qte = {"u": u, "t": 0.0}
	else:
		apply_cast(u, tgt, 0.0)

func apply_cast(u, tgt, bonus):
	if tgt == null or tgt.hp <= 0: tgt = nearest(u)
	if tgt == null: return
	u.anim_state = "attack"
	u.attack_anim = 0.45
	u.facing = 1.0 if (tgt.pos.x >= u.pos.x) else -1.0
	if u.d.r:
		spawn_projectile(u.pos, tgt.pos, u.d.n)

	var ap_mult = 1.0 + (u.ap / 100.0)
	var raw_spell_dmg = (u.base_ad * 2.5) * ap_mult * (1.0 + bonus)

	var is_crit = false
	if u.spells_can_crit and randf() < u.crit_chance:
		raw_spell_dmg *= 1.5
		is_crit = true

	var dealt = apply_damage(tgt, u, raw_spell_dmg, true)

	var heal_mod = 1.0
	for deb in u.debuffs:
		if deb.type == "anti_heal": heal_mod *= (1.0 - deb.val)
	u.hp = minf(u.mx, u.hp + dealt * u.leech * heal_mod)

	for e in units:
		if e.team != u.team and e.hp > 0 and e != tgt and e.pos.distance_to(tgt.pos) < 1.6:
			apply_damage(e, u, raw_spell_dmg * 0.4, true)

	var txt = "CRIT!" if is_crit else ("POW!" if bonus > 0 else "SHING!")
	pop(tgt.pos, txt, PURPLE if is_crit else (RED if bonus > 0 else GOLD))

func qte_press():
	if qte == null: return
	if qte_in_gold(qte.t): resolve_qte(0.3, "PERFECT!")
	else: resolve_qte(0.15, "Good")

func qte_in_gold(time: float) -> bool:
	return time >= QTE_GOLD_START and time <= QTE_GOLD_END

func resolve_qte(bonus, label):
	var u = qte.u
	u.cast = false
	qte = null
	if u.hp <= 0: return
	if label != "": pop(u.pos + Vector2(0, -0.6), label, PURPLE)
	apply_cast(u, nearest(u), bonus)

func end_combat(a0, a1):
	qte = null
	if tutorial_step == Tutorial.FIGHT:
		phase = "prep"
		texts.clear()
		projectiles.clear()
		if practice_round == 1:
			tutorial_step = Tutorial.LESSON
		else:
			tutorial_step = Tutorial.LOOT
			orbs.append(Vector2(3, 2))
			loot_warning_time = LOOT_WARNING_TIME
		notification_time = 0.0
		return
	var win = a1 == 0 or (a0 > a1 and a0 > 0)
	if a0 == 0: win = false
	if win: streak = streak + 1 if streak > 0 else 1
	else: streak = streak - 1 if streak < 0 else -1
	var n = absi(streak)
	var sb = 0 if n < 2 else (1 if n < 4 else (2 if n == 4 else 3))
	var interest = mini(gold / 10, 5)
	var base := round_income()
	var inc = base + interest + sb + (2 if win else 0)
	gold += inc
	add_xp(3)
	var res = "WIN" if win else "LOSS"
	if not win:
		var dmg = mini(8, 2 + a1)
		hp -= dmg
		res += " (-%d HP)" % dmg
	msg = "%s. +%d gold (%d base, %d interest, %d streak)." % [res, inc, base, interest, sb]
	if win:
		for e in units:
			if e.team == 1 and orbs.size() < 3: orbs.append(e.pos)
		if not orbs.is_empty():
			loot_warning_time = LOOT_WARNING_TIME
			msg += " Gold orbs incoming. Click to collect."
	if cur_pve and win:
		if items_inv.size() < 8:
			var drop = ITEM_DB.keys().pick_random()
			var drop_tier = 2 if (stage >= 7 and randf() < 0.25) else 1
			items_inv.append({"n": drop, "t": drop_tier})
			msg += " Found %s %s!" % [drop, "*".repeat(drop_tier)]
	if win:
		stage += 1
	else:
		msg += " Retry stage %d." % stage
	if hp <= 0: phase = "over"
	elif stage > 10: phase = "over"
	else:
		phase = "prep"
		start_prep(win)

# ---------- drawing ----------
func T(p, s, size = 16, col = INK, w = -1.0, al = HORIZONTAL_ALIGNMENT_LEFT):
	draw_string(ThemeDB.fallback_font, p, s, al, w, size, col)

func draw_gold_star(center: Vector2, radius: float, is_filled = true):
	var pts = PackedVector2Array()
	for i in 10:
		var a = -PI * 0.5 + i * (PI / 5.0)
		var r = radius if (i % 2 == 0) else (radius * 0.42)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	if is_filled:
		draw_colored_polygon(pts, Color("f7c828"))
		draw_circle(center + Vector2(0, -radius * 0.28), radius * 0.18, Color("fff8c8"))
	pts.append(pts[0])
	draw_polyline(pts, Color("8a5b00"), 1.2)

func draw_unit_stars(center: Vector2, count: int, sz: float = 6.0):
	var spacing = sz * 2.1
	var start_x = center.x - (count - 1) * spacing * 0.5
	for i in count:
		draw_gold_star(Vector2(start_x + i * spacing, center.y), sz, true)

func draw_fantasy_unit(pos: Vector2, d: Dictionary, team: int = 0, anim_state: String = "idle", anim_t: float = 0.0, attack_t: float = 0.0, facing: float = 1.0):
	var f = 1.0 if facing >= 0.0 else -1.0
	var bob = 0.0
	var lunge = 0.0
	var swing = 0.0
	var wing_flap = 0.0

	if anim_state == "move":
		bob = abs(sin(anim_t * 6.0)) * -4.0
		lunge = sin(anim_t * 6.0) * 2.0 * f
		wing_flap = sin(anim_t * 8.0) * 10.0
	elif anim_state == "attack":
		var prog = clampf(1.0 - (attack_t / 0.35), 0.0, 1.0)
		lunge = sin(prog * PI) * 8.0 * f
		swing = sin(prog * PI)
		wing_flap = sin(prog * PI * 2.0) * 12.0
	else:
		bob = sin(anim_t * 3.0) * 2.0
		wing_flap = sin(anim_t * 2.5) * 4.0

	var c = pos + Vector2(lunge, bob)

	# Ground shadow & ground team ring
	draw_arc(pos + Vector2(0, 18), 18, 0, TAU, 24, Color(0, 0, 0, 0.3), 3.0)
	var team_ring_col = Color("38b000") if team == 0 else Color("d9381e")
	draw_arc(pos + Vector2(0, 18), 18, 0, TAU, 24, team_ring_col, 2.5)

	match d.n:
		"Squire":
			# Leather tunic & bronze headband warrior with shortsword & round wooden buckler
			draw_rect(Rect2(c + Vector2(-8 * f if f < 0 else -8, -6), Vector2(16, 18)), Color("7a4c33"))
			draw_rect(Rect2(c + Vector2(-8 * f if f < 0 else -8, 2), Vector2(16, 4)), Color("422919"))
			draw_circle(c + Vector2(0, -12), 9, Color("edd0b4"))
			draw_arc(c + Vector2(0, -14), 9, -PI * 0.9, -PI * 0.1, 10, Color("523522"), 3.5)
			# Buckler
			draw_circle(c + Vector2(-12 * f, 2), 7, Color("6b4226"))
			draw_circle(c + Vector2(-12 * f, 2), 3, Color("c2c8d0"))
			# Sword thrust
			var sp = c + Vector2(10 * f + swing * 7 * f, -2 - swing * 6)
			draw_line(c + Vector2(6 * f, 4), sp, Color("c2c8d0"), 3.0)

		"Archer":
			# Forest ranger with green hood, quiver, and recurve longbow
			draw_rect(Rect2(c + Vector2(-7 * f if f < 0 else -7, -5), Vector2(14, 18)), Color("326932"))
			draw_line(c + Vector2(-8 * f, -2), c + Vector2(-12 * f, -16), Color("523522"), 3.5)
			draw_circle(c + Vector2(-12 * f, -17), 2.5, Color("ffffff"))
			draw_circle(c + Vector2(0, -12), 9, Color("255425"))
			draw_circle(c + Vector2(2 * f, -11), 6, Color("edd0b4"))
			var bow_c = c + Vector2(10 * f, 0)
			draw_arc(bow_c, 13, -PI * 0.45, PI * 0.45, 10, Color("543015"), 3.0)
			if anim_state == "attack":
				draw_line(bow_c - Vector2(8 * f, 0), bow_c + Vector2(8 * f, 0), Color("e0d8c8"), 2.0)

		"Knight":
			# Heavy steel plate armor with heater shield and broadsword
			draw_rect(Rect2(c + Vector2(-9 * f if f < 0 else -9, -6), Vector2(18, 19)), Color("8fa0b0"))
			draw_line(c + Vector2(-9 * f, 3), c + Vector2(9 * f, 3), GOLD, 2.0)
			draw_circle(c + Vector2(0, -13), 9, Color("768898"))
			draw_rect(Rect2(c + Vector2(-5 * f if f < 0 else -5, -14), Vector2(10, 3)), Color("1a1617"))
			draw_arc(c + Vector2(-2 * f, -22), 8, -PI * 0.8, -PI * 0.1, 8, Color("d02020"), 4.0)
			# Kite shield
			var sh_pts = PackedVector2Array([c + Vector2(-14 * f, -8), c + Vector2(-6 * f, -8), c + Vector2(-8 * f, 12), c + Vector2(-12 * f, 12)])
			draw_colored_polygon(sh_pts, Color("1f488a"))
			draw_polyline(PackedVector2Array([sh_pts[0], sh_pts[1], sh_pts[2], sh_pts[3], sh_pts[0]]), GOLD, 1.5)
			# Sword slash
			var sw_p = c + Vector2(8 * f + swing * 8 * f, -14 - swing * 6)
			draw_line(c + Vector2(6 * f, 5), sw_p, Color("d8e0e8"), 3.5)

		"Mage":
			# Arcane wizard with pointed hat, rune robes, and glowing sapphire staff
			var r_pts = PackedVector2Array([c + Vector2(-8, -6), c + Vector2(8, -6), c + Vector2(11, 14), c + Vector2(-11, 14)])
			draw_colored_polygon(r_pts, Color("1c3e7a"))
			draw_circle(c + Vector2(0, -9), 6, Color("e0e0e0"))
			# Hat
			var hat_pts = PackedVector2Array([c + Vector2(-11, -14), c + Vector2(11, -14), c + Vector2(0, -32)])
			draw_colored_polygon(hat_pts, Color("1c3e7a"))
			draw_line(c + Vector2(-13, -14), c + Vector2(13, -14), GOLD, 2.0)
			# Staff & glowing gem
			var staff_top = c + Vector2(11 * f, -18)
			draw_line(c + Vector2(9 * f, 14), staff_top, Color("5c3818"), 3.0)
			draw_circle(staff_top, 5.0, Color("38d9ff"))
			draw_arc(staff_top, 8.0, 0, TAU, 12, Color("a8f0ff"), 1.5)

		"Rogue":
			# Shadow assassin with dark cowl and dual poison daggers
			draw_rect(Rect2(c + Vector2(-7 * f if f < 0 else -7, -5), Vector2(14, 18)), Color("252228"))
			draw_circle(c + Vector2(0, -12), 9, Color("1a171c"))
			draw_circle(c + Vector2(3 * f, -12), 2, Color("70ff40"))
			# Dual daggers
			draw_line(c + Vector2(6 * f, 2), c + Vector2(13 * f + swing * 6 * f, -5), Color("b0bec5"), 2.5)
			draw_line(c + Vector2(-6 * f, 2), c + Vector2(-11 * f - swing * 4 * f, 6), Color("b0bec5"), 2.5)
			draw_circle(c + Vector2(13 * f + swing * 6 * f, -5), 2.0, Color("44dd55"))

		"Cleric":
			# Ivory priest robes, holy halo, and golden sun mace
			var cl_pts = PackedVector2Array([c + Vector2(-8, -6), c + Vector2(8, -6), c + Vector2(10, 14), c + Vector2(-10, 14)])
			draw_colored_polygon(cl_pts, Color("f6f4ea"))
			draw_line(c + Vector2(-4, -6), c + Vector2(-4, 14), GOLD, 2.0)
			draw_line(c + Vector2(4, -6), c + Vector2(4, 14), GOLD, 2.0)
			draw_circle(c + Vector2(0, -11), 8, Color("edd0b4"))
			# Golden Halo
			draw_arc(c + Vector2(0, -25), 8, 0, TAU, 16, Color("ffd700"), 2.0)
			# Sun mace
			var mace_top = c + Vector2(10 * f, -14)
			draw_line(c + Vector2(8 * f, 10), mace_top, GOLD, 3.0)
			draw_circle(mace_top, 4.5, Color("ffd700"))

		"Golem":
			# Massive stone behemoth with glowing runic fissures
			var g_pts = PackedVector2Array([c + Vector2(-14, -10), c + Vector2(14, -10), c + Vector2(11, 14), c + Vector2(-11, 14)])
			draw_colored_polygon(g_pts, Color("4d4a48"))
			# Runic amber cracks
			draw_line(c + Vector2(-6, -6), c + Vector2(4, 2), Color("ff7a00"), 2.0)
			draw_line(c + Vector2(4, 2), c + Vector2(-2, 10), Color("ff7a00"), 2.0)
			# Stone head
			draw_rect(Rect2(c + Vector2(-8, -20), Vector2(16, 10)), Color("3e3b39"))
			draw_line(c + Vector2(-5, -15), c + Vector2(-2, -15), Color("ffaa00"), 2.0)
			draw_line(c + Vector2(2, -15), c + Vector2(5, -15), Color("ffaa00"), 2.0)
			# Bolder fists
			draw_circle(c + Vector2(-15 * f, 4 + swing * 6), 6.5, Color("44403e"))
			draw_circle(c + Vector2(15 * f, 4 + swing * 6), 6.5, Color("44403e"))

		"Witch":
			# Deep violet gown, wide-brimmed witch hat, and swirling shadow orb
			var w_pts = PackedVector2Array([c + Vector2(-8, -6), c + Vector2(8, -6), c + Vector2(11, 14), c + Vector2(-11, 14)])
			draw_colored_polygon(w_pts, Color("38134d"))
			draw_circle(c + Vector2(0, -11), 8, Color("edd0b4"))
			# Crooked witch hat
			var w_hat = PackedVector2Array([c + Vector2(-12, -14), c + Vector2(12, -14), c + Vector2(-4, -30), c + Vector2(5, -34)])
			draw_colored_polygon(w_hat, Color("270d36"))
			draw_line(c + Vector2(-15, -14), c + Vector2(15, -14), Color("5a217a"), 2.5)
			# Swirling shadow orb
			var orb_p = c + Vector2(12 * f, -6 + sin(anim_t * 4.0) * 3.0)
			draw_circle(orb_p, 5.5, Color("9b22c7"))
			draw_arc(orb_p, 8.0, 0, TAU, 12, Color("e066ff"), 1.5)

		"Dragon":
			# Ferocious crimson scaled drake with flapping wings and horns
			# Wings
			var lw = PackedVector2Array([c + Vector2(-4, -4), c + Vector2(-20, -18 + wing_flap), c + Vector2(-14, 2)])
			var rw = PackedVector2Array([c + Vector2(4, -4), c + Vector2(20, -18 + wing_flap), c + Vector2(14, 2)])
			draw_colored_polygon(lw, Color("701010"))
			draw_colored_polygon(rw, Color("701010"))
			# Body & belly
			draw_circle(c + Vector2(0, 2), 12, Color("b81d1d"))
			draw_circle(c + Vector2(0, 4), 7, Color("d9984e"))
			# Head & golden horns
			draw_circle(c + Vector2(7 * f, -10), 8, Color("c92626"))
			draw_line(c + Vector2(5 * f, -16), c + Vector2(-4 * f, -26), Color("e0b020"), 3.0)
			draw_circle(c + Vector2(9 * f, -10), 2, Color("ffa000"))
			if anim_state == "attack":
				# Fire cone
				var fire_p = PackedVector2Array([c + Vector2(15 * f, -10), c + Vector2(28 * f, -18), c + Vector2(28 * f, -2)])
				draw_colored_polygon(fire_p, Color("ff6600"))

		"Sage":
			# Celestial starlight robes with 3 orbiting mystic spheres
			var s_pts = PackedVector2Array([c + Vector2(-8, -6), c + Vector2(8, -6), c + Vector2(11, 14), c + Vector2(-11, 14)])
			draw_colored_polygon(s_pts, Color("0e1d36"))
			draw_circle(c + Vector2(0, -9), 7, Color("e8e8e8"))
			draw_circle(c + Vector2(0, -14), 8, Color("edd0b4"))
			draw_arc(c + Vector2(0, -21), 6, -PI * 0.8, -PI * 0.2, 8, Color("fff8c8"), 2.0)
			# Orbiting spheres
			var s_cols = [GOLD, Color("38d9ff"), Color("bf36ff")]
			for i in 3:
				var a = anim_t * 2.5 + i * (TAU / 3.0)
				draw_circle(c + Vector2(cos(a) * 16, sin(a) * 8 - 4), 3.5, s_cols[i])

		_:
			# Default high fantasy adventurer token
			draw_circle(c, 16, TIER_COL[clampi(d.t - 1, 0, 4)])
			draw_arc(c, 16, 0, TAU, 20, INK, 2.0)

func token(c, d, team = 0, anim_state = "idle", anim_t = 0.0, attack_t = 0.0, facing = 1.0):
	# 1. Draw 2D fantasy character model
	draw_fantasy_unit(c, d, team, anim_state, anim_t, attack_t, facing)

	# 2. Overhead Unit Name Badge
	var font = ThemeDB.fallback_font
	var name_str = d.n
	var nw = font.get_string_size(name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11).x + 8.0
	draw_rect(Rect2(c.x - nw * 0.5, c.y - 34, nw, 14), Color(0, 0, 0, 0.7))
	T(c + Vector2(-nw * 0.5, -23), name_str, 11, PARCH, nw, HORIZONTAL_ALIGNMENT_CENTER)

	# 3. Gold Stars above head
	draw_unit_stars(c + Vector2(0, -42), d.s, 4.5)

	# 4. Equipped item pips on ground ring
	var its = d.get("it", [])
	if not its.is_empty():
		var pip_sz = 6.0
		var pip_sp = 8.0
		var p_start = c.x - (its.size() - 1) * pip_sp * 0.5
		for idx in its.size():
			var iname = get_it_name(its[idx])
			var rar = ITEM_DB[iname].rarity if ITEM_DB.has(iname) else "common"
			var col = RARITY_COLS.get(rar, GOLD)
			var px = p_start + idx * pip_sp - pip_sz * 0.5
			draw_rect(Rect2(px, c.y + 24, pip_sz, pip_sz), col)
			draw_rect(Rect2(px, c.y + 24, pip_sz, pip_sz), INK, false, 1.0)

func get_unit_hover_info(u, is_combat: bool = false, show_sell_value: bool = true) -> Dictionary:
	var d = u.d if is_combat else u
	var st = stats(d)
	var title = "%s  (Tier %d %s)" % [d.n, d.t, "Ranged" if d.r else "Melee"]
	var lines = []

	if is_combat:
		lines.append({"t": "HP: %d / %d   Mana: %d / 100" % [int(u.hp), int(u.mx), int(u.mana)], "c": GOLD})
	else:
		lines.append({"t": "Base HP: %d   Base AD: %d" % [int(st.hp), int(st.ad)], "c": GOLD})

	lines.append({"t": "AD: %d | Armor: %d | MR: %d | AP: %d" % [int(st.ad), int(st.armor), int(st.mr), int(st.ap)], "c": Color("5cdb7a")})
	lines.append({"t": "Attack Speed: +%d%%   Range: %.1f tiles" % [int(st.as_bonus * 100), st.rng], "c": Color("b8a994")})
	if unit_width(d) == 2:
		lines.append({"t": "Footprint: 2 tiles side by side", "c": GOLD})

	var its = d.get("it", [])
	if its.is_empty():
		lines.append({"t": "Equipped Items: None (0/3 slots)", "c": Color("8a7a5c")})
	else:
		lines.append({"t": "Equipped Items (%d/3):" % its.size(), "c": PARCH})
		for idx in its.size():
			var iname = get_it_name(its[idx])
			var itier = get_it_tier(its[idx])
			var rar = ITEM_DB[iname].rarity if ITEM_DB.has(iname) else "common"
			var col = RARITY_COLS.get(rar, GOLD)
			lines.append({"t": " • %s %s: %s" % [iname, "*".repeat(itier), get_it_desc(iname, itier)], "c": col})

	if not is_combat and show_sell_value:
		lines.append({"t": "Sell Value: %d Gold" % sell_value(d), "c": Color("e69a2b")})

	return {"title": title, "col": TIER_COL[clampi(d.t - 1, 0, 4)], "lines": lines}

func animate_press(rect: Rect2):
	pressed_rect = rect
	press_time = 0.18

func hover_strength(rect: Rect2) -> float:
	return smoothstep(0.0, 1.0, hover_amounts.get(rect, 0.0))

func press_strength(rect: Rect2) -> float:
	return smoothstep(0.0, 1.0, press_time / 0.18) if rect == pressed_rect else 0.0

func animated_rect(rect: Rect2, lift: float) -> Rect2:
	return Rect2(rect.position + Vector2(0, press_strength(rect) * 3.0 - hover_strength(rect) * lift), rect.size)

func draw_paper_panel(rect: Rect2, fill: Color, edge: Color, shadow_height: float = 3.0):
	draw_rect(Rect2(rect.position + Vector2(0, shadow_height), rect.size), Color(INK, 0.20))
	draw_rect(rect, fill)
	draw_rect(rect, edge, false, 1.0)
	draw_line(rect.position + Vector2(2, 2), rect.position + Vector2(rect.size.x - 2, 2), Color(PAPER_HIGHLIGHT, 0.56))

func button(bounds: Rect2, label: String, col: Color):
	var hover := hover_strength(bounds)
	var r := animated_rect(bounds, 3.0)
	draw_paper_panel(r, col.lightened(hover * 0.22).darkened(press_strength(bounds) * 0.14), PAPER_EDGE.lerp(INK, hover), 4.0 + hover * 2.0)
	T(r.position + Vector2(0, r.size.y / 2.0 + 6), label, 17, INK, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func draw_merge_prompt():
	if merge_locs.size() == 3:
		draw_rect(get_viewport_rect(), Color(INK, 0.38))
		var first = loc_get(merge_locs[0])
		draw_paper_panel(MERGE_CONFIRM_PANEL, PAPER_HIGHLIGHT, PAPER_EDGE, 5.0)
		T(MERGE_CONFIRM_PANEL.position + Vector2(0, 30), "Merge three %s units?" % first.n, 22, INK, 420, HORIZONTAL_ALIGNMENT_CENTER)
		T(MERGE_CONFIRM_PANEL.position + Vector2(0, 56), "The first unit stays and gains a star.", 15, INK, 420, HORIZONTAL_ALIGNMENT_CENTER)
		button(MERGE_ACCEPT, "Confirm merge", GOLD.lightened(0.3))
		button(MERGE_CANCEL, "Cancel", KRAFT)
	else:
		draw_paper_panel(MERGE_SELECT_PANEL, PAPER_HIGHLIGHT, PAPER_EDGE, 5.0)
		T(MERGE_SELECT_PANEL.position + Vector2(0, 30), "Select the units (%d/3)" % merge_locs.size(), 22, INK, 420, HORIZONTAL_ALIGNMENT_CENTER)
		var hint := merge_hint if not merge_hint.is_empty() else "Choose three units of the same type and star level."
		T(MERGE_SELECT_PANEL.position + Vector2(0, 58), hint, 15, INK, 420, HORIZONTAL_ALIGNMENT_CENTER)

func draw_notification():
	if notification_time <= 0.0 or phase == "over":
		return
	var entrance := smoothstep(0.0, 0.24, TOAST_DURATION - notification_time)
	var alpha := entrance * smoothstep(0.0, 0.42, notification_time)
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var size := Vector2(maxf(260.0, text_width + 48.0), 52.0)
	var center := get_viewport_rect().get_center()
	center.y += lerpf(12.0, 0.0, entrance)
	var r := Rect2(center - size / 2.0, size)
	draw_rect(Rect2(r.position + Vector2(0, 5), size), Color(INK, alpha * 0.28))
	draw_rect(r, Color("30231F", alpha * 0.96))
	draw_rect(r, Color(GOLD, alpha), false, 1.0)
	draw_rect(Rect2(r.position + Vector2(0, 0), Vector2(4, size.y)), Color(GOLD, alpha))
	T(r.position + Vector2(0, 32), msg, 17, Color(PAPER_HIGHLIGHT, alpha), size.x, HORIZONTAL_ALIGNMENT_CENTER)

func draw_tutorial_guide():
	var panel := Rect2(258, 12, 610, 122)
	draw_paper_panel(panel, Color("30231F"), GOLD, 6.0)
	var center := Vector2(303, 75)
	draw_circle(center, 39, Color("62446F"))
	draw_arc(center, 39, 0, TAU, 40, GOLD, 1.5, true)
	draw_set_transform(center, 0.0, Vector2(1.65, 1.65))
	draw_fantasy_unit(Vector2.ZERO, {"n": "Sage"}, 0, "idle", Time.get_ticks_msec() / 1000.0)
	draw_set_transform(Vector2.ZERO)
	T(Vector2(356, 38), "GUIDE WIZARD  /  PRACTICE %d OF 2" % practice_round, 15, GOLD)
	var lines: Array = LESSONS[tutorial_lesson] if tutorial_step == Tutorial.LESSON else TUTORIAL_LINES[tutorial_step]
	for i in lines.size():
		T(Vector2(356, 64 + i * 21), lines[i], 14, PAPER_HIGHLIGHT)
	if tutorial_step == Tutorial.LESSON:
		button(LESSON_NEXT, "Continue", GOLD.lightened(0.35))

func draw_guide():
	var center := Vector2(39, 346)
	var idle := Time.get_ticks_msec() / 1000.0
	draw_fantasy_unit(center, {"n": "Sage"}, 0, "idle", idle)
	T(Vector2(17, 381), "GUIDE", 11, INK, 45, HORIZONTAL_ALIGNMENT_CENTER)
	var hover := maxf(hover_strength(GUIDE_MODEL), hover_strength(GUIDE_BUBBLE))
	var bubble := animated_rect(GUIDE_BUBBLE, 1.0)
	var fill := Color("FFF4DE").lightened(hover * 0.4)
	draw_paper_panel(bubble, fill, PAPER_EDGE, 2.0)
	var tail := PackedVector2Array([bubble.position + Vector2(1, 21),
		bubble.position + Vector2(-9, 30), bubble.position + Vector2(1, 33)])
	draw_colored_polygon(tail, fill)
	draw_polyline(tail, PAPER_EDGE, 1.0, true)
	var lines: Array = ["Click a unit, then a tile.", "Use the bottom three rows.", "Click me for a tip."]
	if guide_tip_index >= 0:
		lines = GUIDE_TIPS[guide_tip_index]
	for i in lines.size():
		T(bubble.position + Vector2(9, 16 + 17 * i), lines[i], 12)

func draw_spell_qte():
	var panel := Rect2(392, 146, 496, 119)
	var track := Rect2(416, 200, 448, 30)
	var key := Rect2(416, 158, 82, 26)
	var in_gold := qte_in_gold(qte.t)
	var accent := Color("FFE09A") if in_gold else GOLD
	var gold_left := track.position.x + track.size.x * QTE_GOLD_START / QTE_DURATION
	var gold_right := track.position.x + track.size.x * QTE_GOLD_END / QTE_DURATION
	var marker_x := track.position.x + track.size.x * clampf(qte.t / QTE_DURATION, 0.0, 1.0)
	var gold_zone := Rect2(gold_left, track.position.y, gold_right - gold_left, track.size.y)

	draw_paper_panel(panel, Color("302338"), accent, 6.0)
	draw_paper_panel(key, accent if in_gold else Color("F5E8D4"), Color("917092"), 3.0)
	T(key.position + Vector2(0, 18), "SPACE", 14, INK, key.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	T(Vector2(512, 177), "Press when the marker reaches gold", 16, PAPER_HIGHLIGHT)

	draw_rect(track.grow(2), Color("76647C"))
	draw_rect(track, Color("19131F"))
	draw_rect(Rect2(track.position, Vector2(marker_x - track.position.x, track.size.y)), Color("51405F"))
	draw_rect(gold_zone, accent)
	for x in range(1, 8):
		var tick_x := track.position.x + track.size.x * x / 8.0
		var tick_color := Color(INK, 0.32) if tick_x >= gold_left and tick_x <= gold_right else Color(PAPER_HIGHLIGHT, 0.35)
		draw_line(Vector2(tick_x, track.end.y - 6), Vector2(tick_x, track.end.y), tick_color, 1.0, true)
	draw_rect(gold_zone, PAPER_HIGHLIGHT, false, 1.0)

	var marker_center := Vector2(marker_x, track.get_center().y)
	draw_line(marker_center - Vector2(0, 20), marker_center + Vector2(0, 20), INK, 6.0, true)
	draw_line(marker_center - Vector2(0, 19), marker_center + Vector2(0, 19), Color.WHITE, 2.0, true)
	var diamond := PackedVector2Array([Vector2(marker_x, 190), Vector2(marker_x + 6, 196),
		Vector2(marker_x, 202), Vector2(marker_x - 6, 196)])
	draw_colored_polygon(diamond, Color.WHITE)
	T(Vector2(gold_left - 20, 252), "PRESS NOW" if in_gold else "PERFECT WINDOW",
		13, accent, gold_zone.size.x + 40, HORIZONTAL_ALIGNMENT_CENTER)

func unit_footprint(cell: Vector2, unit: Dictionary) -> Rect2:
	return Rect2(BO + cell * CELL, Vector2(unit_width(unit) * CELL, CELL))

func draw_forest_tree(base: Vector2, height: float, tint: Color):
	draw_circle(base + Vector2(7, -3), height * 0.28, Color("1D351E", 0.20))
	draw_rect(Rect2(base - Vector2(3, height * 0.33), Vector2(6, height * 0.33)), Color("65442F"))
	for layer in range(3):
		var y := base.y - height * (1.0 - layer * 0.18)
		var width := height * (0.19 + layer * 0.055)
		var points := PackedVector2Array([Vector2(base.x, y), Vector2(base.x + width, y + height * 0.44),
			Vector2(base.x + width * 0.20, y + height * 0.40),
			Vector2(base.x - width * 0.14, y + height * 0.47), Vector2(base.x - width, y + height * 0.41)])
		draw_colored_polygon(points, tint.lightened(float(2 - layer) * 0.04))

func draw_forest_surroundings():
	var sky := Color("E5E9C7")
	var ground := Color("B4BE8E")
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)]),
		PackedColorArray([sky, sky, ground, ground]))
	draw_rect(Rect2(8, 8, 1264, 704), Color("405637", 0.45), false, 1.0)
	draw_rect(Rect2(252, 0, 625, 516), Color("58784B", 0.22))

	for i in range(9):
		var x := 258.0 + float(i % 3) * 28.0
		var y := 92.0 + float(i / 3) * 159.0 + float(i % 3) * 18.0
		draw_forest_tree(Vector2(x, y), 54.0 + (i % 4) * 14.0, Color("426749"))
		draw_forest_tree(Vector2(1152.0 - x, y + 18.0), 48.0 + (i % 4) * 13.0, Color("395C43"))

	var time := Time.get_ticks_msec() / 1000.0
	for i in range(12):
		var x := (287.0 if i % 2 == 0 else 856.0) + sin(time * 0.7 + i * 2.4) * 17.0
		var y := 44.0 + i * 36.0 + cos(time + i) * 9.0
		var glow := 0.45 + 0.28 * sin(time * 2.3 + i)
		draw_circle(Vector2(x, y), 5, Color("FFF0A7", glow * 0.24))
		draw_circle(Vector2(x, y), 1.8, Color("FFF0A7", glow))

	var field := Rect2(BO, Vector2(COLS, ROWS) * CELL)
	draw_rect(field.grow(12), Color("293D2B", 0.25))
	draw_paper_panel(field.grow(8), Color("524535"), Color("354430"), 5.0)
	draw_rect(field.grow(4), Color("849143"), false, 2.0)
	draw_paper_panel(Rect2(374, 425, 522, 84), Color("5F5B3B"), Color("3C4C35"), 4.0)

func draw_forest_tile(tile: Rect2, x: int, y: int):
	var grass := Color("A7BA78") if y >= 3 else Color("9BA57B")
	if (x + y) % 2 == 0:
		grass = grass.lightened(0.10)
	var hover := hover_strength(tile)
	var base := grass.lerp(Color("EBECC2"), hover * 0.68).darkened(press_strength(tile) * 0.14)
	draw_rect(tile, base)
	draw_rect(tile, Color("5D714E").lerp(PURPLE, hover * 0.60), false, 1.0)
	var corner := tile.position + Vector2(9 + (x * 11 + y * 7) % 23, 54)
	var moss := Color("526C43", 0.45)
	for i in range(3):
		draw_line(corner + Vector2(i * 3, 0), corner + Vector2(i * 4 - 4, -5 - (i % 2) * 3), moss, 1.0, true)
	if (x * 3 + y * 5) % 4 == 0:
		var stone := tile.position + Vector2(50, 14)
		draw_circle(stone + Vector2(0, 1), 4.5, Color("657258", 0.45))
		draw_circle(stone, 3.5, Color("D7DCAC", 0.7))
	if y == 3:
		draw_line(tile.position, tile.position + Vector2(tile.size.x, 0), Color("55634C"), 2.0)

func get_equip_preview(u, s_name: String, s_tier: int) -> Dictionary:
	var title = "%s %s" % [u.n, "*".repeat(u.s)]
	var lines = []
	var its = u.get("it", [])

	if its.is_empty():
		lines.append({"t": "Equipped: None (0/3 slots)", "c": Color("8a7a5c")})
	else:
		lines.append({"t": "Equipped Items (%d/3):" % its.size(), "c": PARCH})
		for idx in its.size():
			var iname = get_it_name(its[idx])
			var itier = get_it_tier(its[idx])
			lines.append({"t": " • %s %s: %s" % [iname, "*".repeat(itier), get_it_desc(iname, itier)], "c": Color("e8d8c1")})

	var match_idx = -1
	for idx in its.size():
		if get_it_name(its[idx]) == s_name:
			match_idx = idx
			break

	if match_idx != -1:
		var cur_t = get_it_tier(its[match_idx])
		if cur_t >= 3:
			lines.append({"t": "CANNOT EQUIP: %s is already Max Tier (★3)!" % s_name, "c": RED})
		else:
			var new_t = mini(cur_t + s_tier, 3)
			lines.append({"t": "► MERGE UPGRADE: %s %s -> %s" % [s_name, "*".repeat(cur_t), "*".repeat(new_t)], "c": GOLD})
			lines.append({"t": "  Current: " + get_it_desc(s_name, cur_t), "c": Color("b8a994")})
			lines.append({"t": "  Upgraded: " + get_it_desc(s_name, new_t), "c": Color("5cdb7a")})
			lines.append({"t": "  (Merges into existing slot)", "c": Color("8a7a5c")})
	else:
		if its.size() >= 3:
			lines.append({"t": "CANNOT EQUIP: Unit slots full (3/3 items)!", "c": RED})
		else:
			lines.append({"t": "► NEW EQUIP (Slot %d/3): %s %s" % [its.size() + 1, s_name, "*".repeat(s_tier)], "c": Color("4aa3df")})
			lines.append({"t": "  Grants: " + get_it_desc(s_name, s_tier), "c": Color("5cdb7a")})

	return {"title": title, "col": GOLD, "lines": lines}

func draw_tooltip_box(pos: Vector2, title: String, title_col: Color, lines: Array, portrait = null):
	var pad := 10.0
	var font = ThemeDB.fallback_font
	var title_sz := 15
	var line_sz := 13

	var max_w = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_sz).x
	for l in lines:
		var txt = l.t if l is Dictionary else str(l)
		var sz = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, line_sz).x
		if sz > max_w: max_w = sz
	var box_w = maxf(240.0, max_w + pad * 2.0 + 12.0)
	var box_h = pad * 2.0 + 18.0 + lines.size() * 18.0 + 8.0
	if portrait != null:
		box_w += 87.0

	var bx = pos.x + 16.0
	var by = pos.y + 16.0
	if bx + box_w > 1260.0: bx = pos.x - box_w - 12.0
	if by + box_h > 700.0: by = 700.0 - box_h
	if bx < 10.0: bx = 10.0
	if by < 10.0: by = 10.0

	var r := Rect2(bx, by, box_w, box_h)
	draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.45))
	draw_rect(r, Color("141112"))
	draw_rect(r, title_col, false, 2)
	T(r.position + Vector2(pad, 18), title, title_sz, title_col)
	draw_line(r.position + Vector2(pad, 25), r.position + Vector2(box_w - pad, 25), Color("3a3435"), 1.0)

	var y_off = 42.0
	for l in lines:
		var txt = l.t if l is Dictionary else str(l)
		var col = l.get("c", PARCH) if l is Dictionary else PARCH
		T(r.position + Vector2(pad, y_off), txt, line_sz, col)
		y_off += 18.0
	if portrait != null:
		var center := r.position + Vector2(box_w - 48.0, box_h * 0.5 + 12.0)
		draw_circle(center, 32, Color(title_col, 0.22))
		draw_fantasy_unit(center, portrait, 0, "idle", Time.get_ticks_msec() / 1000.0)
		draw_unit_stars(center - Vector2(0, 30), portrait.s, 4.5)

func _draw():
	draw_forest_surroundings()
	draw_paper_panel(Rect2(12, 32, 230, 251), Color("EFE0C6"), Color(PAPER_EDGE, 0.50))
	var mp := mouse_pos

	# Grid cells
	for y in ROWS:
		for x in COLS:
			var r = Rect2(BO + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_forest_tile(r, x, y)

	# Bench
	for i in 8:
		var bounds = bench_rect(i)
		var hover := hover_strength(bounds)
		var r := animated_rect(bounds, 2.0)
		var selected = merge_locs.has(["b", i]) or (sel != null and sel[0] == "b" and sel[1] == i)
		draw_paper_panel(r, KRAFT.lerp(PAPER_HIGHLIGHT, hover * 0.62), PURPLE if selected else PAPER_EDGE)
		if selected:
			draw_rect(r.grow(-2), PURPLE, false, 2)
		if bench[i] != null:
			var idle_t = Time.get_ticks_msec() / 1000.0 * 2.5 + i
			token(r.position + Vector2(28, 28), bench[i], 0, "idle", idle_t, 0.0, 1.0)
	T(Vector2(384, 440), "BENCH", 13, PAPER_HIGHLIGHT)

	# Combat or Board units
	if phase == "combat":
		for u in units:
			if u.hp <= 0: continue
			var c = BO + u.pos * CELL + Vector2(32, 32)
			token(c, u.d, u.team, u.anim_state, u.anim_timer, u.attack_anim, u.facing)
			# Health & Mana bars above token
			draw_rect(Rect2(c + Vector2(-24, -48), Vector2(48, 5)), INK)
			draw_rect(Rect2(c + Vector2(-23, -47), Vector2(46 * clampf(u.hp / u.mx, 0, 1), 3)), RED if u.team == 1 else GOLD)
			if u.shield > 0.0:
				var sh_pct = clampf(u.shield / u.mx, 0, 1)
				draw_rect(Rect2(c + Vector2(-23, -47), Vector2(46 * sh_pct, 3)), Color("e0e0ff"))
			draw_rect(Rect2(c + Vector2(-23, -43), Vector2(46 * clampf(u.mana / 100.0, 0, 1), 2)), PURPLE)

		# Flying combat projectiles
		for p in projectiles:
			var curr_pos = p.from.lerp(p.to, clampf(p.t / p.dur, 0.0, 1.0))
			var screen_p = BO + curr_pos * CELL + Vector2(32, 32)
			var dir = (p.to - p.from).normalized()
			match p.type:
				"arrow":
					var tail = screen_p - dir * 14.0
					draw_line(tail, screen_p, Color("6b4226"), 2.0)
					draw_line(screen_p, screen_p - dir * 4.0 + Vector2(-dir.y, dir.x) * 3.0, Color("e0d8c8"), 2.0)
					draw_line(screen_p, screen_p - dir * 4.0 - Vector2(-dir.y, dir.x) * 3.0, Color("e0d8c8"), 2.0)
				"arcane", "star":
					draw_circle(screen_p, 5.0, p.col)
					draw_arc(screen_p, 8.0, 0, TAU, 12, p.col.lightened(0.4), 1.5)
					draw_line(screen_p - dir * 10.0, screen_p, p.col, 3.0)
				"dark":
					draw_circle(screen_p, 6.0, Color("140520"))
					draw_arc(screen_p, 6.0, 0, TAU, 12, p.col, 2.0)
				"holy":
					draw_line(screen_p - dir * 16.0, screen_p, Color("fff8c8"), 3.5)
					draw_circle(screen_p, 4.0, Color("ffd700"))
	else:
		if phase == "prep":
			T(BO + Vector2(0, -16), "ENEMY FORMATION", 13, Color("8E3627"))
			for enemy in enemy_formation:
				var footprint := unit_footprint(enemy.pos, enemy.d).grow(-2)
				draw_rect(footprint, Color(RED, 0.14))
				draw_rect(footprint, Color(RED, 0.45), false, 1.0)
				var idle = Time.get_ticks_msec() / 1000.0 * 2.5 + enemy.pos.x
				token(footprint.get_center(), enemy.d, 1, "idle", idle, 0.0, -1.0)
		for k in board:
			var idle_t = Time.get_ticks_msec() / 1000.0 * 2.5 + k.x * 2.0 + k.y
			var footprint := unit_footprint(Vector2(k), board[k]).grow(-2)
			if unit_width(board[k]) == 2:
				draw_rect(footprint, Color(PURPLE, 0.14))
				draw_rect(footprint, Color(PURPLE, 0.48), false, 1.0)
			if sel == ["g", k] or merge_locs.has(["g", k]):
				draw_rect(footprint, PURPLE, false, 3.0)
			token(footprint.get_center(), board[k], 0, "idle", idle_t, 0.0, 1.0)

	for t in texts:
		T(BO + t.p * CELL + Vector2(-20, 20 - (0.8 - t.t) * 40), t.s, 22, t.c, 80, HORIZONTAL_ALIGNMENT_CENTER)

	# Unit Shop Cards
	for i in 5:
		var bounds = card_rect(i)
		var hover := hover_strength(bounds)
		var r := animated_rect(bounds, 5.0)
		var c = shop[i]
		draw_paper_panel(r, Color("EFDFC1").lerp(PAPER_HIGHLIGHT, hover * 0.8), PAPER_EDGE, 4.0 + hover * 3.0)
		if c != null:
			draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(138, 27)), TIER_COL[c.t - 1].darkened(0.32))
			T(r.position + Vector2(8, 20), c.n, 15, PARCH)
			draw_unit_stars(r.position + Vector2(105, 14), c.t, 4.0)
			var role := "Ranged" if c.r else "Melee"
			T(r.position + Vector2(10, 55), "%s / 2 tiles" % role if unit_width(c) == 2 else role, 15)
			T(r.position + Vector2(10, 75), "HP %d  AD %d" % [u_hp(c), u_ad(c)], 15)
			T(r.position + Vector2(10, 105), "%d gold" % c.t, 18, Color("87520E") if gold >= c.t else RED)
		else:
			T(r.position + Vector2(0, 65), "sold", 16, INK, 140, HORIZONTAL_ALIGNMENT_CENTER)
		if tutorial_step != Tutorial.DONE and (tutorial_step != Tutorial.BUY or i != 0):
			draw_rect(r, Color(PARCH, 0.62))

	# Buttons
	for i in 5:
		button(btn_rect(i), BTNS[i] + (" [ON]" if i == 1 and locked else ""), PURPLE.lightened(0.4) if i == 4 else GOLD.lightened(0.3))
		if tutorial_step != Tutorial.DONE and not tutorial_target().intersects(btn_rect(i)):
			draw_rect(animated_rect(btn_rect(i), 3.0), Color(PARCH, 0.62))
	if phase == "prep" and (tutorial_step == Tutorial.DONE or tutorial_step == Tutorial.MERGE):
		button(MERGE_BUTTON, "Cancel merge" if selecting_merge else "Merge: Select the units", PURPLE.lightened(0.48))

	# HUD
	var practice := tutorial_step != Tutorial.DONE
	var hud = ["PRACTICE BATTLE" if practice else "STAGE %d / 10" % stage, "HP: %d" % hp, "Gold: %d  (interest +%d)" % [gold, mini(gold / 10, 5)],
		"Level: %d  (board %d/%d)" % [level, board.size(), level],
		"XP: %d / %s" % [xp, str(xp_need()) if level < 9 else "MAX"], "Streak: %d" % streak,
		"Round: " + ("training" if practice else ("PvE monsters" if stage in PVE_STAGES else "vs player"))]
	for i in hud.size(): T(Vector2(20, 60 + i * 28), hud[i], 20)
	var odds = ODDS[level]
	T(Vector2(20, 250), "Shop odds (T1-T5):", 15)
	T(Vector2(20, 270), "%d / %d / %d / %d / %d %%" % odds, 15)
	draw_paper_panel(Rect2(12, 288, 230, 22), Color("F4D795"), Color("9C6928"), 2.0)
	draw_circle(Vector2(25, 299), 5, Color("AB711C"), true, -1, true)
	var income_label := "Practice has no HP or gold penalty" if practice else "Round end: +%d gold minimum" % (round_income() + mini(gold / 10, 5))
	T(Vector2(37, 304), income_label, 12)
	if not practice:
		draw_guide()

	# Item Shop
	T(Vector2(20, 392), "ITEM SHOP", 14)
	for i in item_shop.size():
		var bounds = item_btn_rect(i)
		var hover := hover_strength(bounds)
		var r := animated_rect(bounds, 2.0)
		var it = item_shop[i]
		var col = RARITY_COLS.get(it.rarity, INK) if it != null else INK
		draw_paper_panel(r, Color("E9D6B6").lerp(PAPER_HIGHLIGHT, hover * 0.8), col, 2.0 + hover)
		if it != null:
			draw_rect(Rect2(r.position.x, r.position.y, 6, r.size.y), col)
			var stars = "*".repeat(it.t)
			var lbl = "%s %s (%dg)" % [it.n, stars, it.cost]
			T(r.position + Vector2(10, 15), lbl, 12, INK)
			T(r.position + Vector2(10, 27), get_it_desc(it.n, it.t), 10, col.darkened(0.2))
		else:
			T(r.position + Vector2(10, 20), "sold", 13, INK)
		if practice and (tutorial_step != Tutorial.BUY_ITEM or i != 0):
			draw_rect(r, Color(PARCH, 0.62))

	# Item Inventory
	T(Vector2(900, 364), "ITEMS (click one, then a unit)", 14)
	for i in 8:
		var bounds = item_slot_rect(i)
		var hover := hover_strength(bounds)
		var r := animated_rect(bounds, 2.0)
		draw_paper_panel(r, KRAFT.lerp(PAPER_HIGHLIGHT, hover * 0.62), PURPLE if i == sel_item else PAPER_EDGE)
		if i == sel_item:
			draw_rect(r.grow(-2), PURPLE, false, 2)
		if i < items_inv.size():
			var it = items_inv[i]
			var iname = get_it_name(it)
			var itier = get_it_tier(it)
			var rar = ITEM_DB[iname].rarity if ITEM_DB.has(iname) else "common"
			var col = RARITY_COLS.get(rar, INK)
			draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 3), col)
			T(r.position + Vector2(0, 24), iname.substr(0, 6), 11, INK, 52, HORIZONTAL_ALIGNMENT_CENTER)
			draw_unit_stars(r.position + Vector2(26, 42), itier, 3.5)

	# Loot orbs
	for o in orbs:
		var oc = BO + o * CELL + Vector2(32, 32)
		if loot_warning_time > 0.0:
			var progress := 1.0 - loot_warning_time / LOOT_WARNING_TIME
			draw_circle(oc, 18, Color(GOLD, 0.22 + progress * 0.36))
			draw_arc(oc, 19, -PI / 2.0, -PI / 2.0 + maxf(0.01, progress) * TAU, 24, GOLD, 3.0, true)
			T(oc + Vector2(-18, 6), "!", 18, Color("774314"), 36, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			draw_circle(oc, 14, GOLD)
			draw_arc(oc, 14, 0, TAU, 20, INK, 2)
			T(oc + Vector2(-14, 5), "+1", 12, INK, 28, HORIZONTAL_ALIGNMENT_CENTER)

	# Stat sheet
	if sel != null and loc_get(sel) != null:
		var d = loc_get(sel)
		var st = stats(d)
		draw_paper_panel(Rect2(1140, 60, 130, 320), Color("EFE0C6"), PAPER_EDGE)
		T(Vector2(1146, 80), d.n, 16)
		draw_unit_stars(Vector2(1230, 75), d.s, 4.5)
		T(Vector2(1146, 100), "HP %d" % st.hp, 13)
		T(Vector2(1146, 116), "AD %d" % st.ad, 13)
		T(Vector2(1146, 132), "Armor %d" % st.armor, 13)
		T(Vector2(1146, 148), "MR %d" % st.mr, 13)
		T(Vector2(1146, 164), "AP %d" % st.ap, 13)
		T(Vector2(1146, 180), "AS +%d%%" % int(st.as_bonus * 100), 13)
		T(Vector2(1146, 196), "Range %.1f" % st.rng, 13)
		T(Vector2(1146, 212), "Mana %d" % st.mana, 13)
		T(Vector2(1146, 228), "Leech %d%%" % int(st.leech * 100), 13)
		T(Vector2(1146, 246), "Items:", 13)
		var its = d.get("it", [])
		for i in its.size():
			var itn = get_it_name(its[i])
			var itt = get_it_tier(its[i])
			T(Vector2(1146, 264 + i * 16), itn.substr(0, 9) + " " + "*".repeat(itt), 12)
		T(Vector2(1146, 314), "Sell: %dg" % sell_value(d), 13)

	# QTE
	if qte != null:
		draw_spell_qte()

	if phase == "over":
		draw_rect(Rect2(0, 0, 1280, 720), Color(PARCH, 0.9))
		T(Vector2(0, 330), "YOU WIN!" if hp > 0 else "YOU LOSE", 64, INK, 1280, HORIZONTAL_ALIGNMENT_CENTER)
		T(Vector2(0, 380), "Click to restart", 24, PURPLE, 1280, HORIZONTAL_ALIGNMENT_CENTER)

	if practice and selecting_merge:
		draw_merge_prompt()
	if practice:
		draw_tutorial_guide()
		button(SKIP_TUTORIAL, "Skip Tutorial", Color("F4D795"))
	var target := tutorial_target()
	if target.has_area():
		var pulse := 0.70 + 0.30 * sin(Time.get_ticks_msec() / 135.0)
		draw_rect(target.grow(3.0), Color("905313"), false, 5.0)
		draw_rect(target.grow(3.0), Color(GOLD, pulse), false, 3.0)

	if qte != null:
		return

	# Tooltips & Hover cards (renders on top of everything)
	var tip = null
	if selecting_merge:
		if not practice:
			draw_merge_prompt()
		return

	if phase == "prep":
		for i in shop.size():
			if card_rect(i).has_point(mp) and shop[i] != null:
				var offer = shop[i]
				tip = get_unit_hover_info(offer, false, false)
				tip.col = TIER_COL[offer.t - 1].lightened(0.47)
				tip.lines.append({"t": "Cost: %d gold" % offer.t, "c": GOLD})
				tip.portrait = offer
				break

	if phase == "prep" and sel_item >= 0 and sel_item < items_inv.size():
		var s_it = items_inv[sel_item]
		var s_name = get_it_name(s_it)
		var s_tier = get_it_tier(s_it)

		# Check bench unit hover for equip preview
		for i in 8:
			if bench_rect(i).has_point(mp) and bench[i] != null:
				tip = get_equip_preview(bench[i], s_name, s_tier)
				break

		# Check board unit hover for equip preview
		if tip == null:
			var c = (mp - BO) / CELL
			var cx = int(floor(c.x))
			var cy = int(floor(c.y))
			if c.x >= 0 and c.y >= 0 and cx < COLS and cy >= 3 and cy < ROWS:
				var cell_k := board_anchor(Vector2i(cx, cy))
				if board.has(cell_k):
					tip = get_equip_preview(board[cell_k], s_name, s_tier)

	# Item shop button hover
	if tip == null and phase == "prep":
		for i in item_shop.size():
			if item_btn_rect(i).has_point(mp) and item_shop[i] != null:
				var it = item_shop[i]
				var rar = it.rarity
				var r_col = RARITY_COLS.get(rar, GOLD)
				var lines = [
					{"t": "Cost: %d Gold" % it.cost, "c": GOLD},
					{"t": "Tier %d: %s" % [it.t, get_it_desc(it.n, it.t)], "c": Color("5cdb7a")}
				]
				if it.t < 3:
					lines.append({"t": "Duplicate upgrades:", "c": Color("8a7a5c")})
					for t in range(it.t + 1, 4):
						lines.append({"t": "  Tier %d: %s" % [t, get_it_desc(it.n, t)], "c": Color("b8a994")})
				lines.append({"t": "Click to purchase into item bench", "c": Color("8a7a5c")})
				tip = {"title": "%s %s (%s)" % [it.n, "*".repeat(it.t), rar.to_upper()], "col": r_col, "lines": lines}
				break

	# Item inventory slot hover
	if tip == null and phase == "prep":
		for i in items_inv.size():
			if item_slot_rect(i).has_point(mp):
				var it = items_inv[i]
				var iname = get_it_name(it)
				var itier = get_it_tier(it)
				var rar = ITEM_DB[iname].rarity if ITEM_DB.has(iname) else "common"
				var r_col = RARITY_COLS.get(rar, GOLD)
				var lines = [
					{"t": "Tier %d: %s" % [itier, get_it_desc(iname, itier)], "c": Color("5cdb7a")}
				]
				if itier < 3:
					lines.append({"t": "Next Tier (%s): %s" % ["*".repeat(itier + 1), get_it_desc(iname, itier + 1)], "c": Color("b8a994")})
				lines.append({"t": "Click to select, then hover/click a unit", "c": Color("8a7a5c")})
				tip = {"title": "%s %s (%s)" % [iname, "*".repeat(itier), rar.to_upper()], "col": r_col, "lines": lines}
				break

	if tip == null and phase == "prep":
		for enemy in enemy_formation:
			var enemy_tile := unit_footprint(enemy.pos, enemy.d)
			if enemy_tile.has_point(mp):
				tip = get_unit_hover_info(enemy.d, false, false)
				break

	# Unit detail hover card (when no item is actively selected)
	if tip == null and sel_item < 0:
		if phase == "combat":
			for u in units:
				if u.hp <= 0: continue
				var c = BO + u.pos * CELL + Vector2(32, 32)
				if (c - mp).length() < 24.0:
					tip = get_unit_hover_info(u, true)
					break
		else:
			for i in 8:
				if bench_rect(i).has_point(mp) and bench[i] != null:
					tip = get_unit_hover_info(bench[i], false)
					break
			if tip == null:
				var c = (mp - BO) / CELL
				var cx = int(floor(c.x))
				var cy = int(floor(c.y))
				if c.x >= 0 and c.y >= 0 and cx < COLS and cy >= 3 and cy < ROWS:
					var cell_k := board_anchor(Vector2i(cx, cy))
					if board.has(cell_k):
						tip = get_unit_hover_info(board[cell_k], false)

	# Stat sheet equipped items hover
	if tip == null and sel != null and loc_get(sel) != null:
		var d = loc_get(sel)
		var its = d.get("it", [])
		for i in its.size():
			var ir = Rect2(1146, 264 + i * 16, 120, 16)
			if ir.has_point(mp):
				var iname = get_it_name(its[i])
				var itier = get_it_tier(its[i])
				var rar = ITEM_DB[iname].rarity if ITEM_DB.has(iname) else "common"
				var r_col = RARITY_COLS.get(rar, GOLD)
				var lines = [
					{"t": "Equipped: %s" % get_it_desc(iname, itier), "c": Color("5cdb7a")}
				]
				if itier < 3:
					lines.append({"t": "Next Tier (%s): %s" % ["*".repeat(itier + 1), get_it_desc(iname, itier + 1)], "c": Color("b8a994")})
				tip = {"title": "%s %s (%s)" % [iname, "*".repeat(itier), rar.to_upper()], "col": r_col, "lines": lines}
				break

	if tip != null:
		draw_tooltip_box(mp, tip.title, tip.col, tip.lines, tip.get("portrait"))
	if qte == null and not practice:
		draw_notification()
