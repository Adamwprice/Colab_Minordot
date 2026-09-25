extends Node2D

const Catalog = preload("res://scripts/ship_catalog.gd")

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
const PRESTIGE_ATTACK_INTERVAL := 1.0
const ENEMY_DRONE_ORBIT_RADIUS := 82.0
const ENEMY_DRONE_HIT_RADIUS := 16.0

var battle_type: String = "standard"
var prestige_target: int = 0
var click_damage: int = 1
var click_rate_cap: float = 10.0
var hold_click_rate: float = 2.0
var last_click_time: float = -1.0
var last_hold_click_time: float = -1.0
var mining_amount: float = 1.0
var drone_max_hp: int = DRONE_MAX_HP
var boss_tier: int = 0
var enemy_max_hp: int = ENEMY_MAX_HP
var enemy_attack_damage: int = ENEMY_ATTACK_DAMAGE
var enemy_attack_interval: float = ENEMY_ATTACK_INTERVAL
var enemy_name: String = "Enemy Fleet"
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
var hammond_unlocked: bool = false
var hammond_max_hp: int = 100
var hammond_hp: int = 0
var hammond_damage_reduction: float = 0.0
var hammond_damage: float = 5.0
var hammond_interval: float = 1.0
var hammond_attack_timer: float = 0.0
var hammond_damage_bank: float = 0.0
var picket_damage: float = 0.0
var picket_attack_timer: float = 0.0
var picket_damage_bank: float = 0.0
var carrier_unlocked: bool = false
var carrier_max_hp: int = 100
var carrier_hp: int = 0
var gethica_unlocked: bool = false
var gethica_max_hp: int = 100
var gethica_hp: int = 0
var ambrossa_unlocked: bool = false
var ambrossa_max_hp: int = 100
var ambrossa_hp: int = 0
var fighter_drone_damage: float = 2.0
var fighter_drone_speed: float = 1.4
var fighter_drones: Array = []
var research_card_name: String = ""
var elapsed_time: float = 0.0
var enemy_attack_timer: float = 0.0
var battle_finished: bool = false
var drones: Array = []
var enemy_drones: Array = []
var enemy_drone_max_hp: int = 0
var enemy_drone_damage: int = 0
var held_attack_target: String = ""
var held_enemy_drone_index: int = -1
var additional_fleet_ships: Array = []
var starburst_unlocked: bool = false
var starburst_damage: int = 1
var starburst_interval: float = 10.0
var starburst_timer: float = 0.0
var starburst_opening_pending: bool = false
var starburst_return_run: bool = false
var accepted_clicks: int = 0
var jackal_dps: float = 0.0
var jackal_damage_bank: float = 0.0
var jackal_opening_pending: bool = false
var jackal_strafe_speed: float = 1.0
var jackal_recovery_per_second: float = 1.0
var jackal_recovery_bank: float = 0.0
var jackal_recovering: bool = false
var ravager_unlocked: bool = false
var ravager_damage: int = 10
var ravager_interval: float = 10.0
var ravager_timer: float = 0.0
var ravager_siege_pending: bool = false
var ravager_impact_ratio: float = 0.0
var ravager_cracking: bool = false
var ravager_polarised: bool = false
var ravager_armor_break: float = 0.0
var military_command_unlocked: bool = false
var military_assault_mode: bool = false

var status_label: Label = null
var enemy_label: Label = null
var flagship_label: Label = null
var timer_label: Label = null
var drone_label: Label = null
var flagship_hp_display: Label = null
var enemy_hp_display: Label = null
var retreat_button: Button = null
var formation_button: Button = null
var enemy_position := Vector2.ZERO
var flagship_position := Vector2.ZERO
var refinery_position := Vector2.ZERO
var hammond_position := Vector2.ZERO
var carrier_position := Vector2.ZERO
var gethica_position := Vector2.ZERO
var ambrossa_position := Vector2.ZERO

func _ready() -> void:
	_update_arena_positions()
	var game_state = get_node_or_null("/root/GameState")
	var data = {}
	if game_state:
		data = game_state.pending_battle
	battle_type = str(data.get("battle_type", "standard"))
	prestige_target = max(0, int(data.get("prestige_target", 0)))
	click_damage = int(data.get("click_damage", 1))
	click_rate_cap = max(1.0, float(data.get("click_rate_cap", 10.0)))
	hold_click_rate = clamp(float(data.get("hold_click_rate", 2.0)), 1.0, click_rate_cap)
	picket_damage = max(0.0, float(data.get("picket_damage", 0.0)))
	mining_amount = max(0.0, float(data.get("mining_amount", 1.0)))
	drone_max_hp = max(1, int(data.get("drone_max_hp", DRONE_MAX_HP)))
	boss_tier = max(0, int(data.get("boss_tier", 0)))
	if battle_type != "standard":
		enemy_name = str(data.get("enemy_name", "Research Target"))
		enemy_max_hp = max(1, int(data.get("enemy_max_hp", ENEMY_MAX_HP)))
		enemy_attack_damage = max(0, int(data.get("enemy_dps", 0)))
		enemy_attack_interval = PRESTIGE_ATTACK_INTERVAL
		enemy_drone_max_hp = max(0, int(data.get("enemy_drone_hp", 0)))
		enemy_drone_damage = max(0, int(data.get("enemy_drone_dps", 0)))
		var enemy_drone_count = max(0, int(data.get("enemy_drone_count", 0)))
		for index in range(enemy_drone_count):
			enemy_drones.append({
				"hp": enemy_drone_max_hp,
				"angle": TAU * float(index) / max(float(enemy_drone_count), 1.0),
				"attack_timer": randf_range(0.0, PRESTIGE_ATTACK_INTERVAL)
			})
	else:
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
	hammond_unlocked = bool(data.get("hammond_unlocked", false))
	hammond_max_hp = max(1, int(data.get("hammond_max_hp", 100)))
	hammond_damage_reduction = clamp(float(data.get("hammond_damage_reduction", 0.0)), 0.0, 0.95)
	hammond_damage = max(0.0, float(data.get("hammond_damage", 5.0)))
	hammond_interval = max(0.1, float(data.get("hammond_interval", 1.0)))
	hammond_hp = hammond_max_hp if hammond_unlocked else 0
	carrier_unlocked = bool(data.get("carrier_unlocked", false))
	carrier_hp = carrier_max_hp if carrier_unlocked else 0
	gethica_unlocked = bool(data.get("gethica_unlocked", false))
	gethica_hp = gethica_max_hp if gethica_unlocked else 0
	ambrossa_unlocked = bool(data.get("ambrossa_unlocked", false))
	ambrossa_hp = ambrossa_max_hp if ambrossa_unlocked else 0
	additional_fleet_ships = Array(data.get("additional_fleet_ships", [])).duplicate(true)
	for ship in additional_fleet_ships:
		ship["hp"] = int(ship.get("max_hp", 100))
	starburst_unlocked = bool(data.get("starburst_unlocked", false))
	starburst_damage = max(1, int(data.get("starburst_damage", 20)))
	starburst_interval = max(1.0, float(data.get("starburst_interval", 10.0)))
	starburst_opening_pending = bool(data.get("starburst_opening", false))
	starburst_return_run = bool(data.get("starburst_return_run", false))
	jackal_dps = max(0.0, float(data.get("jackal_dps", 0.0)))
	jackal_strafe_speed = max(0.1, float(data.get("jackal_strafe_speed", 1.0)))
	jackal_recovery_per_second = max(0.0, float(data.get("jackal_recovery_per_second", 1.0)))
	jackal_opening_pending = bool(data.get("jackal_opening", false))
	military_command_unlocked = bool(data.get("brooder_military_command", false))
	ravager_unlocked = bool(data.get("ravager_unlocked", false))
	ravager_damage = max(1, int(data.get("ravager_damage", 10)))
	ravager_interval = max(1.0, float(data.get("ravager_interval", 10.0)))
	ravager_impact_ratio = max(0.0, float(data.get("ravager_impact_ratio", 0.0)))
	ravager_siege_pending = bool(data.get("ravager_siege", false))
	ravager_cracking = bool(data.get("ravager_cracking", false))
	ravager_polarised = bool(data.get("ravager_polarised", false))
	fighter_drone_damage = max(0.0, float(data.get("fighter_drone_damage", 2.0)))
	fighter_drone_speed = max(0.1, float(data.get("fighter_drone_speed", 1.4)))
	research_card_name = str(data.get("research_card_name", ""))
	var fighter_count = max(0, int(data.get("fighter_drone_count", 0)))
	for index in range(fighter_count):
		fighter_drones.append({
			"angle": TAU * float(index) / max(float(fighter_count), 1.0),
			"attack_timer": randf_range(0.0, DRONE_ATTACK_INTERVAL),
			"damage_bank": 0.0
		})
	var drone_count = int(data.get("drone_count", 0))
	for index in range(drone_count):
		drones.append({
			"hp": drone_max_hp,
			"angle": TAU * float(index) / max(float(drone_count), 1.0),
			"attack_timer": randf_range(0.0, DRONE_ATTACK_INTERVAL),
			"damage_bank": 0.0
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
	refinery_position = flagship_position + Vector2(-42.0, 28.0)
	hammond_position = flagship_position + Vector2(-54.0, -25.0)
	carrier_position = flagship_position + Vector2(-90.0, 4.0)
	gethica_position = flagship_position + Vector2(42.0, 32.0)
	ambrossa_position = flagship_position + Vector2(50.0, -30.0)
	enemy_position = Vector2(viewport_size.x * 0.75, arena_y)

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var viewport_width = get_viewport_rect().size.x
	status_label = _make_label(layer, Vector2(0, 18), "")
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
	if military_command_unlocked:
		formation_button = Button.new()
		formation_button.name = "FormationButton"
		formation_button.text = "Formation: Guard"
		formation_button.tooltip_text = "Guard reduces incoming damage to military ships. Assault increases military damage by 15%."
		formation_button.size = Vector2(170, 28)
		layer.add_child(formation_button)
		formation_button.pressed.connect(Callable(self, "_on_formation_pressed"))

func _layout_battle_ui() -> void:
	var viewport_size = get_viewport_rect().size
	if timer_label:
		timer_label.position = Vector2(0, 132.0)
		timer_label.size = Vector2(viewport_size.x, 42.0)
	if retreat_button:
		retreat_button.position = Vector2(viewport_size.x * 0.5 - 75.0, 180.0)
	if formation_button:
		formation_button.position = Vector2(viewport_size.x * 0.5 - 85.0, 216.0)

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
	_update_held_attack()
	if battle_finished:
		return
	for drone in drones:
		if int(drone["hp"]) <= 0:
			continue
		drone["angle"] = fmod(float(drone["angle"]) + delta * 1.4, TAU)
		drone["attack_timer"] = float(drone["attack_timer"]) + delta
		if float(drone["attack_timer"]) >= DRONE_ATTACK_INTERVAL:
			drone["attack_timer"] = 0.0
			drone["damage_bank"] = float(drone["damage_bank"]) + mining_amount
			var drone_damage = int(floor(float(drone["damage_bank"])))
			if drone_damage > 0:
				drone["damage_bank"] = float(drone["damage_bank"]) - float(drone_damage)
				_damage_active_enemy(drone_damage)
	for fighter in fighter_drones:
		fighter["angle"] = fmod(float(fighter["angle"]) + delta * fighter_drone_speed, TAU)
		fighter["attack_timer"] = float(fighter["attack_timer"]) + delta
		if float(fighter["attack_timer"]) >= DRONE_ATTACK_INTERVAL:
			fighter["attack_timer"] = 0.0
			fighter["damage_bank"] = float(fighter["damage_bank"]) + fighter_drone_damage
			var fighter_damage = int(floor(float(fighter["damage_bank"])))
			if fighter_damage > 0:
				fighter["damage_bank"] = float(fighter["damage_bank"]) - float(fighter_damage)
				_damage_active_enemy(_get_military_attack_damage(fighter_damage))
	if starburst_unlocked and _is_additional_ship_alive("starburst"):
		starburst_timer += delta
		if starburst_opening_pending or starburst_timer >= starburst_interval:
			starburst_opening_pending = false
			starburst_timer = fmod(starburst_timer, starburst_interval)
			var strike_count = 2 if starburst_return_run else 1
			for strike_index in range(strike_count):
				_damage_active_enemy(_get_military_attack_damage(starburst_damage))
	_update_jackal_recovery(delta)
	if jackal_opening_pending and _is_additional_ship_alive("jackal"):
		jackal_opening_pending = false
		_damage_active_enemy(_get_military_attack_damage(max(1, int(ceil(jackal_dps)))))
	if jackal_dps > 0.0 and _is_additional_ship_alive("jackal") and not jackal_recovering:
		jackal_damage_bank += jackal_dps * delta
		var jackal_damage = int(floor(jackal_damage_bank))
		if jackal_damage > 0:
			jackal_damage_bank -= float(jackal_damage)
			_damage_active_enemy(_get_military_attack_damage(jackal_damage))
	if ravager_unlocked and _is_additional_ship_alive("ravager"):
		ravager_timer += delta
		if ravager_siege_pending or ravager_timer >= ravager_interval:
			var ravager_shots = 2 if ravager_siege_pending else 1
			ravager_siege_pending = false
			ravager_timer = fmod(ravager_timer, ravager_interval)
			for shot_index in range(ravager_shots):
				_fire_ravager()
	if hammond_unlocked and hammond_hp > 0:
		hammond_attack_timer += delta
		if hammond_attack_timer >= hammond_interval:
			hammond_attack_timer = fmod(hammond_attack_timer, hammond_interval)
			hammond_damage_bank += hammond_damage
			var dealt_damage = int(floor(hammond_damage_bank))
			hammond_damage_bank -= float(dealt_damage)
			_damage_active_enemy(_get_military_attack_damage(max(1, dealt_damage)))
	if picket_damage > 0.0 and flagship_hp > 0:
		picket_attack_timer += delta
		if picket_attack_timer >= 1.0:
			picket_attack_timer = fmod(picket_attack_timer, 1.0)
			picket_damage_bank += picket_damage
			var picket_dealt_damage = int(floor(picket_damage_bank))
			picket_damage_bank -= float(picket_dealt_damage)
			if picket_dealt_damage > 0:
				_damage_active_enemy(picket_dealt_damage)
	for enemy_drone in enemy_drones:
		if int(enemy_drone["hp"]) <= 0:
			continue
		enemy_drone["angle"] = fmod(float(enemy_drone["angle"]) - delta * 1.0, TAU)
		enemy_drone["attack_timer"] = float(enemy_drone["attack_timer"]) + delta
		if float(enemy_drone["attack_timer"]) >= PRESTIGE_ATTACK_INTERVAL:
			enemy_drone["attack_timer"] = 0.0
			_attack_player(enemy_drone_damage)
			if _get_fleet_hp() <= 0:
				_finish_battle(false)
				return
	enemy_attack_timer += delta
	if enemy_attack_damage > 0 and enemy_attack_timer >= enemy_attack_interval:
		enemy_attack_timer = 0.0
		_attack_player(enemy_attack_damage)
		if _get_fleet_hp() <= 0:
			_finish_battle(false)
			return
	_update_labels()
	queue_redraw()

func _unhandled_input(event) -> void:
	if battle_finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_clear_held_attack()
			return
		_clear_held_attack()
		for index in range(enemy_drones.size()):
			if int(enemy_drones[index]["hp"]) <= 0:
				continue
			if event.position.distance_to(_get_enemy_drone_position(index)) <= ENEMY_DRONE_HIT_RADIUS:
				held_attack_target = "drone"
				held_enemy_drone_index = index
				_attack_held_target(false)
				return
		if event.position.distance_to(enemy_position) <= 55.0:
			held_attack_target = "boss"
			_attack_held_target(false)

func _update_held_attack() -> void:
	if held_attack_target.is_empty():
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_clear_held_attack()
		return
	_attack_held_target(true)

func _attack_held_target(is_held: bool) -> void:
	if held_attack_target == "drone":
		if held_enemy_drone_index < 0 or held_enemy_drone_index >= enemy_drones.size() or int(enemy_drones[held_enemy_drone_index]["hp"]) <= 0:
			held_enemy_drone_index = _get_first_living_enemy_drone_index()
			if held_enemy_drone_index < 0:
				held_attack_target = "boss"
	if not _try_consume_click(is_held):
		return
	accepted_clicks += 1
	if held_attack_target == "drone":
		_damage_enemy_drone(held_enemy_drone_index, click_damage)
	elif held_attack_target == "boss":
		_damage_enemy(click_damage)
	if starburst_unlocked and accepted_clicks % 5 == 0:
		_damage_active_enemy(_get_military_attack_damage(starburst_damage))

func _clear_held_attack() -> void:
	held_attack_target = ""
	held_enemy_drone_index = -1

func _damage_enemy(amount: int) -> void:
	if _get_living_enemy_drone_count() > 0:
		return
	enemy_hp = max(0, enemy_hp - amount)
	if enemy_hp <= 0:
		_finish_battle(true)

func _damage_active_enemy(amount: int) -> void:
	for index in range(enemy_drones.size()):
		if int(enemy_drones[index]["hp"]) > 0:
			_damage_enemy_drone(index, amount)
			return
	_damage_enemy(amount)

func _fire_ravager() -> void:
	var shot_damage = max(1, int(round(float(ravager_damage) * (1.0 + ravager_armor_break))))
	shot_damage = _get_military_attack_damage(shot_damage)
	var shielded_at_impact = _get_living_enemy_drone_count() > 0
	_damage_active_enemy(shot_damage)
	if battle_finished:
		return
	if ravager_impact_ratio > 0.0:
		var splash_damage = max(1, int(round(float(shot_damage) * ravager_impact_ratio)))
		for index in range(enemy_drones.size()):
			if int(enemy_drones[index]["hp"]) > 0:
				_damage_enemy_drone(index, splash_damage)
	if ravager_polarised and shielded_at_impact:
		var shield_bypass = max(1, int(round(float(shot_damage) * 0.10)))
		enemy_hp = max(0, enemy_hp - shield_bypass)
		if enemy_hp <= 0:
			_finish_battle(true)
			return
	if ravager_cracking:
		ravager_armor_break = min(1.0, ravager_armor_break + 0.05)

func _get_military_attack_damage(amount: int) -> int:
	return max(1, int(round(float(amount) * (1.15 if military_assault_mode else 1.0))))

func _get_additional_ship_index(ship_key: String) -> int:
	for index in range(additional_fleet_ships.size()):
		if str(additional_fleet_ships[index].get("key", "")) == ship_key:
			return index
	return -1

func _is_additional_ship_alive(ship_key: String) -> bool:
	var index = _get_additional_ship_index(ship_key)
	return index >= 0 and int(additional_fleet_ships[index].get("hp", 0)) > 0

func _update_jackal_recovery(delta: float) -> void:
	var index = _get_additional_ship_index("jackal")
	if index < 0 or int(additional_fleet_ships[index].get("hp", 0)) <= 0:
		jackal_recovering = false
		return
	var hp = int(additional_fleet_ships[index]["hp"])
	var max_hp = int(additional_fleet_ships[index].get("max_hp", 100))
	if hp <= int(round(float(max_hp) * 0.35)):
		jackal_recovering = true
	if not jackal_recovering:
		return
	jackal_recovery_bank += jackal_recovery_per_second * delta
	var recovered = int(floor(jackal_recovery_bank))
	if recovered > 0:
		jackal_recovery_bank -= float(recovered)
		additional_fleet_ships[index]["hp"] = min(max_hp, hp + recovered)
	if int(additional_fleet_ships[index]["hp"]) >= int(round(float(max_hp) * 0.75)):
		jackal_recovering = false

func _on_formation_pressed() -> void:
	military_assault_mode = not military_assault_mode
	if formation_button:
		formation_button.text = "Formation: Assault" if military_assault_mode else "Formation: Guard"

func _damage_enemy_drone(index: int, amount: int) -> void:
	if index < 0 or index >= enemy_drones.size():
		return
	enemy_drones[index]["hp"] = max(0, int(enemy_drones[index]["hp"]) - amount)

func _try_consume_click(is_held: bool = false) -> bool:
	var now = float(Time.get_ticks_usec()) / 1000000.0
	var minimum_interval = 1.0 / max(1.0, click_rate_cap)
	if last_click_time >= 0.0 and now - last_click_time < minimum_interval:
		return false
	if is_held:
		var hold_interval = 1.0 / max(1.0, hold_click_rate)
		if last_hold_click_time >= 0.0 and now - last_hold_click_time < hold_interval:
			return false
		last_hold_click_time = now
	last_click_time = now
	return true

func _attack_player(amount: int) -> void:
	if amount <= 0:
		return
	var living_drones = []
	for index in range(drones.size()):
		if int(drones[index]["hp"]) > 0:
			living_drones.append(index)
	if living_drones.size() > 0 and randf() < 0.85:
		var target_index = living_drones[randi() % living_drones.size()]
		drones[target_index]["hp"] = max(0, int(drones[target_index]["hp"]) - amount)
	else:
		_damage_fleet_ship(amount)

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
	var living_ships: Array[String] = []
	if flagship_hp > 0:
		living_ships.append("flagship")
	if refinery_unlocked and refinery_hp > 0:
		living_ships.append("refinery")
	if hammond_unlocked and hammond_hp > 0:
		living_ships.append("hammond")
	if carrier_unlocked and carrier_hp > 0:
		living_ships.append("carrier")
	if gethica_unlocked and gethica_hp > 0:
		living_ships.append("gethica")
	if ambrossa_unlocked and ambrossa_hp > 0:
		living_ships.append("ambrossa")
	for index in range(additional_fleet_ships.size()):
		if int(additional_fleet_ships[index].get("hp", 0)) > 0:
			living_ships.append("additional:%d" % index)
	if living_ships.is_empty():
		return
	var target_key = living_ships[randi() % living_ships.size()]
	if target_key.begins_with("additional:"):
		var target_index = int(target_key.get_slice(":", 1))
		var target_amount = amount
		if military_command_unlocked and not military_assault_mode and str(additional_fleet_ships[target_index].get("category", "")) == "military":
			target_amount = max(1, int(ceil(float(amount) * 0.85)))
		additional_fleet_ships[target_index]["hp"] = max(0, int(additional_fleet_ships[target_index]["hp"]) - target_amount)
		return
	match target_key:
		"refinery": refinery_hp = max(0, refinery_hp - _calculate_refinery_damage(amount))
		"hammond": hammond_hp = max(0, hammond_hp - max(1, int(ceil(float(amount) * (1.0 - hammond_damage_reduction) * (0.85 if military_command_unlocked and not military_assault_mode else 1.0)))))
		"carrier": carrier_hp = max(0, carrier_hp - amount)
		"gethica": gethica_hp = max(0, gethica_hp - amount)
		"ambrossa": ambrossa_hp = max(0, ambrossa_hp - amount)
		_: flagship_hp = max(0, flagship_hp - _calculate_flagship_damage(amount))

func _finish_battle(victory: bool) -> void:
	if battle_finished:
		return
	battle_finished = true
	_clear_held_attack()
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.complete_battle(victory, elapsed_time, _get_living_drone_count())
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_retreat_pressed() -> void:
	_finish_battle(false)

func _update_labels() -> void:
	var remaining = max(0, int(ceil(GameState.BATTLE_TIME_LIMIT - elapsed_time)))
	var living_drones = _get_living_drone_count()
	var living_enemy_drones = _get_living_enemy_drone_count()
	status_label.text = "RESEARCH HUNT | %s" % research_card_name if battle_type == "research_hunt" else "FLEET BATTLE"
	flagship_label.text = "FLEET HP  %d/%d  |  FLAGSHIP %d/%d" % [_get_fleet_hp(), _get_fleet_max_hp(), flagship_hp, flagship_max_hp]
	enemy_label.text = "%s  %d/%d%s" % [enemy_name.to_upper(), enemy_hp, enemy_max_hp, "  |  SHIELDED" if living_enemy_drones > 0 else ""]
	drone_label.text = "YOUR DRONES %d/%d | DAMAGE %.2f/S" % [living_drones, drones.size(), mining_amount]
	if picket_damage > 0.0:
		drone_label.text += "  |  PICKET %.1f DPS" % picket_damage
	if hammond_unlocked and hammond_hp > 0:
		drone_label.text += "  |  HAMMOND %.2f DPS" % (hammond_damage / hammond_interval)
	if starburst_unlocked:
		drone_label.text += "  |  STARBURST %d/RUN" % starburst_damage
	if jackal_dps > 0.0:
		drone_label.text += "  |  JACKAL %.2f DPS" % jackal_dps
	if not enemy_drones.is_empty():
		drone_label.text += "  |  ENEMY DRONES %d/%d | %d DPS EACH" % [living_enemy_drones, enemy_drones.size(), enemy_drone_damage]
	timer_label.text = "TIME  %02d" % remaining
	flagship_hp_display.text = "FLAGSHIP  %d/%d" % [flagship_hp, flagship_max_hp]
	enemy_hp_display.text = "%s  %d/%d" % [enemy_name.to_upper(), enemy_hp, enemy_max_hp]
	flagship_hp_display.position = flagship_position + Vector2(-90.0, -74.0)
	enemy_hp_display.position = enemy_position + Vector2(-90.0, -74.0)

func _get_living_drone_count() -> int:
	var living_drones = 0
	for drone in drones:
		if int(drone["hp"]) > 0:
			living_drones += 1
	return living_drones

func _get_living_enemy_drone_count() -> int:
	var living_drones = 0
	for drone in enemy_drones:
		if int(drone["hp"]) > 0:
			living_drones += 1
	return living_drones

func _get_first_living_enemy_drone_index() -> int:
	for index in range(enemy_drones.size()):
		if int(enemy_drones[index]["hp"]) > 0:
			return index
	return -1

func _get_enemy_drone_position(index: int) -> Vector2:
	var angle = float(enemy_drones[index]["angle"])
	return enemy_position + Vector2(cos(angle), sin(angle)) * ENEMY_DRONE_ORBIT_RADIUS

func _get_fleet_hp() -> int:
	var total = flagship_hp + (refinery_hp if refinery_unlocked else 0) + (hammond_hp if hammond_unlocked else 0) + (carrier_hp if carrier_unlocked else 0) + (gethica_hp if gethica_unlocked else 0) + (ambrossa_hp if ambrossa_unlocked else 0)
	for ship in additional_fleet_ships:
		total += int(ship.get("hp", 0))
	return total

func _get_fleet_max_hp() -> int:
	var total = flagship_max_hp + (refinery_max_hp if refinery_unlocked else 0) + (hammond_max_hp if hammond_unlocked else 0) + (carrier_max_hp if carrier_unlocked else 0) + (gethica_max_hp if gethica_unlocked else 0) + (ambrossa_max_hp if ambrossa_unlocked else 0)
	for ship in additional_fleet_ships:
		total += int(ship.get("max_hp", 100))
	return total

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("07111f"))
	for star_index in range(90):
		var star_pos = Vector2(fmod(float(star_index * 97 + 31), max(get_viewport_rect().size.x, 1.0)), fmod(float(star_index * 53 + 19), max(get_viewport_rect().size.y, 1.0)))
		draw_circle(star_pos, 1.0 if star_index % 4 else 2.0, Color(0.55, 0.7, 0.82, 0.35))
	draw_line(flagship_position, enemy_position, Color(0.35, 0.85, 0.95, 0.18), 2.0)
	if refinery_unlocked and refinery_hp > 0:
		var diamond = PackedVector2Array([
			refinery_position + Vector2(0.0, -17.0),
			refinery_position + Vector2(17.0, 0.0),
			refinery_position + Vector2(0.0, 17.0),
			refinery_position + Vector2(-17.0, 0.0)
		])
		draw_colored_polygon(diamond, Color("84e6b1"))
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("d7ffe8"), 2.0)
	if hammond_unlocked and hammond_hp > 0:
		draw_rect(Rect2(hammond_position - Vector2(20.0, 10.0), Vector2(40.0, 20.0)), Color("d65b5b"))
		draw_rect(Rect2(hammond_position - Vector2(20.0, 10.0), Vector2(40.0, 20.0)), Color("ffd1cc"), false, 2.0)
	if carrier_unlocked and carrier_hp > 0:
		var carrier_shape = PackedVector2Array([carrier_position + Vector2(-24, 0), carrier_position + Vector2(-10, -13), carrier_position + Vector2(22, -8), carrier_position + Vector2(22, 8), carrier_position + Vector2(-10, 13)])
		draw_colored_polygon(carrier_shape, Color("8d78d6"))
		draw_polyline(PackedVector2Array([carrier_shape[0], carrier_shape[1], carrier_shape[2], carrier_shape[3], carrier_shape[4], carrier_shape[0]]), Color("e0d8ff"), 2.0)
	if gethica_unlocked and gethica_hp > 0:
		var gethica_shape = PackedVector2Array([gethica_position + Vector2(-18, 0), gethica_position + Vector2(-4, -9), gethica_position + Vector2(19, 0), gethica_position + Vector2(-4, 9)])
		draw_colored_polygon(gethica_shape, Color("4fbfb6"))
		draw_polyline(PackedVector2Array([gethica_shape[0], gethica_shape[1], gethica_shape[2], gethica_shape[3], gethica_shape[0]]), Color("c9fff8"), 2.0)
	if ambrossa_unlocked and ambrossa_hp > 0:
		var ambrossa_rect = Rect2(ambrossa_position - Vector2(21.0, 11.0), Vector2(42.0, 22.0))
		draw_rect(ambrossa_rect, Color("d5aa4e"))
		draw_rect(ambrossa_rect, Color("fff0b8"), false, 2.0)
	for index in range(additional_fleet_ships.size()):
		var ship = additional_fleet_ships[index]
		if int(ship.get("hp", 0)) <= 0:
			continue
		var ship_position = _get_battle_ship_position(index, ship)
		var category = str(ship.get("category", "civilian"))
		var color: Color = Catalog.CATEGORY_COLORS.get(category, Color.WHITE)
		var ship_rect = Rect2(ship_position - Vector2(12.0, 6.0), Vector2(24.0, 12.0))
		draw_rect(ship_rect, color)
		draw_rect(ship_rect, color.lightened(0.35), false, 1.0)
		draw_string(ThemeDB.fallback_font, ship_position + Vector2(-20.0, -11.0), "%d" % int(ship["hp"]), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 9, color.lightened(0.3))
		if str(ship.get("key", "")) == "ravager" and ravager_interval > 0.0:
			var charge = clamp(ravager_timer / ravager_interval, 0.0, 1.0)
			draw_line(ship_position + Vector2(12.0, 0.0), ship_position.lerp(enemy_position, charge), Color(1.0, 0.45, 0.3, 0.18 + charge * 0.45), 2.0 + charge * 2.0)
	draw_circle(flagship_position, 34.0, Color(0.2, 0.75, 0.95, 0.12))
	draw_circle(flagship_position, 22.0, Color("38b9d6"))
	draw_circle(flagship_position, 9.0, Color("d7fbff"))
	draw_circle(enemy_position, 54.0, Color(0.85, 0.1, 0.12, 0.12))
	draw_circle(enemy_position, 38.0, Color("b71d2b"))
	draw_circle(enemy_position - Vector2(12, 9), 10.0, Color(1.0, 0.42, 0.32, 0.65))
	for index in range(enemy_drones.size()):
		var enemy_drone = enemy_drones[index]
		if int(enemy_drone["hp"]) <= 0:
			continue
		var enemy_drone_pos = _get_enemy_drone_position(index)
		draw_line(enemy_drone_pos, enemy_position, Color(1.0, 0.35, 0.3, 0.18), 1.0)
		draw_circle(enemy_drone_pos, 11.0, Color("c83a42"))
		draw_circle(enemy_drone_pos, 4.0, Color("ffd0c7"))
		draw_string(ThemeDB.fallback_font, enemy_drone_pos + Vector2(-20.0, -17.0), "%d/%d" % [int(enemy_drone["hp"]), enemy_drone_max_hp], HORIZONTAL_ALIGNMENT_CENTER, 40.0, 10, Color("ffc8bf"))
	for drone in drones:
		if int(drone["hp"]) <= 0:
			continue
		var angle = float(drone["angle"])
		var pos = enemy_position + Vector2(cos(angle), sin(angle)) * DRONE_ORBIT_RADIUS
		draw_line(pos, enemy_position, Color(0.8, 0.95, 1.0, 0.12), 1.0)
		draw_circle(pos, 7.0, Color("a9efff"))
		draw_circle(pos, 3.0, Color("ffffff"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-18.0, -14.0), "%d/%d" % [int(drone["hp"]), drone_max_hp], HORIZONTAL_ALIGNMENT_CENTER, 36.0, 10, Color("d9f4ff"))
	for fighter in fighter_drones:
		var fighter_angle = float(fighter["angle"])
		var fighter_pos = enemy_position + Vector2(cos(fighter_angle), sin(fighter_angle)) * (DRONE_ORBIT_RADIUS + 28.0)
		draw_circle(fighter_pos, 5.0, Color("f4d06f"))
		draw_line(fighter_pos, enemy_position, Color(0.95, 0.75, 0.3, 0.16), 1.0)

func _get_battle_ship_position(index: int, ship: Dictionary) -> Vector2:
	var ship_key = str(ship.get("key", ""))
	if ship_key == "starburst":
		var phase = fmod(starburst_timer / max(starburst_interval, 0.1), 1.0)
		var run_progress = phase * 2.0 if phase <= 0.5 else (1.0 - phase) * 2.0
		return flagship_position.lerp(enemy_position, run_progress * 0.82) + Vector2(0.0, -55.0)
	if ship_key == "jackal":
		if jackal_recovering:
			return flagship_position + Vector2(35.0, -45.0)
		var strafe_phase = elapsed_time * jackal_strafe_speed
		return enemy_position + Vector2(sin(strafe_phase) * 145.0, cos(strafe_phase * 0.5) * 78.0)
	if ship_key == "ravager":
		return flagship_position + Vector2(-115.0, 95.0)
	var ring = int(index / 8)
	var slot = index % 8
	var angle = PI + (float(slot) / 7.0 - 0.5) * PI * 0.9
	var radius = 72.0 + float(ring) * 34.0
	return flagship_position + Vector2(cos(angle), sin(angle)) * radius
