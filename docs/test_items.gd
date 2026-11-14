extends SceneTree

func _init():
	print("--- Running Item & Scaling Tests ---")
	var Main = load("res://main.gd")
	var node = Main.new()
	node._ready()

	# Test 1: Verify all 23 items are in ITEM_DB with 3 tiers
	assert(node.ITEM_DB.size() == 23, "Expected 23 items in ITEM_DB, got %d" % node.ITEM_DB.size())
	print("PASS: 23 items defined in ITEM_DB")

	for k in node.ITEM_DB.keys():
		var it = node.ITEM_DB[k]
		assert(it.has("rarity") and it.has("cost") and it.has("tiers"), "Item missing core fields: " + k)
		assert(it.tiers.size() == 3, "Item tiers != 3 for " + k)
	print("PASS: All items have rarity, cost, and 3 tiers")

	# Test 2: Verify stats scaling on 1-star, 2-star with Sword
	var u1 = {"n": "Squire", "t": 1, "r": false, "s": 1, "it": [{"n": "Sword", "t": 1}]}
	var st1 = node.stats(u1)
	assert(is_equal_approx(st1.ad, 45.0), "Expected 45.0 AD, got %f" % st1.ad)
	print("PASS: Tier 1 Sword stat scaling correct")

	var u2 = {"n": "Squire", "t": 1, "r": false, "s": 1, "it": [{"n": "Sword", "t": 2}]}
	var st2 = node.stats(u2)
	assert(is_equal_approx(st2.ad, 59.0), "Expected 59.0 AD, got %f" % st2.ad)
	print("PASS: Tier 2 Sword stat scaling correct")

	var u3 = {"n": "Squire", "t": 1, "r": false, "s": 2, "it": [{"n": "Sword", "t": 3}]}
	var st3 = node.stats(u3)
	assert(is_equal_approx(st3.ad, 162.0), "Expected 162.0 AD on 2-star, got %f" % st3.ad)
	print("PASS: Tier 3 Sword on 2-star unit stat scaling correct")

	# Test 3: Verify Armor and Magic Resist mitigation (100 armor/mr = 50% reduction)
	var dummy_tgt = {"hp": 1000.0, "mx": 1000.0, "shield": 0.0, "armor": 100.0, "mr": 100.0, "mana": 0.0, "mana_taken": 0.0, "debuffs": [], "effects": {}, "barrier_used": false, "internal_cds": {}, "pos": Vector2.ZERO}
	var phys_dmg = node.apply_damage(dummy_tgt, null, 100.0, false)
	assert(is_equal_approx(phys_dmg, 50.0), "Expected 50.0 phys dmg with 100 armor, got %f" % phys_dmg)
	print("PASS: Physical armor mitigation formula correct (50% reduction at 100 armor)")

	var mag_dmg = node.apply_damage(dummy_tgt, null, 100.0, true)
	assert(is_equal_approx(mag_dmg, 50.0), "Expected 50.0 magic dmg with 100 MR, got %f" % mag_dmg)
	print("PASS: Magic resistance mitigation formula correct (50% reduction at 100 MR)")

	# Test 4: Barrier Gem shield trigger (<30% HP)
	dummy_tgt.hp = 250.0
	dummy_tgt.effects["Barrier Gem"] = {"barrier": 0.35}
	dummy_tgt.barrier_used = false
	var dmg2 = node.apply_damage(dummy_tgt, null, 10.0, false)
	assert(dummy_tgt.barrier_used == true, "Barrier Gem should have triggered")
	assert(dummy_tgt.shield > 0.0, "Shield should be granted")
	print("PASS: Barrier Gem shield triggers properly at < 30% HP")

	# Test 5: Duplicate merge-on-unit test
	node.bench[0] = {"n": "Squire", "t": 1, "r": false, "s": 1, "it": [{"n": "Sword", "t": 1}]}
	node.items_inv = [{"n": "Sword", "t": 1}]
	node.sel_item = 0
	node.click_loc(["b", 0])
	assert(node.bench[0].it.size() == 1, "Unit should still have 1 item slot used")
	assert(node.bench[0].it[0].t == 2, "Sword should be upgraded to Tier 2")
	assert(node.items_inv.size() == 0, "Inventory item should be consumed")
	print("PASS: Duplicate item merges and upgrades to Tier 2 on same slot")

	# Equip a 2nd duplicate to reach Tier 3
	node.items_inv = [{"n": "Sword", "t": 1}]
	node.sel_item = 0
	node.click_loc(["b", 0])
	assert(node.bench[0].it[0].t == 3, "Sword should be upgraded to Tier 3")
	print("PASS: Duplicate item merges and upgrades to Tier 3 on same slot")

	# Attempt to equip 3rd duplicate when at Tier 3
	node.items_inv = [{"n": "Sword", "t": 1}]
	node.sel_item = 0
	node.click_loc(["b", 0])
	assert(node.bench[0].it[0].t == 3, "Sword should remain Tier 3")
	assert(node.items_inv.size() == 1, "Duplicate should not be consumed when at max tier")
	print("PASS: Cannot upgrade beyond Tier 3 (stays in inventory)")

	# Test 6: 3-item cap validation
	node.bench[0].it = [{"n": "Sword", "t": 1}, {"n": "Vest", "t": 1}, {"n": "Amp", "t": 1}]
	node.items_inv = [{"n": "Chainmail", "t": 1}]
	node.sel_item = 0
	node.click_loc(["b", 0])
	assert(node.bench[0].it.size() == 3, "Unit should remain capped at 3 items")
	assert(node.items_inv.size() == 1, "4th distinct item rejected and kept in inventory")
	print("PASS: 3-item cap enforced when equipping 4th distinct item")

	node.free()
	print("--- All Item & Scaling Tests Passed Successfully! ---")
	quit(0)
