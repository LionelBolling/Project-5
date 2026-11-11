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
const ITEMS := {"Sword":{"ad":10,"d":"+10 AD"},"Vest":{"hp":150,"d":"+150 HP"},"Amp":{"pad":0.2,"d":"+20% AD"},
	"Orb":{"mana":40,"d":"+40 start mana"},"Leech":{"leech":0.25,"d":"25% lifesteal"}}
const ITEM_NAMES := ["Sword","Vest","Amp","Orb","Leech"]
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

func _ready():
	randomize()
	for i in 8: bench.append(null)
	roll_shop()

# ---------- helpers ----------
# Scaling pipeline: flat item stats added to base first, then star multiplier, then % multipliers.
func stats(d):
	var fh = 0.0
	var fa = 0.0
	var pa = 0.0
	var m0 = 0.0
	var lc = 0.0
	for n in d.get("it", []):
		var it = ITEMS[n]
		fh += it.get("hp", 0)
		fa += it.get("ad", 0)
		pa += it.get("pad", 0)
		m0 += it.get("mana", 0)
		lc += it.get("leech", 0)
	var bh = (300.0 + 130.0 * d.t) * (0.7 if d.r else 1.0)
	var ba = 25.0 + 10.0 * d.t
	var sm = pow(1.8, d.s - 1)
	return {"hp": (bh + fh) * sm, "ad": (ba + fa) * sm * (1.0 + pa), "mana": m0, "leech": lc}
func u_hp(d): return stats(d).hp
func u_ad(d): return stats(d).ad
func item_btn_rect(i): return Rect2(20, 400 + i * 34, 210, 30)
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

func roll_shop():
	shop = []
	for i in 5:
		var t = pick_tier()
		var pool = DEFS.filter(func(x): return x[1] == t)
		var p = pool.pick_random()
		shop.append({"n": p[0], "t": p[1], "r": p[2], "s": 1, "it": []})

func start_prep():
	if not locked: roll_shop()
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
					for itn in loc_get(ls[j]).get("it", []): items_inv.append(itn)
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
	for i in ITEM_NAMES.size():
		if item_btn_rect(i).has_point(p):
			if gold >= 3 and items_inv.size() < 8:
				gold -= 3
				items_inv.append(ITEM_NAMES[i])
			else: msg = "Need 3 gold and a free item slot."
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

func click_loc(l):
	if sel_item >= 0:
		var tu = loc_get(l)
		if tu == null: return
		if not tu.has("it"): tu["it"] = []
		if tu.it.size() >= 3:
			msg = "Unit has 3 items already."
			return
		tu.it.append(items_inv[sel_item])
		items_inv.remove_at(sel_item)
		sel_item = -1
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
	units.append({"d": d, "team": team, "pos": pos, "hp": st.hp * mult, "mx": st.hp * mult,
		"ad": st.ad * mult, "mana": st.mana, "leech": st.leech, "cd": 0.5, "rng": 3.0 if d.r else 1.0, "cast": false})

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
		make_unit({"n": p[0], "t": p[1], "r": p[2], "s": s}, 1, cells[i], 0.75 + 0.07 * stage)
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

func sim(dt):
	ctime += dt
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
		if u.hp <= 0 or u.cast: continue
		var tgt = nearest(u)
		if tgt == null: continue
		if u.mana >= 100.0:
			do_cast(u, tgt)
			continue
		if u.pos.distance_to(tgt.pos) <= u.rng + 0.45:
			u.cd -= dt
			if u.cd <= 0:
				u.cd = 1.25
				tgt.hp -= u.ad
				u.hp = minf(u.mx, u.hp + u.ad * u.leech)
				tgt.mana += 6.0
				u.mana += 10.0
				pop(tgt.pos, str(int(u.ad)), INK)
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
	var dmg = u.ad * 2.5 * (1.0 + bonus)
	tgt.hp -= dmg
	u.hp = minf(u.mx, u.hp + dmg * u.leech)
	for e in units:
		if e.team != u.team and e.hp > 0 and e != tgt and e.pos.distance_to(tgt.pos) < 1.6:
			e.hp -= dmg * 0.4
	pop(tgt.pos, "POW!" if bonus > 0 else "SHING!", RED if bonus > 0 else GOLD)

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
			var drop = ITEM_NAMES.pick_random()
			items_inv.append(drop)
			msg += " Monster dropped a " + drop + "! Click orbs for gold."
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
	T(Vector2(20, 392), "ITEM SHOP (3g each)", 14)
	for i in ITEM_NAMES.size():
		var r = item_btn_rect(i)
		draw_rect(r, KRAFT)
		draw_rect(r, INK, false, 2)
		T(r.position + Vector2(8, 20), ITEM_NAMES[i] + ": " + ITEMS[ITEM_NAMES[i]].d, 14)
	T(Vector2(900, 364), "ITEMS (click one, then a unit)", 14)
	for i in 8:
		var r = item_slot_rect(i)
		draw_rect(r, KRAFT)
		draw_rect(r, PURPLE if i == sel_item else INK, false, 4 if i == sel_item else 2)
		if i < items_inv.size(): T(r.position + Vector2(0, 30), items_inv[i], 13, INK, 52, HORIZONTAL_ALIGNMENT_CENTER)
	# loot orbs
	for o in orbs:
		var oc = BO + o * CELL + Vector2(32, 32)
		draw_circle(oc, 14, GOLD)
		draw_arc(oc, 14, 0, TAU, 20, INK, 2)
	# stat sheet
	if sel != null and loc_get(sel) != null:
		var d = loc_get(sel)
		var st = stats(d)
		draw_rect(Rect2(1140, 60, 130, 280), KRAFT)
		draw_rect(Rect2(1140, 60, 130, 280), INK, false, 2)
		T(Vector2(1148, 82), d.n + " " + "*".repeat(d.s), 16)
		T(Vector2(1148, 106), "HP %d" % st.hp, 14)
		T(Vector2(1148, 126), "AD %d" % st.ad, 14)
		T(Vector2(1148, 146), "Start mana %d" % st.mana, 14)
		T(Vector2(1148, 166), "Lifesteal %d%%" % (st.leech * 100), 14)
		T(Vector2(1148, 192), "Items:", 14)
		var its = d.get("it", [])
		for i in its.size(): T(Vector2(1148, 212 + i * 20), its[i], 14)
		T(Vector2(1148, 300), "Sell: %dg" % sell_value(d), 14)
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
