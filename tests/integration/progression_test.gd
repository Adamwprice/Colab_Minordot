extends SceneTree

var failures := 0

func check(ok: bool, description: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var manager = load("res://scripts/systems/mining/resource_manager.gd").new()
	manager.save_path = "res://scenes/.progression_autosave_test.save"
	var scene = Node2D.new()
	for node_name in ["Drones", "Asteroids"]:
		var node = Node2D.new()
		node.name = node_name
		scene.add_child(node)
	scene.add_child(manager)
	root.add_child(scene)
	manager.regenerate_asteroid_field(4)
	var autosave_state := {}
	if FileAccess.file_exists(manager.save_path):
		var autosave_file = FileAccess.open(manager.save_path, FileAccess.READ)
		if autosave_file:
			autosave_state = autosave_file.get_var()
			autosave_file.close()
	check(int(autosave_state.get("asteroid_field_level", -1)) == 1 and not Array(autosave_state.get("asteroids", [])).is_empty(), "Entering a generated field writes an autosave containing that field")
	manager.autosave_enabled = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path))
	var state = root.get_node("GameState")
	var catalog = load("res://scripts/data/ship_catalog.gd")
	var test_flotilla = load("res://scenes/entities/Flotilla.tscn").instantiate()
	scene.add_child(test_flotilla)
	manager.flotilla = test_flotilla
	var click_target = manager.get_best_asteroid_for(Vector2.ZERO)
	click_target.resource_amount = 100
	test_flotilla.position = click_target.position
	test_flotilla.move_target = click_target.position
	manager.last_click_time = -1.0
	manager.last_hold_click_time = -1.0
	var resource_before_macro = int(click_target.resource_amount)
	var first_macro_gain = manager.click_mine(click_target)
	for macro_click in range(50):
		manager.click_mine(click_target)
	check(first_macro_gain > 0.0 and resource_before_macro - int(click_target.resource_amount) == manager.get_click_output(), "Rapid macro input cannot exceed the manual click cap")
	manager.last_click_time = -1.0
	manager.last_hold_click_time = -1.0
	var resource_before_hold = int(click_target.resource_amount)
	var first_hold_gain = manager.click_mine(click_target, true)
	manager.last_click_time -= 1.0
	var blocked_hold_gain = manager.click_mine(click_target, true)
	manager.last_click_time -= 1.0
	var manual_after_hold_gain = manager.click_mine(click_target, false)
	check(first_hold_gain > 0.0 and blocked_hold_gain == 0.0 and manual_after_hold_gain > 0.0 and resource_before_hold - int(click_target.resource_amount) == manager.get_click_output() * 2, "Holding obeys its lower rate while manual clicks retain the shared hard cap")
	state.passive_levels["flagship_autor"] = 1
	state.autor_enabled = true
	click_target.resource_amount = 1
	manager.fleet_mining_target = click_target
	manager.autor_timer = 1.0
	manager._process_autor(0.0)
	check(manager.fleet_mining_target == null and int(click_target.resource_amount) == 0, "Autor clears a node immediately after depleting it")
	state.passive_levels["flagship_autor"] = 0
	state.autor_enabled = false
	var stale_target = load("res://scenes/entities/Asteroid.tscn").instantiate()
	scene.get_node("Asteroids").add_child(stale_target)
	stale_target.add_to_group("asteroids")
	var target_drone = load("res://scenes/entities/Drone.tscn").instantiate()
	scene.get_node("Drones").add_child(target_drone)
	target_drone.target_asteroid = stale_target
	target_drone.state = target_drone.State.TO_ASTEROID
	stale_target.free()
	target_drone._physics_process(0.016)
	manager.click_mine(stale_target)
	manager.lock_drone_focus(stale_target)
	manager.command_send_drones_to(stale_target)
	manager.set_asteroid_priority(stale_target, 1)
	check(target_drone.target_asteroid == null or is_instance_valid(target_drone.target_asteroid), "Drones and mining commands safely discard freed targets")
	var battle_rate_test = load("res://scripts/systems/combat/battle.gd").new()
	battle_rate_test.click_rate_cap = 10.0
	battle_rate_test.hold_click_rate = 2.0
	var first_battle_click = battle_rate_test._try_consume_click(false)
	var blocked_battle_clicks = 0
	for macro_click in range(50):
		if not battle_rate_test._try_consume_click(false):
			blocked_battle_clicks += 1
	check(first_battle_click and blocked_battle_clicks == 50, "Battle macros obey the same click hard cap")
	battle_rate_test.free()
	var configured_prestige_base = int(catalog.PRESTIGE_BASE_COST)
	var configured_prestige_second = int(ceil(float(catalog.PRESTIGE_BASE_COST) * float(catalog.PRESTIGE_COST_SCALE)))
	check(int(state.get_prestige_data(1)["cost"]) == configured_prestige_base and int(state.get_prestige_data(2)["cost"]) == configured_prestige_second, "Prestige costs follow the configured base and scaling curve")
	state.prestige_level = 0
	state.cap_levels["flagship_general_cap"] = 20
	check(state.get_upgrade_cap("click_output") == 10, "Prestige 0 caps research-expanded upgrades at 10")
	state.prestige_level = 1
	check(state.get_upgrade_cap("click_output") == 15, "Each prestige raises the research cap ceiling by 5")
	state.prestige_level = 0
	state.cap_levels["flagship_general_cap"] = 0
	check(manager.is_autobuy_upgrade_enabled("base", "click_output"), "Ore upgrades begin enabled for autobuy")
	check(not manager.toggle_autobuy_upgrade("base", "click_output") and manager.toggle_autobuy_upgrade("base", "click_output"), "Individual autobuy eligibility toggles off and on")
	var field_names: Array[String] = []
	for field_index in range(21):
		manager._roll_field_name()
		field_names.append(manager.current_field_name)
	check(field_names.duplicate().size() == 21 and field_names.all(func(field_name: String): return field_names.count(field_name) == 1), "Field names do not repeat within the recent-20 window")
	check(catalog.get_category("merlinda") == "utility", "Merlinda is classified as a Utility ship")
	state.dev_ship_overrides["ambrossa"] = true
	check(is_equal_approx(manager.get_ambrossa_income_amount(), 1000.0), "Ambressa starts at 1,000 Credits per cycle")
	state.dev_ship_overrides["ambrossa"] = false
	check(manager.get_hold_click_rate() == 2.0 and manager.get_click_rate_cap() == 10.0, "Starting input rates")
	state.prestige_level = 4
	state.dev_ship_overrides["starburst"] = true
	state.cap_levels["starburst_general_cap"] = 10
	manager.ship_upgrade_levels["starburst"]["combat_engines"] = 13
	check(manager.get_ship_upgrade_warning("starburst", "combat_engines").contains("reaches the hard cap"), "Cap warning before reaching limit")
	manager.ship_upgrade_levels["starburst"]["combat_engines"] = 14
	manager.total_resources = 1000000000.0
	check(manager.upgrade_ship_stat("starburst", "combat_engines"), "Overflow purchase accepted")
	var effective = manager.get_effective_ship_levels("starburst")
	var expected_starburst_share = 1.0 / 3.0
	check(is_equal_approx(effective["salvo"], expected_starburst_share) and is_equal_approx(effective["targeting_attack"], expected_starburst_share) and is_equal_approx(effective["tight_manoeuvres"], expected_starburst_share), "Overflow shared evenly")
	check(manager.get_starburst_attack_interval() == 3.0, "Hard interval floor preserved")
	check(manager.get_ship_upgrade_warning("starburst", "combat_engines").contains("Overflow:"), "Overflow warning identifies recipients")
	var snapshot = manager.get_run_state()
	manager.ship_upgrade_levels["starburst"]["combat_engines"] = 0
	manager.apply_run_state(snapshot, 0)
	check(is_equal_approx(manager.get_effective_ship_levels("starburst")["salvo"], expected_starburst_share), "Fractional overflow survives state restoration")
	manager.ship_upgrade_levels["starburst"]["salvo"] = 30
	manager.ship_upgrade_levels["starburst"]["targeting_attack"] = 30
	manager.ship_upgrade_levels["starburst"]["tight_manoeuvres"] = 30
	check(not manager.upgrade_ship_stat("starburst", "combat_engines"), "Purchase blocked when all recipients capped")
	manager.ship_upgrade_levels["starburst"] = {"combat_engines": 14, "salvo": 28, "targeting_attack": 28, "tight_manoeuvres": 28}
	var receiver_floor = (1130.0 + 900.0 + 1800.0) / 3.0 * pow(1.4, 28.0)
	check(manager.get_ship_upgrade_cost("starburst", "combat_engines") >= receiver_floor, "Overflow price reflects expensive recipients")
	var resolver = load("res://scripts/systems/upgrades/ship_upgrade_overflow.gd")
	var split = resolver.resolve("starburst", {"combat_engines": 15, "a": 0, "b": 0, "c": 0, "d": 0}, {"combat_engines": 30, "a": 30, "b": 30, "c": 30, "d": 30})
	check(is_equal_approx(split["a"], 0.25) and is_equal_approx(split["d"], 0.25), "Five-upgrade example gives quarter levels")
	state.dev_ship_overrides["stapledon"] = true
	state.cap_levels["stapledon_general_cap"] = 10
	manager.ship_upgrade_levels["stapledon"]["flare_catcher"] = 19
	check(manager.get_effective_ship_upgrade_level("stapledon", "dyson_capacity") == 0, "Fractional craft count waits for a whole unit")
	manager.ship_upgrade_levels["stapledon"]["flare_catcher"] = 20
	check(manager.get_effective_ship_upgrade_level("stapledon", "dyson_capacity") == 1, "Fractional craft credits accumulate")
	state.prestige_level = 0
	var flagship_research_strength = state.get_research_battle_multiplier("flagship_autor")
	var merlinda_research_strength = state.get_research_battle_multiplier("merlinda_checkpoint_markers")
	check(merlinda_research_strength > flagship_research_strength, "Higher-prestige ship research creates stronger battles")
	check(state.passive_levels.has("flagship_ion_thrusters") and state.passive_levels.has("racer_ion_thrusters"), "Flagship and racer Ion Thrusters are registered")
	check(state.cap_levels.has("racer_general_cap"), "Racer upgrade-cap research is registered")
	state.passive_levels["flagship_autor"] = 1
	state.pending_passive_levels["flagship_autor"] = 1
	state.research_card_unlocks["flagship_autor"] = 1
	state.cap_levels["flagship_general_cap"] = 3
	state.research_card_unlocks["flagship_general_cap"] = 3
	check(state.reset_for_prestige(), "Prestige succeeds")
	check(state.get_passive_level("flagship_autor") == 1 and int(state.pending_passive_levels["flagship_autor"]) == 1 and not state.can_battle_research_card("flagship_autor") and int(state.research_card_unlocks.get("flagship_autor", 0)) == 1, "One-time research is retained permanently through prestige")
	check(state.cap_levels["flagship_general_cap"] == 0 and state.can_battle_research_card("flagship_general_cap") and not state.research_card_unlocks.has("flagship_general_cap"), "Upgrade Cap research alone resets for prestige")
	state.prestige_level = 4
	state.boss_tier = 3
	state.passive_levels["flagship_autor"] = 1
	state.dev_ship_overrides["hammond"] = true
	state.reset_for_new_game()
	check(state.prestige_level == 0 and state.boss_tier == 0 and state.get_passive_level("flagship_autor") == 0 and state.dev_ship_overrides.is_empty(), "Restart resets persistent progression to a fresh in-memory run")
	scene.free()
	change_scene_to_file("res://scenes/core/Main.tscn")
	await scene_changed
	var ui = current_scene.get_node("UI")
	check(not ui.has_node("BattleButton"), "Obsolete battle button removed")
	var ui_manager = current_scene.get_node("ResourceManager")
	var expedition_cost = int(state.get_prestige_data(1).get("cost", 0))
	ui_manager.total_resources = expedition_cost
	ui._update_rewards_panel_values()
	var prestige_before_confirmation = state.prestige_level
	ui._on_next_prestige_pressed()
	check(ui.next_prestige_button.text.begins_with("Complete Expedition") and ui.expedition_confirmation_dialog.visible and state.prestige_level == prestige_before_confirmation and "One-time research" in ui.expedition_confirmation_dialog.dialog_text, "Complete Expedition requires an informative confirmation before recall")
	var escape_key = InputEventKey.new()
	escape_key.keycode = KEY_ESCAPE
	escape_key.pressed = true
	ui._unhandled_key_input(escape_key)
	check(not ui.expedition_confirmation_dialog.visible and not ui.pause_menu_visible, "Escape closes the expedition confirmation before opening Pause")
	ui._set_research_visibility(true)
	ui._unhandled_key_input(escape_key)
	check(not ui.research_visible and not ui.pause_menu_visible, "Escape closes Expedition Details before opening Pause")
	ui._unhandled_key_input(escape_key)
	check(ui.pause_menu_visible and paused, "Escape opens Pause when Expedition Details is closed")
	ui._set_pause_menu_visibility(false)
	ui_manager.total_resources = 0
	var autobuy_controls_parented = true
	for auto_data in ui.autobuy_toggle_buttons:
		autobuy_controls_parented = autobuy_controls_parented and (auto_data["button"] as Button).get_parent() == ui.ore_upgrade_content
	check(autobuy_controls_parented, "All autobuy controls are parented to the upgrade scroll")
	check(ui.autobuy_toggle_buttons.all(func(auto_data: Dictionary): return not (auto_data["button"] as Button).visible), "Autobuy indicators stay hidden before Development Protocol")
	state.passive_levels["flagship_development_protocol"] = 1
	ui._layout_hud()
	var visible_flagship_autobuy = ui.autobuy_toggle_buttons.filter(func(auto_data: Dictionary): return str(auto_data["section"]) == "player" and (auto_data["button"] as Button).visible).size()
	check(visible_flagship_autobuy == 5, "Development Protocol reveals Flagship autobuy indicators")
	state.passive_levels["flagship_development_protocol"] = 0
	ui._layout_hud()
	ui._set_pause_menu_visibility(true)
	check(ui.pause_overlay.visible and ui.pause_menu_visible and paused, "Escape menu pauses gameplay")
	ui._set_pause_menu_visibility(false)
	check(not ui.pause_overlay.visible and not ui.pause_menu_visible and not paused, "Resume closes the Escape menu and unpauses gameplay")
	ui._set_pause_menu_visibility(true)
	ui._on_pause_restart_pressed()
	check(ui.restart_confirmation_pending and ui.pause_restart_button.text == "Confirm Restart" and paused, "Restart requires confirmation and keeps the game paused")
	ui._set_pause_menu_visibility(false)
	check(ui.upgrade_panel.visible and ui.signal_button.visible and ui.upgrade_label.visible and not ui.drone_panel.visible and not ui.drone_signal_button.visible and not ui.drone_upgrade_label.visible and not ui.mining_text.visible, "Only the selected ore upgrade container is visible at startup")
	var map = current_scene.get_node("WorldCanvas/Map")
	check(map.get_parent() != ui and map.get_parent() is CanvasLayer and map.get_parent().layer < ui.layer, "World map and HUD use separate ordered canvas layers")
	await process_frame
	check(is_instance_valid(map.flagship) and map.flagship == current_scene.get_node("ResourceManager").flotilla, "Map reacquires the runtime Flagship for fleet visuals")
	var drag_test_origin = Vector2(8.0, 8.0)
	var drag_test_pan: Vector2 = map.pan
	map._begin_pointer_interaction(MOUSE_BUTTON_LEFT, drag_test_origin)
	map._update_pointer_drag(drag_test_origin + Vector2(40.0, 0.0))
	var left_does_not_pan = not map.dragging and map.pan.is_equal_approx(drag_test_pan)
	map._end_pointer_interaction(drag_test_origin + Vector2(40.0, 0.0))
	map._begin_pointer_interaction(MOUSE_BUTTON_RIGHT, drag_test_origin)
	map._update_pointer_drag(drag_test_origin + Vector2(40.0, 0.0))
	var right_does_pan = map.dragging and map.pan.is_equal_approx(drag_test_pan + Vector2(40.0, 0.0))
	map._end_pointer_interaction(drag_test_origin + Vector2(40.0, 0.0))
	map.pan = drag_test_pan
	check(left_does_not_pan and right_does_pan and map.POINTER_DRAG_THRESHOLD == 3.0 and map._is_camera_drag_button(MOUSE_BUTTON_MIDDLE), "Only responsive right and middle mouse drags move the camera")
	var original_move_target: Vector2 = map.flagship.move_target
	var left_move_screen = map.size * 0.5 + Vector2(120.0, 80.0)
	map._handle_pointer_click(MOUSE_BUTTON_LEFT, left_move_screen, null)
	var expected_left_target: Vector2 = map._screen_to_world(left_move_screen)
	var left_click_moves = map.flagship.move_target.is_equal_approx(expected_left_target)
	map._handle_pointer_click(MOUSE_BUTTON_RIGHT, left_move_screen + Vector2(100.0, 0.0), null)
	var right_click_does_not_move = map.flagship.move_target.is_equal_approx(expected_left_target)
	map.flagship.move_to(original_move_target)
	check(left_click_moves and right_click_does_not_move, "Left click moves the fleet and right click is camera-only")
	ui._set_research_visibility(true)
	check(ui.research_button.visible and ui.research_button.get_index() > ui.research_panel.get_index(), "Expedition Details remains above the open panel as a close toggle")
	var reward_descriptions_visible = true
	for reward_entry in ui.reward_entries.values():
		var description = reward_entry["description"] as RichTextLabel
		reward_descriptions_visible = reward_descriptions_visible and not description.text.is_empty() and not description.tooltip_text.is_empty()
	check(reward_descriptions_visible, "Prestige ship descriptions remain visible and available as tooltips")
	var development_title_ok = false
	for tile_data in ui.research_upgrade_tiles:
		if str(tile_data["key"]) == "flagship_development_protocol":
			development_title_ok = (tile_data["label"] as Label).text == "Development\nProtocol"
			break
	check(development_title_ok, "Development Protocol title stays inside its research card")
	var overlay_move_target: Vector2 = map.flagship.move_target
	var blocked_press = InputEventMouseButton.new()
	blocked_press.button_index = MOUSE_BUTTON_LEFT
	blocked_press.pressed = true
	blocked_press.position = left_move_screen
	map._gui_input(blocked_press)
	var blocked_release = InputEventMouseButton.new()
	blocked_release.button_index = MOUSE_BUTTON_LEFT
	blocked_release.pressed = false
	blocked_release.position = left_move_screen
	map._gui_input(blocked_release)
	check(map.flagship.move_target.is_equal_approx(overlay_move_target) and map.pressed_button == 0, "Expedition overlay blocks world movement input")
	ui._set_research_visibility(false)
	var hold_target: Node = null
	for field_node in current_scene.get_node("Asteroids").get_children():
		if field_node.is_in_group("asteroids") and not field_node.is_in_group("sun"):
			hold_target = field_node
			break
	if hold_target:
		map.selected = null
		var hold_screen_position = map.size * 0.5 + hold_target.position * map.world_scale + map.pan
		map._begin_pointer_interaction(MOUSE_BUTTON_LEFT, hold_screen_position)
		map.press_started_at -= 1.0
		map._update_pointer_hold_action()
	check(hold_target != null and map.hold_action_started and map.selected == hold_target, "Holding a first node click selects and activates it")
	map._cancel_pointer_interaction()
	var freed_click_target = Node2D.new()
	current_scene.add_child(freed_click_target)
	map.pressed_button = MOUSE_BUTTON_LEFT
	map.press_entity = freed_click_target
	map.selected = freed_click_target
	freed_click_target.free()
	map._end_pointer_interaction(map.size * 0.5)
	check(map.press_entity == null and map.selected == null, "A resource freed between press and release is safely discarded")
	var stale_ui_target = Node2D.new()
	current_scene.add_child(stale_ui_target)
	map.selected = stale_ui_target
	stale_ui_target.free()
	ui._on_pr_up()
	ui._on_pr_dn()
	check(map.selected == null, "Priority controls reject stale map selections")
	var camera_test_pan = map.pan + Vector2(24.0, -12.0)
	map.pan = camera_test_pan
	map._camera_changed()
	await process_frame
	await process_frame
	var background_position = map.map_background.size * 0.5 + camera_test_pan
	check(map.POINTER_HOLD_DELAY == 0.15 and not map.camera_refresh_pending and map.map_background.pan.is_equal_approx(camera_test_pan) and map.map_background.world_layer.position.is_equal_approx(background_position), "Fixed background layer follows responsive camera input")
	var shortcuts_ok = true
	for index in range(5):
		var key = InputEventKey.new()
		key.keycode = KEY_1 + index
		key.pressed = true
		ui._unhandled_key_input(key)
		shortcuts_ok = shortcuts_ok and ui.selected_ore_upgrade_tab == ui.UPGRADE_TAB_ORDER[index]
	check(shortcuts_ok, "Keys 1-5 select all upgrade categories")
	for ship_key in catalog.get_ship_ids():
		state.dev_set_ship_enabled(ship_key, true)
	var ore_panels_do_not_overlap = true
	for tab_key in ui.UPGRADE_TAB_ORDER:
		ui.selected_ore_upgrade_tab = tab_key
		ui._layout_hud()
		var visible_panels: Array[Control] = []
		for panel in [ui.upgrade_panel, ui.drone_panel]:
			if panel and panel.visible:
				visible_panels.append(panel)
		for hud_collection in [ui.ship_upgrade_huds, ui.companion_upgrade_huds]:
			for hud in hud_collection.values():
				var panel = hud["panel"] as Control
				if panel.visible:
					visible_panels.append(panel)
		for first_index in range(visible_panels.size()):
			for second_index in range(first_index + 1, visible_panels.size()):
				var first_rect = Rect2(visible_panels[first_index].position, visible_panels[first_index].size)
				var second_rect = Rect2(visible_panels[second_index].position, visible_panels[second_index].size)
				ore_panels_do_not_overlap = ore_panels_do_not_overlap and not first_rect.intersects(second_rect)
	var narrow_columns: Vector2 = ui._get_upgrade_column_positions(246.0)
	ore_panels_do_not_overlap = ore_panels_do_not_overlap and narrow_columns.x > ui.RIGHT_UPGRADE_LABEL_X and narrow_columns.y > narrow_columns.x and narrow_columns.y < 246.0
	check(ore_panels_do_not_overlap, "Ore upgrade panels and responsive columns do not overlap")
	quit(1 if failures else 0)
