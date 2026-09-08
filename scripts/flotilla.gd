extends Node2D

signal deposited(amount)

var storage: float = 0.0
var move_speed: float = 60.0
var move_target := Vector2.ZERO

func _ready() -> void:
    move_target = position

func _physics_process(delta: float) -> void:
    position = position.move_toward(move_target, move_speed * delta)

func move_to(target: Vector2) -> void:
    move_target = target

func deposit(amount: float) -> void:
    storage += amount
    emit_signal("deposited", storage)
