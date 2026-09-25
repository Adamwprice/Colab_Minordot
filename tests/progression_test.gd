extends SceneTree

var failures := 0

func check(ok: bool, description: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var manager = load("res://scripts/resource_manager.gd").new()
	var scene = Node2D.new()
	for node_name in ["Drones", "Asteroids"]:
		var node = Node2D.new()
		node.name = node_name
		scene.add_child(node)
	scene.add_child(manager)
	root.add_child(scene)
	var state = root.get_node("GameState")
	check(manager.get_hold_click_rate() == 5.0 and manager.get_click_rate_cap() == 10.0, "Starting input rates")
	state.dev_ship_overrides["starburst"] = true
	state.cap_levels["starburst_general_cap"] = 10
	manager.ship_upgrade_levels["starburst"]["combat_engines"] = 13
	check(manager.get_ship_upgrade_warning("starburst", "combat_engines").contains("reaches the hard cap"), "Cap warning before reaching limit")
	manager.ship_upgrade_levels["starburst"]["combat_engines"] = 14
	manager.total_resources = 1000000000.0
	check(manager.upgrade_ship_stat("starburst", "combat_engines"), "Overflow purchase accepted")
	var effective = manager.get_effective_ship_levels("starburst")
	check(is_equal_approx(effective["salvo"], 0.5) and is_equal_approx(effective["targeting_attack"], 0.5), "Overflow shared evenly")
	check(manager.get_starburst_attack_interval() == 3.0, "Hard interval floor preserved")
	check(manager.get_ship_upgrade_warning("starburst", "combat_engines").contains("Overflow:"), "Overflow warning identifies recipients")
	var snapshot = manager.get_run_state()
	manager.ship_upgrade_levels["starburst"]["combat_engines"] = 0
	manager.apply_run_state(snapshot, 0)
	check(is_equal_approx(manager.get_effective_ship_levels("starburst")["salvo"], 0.5), "Fractional overflow survives state restoration")
	manager.ship_upgrade_levels["starburst"]["salvo"] = 30
	manager.ship_upgrade_levels["starburst"]["targeting_attack"] = 30
	check(not manager.upgrade_ship_stat("starburst", "combat_engines"), "Purchase blocked when all recipients capped")
	manager.ship_upgrade_levels["starburst"] = {"combat_engines": 14, "salvo": 28, "targeting_attack": 28}
	var receiver_floor = 0.5 * (1130.0 + 900.0) * pow(1.4, 28.0)
	check(manager.get_ship_upgrade_cost("starburst", "combat_engines") >= receiver_floor, "Overflow price reflects expensive recipients")
	var resolver = load("res://scripts/ship_upgrade_overflow.gd")
	var split = resolver.resolve("starburst", {"combat_engines": 15, "a": 0, "b": 0, "c": 0, "d": 0}, {"combat_engines": 30, "a": 30, "b": 30, "c": 30, "d": 30})
	check(is_equal_approx(split["a"], 0.25) and is_equal_approx(split["d"], 0.25), "Five-upgrade example gives quarter levels")
	state.dev_ship_overrides["stapledon"] = true
	state.cap_levels["stapledon_general_cap"] = 10
	manager.ship_upgrade_levels["stapledon"]["flare_catcher"] = 19
	check(manager.get_effective_ship_upgrade_level("stapledon", "dyson_capacity") == 0, "Fractional craft count waits for a whole unit")
	manager.ship_upgrade_levels["stapledon"]["flare_catcher"] = 20
	check(manager.get_effective_ship_upgrade_level("stapledon", "dyson_capacity") == 1, "Fractional craft credits accumulate")
	state.passive_levels["flagship_picket_array"] = 1
	state.research_card_unlocks["flagship_picket_array"] = 1
	state.cap_levels["flagship_general_cap"] = 3
	check(state.reset_for_prestige(), "Prestige succeeds")
	check(state.get_passive_level("flagship_picket_array") == 1 and not state.can_battle_research_card("flagship_picket_array"), "One-time research stays active and completed")
	check(state.cap_levels["flagship_general_cap"] == 0 and state.can_battle_research_card("flagship_general_cap"), "Upgrade Cap resets for prestige")
	scene.free()
	change_scene_to_file("res://scenes/Main.tscn")
	await scene_changed
	var ui = current_scene.get_node("UI")
	check(not ui.has_node("BattleButton"), "Obsolete battle button removed")
	var shortcuts_ok = true
	for index in range(5):
		var key = InputEventKey.new()
		key.keycode = KEY_1 + index
		key.pressed = true
		ui._unhandled_key_input(key)
		shortcuts_ok = shortcuts_ok and ui.selected_ore_upgrade_tab == ui.UPGRADE_TAB_ORDER[index]
	check(shortcuts_ok, "Keys 1-5 select all upgrade categories")
	quit(1 if failures else 0)
