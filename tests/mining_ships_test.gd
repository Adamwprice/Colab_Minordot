extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = Node2D.new()
	for container_name in ["Asteroids", "Drones"]:
		var container = Node2D.new()
		container.name = container_name
		scene.add_child(container)
	var manager = load("res://scripts/resource_manager.gd").new()
	scene.add_child(manager)
	root.add_child(scene)
	current_scene = scene
	var flagship = load("res://scenes/Flotilla.tscn").instantiate()
	scene.add_child(flagship)
	manager.flotilla = flagship
	var state = root.get_node("GameState")
	var failures := 0
	for ship_key in ["minotard", "tobias", "fruegal"]:
		for key in manager.Catalog.get_ship_ids():
			state.dev_ship_overrides[key] = key == ship_key
		for node in scene.get_node("Asteroids").get_children():
			node.free()
		manager.ship_operation_positions.clear()
		manager.ship_operation_targets.clear()
		manager.ship_income_timers.clear()
		manager.total_resources = 0.0
		var target = load("res://scenes/Asteroid.tscn").instantiate()
		scene.get_node("Asteroids").add_child(target)
		target.add_to_group("asteroids")
		target.position = manager._get_ship_formation_position(ship_key) + Vector2(1000, 0)
		target.resource_amount = 1000
		if ship_key == "tobias":
			target.set_meta("resource_type", "gas_cloud")
		var credited_immediately = false
		for step in range(900):
			manager._process_ship_operations(0.1)
			manager._process_catalog_ship_income(0.1)
			if target.resource_amount < 1000:
				credited_immediately = manager.total_resources == float(1000 - target.resource_amount)
				break
		# Continue beyond the former 500-ore hold limit without returning home.
		for step in range(1200):
			manager._process_ship_operations(0.1)
			manager._process_catalog_ship_income(0.1)
			if target.resource_amount == 0:
				break
		var passed = credited_immediately and manager.total_resources > 500.0 and manager.total_resources == float(1000 - target.resource_amount)
		passed = passed and manager.get_ship_world_position(ship_key).distance_to(target.position) <= manager._get_ship_work_range(ship_key)
		print("%s: extracted=%s delivered=%s %s" % [ship_key, 1000 - target.resource_amount, manager.total_resources, "PASS" if passed else "FAIL"])
		if not passed:
			failures += 1
		var hold_rate = manager.get_hold_click_rate()
		var click_rate = manager.get_click_rate_cap()
		manager.ship_upgrade_levels[ship_key]["input_rate"] = 2
		var rate_passed = manager.get_hold_click_rate() == hold_rate + 2 and manager.get_click_rate_cap() == click_rate + 2
		state.dev_ship_overrides[ship_key] = false
		rate_passed = rate_passed and manager.get_hold_click_rate() == hold_rate and manager.get_click_rate_cap() == click_rate
		print("%s player input rate: %s" % [ship_key, "PASS" if rate_passed else "FAIL"])
		if not rate_passed:
			failures += 1
		manager.ship_upgrade_levels[ship_key]["input_rate"] = 0
	manager.apply_run_state({"ship_upgrades": {"minotard": {"cargo_capacity": 4}}}, 0)
	var migrated = manager.ship_upgrade_levels["minotard"]["input_rate"] == 4
	manager.apply_run_state({"ship_upgrades": {"minotard": {"cargo_capacity": 4, "input_rate": 2}}}, 0)
	migrated = migrated and manager.ship_upgrade_levels["minotard"]["input_rate"] == 2
	print("Cargo upgrade migration: %s" % ("PASS" if migrated else "FAIL"))
	if not migrated:
		failures += 1
	scene.free()
	quit(1 if failures else 0)
