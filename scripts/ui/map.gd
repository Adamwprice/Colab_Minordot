extends Control

const Catalog = preload("res://scripts/data/ship_catalog.gd")
const MapBackground = preload("res://scripts/ui/map_background.gd")

@export var world_scale: float = 0.04
@export var min_scale: float = 0.01
@export var max_scale: float = 1.0

const MINEABLE_PULSE_SPEED := 1.8
const RANGE_ALERT_DURATION := 2.0
const POINTER_DRAG_THRESHOLD := 3.0
const POINTER_HOLD_DELAY := 0.15
const VISUAL_REFRESH_INTERVAL := 1.0 / 60.0

var pan: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_last: Vector2 = Vector2.ZERO
var pressed_button: int = 0
var press_position: Vector2 = Vector2.ZERO
var press_entity: Node = null
var press_started_at: float = 0.0
var hold_action_started: bool = false

var selected: Node = null
var refinery_marker: Node2D = null
var ship_markers := {}
var held_mine_target: Node = null
var range_alert_target: Node = null
var range_alert_started_at: float = -1.0
var map_background: Control = null
var visual_refresh_elapsed: float = 0.0
var selection_label_color := Color.TRANSPARENT
var camera_refresh_pending := false
var main_scene: Node = null
var resource_manager: Node = null
var asteroid_container: Node = null
var drone_container: Node = null
var flagship: Node = null
var game_state: Node = null
var hud_layer: CanvasLayer = null
var last_draw_build_msec := 0.0

func _ready() -> void:
	_cache_scene_references()
	map_background = MapBackground.new()
	map_background.name = "MapBackground"
	map_background.z_index = -100
	map_background.show_behind_parent = true
	add_child(map_background)
	map_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_background.set_camera(world_scale, pan)
	_build_refinery_marker()
	_build_capital_ship_markers()
	set_process(true)
	_refresh_dynamic_visuals()
	call_deferred("_refresh_dynamic_visuals")

func _process(delta):
	if selected != null and not is_instance_valid(selected):
		selected = null
	if press_entity != null and not is_instance_valid(press_entity):
		press_entity = null
		hold_action_started = false
	if held_mine_target != null and not is_instance_valid(held_mine_target):
		held_mine_target = null
	if range_alert_target != null:
		var alert_expired = float(Time.get_ticks_msec()) / 1000.0 - range_alert_started_at >= RANGE_ALERT_DURATION
		if not is_instance_valid(range_alert_target) or alert_expired:
			range_alert_target = null
	if _is_world_input_blocked():
		_cancel_pointer_interaction()
	else:
		_update_pointer_hold_action()
		_update_held_mining()
	visual_refresh_elapsed += delta
	if not dragging and visual_refresh_elapsed < VISUAL_REFRESH_INTERVAL:
		return
	visual_refresh_elapsed = 0.0 if dragging else fmod(visual_refresh_elapsed, VISUAL_REFRESH_INTERVAL)
	if camera_refresh_pending:
		camera_refresh_pending = false
		_apply_camera_refresh()
	_refresh_dynamic_visuals()

func _refresh_dynamic_visuals() -> void:
	_ensure_scene_references()
	_update_refinery_marker()
	_update_capital_ship_markers()
	_update_selection_label()
	queue_redraw()

func _camera_changed() -> void:
	camera_refresh_pending = true

func _apply_camera_refresh() -> void:
	if map_background:
		map_background.set_camera(world_scale, pan)

func _cache_scene_references() -> void:
	main_scene = get_tree().get_current_scene()
	resource_manager = main_scene.get_node_or_null("ResourceManager") if main_scene else null
	asteroid_container = main_scene.get_node_or_null("Asteroids") if main_scene else null
	drone_container = main_scene.get_node_or_null("Drones") if main_scene else null
	hud_layer = main_scene.get_node_or_null("UI") as CanvasLayer if main_scene else null
	game_state = get_node_or_null("/root/GameState")
	_ensure_scene_references()

func _ensure_scene_references() -> void:
	if not is_instance_valid(resource_manager) and is_instance_valid(main_scene):
		resource_manager = main_scene.get_node_or_null("ResourceManager")
	if not is_instance_valid(asteroid_container) and is_instance_valid(main_scene):
		asteroid_container = main_scene.get_node_or_null("Asteroids")
	if not is_instance_valid(drone_container) and is_instance_valid(main_scene):
		drone_container = main_scene.get_node_or_null("Drones")
	if not is_instance_valid(hud_layer) and is_instance_valid(main_scene):
		hud_layer = main_scene.get_node_or_null("UI") as CanvasLayer
	if not is_instance_valid(flagship):
		if is_instance_valid(resource_manager) and is_instance_valid(resource_manager.flotilla):
			flagship = resource_manager.flotilla
		else:
			flagship = get_tree().get_first_node_in_group("flotilla")

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
	_add_ship_id_label(refinery_marker, Catalog.get_display_name("refinery"), Color("3eb489"))
	refinery_marker.set_meta("ship_key", "refinery")
	refinery_marker.add_to_group("capital_ship_marker")

func _update_refinery_marker() -> void:
	if refinery_marker == null:
		return
	var unlocked = game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("refinery")
	var overlay_open := false
	if hud_layer and hud_layer.has_method("_has_open_research_overlay"):
		overlay_open = bool(hud_layer.call("_has_open_research_overlay"))
	refinery_marker.visible = unlocked and not overlay_open
	if not refinery_marker.visible:
		return
	if flagship:
		var refinery_position = resource_manager.get_ship_world_position("refinery") if resource_manager and resource_manager.has_method("get_ship_world_position") else flagship.position
		if flagship.has_method("get_visual_position"):
			refinery_position += flagship.get_visual_position() - flagship.position
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
		_add_ship_id_label(marker, Catalog.get_display_name(ship_key), Catalog.CATEGORY_COLORS.get(category, Color.WHITE))
		marker.set_meta("ship_key", ship_key)
		marker.add_to_group("capital_ship_marker")
		ship_markers[ship_key] = {"node": marker, "offset": ship_data.get("offset", Vector2.ZERO)}

func _add_ship_id_label(marker: Node2D, display_name: String, color: Color) -> void:
	var id_label = Label.new()
	id_label.name = "ShipId"
	id_label.text = display_name.to_upper()
	id_label.position = Vector2(-48.0, -27.0)
	id_label.size = Vector2(96.0, 14.0)
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	id_label.add_theme_font_size_override("font_size", 9)
	id_label.add_theme_color_override("font_color", color.lightened(0.28))
	marker.add_child(id_label)

func _update_capital_ship_markers() -> void:
	var overlay_open = hud_layer and hud_layer.has_method("_has_open_research_overlay") and bool(hud_layer.call("_has_open_research_overlay"))
	var fleet_visual_offset := Vector2.ZERO
	if flagship and flagship.has_method("get_visual_position"):
		fleet_visual_offset = flagship.get_visual_position() - flagship.position
	for ship_key in ship_markers:
		var marker_data: Dictionary = ship_markers[ship_key]
		var marker = marker_data["node"] as Node2D
		marker.visible = game_state and game_state.is_ship_unlocked(ship_key) and not overlay_open
		if marker.visible and flagship:
			var world_position = resource_manager.get_ship_world_position(ship_key) if resource_manager and resource_manager.has_method("get_ship_world_position") else flagship.position
			world_position += fleet_visual_offset
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

func _is_screen_position_visible(screen_position: Vector2, margin: float = 80.0) -> bool:
	return Rect2(Vector2.ZERO, size).grow(margin).has_point(screen_position)

func _draw() -> void:
	var draw_started_usec = Time.get_ticks_usec()
	var rm = resource_manager if is_instance_valid(resource_manager) else null
	var center = size * 0.5
	var animation_time = float(Time.get_ticks_msec()) / 1000.0
	var low_detail = dragging

	# draw asteroids
	if rm:
		var range_fleet = flagship if is_instance_valid(flagship) else null
		var has_range_fleet = range_fleet != null and is_instance_valid(range_fleet)
		var fleet_world_position = (range_fleet.get_visual_position() if range_fleet.has_method("get_visual_position") else range_fleet.position) if has_range_fleet else Vector2.ZERO
		var fleet_range = float(rm.get_fleet_mining_range()) if rm.has_method("get_fleet_mining_range") else 1000.0
		if has_range_fleet and not low_detail:
			var range_center = center + (fleet_world_position * world_scale) + pan
			var range_radius = fleet_range * world_scale
			draw_circle(range_center, range_radius, Color(0.22, 0.78, 0.88, 0.025))
			draw_arc(range_center, range_radius, 0.0, TAU, 64, Color(0.38, 0.88, 0.95, 0.20), 1.0)
			draw_arc(range_center, max(0.0, range_radius - 3.0), 0.0, TAU, 64, Color(0.38, 0.88, 0.95, 0.08), 2.0)
		if not low_detail and rm.has_method("get_merlinda_race_path"):
			var race_path: Array[Vector2] = rm.get_merlinda_race_path()
			if race_path.size() >= 2:
				var race_screen_path := PackedVector2Array()
				for race_point in race_path:
					race_screen_path.append(center + race_point * world_scale + pan)
				draw_polyline(race_screen_path, Color(0.58, 0.36, 0.18, 0.30), 1.0, true)
		var ast_container = asteroid_container if is_instance_valid(asteroid_container) else null
		if ast_container:
			var pulse = 0.5 + 0.5 * sin(animation_time * MINEABLE_PULSE_SPEED)
			for a in ast_container.get_children():
				var world_pos = a.position
				var mpos = center + (world_pos * world_scale) + pan
				if not _is_screen_position_visible(mpos, 140.0):
					continue
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
				if harvestable and not low_detail:
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
				if not low_detail:
					draw_string(ThemeDB.fallback_font, mpos + Vector2(-28, -radius - 8), "%d" % int(a.resource_amount), HORIZONTAL_ALIGNMENT_CENTER, 50, 12, Color("d9f4ff"))
				if not low_detail and a == range_alert_target:
					var alert_elapsed = float(Time.get_ticks_msec()) / 1000.0 - range_alert_started_at
					if alert_elapsed < RANGE_ALERT_DURATION:
						var alert_alpha = 1.0 - smoothstep(RANGE_ALERT_DURATION * 0.65, RANGE_ALERT_DURATION, alert_elapsed)
						draw_string(ThemeDB.fallback_font, mpos + Vector2(-100.0, -radius - 30.0), "OUT OF RANGE - FLEET APPROACHING", HORIZONTAL_ALIGNMENT_CENTER, 200.0, 12, Color(1.0, 0.68, 0.3, alert_alpha))
				if a == selected:
					draw_arc(mpos, radius + 7, 0, TAU, 32, Color("5ee7ff"), 2.0)
		# draw flotilla
		if range_fleet:
			var f = range_fleet
			var fpos = center + (fleet_world_position * world_scale) + pan
			draw_circle(fpos, 22, Color(0.2, 0.75, 0.95, 0.08))
			draw_circle(fpos, 13, Color("38b9d6"))
			draw_circle(fpos, 6, Color("d7fbff"))
			draw_arc(fpos, 20, 0, TAU, 32, Color(0.35, 0.85, 0.95, 0.65), 1.0)
			draw_string(ThemeDB.fallback_font, fpos + Vector2(-38.0, -31.0), "FLAGSHIP", HORIZONTAL_ALIGNMENT_CENTER, 76.0, 9, Color("8de8ff"))
			if f == selected:
				draw_arc(fpos, 27, 0, TAU, 32, Color("f4d06f"), 2.0)
		if refinery_marker and refinery_marker.visible and refinery_marker == selected:
			draw_arc(refinery_marker.position, 21.0, 0.0, TAU, 32, Color("f4d06f"), 2.0)
		for marker_data in ship_markers.values():
			var ship_marker = marker_data["node"] as Node2D
			if ship_marker.visible and ship_marker == selected:
				draw_arc(ship_marker.position, 22.0, 0.0, TAU, 32, Color("f4d06f"), 2.0)
		# Draw active mining routes behind the entities.
		var active_drone_container = drone_container if is_instance_valid(drone_container) else null
		if active_drone_container:
			var mining_route_points := PackedVector2Array()
			var visible_drone_positions := PackedVector2Array()
			for drone in active_drone_container.get_children():
				var drone_world_position: Vector2 = drone.get_visual_position() if drone.has_method("get_visual_position") else drone.position
				var drone_pos = center + (drone_world_position * world_scale) + pan
				var drone_visible = _is_screen_position_visible(drone_pos)
				var show_route = not low_detail and drone.target_asteroid and is_instance_valid(drone.target_asteroid)
				if show_route:
					var target_pos = center + (drone.target_asteroid.position * world_scale) + pan
					if drone_visible or _is_screen_position_visible(target_pos):
						mining_route_points.append(drone_pos)
						mining_route_points.append(target_pos)
				if drone_visible:
					visible_drone_positions.append(drone_pos)
			if mining_route_points.size() >= 2:
				draw_multiline(mining_route_points, Color(0.35, 0.85, 0.95, 0.30), 1.0, true)
			for drone_pos in visible_drone_positions:
				draw_circle(drone_pos, 4, Color("a9efff"))
		if rm.has_method("get_visual_subcraft"):
			for visual in rm.get_visual_subcraft():
				var visual_pos = center + (Vector2(visual["position"]) * world_scale) + pan
				if not _is_screen_position_visible(visual_pos):
					continue
				var visual_radius = clamp(float(visual.get("radius", 40.0)) * world_scale, 2.0, 7.0)
				var visual_color: Color = visual.get("color", Color.WHITE)
				if not low_detail:
					draw_circle(visual_pos, visual_radius + 2.0, Color(visual_color, 0.12))
				draw_circle(visual_pos, visual_radius, visual_color)
				if not low_detail:
					var velocity_hint: Vector2 = visual.get("direction", Vector2.RIGHT.rotated(ship_animation_hint(str(visual.get("kind", "")), animation_time)))
					velocity_hint = velocity_hint.normalized()
					draw_line(visual_pos - velocity_hint * (visual_radius + 3.0), visual_pos, visual_color.lightened(0.35), 1.0)
	last_draw_build_msec = float(Time.get_ticks_usec() - draw_started_usec) / 1000.0

func _gui_input(event):
	if _is_world_input_blocked():
		_cancel_pointer_interaction()
		accept_event()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			world_scale = min(world_scale * 1.1, max_scale)
			_camera_changed()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			world_scale = max(world_scale / 1.1, min_scale)
			_camera_changed()
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				_begin_pointer_interaction(event.button_index, event.position)
			elif event.button_index == pressed_button:
				_end_pointer_interaction(event.position)
	elif event is InputEventMouseMotion:
		_update_pointer_drag(event.position)

func _is_world_input_blocked() -> bool:
	return hud_layer and hud_layer.has_method("_has_open_research_overlay") and bool(hud_layer.call("_has_open_research_overlay"))

func _cancel_pointer_interaction() -> void:
	pressed_button = 0
	dragging = false
	hold_action_started = false
	held_mine_target = null
	press_entity = null

func _begin_pointer_interaction(button: int, screen_position: Vector2) -> void:
	if pressed_button != 0:
		return
	pressed_button = button
	press_position = screen_position
	drag_last = screen_position
	press_entity = _pick_entity(screen_position)
	press_started_at = float(Time.get_ticks_msec()) / 1000.0
	dragging = false
	hold_action_started = false
	held_mine_target = null

func _update_pointer_drag(screen_position: Vector2) -> void:
	if pressed_button == 0:
		return
	if not _is_camera_drag_button(pressed_button):
		drag_last = screen_position
		return
	if not dragging and screen_position.distance_to(press_position) >= POINTER_DRAG_THRESHOLD:
		dragging = true
		held_mine_target = null
		pan += screen_position - press_position
		_camera_changed()
	else:
		if dragging:
			pan += screen_position - drag_last
			_camera_changed()
	drag_last = screen_position

func _is_camera_drag_button(button: int) -> bool:
	return button == MOUSE_BUTTON_RIGHT or button == MOUSE_BUTTON_MIDDLE

func _end_pointer_interaction(screen_position: Vector2) -> void:
	var released_button = pressed_button
	var was_dragging = dragging
	var had_hold_action = hold_action_started
	var clicked_entity = press_entity
	if clicked_entity != null and not is_instance_valid(clicked_entity):
		clicked_entity = null
	pressed_button = 0
	dragging = false
	hold_action_started = false
	held_mine_target = null
	press_entity = null
	if not was_dragging and not had_hold_action:
		_handle_pointer_click(released_button, screen_position, clicked_entity)

func _update_pointer_hold_action() -> void:
	if pressed_button != MOUSE_BUTTON_LEFT or dragging or hold_action_started:
		return
	if float(Time.get_ticks_msec()) / 1000.0 - press_started_at < POINTER_HOLD_DELAY:
		return
	if _is_mineable_field_node(press_entity):
		hold_action_started = true
		selected = press_entity
		_update_selection_label()
		_activate_selected_resource_node(press_entity, true)

func _handle_pointer_click(button: int, screen_position: Vector2, clicked_entity) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return
	if clicked_entity == null or not is_instance_valid(clicked_entity):
		selected = null
		_update_selection_label()
		_order_fleet_to_screen_position(screen_position)
		return
	var was_selected = clicked_entity == selected
	selected = clicked_entity
	_update_selection_label()
	if clicked_entity.is_in_group("capital_ship_marker"):
		_focus_ship_upgrades(str(clicked_entity.get_meta("ship_key", "")))
	elif clicked_entity.is_in_group("flotilla"):
		_focus_ship_upgrades("flagship")
	elif was_selected and _is_mineable_field_node(clicked_entity):
		_activate_selected_resource_node(clicked_entity, false)

func _activate_selected_resource_node(target, is_held: bool) -> void:
	if not _is_mineable_field_node(target):
		return
	if resource_manager == null or not resource_manager.has_method("click_mine"):
		return
	if resource_manager.has_method("can_mine_resource_node") and not bool(resource_manager.can_mine_resource_node(target)):
		return
	_update_range_alert_for_target(target)
	if resource_manager.has_method("is_asteroid_in_mining_range") and not bool(resource_manager.is_asteroid_in_mining_range(target)):
		if resource_manager.has_method("approach_asteroid"):
			resource_manager.approach_asteroid(target)
		held_mine_target = target if is_held else null
		return
	held_mine_target = target
	_mine_held_target(is_held)
	if not is_held:
		held_mine_target = null

func _is_mineable_field_node(target) -> bool:
	return target != null and is_instance_valid(target) and target.is_in_group("asteroids") and not target.is_in_group("sun") and int(target.resource_amount) > 0

func _order_fleet_to_screen_position(screen_position: Vector2) -> void:
	if resource_manager and resource_manager.has_method("order_fleet_to"):
		resource_manager.order_fleet_to(_screen_to_world(screen_position))
		return
	if flagship and flagship.has_method("move_to"):
		flagship.move_to(_screen_to_world(screen_position))

func _focus_ship_upgrades(ship_key: String) -> void:
	if hud_layer and hud_layer.has_method("focus_ore_upgrade_ship"):
		hud_layer.call("focus_ore_upgrade_ship", ship_key)

func _update_range_alert_for_target(target) -> void:
	if target == null or not is_instance_valid(target):
		return
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
	if pressed_button != MOUSE_BUTTON_LEFT or dragging:
		held_mine_target = null
		return
	if _is_world_input_blocked():
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
	if resource_manager and resource_manager.has_method("click_mine"):
		if resource_manager.has_method("can_mine_resource_node") and not bool(resource_manager.can_mine_resource_node(held_mine_target)):
			held_mine_target = null
			return
		resource_manager.click_mine(held_mine_target, is_held)

func _pick_entity(screen_pos: Vector2):
	_ensure_scene_references()
	var center = size * 0.5
	var ast_container = asteroid_container if is_instance_valid(asteroid_container) else null
	var best = null
	var bestd = 1e9
	if ast_container:
		for a in ast_container.get_children():
			var mpos = center + (a.position * world_scale) + pan
			var d = mpos.distance_to(screen_pos)
			if d < bestd and d < 24:
				bestd = d
				best = a
	if refinery_marker and refinery_marker.visible:
		var refinery_distance = refinery_marker.position.distance_to(screen_pos)
		if refinery_distance < bestd and refinery_distance < 26.0:
			bestd = refinery_distance
			best = refinery_marker
	for marker_data in ship_markers.values():
		var ship_marker = marker_data["node"] as Node2D
		if not ship_marker.visible:
			continue
		var ship_distance = ship_marker.position.distance_to(screen_pos)
		if ship_distance < bestd and ship_distance < 26.0:
			bestd = ship_distance
			best = ship_marker
	# check flotilla
	if flagship and is_instance_valid(flagship):
		var f = flagship
		var fm = center + (f.position * world_scale) + pan
		var fd = fm.distance_to(screen_pos)
		if fd < bestd and fd < 32:
			best = f
	return best

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - size * 0.5 - pan) / world_scale

func center_on_node(node: Node) -> void:
	if node == null:
		return
	# pan such that the node appears centered
	pan = -node.position * world_scale
	_camera_changed()

func _update_selection_label():
	var lbl: Label = null
	if has_node("Label"):
		lbl = get_node("Label") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "Label"
		add_child(lbl)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var target_size = Vector2(max(1.0, size.x - 36.0), 42.0)
	if not lbl.size.is_equal_approx(target_size):
		lbl.size = target_size
	var target_position = _clamp_selection_label_position(target_size)
	if not lbl.position.is_equal_approx(target_position):
		lbl.position = target_position
	if selected != null and not is_instance_valid(selected):
		selected = null
	var next_text := "Selected: None"
	var next_color := Color("d9f4ff")
	if selected == null:
		pass
	else:
		if selected.is_in_group("sun"):
			next_text = "Star"
		elif selected.is_in_group("asteroids"):
			var node_name = str(selected.get_meta("resource_display_name", "Planet" if selected.is_in_group("planet") else "Asteroid"))
			var current_scene = get_tree().get_current_scene()
			var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
			var lock_message = resource_manager.get_resource_lock_message(selected) if resource_manager and resource_manager.has_method("get_resource_lock_message") else ""
			next_text = "%s - resources: %d/%d" % [node_name, int(selected.resource_amount), int(selected.max_resource_amount)]
			if not lock_message.is_empty():
				next_text += " | %s" % lock_message
				next_color = Color("ff6f86")
		elif selected.is_in_group("flotilla"):
			next_text = "Flagship - stored: %d" % int(selected.storage)
		elif selected.is_in_group("capital_ship_marker"):
			var ship_key = str(selected.get_meta("ship_key", ""))
			next_text = "%s - %s ship" % [Catalog.get_display_name(ship_key), Catalog.get_category(ship_key).capitalize()]
		else:
			next_text = "Entity"
	if lbl.text != next_text:
		lbl.text = next_text
	if selection_label_color != next_color:
		selection_label_color = next_color
		lbl.add_theme_color_override("font_color", next_color)

func _clamp_selection_label_position(label_size: Vector2) -> Vector2:
	var margin = 18.0
	var target = Vector2(margin, size.y - label_size.y - margin)
	var max_x = max(margin, size.x - label_size.x - margin)
	var max_y = max(margin, size.y - label_size.y - margin)
	return Vector2(clamp(target.x, margin, max_x), clamp(target.y, margin, max_y))
