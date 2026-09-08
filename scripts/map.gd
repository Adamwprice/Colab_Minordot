extends Control

@export var world_scale: float = 0.6
@export var min_scale: float = 0.2
@export var max_scale: float = 2.5

var pan: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_last: Vector2 = Vector2.ZERO

var selected: Node = null

func _ready():
	set_process(true)
	queue_redraw()

func _process(delta):
	# refresh visuals each frame (cheap for prototype)
	queue_redraw()

func _draw():
	var cur_scene = get_tree().get_current_scene()
	var rm = cur_scene.get_node("ResourceManager") if cur_scene.has_node("ResourceManager") else null
	var center = size * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111f"))
	for star_index in range(70):
		var star_x = fmod(float(star_index * 83 + 29), max(size.x, 1.0))
		var star_y = fmod(float(star_index * 47 + 17), max(size.y, 1.0))
		var star_size = 1.0 if star_index % 4 else 2.0
		draw_circle(Vector2(star_x, star_y), star_size, Color(0.55, 0.7, 0.82, 0.35))

	# Navigation grid keeps the world readable while panning and zooming.
	var grid_step = 100.0 * world_scale
	if grid_step > 18.0:
		var grid_origin = center + pan
		for grid_x in range(-12, 13):
			var x = grid_origin.x + grid_x * grid_step
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.18, 0.32, 0.42, 0.18), 1.0)
		for grid_y in range(-8, 9):
			var y = grid_origin.y + grid_y * grid_step
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.18, 0.32, 0.42, 0.18), 1.0)

	# draw asteroids
	if rm:
		var ast_container = cur_scene.get_node("Asteroids") if cur_scene.has_node("Asteroids") else null
		if ast_container:
			for a in ast_container.get_children():
				var world_pos = a.position
				var mpos = center + (world_pos * world_scale) + pan
				if a.is_in_group("sun"):
					var sun_radius = 30.0
					draw_circle(mpos, sun_radius + 18.0, Color(1.0, 0.62, 0.16, 0.08))
					draw_circle(mpos, sun_radius + 8.0, Color(1.0, 0.78, 0.24, 0.14))
					draw_circle(mpos, sun_radius, Color("f4c542"))
					draw_circle(mpos - Vector2(8, 7), 9.0, Color(1.0, 0.94, 0.58, 0.75))
					if a == selected:
						draw_arc(mpos, sun_radius + 12.0, 0, TAU, 32, Color("5ee7ff"), 2.0)
					continue
				var radius = clamp(8 + (a.resource_amount / 20.0), 6, 20)
				var col = Color("d62828") if a.is_in_group("planet") else (Color("d18a43") if a.resource_amount > 80 else Color("8b5f45"))
				draw_circle(mpos, radius + 3, Color(0.9, 0.46, 0.2, 0.08))
				draw_circle(mpos, radius, col)
				draw_circle(mpos - Vector2(radius * 0.3, radius * 0.25), radius * 0.25, Color(1, 0.82, 0.5, 0.55))
				draw_string(ThemeDB.fallback_font, mpos + Vector2(-28, -radius - 8), "%d/%d" % [a.resource_amount, a.max_resource_amount], HORIZONTAL_ALIGNMENT_CENTER, 50, 12, Color("d9f4ff"))
				if a == selected:
					draw_arc(mpos, radius + 7, 0, TAU, 32, Color("5ee7ff"), 2.0)
		# draw flotilla
		var flotillas = get_tree().get_nodes_in_group("flotilla")
		if flotillas.size() > 0:
			var f = flotillas[0]
			var fpos = center + (f.position * world_scale) + pan
			draw_circle(fpos, 22, Color(0.2, 0.75, 0.95, 0.08))
			draw_circle(fpos, 13, Color("38b9d6"))
			draw_circle(fpos, 6, Color("d7fbff"))
			draw_arc(fpos, 20, 0, TAU, 32, Color(0.35, 0.85, 0.95, 0.65), 1.0)
			if f == selected:
				draw_arc(fpos, 27, 0, TAU, 32, Color("f4d06f"), 2.0)
		# Draw active mining routes behind the entities.
		var drone_container = cur_scene.get_node("Drones") if cur_scene.has_node("Drones") else null
		if drone_container:
			for drone in drone_container.get_children():
				var drone_pos = center + (drone.position * world_scale) + pan
				if drone.target_asteroid and is_instance_valid(drone.target_asteroid):
					var target_pos = center + (drone.target_asteroid.position * world_scale) + pan
					draw_dashed_line(drone_pos, target_pos, Color(0.35, 0.85, 0.95, 0.25), 1.0, 5.0)
				draw_circle(drone_pos, 4, Color("a9efff"))

func _gui_input(event):
	if event is InputEventMouseButton:
		# Mouse button indices: LEFT=1, RIGHT=2, WHEEL_UP=4, WHEEL_DOWN=5
		if event.button_index == 1 and event.pressed: # LEFT
			# select nearest entity
			var pos = event.position
			var found = _pick_entity(pos)
			selected = found
			if selected and selected.is_in_group("asteroids"):
				var rm = get_tree().get_current_scene().get_node("ResourceManager")
				if rm and rm.has_method("click_mine"):
					rm.click_mine(selected)
			_update_selection_label()
		elif event.button_index == 2 and event.pressed: # RIGHT
			var flagship = get_tree().get_first_node_in_group("flotilla")
			if flagship and flagship.has_method("move_to"):
				flagship.move_to(_screen_to_world(event.position))
		elif event.button_index == 4 and event.pressed: # WHEEL_UP
			world_scale = min(world_scale * 1.1, max_scale)
		elif event.button_index == 5 and event.pressed: # WHEEL_DOWN
			world_scale = max(world_scale / 1.1, min_scale)
	elif event is InputEventMouseMotion:
		# Middle-drag pans; right-click is reserved for flagship movement orders.
		if Input.is_mouse_button_pressed(3): # MIDDLE
			pan += event.relative

func _pick_entity(screen_pos: Vector2):
	var center = size * 0.5
	var cur_scene = get_tree().get_current_scene()
	var ast_container = cur_scene.get_node("Asteroids") if cur_scene.has_node("Asteroids") else null
	var best = null
	var bestd = 1e9
	if ast_container:
		for a in ast_container.get_children():
			var mpos = center + (a.position * world_scale) + pan
			var d = mpos.distance_to(screen_pos)
			if d < bestd and d < 24:
				bestd = d
				best = a
	# check flotilla
	var flotillas = get_tree().get_nodes_in_group("flotilla")
	if flotillas.size() > 0:
		var f = flotillas[0]
		var fm = center + (f.position * world_scale) + pan
		var fd = fm.distance_to(screen_pos)
		if fd < bestd and fd < 32:
			return f
	return best

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - size * 0.5 - pan) / world_scale

func center_on_node(node: Node) -> void:
	if node == null:
		return
	# pan such that the node appears centered
	pan = -node.position * world_scale
	queue_redraw()

func _update_selection_label():
	# simple label display child
	var lbl: Label = null
	if has_node("Label"):
		lbl = get_node("Label") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "Label"
		add_child(lbl)
		lbl.position = Vector2(18, size.y - 26)
	if selected != null and not is_instance_valid(selected):
		selected = null
	if selected == null:
		lbl.text = "Selected: None"
	else:
		if selected.is_in_group("sun"):
			lbl.text = "Star"
		elif selected.is_in_group("asteroids"):
			lbl.text = "Asteroid - resources: %d/%d" % [int(selected.resource_amount), int(selected.max_resource_amount)]
		elif selected.is_in_group("flotilla"):
			lbl.text = "Flagship - stored: %d" % int(selected.storage)
		else:
			lbl.text = "Entity"
