extends Node2D

signal deposited(amount, gained)

@export var ship_profile: ShipProfile

var storage: float = 0.0
var move_speed: float = 60.0
var move_target := Vector2.ZERO
var formation_forward := Vector2.RIGHT
var previous_position := Vector2.ZERO

func _ready() -> void:
	move_target = position
	previous_position = position

func _physics_process(delta: float) -> void:
	previous_position = position
	var travel_vector = move_target - position
	if travel_vector.length_squared() > 0.001:
		formation_forward = travel_vector.normalized()
	position = position.move_toward(move_target, move_speed * delta)

func move_to(target: Vector2) -> void:
	move_target = target
	var travel_vector = move_target - position
	if travel_vector.length_squared() > 0.001:
		formation_forward = travel_vector.normalized()

func get_formation_forward() -> Vector2:
	return formation_forward

func get_visual_position() -> Vector2:
	return previous_position.lerp(position, Engine.get_physics_interpolation_fraction())

func reset_visual_interpolation() -> void:
	previous_position = position

func deposit(amount: float) -> void:
	storage += amount
	emit_signal("deposited", storage, amount)

func get_ship_profile() -> ShipProfile:
	return ship_profile
