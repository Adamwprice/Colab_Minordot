extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = Node2D.new()
	for container_name in ["Asteroids", "Drones"]:
		var container = Node2D.new()
		container.name = container_name
		scene.add_child(container)
	var manager = load("res://scripts/systems/mining/resource_manager.gd").new()
	scene.add_child(manager)
	root.add_child(scene)
	current_scene = scene
	var flagship = load("res://scenes/entities/Flotilla.tscn").instantiate()
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
		var target = load("res://scenes/entities/Asteroid.tscn").instantiate()
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
	state.dev_ship_overrides["merlinda"] = true
	manager.ship_upgrade_levels["merlinda"]["consolation"] = 0
	manager.companion_upgrade_levels["racer"]["sponsorship"] = 0
	var node_reward = manager._get_merlinda_racer_finish_reward(7)
	var course_reward = manager.get_merlinda_race_completion_reward(7)
	manager.merlinda_race_course.assign([Vector2(100.0, 50.0), Vector2(200.0, 80.0)])
	manager.merlinda_race_active = true
	var race_path = manager.get_merlinda_race_path()
	var merlinda_home = manager.get_ship_world_position("merlinda")
	var race_passed = node_reward == 0.0 and course_reward == 2400.0 and race_path.size() > 8
	race_passed = race_passed and race_path.front().is_equal_approx(merlinda_home) and race_path.back().is_equal_approx(merlinda_home)
	var first_node_waypoints = manager._get_merlinda_node_waypoints(0, 0.5, merlinda_home)
	for waypoint in first_node_waypoints:
		race_passed = race_passed and waypoint.distance_to(manager.merlinda_race_course[0]) >= manager.MERLINDA_BASE_ARC_CLEARANCE
	for waypoint_index in range(1, first_node_waypoints.size()):
		var closest_to_node = Geometry2D.get_closest_point_to_segment(manager.merlinda_race_course[0], first_node_waypoints[waypoint_index - 1], first_node_waypoints[waypoint_index])
		race_passed = race_passed and closest_to_node.distance_to(manager.merlinda_race_course[0]) >= manager.MERLINDA_NODE_OBSTACLE_RADIUS
	var base_course_width = manager.get_racer_course_width()
	var base_outer_arc = manager._get_merlinda_node_waypoints(0, 1.0, merlinda_home)[0].distance_to(manager.merlinda_race_course[0])
	manager.ship_upgrade_levels["merlinda"]["awareness"] = 5
	race_passed = race_passed and manager.get_racer_course_width() > base_course_width
	race_passed = race_passed and manager._get_merlinda_node_waypoints(0, 1.0, merlinda_home)[0].distance_to(manager.merlinda_race_course[0]) > base_outer_arc
	manager.ship_upgrade_levels["merlinda"]["awareness"] = 0
	var base_racer_cap = manager.get_companion_upgrade_cap("racer", "speed")
	state.prestige_level = 1
	state.cap_levels["racer_general_cap"] = 1
	race_passed = race_passed and base_racer_cap == 10 and manager.get_companion_upgrade_cap("racer", "speed") == 12
	state.cap_levels["racer_general_cap"] = 0
	state.prestige_level = 0
	manager.ship_upgrade_levels["merlinda"]["participants"] = 2
	var participant_cost = manager.get_ship_upgrade_cost("merlinda", "participants")
	manager.companion_upgrade_levels["racer"]["sponsorship"] = 5
	var sponsored_participant_cost = manager.get_ship_upgrade_cost("merlinda", "participants")
	race_passed = race_passed and sponsored_participant_cost < participant_cost
	manager.companion_upgrade_levels["racer"]["sponsorship"] = 0
	var flyby_reached = manager._has_racer_reached_marker(
		Vector2(-100.0, 100.0), Vector2(20.0, 100.0), Vector2.ZERO, Vector2(200.0, 0.0), 1000.0, 3.5, 1.0 / 60.0
	)
	var corner_reached = manager._has_racer_reached_marker(
		Vector2(-120.0, 70.0), Vector2(-50.0, 70.0), Vector2.ZERO, Vector2(200.0, 0.0), 1000.0, 3.5, 1.0 / 60.0
	)
	race_passed = race_passed and flyby_reached and corner_reached
	manager.companion_upgrade_levels["racer"]["speed"] = 0
	var base_racer_speed = manager.get_racer_drone_speed(250.0)
	var base_marker_speed = manager.get_merlinda_course_marker_speed()
	manager.companion_upgrade_levels["racer"]["speed"] = 1
	var boosted_racer_speed = manager.get_racer_drone_speed(250.0)
	var boosted_marker_speed = manager.get_merlinda_course_marker_speed()
	race_passed = race_passed and is_equal_approx(boosted_racer_speed / base_racer_speed, 1.05)
	race_passed = race_passed and is_equal_approx(boosted_marker_speed / base_marker_speed, 1.05)
	manager.companion_upgrade_levels["racer"]["speed"] = 0
	state.passive_levels["racer_ion_thrusters"] = 1
	race_passed = race_passed and is_equal_approx(manager.get_racer_drone_speed(250.0), base_racer_speed * 2.0)
	race_passed = race_passed and is_equal_approx(manager.get_merlinda_course_marker_speed(), base_marker_speed * 2.0)
	state.passive_levels["racer_ion_thrusters"] = 0
	var base_turn_speed = manager.get_racer_turn_speed()
	state.passive_levels["racer_afterburn"] = 1
	race_passed = race_passed and is_equal_approx(manager.get_racer_turn_speed(), base_turn_speed * 1.5)
	state.passive_levels["racer_afterburn"] = 0
	state.passive_levels["racer_grand_prize"] = 1
	race_passed = race_passed and manager.get_merlinda_race_completion_reward(7) == 12000.0
	state.passive_levels["racer_grand_prize"] = 0
	manager.ship_upgrade_levels["merlinda"]["participants"] = 1
	state.passive_levels["racer_taggers"] = 1
	manager.racer_states.clear()
	manager._sync_merlinda_racers()
	race_passed = race_passed and manager.racer_states.size() == 2
	state.passive_levels["racer_taggers"] = 0
	manager.racer_states.clear()
	var marker_position = race_path[2]
	manager.merlinda_course_marker_path.assign(race_path)
	manager.merlinda_course_marker_position = marker_position
	manager.merlinda_course_marker_index = 3
	manager.merlinda_course_marker_finished = false
	var remaining_race_path = manager.get_merlinda_race_path()
	race_passed = race_passed and remaining_race_path.size() < race_path.size()
	race_passed = race_passed and remaining_race_path.front().is_equal_approx(marker_position)
	manager.merlinda_course_marker_path.clear()
	manager.merlinda_race_active = false
	race_passed = race_passed and manager.get_merlinda_race_path().is_empty()
	print("Merlinda route and node reward: %s" % ("PASS" if race_passed else "FAIL"))
	if not race_passed:
		failures += 1
	var asteroid_container = scene.get_node("Asteroids")
	for existing_node in asteroid_container.get_children():
		asteroid_container.remove_child(existing_node)
		existing_node.free()
	var race_node = load("res://scenes/entities/Asteroid.tscn").instantiate()
	asteroid_container.add_child(race_node)
	race_node.add_to_group("asteroids")
	race_node.position = merlinda_home + Vector2(4000.0, 1000.0)
	race_node.resource_amount = 1000
	manager.ship_upgrade_levels["merlinda"]["participants"] = 1
	manager._reset_merlinda_race()
	manager.merlinda_race_cooldown = 0.0
	var first_race_started := false
	var first_race_completed := false
	var second_race_started := false
	for step in range(1200):
		manager._process_merlinda_race(0.05)
		if manager.merlinda_race_active:
			if first_race_completed:
				second_race_started = true
				break
			first_race_started = true
		elif first_race_started:
			first_race_completed = true
	var restart_passed = first_race_started and first_race_completed and second_race_started
	print("Merlinda race completion and restart: %s" % ("PASS" if restart_passed else "FAIL"))
	if not restart_passed:
		failures += 1
	var movement_drone = load("res://scripts/entities/drone.gd").new()
	movement_drone.position = Vector2.ZERO
	movement_drone.speed = 1200.0
	movement_drone.move_toward_target(Vector2(10.0, 0.0), 1.0 / 60.0)
	var movement_passed = movement_drone.position.is_equal_approx(Vector2(10.0, 0.0))
	print("High-speed drone arrival clamp: %s" % ("PASS" if movement_passed else "FAIL"))
	if not movement_passed:
		failures += 1
	movement_drone.free()
	scene.free()
	quit(1 if failures else 0)
