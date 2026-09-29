extends Node

const Catalog = preload("res://scripts/data/ship_catalog.gd")
const Overflow = preload("res://scripts/systems/upgrades/ship_upgrade_overflow.gd")
signal upgrade_notice(message: String)

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
var refining_level: int = 0
var capacity_level: int = 0
var drone_level: int = 0
var flagship_speed_level: int = 0
var refinery_upgrade_levels := {}
var ship_upgrade_levels := Catalog.get_default_upgrade_levels()
var companion_upgrade_levels := Catalog.get_default_companion_upgrade_levels()
var asteroid_field_level: int = 0
var next_stage_timer: float = -1.0
var last_click_time: float = -1.0
var last_hold_click_time: float = -1.0
var ambrossa_income_timer: float = 0.0
var ambrossa_rest_timer: float = 0.0
var ambrossa_cycles_completed: int = 0
var ship_income_timers := {}
var local_antenna_timer: float = 0.0
var romius_cycle_progress: float = 0.0
var development_protocol_timer: float = 0.0
var autobuy_upgrade_enabled := {}
var fleet_mining_target: Node = null
var manual_fleet_order_active: bool = false
var income_events: Array[Dictionary] = []
var ship_operation_positions := {}
var ship_operation_targets := {}
var ship_animation_time: float = 0.0
var movement_tick_elapsed: float = 0.0
var simulation_tick_elapsed: float = 0.0
var nelson_track_timer: float = 0.0
var nelson_practice_timer: float = 0.0
var nelson_practice_cycles: int = 0
var elysium_visit_timer: float = 0.0
var racer_states: Array[Dictionary] = []
var merlinda_race_course: Array[Vector2] = []
var merlinda_race_active: bool = false
var merlinda_race_cooldown: float = 3.0
var merlinda_course_marker_path: Array[Vector2] = []
var merlinda_course_marker_position := Vector2.ZERO
var merlinda_course_marker_index: int = 0
var merlinda_course_marker_finished: bool = true
var encore_ship_boost_timers := {}
var encore_active_timer: float = 0.0
var autor_timer: float = 0.0
var last_purchase_name: String = "None"
var last_purchase_cost: int = 0
var current_field_name: String = ""
var recent_field_names: Array[String] = []
var flagship_readiness_bonus_active: bool = false
var rng := RandomNumberGenerator.new()
var asteroid_priority := {} # maps Node -> int priority
var drone_assignment_cache_frame: int = -1
var drone_assignment_cache := {}

const SAVE_PATH := "user://save_game.save"
@export var autosave_enabled: bool = true
var save_path: String = SAVE_PATH
const PLANET_MIN_COUNT := 0
const PLANET_MAX_COUNT := 2
const ASTEROID_MIN_COUNT := 4
const ASTEROID_MAX_COUNT := 10
const FIELD_RESOURCE_CAP := 5000
const PLANET_SEPARATION := 5400.0
const ASTEROID_SEPARATION := 4200.0
const SPAWN_HALF_WIDTH := 33000.0
const SPAWN_HALF_HEIGHT := 33000.0
const SYSTEM_RING_RADII := [9000.0, 10500.0, 12000.0, 13500.0, 15000.0, 19400.0, 21700.0, 26200.0, 29200.0, 32200.0]
const SYSTEM_RING_HALF_WIDTH := 300.0
const FLEET_START_POSITION := Vector2(2950.0, 0.0)
const FIRST_FIELD_PLANET_POSITION := Vector2(8050.0, 0.0)
const INNER_PLANET_RINGS := [1, 2, 3, 4, 5]
const ASTEROID_RINGS := [6, 7]
const OUTER_PLANET_RINGS := [8, 9, 10]
const PLANET_RINGS := [1, 2, 3, 4, 5, 8, 9, 10]

const BASE_SPEED := 300.0
const BASE_MINING_AMOUNT := 1
const BASE_MINING_SPEED := 1.0
const BASE_CAPACITY := 10
const BASE_DRONE_CAP := 0
const BASE_CLICK_OUTPUT := 1
const BASE_CLICK_RATE_CAP := 10
const BASE_HOLD_CLICK_RATE := 2
const BASE_FLAGSHIP_SPEED := 200.0
const CLICK_OUTPUT_PER_LEVEL := 1
const CLICK_RATE_CAP_PER_LEVEL := 1
const FLAGSHIP_SPEED_PER_LEVEL := 10.0
const MINING_AMOUNT_PER_LEVEL := 1
const MINING_SPEED_PER_LEVEL := 0.1
const REFINING_BONUS_PER_LEVEL := 0.020
const DRONE_CAPACITY_PER_LEVEL := 1
const CARRY_CAPACITY_PER_LEVEL := 10
const ORE_COST_MULTIPLIER := 1.4
const DRONE_SPEED_PER_LEVEL := 10.0
const MAX_UPGRADE_LEVEL := 10
const NEXT_STAGE_DELAY := 10.0
const FLEET_MINING_RANGE := 5000.0
const FLEET_APPROACH_DISTANCE := 2000.0
const FLEET_FORMATION_SCALE := 50.0
const DEVELOPMENT_PROTOCOL_INTERVAL := 5.0
const INCOME_RATE_WINDOW := 10.0
const MOVEMENT_TICK_INTERVAL := 1.0 / 60.0
const SIMULATION_TICK_INTERVAL := 0.1
const SPECIAL_NODE_PRE_UNLOCK_CHANCE := 0.08
const SPECIAL_NODE_EXTRA_CHANCE := 0.08
const LOCAL_ANTENNA_INTERVAL := 300.0
const ORE_UPGRADE_BASE_COSTS := {
	"click_output": 50,
	"click_multiplier": 100,
	"drones": 300,
	"flagship_speed": 25,
	"mining": 100,
	"mining_speed": 150,
	"refining": 1750,
	"capacity": 75,
	"speed": 10
}
const HAMMOND_BASE_DAMAGE := 5.0
const HAMMOND_AUTOCANNON_DAMAGE := 0.25
const HAMMOND_BASE_INTERVAL := 10.0
const HAMMOND_CONVEYOR_REDUCTION := 0.002
const HAMMOND_MIN_INTERVAL := 1.0
const FIGHTER_DRONE_DAMAGE := 2
const CARRIER_COORDINATION_SPEED := 5.0
const GETHICA_SCANNER_RESOURCES := 500
const GETHICA_TRACKING_SPEED := 0.1
const GETHICA_FLEET_SPEED := 5.0
const AMBROSSA_BASE_INCOME := 1000.0
const AMBROSSA_WORKSHOP_INCOME := 100.0
const AMBROSSA_QUALITY_CHANCE := 0.02
const AMBROSSA_QUALITY_REWARD := 1000.0
const AMBROSSA_REPUTATION_REDUCTION := 0.01
const AMBROSSA_BASE_INTERVAL := 10.0
const AMBROSSA_BASE_REST := 5.0
const AMBROSSA_MIN_INTERVAL := 1.0
const STARBURST_BASE_CONTACT_DPS := 5.0
const MERLINDA_RACE_WAIT := 5.0
const MERLINDA_RACER_SPEED_SCALE := 8.0
const MERLINDA_RACER_MIN_SPEED := 200.0
const MERLINDA_RACER_MAX_SPEED := 300.0
const MERLINDA_COURSE_MARKER_SPEED := 1500.0
const MERLINDA_CHECKPOINT_REWARD := 50.0
const MERLINDA_BASE_RACE_REWARD := 1000.0
const MERLINDA_RACE_REWARD_PER_NODE := 200.0
const MERLINDA_NODE_OBSTACLE_RADIUS := 500.0
const MERLINDA_BASE_ARC_CLEARANCE := 650.0
const MERLINDA_BASE_COURSE_WIDTH := 160.0
const MERLINDA_CHECKPOINT_TOLERANCE := 35.0
const MERLINDA_WAYPOINT_CAPTURE_RATIO := 0.45
const MERLINDA_MAX_WAYPOINT_CAPTURE := 180.0
const MERLINDA_AWARENESS_WIDTH_GROWTH := 0.45
const MERLINDA_BYPASS_SAMPLE_SPACING := 220.0
const MERLINDA_MIN_BYPASS_SAMPLES := 5
const MERLINDA_MAX_BYPASS_SAMPLES := 18
const MERLINDA_BASE_TURN_SPEED := 3.5
const MERLINDA_SWIVEL_BONUS_PER_LEVEL := 0.10
const MERLINDA_PICKUP_CHANCE_PER_LEVEL := 0.02
const MERLINDA_PICKUP_SPEED_PER_LEVEL := 0.03
const MERLINDA_PICKUP_DURATION := 2.0
const MERLINDA_PITSTOP_SLOW_DURATION := 1.25
const MERLINDA_PITSTOP_BOOST_DURATION := 3.0
const MERLINDA_PITSTOP_SLOW_MULTIPLIER := 0.5
const MERLINDA_PITSTOP_BOOST_MULTIPLIER := 1.75
const MERLINDA_DERBY_MISHAP_CHANCE_PER_LEVEL := 0.03
const MERLINDA_DERBY_REWARD_PER_LEVEL := 100.0
const MERLINDA_ENCORE_PASS_RADIUS := 700.0
const MERLINDA_ENCORE_DURATION := 2.0
const MERLINDA_ENCORE_RACER_BONUS_PER_LEVEL := 0.02
const MERLINDA_ENCORE_UNIT_MULTIPLIER := 1.10
const MERLINDA_SPONSORSHIP_DISCOUNT_PER_LEVEL := 0.02
const MERLINDA_SPONSORSHIP_MIN_COST_MULTIPLIER := 0.40
const RACER_STALL_RECOVERY_TIME := 3.0
const NELSON_PRACTICE_INTERVAL := 60.0
const ROMIUS_CIVILIAN_DISCOUNT := 0.10
const ROMIUS_SUPPORT_INCOME_PER_LEVEL := 0.02
const ROMIUS_MILITARY_SPEED_PER_LEVEL := 0.01
const FIELD_NAME_PREFIXES := ["Aster", "Boreal", "Cinder", "Dawn", "Eidolon", "Farside", "Glimmer", "Helix", "Ion", "Jovian"]
const FIELD_NAME_SUFFIXES := ["Reach", "Drift", "Expanse", "Crossing", "Hollow", "Veil", "Frontier", "Basin", "March", "Strand"]
const DRONE_LAUNCH_DISTANCE := 34.0
const DRONE_LAUNCH_SPREAD := 10.0
const DRONE_SUN_CLEARANCE := 80.0
const MIN_LAUNCH_DIRECTION_LENGTH := 0.001
func _ready():
	if asteroid_scene == null:
		asteroid_scene = load("res://scenes/entities/Asteroid.tscn")
	if drone_scene == null:
		drone_scene = load("res://scenes/entities/Drone.tscn")
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_signal("ship_modifiers_changed"):
		game_state.ship_modifiers_changed.connect(Callable(self, "_on_ship_modifiers_changed"))
	refinery_upgrade_levels = ship_upgrade_levels.get("refinery", {})
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
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_ship_unlocked("merlinda"):
		_sync_merlinda_racers()
	return {
		"total_resources": total_resources,
		"upgrades": {
			"click_output": click_output_level,
			"click_multiplier": click_multiplier_level,
			"speed": speed_level,
			"mining": mining_level,
			"mining_speed": mining_speed_level,
			"refining": refining_level,
			"capacity": capacity_level,
			"drones": drone_level,
			"flagship_speed": flagship_speed_level
		},
		"refinery_upgrades": refinery_upgrade_levels.duplicate(true),
		"ship_upgrades": ship_upgrade_levels.duplicate(true),
		"companion_upgrades": companion_upgrade_levels.duplicate(true),
		"autobuy_upgrade_enabled": autobuy_upgrade_enabled.duplicate(true),
		"racer_speed_stats": _get_racer_speed_stats(),
		"asteroid_field_level": asteroid_field_level,
		"current_field_name": current_field_name,
		"recent_field_names": recent_field_names.duplicate(),
		"flagship_readiness_bonus_active": flagship_readiness_bonus_active,
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
	refining_level = int(upgrades.get("refining", upgrades.get("drone_multiplier", refining_level)))
	capacity_level = int(upgrades.get("capacity", capacity_level))
	drone_level = int(upgrades.get("drones", drone_level))
	flagship_speed_level = int(upgrades.get("flagship_speed", flagship_speed_level))
	var saved_refinery_upgrades: Dictionary = state.get("refinery_upgrades", {})
	for stat_key in refinery_upgrade_levels:
		refinery_upgrade_levels[stat_key] = max(0, int(saved_refinery_upgrades.get(stat_key, refinery_upgrade_levels[stat_key])))
	var saved_ship_upgrades: Dictionary = state.get("ship_upgrades", {}).duplicate(true)
	var saved_companion_upgrades: Dictionary = state.get("companion_upgrades", {}).duplicate(true)
	autobuy_upgrade_enabled = state.get("autobuy_upgrade_enabled", autobuy_upgrade_enabled).duplicate(true)
	var saved_merlinda: Dictionary = saved_ship_upgrades.get("merlinda", {}).duplicate(true)
	var saved_racer: Dictionary = saved_companion_upgrades.get("racer", {}).duplicate(true)
	if not saved_merlinda.has("awareness") and saved_racer.has("awareness"):
		saved_merlinda["awareness"] = saved_racer["awareness"]
	if not saved_merlinda.has("pick_me_ups") and saved_merlinda.has("tuning"):
		saved_merlinda["pick_me_ups"] = saved_merlinda["tuning"]
	if not saved_racer.has("encore") and saved_merlinda.has("encore"):
		saved_racer["encore"] = saved_merlinda["encore"]
	saved_ship_upgrades["merlinda"] = saved_merlinda
	saved_companion_upgrades["racer"] = saved_racer
	for ship_key in ship_upgrade_levels:
		var saved_levels: Dictionary = saved_ship_upgrades.get(ship_key, {})
		saved_levels = _migrate_mining_ship_upgrades(ship_key, saved_levels)
		for stat_key in ship_upgrade_levels[ship_key]:
			ship_upgrade_levels[ship_key][stat_key] = max(0, int(saved_levels.get(stat_key, ship_upgrade_levels[ship_key][stat_key])))
	for companion_id in companion_upgrade_levels:
		var saved_levels: Dictionary = saved_companion_upgrades.get(companion_id, {})
		for stat_key in companion_upgrade_levels[companion_id]:
			companion_upgrade_levels[companion_id][stat_key] = max(0, int(saved_levels.get(stat_key, companion_upgrade_levels[companion_id][stat_key])))
	racer_states.clear()
	var home = get_ship_world_position("merlinda")
	for saved_speed in Array(state.get("racer_speed_stats", [])):
		racer_states.append({
			"position": home,
			"checkpoint": 0,
			"curve_step": 0,
			"finished": true,
			"direction": Vector2.RIGHT,
			"base_speed": clamp(float(saved_speed), MERLINDA_RACER_MIN_SPEED, MERLINDA_RACER_MAX_SPEED),
			"pickup_timer": 0.0, "pickup_multiplier": 1.0,
			"pitstop_phase": "", "pitstop_timer": 0.0,
			"slow_timer": 0.0, "stop_timer": 0.0, "disabled_timer": 0.0,
			"encore_timer": 0.0, "encore_contacts": {}
		})
	asteroid_field_level = int(state.get("asteroid_field_level", asteroid_field_level))
	current_field_name = str(state.get("current_field_name", current_field_name))
	recent_field_names.assign(state.get("recent_field_names", recent_field_names))
	flagship_readiness_bonus_active = bool(state.get("flagship_readiness_bonus_active", flagship_readiness_bonus_active))
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
		active_drones = max(active_drones, get_readiness_drone_minimum())
		spawn_owned_drones(active_drones)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")

func can_enter_battle() -> bool:
	return asteroid_field_level + 1 >= 10

func advance_field_after_battle() -> void:
	regenerate_asteroid_field()

func reset_run_for_prestige(surviving_drones: int = 0, update_game_state: bool = true, force_prestige: bool = false) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	var readiness_was_active = game_state and game_state.has_method("is_flagship_readiness_unlocked") and game_state.is_flagship_readiness_unlocked()
	var starting_command_level = 0
	if game_state and game_state.has_method("get_flagship_starting_command_level"):
		starting_command_level = int(game_state.get_flagship_starting_command_level())
	if update_game_state and game_state and game_state.has_method("reset_for_prestige"):
		if not bool(game_state.reset_for_prestige(force_prestige)):
			return false
	flagship_readiness_bonus_active = readiness_was_active
	total_resources = 0
	click_output_level = 0
	click_multiplier_level = 0
	speed_level = 0
	mining_level = 0
	mining_speed_level = 0
	refining_level = 0
	capacity_level = 0
	drone_level = max(max(0, surviving_drones), starting_command_level)
	flagship_speed_level = 0
	for stat_key in refinery_upgrade_levels:
		refinery_upgrade_levels[stat_key] = 0
	for ship_key in ship_upgrade_levels:
		for stat_key in ship_upgrade_levels[ship_key]:
			ship_upgrade_levels[ship_key][stat_key] = 0
	for companion_id in companion_upgrade_levels:
		for stat_key in companion_upgrade_levels[companion_id]:
			companion_upgrade_levels[companion_id][stat_key] = 0
	asteroid_field_level = 0
	next_stage_timer = -1.0
	ambrossa_income_timer = 0.0
	ambrossa_rest_timer = 0.0
	ambrossa_cycles_completed = 0
	ship_income_timers.clear()
	ship_operation_positions.clear()
	ship_operation_targets.clear()
	ship_animation_time = 0.0
	nelson_track_timer = 0.0
	nelson_practice_timer = 0.0
	nelson_practice_cycles = 0
	elysium_visit_timer = 0.0
	_reset_merlinda_race()
	encore_ship_boost_timers.clear()
	encore_active_timer = 0.0
	autor_timer = 0.0
	last_purchase_name = "None"
	last_purchase_cost = 0
	local_antenna_timer = 0.0
	romius_cycle_progress = 0.0
	development_protocol_timer = 0.0
	fleet_mining_target = null
	manual_fleet_order_active = false
	income_events.clear()
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = 0
		flotilla.position = FLEET_START_POSITION
		flotilla.move_target = FLEET_START_POSITION
		if flotilla.has_method("reset_visual_interpolation"):
			flotilla.reset_visual_interpolation()
	var parent = get_parent()
	if parent and parent.has_node("Asteroids"):
		for asteroid in parent.get_node("Asteroids").get_children():
			asteroid.free()
		asteroid_priority.clear()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			drone.free()
		spawn_owned_drones(get_owned_drone_count())
	spawn_resource_field()
	_autosave_new_field()
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
	var gethica_unlocked = game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("gethica")
	var ambrossa_unlocked = game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("ambrossa")
	var battle_stats = {
		"battle_type": "standard",
		"click_damage": get_battle_click_damage(),
		"click_rate_cap": get_click_rate_cap(),
		"hold_click_rate": get_hold_click_rate(),
		"autor_enabled": bool(game_state.is_autor_active()),
		"picket_damage": float(game_state.get_flagship_picket_damage()),
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
		"hammond_max_hp": get_hammond_max_hp(),
		"hammond_damage_reduction": get_hammond_damage_reduction(),
		"hammond_damage": get_hammond_damage(),
		"hammond_interval": get_hammond_interval(),
		"carrier_unlocked": carrier_unlocked,
		"gethica_unlocked": gethica_unlocked,
		"ambrossa_unlocked": ambrossa_unlocked,
		"fighter_drone_count": get_fighter_drone_count(),
		"fighter_drone_damage": get_fighter_drone_damage(),
		"fighter_drone_speed": get_fighter_drone_speed()
	}
	battle_stats.merge(get_extended_battle_stats(), true)
	game_state.prepare_battle(get_run_state(), battle_stats)
	get_tree().change_scene_to_file("res://scenes/combat/Battle.tscn")
	return true

func get_research_battle_requirement_status(research_key: String) -> Dictionary:
	var requirements = Catalog.get_research_requirements(research_key)
	var details: Array[String] = []
	var unmet: Array[String] = []
	var first_current = 0
	var first_required = 0
	for requirement in requirements:
		var owner = str(requirement.get("owner", ""))
		var stat_key = str(requirement.get("stat", ""))
		var required_level = max(0, int(requirement.get("level", 0)))
		var current_level = _get_research_requirement_level(owner, stat_key)
		var label = str(requirement.get("label", stat_key.capitalize()))
		var progress = "%s %d/%d" % [label, current_level, required_level]
		details.append(progress)
		if current_level < required_level:
			if unmet.is_empty():
				first_current = current_level
				first_required = required_level
			unmet.append(progress)
	return {
		"met": unmet.is_empty(),
		"summary": ", ".join(unmet if not unmet.is_empty() else details),
		"details": details,
		"current": first_current,
		"required": first_required
	}

func _get_research_requirement_level(owner: String, stat_key: String) -> int:
	if stat_key == "*":
		return _get_total_ore_upgrade_levels(owner)
	if owner == "flagship" or owner == "mining_drone":
		match stat_key:
			"click_output": return click_output_level
			"click_multiplier": return click_multiplier_level
			"drones": return drone_level
			"flagship_speed": return flagship_speed_level
			"refining": return refining_level
			"speed": return speed_level
			"mining": return mining_level
			"mining_speed": return mining_speed_level
			"capacity": return capacity_level
			_: return 0
	if companion_upgrade_levels.has(owner):
		return int(companion_upgrade_levels[owner].get(stat_key, 0))
	return int(ship_upgrade_levels.get(owner, {}).get(stat_key, 0))

func _get_total_ore_upgrade_levels(owner: String) -> int:
	if owner == "flagship":
		return click_output_level + click_multiplier_level + drone_level + flagship_speed_level + refining_level
	if owner == "mining_drone":
		return speed_level + mining_level + mining_speed_level + capacity_level
	var levels: Dictionary = companion_upgrade_levels.get(owner, {}) if companion_upgrade_levels.has(owner) else ship_upgrade_levels.get(owner, {})
	var total = 0
	for level in levels.values():
		total += max(0, int(level))
	return total

func can_start_research_hunt(research_key: String) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.can_battle_research_card(research_key):
		return false
	return bool(get_research_battle_requirement_status(research_key)["met"])

func start_research_hunt(research_key: String) -> bool:
	var parent = get_parent()
	var game_state = get_node_or_null("/root/GameState")
	if parent == null or game_state == null or not game_state.has_method("create_research_hunt"):
		return false
	if not can_start_research_hunt(research_key):
		return false
	var battle_stats: Dictionary = game_state.create_research_hunt(research_key)
	if battle_stats.is_empty():
		return false
	battle_stats.merge({
		"click_damage": get_battle_click_damage(),
		"click_rate_cap": get_click_rate_cap(),
		"hold_click_rate": get_hold_click_rate(),
		"autor_enabled": bool(game_state.is_autor_active()),
		"picket_damage": float(game_state.get_flagship_picket_damage()),
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
		"hammond_max_hp": get_hammond_max_hp(),
		"hammond_damage_reduction": get_hammond_damage_reduction(),
		"hammond_damage": get_hammond_damage(),
		"hammond_interval": get_hammond_interval(),
		"carrier_unlocked": game_state.is_ship_unlocked("drone_carrier"),
		"gethica_unlocked": game_state.is_ship_unlocked("gethica"),
		"ambrossa_unlocked": game_state.is_ship_unlocked("ambrossa"),
		"fighter_drone_count": get_fighter_drone_count(),
		"fighter_drone_damage": get_fighter_drone_damage(),
		"fighter_drone_speed": get_fighter_drone_speed()
	}, true)
	battle_stats.merge(get_extended_battle_stats(), true)
	game_state.prepare_battle(get_run_state(), battle_stats)
	get_tree().change_scene_to_file("res://scenes/combat/Battle.tscn")
	return true

func _process(delta: float) -> void:
	ship_animation_time += delta
	movement_tick_elapsed += delta
	if movement_tick_elapsed >= MOVEMENT_TICK_INTERVAL:
		var movement_steps = int(floor(movement_tick_elapsed / MOVEMENT_TICK_INTERVAL))
		var movement_delta = float(movement_steps) * MOVEMENT_TICK_INTERVAL
		movement_tick_elapsed -= movement_delta
		_process_encore_ship_boosts(movement_delta)
		_process_ship_operations(movement_delta)
		_process_merlinda_race(movement_delta)
	simulation_tick_elapsed += delta
	if simulation_tick_elapsed < SIMULATION_TICK_INTERVAL:
		return
	var simulation_delta = simulation_tick_elapsed
	simulation_tick_elapsed = 0.0
	_process_simulation_tick(simulation_delta)

func _process_simulation_tick(delta: float) -> void:
	_process_ambrossa_income(delta)
	_process_catalog_ship_income(delta)
	_process_catalog_research_income(delta)
	_process_local_antenna(delta)
	_process_autor(delta)
	_process_development_protocol(delta)
	_prune_income_events()
	_process_field_progression(delta)

func _process_field_progression(delta: float) -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	var resource_nodes = 0
	for node in container.get_children():
		if not node.is_in_group("sun") and can_mine_resource_node(node):
			resource_nodes += 1
	if resource_nodes > 0:
		next_stage_timer = -1.0
		return
	_recall_drones_to_flagship()
	if not _is_fleet_rallied_for_next_field():
		next_stage_timer = -1.0
		return
	if next_stage_timer < 0.0:
		next_stage_timer = _get_next_stage_delay()
	next_stage_timer = max(0.0, next_stage_timer - delta)
	if next_stage_timer <= 0.0:
		regenerate_asteroid_field()

func _get_next_stage_delay() -> float:
	var game_state = get_node_or_null("/root/GameState")
	return 5.0 if game_state and int(game_state.get_passive_level("parallax_armilla_designator")) > 0 else NEXT_STAGE_DELAY

func _recall_drones_to_flagship() -> void:
	var parent = get_parent()
	if parent == null or not parent.has_node("Drones"):
		return
	for drone in parent.get_node("Drones").get_children():
		if is_instance_valid(drone) and drone.has_method("recall_to_flagship"):
			drone.recall_to_flagship()

func _is_fleet_rallied_for_next_field() -> bool:
	if flotilla == null or not is_instance_valid(flotilla):
		return false
	var flagship_global_position: Vector2 = flotilla.global_position
	var transit_aura_radius = get_fleet_mining_range()
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			if is_instance_valid(drone) and drone is Node2D:
				if drone.global_position.distance_to(flagship_global_position) > transit_aura_radius:
					return false

	# Current companion ships use formation offsets. The group check also supports
	# future ships that become independently moving scene nodes.
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("is_ship_unlocked"):
		for ship_key in Catalog.get_ship_ids():
			if game_state.is_ship_unlocked(ship_key):
				if get_ship_world_position(ship_key).distance_to(flotilla.position) > transit_aura_radius:
					return false
	for ship in get_tree().get_nodes_in_group("fleet_ships"):
		if ship != flotilla and is_instance_valid(ship) and ship is Node2D:
			if ship.global_position.distance_to(flagship_global_position) > transit_aura_radius:
				return false
	return true

func _process_ambrossa_income(delta: float) -> void:
	var income = get_ambrossa_income_amount()
	if income <= 0.0:
		ambrossa_income_timer = 0.0
		ambrossa_rest_timer = 0.0
		ambrossa_cycles_completed = 0
		return
	if ambrossa_rest_timer > 0.0:
		ambrossa_rest_timer = max(0.0, ambrossa_rest_timer - delta)
		return
	ambrossa_income_timer += delta
	var interval = get_ambrossa_income_interval()
	while ambrossa_income_timer >= interval:
		ambrossa_income_timer -= interval
		add_resources(income, "ambrossa")
		var game_state = get_node_or_null("/root/GameState")
		var quality_level = get_effective_ship_upgrade_level("ambrossa", "quality_assurance")
		if rng.randf() < min(0.8, quality_level * AMBROSSA_QUALITY_CHANCE):
			add_resources(AMBROSSA_QUALITY_REWARD * get_ship_ore_multiplier("ambrossa"), "ambrossa_quality")
		ambrossa_cycles_completed += 1
		var cycles_before_rest = 2 if game_state and int(game_state.get_passive_level("ambrossa_efficient_planning")) > 0 else 1
		if ambrossa_cycles_completed >= cycles_before_rest:
			ambrossa_cycles_completed = 0
			var schedule_level = get_effective_ship_upgrade_level("ambrossa", "work_schedules")
			ambrossa_rest_timer = AMBROSSA_BASE_REST * max(0.2, 1.0 - schedule_level * 0.02)
			break

func _process_catalog_ship_income(delta: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	_process_mining_ship("minotard", delta, [""], 1)
	_process_mining_ship("tobias", delta, ["gas_planet", "gas_cloud"], 1)
	_process_mining_ship("fruegal", delta, ["", "gas_planet", "gas_cloud", "enriched"], 3)
	for ship_key in ["nelson", "stapledon", "tarrip", "elysium_air"]:
		if not game_state.is_ship_unlocked(ship_key):
			ship_income_timers[ship_key] = 0.0
			continue
		var interval = _get_catalog_income_interval(ship_key)
		ship_income_timers[ship_key] = float(ship_income_timers.get(ship_key, 0.0)) + delta
		while float(ship_income_timers[ship_key]) >= interval:
			ship_income_timers[ship_key] = float(ship_income_timers[ship_key]) - interval
			var income = _get_catalog_income_amount(ship_key)
			if income > 0.0:
				add_resources(income * get_ship_ore_multiplier(ship_key), ship_key)

func _process_merlinda_race(delta: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked("merlinda"):
		_reset_merlinda_race()
		return
	_sync_merlinda_racers()
	if racer_states.is_empty():
		merlinda_race_active = false
		return
	var home = get_ship_world_position("merlinda")
	if not merlinda_race_active:
		for racer_index in range(racer_states.size()):
			racer_states[racer_index]["position"] = _get_racer_dock_position(home, racer_index, racer_states.size())
		if not _has_remaining_merlinda_race_nodes():
			merlinda_race_course.clear()
			merlinda_race_cooldown = MERLINDA_RACE_WAIT
			return
		merlinda_race_cooldown = max(0.0, merlinda_race_cooldown - delta)
		if merlinda_race_cooldown <= 0.0:
			merlinda_race_course = _build_merlinda_race_course()
			if not merlinda_race_course.is_empty():
				_start_merlinda_race()
		return
	if merlinda_race_course.is_empty():
		merlinda_race_active = false
		return
	_process_merlinda_course_marker(delta)
	for racer_index in range(racer_states.size()):
		var racer: Dictionary = racer_states[racer_index]
		if bool(racer.get("finished", false)):
			continue
		var temporary_speed_multiplier = _process_racer_temporary_effects(racer, delta)
		if temporary_speed_multiplier <= 0.0:
			continue
		var checkpoint_index = int(racer.get("checkpoint", 0))
		var target = _get_racer_course_target(checkpoint_index, racer_index, home)
		var position: Vector2 = racer.get("position", home)
		var racer_speed = get_racer_drone_speed(float(racer.get("base_speed", 250.0)))
		var movement_speed = racer_speed * temporary_speed_multiplier
		if checkpoint_index >= merlinda_race_course.size():
			movement_speed = min(racer_speed, max(120.0, position.distance_to(target) * get_racer_turn_speed() * 0.55))
		var reached_marker = position.distance_to(target) <= MERLINDA_CHECKPOINT_TOLERANCE
		if not reached_marker:
			var distance_before = position.distance_to(target)
			var next_target = _get_racer_target_after_current(checkpoint_index, racer_index, home)
			var turn_speed = get_racer_turn_speed()
			var lookahead_distance = clamp(movement_speed / max(0.1, turn_speed) * 0.6, 160.0, 1200.0)
			var lookahead_blend = clamp(1.0 - position.distance_to(target) / lookahead_distance, 0.0, 0.65)
			var steering_target = target.lerp(next_target, lookahead_blend)
			var desired_direction = (steering_target - position).normalized()
			var direction: Vector2 = racer.get("direction", desired_direction)
			if direction.length_squared() <= 0.001:
				direction = desired_direction
			var angle_delta = wrapf(desired_direction.angle() - direction.angle(), -PI, PI)
			var turn_amount = clamp(angle_delta, -turn_speed * delta, turn_speed * delta)
			direction = direction.rotated(turn_amount).normalized()
			var previous_position = position
			var proposed_position = position + direction * movement_speed * delta
			var corrected_position = _keep_racer_outside_nodes(position, proposed_position)
			if not corrected_position.is_equal_approx(proposed_position) and not corrected_position.is_equal_approx(position):
				direction = (corrected_position - position).normalized()
			position = corrected_position
			racer["position"] = position
			racer["direction"] = direction
			_process_racer_encore(racer)
			reached_marker = _has_racer_reached_marker(previous_position, position, target, next_target, movement_speed, turn_speed, delta)
			var made_progress = position.distance_to(target) < distance_before - 0.5
			racer["stall_timer"] = 0.0 if made_progress else float(racer.get("stall_timer", 0.0)) + delta
			if not reached_marker and float(racer["stall_timer"]) >= RACER_STALL_RECOVERY_TIME:
				# Reacquire the waypoint directly after prolonged collision/turning deadlock.
				racer["direction"] = (target - position).normalized()
				reached_marker = position.distance_to(target) <= MERLINDA_MAX_WAYPOINT_CAPTURE * 2.0
				racer["stall_timer"] = 0.0
		if not reached_marker:
			continue
		if checkpoint_index < merlinda_race_course.size():
			var curve_step = int(racer.get("curve_step", 0))
			var node_waypoints = _get_merlinda_node_waypoints(checkpoint_index, _get_racer_lane_factor(racer_index), home)
			if curve_step < node_waypoints.size() - 1:
				racer["curve_step"] = curve_step + 1
				continue
			racer["curve_step"] = 0
			racer["checkpoint"] = checkpoint_index + 1
			racer["base_speed"] = _roll_racer_speed_stat()
			_apply_racer_pick_me_up(racer)
			_grant_merlinda_checkpoint_reward()
		else:
			racer["finished"] = true
			_grant_merlinda_racer_finish_reward(checkpoint_index)
	if merlinda_course_marker_finished:
		_grant_merlinda_race_completion_reward()
		merlinda_race_active = false
		merlinda_race_course.clear()
		merlinda_course_marker_path.clear()
		merlinda_race_cooldown = 0.0

func _sync_merlinda_racers() -> void:
	var desired_count = max(0, get_effective_ship_upgrade_level("merlinda", "participants"))
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("racer_taggers")) > 0:
		desired_count *= 2
	var home = get_ship_world_position("merlinda")
	while racer_states.size() < desired_count:
		var index = racer_states.size()
		racer_states.append({
			"position": _get_racer_dock_position(home, index, desired_count),
			"checkpoint": 0,
			"curve_step": 0,
			"finished": not merlinda_race_active,
			"direction": Vector2.RIGHT,
			"base_speed": _roll_racer_speed_stat(),
			"pickup_timer": 0.0, "pickup_multiplier": 1.0,
			"pitstop_phase": "", "pitstop_timer": 0.0,
			"slow_timer": 0.0, "stop_timer": 0.0, "disabled_timer": 0.0,
			"encore_timer": 0.0, "encore_contacts": {}, "stall_timer": 0.0
		})
	while racer_states.size() > desired_count:
		racer_states.pop_back()

func _start_merlinda_race() -> void:
	if racer_states.is_empty() or merlinda_race_course.is_empty():
		return
	var home = get_ship_world_position("merlinda")
	for racer_index in range(racer_states.size()):
		var racer: Dictionary = racer_states[racer_index]
		racer["checkpoint"] = 0
		racer["curve_step"] = 0
		racer["finished"] = false
		racer["base_speed"] = _roll_racer_speed_stat()
		racer["pickup_timer"] = 0.0
		racer["pickup_multiplier"] = 1.0
		racer["slow_timer"] = 0.0
		racer["stop_timer"] = 0.0
		racer["disabled_timer"] = 0.0
		racer["encore_timer"] = 0.0
		racer["encore_contacts"] = {}
		racer["stall_timer"] = 0.0
		racer["pitstop_phase"] = ""
		racer["pitstop_timer"] = 0.0
		var game_state = get_node_or_null("/root/GameState")
		if game_state and int(game_state.get_passive_level("merlinda_pitstop")) > 0 and rng.randf() < 0.5:
			racer["pitstop_phase"] = "slow"
			racer["pitstop_timer"] = MERLINDA_PITSTOP_SLOW_DURATION
		var target = _get_racer_course_target(0, racer_index, home)
		var position: Vector2 = racer.get("position", home)
		if not position.is_equal_approx(target):
			racer["direction"] = (target - position).normalized()
	merlinda_course_marker_path = _build_merlinda_center_path(home)
	merlinda_course_marker_position = home
	merlinda_course_marker_index = 1
	merlinda_course_marker_finished = merlinda_course_marker_path.size() < 2
	merlinda_race_active = true

func _reset_merlinda_race(preserve_racers: bool = false) -> void:
	if preserve_racers:
		for racer in racer_states:
			racer["checkpoint"] = 0
			racer["curve_step"] = 0
			racer["finished"] = true
			racer["pickup_timer"] = 0.0
			racer["pitstop_phase"] = ""
			racer["pitstop_timer"] = 0.0
			racer["slow_timer"] = 0.0
			racer["stop_timer"] = 0.0
			racer["disabled_timer"] = 0.0
			racer["encore_timer"] = 0.0
			racer["encore_contacts"] = {}
			racer["stall_timer"] = 0.0
	else:
		racer_states.clear()
	merlinda_race_course.clear()
	merlinda_course_marker_path.clear()
	merlinda_course_marker_position = Vector2.ZERO
	merlinda_course_marker_index = 0
	merlinda_course_marker_finished = true
	merlinda_race_active = false
	merlinda_race_cooldown = 3.0

func _get_racer_speed_stats() -> Array[float]:
	var speed_stats: Array[float] = []
	for racer in racer_states:
		speed_stats.append(float(racer.get("base_speed", 250.0)))
	return speed_stats

func _build_merlinda_race_course() -> Array[Vector2]:
	var course: Array[Vector2] = []
	var parent = get_parent()
	if parent == null or not parent.has_node("Asteroids"):
		return course
	for node in parent.get_node("Asteroids").get_children():
		if node is Node2D and node.is_in_group("asteroids") and not node.is_in_group("sun") and int(node.get("resource_amount")) > 0:
			course.append(node.position)
	if course.size() <= 1:
		return course
	var center = _get_sun_world_position()
	course.sort_custom(func(a: Vector2, b: Vector2): return (a - center).angle() < (b - center).angle())
	var home = get_ship_world_position("merlinda")
	var nearest_index = 0
	var nearest_distance = INF
	for index in range(course.size()):
		var distance = home.distance_squared_to(course[index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	var ordered: Array[Vector2] = []
	for offset in range(course.size()):
		ordered.append(course[(nearest_index + offset) % course.size()])
	return ordered

func get_merlinda_race_path() -> Array[Vector2]:
	var path: Array[Vector2] = []
	if not merlinda_race_active or merlinda_race_course.is_empty():
		return path
	var home = get_ship_world_position("merlinda")
	if merlinda_course_marker_path.is_empty():
		return _build_merlinda_center_path(home)
	path.append(merlinda_course_marker_position)
	for path_index in range(merlinda_course_marker_index, merlinda_course_marker_path.size()):
		path.append(merlinda_course_marker_path[path_index])
	return path

func _build_merlinda_center_path(home: Vector2) -> Array[Vector2]:
	var path: Array[Vector2] = [home]
	for checkpoint_index in range(merlinda_race_course.size()):
		path.append_array(_get_merlinda_node_waypoints(checkpoint_index, 0.5, home))
	path.append(home)
	return path

func _process_merlinda_course_marker(delta: float) -> void:
	if merlinda_course_marker_finished or merlinda_course_marker_path.size() < 2:
		merlinda_course_marker_finished = true
		return
	var remaining_distance = get_merlinda_course_marker_speed() * delta
	while remaining_distance > 0.0 and merlinda_course_marker_index < merlinda_course_marker_path.size():
		var target = merlinda_course_marker_path[merlinda_course_marker_index]
		var distance_to_target = merlinda_course_marker_position.distance_to(target)
		if distance_to_target <= remaining_distance:
			merlinda_course_marker_position = target
			merlinda_course_marker_index += 1
			remaining_distance -= distance_to_target
		else:
			merlinda_course_marker_position = merlinda_course_marker_position.move_toward(target, remaining_distance)
			remaining_distance = 0.0
	if merlinda_course_marker_index >= merlinda_course_marker_path.size():
		merlinda_course_marker_finished = true

func _has_remaining_merlinda_race_nodes() -> bool:
	var parent = get_parent()
	if parent == null or not parent.has_node("Asteroids"):
		return false
	for node in parent.get_node("Asteroids").get_children():
		if node is Node2D and node.is_in_group("asteroids") and not node.is_in_group("sun") and int(node.get("resource_amount")) > 0:
			return true
	return false

func _get_racer_course_target(checkpoint_index: int, racer_index: int, home: Vector2) -> Vector2:
	if checkpoint_index >= merlinda_race_course.size():
		return _get_racer_dock_position(home, racer_index, racer_states.size())
	var waypoints = _get_merlinda_node_waypoints(checkpoint_index, _get_racer_lane_factor(racer_index), home)
	var curve_step = clamp(int(racer_states[racer_index].get("curve_step", 0)), 0, waypoints.size() - 1)
	return waypoints[curve_step]

func _get_racer_target_after_current(checkpoint_index: int, racer_index: int, home: Vector2) -> Vector2:
	if checkpoint_index >= merlinda_race_course.size():
		return _get_racer_dock_position(home, racer_index, racer_states.size())
	var lane_factor = _get_racer_lane_factor(racer_index)
	var waypoints = _get_merlinda_node_waypoints(checkpoint_index, lane_factor, home)
	var curve_step = clamp(int(racer_states[racer_index].get("curve_step", 0)), 0, waypoints.size() - 1)
	if curve_step + 1 < waypoints.size():
		return waypoints[curve_step + 1]
	if checkpoint_index + 1 < merlinda_race_course.size():
		var next_waypoints = _get_merlinda_node_waypoints(checkpoint_index + 1, lane_factor, home)
		if not next_waypoints.is_empty():
			return next_waypoints[0]
	return _get_racer_dock_position(home, racer_index, racer_states.size())

func _has_racer_reached_marker(from_position: Vector2, position: Vector2, target: Vector2, next_target: Vector2, racer_speed: float, turn_speed: float, delta: float) -> bool:
	var frame_tolerance = max(MERLINDA_CHECKPOINT_TOLERANCE, racer_speed * delta * 1.25)
	var closest_to_target = Geometry2D.get_closest_point_to_segment(target, from_position, position)
	if position.distance_to(target) <= frame_tolerance or closest_to_target.distance_to(target) <= frame_tolerance:
		return true
	var distance_to_next = target.distance_to(next_target)
	if distance_to_next <= 0.001:
		var docking_capture = clamp(racer_speed / max(0.1, turn_speed) * 0.35, MERLINDA_CHECKPOINT_TOLERANCE, MERLINDA_MAX_WAYPOINT_CAPTURE)
		return position.distance_to(target) <= docking_capture
	var outgoing = (next_target - target) / distance_to_next
	var crossed_waypoint = (from_position - target).dot(outgoing) <= 0.0 and (position - target).dot(outgoing) >= 0.0
	if crossed_waypoint:
		return true
	var corner_capture = clamp(distance_to_next * MERLINDA_WAYPOINT_CAPTURE_RATIO, MERLINDA_CHECKPOINT_TOLERANCE, MERLINDA_MAX_WAYPOINT_CAPTURE)
	return position.distance_to(target) <= corner_capture

func _get_racer_lane_factor(racer_index: int) -> float:
	if racer_states.size() <= 1:
		return 0.5
	return float(racer_index) / float(racer_states.size() - 1)

func _get_merlinda_node_waypoints(checkpoint_index: int, lane_factor: float, home: Vector2) -> Array[Vector2]:
	var waypoints: Array[Vector2] = []
	if checkpoint_index < 0 or checkpoint_index >= merlinda_race_course.size():
		return waypoints
	var node_center = merlinda_race_course[checkpoint_index]
	var previous_point = home if checkpoint_index == 0 else merlinda_race_course[checkpoint_index - 1]
	var next_point = home if checkpoint_index == merlinda_race_course.size() - 1 else merlinda_race_course[checkpoint_index + 1]
	var incoming = (node_center - previous_point).normalized()
	var outgoing = (next_point - node_center).normalized()
	if incoming.length_squared() <= 0.001:
		incoming = Vector2.RIGHT
	if outgoing.length_squared() <= 0.001:
		outgoing = incoming
	var course_direction = (next_point - previous_point).normalized()
	if course_direction.length_squared() <= 0.001:
		course_direction = (incoming + outgoing).normalized()
	if course_direction.length_squared() <= 0.001:
		course_direction = incoming
	var outside = (node_center - _get_sun_world_position()).normalized()
	if outside.length_squared() <= 0.001:
		outside = course_direction.orthogonal()
	var outside_normal = course_direction.orthogonal().normalized()
	if outside_normal.dot(outside) < 0.0:
		outside_normal = -outside_normal
	var pass_normal = outside_normal if checkpoint_index % 2 == 0 else -outside_normal
	var clearance = MERLINDA_BASE_ARC_CLEARANCE + clamp(lane_factor, 0.0, 1.0) * get_racer_course_width()
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("racer_guidelines")) > 0:
		clearance *= 1.5
	var nearby_distance = min(node_center.distance_to(previous_point), node_center.distance_to(next_point))
	var bypass_length = clamp(min(clearance * 1.15, nearby_distance * 0.35), 280.0, clearance * 1.15)
	var entry = node_center - incoming * bypass_length + pass_normal * clearance
	var control = node_center + pass_normal * clearance
	var exit = node_center + outgoing * bypass_length + pass_normal * clearance
	var estimated_length = entry.distance_to(control) + control.distance_to(exit)
	var sample_count = clamp(int(ceil(estimated_length / MERLINDA_BYPASS_SAMPLE_SPACING)), MERLINDA_MIN_BYPASS_SAMPLES, MERLINDA_MAX_BYPASS_SAMPLES)
	for sample_index in range(sample_count + 1):
		var progress = float(sample_index) / float(sample_count)
		var inverse = 1.0 - progress
		var waypoint = inverse * inverse * entry + 2.0 * inverse * progress * control + progress * progress * exit
		var from_node = waypoint - node_center
		if from_node.length() < clearance:
			var safe_direction = from_node.normalized() if from_node.length_squared() > 0.001 else pass_normal
			waypoint = node_center + safe_direction * clearance
		waypoints.append(waypoint)
	return waypoints

func _keep_racer_outside_nodes(from_position: Vector2, proposed_position: Vector2) -> Vector2:
	var parent = get_parent()
	if parent == null or not parent.has_node("Asteroids"):
		return proposed_position
	var corrected_position = proposed_position
	for node in parent.get_node("Asteroids").get_children():
		if not node is Node2D or not node.is_in_group("asteroids") or node.is_in_group("sun"):
			continue
		var closest_point = Geometry2D.get_closest_point_to_segment(node.position, from_position, corrected_position)
		var from_node = closest_point - node.position
		if from_node.length() >= MERLINDA_NODE_OBSTACLE_RADIUS:
			continue
		if from_node.length_squared() <= 0.001:
			from_node = (corrected_position - from_position).orthogonal()
			if from_node.length_squared() <= 0.001:
				from_node = Vector2.RIGHT
		corrected_position = node.position + from_node.normalized() * MERLINDA_NODE_OBSTACLE_RADIUS
	return corrected_position

func _get_racer_dock_position(home: Vector2, racer_index: int, racer_count: int) -> Vector2:
	if racer_count <= 1:
		return home + Vector2(55.0, 0.0)
	var angle = TAU * float(racer_index) / float(racer_count)
	return home + Vector2(cos(angle), sin(angle)) * 55.0

func _are_all_merlinda_racers_finished() -> bool:
	if racer_states.is_empty():
		return false
	for racer in racer_states:
		if not bool(racer.get("finished", false)):
			return false
	return true

func _process_racer_temporary_effects(racer: Dictionary, delta: float) -> float:
	for timer_key in ["pickup_timer", "slow_timer", "stop_timer", "disabled_timer", "encore_timer"]:
		racer[timer_key] = max(0.0, float(racer.get(timer_key, 0.0)) - delta)
	var pitstop_phase = str(racer.get("pitstop_phase", ""))
	if not pitstop_phase.is_empty():
		var pitstop_timer = max(0.0, float(racer.get("pitstop_timer", 0.0)) - delta)
		if pitstop_timer <= 0.0:
			if pitstop_phase == "slow":
				pitstop_phase = "boost"
				pitstop_timer = MERLINDA_PITSTOP_BOOST_DURATION
			else:
				pitstop_phase = ""
		racer["pitstop_phase"] = pitstop_phase
		racer["pitstop_timer"] = pitstop_timer
	if float(racer.get("disabled_timer", 0.0)) > 0.0 or float(racer.get("stop_timer", 0.0)) > 0.0:
		return 0.0
	var multiplier = 1.0
	if float(racer.get("slow_timer", 0.0)) > 0.0:
		multiplier *= 0.45
	if float(racer.get("pickup_timer", 0.0)) > 0.0:
		multiplier *= float(racer.get("pickup_multiplier", 1.0))
	if float(racer.get("encore_timer", 0.0)) > 0.0:
		var encore_level = get_companion_upgrade_level("racer", "encore")
		multiplier *= 1.0 + min(0.5, float(encore_level) * MERLINDA_ENCORE_RACER_BONUS_PER_LEVEL)
	if pitstop_phase == "slow":
		multiplier *= MERLINDA_PITSTOP_SLOW_MULTIPLIER
	elif pitstop_phase == "boost":
		multiplier *= MERLINDA_PITSTOP_BOOST_MULTIPLIER
	return multiplier

func _apply_racer_pick_me_up(racer: Dictionary) -> void:
	var pickup_level = int(get_effective_ship_upgrade_level("merlinda", "pick_me_ups"))
	if pickup_level <= 0 or rng.randf() >= min(0.8, float(pickup_level) * MERLINDA_PICKUP_CHANCE_PER_LEVEL):
		return
	var game_state = get_node_or_null("/root/GameState")
	var derby_active = game_state and bool(game_state.merlinda_derby_picks_enabled)
	if derby_active and rng.randf() < min(0.75, float(pickup_level) * MERLINDA_DERBY_MISHAP_CHANCE_PER_LEVEL):
		match rng.randi_range(0, 2):
			0:
				racer["slow_timer"] = 3.0
			1:
				racer["stop_timer"] = 1.5
			_:
				racer["disabled_timer"] = 3.5
		add_resources(float(pickup_level) * MERLINDA_DERBY_REWARD_PER_LEVEL * get_ship_ore_multiplier("merlinda"), "merlinda")
		return
	racer["pickup_timer"] = MERLINDA_PICKUP_DURATION
	racer["pickup_multiplier"] = 1.0 + min(1.5, float(pickup_level) * MERLINDA_PICKUP_SPEED_PER_LEVEL)

func _process_racer_encore(racer: Dictionary) -> void:
	var encore_level = get_companion_upgrade_level("racer", "encore")
	if encore_level <= 0 or encore_active_timer > 0.0:
		return
	var racer_position: Vector2 = racer.get("position", Vector2.ZERO)
	var contacts: Dictionary = racer.get("encore_contacts", {})
	var triggered := false
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			if not is_instance_valid(drone) or not drone is Node2D:
				continue
			var contact_key = "drone:%s" % drone.get_instance_id()
			if contacts.has(contact_key) or racer_position.distance_to(drone.position) > MERLINDA_ENCORE_PASS_RADIUS:
				continue
			contacts[contact_key] = true
			drone.set_meta("merlinda_encore_until_msec", Time.get_ticks_msec() + int(MERLINDA_ENCORE_DURATION * 1000.0))
			drone.set_meta("merlinda_encore_multiplier", MERLINDA_ENCORE_UNIT_MULTIPLIER)
			triggered = true
			break
	var game_state = get_node_or_null("/root/GameState")
	if game_state and not triggered:
		for ship_key in ["flagship"] + Catalog.get_ship_ids():
			if ship_key == "merlinda" or (ship_key != "flagship" and not game_state.is_ship_unlocked(ship_key)):
				continue
			var contact_key = "ship:%s" % ship_key
			if contacts.has(contact_key):
				continue
			var ship_position = flotilla.position if ship_key == "flagship" and flotilla and is_instance_valid(flotilla) else get_ship_world_position(ship_key)
			if racer_position.distance_to(ship_position) > MERLINDA_ENCORE_PASS_RADIUS:
				continue
			contacts[contact_key] = true
			encore_ship_boost_timers[ship_key] = MERLINDA_ENCORE_DURATION
			triggered = true
			break
	if triggered:
		racer["encore_timer"] = MERLINDA_ENCORE_DURATION
		encore_active_timer = MERLINDA_ENCORE_DURATION
	racer["encore_contacts"] = contacts

func _process_encore_ship_boosts(delta: float) -> void:
	encore_active_timer = max(0.0, encore_active_timer - delta)
	var expired: Array[String] = []
	var flagship_was_boosted = encore_ship_boost_timers.has("flagship")
	for ship_key in encore_ship_boost_timers:
		encore_ship_boost_timers[ship_key] = max(0.0, float(encore_ship_boost_timers[ship_key]) - delta)
		if float(encore_ship_boost_timers[ship_key]) <= 0.0:
			expired.append(str(ship_key))
	for ship_key in expired:
		encore_ship_boost_timers.erase(ship_key)
	if flagship_was_boosted or encore_ship_boost_timers.has("flagship"):
		configure_flagship()

func _grant_merlinda_checkpoint_reward() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("merlinda_checkpoint_markers")) > 0:
		add_resources(MERLINDA_CHECKPOINT_REWARD * get_ship_ore_multiplier("merlinda"), "merlinda")

func _get_merlinda_racer_finish_reward(nodes_raced: int) -> float:
	return float(get_effective_ship_upgrade_level("merlinda", "consolation")) * 25.0 if nodes_raced > 0 else 0.0

func _grant_merlinda_racer_finish_reward(nodes_raced: int) -> void:
	var reward = _get_merlinda_racer_finish_reward(nodes_raced)
	if reward > 0.0:
		add_resources(reward * get_ship_ore_multiplier("merlinda"), "merlinda")

func _grant_merlinda_race_completion_reward() -> void:
	var reward = get_merlinda_race_completion_reward(merlinda_race_course.size())
	if reward > 0.0:
		add_resources(reward * get_ship_ore_multiplier("merlinda"), "merlinda")

func get_merlinda_race_completion_reward(nodes_raced: int) -> float:
	var reward = MERLINDA_BASE_RACE_REWARD + float(max(0, nodes_raced)) * MERLINDA_RACE_REWARD_PER_NODE
	reward += float(get_effective_ship_upgrade_level("merlinda", "celebrations")) * 500.0
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("racer_grand_prize")) > 0:
		reward *= 5.0
	return reward

func get_racer_drone_speed(base_speed_stat: float = 250.0) -> float:
	return clamp(base_speed_stat, MERLINDA_RACER_MIN_SPEED, MERLINDA_RACER_MAX_SPEED) * MERLINDA_RACER_SPEED_SCALE * get_merlinda_racer_speed_multiplier()

func get_merlinda_course_marker_speed() -> float:
	return MERLINDA_COURSE_MARKER_SPEED * get_merlinda_racer_speed_multiplier()

func get_merlinda_racer_speed_multiplier() -> float:
	var multiplier = get_speed() / BASE_SPEED
	multiplier *= 1.0 + float(get_companion_upgrade_level("racer", "speed")) * 0.05
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("racer_ion_thrusters")) > 0:
		multiplier *= 2.0
	return multiplier

func get_racer_course_width() -> float:
	var awareness_level = get_effective_ship_upgrade_level("merlinda", "awareness")
	return MERLINDA_BASE_COURSE_WIDTH * (1.0 + log(1.0 + float(awareness_level)) * MERLINDA_AWARENESS_WIDTH_GROWTH)

func _roll_racer_speed_stat() -> float:
	return float(rng.randi_range(int(MERLINDA_RACER_MIN_SPEED), int(MERLINDA_RACER_MAX_SPEED)))

func get_racer_turn_speed() -> float:
	var turn_speed = MERLINDA_BASE_TURN_SPEED * (1.0 + float(get_companion_upgrade_level("racer", "swivel")) * MERLINDA_SWIVEL_BONUS_PER_LEVEL)
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("racer_afterburn")) > 0:
		turn_speed *= 1.5
	return turn_speed

func _process_ship_operations(delta: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or flotilla == null or not is_instance_valid(flotilla):
		return
	for ship_key in Catalog.get_ship_ids():
		if not game_state.is_ship_unlocked(ship_key):
			continue
		var formation_position = _get_ship_formation_position(ship_key)
		if not ship_operation_positions.has(ship_key):
			ship_operation_positions[ship_key] = formation_position
		var desired_position = formation_position
		if ship_key in ["minotard", "atlas", "tobias", "fruegal"]:
			var resource_types: Array = [""]
			if ship_key == "atlas":
				resource_types = ["", "enriched", "gas_planet", "gas_cloud"]
			elif ship_key == "tobias":
				resource_types = ["gas_planet", "gas_cloud"]
			elif ship_key == "fruegal":
				resource_types = ["", "enriched", "gas_planet", "gas_cloud"]
			var target = ship_operation_targets.get(ship_key)
			if target == null or not is_instance_valid(target) or not _is_valid_mining_target(target) or not resource_types.has(str(target.get_meta("resource_type", ""))):
				target = _get_nearest_resource_by_types(resource_types, ship_key)
				ship_operation_targets[ship_key] = target
			if target != null:
				var approach_direction = (flotilla.position - target.position).normalized()
				if approach_direction.length_squared() < 0.001:
					approach_direction = Vector2.LEFT
				var stand_off = min(240.0, max(40.0, _get_ship_work_range(ship_key) * 0.4))
				desired_position = target.position + approach_direction * stand_off
		elif ship_key == "stapledon":
			desired_position = _get_sun_world_position() + Vector2(700.0, 0.0)
		elif ship_key == "boschore" and game_state.is_ship_unlocked("tobias"):
			desired_position = get_ship_world_position("tobias") + Vector2(-140.0, 50.0)
		var current_position: Vector2 = ship_operation_positions[ship_key]
		ship_operation_positions[ship_key] = current_position.move_toward(desired_position, _get_operational_ship_speed(ship_key) * delta)

func _get_ship_formation_position(ship_key: String) -> Vector2:
	var flagship_position = flotilla.position if flotilla and is_instance_valid(flotilla) else FLEET_START_POSITION
	var formation_offset: Vector2 = Catalog.get_ship_data(ship_key).get("offset", Vector2.ZERO) * FLEET_FORMATION_SCALE
	if flotilla and is_instance_valid(flotilla) and flotilla.has_method("get_formation_forward"):
		var forward: Vector2 = flotilla.get_formation_forward()
		formation_offset = Vector2(
			forward.x * formation_offset.x - forward.y * formation_offset.y,
			forward.y * formation_offset.x + forward.x * formation_offset.y
		)
	return flagship_position + formation_offset

func _get_operational_ship_speed(ship_key: String) -> float:
	var speed = BASE_FLAGSHIP_SPEED + float(get_effective_ship_upgrade_level(ship_key, "speed")) * 10.0
	speed += float(get_effective_ship_upgrade_level("gethica", "local_sfc")) * 10.0
	speed += float(get_effective_ship_upgrade_level("parallax", "coordinator")) * 2.0
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		if ship_key == "minotard" and int(game_state.get_passive_level("minotard_ion_thrusters")) > 0:
			speed *= 2.0
		elif ship_key == "atlas":
			if int(game_state.get_passive_level("atlas_industrial_thruster")) > 0:
				speed += 20.0
			if int(game_state.get_passive_level("atlas_ion_thruster")) > 0:
				speed *= 2.0
		elif ship_key == "tobias" and int(game_state.get_passive_level("tobias_helium_fuel")) > 0:
			speed *= 3.0
	if float(encore_ship_boost_timers.get(ship_key, 0.0)) > 0.0:
		speed *= MERLINDA_ENCORE_UNIT_MULTIPLIER
	return max(20.0, speed)

func _get_ship_work_range(ship_key: String) -> float:
	match ship_key:
		"atlas":
			return 2000.0
		"tobias":
			return 300.0 + float(get_effective_ship_upgrade_level("tobias", "elongation")) * 100.0 + float(get_effective_ship_upgrade_level("boschore", "extension")) * 250.0
		"fruegal":
			return 300.0 + float(get_effective_ship_upgrade_level("fruegal", "funneling")) * 100.0
	return 300.0

func _process_catalog_research_income(delta: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if game_state.is_ship_unlocked("nelson") and int(game_state.get_passive_level("nelson_channels")) > 0 and get_effective_ship_upgrade_level("nelson", "local_fm") > 0:
		nelson_track_timer += delta
		var channel_interval = max(30.0, 120.0 - float(get_effective_ship_upgrade_level("nelson", "local_fm")) * 5.0)
		while nelson_track_timer >= channel_interval:
			nelson_track_timer -= channel_interval
			add_resources(2000.0 * get_ship_ore_multiplier("nelson"), "nelson")
	else:
		nelson_track_timer = 0.0
	if game_state.is_ship_unlocked("nelson") and get_effective_ship_upgrade_level("nelson", "band_practice") > 0:
		nelson_practice_timer += delta
		while nelson_practice_timer >= NELSON_PRACTICE_INTERVAL:
			nelson_practice_timer -= NELSON_PRACTICE_INTERVAL
			nelson_practice_cycles += 1
	else:
		nelson_practice_timer = 0.0
		nelson_practice_cycles = 0
	if game_state.is_ship_unlocked("elysium_air"):
		elysium_visit_timer = fmod(elysium_visit_timer + delta, _get_elysium_visit_interval())
	else:
		elysium_visit_timer = 0.0

func _get_elysium_visit_interval() -> float:
	return max(60.0, 300.0 - float(get_effective_ship_upgrade_level("elysium_air", "invitation")) * 2.0)

func is_elysium_visitor_active() -> bool:
	var duration = 10.0 * (1.0 + float(get_effective_ship_upgrade_level("elysium_air", "invitation")) * 0.01)
	return elysium_visit_timer < duration

func _process_mining_ship(ship_key: String, delta: float, resource_types: Array, max_targets: int) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked(ship_key):
		ship_income_timers[ship_key] = 0.0
		return
	var amount = 0
	var interval = 1.0
	match ship_key:
		"minotard":
			amount = 10 + get_effective_ship_upgrade_level(ship_key, "mining_array") * 10
			interval = 1.0 / max(0.1, 1.0 + float(get_effective_ship_upgrade_level(ship_key, "optimized_mining")) * 0.05)
			if int(game_state.get_passive_level("minotard_bifocal_lens")) > 0:
				interval /= 1.05
		"tobias":
			amount = 10 + get_effective_ship_upgrade_level(ship_key, "dual_chamber") * 10
			var vacuum_count = (5 if int(game_state.get_passive_level("tobias_vacuum_drone_bays")) > 0 else 0) + get_effective_ship_upgrade_level("boschore", "vacuum_command_capacity")
			amount += vacuum_count * 2
			interval = 1.0 / max(0.1, 1.0 + float(get_effective_ship_upgrade_level(ship_key, "compressor")) * 0.05)
			if vacuum_count > 0:
				interval /= get_drone_reconfiguration_multiplier()
			if int(game_state.get_passive_level("boschore_nozzle_selection")) > 0:
				interval /= 3.0
		"fruegal":
			amount = 5 + get_effective_ship_upgrade_level(ship_key, "micron_laser") * 5
			interval = 1.0 / max(0.1, 1.0 + float(get_effective_ship_upgrade_level(ship_key, "diamond_tip")) * 0.05)
	if amount <= 0:
		return
	var active_target = ship_operation_targets.get(ship_key)
	if active_target == null or not is_instance_valid(active_target) or not _is_valid_mining_target(active_target):
		return
	if ship_key == "fruegal" and str(active_target.get_meta("resource_type", "")) in ["gas_planet", "gas_cloud"]:
		var vacuum_count = get_effective_ship_upgrade_level(ship_key, "vacuum_command_capacity")
		amount += vacuum_count * 2
		if vacuum_count > 0:
			interval /= get_drone_reconfiguration_multiplier()
	if get_ship_world_position(ship_key).distance_to(active_target.position) > _get_ship_work_range(ship_key):
		return
	if float(encore_ship_boost_timers.get(ship_key, 0.0)) > 0.0:
		interval /= MERLINDA_ENCORE_UNIT_MULTIPLIER
	if ship_key == "fruegal":
		var nearby_nodes = _count_resources_in_range(get_ship_world_position(ship_key), _get_ship_work_range(ship_key), resource_types)
		interval /= 1.0 + float(max(0, nearby_nodes - 1) * get_effective_ship_upgrade_level(ship_key, "adjacentor")) * 0.02
	ship_income_timers[ship_key] = float(ship_income_timers.get(ship_key, 0.0)) + delta
	while float(ship_income_timers[ship_key]) >= interval:
		if not _is_valid_mining_target(active_target):
			ship_income_timers[ship_key] = 0.0
			break
		ship_income_timers[ship_key] = float(ship_income_timers[ship_key]) - interval
		var cycle_targets: Array[Node] = []
		for target_index in range(max_targets):
			var target = active_target if target_index == 0 else _get_nearest_resource_by_types(resource_types, ship_key, cycle_targets)
			if target == null:
				break
			cycle_targets.append(target)
			if get_ship_world_position(ship_key).distance_to(target.position) > _get_ship_work_range(ship_key):
				break
			var harvested = int(target.mine(amount))
			if harvested <= 0:
				continue
			var gained = float(harvested) * get_ship_ore_multiplier(ship_key)
			if ship_key == "minotard" and int(game_state.get_passive_level("minotard_optical_lens")) > 0:
				gained *= 1.1
			if ship_key == "tobias":
				var active_vacuum_count = (5 if int(game_state.get_passive_level("tobias_vacuum_drone_bays")) > 0 else 0) + get_effective_ship_upgrade_level("boschore", "vacuum_command_capacity")
				gained *= 1.0 + float(active_vacuum_count * get_effective_ship_upgrade_level("boschore", "exciter")) * 0.02
				if int(game_state.get_passive_level("boschore_dust_bunnies")) > 0:
					gained += 100.0
			add_resources(gained, ship_key)

func _get_nearest_resource_by_types(resource_types: Array, ship_key: String = "flagship", excluded_targets: Array[Node] = []) -> Node:
	var parent = get_parent()
	if parent == null or not parent.has_node("Asteroids"):
		return null
	var best: Node = null
	var best_distance = INF
	for node in parent.get_node("Asteroids").get_children():
		if node in excluded_targets:
			continue
		if not _is_valid_mining_target(node):
			continue
		var resource_type = str(node.get_meta("resource_type", ""))
		if not resource_types.has(resource_type):
			continue
		var distance = get_ship_world_position(ship_key).distance_to(node.position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best

func _count_resources_in_range(origin: Vector2, radius: float, resource_types: Array) -> int:
	var parent = get_parent()
	if parent == null or not parent.has_node("Asteroids"):
		return 0
	var count = 0
	for node in parent.get_node("Asteroids").get_children():
		if _is_valid_mining_target(node) and resource_types.has(str(node.get_meta("resource_type", ""))) and origin.distance_to(node.position) <= radius:
			count += 1
	return count

func _get_catalog_income_interval(ship_key: String) -> float:
	var game_state = get_node_or_null("/root/GameState")
	match ship_key:
		"merlinda":
			return MERLINDA_RACE_WAIT
		"stapledon":
			var interval = max(2.0, 20.0 - float(get_effective_ship_upgrade_level(ship_key, "flare_catcher")))
			if game_state and int(game_state.get_passive_level("stapledon_nanofilm")) > 0:
				interval *= 0.98
			return interval / get_drone_reconfiguration_multiplier()
		"tarrip":
			var interval = 7.5 if game_state and int(game_state.get_passive_level("tarrip_efficient_bureaucracy")) > 0 else 10.0
			return interval / get_drone_reconfiguration_multiplier()
		"elysium_air":
			var interval = max(30.0, 300.0 - float(get_effective_ship_upgrade_level(ship_key, "invitation")) * 2.0)
			if game_state and int(game_state.get_passive_level("elysium_xeno_trade")) > 0:
				interval /= 1.25
			if game_state and int(game_state.get_passive_level("elysium_visitors")) > 0 and is_elysium_visitor_active():
				interval /= 1.5
			return interval / get_drone_reconfiguration_multiplier()
	return 1.0

func _get_catalog_income_amount(ship_key: String) -> float:
	var game_state = get_node_or_null("/root/GameState")
	var ship_count = Catalog.get_ship_count_at_rank(int(game_state.prestige_level)) if game_state else 1
	match ship_key:
		"nelson":
			return float(get_effective_ship_upgrade_level(ship_key, "local_comms")) * 5.0 + float(get_effective_ship_upgrade_level(ship_key, "commissions") * ship_count)
		"merlinda":
			return 0.0
		"stapledon":
			var income = float(get_effective_ship_upgrade_level(ship_key, "dyson_capacity")) * 25.0
			income *= 1.0 + float(get_effective_ship_upgrade_level(ship_key, "solar_collectors")) * 0.05
			if game_state and int(game_state.get_passive_level("stapledon_monocrystalline")) > 0:
				income *= 1.2
			return income
		"tarrip":
			var traders = get_effective_ship_upgrade_level(ship_key, "trader_capacity")
			var cargo = 50.0 + float(get_effective_ship_upgrade_level(ship_key, "micro_transits")) * 5.0
			if game_state and int(game_state.get_passive_level("tarrip_specialised_cargo")) > 0:
				cargo *= 2.0
			return float(traders) * (cargo + float(get_effective_ship_upgrade_level(ship_key, "tradehub")) * 50.0) + float(get_effective_ship_upgrade_level(ship_key, "highstreet_traffic") * ship_count * 100)
		"elysium_air":
			var income = float(get_effective_ship_upgrade_level(ship_key, "trader_capacity")) * 100.0
			income *= 1.0 + float(get_effective_ship_upgrade_level(ship_key, "exhibits")) * 0.25
			return income
	return 0.0

func _process_local_antenna(delta: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked("kradle") or int(game_state.get_passive_level("kradle_local_antenna")) <= 0:
		local_antenna_timer = 0.0
		return
	local_antenna_timer += delta
	if local_antenna_timer < LOCAL_ANTENNA_INTERVAL:
		return
	local_antenna_timer = fmod(local_antenna_timer, LOCAL_ANTENNA_INTERVAL)
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	var node = asteroid_scene.instantiate()
	container.add_child(node)
	node.name = "LocalAntennaAsteroid"
	node.position = get_ship_world_position("kradle") + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(12.0, 20.0)
	node.max_resource_amount = 100
	node.resource_amount = 100
	node.set_meta("bonus_resource_node", true)
	node.set_meta("resource_display_name", "Local Antenna Asteroid")
	node.add_to_group("asteroids")

func _process_autor(delta: float) -> void:
	if flotilla == null or not is_instance_valid(flotilla):
		return
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("is_autor_active") or not game_state.is_autor_active():
		autor_timer = 0.0
		return
	if manual_fleet_order_active:
		if flotilla.position.distance_to(flotilla.move_target) <= 1.0:
			manual_fleet_order_active = false
		else:
			return
	if not _is_valid_mining_target(fleet_mining_target):
		fleet_mining_target = null
	if fleet_mining_target:
		_move_fleet_within_mining_range(fleet_mining_target)
	else:
		var parent = get_parent()
		if parent == null or not parent.has_node("Asteroids"):
			return
		fleet_mining_target = _get_closest_asteroid_for_assignment(flotilla.position, parent.get_node("Asteroids"), false)
		if fleet_mining_target:
			_move_fleet_within_mining_range(fleet_mining_target)
	if not _is_valid_mining_target(fleet_mining_target) or not is_asteroid_in_mining_range(fleet_mining_target):
		return
	autor_timer += delta
	var interval = 1.0 / max(1.0, get_hold_click_rate())
	while autor_timer >= interval:
		if not _is_valid_mining_target(fleet_mining_target):
			fleet_mining_target = null
			break
		autor_timer -= interval
		click_mine(fleet_mining_target, true, true)
		if not _is_valid_mining_target(fleet_mining_target):
			fleet_mining_target = null
			break

func _process_development_protocol(delta: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	var enabled = game_state and game_state.has_method("is_development_protocol_unlocked") and game_state.is_development_protocol_unlocked() and bool(game_state.development_protocol_enabled)
	if not enabled:
		development_protocol_timer = 0.0
		return
	development_protocol_timer += delta
	if development_protocol_timer < DEVELOPMENT_PROTOCOL_INTERVAL:
		return
	development_protocol_timer = fmod(development_protocol_timer, DEVELOPMENT_PROTOCOL_INTERVAL)
	_buy_cheapest_ore_upgrade()

func _buy_cheapest_ore_upgrade() -> bool:
	var candidates: Array[Dictionary] = []
	for upgrade in ["click_output", "click_multiplier", "flagship_speed", "refining", "mining", "mining_speed", "capacity", "speed"]:
		if not is_autobuy_upgrade_enabled("base", upgrade):
			continue
		var base_level = int(get("%s_level" % upgrade))
		if base_level < get_ore_upgrade_cap(upgrade):
			candidates.append({"kind": "base", "key": upgrade, "cost": get_ore_upgrade_cost(upgrade, base_level)})
	if is_autobuy_upgrade_enabled("base", "drones") and (has_missing_owned_drones("flagship") or drone_level < get_ore_upgrade_cap("drones")):
		candidates.append({"kind": "drone", "key": "drones", "cost": get_drone_purchase_cost()})

	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("is_ship_unlocked"):
		for ship_key in ship_upgrade_levels:
			if not game_state.is_ship_unlocked(ship_key):
				continue
			for stat_key in ship_upgrade_levels[ship_key]:
				if not is_autobuy_upgrade_enabled(ship_key, stat_key):
					continue
				var ship_level = get_ship_upgrade_level(ship_key, stat_key)
				var replacing_drone = stat_key == _get_ship_mining_drone_stat(ship_key) and not str(stat_key).is_empty() and has_missing_owned_drones(ship_key)
				if not replacing_drone and get_ship_upgrade_gains(ship_key, stat_key).is_empty():
					continue
				if replacing_drone or ship_level < get_ship_upgrade_cap(ship_key, stat_key):
					candidates.append({
						"kind": "ship",
						"ship": ship_key,
						"key": stat_key,
						"cost": get_ship_upgrade_cost(ship_key, stat_key, 0 if replacing_drone else ship_level)
					})
		for companion_id in companion_upgrade_levels:
			var required_ship = str(Catalog.get_companion_data(companion_id).get("required_ship", ""))
			if not required_ship.is_empty() and not game_state.is_ship_unlocked(required_ship):
				continue
			for stat_key in companion_upgrade_levels[companion_id]:
				if not is_autobuy_upgrade_enabled("companion:%s" % companion_id, stat_key):
					continue
				var companion_level = get_companion_upgrade_level(companion_id, stat_key)
				if companion_level < get_companion_upgrade_cap(companion_id, stat_key):
					candidates.append({
						"kind": "companion",
						"companion": companion_id,
						"key": stat_key,
						"cost": get_companion_upgrade_cost(companion_id, stat_key, companion_level)
					})

	var best: Dictionary = {}
	for candidate in candidates:
		var cost = int(candidate["cost"])
		if cost > total_resources:
			continue
		if best.is_empty() or cost < int(best["cost"]):
			best = candidate
	if best.is_empty():
		return false
	match str(best["kind"]):
		"base":
			if str(best["key"]) == "flagship_speed":
				return upgrade_flagship_speed()
			return _buy_upgrade(str(best["key"]))
		"drone":
			return buy_drone()
		"ship":
			return upgrade_ship_stat(str(best["ship"]), str(best["key"]))
		"companion":
			return upgrade_companion_stat(str(best["companion"]), str(best["key"]))
	return false

func _autobuy_upgrade_key(owner: String, stat_key: String) -> String:
	return "%s:%s" % [owner, stat_key]

func is_autobuy_upgrade_enabled(owner: String, stat_key: String) -> bool:
	return bool(autobuy_upgrade_enabled.get(_autobuy_upgrade_key(owner, stat_key), true))

func toggle_autobuy_upgrade(owner: String, stat_key: String) -> bool:
	var key = _autobuy_upgrade_key(owner, stat_key)
	autobuy_upgrade_enabled[key] = not bool(autobuy_upgrade_enabled.get(key, true))
	emit_signal("upgrades_changed")
	return bool(autobuy_upgrade_enabled[key])

func order_fleet_to(world_position: Vector2) -> void:
	if flotilla == null or not is_instance_valid(flotilla):
		return
	fleet_mining_target = null
	manual_fleet_order_active = true
	flotilla.move_to(world_position)

func stop_fleet() -> void:
	if flotilla == null or not is_instance_valid(flotilla):
		return
	fleet_mining_target = null
	manual_fleet_order_active = false
	flotilla.move_to(flotilla.position)

func approach_asteroid(target) -> bool:
	if not _is_valid_mining_target(target) or flotilla == null or not is_instance_valid(flotilla):
		return false
	fleet_mining_target = target
	manual_fleet_order_active = false
	_move_fleet_within_mining_range(target)
	return true

func _move_fleet_within_mining_range(target) -> void:
	if not _is_valid_mining_target(target) or flotilla == null or not is_instance_valid(flotilla):
		return
	var distance = flotilla.position.distance_to(target.position)
	if distance <= get_fleet_mining_range():
		return
	var away_from_target = (flotilla.position - target.position).normalized()
	if away_from_target.length_squared() <= MIN_LAUNCH_DIRECTION_LENGTH:
		away_from_target = Vector2.RIGHT
	var destination = target.position + away_from_target * FLEET_APPROACH_DISTANCE
	if flotilla.move_target.distance_to(destination) > 1.0:
		flotilla.move_to(destination)

func _is_valid_mining_target(target) -> bool:
	return target != null and is_instance_valid(target) and target.is_in_group("asteroids") and not target.is_in_group("sun") and int(target.resource_amount) > 0 and can_mine_resource_node(target)

func can_mine_resource_node(target) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var required_ship = str(target.get_meta("required_ship", ""))
	if required_ship.is_empty():
		return true
	var game_state = get_node_or_null("/root/GameState")
	return game_state != null and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked(required_ship)

func get_resource_lock_message(target) -> String:
	if target == null or not is_instance_valid(target) or can_mine_resource_node(target):
		return ""
	var required_ship = str(target.get_meta("required_ship", ""))
	return "LOCKED: Requires %s to harvest" % Catalog.get_display_name(required_ship)

func is_asteroid_in_mining_range(target) -> bool:
	return _is_valid_mining_target(target) and flotilla != null and is_instance_valid(flotilla) and flotilla.position.distance_to(target.position) <= get_fleet_mining_range()

func _record_income(source: String, amount: float) -> void:
	if amount <= 0.0:
		return
	income_events.append({"time": float(Time.get_ticks_msec()) / 1000.0, "source": source, "amount": amount})
	_prune_income_events()

func get_income_summary() -> Dictionary:
	_prune_income_events()
	var summary := {}
	for event in income_events:
		var source = str(event.get("source", "other"))
		summary[source] = float(summary.get(source, 0.0)) + float(event.get("amount", 0.0))
	return summary

func _record_purchase(purchase_name: String, cost: int) -> void:
	last_purchase_name = purchase_name
	last_purchase_cost = max(0, cost)

func get_last_purchase_text() -> String:
	return "%s | %d Credits" % [last_purchase_name, last_purchase_cost]

func _prune_income_events() -> void:
	var cutoff = float(Time.get_ticks_msec()) / 1000.0 - INCOME_RATE_WINDOW
	while not income_events.is_empty() and float(income_events[0]["time"]) < cutoff:
		income_events.pop_front()

func get_income_rate(source: String) -> float:
	_prune_income_events()
	var total = 0.0
	for event in income_events:
		if str(event["source"]) == source:
			total += float(event["amount"])
	return total / INCOME_RATE_WINDOW

func get_ship_income_rate(ship_key: String) -> float:
	match ship_key:
		"flagship":
			return get_income_rate("click_mining")
		"mining_drone", "drone_carrier":
			return get_income_rate("mining_drones")
	return get_income_rate(ship_key)

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

func _random_ring_spawn_position(allowed_rings: Array) -> Vector2:
	var ring_index = int(allowed_rings[rng.randi_range(0, allowed_rings.size() - 1)])
	var angle = rng.randf_range(0.0, TAU)
	var radius = float(SYSTEM_RING_RADII[ring_index - 1]) + rng.randf_range(-SYSTEM_RING_HALF_WIDTH, SYSTEM_RING_HALF_WIDTH)
	return Vector2(cos(angle), sin(angle)) * radius

func get_system_ring_radii() -> PackedFloat32Array:
	var radii := PackedFloat32Array()
	for radius in SYSTEM_RING_RADII:
		radii.append(float(radius))
	return radii

func get_fleet_start_position() -> Vector2:
	return FLEET_START_POSITION

func get_fleet_mining_range() -> float:
	var adjuster_levels = get_effective_ship_upgrade_level("gethica", "adjuster") + get_effective_ship_upgrade_level("kradle", "adjuster")
	return FLEET_MINING_RANGE + float(adjuster_levels) * 100.0

func get_system_ring_index(world_position: Vector2) -> int:
	var closest_ring = 1
	var closest_distance = INF
	for ring_offset in range(SYSTEM_RING_RADII.size()):
		var distance_to_ring = abs(world_position.length() - float(SYSTEM_RING_RADII[ring_offset]))
		if distance_to_ring < closest_distance:
			closest_distance = distance_to_ring
			closest_ring = ring_offset + 1
	return closest_ring

func is_planet_spawn_ring(ring_index: int) -> bool:
	return ring_index in PLANET_RINGS

func _is_spawn_position_valid(candidate: Vector2, existing: Array, min_distance: float) -> bool:
	for other in existing:
		if candidate.distance_to(other) < min_distance:
			return false
	return true

func _find_ring_spawn_position(existing: Array, min_distance: float, allowed_rings: Array) -> Vector2:
	for attempt in range(300):
		var candidate = _random_ring_spawn_position(allowed_rings)
		if _is_spawn_position_valid(candidate, existing, min_distance):
			return candidate
	var starting_angle = rng.randf_range(0.0, TAU)
	for ring_value in allowed_rings:
		var radius = float(SYSTEM_RING_RADII[int(ring_value) - 1])
		var slot_count = max(8, int(floor(TAU * radius / min_distance)))
		for slot_index in range(slot_count):
			var angle = starting_angle + TAU * float(slot_index) / float(slot_count)
			var candidate = Vector2(cos(angle), sin(angle)) * radius
			if _is_spawn_position_valid(candidate, existing, min_distance):
				return candidate
	return _random_ring_spawn_position(allowed_rings)

func _get_spawn_blockers(container: Node) -> Array:
	var blockers = []
	for node in container.get_children():
		if node.is_in_group("asteroids") and not node.is_in_group("sun"):
			blockers.append(node.position)
	return blockers

func spawn_resource_field() -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	for node in container.get_children():
		if node.is_in_group("asteroids") and not node.is_in_group("sun"):
			return
	_roll_field_name()
	spawn_sun()
	spawn_planets()
	spawn_asteroids()

func spawn_asteroids(count: int = -1) -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	if count < 0:
		count = rng.randi_range(ASTEROID_MIN_COUNT, ASTEROID_MAX_COUNT) + get_field_extra_node_count()
	var blockers = _get_spawn_blockers(container)
	for i in range(count):
		var a = asteroid_scene.instantiate()
		container.add_child(a)
		var asteroid_ring = [ASTEROID_RINGS[i % ASTEROID_RINGS.size()]]
		var spawn_position = _find_ring_spawn_position(blockers, ASTEROID_SEPARATION, asteroid_ring)
		a.position = spawn_position
		a.set_meta("system_ring", get_system_ring_index(spawn_position))
		a.max_resource_amount = 0
		a.resource_amount = a.max_resource_amount
		a.add_to_group("asteroids")
		blockers.append(spawn_position)
	_distribute_field_resources(container)
	_spawn_special_resource_nodes(container)

func _distribute_field_resources(container: Node) -> void:
	var resource_nodes: Array[Node] = []
	for node in container.get_children():
		if node.is_in_group("asteroids") and not node.is_in_group("sun") and not bool(node.get_meta("bonus_resource_node", false)) and not bool(node.get_meta("first_field_planet", false)):
			resource_nodes.append(node)
	if resource_nodes.is_empty():
		return
	var field_resource_cap = get_field_resource_cap(resource_nodes.size())
	var resources_per_node = int(floor(float(field_resource_cap) / float(resource_nodes.size())))
	var remainder = field_resource_cap % resource_nodes.size()
	for index in range(resource_nodes.size()):
		var node_resources = resources_per_node + (1 if index < remainder else 0)
		resource_nodes[index].max_resource_amount = node_resources
		resource_nodes[index].resource_amount = node_resources

func get_field_resource_cap(normal_node_count: int = 1) -> int:
	var resource_cap = FIELD_RESOURCE_CAP
	resource_cap += get_effective_ship_upgrade_level("gethica", "spectrometer") * GETHICA_SCANNER_RESOURCES * max(0, normal_node_count)
	return resource_cap

func get_field_extra_node_count() -> int:
	var game_state = get_node_or_null("/root/GameState")
	var extra_nodes = get_effective_ship_upgrade_level("parallax", "matilda_array")
	if game_state and int(game_state.get_passive_level("gethica_deep_space_arrays")) > 0:
		extra_nodes += 5
	return extra_nodes

func _roll_field_name() -> void:
	var available: Array[String] = []
	for prefix in FIELD_NAME_PREFIXES:
		for suffix in FIELD_NAME_SUFFIXES:
			var candidate = "%s %s" % [prefix, suffix]
			if not recent_field_names.has(candidate):
				available.append(candidate)
	if available.is_empty():
		recent_field_names.clear()
		_roll_field_name()
		return
	current_field_name = available[rng.randi_range(0, available.size() - 1)]
	recent_field_names.append(current_field_name)
	while recent_field_names.size() > 20:
		recent_field_names.pop_front()

func get_field_display_name() -> String:
	if current_field_name.is_empty():
		_roll_field_name()
	return "%s (%d)" % [current_field_name, asteroid_field_level + 1]

func spawn_planets(count: int = -1) -> void:
	var container = get_parent().get_node_or_null("Asteroids")
	if container == null:
		return
	var existing_planets = 0
	var has_first_field_planet = false
	var blockers = []
	for node in container.get_children():
		if node.is_in_group("planet"):
			if bool(node.get_meta("first_field_planet", false)):
				has_first_field_planet = true
			else:
				existing_planets += 1
		if node.is_in_group("asteroids"):
			blockers.append(node.position)
	if asteroid_field_level == 0 and not has_first_field_planet:
		var first_field_planet = _create_planet_node(container, FIRST_FIELD_PLANET_POSITION, 0, true)
		blockers.append(first_field_planet.position)
	if existing_planets >= PLANET_MAX_COUNT:
		return
	if count < 0:
		count = rng.randi_range(PLANET_MIN_COUNT, PLANET_MAX_COUNT - existing_planets)
	count = min(count, PLANET_MAX_COUNT - existing_planets)
	for i in range(count):
		var allowed_rings = PLANET_RINGS
		if count > 1:
			allowed_rings = INNER_PLANET_RINGS if i % 2 == 0 else OUTER_PLANET_RINGS
		var planet_position = _find_ring_spawn_position(blockers, PLANET_SEPARATION, allowed_rings)
		_create_planet_node(container, planet_position, get_system_ring_index(planet_position), false)
		blockers.append(planet_position)

func _create_planet_node(container: Node, planet_position: Vector2, system_ring: int, is_first_field_planet: bool) -> Node:
	var planet = asteroid_scene.instantiate()
	planet.name = "TutorialPlanet" if is_first_field_planet else "Planet"
	container.add_child(planet)
	planet.position = planet_position
	planet.set_meta("system_ring", system_ring)
	planet.set_meta("first_field_planet", is_first_field_planet)
	planet.set_meta("bonus_resource_node", is_first_field_planet)
	planet.max_resource_amount = 1000 if is_first_field_planet else 0
	planet.resource_amount = planet.max_resource_amount
	planet.add_to_group("asteroids")
	planet.add_to_group("planet")
	return planet

func _spawn_special_resource_nodes(container: Node) -> void:
	var game_state = get_node_or_null("/root/GameState")
	var blockers = _get_spawn_blockers(container)
	for resource_type in Catalog.SPECIAL_NODES:
		var definition: Dictionary = Catalog.SPECIAL_NODES[resource_type]
		var required_ship = str(definition["required_ship"])
		var unlocked = game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked(required_ship)
		var desired_count = 1 if unlocked else (1 if rng.randf() < SPECIAL_NODE_PRE_UNLOCK_CHANCE else 0)
		if unlocked and rng.randf() < SPECIAL_NODE_EXTRA_CHANCE:
			desired_count += 1
		var existing_count = 0
		for node in container.get_children():
			if str(node.get_meta("resource_type", "")) == str(resource_type):
				existing_count += 1
		for index in range(max(0, desired_count - existing_count)):
			var special_node = asteroid_scene.instantiate()
			container.add_child(special_node)
			var allowed_rings: Array = Array(definition["rings"])
			var spawn_position = _find_ring_spawn_position(blockers, ASTEROID_SEPARATION, allowed_rings)
			special_node.position = spawn_position
			special_node.name = str(definition["name"]).replace(" ", "")
			special_node.max_resource_amount = _get_special_node_amount(str(resource_type), definition)
			special_node.resource_amount = special_node.max_resource_amount
			special_node.set_meta("system_ring", get_system_ring_index(spawn_position))
			special_node.set_meta("resource_type", str(resource_type))
			special_node.set_meta("resource_display_name", str(definition["name"]))
			special_node.set_meta("required_ship", required_ship)
			special_node.set_meta("bonus_resource_node", true)
			special_node.add_to_group("asteroids")
			special_node.add_to_group("special_resource")
			if str(resource_type) == "gas_planet":
				special_node.add_to_group("planet")
			blockers.append(spawn_position)

func _get_special_node_amount(resource_type: String, definition: Dictionary) -> int:
	if resource_type == "enriched":
		var game_state = get_node_or_null("/root/GameState")
		if game_state and int(game_state.get_passive_level("gethica_scan_enrichment")) > 0:
			return 5000
	return int(definition.get("amount", 1000))

func get_active_drone_count(source_ship: String = "") -> int:
	var parent = get_parent()
	if parent == null or not parent.has_node("Drones"):
		return 0
	var drones = parent.get_node("Drones").get_children()
	if source_ship.is_empty():
		return drones.size()
	var owned_count = 0
	for drone in drones:
		if str(drone.source_ship) == source_ship:
			owned_count += 1
	return owned_count

func get_owned_drone_count(source_ship: String = "") -> int:
	var game_state = get_node_or_null("/root/GameState")
	var flagship_readiness = 1 if flagship_readiness_bonus_active or (game_state and game_state.has_method("is_flagship_readiness_unlocked") and game_state.is_flagship_readiness_unlocked()) else 0
	if source_ship == "flagship":
		return max(flagship_readiness, drone_level)
	if not source_ship.is_empty():
		return max(0, _get_ship_mining_drone_capacity(source_ship))
	var owned_count = max(flagship_readiness, drone_level)
	for ship_key in ship_upgrade_levels:
		owned_count += _get_ship_mining_drone_capacity(ship_key)
	return max(0, owned_count)

func get_readiness_drone_minimum() -> int:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return 0
	var minimum = 1 if flagship_readiness_bonus_active or (game_state.has_method("is_flagship_readiness_unlocked") and game_state.is_flagship_readiness_unlocked()) else 0
	if int(game_state.get_passive_level("brooder_readiness")) > 0:
		minimum += 5
	return minimum

func _get_ship_mining_drone_capacity(ship_key: String) -> int:
	match ship_key:
		"kradle", "atlas":
			return get_effective_ship_upgrade_level(ship_key, "command_capacity")
		"drone_carrier":
			var capacity = int(get_effective_ship_upgrade_level(ship_key, "command_capacity"))
			var game_state = get_node_or_null("/root/GameState")
			return max(capacity, 5 if game_state and int(game_state.get_passive_level("brooder_readiness")) > 0 else 0)
		"fruegal":
			return get_effective_ship_upgrade_level(ship_key, "drone_command_capacity")
	return 0

func has_missing_owned_drones(source_ship: String = "") -> bool:
	if get_active_drone_count() >= get_owned_drone_count():
		return false
	return get_active_drone_count(source_ship) < get_owned_drone_count(source_ship)

func get_drone_purchase_cost() -> int:
	if has_missing_owned_drones("flagship"):
		return get_ore_upgrade_cost("drones", 0)
	return get_ore_upgrade_cost("drones", drone_level)

func get_click_output() -> int:
	var shared_output = get_effective_ship_upgrade_level("kradle", "output") + get_effective_ship_upgrade_level("drone_carrier", "output")
	var base_output = float(BASE_CLICK_OUTPUT + (click_output_level + shared_output) * CLICK_OUTPUT_PER_LEVEL)
	return max(0, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_MINING_CLICK_OUTPUT, base_output))))

func get_battle_click_damage() -> int:
	var damage = get_click_output()
	damage += int(get_effective_ship_upgrade_level("hammond", "salvo_bays"))
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_flagship_battle_click_bonus"):
		damage += int(game_state.get_flagship_battle_click_bonus())
	return max(0, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_BATTLE_CLICK_DAMAGE, float(damage)))))

func get_starburst_targeting_multiplier() -> float:
	return 1.0 + float(get_effective_ship_upgrade_level("starburst", "targeting_attack")) * 0.1

func get_starburst_contact_dps() -> float:
	return STARBURST_BASE_CONTACT_DPS * get_starburst_targeting_multiplier()

func get_starburst_click_bonus() -> int:
	return max(0, int(floor(get_effective_ship_upgrade_level("starburst", "salvo"))))

func get_starburst_tight_manoeuvres_level() -> float:
	return max(0.0, get_effective_ship_upgrade_level("starburst", "tight_manoeuvres"))

func get_starburst_attack_interval() -> float:
	return max(3.0, 10.0 - float(get_effective_ship_upgrade_level("starburst", "combat_engines")) * 0.5)

func get_jackal_dps() -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked("jackal"):
		return 0.0
	var damage = 2.0 + float(get_effective_ship_upgrade_level("jackal", "cohorts")) * 0.25
	damage *= 1.0 + float(get_effective_ship_upgrade_level("jackal", "strafe")) * 0.05
	return damage

func get_jackal_strafe_speed() -> float:
	var speed = 1.0 + float(get_effective_ship_upgrade_level("jackal", "strafe")) * 0.05
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("jackal_speed")) > 0:
		speed *= 1.5
	return speed

func get_jackal_recovery_per_second() -> float:
	var recovery = 1.0 + float(get_effective_ship_upgrade_level("jackal", "rations"))
	recovery *= 1.0 + float(get_effective_ship_upgrade_level("jackal", "stimpack")) * 0.05
	return recovery

func get_ravager_damage() -> int:
	return 10 + get_effective_ship_upgrade_level("ravager", "material") * 5

func get_ravager_interval() -> float:
	return max(2.0, 10.0 * pow(0.98, float(get_effective_ship_upgrade_level("ravager", "magnetic_lining"))))

func get_additional_battle_ships() -> Array[Dictionary]:
	var game_state = get_node_or_null("/root/GameState")
	var ships: Array[Dictionary] = []
	if game_state == null:
		return ships
	for ship_key in Catalog.get_ship_ids():
		if ship_key in ["refinery", "hammond", "drone_carrier", "gethica", "ambrossa"] or not game_state.is_ship_unlocked(ship_key):
			continue
		var max_hp = 100
		if ship_key == "jackal" and int(game_state.get_passive_level("jackal_plating")) > 0:
			max_hp = 125
		ships.append({"key": ship_key, "name": Catalog.get_display_name(ship_key), "category": Catalog.get_category(ship_key), "max_hp": max_hp})
	return ships

func get_extended_battle_stats() -> Dictionary:
	var game_state = get_node_or_null("/root/GameState")
	var starburst_unlocked = game_state and game_state.is_ship_unlocked("starburst")
	var ravager_unlocked = game_state and game_state.is_ship_unlocked("ravager")
	return {
		"additional_fleet_ships": get_additional_battle_ships(),
		"starburst_unlocked": starburst_unlocked,
		"starburst_damage": get_starburst_contact_dps(),
		"starburst_click_bonus": get_starburst_click_bonus(),
		"starburst_targeting_multiplier": get_starburst_targeting_multiplier(),
		"starburst_tight_manoeuvres": get_starburst_tight_manoeuvres_level(),
		"starburst_interval": get_starburst_attack_interval(),
		"starburst_opening": starburst_unlocked and int(game_state.get_passive_level("starburst_opening_salvo")) > 0,
		"starburst_return_run": starburst_unlocked and int(game_state.get_passive_level("starburst_return_run")) > 0,
		"brooder_last_effort": game_state and int(game_state.get_passive_level("brooder_last_effort")) > 0,
		"jackal_dps": get_jackal_dps(),
		"jackal_strafe_speed": get_jackal_strafe_speed(),
		"jackal_recovery_per_second": get_jackal_recovery_per_second(),
		"jackal_opening": game_state and game_state.is_ship_unlocked("jackal") and int(game_state.get_passive_level("jackal_opening_salvo")) > 0,
		"brooder_military_command": game_state and game_state.is_ship_unlocked("drone_carrier") and int(game_state.get_passive_level("brooder_military_command")) > 0,
		"ravager_unlocked": ravager_unlocked,
		"ravager_damage": get_ravager_damage(),
		"ravager_interval": get_ravager_interval(),
		"ravager_impact_ratio": float(get_effective_ship_upgrade_level("ravager", "impact_radius")) * 0.05,
		"ravager_siege": ravager_unlocked and int(game_state.get_passive_level("ravager_siege")) > 0,
		"ravager_cracking": ravager_unlocked and int(game_state.get_passive_level("ravager_cracking_rounds")) > 0,
		"ravager_polarised": ravager_unlocked and int(game_state.get_passive_level("ravager_polarised_material")) > 0
	}

func get_drone_battle_damage() -> float:
	var damage = resolve_ship_stat(&"mining_drone", ShipProfile.STAT_BATTLE_DAMAGE, float(get_mining_amount()))
	return max(0.0, damage * get_drone_reconfiguration_multiplier())

func get_drone_max_hp() -> int:
	var base_hp = 10.0
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_drone_max_hp"):
		base_hp = float(game_state.get_drone_max_hp())
	return max(1, int(round(resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MAX_HP, base_hp))))

func get_global_ore_multiplier() -> float:
	var game_state = get_node_or_null("/root/GameState")
	var multiplier = 1.0 + float(refining_level) * REFINING_BONUS_PER_LEVEL
	if game_state and game_state.is_ship_unlocked("nelson"):
		if int(game_state.get_passive_level("nelson_art_commission")) > 0:
			multiplier *= 1.0 + float(Catalog.get_ship_count_at_rank(int(game_state.prestige_level))) * 0.02
	return multiplier

func get_ship_ore_multiplier(ship_key: String) -> float:
	var multiplier = get_global_ore_multiplier()
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_ship_unlocked("refinery") and Catalog.get_category(ship_key) == "support":
		var furnace_bonus = float(get_effective_ship_upgrade_level("refinery", "furnace")) * ROMIUS_SUPPORT_INCOME_PER_LEVEL
		if int(game_state.get_passive_level("refinery_heavy_furnaces")) > 0:
			furnace_bonus *= 2.0
		multiplier *= 1.0 + furnace_bonus
	if game_state and game_state.is_ship_unlocked("nelson") and Catalog.get_category(ship_key) == "civilian":
		multiplier *= 1.0 + float(get_effective_ship_upgrade_level("nelson", "local_fm")) * 0.025
	if ship_key == "nelson" and nelson_practice_cycles > 0:
		multiplier *= 1.0 + float(nelson_practice_cycles) * 0.01
	if float(encore_ship_boost_timers.get(ship_key, 0.0)) > 0.0:
		multiplier *= MERLINDA_ENCORE_UNIT_MULTIPLIER
	return multiplier

func get_drone_reconfiguration_multiplier() -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_ship_unlocked("drone_carrier") and int(game_state.get_passive_level("brooder_drone_reconfiguration")) > 0:
		return 1.05
	return 1.0

func get_ore_cost_multiplier() -> float:
	return 1.0

func get_refinery_upgrade_level(stat_key: String) -> int:
	return get_ship_upgrade_level("refinery", stat_key)

func get_refinery_stat_value(stat_key: String):
	var ore_level = get_refinery_upgrade_level(stat_key)
	var base_value = 0.0
	var modifier_stat = StringName(stat_key)
	match stat_key:
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
			base_value = 0.0012 * float(get_effective_ship_upgrade_level("refinery", "furnace"))
			modifier_stat = ShipProfile.STAT_GLOBAL_INCOME_BONUS
	return resolve_ship_stat(&"refinery", modifier_stat, base_value)

func get_refinery_click_multiplier() -> float:
	return 1.0

func upgrade_refinery_stat(stat_key: String) -> bool:
	return upgrade_ship_stat("refinery", stat_key)

func get_click_rate_cap() -> float:
	var base_rate = float(BASE_CLICK_RATE_CAP + get_input_rate_level() * CLICK_RATE_CAP_PER_LEVEL)
	return max(1.0, resolve_ship_stat(&"flagship", ShipProfile.STAT_CLICK_RATE, base_rate))

func get_hold_click_rate() -> float:
	return min(get_click_rate_cap(), float(BASE_HOLD_CLICK_RATE + get_input_rate_level()))

func get_input_rate_level() -> int:
	var input_rate_level = click_multiplier_level
	input_rate_level += get_effective_ship_upgrade_level("kradle", "input_rate")
	input_rate_level += get_effective_ship_upgrade_level("drone_carrier", "input_rate")
	for ship_key in ["minotard", "tobias", "fruegal"]:
		input_rate_level += get_effective_ship_upgrade_level(ship_key, "input_rate")
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("brooder_cooperation")) > 0:
		input_rate_level += int(floor(float(get_active_companion_count()) / 10.0))
	return max(0, input_rate_level)

func get_active_companion_count() -> int:
	return get_active_drone_count() + get_fighter_drone_count() + racer_states.size()

func _try_consume_click(is_held: bool = false) -> bool:
	var now = float(Time.get_ticks_usec()) / 1000000.0
	var minimum_interval = 1.0 / max(1.0, get_click_rate_cap())
	if last_click_time >= 0.0 and now - last_click_time < minimum_interval:
		return false
	if is_held:
		var hold_interval = 1.0 / max(1.0, get_hold_click_rate())
		if last_hold_click_time >= 0.0 and now - last_hold_click_time < hold_interval:
			return false
		last_hold_click_time = now
	last_click_time = now
	return true

func get_speed() -> float:
	var speed = BASE_SPEED + speed_level * DRONE_SPEED_PER_LEVEL
	speed += float(get_effective_ship_upgrade_level("gethica", "drone_fc")) * 5.0
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_passive_level"):
		if int(game_state.get_passive_level("drone_ion_thrusts")) > 0:
			speed *= 3.0
	speed *= get_drone_reconfiguration_multiplier()
	return max(0.0, resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MOVE_SPEED, speed))

func _migrate_mining_ship_upgrades(ship_key: String, saved_levels: Dictionary) -> Dictionary:
	var levels = saved_levels.duplicate()
	if ship_key == "minotard" and not levels.has("input_rate") and levels.has("cargo_capacity"):
		levels["input_rate"] = levels["cargo_capacity"]
	if ship_key == "refinery" and not levels.has("reclamation") and levels.has("cycling"):
		levels["reclamation"] = levels["cycling"]
	if ship_key == "gethica":
		if not levels.has("spectrometer") and levels.has("spectrometer_alpha"):
			levels["spectrometer"] = levels["spectrometer_alpha"]
		if not levels.has("adjuster") and levels.has("fleet_adjuster"):
			levels["adjuster"] = levels["fleet_adjuster"]
	if ship_key == "hammond" and not levels.has("arming_sequences") and levels.has("arming_time"):
		levels["arming_sequences"] = levels["arming_time"]
	return levels

func get_ship_upgrade_level(ship_key: String, stat_key: String) -> int:
	if not ship_upgrade_levels.has(ship_key):
		return 0
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("is_ship_unlocked") and not game_state.is_ship_unlocked(ship_key):
		return 0
	return int(ship_upgrade_levels[ship_key].get(stat_key, 0))

func apply_dev_ship_toggle(ship_key: String, enabled: bool) -> void:
	ship_operation_positions.erase(ship_key)
	ship_operation_targets.erase(ship_key)
	ship_income_timers.erase(ship_key)
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		var drone_container = parent.get_node("Drones")
		if not enabled:
			for drone in drone_container.get_children():
				if str(drone.get("source_ship")) == ship_key:
					drone_container.remove_child(drone)
					drone.queue_free()
		else:
			var missing_drones = max(0, get_owned_drone_count(ship_key) - get_active_drone_count(ship_key))
			if missing_drones > 0:
				spawn_drones(missing_drones, ship_key)
	emit_signal("upgrades_changed")

func get_ship_upgrade_cap(ship_key: String, stat_key: String) -> int:
	return get_ore_upgrade_cap("%s_%s" % [ship_key, stat_key])

func get_effective_ship_levels(ship_key: String, added_stat: String = "") -> Dictionary:
	var purchased: Dictionary = ship_upgrade_levels.get(ship_key, {}).duplicate()
	if purchased.has(added_stat):
		purchased[added_stat] += 1
	var caps := {}
	for stat in purchased:
		caps[stat] = get_ship_upgrade_cap(ship_key, stat)
	return Overflow.resolve(ship_key, purchased, caps)

func get_effective_ship_upgrade_level(ship_key: String, stat_key: String) -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and not game_state.is_ship_unlocked(ship_key):
		return 0.0
	var purchased: Dictionary = ship_upgrade_levels.get(ship_key, {})
	var level = float(purchased.get(stat_key, 0.0))
	# Most ships never overflow; avoid resolving every upgrade on every frame.
	for key in purchased:
		if float(purchased[key]) > Overflow.hard_cap(ship_key, key):
			level = float(get_effective_ship_levels(ship_key).get(stat_key, 0.0))
			break
	# Craft and node counts accumulate fractional credit before creating a unit.
	if stat_key in ["participants", "dyson_capacity", "trader_capacity", "fighter_bays", "command_capacity", "drone_command_capacity", "vacuum_command_capacity", "matilda_array"]:
		return floor(level + 0.000001)
	return level

func get_ship_upgrade_gains(ship_key: String, stat_key: String) -> Dictionary:
	var before = get_effective_ship_levels(ship_key)
	var after = get_effective_ship_levels(ship_key, stat_key)
	var gains := {}
	for key in after:
		var gain = float(after[key]) - float(before[key])
		if gain > 0.000001:
			gains[key] = gain
	return gains

func get_ship_upgrade_warning(ship_key: String, stat_key: String) -> String:
	var cap = Overflow.hard_cap(ship_key, stat_key)
	var current = float(get_effective_ship_levels(ship_key).get(stat_key, 0.0))
	if current + 1.0 < cap:
		return ""
	var gains = get_ship_upgrade_gains(ship_key, stat_key)
	var recipients: Array[String] = []
	for key in gains:
		if key != stat_key:
			recipients.append("%s +%.3f levels" % [str(key).capitalize(), float(gains[key])])
	if gains.is_empty():
		return "Hard cap reached. All other upgrades are capped; purchase unavailable."
	if not recipients.is_empty():
		return "Hard cap reached or crossed. Overflow: %s. Cost includes receiving upgrades." % ", ".join(recipients)
	return "This purchase reaches the hard cap. Further levels will overflow into other available upgrades."

func get_ship_upgrade_cost(ship_key: String, stat_key: String, level: int = -1) -> int:
	if not ship_upgrade_levels.has(ship_key):
		return 0
	var base_cost = Catalog.get_ore_base_cost(ship_key, stat_key)
	if base_cost <= 0:
		return 0
	if level < 0:
		level = get_ship_upgrade_level(ship_key, stat_key)
	var cost = float(base_cost) * pow(ORE_COST_MULTIPLIER, float(level))
	if level == get_ship_upgrade_level(ship_key, stat_key):
		var effective = get_effective_ship_levels(ship_key)
		var gains = get_ship_upgrade_gains(ship_key, stat_key)
		var receiver_cost = 0.0
		for key in gains:
			receiver_cost += float(gains[key]) * Catalog.get_ore_base_cost(ship_key, key) * pow(ORE_COST_MULTIPLIER, float(effective[key]))
		cost = max(cost, receiver_cost)
	if ship_key == "merlinda" and stat_key == "participants":
		var sponsorship_level = get_companion_upgrade_level("racer", "sponsorship")
		cost *= max(MERLINDA_SPONSORSHIP_MIN_COST_MULTIPLIER, 1.0 - float(sponsorship_level) * MERLINDA_SPONSORSHIP_DISCOUNT_PER_LEVEL)
	var game_state = get_node_or_null("/root/GameState")
	if game_state and Catalog.get_category(ship_key) == "civilian" and int(game_state.get_passive_level("refinery_recycling")) > 0:
		cost *= 1.0 - ROMIUS_CIVILIAN_DISCOUNT
	return int(ceil(cost * get_ore_cost_multiplier()))

func upgrade_ship_stat(ship_key: String, stat_key: String) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked(ship_key) or not ship_upgrade_levels.has(ship_key):
		return false
	if not ship_upgrade_levels[ship_key].has(stat_key):
		return false
	var level = get_ship_upgrade_level(ship_key, stat_key)
	var adds_mining_drone = _get_ship_mining_drone_stat(ship_key) == stat_key
	var replacing_drone = adds_mining_drone and has_missing_owned_drones(ship_key)
	if not replacing_drone and level >= get_ship_upgrade_cap(ship_key, stat_key):
		return false
	if not replacing_drone and get_ship_upgrade_gains(ship_key, stat_key).is_empty():
		return false
	var notice = get_ship_upgrade_warning(ship_key, stat_key)
	var cost = get_ship_upgrade_cost(ship_key, stat_key, 0 if replacing_drone else level)
	if total_resources < cost:
		return false
	total_resources -= cost
	_record_purchase("%s %s" % [Catalog.get_display_name(ship_key), stat_key.replace("_", " ").capitalize()], cost)
	if not replacing_drone:
		ship_upgrade_levels[ship_key][stat_key] = level + 1
	if adds_mining_drone:
		spawn_drones(1, ship_key)
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	var parent = get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			configure_drone(drone)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	if not notice.is_empty():
		emit_signal("upgrade_notice", notice)
	return true

func get_companion_upgrade_level(companion_id: String, stat_key: String) -> int:
	if not companion_upgrade_levels.has(companion_id):
		return 0
	var game_state = get_node_or_null("/root/GameState")
	var required_ship = str(Catalog.get_companion_data(companion_id).get("required_ship", ""))
	if game_state and not required_ship.is_empty() and not game_state.is_ship_unlocked(required_ship):
		return 0
	return int(companion_upgrade_levels[companion_id].get(stat_key, 0))

func get_companion_upgrade_cap(companion_id: String, stat_key: String) -> int:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_upgrade_cap"):
		return int(game_state.get_upgrade_cap("%s_%s" % [companion_id, stat_key]))
	return MAX_UPGRADE_LEVEL

func get_companion_upgrade_cost(companion_id: String, stat_key: String, level: int = -1) -> int:
	if not companion_upgrade_levels.has(companion_id):
		return 0
	var base_cost = Catalog.get_companion_ore_base_cost(companion_id, stat_key)
	if base_cost <= 0:
		return 0
	if level < 0:
		level = get_companion_upgrade_level(companion_id, stat_key)
	return int(ceil(float(base_cost) * pow(ORE_COST_MULTIPLIER, float(level)) * get_ore_cost_multiplier()))

func upgrade_companion_stat(companion_id: String, stat_key: String) -> bool:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not companion_upgrade_levels.has(companion_id):
		return false
	var required_ship = str(Catalog.get_companion_data(companion_id).get("required_ship", ""))
	if not required_ship.is_empty() and not game_state.is_ship_unlocked(required_ship):
		return false
	if not companion_upgrade_levels[companion_id].has(stat_key):
		return false
	var level = get_companion_upgrade_level(companion_id, stat_key)
	if level >= get_companion_upgrade_cap(companion_id, stat_key):
		return false
	var cost = get_companion_upgrade_cost(companion_id, stat_key, level)
	if cost <= 0 or total_resources < cost:
		return false
	total_resources -= cost
	_record_purchase("%s %s" % [Catalog.get_companion_display_name(companion_id), stat_key.replace("_", " ").capitalize()], cost)
	companion_upgrade_levels[companion_id][stat_key] = level + 1
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func _get_ship_mining_drone_stat(ship_key: String) -> String:
	if ship_key in ["kradle", "drone_carrier"]:
		return "command_capacity"
	if ship_key == "fruegal":
		return "drone_command_capacity"
	return ""

func get_hammond_damage() -> float:
	var damage_per_shot = HAMMOND_BASE_DAMAGE + float(get_effective_ship_upgrade_level("hammond", "lori_cannons")) * 2.0
	return damage_per_shot * (1.0 + float(get_effective_ship_upgrade_level("hammond", "intensity")))

func get_hammond_max_hp() -> int:
	return 100

func get_hammond_damage_reduction() -> float:
	return 0.0

func get_hammond_interval() -> float:
	var interval = HAMMOND_BASE_INTERVAL * pow(0.98, float(get_effective_ship_upgrade_level("hammond", "arming_sequences")))
	interval /= 1.0 + float(get_effective_ship_upgrade_level("refinery", "shell_factory")) * ROMIUS_MILITARY_SPEED_PER_LEVEL
	return max(HAMMOND_MIN_INTERVAL, interval)

func get_fighter_drone_count() -> int:
	var count = get_effective_ship_upgrade_level("drone_carrier", "fighter_bays")
	var game_state = get_node_or_null("/root/GameState")
	if game_state and int(game_state.get_passive_level("hammond_fighter_bays")) > 0:
		count += 5
	if game_state and int(game_state.get_passive_level("brooder_readiness")) > 0:
		count = max(count, 1)
	return count

func get_fighter_drone_speed() -> float:
	return 1.4 * get_drone_reconfiguration_multiplier()

func get_fighter_drone_damage() -> float:
	return float(FIGHTER_DRONE_DAMAGE) * get_drone_reconfiguration_multiplier()

func get_ambrossa_income_amount() -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked("ambrossa"):
		return 0.0
	var workshops = get_effective_ship_upgrade_level("ambrossa", "workshops")
	var income = AMBROSSA_BASE_INCOME + float(workshops) * AMBROSSA_WORKSHOP_INCOME
	if int(game_state.get_passive_level("ambrossa_market_demands")) > 0:
		income *= 2.0
	return income * get_ship_ore_multiplier("ambrossa")

func get_ambrossa_income_interval() -> float:
	var reputation_level = get_effective_ship_upgrade_level("ambrossa", "trader_reputation")
	return max(AMBROSSA_MIN_INTERVAL, AMBROSSA_BASE_INTERVAL * pow(1.0 - AMBROSSA_REPUTATION_REDUCTION, float(reputation_level)))

func get_ambrossa_countdown() -> float:
	if ambrossa_rest_timer > 0.0:
		return ambrossa_rest_timer
	return max(0.0, get_ambrossa_income_interval() - ambrossa_income_timer)

func get_flagship_speed() -> float:
	var speed = BASE_FLAGSHIP_SPEED + flagship_speed_level * FLAGSHIP_SPEED_PER_LEVEL
	speed += float(get_effective_ship_upgrade_level("gethica", "local_sfc")) * 10.0
	speed += float(get_effective_ship_upgrade_level("parallax", "coordinator")) * 2.0
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_flagship_speed_multiplier"):
		speed *= float(game_state.get_flagship_speed_multiplier())
	if float(encore_ship_boost_timers.get("flagship", 0.0)) > 0.0:
		speed *= MERLINDA_ENCORE_UNIT_MULTIPLIER
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
	if game_state and game_state.has_method("get_passive_level") and int(game_state.get_passive_level("drone_mining_lasers")) > 0:
		amount *= 2
	return max(0, int(round(resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MINING_AMOUNT, float(amount)))))

func get_mining_speed() -> float:
	var base_speed = BASE_MINING_SPEED + mining_speed_level * MINING_SPEED_PER_LEVEL
	base_speed *= get_drone_reconfiguration_multiplier()
	return max(0.1, resolve_ship_stat(&"mining_drone", ShipProfile.STAT_MINING_SPEED, base_speed))

func get_mining_interval() -> float:
	return 1.0 / max(0.1, get_mining_speed())

func get_drone_mining_interval_at(world_position: Vector2) -> float:
	var mining_speed = get_mining_speed()
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_ship_unlocked("atlas") and world_position.distance_to(get_ship_world_position("atlas")) <= 2000.0:
		mining_speed *= 1.0 + float(get_effective_ship_upgrade_level("atlas", "industrial_link")) * 0.10
	if game_state and game_state.is_ship_unlocked("parallax") and world_position.distance_to(get_ship_world_position("parallax")) <= 2000.0:
		mining_speed *= 1.0 + float(get_effective_ship_upgrade_level("parallax", "booster")) * 0.02
	return 1.0 / max(0.1, mining_speed)

func get_refining_multiplier() -> float:
	return 1.0 + float(refining_level) * REFINING_BONUS_PER_LEVEL

func get_capacity() -> int:
	var base_capacity = float(BASE_CAPACITY + capacity_level * CARRY_CAPACITY_PER_LEVEL + get_effective_ship_upgrade_level("atlas", "storage_bins") * 10)
	base_capacity *= get_drone_reconfiguration_multiplier()
	return max(0, int(round(resolve_ship_stat(&"mining_drone", ShipProfile.STAT_CARRY_CAPACITY, base_capacity))))

func configure_drone(drone: Node) -> void:
	if drone == null:
		return
	drone.speed = get_speed()
	drone.outbound_speed_multiplier = 1.0 + float(get_effective_ship_upgrade_level("drone_carrier", "acceleration")) * 0.005
	drone.mining_amount = get_mining_amount()
	drone.mine_interval = get_mining_interval()
	drone.mining_reward_multiplier = get_global_ore_multiplier() * get_drone_reconfiguration_multiplier()
	drone.carry_capacity = get_capacity()

func get_drone_deposit_position(drone_position: Vector2) -> Vector2:
	var flagship_position = flotilla.position if flotilla and is_instance_valid(flotilla) else FLEET_START_POSITION
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_ship_unlocked("atlas"):
		var atlas_position = get_ship_world_position("atlas")
		if drone_position.distance_to(atlas_position) < drone_position.distance_to(flagship_position):
			return atlas_position
	return flagship_position

func should_drone_deposit_before_target(drone_position: Vector2, target_position: Vector2) -> bool:
	var deposit_position = get_drone_deposit_position(drone_position)
	var closest_point = Geometry2D.get_closest_point_to_segment(deposit_position, drone_position, target_position)
	return deposit_position.distance_to(closest_point) <= 1000.0

func get_drone_deposit_radius(deposit_position: Vector2) -> float:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_ship_unlocked("atlas") and deposit_position.distance_to(get_ship_world_position("atlas")) <= 1.0:
		return 300.0 if int(game_state.get_passive_level("atlas_calculated_ejector")) > 0 else 24.0
	return 16.0

func deposit_drone_cargo(amount: float, origin: Vector2 = Vector2.INF) -> void:
	if amount > 0.0:
		add_resources(amount, "mining_drones", origin)

func regenerate_asteroid_field(count: int = -1) -> void:
	var parent = get_parent()
	if not parent.has_node("Asteroids"):
		return
	var container = parent.get_node("Asteroids")
	next_stage_timer = -1.0
	asteroid_field_level += 1
	_roll_field_name()
	_reset_merlinda_race(true)
	for asteroid in container.get_children():
		asteroid.free()
	asteroid_priority.clear()
	spawn_sun()
	spawn_planets()
	spawn_asteroids(count)
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_ship_unlocked("elysium_air"):
		var monolith_income = get_effective_ship_upgrade_level("elysium_air", "monolith") * 5000
		if monolith_income > 0:
			add_resources(float(monolith_income) * get_ship_ore_multiplier("elysium_air"), "elysium_air")
	if game_state and int(game_state.get_passive_level("nelson_concerts")) > 0:
		add_resources(1000.0 * get_ship_ore_multiplier("nelson"), "nelson_concert")
	_autosave_new_field()

func _autosave_new_field() -> void:
	if not autosave_enabled:
		return
	if save_game():
		emit_signal("upgrade_notice", "New field entered - game autosaved")
	else:
		push_warning("New field generated, but autosave failed")

func get_ship_world_position(ship_key: String) -> Vector2:
	if ship_operation_positions.has(ship_key):
		return ship_operation_positions[ship_key]
	return _get_ship_formation_position(ship_key)

func get_visual_subcraft() -> Array[Dictionary]:
	var visuals: Array[Dictionary] = []
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return visuals
	var drone_multiplier = get_drone_reconfiguration_multiplier()
	if game_state.is_ship_unlocked("drone_carrier"):
		var fighter_count = min(24, get_fighter_drone_count())
		var carrier_position = get_ship_world_position("drone_carrier")
		for index in range(fighter_count):
			var angle = ship_animation_time * 0.8 * drone_multiplier + TAU * float(index) / max(1.0, float(fighter_count))
			visuals.append({"position": carrier_position + Vector2(cos(angle), sin(angle)) * 190.0, "color": Color("ff8d78"), "radius": 42.0, "kind": "fighter"})
	if game_state.is_ship_unlocked("tobias"):
		var vacuum_count = (5 if int(game_state.get_passive_level("tobias_vacuum_drone_bays")) > 0 else 0) + get_effective_ship_upgrade_level("boschore", "vacuum_command_capacity")
		var tobias_position = get_ship_world_position("tobias")
		for index in range(min(24, vacuum_count)):
			var angle = -ship_animation_time * 0.65 * drone_multiplier + TAU * float(index) / max(1.0, float(vacuum_count))
			visuals.append({"position": tobias_position + Vector2(cos(angle), sin(angle)) * 150.0, "color": Color("78d8ef"), "radius": 38.0, "kind": "vacuum"})
	if game_state.is_ship_unlocked("merlinda"):
		var merlinda_position = get_ship_world_position("merlinda")
		for racer in racer_states:
			if float(racer.get("disabled_timer", 0.0)) > 0.0:
				continue
			visuals.append({"position": racer.get("position", merlinda_position), "direction": racer.get("direction", Vector2.RIGHT), "speed_stat": racer.get("base_speed", 250.0), "color": Color("f4d06f"), "radius": 45.0, "kind": "racer"})
	if game_state.is_ship_unlocked("stapledon"):
		var dyson_count = min(24, get_effective_ship_upgrade_level("stapledon", "dyson_capacity"))
		var sun_position = _get_sun_world_position()
		for index in range(dyson_count):
			var angle = ship_animation_time * 0.35 * drone_multiplier + TAU * float(index) / max(1.0, float(dyson_count))
			visuals.append({"position": sun_position + Vector2(cos(angle), sin(angle)) * 1200.0, "color": Color("ffe28a"), "radius": 48.0, "kind": "dyson"})
	var trader_count = 0
	if game_state.is_ship_unlocked("tarrip"):
		trader_count += get_effective_ship_upgrade_level("tarrip", "trader_capacity")
	if game_state.is_ship_unlocked("elysium_air"):
		trader_count += get_effective_ship_upgrade_level("elysium_air", "trader_capacity")
	var unlocked_positions: Array[Vector2] = []
	for ship_key in Catalog.get_ship_ids():
		if game_state.is_ship_unlocked(ship_key):
			unlocked_positions.append(get_ship_world_position(ship_key))
	if unlocked_positions.size() >= 2:
		for index in range(min(24, trader_count)):
			var from_index = index % unlocked_positions.size()
			var to_index = (from_index + 1 + int(index / unlocked_positions.size())) % unlocked_positions.size()
			var progress = fmod(ship_animation_time * 0.16 * drone_multiplier + float(index) * 0.17, 1.0)
			visuals.append({"position": unlocked_positions[from_index].lerp(unlocked_positions[to_index], progress), "color": Color("f6c85f"), "radius": 36.0, "kind": "trader"})
	if game_state.is_ship_unlocked("elysium_air") and is_elysium_visitor_active():
		var visitor_offset = Vector2(900.0 + sin(ship_animation_time) * 180.0, -700.0)
		var elysium_position = get_ship_world_position("elysium_air")
		visuals.append({"position": elysium_position + visitor_offset, "color": Color("75f0d0"), "radius": 90.0, "kind": "visitor"})
	return visuals

func _get_sun_world_position() -> Vector2:
	var parent = get_parent()
	if parent and parent.has_node("Asteroids"):
		var sun = parent.get_node("Asteroids").get_node_or_null("Sun") as Node2D
		if sun:
			return sun.position
	return Vector2.ZERO

func _get_drone_launch_position(ship_key: String, launch_index: int) -> Vector2:
	var ship_position = get_ship_world_position(ship_key)
	var sun_position = _get_sun_world_position()
	var launch_direction = ship_position - sun_position
	if launch_direction.length() < MIN_LAUNCH_DIRECTION_LENGTH:
		launch_direction = Vector2.RIGHT
	launch_direction = launch_direction.normalized()
	var tangent = Vector2(-launch_direction.y, launch_direction.x)
	var spread_slot = float((launch_index % 5) - 2)
	var launch_position = ship_position + launch_direction * DRONE_LAUNCH_DISTANCE
	launch_position += tangent * spread_slot * DRONE_LAUNCH_SPREAD
	var from_sun = launch_position - sun_position
	if from_sun.length() < DRONE_SUN_CLEARANCE:
		var safe_direction = from_sun.normalized() if from_sun.length() >= MIN_LAUNCH_DIRECTION_LENGTH else Vector2.RIGHT
		launch_position = sun_position + safe_direction * DRONE_SUN_CLEARANCE
	return launch_position

func spawn_drones(count: int, source_ship: String = "flagship") -> void:
	var container = null
	if get_parent().has_node("Drones"):
		container = get_parent().get_node("Drones")
	if container == null:
		return
	for i in range(count):
		var d = drone_scene.instantiate()
		d.source_ship = source_ship
		d.position = _get_drone_launch_position(source_ship, i)
		container.add_child(d)
		d.add_to_group("drones")
		configure_drone(d)

func spawn_owned_drones(count: int) -> void:
	var remaining = min(max(0, count), get_owned_drone_count())
	var ownership = [["flagship", drone_level]]
	for ship_key in Catalog.get_ship_ids():
		var ship_capacity = _get_ship_mining_drone_capacity(ship_key)
		if ship_capacity > 0:
			ownership.append([ship_key, ship_capacity])
	for allocation in ownership:
		if remaining <= 0:
			break
		var allocation_count = min(remaining, max(0, int(allocation[1])))
		if allocation_count > 0:
			spawn_drones(allocation_count, str(allocation[0]))
			remaining -= allocation_count
	if remaining > 0:
		spawn_drones(remaining, "flagship")

func get_ore_upgrade_cost(upgrade: String, level: int = -1) -> int:
	if level < 0:
		level = drone_level if upgrade == "drones" else int(get("%s_level" % upgrade))
	return _upgrade_cost(upgrade, level)

func _upgrade_cost(upgrade: String, level: int) -> int:
	var base_cost = int(ORE_UPGRADE_BASE_COSTS.get(upgrade, 50))
	return int(ceil(float(base_cost) * pow(ORE_COST_MULTIPLIER, float(level)) * get_ore_cost_multiplier()))

func _buy_upgrade(upgrade: String) -> bool:
	var level = int(get(upgrade + "_level"))
	if level >= get_ore_upgrade_cap(upgrade):
		return false
	var cost = get_ore_upgrade_cost(upgrade, level)
	if total_resources < cost:
		return false
	total_resources -= cost
	_record_purchase(upgrade.replace("_", " ").capitalize(), cost)
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

func upgrade_refining() -> bool:
	return _buy_upgrade("refining")

func upgrade_capacity() -> bool:
	return _buy_upgrade("capacity")

func buy_drone() -> bool:
	if has_missing_owned_drones("flagship"):
		var replacement_cost = get_ore_upgrade_cost("drones", 0)
		if total_resources < replacement_cost:
			return false
		total_resources -= replacement_cost
		_record_purchase("Replacement mining drone", replacement_cost)
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
	_record_purchase("Flagship mining drone", cost)
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	drone_level += 1
	spawn_drones(1)
	emit_signal("resource_changed", total_resources)
	emit_signal("upgrades_changed")
	return true

func _on_flotilla_deposited(amount, gained: float = 0.0):
	var processed_gain = _apply_romius_income_systems(gained)
	total_resources = float(amount) + (processed_gain - gained)
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	_record_income("mining_drones", processed_gain)
	emit_signal("resource_changed", total_resources)

func add_resources(amount: float, source: String = "other", origin: Vector2 = Vector2.INF) -> void:
	if amount <= 0.0:
		return
	if (not is_finite(origin.x) or not is_finite(origin.y)) and not Catalog.get_ship_data(source).is_empty():
		origin = get_ship_world_position(source)
	amount = _apply_atlas_optimizer(amount, origin)
	var processed_amount = _apply_romius_income_systems(amount)
	total_resources += processed_amount
	_record_income(source, processed_amount)
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	emit_signal("resource_changed", total_resources)

func click_mine(asteroid, is_held: bool = false, bypass_rate_limit: bool = false) -> float:
	if asteroid == null or not is_instance_valid(asteroid):
		return 0
	if int(asteroid.resource_amount) <= 0:
		return 0
	if not can_mine_resource_node(asteroid):
		return 0
	if not is_asteroid_in_mining_range(asteroid):
		approach_asteroid(asteroid)
		return 0
	if not bypass_rate_limit and not _try_consume_click(is_held):
		return 0
	var harvested = asteroid.mine(get_click_output())
	if harvested <= 0:
		return 0
	var gained = float(harvested) * get_refinery_click_multiplier() * get_ship_ore_multiplier("flagship")
	gained = _apply_atlas_optimizer(gained, asteroid.position)
	gained = _apply_romius_income_systems(gained)
	total_resources += gained
	_record_income("click_mining", gained)
	if flotilla and is_instance_valid(flotilla):
		flotilla.storage = total_resources
	emit_signal("resource_changed", total_resources)
	return gained

func _apply_atlas_optimizer(amount: float, origin: Vector2) -> float:
	if amount <= 0.0 or not is_finite(origin.x) or not is_finite(origin.y):
		return amount
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked("atlas"):
		return amount
	var optimizer_level = get_effective_ship_upgrade_level("atlas", "optimizer_lens")
	if optimizer_level > 0 and origin.distance_to(get_ship_world_position("atlas")) <= _get_ship_work_range("atlas"):
		return amount * (1.0 + float(optimizer_level))
	return amount

func _apply_romius_income_systems(amount: float) -> float:
	if amount <= 0.0:
		return amount
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_ship_unlocked("refinery"):
		return amount
	var bonus = 0.0
	if int(game_state.get_passive_level("refinery_waste_processes")) > 0:
		bonus += amount * 0.025
	romius_cycle_progress += amount
	var completed_cycles = int(floor(romius_cycle_progress / 1000.0))
	if completed_cycles > 0:
		romius_cycle_progress -= float(completed_cycles) * 1000.0
		bonus += float(completed_cycles * get_effective_ship_upgrade_level("refinery", "reclamation") * 100)
	return amount + bonus

func set_asteroid_priority(ast, delta: int) -> void:
	if ast == null or not is_instance_valid(ast):
		return
	var key = str(ast.get_instance_id())
	var cur = 0
	if asteroid_priority.has(key):
		cur = int(asteroid_priority[key])
	cur += delta
	asteroid_priority[key] = cur

func get_asteroid_priority(ast) -> int:
	if ast == null or not is_instance_valid(ast):
		return 0
	var key = str(ast.get_instance_id())
	return int(asteroid_priority.get(key, 0))

func split_drones_across_asteroids() -> int:
	var parent = get_parent()
	if not parent.has_node("Asteroids") or not parent.has_node("Drones"):
		return 0
	var asteroids = parent.get_node("Asteroids").get_children()
	var drones = parent.get_node("Drones").get_children()
	asteroids = asteroids.filter(func(asteroid): return _is_valid_mining_target(asteroid))
	if asteroids.is_empty():
		return 0
	var assigned = 0
	for index in range(drones.size()):
		var drone = drones[index]
		if drone.has_method("assign_target"):
			drone.assign_target(asteroids[index % asteroids.size()], false)
			assigned += 1
	return assigned

func lock_drone_focus(preferred_target = null) -> Node:
	var target = preferred_target
	if not _is_valid_mining_target(target):
		var origin = flotilla.position if flotilla and is_instance_valid(flotilla) else Vector2.ZERO
		var parent = get_parent()
		if parent == null or not parent.has_node("Asteroids"):
			return null
		target = _get_closest_asteroid_for_assignment(origin, parent.get_node("Asteroids"), false)
	if target == null:
		return null
	approach_asteroid(target)
	command_send_drones_to(target)
	return target

func get_best_asteroid_for(pos: Vector2, distribute_targets: bool = false) -> Node:
	var parent = get_parent()
	if not parent.has_node("Asteroids"):
		return null
	var ast_container = parent.get_node("Asteroids")
	if distribute_targets:
		var assigned_targets = _get_drone_assignment_snapshot()
		var closest_unassigned = _get_closest_asteroid_for_assignment(pos, ast_container, true, true, assigned_targets)
		if closest_unassigned:
			assigned_targets[closest_unassigned.get_instance_id()] = true
			return closest_unassigned
		var closest_available = _get_closest_asteroid_for_assignment(pos, ast_container, false, true)
		if closest_available:
			return closest_available
		return _get_closest_asteroid_for_assignment(pos, ast_container, false, false)
	var best = null
	var best_score = -1e9
	for a in ast_container.get_children():
		if not is_instance_valid(a):
			continue
		if not _is_valid_mining_target(a):
			continue
		if _is_reserved_mining_target(a):
			continue
		var pr = get_asteroid_priority(a)
		var score = pr * 1000 - int(pos.distance_to(a.position))
		if score > best_score:
			best_score = score
			best = a
	return best if best != null else _get_closest_asteroid_for_assignment(pos, ast_container, false, false)

func _get_drone_assignment_snapshot() -> Dictionary:
	var physics_frame = Engine.get_physics_frames()
	if drone_assignment_cache_frame == physics_frame:
		return drone_assignment_cache
	drone_assignment_cache_frame = physics_frame
	drone_assignment_cache.clear()
	var parent = get_parent()
	if parent == null or not parent.has_node("Drones"):
		return drone_assignment_cache
	for drone in parent.get_node("Drones").get_children():
		if not is_instance_valid(drone):
			continue
		var target = drone.target_asteroid
		if is_instance_valid(target) and int(drone.state) in [1, 2]:
			drone_assignment_cache[target.get_instance_id()] = true
	return drone_assignment_cache

func _get_closest_asteroid_for_assignment(pos: Vector2, ast_container: Node, require_unassigned: bool, skip_reserved: bool = false, assigned_targets = null) -> Node:
	var best = null
	var best_distance = INF
	for asteroid in ast_container.get_children():
		if not is_instance_valid(asteroid):
			continue
		if not _is_valid_mining_target(asteroid):
			continue
		if skip_reserved and _is_reserved_mining_target(asteroid):
			continue
		if require_unassigned:
			var is_assigned = assigned_targets.has(asteroid.get_instance_id()) if assigned_targets is Dictionary else _get_assigned_drone_count(asteroid) > 0
			if is_assigned:
				continue
		var distance = pos.distance_to(asteroid.position)
		if distance < best_distance:
			best_distance = distance
			best = asteroid
	return best

func _is_reserved_mining_target(asteroid: Node) -> bool:
	var minotard_target = ship_operation_targets.get("minotard")
	return minotard_target != null and is_instance_valid(minotard_target) and minotard_target == asteroid

func _get_assigned_drone_count(asteroid: Node) -> int:
	var parent = get_parent()
	if parent == null or not parent.has_node("Drones"):
		return 0
	var assigned_count = 0
	for drone in parent.get_node("Drones").get_children():
		if drone.target_asteroid == asteroid and int(drone.state) in [1, 2]:
			assigned_count += 1
	return assigned_count

func save_game() -> bool:
	var parent = get_parent()
	var ast_container = parent.get_node("Asteroids")
	var drone_container = parent.get_node("Drones")

	var state = {
		"flotilla": {"storage": flotilla.storage if flotilla else 0, "position": [flotilla.position.x, flotilla.position.y] if flotilla else [0,0]},
		"upgrades": {"click_output": click_output_level, "click_multiplier": click_multiplier_level, "speed": speed_level, "mining": mining_level, "mining_speed": mining_speed_level, "refining": refining_level, "capacity": capacity_level, "drones": drone_level, "flagship_speed": flagship_speed_level},
		"refinery_upgrades": refinery_upgrade_levels.duplicate(true),
		"ship_upgrades": ship_upgrade_levels.duplicate(true),
		"companion_upgrades": companion_upgrade_levels.duplicate(true),
		"autobuy_upgrade_enabled": autobuy_upgrade_enabled.duplicate(true),
		"asteroid_field_level": asteroid_field_level,
		"current_field_name": current_field_name,
		"recent_field_names": recent_field_names.duplicate(),
		"flagship_readiness_bonus_active": flagship_readiness_bonus_active,
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
		state["asteroids"].append({
			"pos": [a.position.x, a.position.y],
			"resource_amount": a.resource_amount,
			"max_resource_amount": a.max_resource_amount,
			"is_planet": a.is_in_group("planet"),
			"is_first_field_planet": bool(a.get_meta("first_field_planet", false)),
			"bonus_resource_node": bool(a.get_meta("bonus_resource_node", false)),
			"resource_type": str(a.get_meta("resource_type", "")),
			"resource_display_name": str(a.get_meta("resource_display_name", "")),
			"required_ship": str(a.get_meta("required_ship", ""))
		})

	var drones = drone_container.get_children()
	for d in drones:
		var target_index = -1
		if d.target_asteroid != null and is_instance_valid(d.target_asteroid):
			target_index = ast_list.find(d.target_asteroid)
		var focus_target_index = -1
		if d.focused_target != null and is_instance_valid(d.focused_target):
			focus_target_index = ast_list.find(d.focused_target)
		state["drones"].append({"pos": [d.position.x, d.position.y], "carry": d.carry, "state": int(d.state), "source_ship": d.source_ship, "target_index": target_index, "focus_target_index": focus_target_index})

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open %s for saving" % save_path)
		return false
	file.store_var(state)
	file.close()
	print("Saved game to %s" % save_path)
	return true

func command_send_drones_to(target_asteroid) -> void:
	if not _is_valid_mining_target(target_asteroid):
		return
	var parent = get_parent()
	if not parent.has_node("Drones"):
		return
	var drone_container = parent.get_node("Drones")
	for d in drone_container.get_children():
		if d.has_method("assign_target"):
			d.assign_target(target_asteroid, true)

func load_game() -> bool:
	var parent = get_parent()
	var ast_container = parent.get_node("Asteroids")
	var drone_container = parent.get_node("Drones")

	if not FileAccess.file_exists(save_path):
		print("No save file found at %s" % save_path)
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("Could not open %s for loading" % save_path)
		return false
	var state = file.get_var()
	file.close()
	income_events.clear()
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("apply_save_state"):
		game_state.apply_save_state(state.get("research", {}))
	var saved_flotilla = state.get("flotilla", {})
	var saved_upgrades = state.get("upgrades", {})
	asteroid_field_level = int(state.get("asteroid_field_level", 0))
	current_field_name = str(state.get("current_field_name", current_field_name))
	recent_field_names.assign(state.get("recent_field_names", recent_field_names))
	flagship_readiness_bonus_active = bool(state.get("flagship_readiness_bonus_active", false))
	autobuy_upgrade_enabled = state.get("autobuy_upgrade_enabled", {}).duplicate(true)
	click_output_level = int(saved_upgrades.get("click_output", 0))
	click_multiplier_level = int(saved_upgrades.get("click_multiplier", 0))
	flagship_speed_level = int(saved_upgrades.get("flagship_speed", 0))
	configure_flagship()
	speed_level = int(saved_upgrades.get("speed", 0))
	mining_level = int(saved_upgrades.get("mining", 0))
	mining_speed_level = int(saved_upgrades.get("mining_speed", 0))
	refining_level = int(saved_upgrades.get("refining", saved_upgrades.get("drone_multiplier", 0)))
	capacity_level = int(saved_upgrades.get("capacity", 0))
	drone_level = int(saved_upgrades.get("drones", 0))
	var saved_refinery_upgrades: Dictionary = state.get("refinery_upgrades", {})
	for stat_key in refinery_upgrade_levels:
		refinery_upgrade_levels[stat_key] = max(0, int(saved_refinery_upgrades.get(stat_key, 0)))
	var saved_ship_upgrades: Dictionary = state.get("ship_upgrades", {})
	for ship_key in ship_upgrade_levels:
		var saved_levels: Dictionary = saved_ship_upgrades.get(ship_key, {})
		saved_levels = _migrate_mining_ship_upgrades(ship_key, saved_levels)
		for stat_key in ship_upgrade_levels[ship_key]:
			ship_upgrade_levels[ship_key][stat_key] = max(0, int(saved_levels.get(stat_key, 0)))
	var saved_companion_upgrades: Dictionary = state.get("companion_upgrades", {})
	for companion_id in companion_upgrade_levels:
		var saved_levels: Dictionary = saved_companion_upgrades.get(companion_id, {})
		for stat_key in companion_upgrade_levels[companion_id]:
			companion_upgrade_levels[companion_id][stat_key] = max(0, int(saved_levels.get(stat_key, 0)))
	if flotilla and saved_flotilla.has("storage"):
		flotilla.storage = float(saved_flotilla["storage"])
		total_resources = flotilla.storage
		emit_signal("resource_changed", total_resources)
	if flotilla and saved_flotilla.has("position"):
		var saved_position = saved_flotilla["position"]
		flotilla.position = Vector2(float(saved_position[0]), float(saved_position[1]))
		if flotilla.has_method("reset_visual_interpolation"):
			flotilla.reset_visual_interpolation()

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
		var is_first_field_planet = bool(adata.get("is_first_field_planet", false))
		if not adata.has("is_first_field_planet") and asteroid_field_level == 0 and bool(adata.get("is_planet", false)):
			is_first_field_planet = a.position.is_equal_approx(FIRST_FIELD_PLANET_POSITION) and a.max_resource_amount == 1000
		a.set_meta("first_field_planet", is_first_field_planet)
		a.set_meta("bonus_resource_node", bool(adata.get("bonus_resource_node", is_first_field_planet)))
		a.set_meta("resource_type", str(adata.get("resource_type", "")))
		a.set_meta("resource_display_name", str(adata.get("resource_display_name", "")))
		a.set_meta("required_ship", str(adata.get("required_ship", "")))
		a.add_to_group("asteroids")
		if not str(a.get_meta("resource_type", "")).is_empty():
			a.add_to_group("special_resource")
		if adata.get("is_planet", false):
			a.name = "TutorialPlanet" if is_first_field_planet else "Planet"
			a.add_to_group("planet")
		ast_nodes.append(a)
	spawn_sun()

	for ddata in state.get("drones", []):
		var d = drone_scene.instantiate()
		var source_ship = str(ddata.get("source_ship", "flagship"))
		if source_ship == "refinery":
			d.free()
			continue
		d.source_ship = source_ship
		d.position = Vector2(ddata["pos"][0], ddata["pos"][1])
		drone_container.add_child(d)
		d.carry = float(ddata.get("carry", 0.0))
		d.state = int(ddata.get("state", 0))
		var tindex = int(ddata.get("target_index", -1))
		if tindex >= 0 and tindex < ast_nodes.size():
			d.target_asteroid = ast_nodes[tindex]
		var focus_index = int(ddata.get("focus_target_index", -1))
		if focus_index >= 0 and focus_index < ast_nodes.size():
			d.focused_target = ast_nodes[focus_index]
		d.add_to_group("drones")
		configure_drone(d)

	if flotilla and state.has("flotilla"):
		flotilla.storage = float(state["flotilla"].get("storage", 0.0))
		total_resources = flotilla.storage
		emit_signal("resource_changed", total_resources)

	print("Loaded game from %s" % save_path)
	return true
