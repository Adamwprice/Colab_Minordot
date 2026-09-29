extends SceneTree

const Catalog = preload("res://scripts/data/ship_catalog.gd")
const MANAGER_SCRIPT = preload("res://scripts/systems/mining/resource_manager.gd")
const FLOTILLA_SCENE = preload("res://scenes/entities/Flotilla.tscn")
const ASTEROID_SCENE = preload("res://scenes/entities/Asteroid.tscn")
const BATTLE_SCENE = preload("res://scenes/combat/Battle.tscn")

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if condition else "FAIL", description])
	if not condition:
		failures += 1

func _run() -> void:
	for owner in Catalog.get_ship_ids(true):
		_stress_ship(str(owner))
	for companion_id in Catalog.get_companion_ids():
		var companion_data = Catalog.get_companion_data(companion_id)
		if not Array(companion_data.get("ore", [])).is_empty() or not Array(companion_data.get("research", [])).is_empty():
			_stress_companion(companion_id)
	_stress_all_combined()
	print("UPGRADE STRESS SUMMARY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _create_fixture(enabled_ships: Array[String]) -> Dictionary:
	var state = root.get_node("GameState")
	state.reset_for_new_game()
	state.prestige_level = 30
	for ship_id in Catalog.get_ship_ids():
		state.dev_ship_overrides[ship_id] = enabled_ships.has(ship_id)

	var fixture = Node2D.new()
	fixture.name = "UpgradeStressFixture"
	for container_name in ["Asteroids", "Drones"]:
		var container = Node2D.new()
		container.name = container_name
		fixture.add_child(container)
	root.add_child(fixture)
	current_scene = fixture

	var manager = MANAGER_SCRIPT.new()
	manager.name = "ResourceManager"
	manager.autosave_enabled = false
	fixture.add_child(manager)
	var flotilla = FLOTILLA_SCENE.instantiate()
	flotilla.name = "StressFlagship"
	fixture.add_child(flotilla)
	manager.flotilla = flotilla
	manager.configure_flagship()
	manager.spawn_resource_field()

	var gas_node = ASTEROID_SCENE.instantiate()
	gas_node.name = "StressGasCloud"
	fixture.get_node("Asteroids").add_child(gas_node)
	gas_node.add_to_group("asteroids")
	gas_node.add_to_group("special_resource")
	gas_node.position = flotilla.position + Vector2(1200.0, 300.0)
	gas_node.resource_amount = 100000
	gas_node.max_resource_amount = 100000
	gas_node.set_meta("resource_type", "gas_cloud")
	gas_node.set_meta("required_ship", "tobias")
	return {"fixture": fixture, "manager": manager, "state": state, "flotilla": flotilla}

func _free_fixture(data: Dictionary) -> void:
	var fixture = data.get("fixture")
	if current_scene == fixture:
		current_scene = null
	if is_instance_valid(fixture):
		fixture.free()

func _ship_dependencies(ship_id: String) -> Array[String]:
	var enabled: Array[String] = []
	if int(Catalog.get_ship_data(ship_id).get("rank", 0)) > 0:
		enabled.append(ship_id)
	if ship_id == "boschore":
		enabled.append("tobias")
	return enabled

func _stress_ship(ship_id: String) -> void:
	var data = _create_fixture(_ship_dependencies(ship_id))
	var manager = data["manager"]
	var state = data["state"]
	var rows = _get_owner_ore_rows(ship_id)
	var catalog_data = Catalog.get_ship_data(ship_id)
	var cap_key = str(catalog_data.get("cap_key", "%s_general_cap" % ship_id))

	_check(not catalog_data.is_empty(), "%s catalog entry exists" % ship_id)
	for row in rows:
		var stat_key = str(row["stat"])
		var cost = _get_owner_cost(manager, ship_id, stat_key)
		var cap = _get_owner_cap(manager, ship_id, stat_key)
		_check(cost > 0 and cap > 0, "%s/%s has a positive cost and cap" % [ship_id, stat_key])
		_set_owner_level(manager, ship_id, stat_key, 0)
		manager.total_resources = 1.0e30
		if manager.flotilla:
			manager.flotilla.storage = manager.total_resources
		_check(_purchase_owner_upgrade(manager, ship_id, stat_key), "%s/%s purchases successfully" % [ship_id, stat_key])
		_set_owner_level(manager, ship_id, stat_key, cap)
		_exercise_runtime(manager, state, 2)
		_set_owner_level(manager, ship_id, stat_key, 0)

	if state.cap_levels.has(cap_key) and not rows.is_empty():
		var sample_stat = str(rows[0]["stat"])
		var base_cap = _get_owner_cap(manager, ship_id, sample_stat)
		state.cap_levels[cap_key] = 1
		var raised_cap = _get_owner_cap(manager, ship_id, sample_stat)
		_check(raised_cap >= base_cap + 2, "%s cap research raises its ore caps" % ship_id)
		state.cap_levels[cap_key] = 0

	_set_all_owner_levels_to_cap(manager, ship_id, rows)
	var research_rows = Catalog.get_research_rows(ship_id)
	for research in research_rows:
		_clear_passive_research(state)
		var research_key = str(research["key"])
		_check(state.passive_levels.has(research_key), "%s research %s is registered" % [ship_id, research_key])
		if state.passive_levels.has(research_key):
			state.passive_levels[research_key] = 1
			_enable_research_toggles(state)
			manager.regenerate_asteroid_field(6)
			_exercise_runtime(manager, state, 3)
			_exercise_long_cycles(manager)
			_exercise_battle(data, "%s/%s" % [ship_id, research_key])

	_clear_passive_research(state)
	for research in research_rows:
		state.passive_levels[str(research["key"])] = 1
	if state.cap_levels.has(cap_key):
		state.cap_levels[cap_key] = 2
	_enable_research_toggles(state)
	manager.regenerate_asteroid_field(6)
	_exercise_runtime(manager, state, 30)
	_exercise_long_cycles(manager)
	_exercise_battle(data, ship_id)
	_check(_runtime_values_are_finite(manager), "%s combined upgrades produce finite runtime values" % ship_id)
	_free_fixture(data)

func _stress_companion(companion_id: String) -> void:
	var companion_data = Catalog.get_companion_data(companion_id)
	var required_ship = str(companion_data.get("required_ship", ""))
	var enabled: Array[String] = []
	if not required_ship.is_empty():
		enabled.append(required_ship)
	for research in Array(companion_data.get("research", [])):
		var research_ship = str(research.get("requires_ship", required_ship))
		if not research_ship.is_empty() and not enabled.has(research_ship):
			enabled.append(research_ship)
	var data = _create_fixture(enabled)
	var manager = data["manager"]
	var state = data["state"]
	var ore_rows = Array(companion_data.get("ore", []))
	for row in ore_rows:
		var stat_key = str(row["stat"])
		var cost = manager.get_companion_upgrade_cost(companion_id, stat_key)
		var cap = manager.get_companion_upgrade_cap(companion_id, stat_key)
		_check(cost > 0 and cap > 0, "%s/%s has a positive cost and cap" % [companion_id, stat_key])
		manager.total_resources = 1.0e30
		_check(manager.upgrade_companion_stat(companion_id, stat_key), "%s/%s purchases successfully" % [companion_id, stat_key])
		manager.companion_upgrade_levels[companion_id][stat_key] = cap
		_exercise_runtime(manager, state, 2)
		manager.companion_upgrade_levels[companion_id][stat_key] = 0

	for row in ore_rows:
		var stat_key = str(row["stat"])
		manager.companion_upgrade_levels[companion_id][stat_key] = manager.get_companion_upgrade_cap(companion_id, stat_key)
	for research in Array(companion_data.get("research", [])):
		_clear_passive_research(state)
		var research_key = str(research["key"])
		_check(state.passive_levels.has(research_key), "%s research %s is registered" % [companion_id, research_key])
		if state.passive_levels.has(research_key):
			state.passive_levels[research_key] = 1
			_exercise_runtime(manager, state, 3)
			_exercise_long_cycles(manager)
			_exercise_battle(data, "%s/%s" % [companion_id, research_key])
	_check(_runtime_values_are_finite(manager), "%s upgrades produce finite runtime values" % companion_id)
	_free_fixture(data)

func _stress_all_combined() -> void:
	var all_ships: Array[String] = []
	all_ships.assign(Catalog.get_ship_ids())
	var data = _create_fixture(all_ships)
	var manager = data["manager"]
	var state = data["state"]
	for ship_id in Catalog.get_ship_ids(true):
		var rows = _get_owner_ore_rows(ship_id)
		_set_all_owner_levels_to_cap(manager, ship_id, rows)
	for companion_id in Catalog.get_companion_ids():
		for row in Array(Catalog.get_companion_data(companion_id).get("ore", [])):
			var stat_key = str(row["stat"])
			manager.companion_upgrade_levels[companion_id][stat_key] = manager.get_companion_upgrade_cap(companion_id, stat_key)
	for cap_key in state.cap_levels:
		state.cap_levels[cap_key] = 2
	for research_key in state.passive_levels:
		state.passive_levels[research_key] = 1
	_enable_research_toggles(state)
	manager.spawn_owned_drones(manager.get_owned_drone_count())
	manager.regenerate_asteroid_field(12)
	_exercise_runtime(manager, state, 100)
	_exercise_long_cycles(manager)
	_exercise_battle(data, "all upgrades combined")
	_check(_runtime_values_are_finite(manager), "All ships, ore upgrades, and research upgrades coexist")
	_free_fixture(data)

func _get_owner_ore_rows(owner: String) -> Array:
	if owner == "flagship":
		return [
			{"stat": "click_output"}, {"stat": "click_multiplier"}, {"stat": "drones"},
			{"stat": "flagship_speed"}, {"stat": "refining"}
		]
	if owner == "mining_drone":
		return [{"stat": "mining"}, {"stat": "mining_speed"}, {"stat": "capacity"}, {"stat": "speed"}]
	return Catalog.get_ore_rows(owner)

func _get_owner_cost(manager: Node, owner: String, stat_key: String) -> int:
	if owner in ["flagship", "mining_drone"]:
		return manager.get_ore_upgrade_cost(stat_key)
	return manager.get_ship_upgrade_cost(owner, stat_key)

func _get_owner_cap(manager: Node, owner: String, stat_key: String) -> int:
	if owner in ["flagship", "mining_drone"]:
		return manager.get_ore_upgrade_cap(stat_key)
	return manager.get_ship_upgrade_cap(owner, stat_key)

func _set_owner_level(manager: Node, owner: String, stat_key: String, level: int) -> void:
	if owner == "flagship" or owner == "mining_drone":
		var property_name = {
			"click_output": "click_output_level", "click_multiplier": "click_multiplier_level",
			"drones": "drone_level", "flagship_speed": "flagship_speed_level",
			"refining": "refining_level", "mining": "mining_level",
			"mining_speed": "mining_speed_level", "capacity": "capacity_level", "speed": "speed_level"
		}.get(stat_key, "")
		if not property_name.is_empty():
			manager.set(property_name, level)
	else:
		manager.ship_upgrade_levels[owner][stat_key] = level

func _purchase_owner_upgrade(manager: Node, owner: String, stat_key: String) -> bool:
	if owner == "flagship" or owner == "mining_drone":
		var method_name = {
			"click_output": "upgrade_click_output", "click_multiplier": "upgrade_click_multiplier",
			"drones": "buy_drone", "flagship_speed": "upgrade_flagship_speed",
			"refining": "upgrade_refining", "mining": "upgrade_mining",
			"mining_speed": "upgrade_mining_speed", "capacity": "upgrade_capacity", "speed": "upgrade_speed"
		}.get(stat_key, "")
		return not method_name.is_empty() and bool(manager.call(method_name))
	return bool(manager.upgrade_ship_stat(owner, stat_key))

func _set_all_owner_levels_to_cap(manager: Node, owner: String, rows: Array) -> void:
	for row in rows:
		var stat_key = str(row["stat"])
		_set_owner_level(manager, owner, stat_key, _get_owner_cap(manager, owner, stat_key))

func _clear_passive_research(state: Node) -> void:
	for research_key in state.passive_levels:
		state.passive_levels[research_key] = 0
	state.autor_enabled = false
	state.development_protocol_enabled = false
	state.merlinda_derby_picks_enabled = false

func _enable_research_toggles(state: Node) -> void:
	state.autor_enabled = state.get_passive_level("flagship_autor") > 0
	state.development_protocol_enabled = state.get_passive_level("flagship_development_protocol") > 0
	state.merlinda_derby_picks_enabled = state.get_passive_level("merlinda_derby_picks") > 0

func _exercise_runtime(manager: Node, state: Node, steps: int) -> void:
	manager.configure_flagship()
	if manager.get_parent().get_node("Drones").get_child_count() == 0:
		manager.spawn_drones(1)
	for drone in manager.get_parent().get_node("Drones").get_children():
		manager.configure_drone(drone)
	for step in range(steps):
		manager._process(0.1)
		for drone in manager.get_parent().get_node("Drones").get_children():
			if is_instance_valid(drone):
				drone._physics_process(0.1)
	manager.get_visual_subcraft()
	manager.get_extended_battle_stats()
	manager.get_click_output()
	manager.get_click_rate_cap()
	manager.get_hold_click_rate()
	manager.get_mining_amount()
	manager.get_mining_interval()
	manager.get_capacity()
	manager.get_speed()
	manager.get_fleet_mining_range()
	manager.get_field_resource_cap(10)
	manager.get_field_extra_node_count()
	manager.get_global_ore_multiplier()
	manager.get_ore_cost_multiplier()

func _exercise_long_cycles(manager: Node) -> void:
	manager._process_ambrossa_income(30.0)
	manager._process_catalog_ship_income(301.0)
	manager._process_catalog_research_income(301.0)
	manager._process_local_antenna(301.0)
	manager._process_merlinda_race(10.0)

func _build_battle_stats(manager: Node, state: Node) -> Dictionary:
	var stats = {
		"battle_type": "research_hunt", "enemy_name": "Upgrade Stress Target",
		"enemy_max_hp": 1000000, "enemy_dps": 1, "enemy_drone_count": 3,
		"enemy_drone_hp": 1000, "enemy_drone_dps": 1,
		"click_damage": manager.get_battle_click_damage(), "click_rate_cap": manager.get_click_rate_cap(),
		"hold_click_rate": manager.get_hold_click_rate(), "autor_enabled": state.is_autor_active(),
		"picket_damage": state.get_flagship_picket_damage(), "mining_amount": manager.get_drone_battle_damage(),
		"drone_max_hp": manager.get_drone_max_hp(), "drone_count": manager.get_active_drone_count(),
		"flagship_max_hp": state.get_flagship_max_hp(), "flagship_armor": state.get_flagship_armor_reduction(),
		"flagship_shield": state.get_flagship_shield_reduction(),
		"refinery_unlocked": state.is_ship_unlocked("refinery"), "refinery_max_hp": manager.get_refinery_stat_value("hull"),
		"refinery_armor": manager.get_refinery_stat_value("armor"), "refinery_shield": manager.get_refinery_stat_value("shield"),
		"hammond_unlocked": state.is_ship_unlocked("hammond"), "hammond_max_hp": manager.get_hammond_max_hp(),
		"hammond_damage_reduction": manager.get_hammond_damage_reduction(), "hammond_damage": manager.get_hammond_damage(),
		"hammond_interval": manager.get_hammond_interval(), "carrier_unlocked": state.is_ship_unlocked("drone_carrier"),
		"gethica_unlocked": state.is_ship_unlocked("gethica"), "ambrossa_unlocked": state.is_ship_unlocked("ambrossa"),
		"fighter_drone_count": manager.get_fighter_drone_count(), "fighter_drone_damage": manager.get_fighter_drone_damage(),
		"fighter_drone_speed": manager.get_fighter_drone_speed()
	}
	stats.merge(manager.get_extended_battle_stats(), true)
	return stats

func _exercise_battle(data: Dictionary, label: String) -> void:
	var fixture = data["fixture"]
	var manager = data["manager"]
	var state = data["state"]
	state.prepare_battle(manager.get_run_state(), _build_battle_stats(manager, state))
	var battle = BATTLE_SCENE.instantiate()
	fixture.add_child(battle)
	var hostile_hp_before = _get_total_hostile_hp(battle)
	for step in range(10):
		battle._process(0.1)
	battle.held_attack_target = "drone" if not battle.enemy_drones.is_empty() else "boss"
	battle.held_enemy_drone_index = 0
	battle.last_click_time = -1.0
	battle._attack_held_target(false)
	_check(_get_total_hostile_hp(battle) < hostile_hp_before, "%s battle-facing upgrades run without conflict" % label)
	fixture.remove_child(battle)
	battle.free()

func _get_total_hostile_hp(battle: Node) -> int:
	var total = int(battle.enemy_hp)
	for enemy_drone in battle.enemy_drones:
		total += int(enemy_drone["hp"])
	return total

func _runtime_values_are_finite(manager: Node) -> bool:
	var values = [
		manager.total_resources, manager.get_click_output(), manager.get_click_rate_cap(), manager.get_hold_click_rate(),
		manager.get_mining_amount(), manager.get_mining_interval(), manager.get_capacity(), manager.get_speed(),
		manager.get_fleet_mining_range(), manager.get_field_resource_cap(10), manager.get_field_extra_node_count(),
		manager.get_global_ore_multiplier(), manager.get_ore_cost_multiplier(), manager.get_hammond_damage(),
		manager.get_hammond_interval(), manager.get_fighter_drone_damage(), manager.get_fighter_drone_speed()
	]
	for value in values:
		if value is float and not is_finite(value):
			return false
		if value is int and value < 0:
			return false
	return true
