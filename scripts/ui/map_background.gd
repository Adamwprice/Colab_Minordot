extends Control

const SYSTEM_RING_SEGMENTS := 72

class WorldLayer:
	extends Node2D

	var ring_radii := PackedFloat32Array()
	var ring_types := PackedByteArray()
	var camera_scale := 0.04

	func configure(radii: PackedFloat32Array, types: PackedByteArray, scale_value: float) -> void:
		ring_radii = radii
		ring_types = types
		camera_scale = scale_value
		queue_redraw()

	func set_camera_scale(scale_value: float) -> void:
		if is_equal_approx(camera_scale, scale_value):
			return
		camera_scale = scale_value
		queue_redraw()

	func _draw() -> void:
		var world_line_width = 1.0 / max(camera_scale, 0.001)
		for ring_offset in range(ring_radii.size()):
			var is_planet_ring = ring_offset < ring_types.size() and bool(ring_types[ring_offset])
			var ring_color = Color(0.88, 0.24, 0.27, 0.045) if is_planet_ring else Color(0.86, 0.58, 0.28, 0.06)
			draw_arc(Vector2.ZERO, ring_radii[ring_offset], 0.0, TAU, SYSTEM_RING_SEGMENTS, ring_color, world_line_width)

var world_scale: float = 0.04
var pan := Vector2.ZERO
var world_layer: WorldLayer = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer = WorldLayer.new()
	world_layer.name = "FixedWorldLayer"
	world_layer.z_index = 1
	add_child(world_layer)
	var ring_radii := PackedFloat32Array()
	var ring_types := PackedByteArray()
	var current_scene = get_tree().get_current_scene()
	var resource_manager = current_scene.get_node_or_null("ResourceManager") if current_scene else null
	if resource_manager and resource_manager.has_method("get_system_ring_radii"):
		ring_radii = resource_manager.get_system_ring_radii()
		for ring_offset in range(ring_radii.size()):
			ring_types.append(1 if resource_manager.is_planet_spawn_ring(ring_offset + 1) else 0)
	world_layer.configure(ring_radii, ring_types, world_scale)
	resized.connect(_on_resized)
	_update_world_transform()
	queue_redraw()

func set_camera(scale_value: float, pan_value: Vector2) -> void:
	if is_equal_approx(world_scale, scale_value) and pan.is_equal_approx(pan_value):
		return
	var scale_changed = not is_equal_approx(world_scale, scale_value)
	world_scale = scale_value
	pan = pan_value
	if world_layer:
		if scale_changed:
			world_layer.set_camera_scale(world_scale)
		_update_world_transform()

func _on_resized() -> void:
	_update_world_transform()
	queue_redraw()

func _update_world_transform() -> void:
	if world_layer == null:
		return
	world_layer.position = size * 0.5 + pan
	world_layer.scale = Vector2.ONE * world_scale

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111f"))
	for star_index in range(140):
		var star_x = fmod(float(star_index * 83 + 29), max(size.x, 1.0))
		var star_y = fmod(float(star_index * 47 + 17), max(size.y, 1.0))
		var star_size = 1.0 if star_index % 4 else 2.0
		draw_circle(Vector2(star_x, star_y), star_size, Color(0.55, 0.7, 0.82, 0.35))
