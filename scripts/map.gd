extends Control

const Catalog = preload("res://scripts/ship_catalog.gd")

@export var world_scale: float = 0.04
@export var min_scale: float = 0.01
@export var max_scale: float = 1.0

const GRID_WORLD_STEP := 1500.0
const MINEABLE_PULSE_SPEED := 1.8
const RANGE_ALERT_DURATION := 2.0

var pan: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_last: Vector2 = Vector2.ZERO

var selected: Node = null
var refinery_marker: Node2D = null
var ship_markers := {}
var held_mine_target: Node = null
var range_alert_target: Node = null
var range_alert_started_at: float = -1.0

func _ready():
	_build_refinery_marker()
	_build_capital_ship_markers()
	set_process(true)
	queue_redraw()

func _process(delta):
	# refresh visuals each frame (cheap for prototype)
	if range_alert_target != null:
		var alert_expired = float(Time.get_ticks_msec()) / 1000.0 - range_alert_started_at >= RANGE_ALERT_DURATION
		if not is_instance_valid(range_alert_target) or alert_expired:
			range_alert_target = null
	_update_held_mining()
	_update_refinery_marker()
	_update_capital_ship_markers()
	_update_selection_label()
	queue_redraw()

func _build_refinery_marker() -> void:
	refinery_marker = Node2D.new()
	refinery_marker.name = "RefineryMarker"
	refinery_marker.z_index = 50
	refinery_marker.visible = false
	add_child(refinery_marker)

	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(0, -13), Vector2(13, 0), Vector2(0, 13), Vector2(-13, 0)])
	glow.color = Color(0.24, 0.71, 0.54, 0.18)
	refinery_marker.add_child(glow)

	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(0, -9), Vector2(9, 0), Vector2(0, 9), Vector2(-9, 0)])
	body.color = Color("3eb489")
	refinery_marker.add_child(body)

	var outline = Line2D.new()
	outline.points = PackedVector2Array([Vector2(0, -9), Vector2(9, 0), Vector2(0, 9), Vector2(-9, 0), Vector2(0, -9)])
	outline.default_color = Color("baf7df")
	outline.width = 2.0
	refinery_marker.add_child(outline)

	var core = Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0)])
	core.color = Color("e8fff6")
	refinery_marker.add_child(core)

func _update_refinery_marker() -> void:
	if refinery_marker == null:
		return
	var game_state = get_node_or_null("/root/GameState")
	var unlocked = game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("refinery")
	var overlay_open := false
	var ui_layer = get_parent()
	if ui_layer and ui_layer.has_method("_has_open_research_overlay"):
		overlay_open = bool(ui_layer.call("_has_open_research_overlay"))
	refinery_marker.visible = unlocked and not overlay_open
	if not refinery_marker.visible:
		return
	var flagship = get_tree().get_first_node_in_group("flotilla")
	if flagship:
		var current_scene = get_tree().get_current_scene()
		var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
		var refinery_position = resource_manager.get_ship_world_position("refinery") if resource_manager and resource_manager.has_method("get_ship_world_position") else flagship.position
		refinery_marker.position = size * 0.5 + (refinery_position * world_scale) + pan

func _build_capital_ship_markers() -> void:
	for ship_key in Catalog.get_ship_ids():
		if ship_key == "refinery":
			continue
		var ship_data = Catalog.get_ship_data(ship_key)
		var category = str(ship_data.get("category", "civilian"))
		var shape = PackedVector2Array([Vector2(-13, -7), Vector2(11, -7), Vector2(16, 0), Vector2(11, 7), Vector2(-13, 7)])
		if category == "military":
			shape = PackedVector2Array([Vector2(-16, 0), Vector2(-7, -8), Vector2(16, -4), Vector2(16, 4), Vector2(-7, 8)])
		elif category == "support":
			shape = PackedVector2Array([Vector2(-14, -8), Vector2(14, -8), Vector2(14, 8), Vector2(-14, 8)])
		elif category == "utility":
			shape = PackedVector2Array([Vector2(-14, 0), Vector2(-4, -8), Vector2(14, 0), Vector2(-4, 8)])
		var marker = Node2D.new()
		marker.name = "%sMarker" % str(ship_key).to_pascal_case()
		marker.z_index = 49
		marker.visible = false
		add_child(marker)
		var body = Polygon2D.new()
		body.polygon = shape
		body.color = Catalog.CATEGORY_COLORS.get(category, Color.WHITE)
		marker.add_child(body)
		var outline = Line2D.new()
		var outline_points: PackedVector2Array = shape.duplicate()
		outline_points.append(outline_points[0])
		outline.points = outline_points
		outline.default_color = Color("f4efff")
		outline.width = 2.0
		marker.add_child(outline)
		ship_markers[ship_key] = {"node": marker, "offset": ship_data.get("offset", Vector2.ZERO)}

func _update_capital_ship_markers() -> void:
	var game_state = get_node_or_null("/root/GameState")
	var ui_layer = get_parent()
	var overlay_open = ui_layer and ui_layer.has_method("_has_open_research_overlay") and bool(ui_layer.call("_has_open_research_overlay"))
	var flagship = get_tree().get_first_node_in_group("flotilla")
	var current_scene = get_tree().get_current_scene()
	var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
	for ship_key in ship_markers:
		var marker_data: Dictionary = ship_markers[ship_key]
		var marker = marker_data["node"] as Node2D
		marker.visible = game_state and game_state.is_ship_unlocked(ship_key) and not overlay_open
		if marker.visible and flagship:
			var world_position = resource_manager.get_ship_world_position(ship_key) if resource_manager and resource_manager.has_method("get_ship_world_position") else flagship.position
			marker.position = size * 0.5 + (world_position * world_scale) + pan

func _get_formation_screen_offset(flagship: Node, local_offset: Vector2) -> Vector2:
	if flagship and flagship.has_method("get_formation_forward"):
		var forward: Vector2 = flagship.get_formation_forward()
		return Vector2(
			forward.x * local_offset.x - forward.y * local_offset.y,
			forward.y * local_offset.x + forward.x * local_offset.y
		)
	return local_offset

func ship_animation_hint(kind: String, time_seconds: float) -> float:
	match kind:
		"racer":
			return time_seconds * 2.0
		"trader":
			return time_seconds
		"dyson":
			return time_seconds * 0.4
		_:
			return -time_seconds * 0.7

func _draw():
	var cur_scene = get_tree().get_current_scene()
	var rm = cur_scene.get_node("ResourceManager") if cur_scene.has_node("ResourceManager") else null
	var center = size * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111f"))
	for star_index in range(140):
		var star_x = fmod(float(star_index * 83 + 29), max(size.x, 1.0))
		var star_y = fmod(float(star_index * 47 + 17), max(size.y, 1.0))
		var star_size = 1.0 if star_index % 4 else 2.0
		draw_circle(Vector2(star_x, star_y), star_size, Color(0.55, 0.7, 0.82, 0.35))

	# Navigation grid keeps the world readable while panning and zooming.
	var grid_step = GRID_WORLD_STEP * world_scale
	if grid_step > 18.0:
		var grid_origin = center + pan
		var first_grid_x = int(floor(-grid_origin.x / grid_step))
		var last_grid_x = int(ceil((size.x - grid_origin.x) / grid_step))
		var first_grid_y = int(floor(-grid_origin.y / grid_step))
		var last_grid_y = int(ceil((size.y - grid_origin.y) / grid_step))
		for grid_x in range(first_grid_x, last_grid_x + 1):
			var x = grid_origin.x + grid_x * grid_step
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.18, 0.32, 0.42, 0.18), 1.0)
		for grid_y in range(first_grid_y, last_grid_y + 1):
			var y = grid_origin.y + grid_y * grid_step
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.18, 0.32, 0.42, 0.18), 1.0)

	# draw asteroids
	if rm:
		var range_fleet = get_tree().get_first_node_in_group("flotilla")
		var has_range_fleet = range_fleet != null and is_instance_valid(range_fleet)
		var fleet_world_position = range_fleet.position if has_range_fleet else Vector2.ZERO
		var fleet_range = float(rm.get_fleet_mining_range()) if rm.has_method("get_fleet_mining_range") else 1000.0
		if has_range_fleet:
			var range_center = center + (fleet_world_position * world_scale) + pan
			var range_radius = fleet_range * world_scale
			draw_circle(range_center, range_radius, Color(0.22, 0.78, 0.88, 0.025))
			draw_arc(range_center, range_radius, 0.0, TAU, 128, Color(0.38, 0.88, 0.95, 0.20), 1.0)
			draw_arc(range_center, max(0.0, range_radius - 3.0), 0.0, TAU, 128, Color(0.38, 0.88, 0.95, 0.08), 2.0)
		if rm.has_method("get_system_ring_radii"):
			var ring_radii: PackedFloat32Array = rm.get_system_ring_radii()
			for ring_offset in range(ring_radii.size()):
				var ring_number = ring_offset + 1
				var is_planet_ring = rm.is_planet_spawn_ring(ring_number)
				var ring_color = Color(0.88, 0.24, 0.27, 0.045) if is_planet_ring else Color(0.86, 0.58, 0.28, 0.06)
				draw_arc(center + pan, ring_radii[ring_offset] * world_scale, 0.0, TAU, 160, ring_color, 1.0)
		var ast_container = cur_scene.get_node("Asteroids") if cur_scene.has_node("Asteroids") else null
		if ast_container:
			var pulse = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 1000.0 * MINEABLE_PULSE_SPEED)
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
				var resource_type = str(a.get_meta("resource_type", ""))
				var col = Color("d62828") if a.is_in_group("planet") else (Color("d18a43") if a.resource_amount > 80 else Color("8b5f45"))
				if resource_type == "enriched":
					col = Color("ef77d2")
				elif resource_type == "gas_planet":
					col = Color("65c7b3")
				elif resource_type == "gas_cloud":
					col = Color("72a9d8")
				var unlocked_for_mining = not rm.has_method("can_mine_resource_node") or bool(rm.can_mine_resource_node(a))
				var harvestable = int(a.resource_amount) > 0 and unlocked_for_mining
				var within_fleet_range = harvestable and has_range_fleet and world_pos.distance_to(fleet_world_position) <= fleet_range
				if harvestable:
					var glow_alpha = lerp(0.06, 0.14, pulse) if within_fleet_range else lerp(0.025, 0.07, pulse)
					var outline_alpha = lerp(0.22, 0.48, pulse) if within_fleet_range else lerp(0.10, 0.24, pulse)
					var harvest_glow = Color(0.35, 0.94, 0.69, glow_alpha) if within_fleet_range else Color(0.9, 0.46, 0.2, glow_alpha)
					var harvest_outline = Color(0.45, 1.0, 0.76, outline_alpha) if within_fleet_range else Color(0.94, 0.64, 0.32, outline_alpha)
					draw_circle(mpos, radius + 6.0 + pulse * 2.0, harvest_glow)
					draw_arc(mpos, radius + 4.0 + pulse * 2.0, 0.0, TAU, 32, harvest_outline, 1.0)
				draw_circle(mpos, radius, col)
				draw_circle(mpos - Vector2(radius * 0.3, radius * 0.25), radius * 0.25, Color(1, 0.82, 0.5, 0.55))
				if not unlocked_for_mining:
					draw_circle(mpos, radius + 8.0, Color(0.9, 0.2, 0.35, 0.08))
					draw_arc(mpos, radius + 6.0, 0.0, TAU, 32, Color(1.0, 0.3, 0.45, 0.85), 2.0)
					draw_line(mpos + Vector2(-radius * 0.7, -radius * 0.7), mpos + Vector2(radius * 0.7, radius * 0.7), Color("ff526f"), 2.0)
					draw_line(mpos + Vector2(radius * 0.7, -radius * 0.7), mpos + Vector2(-radius * 0.7, radius * 0.7), Color("ff526f"), 2.0)
				draw_string(ThemeDB.fallback_font, mpos + Vector2(-28, -radius - 8), "%d" % int(a.resource_amount), HORIZONTAL_ALIGNMENT_CENTER, 50, 12, Color("d9f4ff"))
				if a == range_alert_target:
					var alert_elapsed = float(Time.get_ticks_msec()) / 1000.0 - range_alert_started_at
					if alert_elapsed < RANGE_ALERT_DURATION:
						var alert_alpha = 1.0 - smoothstep(RANGE_ALERT_DURATION * 0.65, RANGE_ALERT_DURATION, alert_elapsed)
						draw_string(ThemeDB.fallback_font, mpos + Vector2(-100.0, -radius - 30.0), "OUT OF RANGE - FLEET APPROACHING", HORIZONTAL_ALIGNMENT_CENTER, 200.0, 12, Color(1.0, 0.68, 0.3, alert_alpha))
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
		if rm.has_method("get_visual_subcraft"):
			for visual in rm.get_visual_subcraft():
				var visual_pos = center + (Vector2(visual["position"]) * world_scale) + pan
				var visual_radius = clamp(float(visual.get("radius", 40.0)) * world_scale, 2.0, 7.0)
				var visual_color: Color = visual.get("color", Color.WHITE)
				draw_circle(visual_pos, visual_radius + 2.0, Color(visual_color, 0.12))
				draw_circle(visual_pos, visual_radius, visual_color)
				var velocity_hint: Vector2 = visual.get("direction", Vector2.RIGHT.rotated(ship_animation_hint(str(visual.get("kind", "")), float(Time.get_ticks_msec()) / 1000.0)))
				velocity_hint = velocity_hint.normalized()
				draw_line(visual_pos - velocity_hint * (visual_radius + 3.0), visual_pos, visual_color.lightened(0.35), 1.0)

func _gui_input(event):
	if event is InputEventMouseButton:
		# Mouse button indices: LEFT=1, RIGHT=2, WHEEL_UP=4, WHEEL_DOWN=5
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				selected = _pick_entity(event.position)
				held_mine_target = selected if selected and selected.is_in_group("asteroids") and not selected.is_in_group("sun") else null
				_update_range_alert_for_target(held_mine_target)
				_mine_held_target(false)
				_update_selection_label()
			else:
				held_mine_target = null
		elif event.button_index == 2 and event.pressed: # RIGHT
			var current_scene = get_tree().get_current_scene()
			var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
			if resource_manager and resource_manager.has_method("order_fleet_to"):
				resource_manager.order_fleet_to(_screen_to_world(event.position))
			else:
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

func _update_range_alert_for_target(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	var current_scene = get_tree().get_current_scene()
	var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
	if resource_manager == null or not resource_manager.has_method("is_asteroid_in_mining_range"):
		return
	var mineable = not resource_manager.has_method("can_mine_resource_node") or bool(resource_manager.can_mine_resource_node(target))
	if mineable and not bool(resource_manager.is_asteroid_in_mining_range(target)):
		range_alert_target = target
		range_alert_started_at = float(Time.get_ticks_msec()) / 1000.0
	elif target == range_alert_target:
		range_alert_target = null

func _update_held_mining() -> void:
	if held_mine_target == null:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		held_mine_target = null
		return
	var ui_layer = get_parent()
	if ui_layer and ui_layer.has_method("_has_open_research_overlay") and bool(ui_layer.call("_has_open_research_overlay")):
		held_mine_target = null
		return
	_mine_held_target(true)

func _mine_held_target(is_held: bool) -> void:
	if held_mine_target == null or not is_instance_valid(held_mine_target):
		held_mine_target = null
		return
	if not held_mine_target.is_in_group("asteroids") or held_mine_target.is_in_group("sun") or int(held_mine_target.resource_amount) <= 0:
		held_mine_target = null
		return
	var current_scene = get_tree().get_current_scene()
	var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
	if resource_manager and resource_manager.has_method("click_mine"):
		if resource_manager.has_method("can_mine_resource_node") and not bool(resource_manager.can_mine_resource_node(held_mine_target)):
			held_mine_target = null
			return
		resource_manager.click_mine(held_mine_target, is_held)

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
		lbl.add_theme_color_override("font_color", Color("d9f4ff"))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size = Vector2(max(1.0, size.x - 36.0), 42.0)
	lbl.position = _clamp_selection_label_position(lbl.size)
	lbl.add_theme_color_override("font_color", Color("d9f4ff"))
	if selected != null and not is_instance_valid(selected):
		selected = null
	if selected == null:
		lbl.text = "Selected: None"
	else:
		if selected.is_in_group("sun"):
			lbl.text = "Star"
		elif selected.is_in_group("asteroids"):
			var node_name = str(selected.get_meta("resource_display_name", "Planet" if selected.is_in_group("planet") else "Asteroid"))
			var current_scene = get_tree().get_current_scene()
			var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
			var lock_message = resource_manager.get_resource_lock_message(selected) if resource_manager and resource_manager.has_method("get_resource_lock_message") else ""
			lbl.text = "%s - resources: %d/%d" % [node_name, int(selected.resource_amount), int(selected.max_resource_amount)]
			if not lock_message.is_empty():
				lbl.text += " | %s" % lock_message
				lbl.add_theme_color_override("font_color", Color("ff6f86"))
			else:
				lbl.add_theme_color_override("font_color", Color("d9f4ff"))
		elif selected.is_in_group("flotilla"):
			lbl.text = "Flagship - stored: %d" % int(selected.storage)
		else:
			lbl.text = "Entity"

func _clamp_selection_label_position(label_size: Vector2) -> Vector2:
	var margin = 18.0
	var target = Vector2(margin, size.y - label_size.y - margin)
	var max_x = max(margin, size.x - label_size.x - margin)
	var max_y = max(margin, size.y - label_size.y - margin)
	return Vector2(clamp(target.x, margin, max_x), clamp(target.y, margin, max_y))
