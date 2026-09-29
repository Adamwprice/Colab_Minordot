extends Node2D

enum State { IDLE, TO_ASTEROID, MINING, TO_FLOTILLA }
const MINING_INTERVAL_REFRESH := 0.1
const TARGET_SEARCH_INTERVAL := 0.2

var state = State.IDLE

@export var ship_profile: ShipProfile

var speed: float = 50.0
var outbound_speed_multiplier: float = 1.0
var carry_capacity: int = 10
var mining_amount: int = 1
var carry: float = 0.0
var mining_reward_multiplier: float = 1.0
var mine_timer: float = 0.0 
var mine_interval: float = 1 # seconds between mine ticks

var target_asteroid: Node = null
var focused_target: Node = null
var flotilla: Node = null
var source_ship: String = "flagship"
var resource_manager: Node = null
var active_mine_interval: float = 1.0
var mining_interval_refresh_elapsed: float = MINING_INTERVAL_REFRESH
var previous_position := Vector2.ZERO
var target_search_timer := 0.0

func _ready() -> void:
	set_physics_process(true)
	mine_timer = 0.0
	resource_manager = _find_resource_manager()
	previous_position = position

func _physics_process(delta):
	previous_position = position
	if state == State.IDLE:
		target_search_timer -= delta
		if target_search_timer <= 0.0:
			find_target()
	elif state == State.TO_ASTEROID:
		if not is_instance_valid(target_asteroid):
			_retarget_after_depletion()
			return
		move_toward_target(target_asteroid.global_position, delta, outbound_speed_multiplier)
		if position.distance_to(target_asteroid.global_position) < 12:
			state = State.MINING
			mine_timer = 0.0
			mining_interval_refresh_elapsed = MINING_INTERVAL_REFRESH
	elif state == State.MINING:
		if not is_instance_valid(target_asteroid):
			_retarget_after_depletion()
			return
		var rm = _get_resource_manager()
		mining_interval_refresh_elapsed += delta
		if mining_interval_refresh_elapsed >= MINING_INTERVAL_REFRESH:
			mining_interval_refresh_elapsed = fmod(mining_interval_refresh_elapsed, MINING_INTERVAL_REFRESH)
			active_mine_interval = mine_interval
			if rm and rm.has_method("get_drone_mining_interval_at"):
				active_mine_interval = float(rm.get_drone_mining_interval_at(global_position))
			active_mine_interval /= _get_encore_multiplier()
		mine_timer += delta
		if mine_timer >= active_mine_interval:
			mine_timer = 0.0
			var space_left = max(0, int(floor(float(carry_capacity) - carry)))
			if space_left <= 0:
				_go_to_flotilla()
				return
			var boosted_mining_amount = int(ceil(float(mining_amount) * _get_encore_multiplier()))
			var harvested = target_asteroid.mine(min(boosted_mining_amount, space_left))
			carry += float(harvested)
			if carry >= carry_capacity:
				_go_to_flotilla()
			elif harvested <= 0:
				_retarget_after_depletion()
	elif state == State.TO_FLOTILLA and is_instance_valid(flotilla):
		var deposit_position = flotilla.global_position
		var deposit_radius = 16.0
		var rm = _get_resource_manager()
		if rm and rm.has_method("get_drone_deposit_position"):
			deposit_position = rm.get_drone_deposit_position(global_position)
			deposit_radius = float(rm.get_drone_deposit_radius(deposit_position))
		move_toward_target(deposit_position, delta)
		if global_position.distance_to(deposit_position) < deposit_radius:
			if rm and rm.has_method("deposit_drone_cargo"):
				rm.deposit_drone_cargo(carry * mining_reward_multiplier, global_position)
			else:
				flotilla.deposit(carry * mining_reward_multiplier)
			carry = 0
			state = State.IDLE
			target_search_timer = 0.0
	else:
		state = State.IDLE

func move_toward_target(target_pos: Vector2, delta: float, speed_multiplier: float = 1.0) -> void:
	var encore_multiplier = _get_encore_multiplier()
	var travel_distance = max(0.0, speed * speed_multiplier * encore_multiplier * delta)
	position = position.move_toward(target_pos, travel_distance)

func _get_encore_multiplier() -> float:
	if int(get_meta("merlinda_encore_until_msec", 0)) > Time.get_ticks_msec():
		return float(get_meta("merlinda_encore_multiplier", 1.0))
	return 1.0

func get_visual_position() -> Vector2:
	return previous_position.lerp(position, Engine.get_physics_interpolation_fraction())

func _get_resource_manager() -> Node:
	if is_instance_valid(resource_manager):
		return resource_manager
	resource_manager = _find_resource_manager()
	return resource_manager

func _find_resource_manager() -> Node:
	var cur_scene = get_tree().get_current_scene()
	return cur_scene.get_node_or_null("ResourceManager") if cur_scene else null

func find_target() -> void:
	var rm = _get_resource_manager()
	var search_jitter = float(get_instance_id() % 51) / 100.0
	target_search_timer = TARGET_SEARCH_INTERVAL * (0.75 + search_jitter)
	var focused_target_available = is_instance_valid(focused_target) and focused_target.is_in_group("asteroids") and int(focused_target.resource_amount) > 0
	if focused_target_available and rm and rm.has_method("can_mine_resource_node"):
		focused_target_available = bool(rm.can_mine_resource_node(focused_target))
	if focused_target_available:
		target_asteroid = focused_target
		state = State.TO_ASTEROID
		return
	focused_target = null
	# Request ResourceManager for best asteroid (considers priority)
	var best = null
	if rm and rm.has_method("get_best_asteroid_for"):
		best = rm.get_best_asteroid_for(position, true)
	else:
		# fallback: nearest by distance
		var asteroids = get_tree().get_nodes_in_group("asteroids")
		var bestd = 1e9
		for a in asteroids:
			var d = position.distance_to(a.global_position)
			if d < bestd:
				best = a
				bestd = d
	if best:
		target_asteroid = best
		state = State.TO_ASTEROID

func _go_to_flotilla():
	target_asteroid = null
	var rm = _get_resource_manager()
	if rm and is_instance_valid(rm.flotilla):
		flotilla = rm.flotilla
	else:
		var list = get_tree().get_nodes_in_group("flotilla")
		flotilla = list[0] if not list.is_empty() else null
	if flotilla:
		state = State.TO_FLOTILLA

func _retarget_after_depletion() -> void:
	target_asteroid = null
	if is_instance_valid(focused_target) and int(focused_target.get("resource_amount")) <= 0:
		focused_target = null
	if carry >= float(carry_capacity):
		_go_to_flotilla()
		return
	find_target()
	if not is_instance_valid(target_asteroid):
		_go_to_flotilla()
		return
	var rm = _get_resource_manager()
	if carry > 0.0 and rm and rm.has_method("should_drone_deposit_before_target") and rm.should_drone_deposit_before_target(global_position, target_asteroid.global_position):
		_go_to_flotilla()

func assign_target(target, persist_until_depleted: bool = false) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.is_in_group("asteroids") or target.is_in_group("sun") or int(target.get("resource_amount")) <= 0:
		return
	focused_target = target if persist_until_depleted else null
	if carry >= float(carry_capacity):
		_go_to_flotilla()
		return
	target_asteroid = target
	flotilla = null
	state = State.TO_ASTEROID

func recall_to_flagship() -> void:
	focused_target = null
	_go_to_flotilla()

func get_ship_profile() -> ShipProfile:
	return ship_profile
