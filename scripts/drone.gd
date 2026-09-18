extends Node2D

enum State { IDLE, TO_ASTEROID, MINING, TO_FLOTILLA }
var state = State.IDLE

@export var ship_profile: ShipProfile

var speed: float = 50.0
var carry_capacity: int = 10
var mining_amount: int = 1
var carry: float = 0.0
var mining_reward_multiplier: float = 1.0
var mine_timer: float = 0.0 
var mine_interval: float = 1 # seconds between mine ticks

var target_asteroid: Node = null
var flotilla: Node = null

func _ready():
	set_physics_process(true)
	mine_timer = 0.0

func _physics_process(delta):
	if state == State.IDLE:
		find_target()
	elif state == State.TO_ASTEROID:
		if not is_instance_valid(target_asteroid):
			_go_to_flotilla()
			return
		move_toward_target(target_asteroid.global_position, delta)
		if position.distance_to(target_asteroid.global_position) < 12:
			state = State.MINING
			mine_timer = 0.0
	elif state == State.MINING:
		if not is_instance_valid(target_asteroid):
			_go_to_flotilla()
			return
		mine_timer += delta
		if mine_timer >= mine_interval:
			mine_timer = 0.0
			var space_left = max(0, int(floor(float(carry_capacity) - carry)))
			if space_left <= 0:
				_go_to_flotilla()
				return
			var harvested = target_asteroid.mine(min(mining_amount, space_left))
			carry += float(harvested)
			if carry >= carry_capacity or harvested <= 0:
				_go_to_flotilla()
	elif state == State.TO_FLOTILLA and is_instance_valid(flotilla):
		move_toward_target(flotilla.global_position, delta)
		if position.distance_to(flotilla.global_position) < 16:
			flotilla.deposit(carry * mining_reward_multiplier)
			carry = 0
			state = State.IDLE
	else:
		state = State.IDLE

func move_toward_target(target_pos: Vector2, delta: float) -> void:
	var dir = (target_pos - position).normalized()
	position += dir * speed * delta

func find_target() -> void:
	# Request ResourceManager for best asteroid (considers priority)
	var cur_scene = get_tree().get_current_scene()
	var rm = cur_scene.get_node("ResourceManager") if cur_scene.has_node("ResourceManager") else null
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
	var list = get_tree().get_nodes_in_group("flotilla")
	if list.size() > 0:
		flotilla = list[0]
	else:
		# fallback to resource manager's flotilla reference
		var cur_scene = get_tree().get_current_scene()
		var rm = cur_scene.get_node("ResourceManager") if cur_scene.has_node("ResourceManager") else null
		if rm and rm.flotilla:
			flotilla = rm.flotilla
	if flotilla:
		state = State.TO_FLOTILLA

func assign_target(target: Node) -> void:
	if target == null:
		return
	if carry >= float(carry_capacity):
		_go_to_flotilla()
		return
	target_asteroid = target
	flotilla = null
	state = State.TO_ASTEROID

func get_ship_profile() -> ShipProfile:
	return ship_profile
