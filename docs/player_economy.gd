extends RefCounted
class_name PlayerEconomy

# --- MONEY STATE ---
const STARTING_GOLD := 12
const BASE_ROUND_INCOME := 5
const INTEREST_DIVISOR := 10
const MAX_INTEREST := 5
const WIN_GOLD_BONUS := 1
const REROLL_COST := 2
const LOOT_ORB_GOLD := 1

var gold: int = STARTING_GOLD
var streak: int = 0 # Positive = win streak, Negative = loss streak

# --- LEVELS / XP STATE ---
const STARTING_LEVEL := 3
const MAX_LEVEL := 9
const XP_COST_GOLD := 4
const XP_PER_PURCHASE := 4
const PASSIVE_XP_PER_ROUND := 2

const XP_TABLE := {
	1: 2, 2: 6, 3: 4, 4: 8, 5: 12, 6: 18, 7: 24, 8: 32
}

const SHOP_ODDS := {
	1: [100, 0, 0, 0, 0],
	2: [100, 0, 0, 0, 0],
	3: [75, 25, 0, 0, 0],
	4: [55, 30, 15, 0, 0],
	5: [45, 33, 20, 2, 0],
	6: [30, 40, 25, 5, 0],
	7: [19, 30, 35, 15, 1],
	8: [16, 20, 35, 25, 4],
	9: [9, 15, 30, 30, 16]
}

var level: int = STARTING_LEVEL
var xp: int = 0

func reset() -> void:
	gold = STARTING_GOLD
	streak = 0
	level = STARTING_LEVEL
	xp = 0

# --- MONEY METHODS ---
func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

func get_interest() -> int:
	return mini(int(floor(float(gold) / float(INTEREST_DIVISOR))), MAX_INTEREST)

func get_streak_bonus() -> int:
	var n := absi(streak)
	if n < 2: return 0
	if n < 4: return 1
	if n == 4: return 2
	return 3

func get_sell_value(unit: Dictionary) -> int:
	return int(unit.t) * int(pow(3, int(unit.s) - 1)) - (1 if int(unit.s) > 1 else 0)

func sell_unit(unit: Dictionary) -> int:
	var value := get_sell_value(unit)
	add_gold(value)
	return value

func collect_loot_orb() -> int:
	add_gold(LOOT_ORB_GOLD)
	return LOOT_ORB_GOLD

# --- LEVELS / XP METHODS ---
func get_xp_needed() -> int:
	return XP_TABLE.get(level, 9999)

func get_max_board_units() -> int:
	return level

func get_shop_odds() -> Array:
	return SHOP_ODDS.get(level, [75, 25, 0, 0, 0])

func buy_xp() -> Dictionary:
	if level >= MAX_LEVEL:
		return {"ok": false, "msg": "Already max level."}
	if not spend_gold(XP_COST_GOLD):
		return {"ok": false, "msg": "Need %d gold." % XP_COST_GOLD}
	var leveled := add_xp(XP_PER_PURCHASE)
	return {"ok": true, "leveled": leveled}

func add_xp(amount: int) -> bool:
	var leveled := false
	xp += amount
	while level < MAX_LEVEL and xp >= get_xp_needed():
		xp -= get_xp_needed()
		level += 1
		leveled = true
	return leveled

# --- END OF ROUND SETTLEMENT ---
func settle_round(win: bool, base_income: int = BASE_ROUND_INCOME) -> Dictionary:
	streak = (streak + 1 if streak > 0 else 1) if win else (streak - 1 if streak < 0 else -1)
	var interest := get_interest()
	var streak_bonus := get_streak_bonus()
	var win_bonus := WIN_GOLD_BONUS if win else 0
	var total_gold := base_income + interest + streak_bonus + win_bonus

	add_gold(total_gold)
	var leveled := add_xp(PASSIVE_XP_PER_ROUND)

	return {
		"total_gold": total_gold,
		"base": base_income,
		"interest": interest,
		"streak_bonus": streak_bonus,
		"win_bonus": win_bonus,
		"leveled": leveled
	}
