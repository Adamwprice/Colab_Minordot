extends Node2D

signal deposited(amount, gained)

@export var ship_profile: ShipProfile

var storage: float = 0.0
var move_speed: float = 60.0
var move_target := Vector2.ZERO
var formation_forward := Vector2.RIGHT

func _ready() -> void:
	move_target = position

func _physics_process(delta: float) -> void:
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

func deposit(amount: float) -> void:
	storage += amount
	emit_signal("deposited", storage, amount)

func get_ship_profile() -> ShipProfile:
	return ship_profile
