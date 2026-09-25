extends Node2D

@onready var resource_manager = $ResourceManager
@onready var asteroids_container = $Asteroids
@onready var drones_container = $Drones
@onready var flotilla_node = $Flotilla
@onready var ui_layer = $UI

func _ready():
	var flotilla_scene = load("res://scenes/Flotilla.tscn")
	var base = flotilla_scene.instantiate()
	flotilla_node.add_child(base)
	base.position = resource_manager.get_fleet_start_position()
	base.move_target = base.position
	base.add_to_group("flotilla")
	resource_manager.flotilla = base
	resource_manager.configure_flagship()

	var game_state = get_node_or_null("/root/GameState")
	var field_prepared = false
	if game_state and game_state.battle_return_pending and not game_state.saved_run_state.is_empty():
		if game_state.prestige_reset_pending:
			resource_manager.reset_run_for_prestige(0, false)
		else:
			resource_manager.apply_run_state(game_state.saved_run_state, game_state.surviving_drone_count)
			if game_state.battle_advance_field_pending:
				resource_manager.advance_field_after_battle()
			else:
				resource_manager.spawn_resource_field()
		field_prepared = true
		game_state.consume_battle_return_pending()
	if not field_prepared:
		resource_manager.spawn_resource_field()

	if base.has_method("connect") and resource_manager.has_method("_on_flotilla_deposited"):
		base.connect("deposited", Callable(resource_manager, "_on_flotilla_deposited"))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var u := int(event.unicode)
		if u == 115 or u == 83:
			resource_manager.save_game()
		elif u == 108 or u == 76:
			resource_manager.load_game()
