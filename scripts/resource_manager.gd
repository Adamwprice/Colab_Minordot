extends Node

signal resource_changed
signal upgrades_changed

@export var asteroid_scene: PackedScene
@export var drone_scene: PackedScene

var flotilla: Node = null

var total_resources: float = 0.0
var click_output_level: int = 0
var click_multiplier_level: int = 0
var speed_level: int = 0
var mining_level: int = 0
var mining_speed_level: int = 0
var drone_multiplier_level: int = 0
var capacity_level: int = 0
var drone_level: int = 0
var flagship_speed_level: int = 0
var refinery_upgrade_levels := {
	"command_capacity": 0,
	"click_rate": 0,
	"click_multiplier": 0,
	"global_income_bonus": 0
}
var ship_upgrade_levels := {
	"hammond": {"command_capacity": 0, "click_rate": 0, "autocannon": 0, "ammo_conveyor": 0, "torpedo": 0},
	"drone_carrier": {"command_capacity": 0, "click_rate": 0, "drone_coordination": 0, "fighter_drones": 0}
}
var asteroid_field_level: int = 0
var next_stage_timer: float = -1.0
var last_click_time: float = -1.0
var rng := RandomNumberGenerator.new()
var asteroid_priority := {} # maps Node -> int priority
var _sort_target: Node = null

const SAVE_PATH := "user://save_game.save"
const PLANET_MIN_COUNT := 0
const PLANET_MAX_COUNT := 2
const ASTEROID_MIN_COUNT := 4
const ASTEROID_MAX_COUNT := 10
const FIELD_RESOURCE_CAP := 5000
const PLANET_MIN_DISTANCE_FROM_SUN := 100.0
const ASTEROID_MIN_DISTANCE_FROM_SUN := 1000.0
const PLANET_SEPARATION := 500.0
const ASTEROID_SEPARATION := 500.0
const SPAWN_HALF_WIDTH := 600.0
const SPAWN_HALF_HEIGHT := 350.0
const SPAWN_FALLBACK_EXTRA_RADIUS := 700.0

const BASE_SPEED := 50.0
const BASE_MINING_AMOUNT := 1
const BASE_MINING_SPEED := 1.0
const BASE_CAPACITY := 10
const BASE_DRONE_CAP := 0
const BASE_CLICK_OUTPUT := 1
const BASE_CLICK_RATE_CAP := 10
const BASE_FLAGSHIP_SPEED := 60.0
const CLICK_OUTPUT_PER_LEVEL := 1
const CLICK_RATE_CAP_PER_LEVEL := 1
const FLAGSHIP_SPEED_PER_LEVEL := 10.0
const MINING_AMOUNT_PER_LEVEL := 1
const MINING_SPEED_PER_LEVEL := 0.1
const DRONE_MULTIPLIER_PER_LEVEL := 0.25
const DRONE_CAPACITY_PER_LEVEL := 1
const CARRY_CAPACITY_PER_LEVEL := 10
const ORE_COST_MULTIPLIER := 1.4
const DRONE_SPEED_PER_LEVEL := 10.0
const MAX_UPGRADE_LEVEL := 10
const NEXT_STAGE_DELAY := 10.0
const ORE_UPGRADE_BASE_COSTS := {
	"click_output": 50,
	"click_multiplier": 1000,
	"drones": 750,
	"flagship_speed": 25,
	"mining": 100,
	"mining_speed": 150,
	"drone_multiplier": 1750,
	"capacity": 75,
	"speed": 10
}
const REFINERY_ORE_BASE_COSTS := {
	"command_capacity": 750,
	"click_rate": 1000,
	"click_multiplier": 1000,
	"global_income_bonus": 2500
}
const SHIP_ORE_BASE_COSTS := {
	"command_capacity": 750,
	"click_rate": 1000,
	"autocannon": 100,
	"ammo_conveyor": 150,
	"torpedo": 50,
	"drone_coordination": 10,
	"fighter_drones": 750
}
const HAMMOND_BASE_DAMAGE := 5.0
const HAMMOND_AUTOCANNON_DAMAGE := 0.25
const HAMMOND_BASE_INTERVAL := 1.0
const HAMMOND_CONVEYOR_REDUCTION := 0.002
const HAMMOND_MIN_INTERVAL := 0.1
const FIGHTER_DRONE_DAMAGE := 2
const CARRIER_COORDINATION_SPEED := 5.0

func _ready():
	if asteroid_scene == null:
		asteroid_scene = load("res://scenes/Asteroid.tscn")
	if drone_scene == null:
		drone_scene = load("res://scenes/Drone.tscn")
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_signal("ship_modifiers_changed"):
		game_state.ship_modifiers_changed.connect(Callable(self, "_on_ship_modifiers_changed"))
	rng.randomize()
	set_process(true)

func resolve_ship_stat(ship_id: StringName, stat: StringName, base_value: float) -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("resolve_ship_stat"):
		return float(game_state.resolve_ship_stat(ship_id, stat, base_value))
	return base_value

func _on_ship_modifiers_changed() -> void:
	configure_flagship()
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			configure_drone(drone)
	emit_signal("upgrades_changed")

func get_ore_upgrade_cap(upgrade: String) -> int:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_upgrade_cap"):
		return int(game_state.get_upgrade_cap(upgrade))
	return MAX_UPGRADE_LEVEL

func get_run_state() -> Dictionary:
	var parent = get_parent()
	var drone_count = 0
	if parent and parent.has_node("Drones"):
		drone_count = parent.get_node("Drones").get_child_count()
	return {
		"total_resources": total_resources,
		"upgrades": {
			"click_output": click_output_level,
			"click_multiplier": click_multiplier_level,
			"speed": speed_level,
			"mining": mining_level,
			"mining_speed": mining_speed_level,
			"drone_multiplier": drone_multiplier_level,
			"capacity": capacity_level,
			"drones": drone_level,
			"flagship_speed": flagship_speed_level
		},
		"refinery_upgrades": refinery_upgrade_levels.duplicate(true),
		"ship_upgrades": ship_upgrade_levels.duplicate(true),
		"asteroid_field_level": asteroid_field_level,
		"drone_count": drone_count,
		"click_damage": get_battle_click_damage(),
		"mining_amount": get_mining_amount()
	}

func apply_run_state(state: Dictionary, active_drone_override: int = -1) -> void:
	if state.is_empty():
		return
	var upgrades = state.get("upgrades", {})
	click_output_level = int(upgrades.get("click_output", click_output_level))
	click_multiplier_level = int(upgrades.get("click_multiplier", click_multiplier_level))
	speed_level = int(upgrades.get("speed", speed_level))
	mining_level = int(upgrades.get("mining", mining_level))
	mining_speed_level = int(upgrades.get("mining_speed", mining_speed_level))
	drone_multiplier_level = int(upgrades.get("drone_multiplier", drone_multiplier_level))
	capacity_level = int(upgrades.get("capacity", capacity_level))
	drone_level = int(upgrades.get("drones", drone_level))
	flagship_speed_level = int(upgrades.get("flagship_speed", flagship_speed_level))
	var saved_refinery_upgrades: Dictionary = state.get("refinery_upgrades", {})
	for stat_key in refinery_upgrade_levels:
		refinery_upgrade_levels[stat_key] = max(0, int(saved_refinery_upgrades.get(stat_key, refinery_upgrade_levels[stat_key])))
	var saved_ship_upgrades: Dictionary = state.get("ship_upgrades", {})
	for ship_key in ship_upgrade_levels:
		var saved_levels: Dictionary = saved_ship_upgrades.get(ship_key, {})
		for stat_key in ship_upgrade_levels[ship_key]:
			ship_upgrade_levels[ship_key][stat_key] = max(0, int(saved_levels.get(stat_key, ship_upgrade_levels[ship_key][stat_key])))
	asteroid_field_level = int(state.get("asteroid_field_level", asteroid_field_level))
	total_resources = float(state.get("total_resources", total_resources))
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	configure_flagship()
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		var drone_container = parent.get_node("Drones")
		for drone in drone_container.get_children():
			drone.free()
		var active_drones = int(state.get("drone_count", drone_level))
		if active_drone_override >= 0:
			active_drones = min(active_drones, active_drone_override)
		spawn_drones(active_drones)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")

func can_enter_battle() -> bool:
	return asteroid_field_level + 1 >= 10

func advance_field_after_battle() -> void:
	regenerate_asteroid_field()

func reset_run_for_prestige(surviving_drones: int = 0, update_game_state: bool = true, force_prestige: bool = false) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	if update_game_state and game_state and game_state.has_method("reset_for_prestige"):
		if not bool(game_state.reset_for_prestige(force_prestige)):
			return false
	total_resources = 0
	click_output_level = 0
	click_multiplier_level = 0
	speed_level = 0
	mining_level = 0
	mining_speed_level = 0
	drone_multiplier_level = 0
	capacity_level = 0
	var starting_command_level = 0
	if game_state and game_state.has_method("get_flagship_starting_command_level"):
		starting_command_level = int(game_state.get_flagship_starting_command_level())
	drone_level = max(max(0, surviving_drones), starting_command_level)
	flagship_speed_level = 0
	for stat_key in refinery_upgrade_levels:
		refinery_upgrade_levels[stat_key] = 0
	for ship_key in ship_upgrade_levels:
		for stat_key in ship_upgrade_levels[ship_key]:
			ship_upgrade_levels[ship_key][stat_key] = 0
	asteroid_field_level = 0
	next_stage_timer = -1.0
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = 0
	var parent = get_parent()
	if parent and parent.has_node("Asteroids"):
		for asteroid in parent.get_node("Asteroids").get_children():
			asteroid.free()
		asteroid_priority.clear()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			drone.free()
		spawn_drones(drone_level)
	spawn_resource_field()
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func purchase_prestige(force: bool = false) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	if not force and (not game_state.has_method("can_prestige") or not game_state.can_prestige(total_resources)):
		return false
	return reset_run_for_prestige(0, true, true)

func start_battle() -> bool:
	if not can_enter_battle():
		return false
	var parent = get_parent()
	if parent == null:
		return false
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	var boss_tier = int(game_state.boss_tier)
	if game_state.has_method("get_effective_boss_tier"):
		boss_tier = int(game_state.get_effective_boss_tier())
	var flagship_max_hp = 100
	var flagship_armor = 0
	var flagship_shield = 0.0
	if game_state.has_method("get_flagship_max_hp"):
		flagship_max_hp = int(game_state.get_flagship_max_hp())
	if game_state.has_method("get_flagship_armor_reduction"):
		flagship_armor = int(game_state.get_flagship_armor_reduction())
	if game_state.has_method("get_flagship_shield_reduction"):
		flagship_shield = float(game_state.get_flagship_shield_reduction())
	var refinery_unlocked = game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("refinery")
	var hammond_unlocked = game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("hammond")
	var carrier_unlocked = game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("drone_carrier")
	var battle_stats = {
		"battle_type": "standard",
		"click_damage": get_battle_click_damage(),
		"click_rate_cap": get_click_rate_cap(),
		"mining_amount": get_drone_battle_damage(),
		"drone_max_hp": get_drone_max_hp(),
		"drone_count": parent.get_node("Drones").get_child_count() if parent.has_node("Drones") else 0,
		"field_level": asteroid_field_level + 1,
		"boss_tier": boss_tier,
		"flagship_max_hp": flagship_max_hp,
		"flagship_armor": flagship_armor,
		"flagship_shield": flagship_shield,
		"refinery_unlocked": refinery_unlocked,
		"refinery_max_hp": int(get_refinery_stat_value("hull")),
		"refinery_armor": int(get_refinery_stat_value("armor")),
		"refinery_shield": float(get_refinery_stat_value("shield")),
		"hammond_unlocked": hammond_unlocked,
		"hammond_damage": get_hammond_damage(),
		"hammond_interval": get_hammond_interval(),
		"carrier_unlocked": carrier_unlocked,
		"fighter_drone_count": get_fighter_drone_count(),
		"fighter_drone_damage": FIGHTER_DRONE_DAMAGE,
		"fighter_drone_speed": get_fighter_drone_speed()
	}
	game_state.prepare_battle(get_run_state(), battle_stats)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
	return true

func start_prestige_battle(target_prestige: int) -> bool:
	return false

func start_research_hunt() -> bool:
	var parent = get_parent()
	var game_state = get_node_or_null("/root/GameState")
	if parent == null or game_state == null or not game_state.has_method("create_research_hunt"):
		return false
	var battle_stats: Dictionary = game_state.create_research_hunt()
	if battle_stats.is_empty():
		return false
	battle_stats.merge({
		"click_damage": get_battle_click_damage(),
		"click_rate_cap": get_click_rate_cap(),
		"mining_amount": get_drone_battle_damage(),
		"drone_max_hp": get_drone_max_hp(),
		"drone_count": parent.get_node("Drones").get_child_count() if parent.has_node("Drones") else 0,
		"field_level": asteroid_field_level + 1,
		"flagship_max_hp": int(game_state.get_flagship_max_hp()),
		"flagship_armor": int(game_state.get_flagship_armor_reduction()),
		"flagship_shield": float(game_state.get_flagship_shield_reduction()),
		"refinery_unlocked": game_state.is_ship_unlocked("refinery"),
		"refinery_max_hp": int(get_refinery_stat_value("hull")),
		"refinery_armor": int(get_refinery_stat_value("armor")),
		"refinery_shield": float(get_refinery_stat_value("shield")),
		"hammond_unlocked": game_state.is_ship_unlocked("hammond"),
		"hammond_damage": get_hammond_damage(),
		"hammond_interval": get_hammond_interval(),
		"carrier_unlocked": game_state.is_ship_unlocked("drone_carrier"),
		"fighter_drone_count": get_fighter_drone_count(),
		"fighter_drone_damage": FIGHTER_DRONE_DAMAGE,
		"fighter_drone_speed": get_fighter_drone_speed()
	}, true)
	game_state.prepare_battle(get_run_state(), battle_stats)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
	return true

func _process(delta: float) -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	var resource_nodes = 0
	for node in container.get_children():
		if not node.is_in_group("sun"):
			resource_nodes += 1
	if resource_nodes > 0:
		next_stage_timer = -1.0
		return
	if next_stage_timer < 0.0:
		next_stage_timer = NEXT_STAGE_DELAY
	next_stage_timer = max(0.0, next_stage_timer - delta)
	if next_stage_timer <= 0.0:
		regenerate_asteroid_field()

func spawn_sun() -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null or container.get_node_or_null("Sun") != null:
		return
	var sun = asteroid_scene.instantiate()
	sun.name = "Sun"
	sun.max_resource_amount = 0
	sun.resource_amount = 0
	sun.position = Vector2.ZERO
	sun.add_to_group("sun")
	container.add_child(sun)

func _random_spawn_position() -> Vector2:
	return Vector2(rng.randf_range(-SPAWN_HALF_WIDTH, SPAWN_HALF_WIDTH), rng.randf_range(-SPAWN_HALF_HEIGHT, SPAWN_HALF_HEIGHT))

func _is_spawn_position_valid(candidate: Vector2, existing: Array, min_distance: float, min_distance_from_sun: float) -> bool:
	if candidate.length() < min_distance_from_sun:
		return false
	for other in existing:
		if candidate.distance_to(other) < min_distance:
			return false
	return true

func _find_spawn_position(existing: Array, min_distance: float, min_distance_from_sun: float = 0.0) -> Vector2:
	for attempt in range(100):
		var candidate = _random_spawn_position()
		if _is_spawn_position_valid(candidate, existing, min_distance, min_distance_from_sun):
			return candidate
	for attempt in range(100):
		var angle = rng.randf_range(0.0, TAU)
		var radius = rng.randf_range(min_distance_from_sun, min_distance_from_sun + SPAWN_FALLBACK_EXTRA_RADIUS)
		var candidate = Vector2(cos(angle), sin(angle)) * radius
		if _is_spawn_position_valid(candidate, existing, min_distance, min_distance_from_sun):
			return candidate
	var fallback_angle = rng.randf_range(0.0, TAU)
	return Vector2(cos(fallback_angle), sin(fallback_angle)) * max(min_distance_from_sun, min_distance)

func _get_spawn_blockers(container: Node) -> Array:
	var blockers = []
	for node in container.get_children():
		if node.is_in_group("sun") or node.is_in_group("asteroids"):
			blockers.append(node.position)
	return blockers

func spawn_resource_field() -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	for node in container.get_children():
		if node.is_in_group("asteroids") and not node.is_in_group("sun"):
			return
	spawn_sun()
	spawn_planets()
	spawn_asteroids()

func spawn_asteroids(count: int = -1) -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	if count < 0:
		count = rng.randi_range(ASTEROID_MIN_COUNT, ASTEROID_MAX_COUNT)
	var blockers = _get_spawn_blockers(container)
	for i in range(count):
		var a = asteroid_scene.instantiate()
		container.add_child(a)
		var spawn_position = _find_spawn_position(blockers, ASTEROID_SEPARATION, ASTEROID_MIN_DISTANCE_FROM_SUN)
		a.position = spawn_position
		a.max_resource_amount = 0
		a.resource_amount = a.max_resource_amount
		a.add_to_group("asteroids")
		blockers.append(spawn_position)
	_distribute_field_resources(container)

func _distribute_field_resources(container: Node) -> void:
	var resource_nodes: Array[Node] = []
	for node in container.get_children():
		if node.is_in_group("asteroids") and not node.is_in_group("sun"):
			resource_nodes.append(node)
	if resource_nodes.is_empty():
		return
	var resources_per_node = int(floor(float(FIELD_RESOURCE_CAP) / float(resource_nodes.size())))
	var remainder = FIELD_RESOURCE_CAP % resource_nodes.size()
	for index in range(resource_nodes.size()):
		var node_resources = resources_per_node + (1 if index < remainder else 0)
		resource_nodes[index].max_resource_amount = node_resources
		resource_nodes[index].resource_amount = node_resources

func spawn_planets(count: int = -1) -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	var existing_planets = 0
	for node in container.get_children():
		if node.is_in_group("planet"):
			existing_planets += 1
	if existing_planets >= PLANET_MAX_COUNT:
		return
	if count < 0:
		count = rng.randi_range(PLANET_MIN_COUNT, PLANET_MAX_COUNT - existing_planets)
	count = min(count, PLANET_MAX_COUNT - existing_planets)
	var blockers = []
	for node in container.get_children():
		if node.is_in_group("asteroids"):
			blockers.append(node.position)
	for i in range(count):
		var planet = asteroid_scene.instantiate()
		planet.name = "Planet"
		container.add_child(planet)
		var planet_position = _find_spawn_position(blockers, PLANET_SEPARATION, PLANET_MIN_DISTANCE_FROM_SUN)
		planet.position = planet_position
		planet.max_resource_amount = 0
		planet.resource_amount = planet.max_resource_amount
		planet.add_to_group("asteroids")
		planet.add_to_group("planet")
		blockers.append(planet_position)

func spawn_planet() -> void:
	spawn_planets(1)

func get_drone_cap() -> int:
	var command_levels = drone_level + get_refinery_upgrade_level("command_capacity")
	command_levels += get_ship_upgrade_level("hammond", "command_capacity")
	command_levels += get_ship_upgrade_level("drone_carrier", "command_capacity")
	var base_capacity = float(BASE_DRONE_CAP + command_levels * DRONE_CAPACITY_PER_LEVEL)
	return max(0, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_COMMAND_CAPACITY, base_capacity))))

func get_active_drone_count() -> int:
	var parent = get_parent()
	if parent == null or not parent.has_node("Drones"):
		return 0
	return parent.get_node("Drones").get_child_count()

func get_drone_purchase_cost() -> int:
	if get_active_drone_count() < drone_level:
		return get_ore_upgrade_cost("drones", 0)
	return get_ore_upgrade_cost("drones", drone_level)

func get_click_output() -> int:
	var base_output = float(BASE_CLICK_OUTPUT + click_output_level * CLICK_OUTPUT_PER_LEVEL)
	return max(0, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_MINING_CLICK_OUTPUT, base_output))))

func get_battle_click_damage() -> int:
	var damage = get_click_output()
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_flagship_battle_click_bonus"):
		damage += int(game_state.get_flagship_battle_click_bonus())
	if game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("hammond"):
		damage += get_ship_upgrade_level("hammond", "torpedo")
	return max(0, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_BATTLE_CLICK_DAMAGE, float(damage)))))

func get_drone_battle_damage() -> int:
	return max(0, int(round(resolve_ship_stat(&"mining_drone", ShipProfile.STAT_BATTLE_DAMAGE, float(get_mining_amount())))))

func get_drone_max_hp() -> int:
	var base_hp = 10.0
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_drone_max_hp"):
		base_hp = float(game_state.get_drone_max_hp())
	return max(1, int(round(resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MAX_HP, base_hp))))

func get_click_multiplier() -> float:
	return 1.0

func get_global_ore_multiplier() -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("refinery"):
		return 1.0 + float(get_refinery_stat_value("global_income_bonus"))
	return 1.0

func get_refinery_upgrade_level(stat_key: String) -> int:
	return int(refinery_upgrade_levels.get(stat_key, 0))

func get_refinery_upgrade_cap(stat_key: String) -> int:
	return get_ore_upgrade_cap("refinery_%s" % stat_key)

func get_refinery_upgrade_cost(stat_key: String, level: int = -1) -> int:
	if not REFINERY_ORE_BASE_COSTS.has(stat_key):
		return 0
	if level < 0:
		level = get_refinery_upgrade_level(stat_key)
	return int(ceil(float(REFINERY_ORE_BASE_COSTS[stat_key]) * pow(ORE_COST_MULTIPLIER, float(level))))

func get_refinery_stat_value(stat_key: String):
	var ore_level = get_refinery_upgrade_level(stat_key)
	var base_value = 0.0
	var modifier_stat = StringName(stat_key)
	match stat_key:
		"command_capacity":
			base_value = float(ore_level)
			modifier_stat = ShipProfile.STAT_COMMAND_CAPACITY
		"click_rate":
			base_value = float(BASE_CLICK_RATE_CAP + ore_level)
			modifier_stat = ShipProfile.STAT_CLICK_RATE
		"click_multiplier":
			base_value = 1.0 + float(ore_level) * 0.025
			modifier_stat = ShipProfile.STAT_CLICK_MULTIPLIER
		"hull":
			base_value = 100.0
			modifier_stat = ShipProfile.STAT_MAX_HP
		"armor":
			modifier_stat = ShipProfile.STAT_ARMOR
		"shield":
			modifier_stat = ShipProfile.STAT_SHIELD
		"global_income_bonus":
			base_value = 0.012 * float(ore_level + 1)
			modifier_stat = ShipProfile.STAT_GLOBAL_INCOME_BONUS
	return resolve_ship_stat(&"refinery", modifier_stat, base_value)

func get_refinery_click_multiplier() -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("refinery"):
		return float(get_refinery_stat_value("click_multiplier"))
	return 1.0

func upgrade_refinery_stat(stat_key: String) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("is_ship_unlocked") or not game_state.is_ship_unlocked("refinery"):
		return false
	if not refinery_upgrade_levels.has(stat_key):
		return false
	var level = get_refinery_upgrade_level(stat_key)
	if level >= get_refinery_upgrade_cap(stat_key):
		return false
	var cost = get_refinery_upgrade_cost(stat_key, level)
	if total_resources < cost:
		return false
	total_resources -= cost
	refinery_upgrade_levels[stat_key] = level + 1
	if stat_key == "command_capacity":
		spawn_drones(1)
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			configure_drone(drone)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func get_click_rate_cap() -> float:
	var click_levels = click_multiplier_level + get_refinery_upgrade_level("click_rate")
	click_levels += get_ship_upgrade_level("hammond", "click_rate")
	click_levels += get_ship_upgrade_level("drone_carrier", "click_rate")
	var base_rate = float(BASE_CLICK_RATE_CAP + click_levels * CLICK_RATE_CAP_PER_LEVEL)
	return max(1.0, resolve_ship_stat(&"flagship", ShipProfile.STAT_CLICK_RATE, base_rate))

func _try_consume_click() -> bool:
	var now = float(Time.get_ticks_usec()) / 1000000.0
	var minimum_interval = 1.0 / max(1.0, get_click_rate_cap())
	if last_click_time >= 0.0 and now - last_click_time < minimum_interval:
		return false
	last_click_time = now
	return true

func get_speed() -> float:
	var speed = BASE_SPEED + speed_level * DRONE_SPEED_PER_LEVEL
	speed += float(get_ship_upgrade_level("drone_carrier", "drone_coordination")) * CARRIER_COORDINATION_SPEED
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_passive_level"):
		if int(game_state.get_passive_level("drone_ion_thrusts")) > 0:
			speed *= 3.0
	return max(0.0, resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MOVE_SPEED, speed))

func get_ship_upgrade_level(ship_key: String, stat_key: String) -> int:
	if not ship_upgrade_levels.has(ship_key):
		return 0
	return int(ship_upgrade_levels[ship_key].get(stat_key, 0))

func get_ship_upgrade_cap(ship_key: String, stat_key: String) -> int:
	return get_ore_upgrade_cap("%s_%s" % [ship_key, stat_key])

func get_ship_upgrade_cost(ship_key: String, stat_key: String, level: int = -1) -> int:
	if not ship_upgrade_levels.has(ship_key) or not SHIP_ORE_BASE_COSTS.has(stat_key):
		return 0
	if level < 0:
		level = get_ship_upgrade_level(ship_key, stat_key)
	return int(ceil(float(SHIP_ORE_BASE_COSTS[stat_key]) * pow(ORE_COST_MULTIPLIER, float(level))))

func upgrade_ship_stat(ship_key: String, stat_key: String) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked(ship_key) or not ship_upgrade_levels.has(ship_key):
		return false
	if not ship_upgrade_levels[ship_key].has(stat_key):
		return false
	var level = get_ship_upgrade_level(ship_key, stat_key)
	if level >= get_ship_upgrade_cap(ship_key, stat_key):
		return false
	var cost = get_ship_upgrade_cost(ship_key, stat_key, level)
	if total_resources < cost:
		return false
	total_resources -= cost
	ship_upgrade_levels[ship_key][stat_key] = level + 1
	if stat_key == "command_capacity":
		spawn_drones(1)
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			configure_drone(drone)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func get_hammond_damage() -> float:
	return HAMMOND_BASE_DAMAGE + float(get_ship_upgrade_level("hammond", "autocannon")) * HAMMOND_AUTOCANNON_DAMAGE

func get_hammond_interval() -> float:
	return max(HAMMOND_MIN_INTERVAL, HAMMOND_BASE_INTERVAL - float(get_ship_upgrade_level("hammond", "ammo_conveyor")) * HAMMOND_CONVEYOR_REDUCTION)

func get_fighter_drone_count() -> int:
	return get_ship_upgrade_level("drone_carrier", "fighter_drones")

func get_fighter_drone_speed() -> float:
	return 1.4 + float(get_ship_upgrade_level("drone_carrier", "drone_coordination")) * 0.05

func get_flagship_speed() -> float:
	var speed = BASE_FLAGSHIP_SPEED + flagship_speed_level * FLAGSHIP_SPEED_PER_LEVEL
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_flagship_speed_multiplier"):
		speed *= float(game_state.get_flagship_speed_multiplier())
	return max(0.0, resolve_ship_stat(&"flagship", ShipProfile.STAT_MOVE_SPEED, speed))

func configure_flagship() -> void:
	if flotilla and is_instance_valid(flotilla):
		flotilla.move_speed = get_flagship_speed()

func upgrade_flagship_speed() -> bool:
	if flagship_speed_level >= get_ore_upgrade_cap("flagship_speed"):
		return false
	var cost = get_ore_upgrade_cost("flagship_speed", flagship_speed_level)
	if total_resources < cost:
		return false
	total_resources -= cost
	flotilla.storage = total_resources if flotilla else total_resources
	flagship_speed_level += 1
	configure_flagship()
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func get_mining_amount() -> int:
	var amount = BASE_MINING_AMOUNT + mining_level * MINING_AMOUNT_PER_LEVEL
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_passive_level"):
		if int(game_state.get_passive_level("drone_mining_lasers")) > 0:
			amount *= 2
	return max(0, int(round(resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MINING_AMOUNT, float(amount)))))

func get_mining_speed() -> float:
	var base_speed = BASE_MINING_SPEED + mining_speed_level * MINING_SPEED_PER_LEVEL
	return max(0.1, resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MINING_SPEED, base_speed))

func get_mining_interval() -> float:
	return 1.0 / max(0.1, get_mining_speed())

func get_drone_multiplier() -> float:
	var base_multiplier = 1.0 + drone_multiplier_level * DRONE_MULTIPLIER_PER_LEVEL
	return max(0.0, resolve_ship_stat(&"mining_drone", ShipProfile.STAT_ORE_MULTIPLIER, base_multiplier))

func get_capacity() -> int:
	var base_capacity = float(BASE_CAPACITY + capacity_level * CARRY_CAPACITY_PER_LEVEL)
	return max(0, int(round(resolve_ship_stat(&"mining_drone", ShipProfile.STAT_CARRY_CAPACITY, base_capacity))))

func configure_drone(drone: Node) -> void:
	if drone == null:
		return
	drone.speed = get_speed()
	drone.mining_amount = get_mining_amount()
	drone.mine_interval = get_mining_interval()
	drone.mining_reward_multiplier = get_drone_multiplier() * get_global_ore_multiplier()
	drone.carry_capacity = get_capacity()

func regenerate_asteroid_field(count: int = -1) -> void:
	var parent = get_parent()
	if not parent.has_node("Asteroids"):
		return
	var container = parent.get_node("Asteroids")
	next_stage_timer = -1.0
	asteroid_field_level += 1
	for asteroid in container.get_children():
		asteroid.free()
	asteroid_priority.clear()
	spawn_sun()
	spawn_planets()
	spawn_asteroids(count)

func spawn_drones(count: int) -> void:
	var container = null
	if get_parent().has_node("Drones"):
		container = get_parent().get_node("Drones")
	if container == null:
		return
	for i in range(count):
		var d = drone_scene.instantiate()
		container.add_child(d)
		d.position = Vector2(rng.randf_range(-60.0, 60.0), rng.randf_range(-40.0, 40.0))
		d.add_to_group("drones")
		configure_drone(d)

func get_ore_upgrade_cost(upgrade: String, level: int = -1) -> int:
	if level < 0:
		level = drone_level if upgrade == "drones" else int(get("%s_level" % upgrade))
	return _upgrade_cost(upgrade, level)

func _upgrade_cost(upgrade: String, level: int) -> int:
	var base_cost = int(ORE_UPGRADE_BASE_COSTS.get(upgrade, 50))
	return int(ceil(float(base_cost) * pow(ORE_COST_MULTIPLIER, float(level))))

func _buy_upgrade(upgrade: String) -> bool:
	var level = int(get(upgrade + "_level"))
	if level >= get_ore_upgrade_cap(upgrade):
		return false
	var cost = get_ore_upgrade_cost(upgrade, level)
	if total_resources < cost:
		return false
	total_resources -= cost
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	set(upgrade + "_level", level + 1)
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			configure_drone(drone)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func upgrade_speed() -> bool:
	return _buy_upgrade("speed")

func upgrade_click_output() -> bool:
	return _buy_upgrade("click_output")

func upgrade_click_multiplier() -> bool:
	return _buy_upgrade("click_multiplier")

func upgrade_mining() -> bool:
	return _buy_upgrade("mining")

func upgrade_mining_speed() -> bool:
	return _buy_upgrade("mining_speed")

func upgrade_drone_multiplier() -> bool:
	return _buy_upgrade("drone_multiplier")

func upgrade_capacity() -> bool:
	return _buy_upgrade("capacity")

func buy_drone() -> bool:
	var active_drone_count = get_active_drone_count()
	if active_drone_count < drone_level:
		var replacement_cost = get_ore_upgrade_cost("drones", 0)
		if total_resources < replacement_cost:
			return false
		total_resources -= replacement_cost
		if flotilla and is_instance_valid(flotilla):
			flotilla.storage = total_resources
		spawn_drones(1)
		emit_signal("resource_changed", total_resources)
		emit_signal("upgrades_changed")
		return true
	if drone_level >= get_ore_upgrade_cap("drones"):
		return false
	var cost = get_ore_upgrade_cost("drones", drone_level)
	if total_resources < cost:
		return false
	total_resources -= cost
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	drone_level += 1
	spawn_drones(1)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func _on_flotilla_deposited(amount):
	total_resources = float(amount)
	emit_signal("resource_changed", total_resources)

func add_resources(amount: float) -> void:
	if amount <= 0.0:
		return
	total_resources += amount
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	emit_signal("resource_changed", total_resources)

func click_mine(asteroid: Node) -> float:
	if asteroid == null or not is_instance_valid(asteroid):
		return 0
	if int(asteroid.resource_amount) <= 0:
		return 0
	if not _try_consume_click():
		return 0
	var harvested = asteroid.mine(get_click_output())
	if harvested <= 0:
		return 0
	var gained = float(harvested) * get_refinery_click_multiplier() * get_global_ore_multiplier()
	total_resources += gained
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	emit_signal("resource_changed", total_resources)
	return gained

func set_asteroid_priority(ast: Node, delta: int) -> void:
	if ast == null:
		return
	var key = str(ast.get_instance_id())
	var cur = 0
	if asteroid_priority.has(key):
		cur = int(asteroid_priority[key])
	cur += delta
	asteroid_priority[key] = cur

func get_asteroid_priority(ast: Node) -> int:
	if ast == null:
		return 0
	var key = str(ast.get_instance_id())
	return int(asteroid_priority.get(key, 0))

func send_n_drones_to(target_asteroid: Node, n: int) -> void:
	if target_asteroid == null or not target_asteroid.is_in_group("asteroids"):
		return
	var parent = get_parent()
	if not parent.has_node("Drones"):
		return
	var drone_container = parent.get_node("Drones")
	var list = drone_container.get_children()
	_sort_target = target_asteroid
	list.sort_custom(Callable(self, "_drone_distance_cmp"))
	_sort_target = null
	var sent = 0
	for d in list:
		if sent >= n:
			break
		if d.has_method("assign_target"):
			d.assign_target(target_asteroid)
			sent += 1

func split_drones_across_asteroids() -> int:
	var parent = get_parent()
	if not parent.has_node("Asteroids") or not parent.has_node("Drones"):
		return 0
	var asteroids = parent.get_node("Asteroids").get_children()
	var drones = parent.get_node("Drones").get_children()
	asteroids = asteroids.filter(func(asteroid): return is_instance_valid(asteroid) and asteroid.is_in_group("asteroids"))
	if asteroids.is_empty():
		return 0
	var assigned = 0
	for index in range(drones.size()):
		var drone = drones[index]
		if drone.has_method("assign_target"):
			drone.assign_target(asteroids[index % asteroids.size()])
			assigned += 1
	return assigned

func _drone_distance_cmp(a, b):
	var target = _sort_target
	if target == null:
		return 0
	var da = a.position.distance_to(target.position)
	var db = b.position.distance_to(target.position)
	if da < db:
		return -1
	elif da > db:
		return 1
	return 0

func get_best_asteroid_for(pos: Vector2, distribute_targets: bool = false) -> Node:
	var parent = get_parent()
	if not parent.has_node("Asteroids"):
		return null
	var ast_container = parent.get_node("Asteroids")
	if distribute_targets:
		var closest_unassigned = _get_closest_asteroid_for_assignment(pos, ast_container, true)
		if closest_unassigned:
			return closest_unassigned
		return _get_closest_asteroid_for_assignment(pos, ast_container, false)
	var best = null
	var best_score = -1e9
	for a in ast_container.get_children():
		if not is_instance_valid(a):
			continue
		if not a.is_in_group("asteroids"):
			continue
		var pr = get_asteroid_priority(a)
		var score = pr * 1000 - int(pos.distance_to(a.position))
		if score > best_score:
			best_score = score
			best = a
	return best

func _get_closest_asteroid_for_assignment(pos: Vector2, ast_container: Node, require_unassigned: bool) -> Node:
	var best = null
	var best_distance = INF
	for asteroid in ast_container.get_children():
		if not is_instance_valid(asteroid):
			continue
		if not asteroid.is_in_group("asteroids"):
			continue
		if require_unassigned and _get_assigned_drone_count(asteroid) > 0:
			continue
		var distance = pos.distance_to(asteroid.position)
		if distance < best_distance:
			best_distance = distance
			best = asteroid
	return best

func _get_assigned_drone_count(asteroid: Node) -> int:
	var parent = get_parent()
	if parent == null or not parent.has_node("Drones"):
		return 0
	var assigned_count = 0
	for drone in parent.get_node("Drones").get_children():
		if drone.target_asteroid == asteroid and int(drone.state) in [1, 2]:
			assigned_count += 1
	return assigned_count

func save_game() -> void:
	var parent = get_parent()
	var ast_container = parent.get_node("Asteroids")
	var drone_container = parent.get_node("Drones")

	var state = {
		"flotilla": {"storage": flotilla.storage if flotilla else 0, "position": [flotilla.position.x, flotilla.position.y] if flotilla else [0,0]},
		"upgrades": {"click_output": click_output_level, "click_multiplier": click_multiplier_level, "speed": speed_level, "mining": mining_level, "mining_speed": mining_speed_level, "drone_multiplier": drone_multiplier_level, "capacity": capacity_level, "drones": drone_level, "flagship_speed": flagship_speed_level},
		"refinery_upgrades": refinery_upgrade_levels.duplicate(true),
		"ship_upgrades": ship_upgrade_levels.duplicate(true),
		"asteroid_field_level": asteroid_field_level,
		"research": {},
		"asteroids": [],
		"drones": []
	}
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_save_state"):
		state["research"] = game_state.get_save_state()

	var ast_list = []
	for a in ast_container.get_children():
		if a.is_in_group("sun"):
			continue
		ast_list.append(a)
		state["asteroids"].append({"pos": [a.position.x, a.position.y], "resource_amount": a.resource_amount, "max_resource_amount": a.max_resource_amount, "is_planet": a.is_in_group("planet")})

	var drones = drone_container.get_children()
	for d in drones:
		var target_index = -1
		if d.target_asteroid != null and is_instance_valid(d.target_asteroid):
			target_index = ast_list.find(d.target_asteroid)
		state["drones"].append({"pos": [d.position.x, d.position.y], "carry": d.carry, "state": int(d.state), "target_index": target_index})

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(state)
	file.close()
	print("Saved game to %s" % SAVE_PATH)

func command_send_drones_to(target_asteroid: Node) -> void:
	if target_asteroid == null or not target_asteroid.is_in_group("asteroids"):
		return
	var parent = get_parent()
	if not parent.has_node("Drones"):
		return
	var drone_container = parent.get_node("Drones")
	for d in drone_container.get_children():
		if d.has_method("assign_target"):
			d.assign_target(target_asteroid)

func load_game() -> void:
	var parent = get_parent()
	var ast_container = parent.get_node("Asteroids")
	var drone_container = parent.get_node("Drones")

	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found at %s" % SAVE_PATH)
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var state = file.get_var()
	file.close()
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("apply_save_state"):
		game_state.apply_save_state(state.get("research", {}))
	var saved_flotilla = state.get("flotilla", {})
	var saved_upgrades = state.get("upgrades", {})
	asteroid_field_level = int(state.get("asteroid_field_level", 0))
	click_output_level = int(saved_upgrades.get("click_output", 0))
	click_multiplier_level = int(saved_upgrades.get("click_multiplier", 0))
	flagship_speed_level = int(saved_upgrades.get("flagship_speed", 0))
	configure_flagship()
	speed_level = int(saved_upgrades.get("speed", 0))
	mining_level = int(saved_upgrades.get("mining", 0))
	mining_speed_level = int(saved_upgrades.get("mining_speed", 0))
	drone_multiplier_level = int(saved_upgrades.get("drone_multiplier", 0))
	capacity_level = int(saved_upgrades.get("capacity", 0))
	drone_level = int(saved_upgrades.get("drones", 0))
	var saved_refinery_upgrades: Dictionary = state.get("refinery_upgrades", {})
	for stat_key in refinery_upgrade_levels:
		refinery_upgrade_levels[stat_key] = max(0, int(saved_refinery_upgrades.get(stat_key, 0)))
	var saved_ship_upgrades: Dictionary = state.get("ship_upgrades", {})
	for ship_key in ship_upgrade_levels:
		var saved_levels: Dictionary = saved_ship_upgrades.get(ship_key, {})
		for stat_key in ship_upgrade_levels[ship_key]:
			ship_upgrade_levels[ship_key][stat_key] = max(0, int(saved_levels.get(stat_key, 0)))
	if flotilla and saved_flotilla.has("storage"):
		flotilla.storage = float(saved_flotilla["storage"])
		total_resources = flotilla.storage
		emit_signal("resource_changed", total_resources)
	if flotilla and saved_flotilla.has("position"):
		var saved_position = saved_flotilla["position"]
		flotilla.position = Vector2(float(saved_position[0]), float(saved_position[1]))

	for c in ast_container.get_children():
		c.free()
	for c in drone_container.get_children():
		c.free()

	var ast_nodes = []
	for adata in state.get("asteroids", []):
		var a = asteroid_scene.instantiate()
		ast_container.add_child(a)
		a.position = Vector2(adata["pos"][0], adata["pos"][1])
		a.resource_amount = int(adata.get("resource_amount", 0))
		a.max_resource_amount = int(adata.get("max_resource_amount", max(a.resource_amount, 1)))
		a.add_to_group("asteroids")
		if adata.get("is_planet", false):
			a.name = "Planet"
			a.add_to_group("planet")
		ast_nodes.append(a)
	spawn_sun()

	for ddata in state.get("drones", []):
		var d = drone_scene.instantiate()
		drone_container.add_child(d)
		d.position = Vector2(ddata["pos"][0], ddata["pos"][1])
		d.carry = float(ddata.get("carry", 0.0))
		d.state = int(ddata.get("state", 0))
		var tindex = int(ddata.get("target_index", -1))
		if tindex >= 0 and tindex < ast_nodes.size():
			d.target_asteroid = ast_nodes[tindex]
		d.add_to_group("drones")
		configure_drone(d)

	if flotilla and state.has("flotilla"):
		flotilla.storage = float(state["flotilla"].get("storage", 0.0))
		total_resources = flotilla.storage
		emit_signal("resource_changed", total_resources)

	print("Loaded game from %s" % SAVE_PATH)
