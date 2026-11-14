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
const TIER_COL := [Color("8a7a5c"), Color("E69A2B"), Color("893BFF"), Color("D9381E"), Color("1A1617")]
const DEFS := [["Squire",1,false],["Archer",1,true],["Knight",2,false],["Mage",2,true],
	["Rogue",3,false],["Cleric",3,true],["Golem",4,false],["Witch",4,true],["Dragon",5,false],["Sage",5,true]]
const ODDS := {3:[75,25,0,0,0],4:[55,30,15,0,0],5:[45,33,20,2,0],6:[30,40,25,5,0],
	7:[19,30,35,15,1],8:[16,20,35,25,4],9:[9,15,30,30,16]}
const XPN := {3:6,4:10,5:20,6:36,7:48,8:60}

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

var gold := 8
var level := 3
var xp := 0
var hp := 40
var stage := 1
var streak := 0
var phase := "prep"
var locked := false
var msg := "Buy units, place them on the bottom 3 rows, then start the battle."
var shop := []
var item_shop := []
var bench := []
var board := {}
var sel = null
var units := []
var texts := []
var ctime := 0.0
var qte = null
var items_inv := []
var sel_item := -1
var orbs := []
var cur_pve := false
var aura_timer := 0.0

func _ready():
	randomize()
	for i in 8: bench.append(null)
	roll_shop()
	roll_item_shop()

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

func start_prep():
	if not locked:
		roll_shop()
		roll_item_shop()
	locked = false

func loc_get(l):
	if l[0] == "b": return bench[l[1]]
	return board.get(l[1])

func loc_set(l, u):
	if l[0] == "b": bench[l[1]] = u
	elif u == null: board.erase(l[1])
	else: board[l[1]] = u

func all_locs():
	var a = []
	for i in 8: a.append(["b", i])
	for k in board.keys(): a.append(["g", k])
	return a

func merge():
	var changed = true
	while changed:
		changed = false
		var groups = {}
		for l in all_locs():
			var u = loc_get(l)
			if u == null or u.s >= 3: continue
			var key = u.n + str(u.s)
			if not groups.has(key): groups[key] = []
			groups[key].append(l)
		for key in groups:
			var ls = groups[key]
			if ls.size() >= 3:
				loc_get(ls[0]).s += 1
				for j in [1, 2]:
					for itn in loc_get(ls[j]).get("it", []):
						if items_inv.size() < 8:
							items_inv.append(itn)
						else:
							gold += 3
					loc_set(ls[j], null)
				sel = null
				msg = "Star up!"
				changed = true
				break

func sell_value(u): return u.t * int(pow(3, u.s - 1)) - (1 if u.s > 1 else 0)

# ---------- input ----------
func _input(e):
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		click(e.position)
	elif e is InputEventKey and e.pressed and not e.echo:
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
	if phase != "prep": return
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
		click_loc(["g", Vector2i(cx, cy)])
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
	if board.size() > level:
		loc_set(sel, a)
		loc_set(l, b)
		msg = "Board full: you can field %d units at level %d." % [level, level]
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
	merge()

func do_btn(i):
	if phase != "prep": return
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
		"hp": st.hp * mult, "mx": st.hp * mult, "shield": 0.0,
		"ad": st.ad * mult, "base_ad": st.ad * mult,
		"armor": st.armor, "mr": st.mr, "ap": st.ap,
		"as_bonus": st.as_bonus, "mana": st.mana, "leech": st.leech,
		"mana_hit": st.mana_hit, "mana_taken": st.mana_taken,
		"crit_chance": st.crit_chance, "spells_can_crit": st.spells_can_crit,
		"effects": st.effects, "cd": 0.5, "rng": st.rng, "cast": false,
		"debuffs": [], "internal_cds": {}, "barrier_used": false
	})

func start_battle():
	if board.is_empty():
		msg = "Place at least one unit on the board first."
		return
	sel = null
	sel_item = -1
	orbs = []
	cur_pve = stage in PVE_STAGES
	phase = "combat"
	units = []
	texts = []
	ctime = 0.0
	aura_timer = 0.0
	qte = null
	for k in board: make_unit(board[k], 0, Vector2(k.x, k.y), 1.0)
	var cells = []
	for y in 3:
		for x in COLS: cells.append(Vector2(x, y))
	cells.shuffle()
	var n = mini(int(1 + stage * 0.8) + 1, 9)
	var maxt = clampi(1 + stage / 2, 1, 5)
	for i in n:
		var p = DEFS.pick_random()
		while p[1] > maxt: p = DEFS.pick_random()
		var s = 1
		if stage >= 6 and randf() < 0.4: s = 2
		if stage >= 9 and randf() < 0.3: s = 3
		make_unit({"n": p[0], "t": p[1], "r": p[2], "s": s, "it": []}, 1, cells[i], 0.75 + 0.07 * stage)
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
	for t in texts: t.t -= dt
	texts = texts.filter(func(t): return t.t > 0)
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
		qte.t += dt
		if qte.t > 0.75: resolve_qte(0.0, "")

	for u in units:
		if u.hp <= 0: continue
		for k in u.internal_cds.keys():
			u.internal_cds[k] = maxf(0.0, u.internal_cds[k] - dt)
		for deb in u.debuffs:
			deb.t -= dt
		u.debuffs = u.debuffs.filter(func(d): return d.t > 0)

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
			u.cd -= dt
			if u.cd <= 0:
				u.cd = attack_cd
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
			u.pos += (tgt.pos - u.pos).normalized() * 1.6 * dt
			for o in units:
				if o != u and o.hp > 0 and o.pos.distance_to(u.pos) < 0.5:
					u.pos += (u.pos - o.pos).normalized() * 1.0 * dt

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
	if qte.t >= 0.275 and qte.t <= 0.475: resolve_qte(0.3, "PERFECT!")
	else: resolve_qte(0.15, "Good")

func resolve_qte(bonus, label):
	var u = qte.u
	u.cast = false
	qte = null
	if u.hp <= 0: return
	if label != "": pop(u.pos + Vector2(0, -0.6), label, PURPLE)
	apply_cast(u, nearest(u), bonus)

func end_combat(a0, a1):
	qte = null
	var win = a1 == 0 or (a0 > a1 and a0 > 0)
	if a0 == 0: win = false
	if win: streak = streak + 1 if streak > 0 else 1
	else: streak = streak - 1 if streak < 0 else -1
	var n = absi(streak)
	var sb = 0 if n < 2 else (1 if n < 4 else (2 if n == 4 else 3))
	var interest = mini(gold / 10, 5)
	var inc = 5 + interest + sb + (1 if win else 0)
	gold += inc
	add_xp(2)
	var res = "WIN" if win else "LOSS"
	if not win:
		var dmg = 2 + 2 * a1
		hp -= dmg
		res += " (-%d HP)" % dmg
	msg = "%s. +%d gold (5 base, %d interest, %d streak)." % [res, inc, interest, sb]
	if cur_pve and win:
		for e in units:
			if e.team == 1 and orbs.size() < 3: orbs.append(e.pos)
		if items_inv.size() < 8:
			var drop = ITEM_DB.keys().pick_random()
			var drop_tier = 2 if (stage >= 7 and randf() < 0.25) else 1
			items_inv.append({"n": drop, "t": drop_tier})
			msg += " Monster dropped a %s %s! Click orbs for gold." % [drop, "*".repeat(drop_tier)]
	stage += 1
	if hp <= 0: phase = "over"
	elif stage > 10: phase = "over"
	else:
		phase = "prep"
		start_prep()

# ---------- drawing ----------
func T(p, s, size = 16, col = INK, w = -1.0, al = HORIZONTAL_ALIGNMENT_LEFT):
	draw_string(ThemeDB.fallback_font, p, s, al, w, size, col)

func token(c, d, team = 0):
	draw_circle(c + Vector2(3, 4), 24, Color(0, 0, 0, 0.35))
	draw_circle(c, 24, TIER_COL[d.t - 1])
	draw_arc(c, 24, 0, TAU, 28, RED if team == 1 else INK, 3)
	T(c + Vector2(-24, 6), d.n.substr(0, 2), 18, PARCH, 48, HORIZONTAL_ALIGNMENT_CENTER)
	T(c + Vector2(-24, 20), "*".repeat(d.s), 16, PARCH, 48, HORIZONTAL_ALIGNMENT_CENTER)

func button(r, label, col):
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
	draw_rect(r, col)
	draw_rect(r, INK, false, 2)
	T(r.position + Vector2(0, 29), label, 17, INK, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func _draw():
	draw_rect(Rect2(0, 0, 1280, 720), PARCH)
	for y in ROWS:
		for x in COLS:
			var r = Rect2(BO + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r, KRAFT if y >= 3 else KRAFT.darkened(0.15))
			draw_rect(r, INK, false, 2)
	if sel != null and sel[0] == "g":
		draw_rect(Rect2(BO + Vector2(sel[1]) * CELL, Vector2(CELL, CELL)), PURPLE, false, 4)
	for i in 8:
		var r = bench_rect(i)
		draw_rect(r, KRAFT)
		draw_rect(r, PURPLE if (sel != null and sel[0] == "b" and sel[1] == i) else INK, false, 3 if (sel != null and sel[0] == "b" and sel[1] == i) else 2)
		if bench[i] != null: token(r.position + Vector2(28, 28), bench[i])
	T(Vector2(384, 440), "BENCH", 13)
	if phase == "combat":
		for u in units:
			if u.hp <= 0: continue
			var c = BO + u.pos * CELL + Vector2(32, 32)
			token(c, u.d, u.team)
			draw_rect(Rect2(c + Vector2(-24, -34), Vector2(48, 6)), INK)
			draw_rect(Rect2(c + Vector2(-23, -33), Vector2(46 * clampf(u.hp / u.mx, 0, 1), 4)), RED if u.team == 1 else GOLD)
			if u.shield > 0.0:
				var sh_pct = clampf(u.shield / u.mx, 0, 1)
				draw_rect(Rect2(c + Vector2(-23, -33), Vector2(46 * sh_pct, 4)), Color("e0e0ff"))
			draw_rect(Rect2(c + Vector2(-23, -28), Vector2(46 * clampf(u.mana / 100.0, 0, 1), 3)), PURPLE)
	else:
		for k in board: token(BO + Vector2(k) * CELL + Vector2(32, 32), board[k])
	for t in texts:
		T(BO + t.p * CELL + Vector2(-20, 20 - (0.8 - t.t) * 40), t.s, 22, t.c, 80, HORIZONTAL_ALIGNMENT_CENTER)
	# shop
	for i in 5:
		var r = card_rect(i)
		var c = shop[i]
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, KRAFT)
		draw_rect(r, INK, false, 2)
		if c != null:
			draw_rect(Rect2(r.position, Vector2(140, 28)), TIER_COL[c.t - 1])
			T(r.position + Vector2(0, 20), c.n + "  " + "*".repeat(c.t), 16, PARCH, 140, HORIZONTAL_ALIGNMENT_CENTER)
			T(r.position + Vector2(10, 55), "Ranged" if c.r else "Melee", 15)
			T(r.position + Vector2(10, 75), "HP %d  AD %d" % [u_hp(c), u_ad(c)], 15)
			T(r.position + Vector2(10, 105), "%d gold" % c.t, 18, GOLD if gold >= c.t else RED)
		else:
			T(r.position + Vector2(0, 65), "sold", 16, INK, 140, HORIZONTAL_ALIGNMENT_CENTER)
	# buttons
	for i in 5:
		button(btn_rect(i), BTNS[i] + (" [ON]" if i == 1 and locked else ""), PURPLE.lightened(0.4) if i == 4 else GOLD.lightened(0.3))
	# HUD
	var hud = ["STAGE %d / 10" % stage, "HP: %d" % hp, "Gold: %d  (interest +%d)" % [gold, mini(gold / 10, 5)],
		"Level: %d  (board %d/%d)" % [level, board.size(), level],
		"XP: %d / %s" % [xp, str(xp_need()) if level < 9 else "MAX"], "Streak: %d" % streak,
		"Round: " + ("PvE monsters" if stage in PVE_STAGES else "vs player")]
	for i in hud.size(): T(Vector2(20, 60 + i * 28), hud[i], 20)
	var odds = ODDS[level]
	T(Vector2(20, 250), "Shop odds (T1-T5):", 15)
	T(Vector2(20, 270), "%d / %d / %d / %d / %d %%" % odds, 15)
	T(Vector2(20, 330), "Click a unit, then click a\nslot to move/swap it.\nBottom 3 board rows only.", 14)
	T(Vector2(20, 700), msg, 18, INK)
	# items
	T(Vector2(20, 392), "ITEM SHOP", 14)
	for i in item_shop.size():
		var r = item_btn_rect(i)
		var it = item_shop[i]
		draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))
		draw_rect(r, KRAFT)
		var col = RARITY_COLS.get(it.rarity, INK) if it != null else INK
		draw_rect(r, col, false, 2)
		if it != null:
			draw_rect(Rect2(r.position.x, r.position.y, 6, r.size.y), col)
			var stars = "*".repeat(it.t)
			var lbl = "%s %s (%dg)" % [it.n, stars, it.cost]
			T(r.position + Vector2(10, 15), lbl, 12, INK)
			T(r.position + Vector2(10, 27), get_it_desc(it.n, it.t), 10, col.darkened(0.2))
		else:
			T(r.position + Vector2(10, 20), "sold", 13, INK)
	T(Vector2(900, 364), "ITEMS (click one, then a unit)", 14)
	for i in 8:
		var r = item_slot_rect(i)
		draw_rect(r, KRAFT)
		draw_rect(r, PURPLE if i == sel_item else INK, false, 4 if i == sel_item else 2)
		if i < items_inv.size():
			var it = items_inv[i]
			var iname = get_it_name(it)
			var itier = get_it_tier(it)
			var rar = ITEM_DB[iname].rarity if ITEM_DB.has(iname) else "common"
			var col = RARITY_COLS.get(rar, INK)
			draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 3), col)
			T(r.position + Vector2(0, 24), iname.substr(0, 6), 11, INK, 52, HORIZONTAL_ALIGNMENT_CENTER)
			T(r.position + Vector2(0, 42), "*".repeat(itier), 13, col, 52, HORIZONTAL_ALIGNMENT_CENTER)
	# loot orbs
	for o in orbs:
		var oc = BO + o * CELL + Vector2(32, 32)
		draw_circle(oc, 14, GOLD)
		draw_arc(oc, 14, 0, TAU, 20, INK, 2)
	# stat sheet
	if sel != null and loc_get(sel) != null:
		var d = loc_get(sel)
		var st = stats(d)
		draw_rect(Rect2(1140, 60, 130, 320), KRAFT)
		draw_rect(Rect2(1140, 60, 130, 320), INK, false, 2)
		T(Vector2(1146, 80), d.n + " " + "*".repeat(d.s), 16)
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
		var bx = BO.x
		draw_rect(Rect2(bx, 190, 448, 60), INK)
		draw_rect(Rect2(bx + 448 * 0.275 / 0.75, 190, 448 * 0.2 / 0.75, 60), GOLD)
		draw_rect(Rect2(bx + 448 * qte.t / 0.75 - 3, 186, 6, 68), RED)
		T(Vector2(bx, 182), "SPACE!  (hit the gold zone)", 22, RED, 448, HORIZONTAL_ALIGNMENT_CENTER)
	if phase == "over":
		draw_rect(Rect2(0, 0, 1280, 720), Color(PARCH, 0.9))
		T(Vector2(0, 330), "YOU WIN!" if hp > 0 else "YOU LOSE", 64, INK, 1280, HORIZONTAL_ALIGNMENT_CENTER)
		T(Vector2(0, 380), "Click to restart", 24, PURPLE, 1280, HORIZONTAL_ALIGNMENT_CENTER)
