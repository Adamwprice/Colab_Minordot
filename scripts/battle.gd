extends Node2D

const ENEMY_MAX_HP := 500
const FLAGSHIP_MAX_HP := 100
const DRONE_MAX_HP := 10
const DRONE_ATTACK_INTERVAL := 1.0
const ENEMY_ATTACK_INTERVAL := 1.25
const ENEMY_ATTACK_DAMAGE := 5
const DRONE_ORBIT_RADIUS := 115.0
const ENEMY_HP_PER_TIER := 0.75
const ENEMY_DAMAGE_PER_TIER := 0.25
const REFINERY_MAX_HP := 100

var click_damage: int = 1
var click_rate_cap: float = 10.0
var last_click_time: float = -1.0
var mining_amount: int = 1
var boss_tier: int = 0
var enemy_max_hp: int = ENEMY_MAX_HP
var enemy_attack_damage: int = ENEMY_ATTACK_DAMAGE
var enemy_hp: int = ENEMY_MAX_HP
var flagship_max_hp: int = FLAGSHIP_MAX_HP
var flagship_hp: int = FLAGSHIP_MAX_HP
var flagship_armor: int = 0
var flagship_shield: float = 0.0
var refinery_unlocked: bool = false
var refinery_max_hp: int = REFINERY_MAX_HP
var refinery_hp: int = 0
var refinery_armor: int = 0
var refinery_shield: float = 0.0
var elapsed_time: float = 0.0
var enemy_attack_timer: float = 0.0
var battle_finished: bool = false
var drones: Array = []

var status_label: Label = null
var enemy_label: Label = null
var flagship_label: Label = null
var timer_label: Label = null
var drone_label: Label = null
var flagship_hp_display: Label = null
var enemy_hp_display: Label = null
var retreat_button: Button = null
var enemy_position := Vector2.ZERO
var flagship_position := Vector2.ZERO
var refinery_position := Vector2.ZERO

func _ready() -> void:
	_update_arena_positions()
	var game_state = get_node_or_null("/root/GameState")
	var data = {}
	if game_state:
		data = game_state.pending_battle
	click_damage = int(data.get("click_damage", 1))
	click_rate_cap = max(1.0, float(data.get("click_rate_cap", 10.0)))
	mining_amount = int(data.get("mining_amount", 1))
	boss_tier = max(0, int(data.get("boss_tier", 0)))
	var hp_scale = 1.0 + float(boss_tier) * ENEMY_HP_PER_TIER
	var damage_scale = 1.0 + float(boss_tier) * ENEMY_DAMAGE_PER_TIER
	enemy_max_hp = int(round(float(ENEMY_MAX_HP) * hp_scale))
	enemy_attack_damage = max(1, int(round(float(ENEMY_ATTACK_DAMAGE) * damage_scale)))
	enemy_hp = enemy_max_hp
	flagship_max_hp = max(1, int(data.get("flagship_max_hp", FLAGSHIP_MAX_HP)))
	flagship_hp = flagship_max_hp
	flagship_armor = max(0, int(data.get("flagship_armor", 0)))
	flagship_shield = clamp(float(data.get("flagship_shield", 0.0)), 0.0, 0.95)
	refinery_unlocked = bool(data.get("refinery_unlocked", false))
	refinery_max_hp = max(1, int(data.get("refinery_max_hp", REFINERY_MAX_HP)))
	refinery_armor = max(0, int(data.get("refinery_armor", 0)))
	refinery_shield = clamp(float(data.get("refinery_shield", 0.0)), 0.0, 0.95)
	refinery_hp = refinery_max_hp if refinery_unlocked else 0
	var drone_count = int(data.get("drone_count", 0))
	for index in range(drone_count):
		drones.append({
			"hp": DRONE_MAX_HP,
			"angle": TAU * float(index) / max(float(drone_count), 1.0),
			"attack_timer": randf_range(0.0, DRONE_ATTACK_INTERVAL)
		})
	_build_ui()
	get_viewport().size_changed.connect(Callable(self, "_layout_battle_ui"))
	_layout_battle_ui()
	set_process(true)
	queue_redraw()

func _update_arena_positions() -> void:
	var viewport_size = get_viewport_rect().size
	var arena_y = viewport_size.y * 0.58
	flagship_position = Vector2(viewport_size.x * 0.25, arena_y)
	refinery_position = flagship_position + Vector2(44.0, -34.0)
	enemy_position = Vector2(viewport_size.x * 0.75, arena_y)

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var viewport_width = get_viewport_rect().size.x
	status_label = _make_label(layer, Vector2(0, 18), "CURRENT BATTLE PRESTIGE")
	flagship_label = _make_label(layer, Vector2(0, 48), "")
	enemy_label = _make_label(layer, Vector2(0, 76), "")
	drone_label = _make_label(layer, Vector2(0, 104), "")
	timer_label = _make_label(layer, Vector2(0, 132), "")
	for label in [status_label, enemy_label, flagship_label, timer_label, drone_label]:
		label.size.x = viewport_width
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 30)
	timer_label.add_theme_color_override("font_color", Color("f4d06f"))
	flagship_hp_display = _make_label(layer, Vector2(0, 0), "")
	enemy_hp_display = _make_label(layer, Vector2(0, 0), "")
	flagship_hp_display.size = Vector2(180, 28)
	enemy_hp_display.size = Vector2(180, 28)
	flagship_hp_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flagship_hp_display.add_theme_color_override("font_color", Color("8de8ff"))
	enemy_hp_display.add_theme_color_override("font_color", Color("ff9a9a"))
	retreat_button = Button.new()
	retreat_button.name = "RetreatButton"
	retreat_button.text = "Retreat"
	retreat_button.size = Vector2(150, 28)
	layer.add_child(retreat_button)
	retreat_button.pressed.connect(Callable(self, "_on_retreat_pressed"))

func _layout_battle_ui() -> void:
	var viewport_size = get_viewport_rect().size
	if timer_label:
		timer_label.position = Vector2(0, 132.0)
		timer_label.size = Vector2(viewport_size.x, 42.0)
	if retreat_button:
		retreat_button.position = Vector2(viewport_size.x * 0.5 - 75.0, 180.0)

func _make_label(parent: Node, pos: Vector2, text: String) -> Label:
	var label = Label.new()
	label.position = pos
	label.size = Vector2(520, 24)
	label.text = text
	label.add_theme_color_override("font_color", Color("d9f4ff"))
	parent.add_child(label)
	return label

func _process(delta: float) -> void:
	if battle_finished:
		return
	_update_arena_positions()
	elapsed_time += delta
	if elapsed_time >= GameState.BATTLE_TIME_LIMIT:
		_finish_battle(false)
		return
	for drone in drones:
		if int(drone["hp"]) <= 0:
			continue
		drone["angle"] = fmod(float(drone["angle"]) + delta * 1.4, TAU)
		drone["attack_timer"] = float(drone["attack_timer"]) + delta
		if float(drone["attack_timer"]) >= DRONE_ATTACK_INTERVAL:
			drone["attack_timer"] = 0.0
			_damage_enemy(mining_amount)
	enemy_attack_timer += delta
	if enemy_attack_timer >= ENEMY_ATTACK_INTERVAL:
		enemy_attack_timer = 0.0
		_enemy_attack()
	_update_labels()
	queue_redraw()

func _unhandled_input(event) -> void:
	if battle_finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.position.distance_to(enemy_position) <= 55.0:
			if not _try_consume_click():
				return
			_damage_enemy(click_damage)

func _damage_enemy(amount: int) -> void:
	enemy_hp = max(0, enemy_hp - amount)
	if enemy_hp <= 0:
		_finish_battle(true)

func _try_consume_click() -> bool:
	var now = float(Time.get_ticks_usec()) / 1000000.0
	var minimum_interval = 1.0 / max(1.0, click_rate_cap)
	if last_click_time >= 0.0 and now - last_click_time < minimum_interval:
		return false
	last_click_time = now
	return true

func _enemy_attack() -> void:
	var living_drones = []
	for index in range(drones.size()):
		if int(drones[index]["hp"]) > 0:
			living_drones.append(index)
	if living_drones.size() > 0 and randf() < 0.85:
		var target_index = living_drones[randi() % living_drones.size()]
		drones[target_index]["hp"] = max(0, int(drones[target_index]["hp"]) - enemy_attack_damage)
	else:
		_damage_fleet_ship(enemy_attack_damage)
		if _get_fleet_hp() <= 0:
			_finish_battle(false)

func _calculate_flagship_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	var shielded_damage = float(amount) * (1.0 - flagship_shield)
	var reduced_damage = int(ceil(shielded_damage)) - flagship_armor
	return max(1, reduced_damage)

func _calculate_refinery_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	var shielded_damage = float(amount) * (1.0 - refinery_shield)
	var reduced_damage = int(ceil(shielded_damage)) - refinery_armor
	return max(1, reduced_damage)

func _damage_fleet_ship(amount: int) -> void:
	if refinery_unlocked and refinery_hp > 0 and flagship_hp > 0:
		if randf() < 0.35:
			refinery_hp = max(0, refinery_hp - _calculate_refinery_damage(amount))
		else:
			flagship_hp = max(0, flagship_hp - _calculate_flagship_damage(amount))
	elif refinery_unlocked and refinery_hp > 0:
		refinery_hp = max(0, refinery_hp - _calculate_refinery_damage(amount))
	else:
		flagship_hp = max(0, flagship_hp - _calculate_flagship_damage(amount))

func _finish_battle(victory: bool) -> void:
	if battle_finished:
		return
	battle_finished = true
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.complete_battle(victory, elapsed_time, _get_living_drone_count())
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_retreat_pressed() -> void:
	_finish_battle(false)

func _update_labels() -> void:
	var remaining = max(0, int(ceil(GameState.BATTLE_TIME_LIMIT - elapsed_time)))
	var living_drones = _get_living_drone_count()
	flagship_label.text = "FLEET HP  %d/%d  |  FLAGSHIP %d/%d" % [_get_fleet_hp(), _get_fleet_max_hp(), flagship_hp, flagship_max_hp]
	enemy_label.text = "ENEMY HP  %d/%d" % [enemy_hp, enemy_max_hp]
	drone_label.text = "DRONES  %d/%d  |  DAMAGE %d PER SECOND" % [living_drones, drones.size(), mining_amount]
	timer_label.text = "TIME  %02d" % remaining
	flagship_hp_display.text = "FLAGSHIP  %d/%d" % [flagship_hp, flagship_max_hp]
	enemy_hp_display.text = "ENEMY  %d/%d" % [enemy_hp, enemy_max_hp]
	flagship_hp_display.position = flagship_position + Vector2(-90.0, -74.0)
	enemy_hp_display.position = enemy_position + Vector2(-90.0, -74.0)

func _get_living_drone_count() -> int:
	var living_drones = 0
	for drone in drones:
		if int(drone["hp"]) > 0:
			living_drones += 1
	return living_drones

func _get_fleet_hp() -> int:
	return flagship_hp + (refinery_hp if refinery_unlocked else 0)

func _get_fleet_max_hp() -> int:
	return flagship_max_hp + (refinery_max_hp if refinery_unlocked else 0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("07111f"))
	for star_index in range(90):
		var star_pos = Vector2(fmod(float(star_index * 97 + 31), max(get_viewport_rect().size.x, 1.0)), fmod(float(star_index * 53 + 19), max(get_viewport_rect().size.y, 1.0)))
		draw_circle(star_pos, 1.0 if star_index % 4 else 2.0, Color(0.55, 0.7, 0.82, 0.35))
	draw_line(flagship_position, enemy_position, Color(0.35, 0.85, 0.95, 0.18), 2.0)
	draw_circle(flagship_position, 34.0, Color(0.2, 0.75, 0.95, 0.12))
	draw_circle(flagship_position, 22.0, Color("38b9d6"))
	draw_circle(flagship_position, 9.0, Color("d7fbff"))
	if refinery_unlocked and refinery_hp > 0:
		var diamond = PackedVector2Array([
			refinery_position + Vector2(0.0, -17.0),
			refinery_position + Vector2(17.0, 0.0),
			refinery_position + Vector2(0.0, 17.0),
			refinery_position + Vector2(-17.0, 0.0)
		])
		draw_colored_polygon(diamond, Color("84e6b1"))
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("d7ffe8"), 2.0)
	draw_circle(enemy_position, 54.0, Color(0.85, 0.1, 0.12, 0.12))
	draw_circle(enemy_position, 38.0, Color("b71d2b"))
	draw_circle(enemy_position - Vector2(12, 9), 10.0, Color(1.0, 0.42, 0.32, 0.65))
	for drone in drones:
		if int(drone["hp"]) <= 0:
			continue
		var angle = float(drone["angle"])
		var pos = enemy_position + Vector2(cos(angle), sin(angle)) * DRONE_ORBIT_RADIUS
		draw_line(pos, enemy_position, Color(0.8, 0.95, 1.0, 0.12), 1.0)
		draw_circle(pos, 7.0, Color("a9efff"))
		draw_circle(pos, 3.0, Color("ffffff"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-18.0, -14.0), "%d/%d" % [int(drone["hp"]), DRONE_MAX_HP], HORIZONTAL_ALIGNMENT_CENTER, 36.0, 10, Color("d9f4ff"))
