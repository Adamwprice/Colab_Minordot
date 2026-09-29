extends Node2D

@export var max_resource_amount: int = 100
@export var resource_amount: int = 100
@export var reward_multiplier: int = 1
var orbit_enabled := false
var orbit_center := Vector2.ZERO
var orbit_radius := 300.0
var orbit_angle := 0.0
var orbit_speed := 0.12

func _process(delta: float) -> void:
	if orbit_enabled:
		orbit_angle = fmod(orbit_angle + orbit_speed * delta, TAU)
		position = orbit_center + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius

func mine(amount: int) -> int:
	var taken = min(amount, resource_amount)
	resource_amount -= taken
	if resource_amount <= 0:
		queue_free()
	return taken
