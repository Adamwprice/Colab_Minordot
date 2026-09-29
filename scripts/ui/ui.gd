extends CanvasLayer

const Catalog = preload("res://scripts/data/ship_catalog.gd")

var resource_manager: Node = null
var resource_label: Label = null
var last_action_label: Label = null
var fleet_label: Label = null
var stage_label: Label = null
var fps_label: Label = null
var right_ore_label: Label = null
var fleet_maneuver_button: Button = null
var development_protocol_button: Button = null
var upgrade_label: Label = null
var speed_button: Button = null
var mining_button: Button = null
var mining_speed_button: Button = null
var refining_button: Button = null
var capacity_button: Button = null
var drone_button: Button = null
var click_output_button: Button = null
var click_multiplier_button: Button = null
var signal_button: Button = null
var drone_signal_button: Button = null
var speed_text: Label = null
var mining_text: Label = null
var mining_speed_text: Label = null
var refining_text: Label = null
var capacity_text: Label = null
var drone_text: Label = null
var click_output_text: Label = null
var click_multiplier_text: Label = null
var drone_upgrade_label: Label = null
var refinery_upgrade_label: Label = null
var refinery_signal_button: Button = null
var flagship_speed_text: Label = null
var flagship_speed_button: Button = null
var command_capacity_text: Label = null
var command_capacity_button: Button = null
var controls_toggle_button: Button = null
var controls_label: Label = null
var dev_panel: Panel = null
var dev_label: Label = null
var dev_add_ore_button: Button = null
var dev_prestige_button: Button = null
var research_button: Button = null
var research_panel: Panel = null
var research_toggle_button: Button = null
var research_status_label: Label = null
var research_tab_button: Button = null
var rewards_tab_button: Button = null
var next_prestige_button: Button = null
var expedition_confirmation_dialog: ConfirmationDialog = null
var pending_expedition_target: int = 0
var research_scroll_container: ScrollContainer = null
var rewards_scroll_container: ScrollContainer = null
var research_scroll_content: Control = null
var rewards_scroll_content: Control = null
var research_category_buttons := {}
var research_empty_label: Label = null
var research_rows: Array = []
var research_upgrade_tiles: Array = []
var research_row_controls: Array[Control] = []
var research_ship_lock_labels := {}
var reward_controls: Array[Control] = []
var reward_entries := {}
var prestige_boss_levels: Array[int] = []
var upgrade_panel: Panel = null
var drone_panel: Panel = null
var refinery_panel: Panel = null
var ore_upgrade_scroll: ScrollContainer = null
var ore_upgrade_content: Control = null
var ore_upgrade_tab_buttons := {}
var ore_upgrade_empty_label: Label = null
var player_separators: Array[Control] = []
var drone_separators: Array[Control] = []
var player_level_texts: Array[Label] = []
var player_effect_texts: Array[Label] = []
var drone_level_texts: Array[Label] = []
var drone_effect_texts: Array[Label] = []
var refinery_upgrade_texts: Array[Label] = []
var refinery_upgrade_buttons: Array[Button] = []
var refinery_separators: Array[Control] = []
var refinery_level_texts: Array[Label] = []
var refinery_effect_texts: Array[Label] = []
var ship_upgrade_huds := {}
var ship_upgrades_visible := {}
var companion_upgrade_huds := {}
var companion_upgrades_visible := {}
var action_timer: Timer = null
var player_upgrades_visible: bool = true
var drone_upgrades_visible: bool = true
var refinery_upgrades_visible: bool = true
var control_buttons_visible: bool = true
var research_visible: bool = false
var expedition_tab: String = "research"
var selected_ore_upgrade_tab: String = "civilian"
var selected_research_category: String = "civilian"
var focused_ore_ship_key: String = ""
var flagship_upgrade_panel_style: StyleBoxFlat = null
var hud_refresh_elapsed := 0.0
var last_hud_refresh_msec := 0.0
var fps_refresh_elapsed := 0.0
var map_view: Control = null
var income_log_panel: Panel = null
var income_log_label: Label = null
var autobuy_toggle_buttons: Array[Dictionary] = []
var pause_overlay: ColorRect = null
var pause_panel: Panel = null
var pause_status_label: Label = null
var pause_restart_button: Button = null
var pause_menu_visible: bool = false
var restart_confirmation_pending: bool = false
var upgrade_effect_number_regex := RegEx.new()

const HUD_REFRESH_INTERVAL := 0.25
const FPS_REFRESH_INTERVAL := 0.25
const RESEARCH_PANEL_SIZE := Vector2(1140.0, 630.0)
const RESEARCH_PANEL_VIEWPORT_RATIO := 0.8
const RESEARCH_UPGRADE_TILE_SIZE := Vector2(140.0, 88.0)
const RIGHT_UPGRADE_PANEL_WIDTH := 380.0
const RIGHT_UPGRADE_TOP_Y := 88.0
const RIGHT_UPGRADE_ROW_GAP := 30.0
const RIGHT_UPGRADE_LABEL_X := 42.0
const RIGHT_UPGRADE_LEVEL_X := 214.0
const RIGHT_UPGRADE_EFFECT_X := 262.0
const RIGHT_UPGRADE_HEADER_HEIGHT := 38.0
const RIGHT_UPGRADE_FLAGSHIP_HEIGHT := 188.0
const RIGHT_UPGRADE_DRONE_HEIGHT := 168.0
const RIGHT_UPGRADE_REFINERY_HEIGHT := 128.0
const RIGHT_UPGRADE_SECTION_GAP := 22.0
const MILITARY_FONT_COLOR := Color("ff7770")
const CIVILIAN_FONT_COLOR := Color("f4d06f")
const UTILITY_FONT_COLOR := Color("c3a6ff")
const SUPPORT_FONT_COLOR := Color("7ce0b8")
const UPGRADE_TAB_ORDER := ["civilian", "drones", "military", "support", "utility"]
const UPGRADE_TAB_TITLES := {
	"drones": "DRONES",
	"civilian": "CIVILIAN",
	"military": "MILITARY",
	"support": "SUPPORT",
	"utility": "UTILITY"
}
const UPGRADE_TAB_DESCRIPTIONS := {
	"civilian": "The backbone of your fleet for income and logistics.",
	"military": "Aids in fleet battles and defends the fleet.",
	"support": "Improves production, refinement, and development.",
	"utility": "Introduces new systems and mechanics."
}
const EMPTY_SHIP_CLASS_MESSAGE := "No ship of this type constructed, Recall expedition to obtain new ships"
const REFINERY_HUD_UPGRADES := [
	{"label": "INPUT RATE", "stat_key": "click_rate", "description": "Adds 1 held activation and 1 registered click per second."},
	{"label": "CLICK MULT", "stat_key": "click_multiplier", "description": "Adds 0.025x to Credits gained from each accepted click."},
	{"label": "GLOBAL BONUS", "stat_key": "global_income_bonus", "description": "Adds 0.012x to all Credit income."}
]
const ORE_UPGRADE_DESCRIPTIONS := {
	"click_output": "Adds 1 Credit per mining click and 1 base damage per battle click. Battle-only bonuses are applied afterward.",
	"click_multiplier": "Adds 1 held mining or battle activation per second and 1 registered manual click per second. Holding starts at 2/sec; manual input starts at a 10/sec hard limit.",
	"drones": "Adds 1 mining drone owned and controlled by the Flagship.",
	"flagship_speed": "Adds 10 to Flagship movement speed while mining fields.",
	"refining": "Adds 0.020x to all Credit income from every source.",
	"mining": "Adds 1 Credit extracted by each mining drone per mining tick.",
	"mining_speed": "Adds 0.1 mining ticks per second to every mining drone.",
	"capacity": "Adds 10 Credits to every mining drone's cargo capacity.",
	"speed": "Adds 10 to every mining drone's movement speed."
}
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_effect_number_regex.compile("[+-]?\\d[\\d,]*(?:\\.\\d+)?(?:%|x|s)?")
	var cur_scene = get_tree().get_current_scene()
	resource_manager = cur_scene.get_node("ResourceManager") if cur_scene.has_node("ResourceManager") else null
	map_view = cur_scene.get_node_or_null("WorldCanvas/Map") as Control
	if resource_manager:
		resource_manager.upgrade_notice.connect(_show_action)

	# Compact command overlay
	resource_label = Label.new()
	resource_label.name = "ResourceLabel"
	resource_label.text = "CREDITS  0"
	add_child(resource_label)
	resource_label.position = Vector2(18, 16)
	resource_label.add_theme_font_size_override("font_size", 22)
	resource_label.tooltip_text = "Exact Credits: 0.00"

	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "ORBITAL EXTRACTOR"
	add_child(title_label)
	title_label.position = Vector2(20, 48)
	title_label.add_theme_color_override("font_color", Color("72d6e8"))

	fleet_label = Label.new()
	fleet_label.name = "FleetLabel"
	add_child(fleet_label)
	fleet_label.position = Vector2(18, 76)
	fleet_label.add_theme_color_override("font_color", Color("b7c9d6"))

	stage_label = Label.new()
	stage_label.name = "StageLabel"
	add_child(stage_label)
	stage_label.position = Vector2(18, 100)
	stage_label.size = Vector2(520, 24)
	stage_label.add_theme_color_override("font_color", Color("f4d06f"))

	fps_label = Label.new()
	fps_label.name = "FpsLabel"
	fps_label.text = "FPS  0"
	fps_label.position = Vector2(18, 124)
	fps_label.size = Vector2(120, 24)
	fps_label.mouse_filter = Control.MOUSE_FILTER_STOP
	fps_label.tooltip_text = "Collecting performance data..."
	fps_label.add_theme_color_override("font_color", Color("7ce0b8"))
	add_child(fps_label)

	var help_label = Label.new()
	help_label.name = "HelpLabel"
	help_label.text = "Left-click empty space to move fleet; click a node again to mine or approach | Drag right or middle mouse to pan"
	add_child(help_label)
	help_label.position = Vector2(18, get_viewport().get_visible_rect().size.y - 48)
	help_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.8, 0.8))

	# Command controls
	var btn_x = max(18.0, get_viewport().get_visible_rect().size.x - RIGHT_UPGRADE_PANEL_WIDTH - 20.0)
	var btn_y = 10

	controls_toggle_button = Button.new()
	controls_toggle_button.name = "ControlsToggleButton"
	controls_toggle_button.text = ">"
	controls_toggle_button.tooltip_text = "Toggle command controls"
	controls_toggle_button.size = Vector2(28, 28)
	add_child(controls_toggle_button)
	controls_toggle_button.pressed.connect(Callable(self, "_on_controls_signal_pressed"))

	controls_label = Label.new()
	controls_label.name = "ControlsLabel"
	controls_label.text = "CONTROLS"
	controls_label.size = Vector2(180, 24)
	controls_label.add_theme_font_size_override("font_size", 14)
	controls_label.add_theme_color_override("font_color", Color("f4d06f"))
	add_child(controls_label)

	var btn_center = Button.new()
	btn_center.name = "CenterButton"
	btn_center.text = "Center Flagship"
	btn_center.position = Vector2(btn_x, btn_y)
	btn_center.size = Vector2(280, 26)
	add_child(btn_center)
	btn_center.pressed.connect(Callable(self, "_on_center_pressed"))



	var btn_new_field = Button.new()
	btn_new_field.name = "NewFieldButton"
	btn_new_field.text = "New Asteroid Field"
	btn_new_field.position = Vector2(btn_x, btn_y + 144)
	btn_new_field.size = Vector2(280, 26)
	add_child(btn_new_field)
	btn_new_field.pressed.connect(Callable(self, "_on_new_field_pressed"))

	var btn_lock_focus = Button.new()
	btn_lock_focus.name = "LockFocusButton"
	btn_lock_focus.text = "Joint Focus"
	btn_lock_focus.tooltip_text = "Focus all drones on the selected mineable node, or the closest available node"
	btn_lock_focus.position = Vector2(btn_x, btn_y + 36)
	btn_lock_focus.size = Vector2(280, 26)
	add_child(btn_lock_focus)
	btn_lock_focus.pressed.connect(Callable(self, "_on_lock_focus_pressed"))

	var btn_split = Button.new()
	btn_split.name = "SplitFocusButton"
	btn_split.text = "Split Focus"
	btn_split.tooltip_text = "Clear focus locks and distribute drones across the field"
	btn_split.position = Vector2(btn_x, btn_y + 72)
	btn_split.size = Vector2(280, 26)
	add_child(btn_split)
	btn_split.pressed.connect(Callable(self, "_on_split_focus_pressed"))

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.08, 0.13, 0.92)
	panel_style.border_color = Color(0.25, 0.65, 0.75, 0.65)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4

	dev_panel = Panel.new()
	dev_panel.name = "DevPanel"
	dev_panel.size = Vector2(280.0, 102.0)
	dev_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	add_child(dev_panel)

	dev_label = Label.new()
	dev_label.name = "DevLabel"
	dev_label.text = "DEV TOOLS"
	dev_label.position = Vector2(10.0, 5.0)
	dev_label.size = Vector2(260.0, 22.0)
	dev_label.add_theme_font_size_override("font_size", 12)
	dev_label.add_theme_color_override("font_color", Color("f4d06f"))
	dev_panel.add_child(dev_label)

	dev_add_ore_button = Button.new()
	dev_add_ore_button.name = "DevAddOreButton"
	dev_add_ore_button.text = "+100,000 Credits"
	dev_add_ore_button.position = Vector2(8.0, 31.0)
	dev_add_ore_button.size = Vector2(264.0, 28.0)
	dev_panel.add_child(dev_add_ore_button)
	dev_add_ore_button.pressed.connect(Callable(self, "_on_dev_add_ore_pressed"))

	dev_prestige_button = Button.new()
	dev_prestige_button.name = "DevPrestigeButton"
	dev_prestige_button.text = "Prestige +1"
	dev_prestige_button.tooltip_text = "Perform the next normal prestige without requiring its Credit cost"
	dev_prestige_button.position = Vector2(8.0, 65.0)
	dev_prestige_button.size = Vector2(264.0, 28.0)
	dev_panel.add_child(dev_prestige_button)
	dev_prestige_button.pressed.connect(Callable(self, "_on_dev_prestige_pressed"))

	income_log_panel = Panel.new()
	income_log_panel.name = "IncomeLogPanel"
	income_log_panel.size = Vector2(300.0, 176.0)
	income_log_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	add_child(income_log_panel)
	income_log_label = Label.new()
	income_log_label.name = "IncomeLogLabel"
	income_log_label.position = Vector2(10.0, 8.0)
	income_log_label.size = Vector2(280.0, 160.0)
	income_log_label.text = "INCOME LOG\nNo recent Credit income\n\nLAST PURCHASE\nNone"
	income_log_label.add_theme_font_size_override("font_size", 12)
	income_log_label.add_theme_color_override("font_color", Color("d9f4ff"))
	income_log_panel.add_child(income_log_label)

	research_button = Button.new()
	research_button.name = "ResearchButton"
	research_button.text = "Expedition Details"
	research_button.position = Vector2(max(18.0, get_viewport().get_visible_rect().size.x * 0.5 - 120.0), 12.0)
	research_button.size = Vector2(280, 38)
	research_button.add_theme_stylebox_override("normal", _make_flat_style(Color(0.04, 0.08, 0.12, 0.92), Color.WHITE, 2, 3))
	research_button.tooltip_text = "Toggle expedition research and rewards"
	add_child(research_button)
	research_button.pressed.connect(Callable(self, "_on_research_toggle_pressed"))

	_build_research_panel()

	right_ore_label = Label.new()
	right_ore_label.name = "RightOreLabel"
	right_ore_label.text = "CREDITS  0"
	right_ore_label.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, 24)
	right_ore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_ore_label.add_theme_font_size_override("font_size", 18)
	right_ore_label.add_theme_color_override("font_color", Color("f4d06f"))
	add_child(right_ore_label)

	development_protocol_button = Button.new()
	development_protocol_button.name = "DevelopmentProtocolButton"
	development_protocol_button.text = "Auto Buy: OFF"
	development_protocol_button.toggle_mode = true
	development_protocol_button.size = Vector2(142.0, 26.0)
	development_protocol_button.visible = false
	development_protocol_button.tooltip_text = "Toggle Development Protocol: Buy most affordable ship upgrade every 5 seconds."
	add_child(development_protocol_button)
	development_protocol_button.pressed.connect(Callable(self, "_on_development_protocol_toggle_pressed"))

	fleet_maneuver_button = Button.new()
	fleet_maneuver_button.name = "AutorButton"
	fleet_maneuver_button.text = "Autor: OFF"
	fleet_maneuver_button.toggle_mode = true
	fleet_maneuver_button.size = Vector2(118.0, 26.0)
	fleet_maneuver_button.visible = false
	fleet_maneuver_button.tooltip_text = "Toggle Autor: automatically mine or attack at the held-input rate while manual input remains available."
	add_child(fleet_maneuver_button)
	fleet_maneuver_button.pressed.connect(Callable(self, "_on_autor_toggle_pressed"))

	upgrade_panel = Panel.new()
	upgrade_panel.name = "UpgradePanel"
	upgrade_panel.position = Vector2(btn_x - 8, RIGHT_UPGRADE_TOP_Y)
	upgrade_panel.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, 158)
	upgrade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flagship_upgrade_panel_style = panel_style.duplicate() as StyleBoxFlat
	upgrade_panel.add_theme_stylebox_override("panel", flagship_upgrade_panel_style)
	add_child(upgrade_panel)

	signal_button = Button.new()
	signal_button.name = "UpgradeSignalButton"
	signal_button.text = ">"
	signal_button.tooltip_text = "Toggle flagship upgrades"
	signal_button.position = Vector2(btn_x, RIGHT_UPGRADE_TOP_Y + 8.0)
	signal_button.size = Vector2(28, 28)
	add_child(signal_button)
	signal_button.pressed.connect(Callable(self, "_on_signal_pressed"))

	upgrade_label = Label.new()
	upgrade_label.name = "UpgradeLabel"
	add_child(upgrade_label)
	upgrade_label.position = Vector2(btn_x + RIGHT_UPGRADE_LABEL_X, RIGHT_UPGRADE_TOP_Y + 8.0)
	upgrade_label.size = Vector2(244, 24)
	upgrade_label.clip_text = true
	upgrade_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	upgrade_label.add_theme_font_size_override("font_size", 14)
	upgrade_label.add_theme_color_override("font_color", CIVILIAN_FONT_COLOR)

	click_output_text = _create_upgrade_row("ClickOutput", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0, "player")
	click_multiplier_text = _create_upgrade_row("ClickMultiplier", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP, "player")
	command_capacity_text = _create_upgrade_row("CommandCapacity", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, "player")
	refining_text = _create_upgrade_row("Refining", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, "player")
	flagship_speed_text = _create_upgrade_row("MoveSpeed", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 4.0, "player")

	drone_panel = Panel.new()
	drone_panel.name = "DroneUpgradePanel"
	drone_panel.position = Vector2(btn_x - 8, RIGHT_UPGRADE_TOP_Y + 174.0)
	drone_panel.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, RIGHT_UPGRADE_DRONE_HEIGHT)
	drone_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drone_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(drone_panel)

	drone_signal_button = Button.new()
	drone_signal_button.name = "DroneUpgradeSignalButton"
	drone_signal_button.text = ">"
	drone_signal_button.tooltip_text = "Toggle shared mining-drone upgrades"
	drone_signal_button.position = Vector2(btn_x, RIGHT_UPGRADE_TOP_Y + 182.0)
	drone_signal_button.size = Vector2(28, 28)
	add_child(drone_signal_button)
	drone_signal_button.pressed.connect(Callable(self, "_on_drone_signal_pressed"))

	drone_upgrade_label = Label.new()
	drone_upgrade_label.name = "DroneUpgradeLabel"
	drone_upgrade_label.text = "MINING DRONES"
	drone_upgrade_label.position = Vector2(btn_x + RIGHT_UPGRADE_LABEL_X, RIGHT_UPGRADE_TOP_Y + 182.0)
	drone_upgrade_label.size = Vector2(244, 24)
	drone_upgrade_label.clip_text = true
	drone_upgrade_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	drone_upgrade_label.add_theme_font_size_override("font_size", 14)
	drone_upgrade_label.add_theme_color_override("font_color", Color("f4d06f"))
	add_child(drone_upgrade_label)

	mining_text = _create_upgrade_row("MiningAmount", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0, "drone")
	mining_speed_text = _create_upgrade_row("MiningSpeed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP, "drone")
	capacity_text = _create_upgrade_row("Capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, "drone")
	speed_text = _create_upgrade_row("MoveSpeed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, "drone")

	click_output_button = _create_upgrade_button("Upgrade click output", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0, Callable(self, "_on_upgrade_click_output"))
	click_multiplier_button = _create_upgrade_button("Upgrade input rate", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP, Callable(self, "_on_upgrade_click_multiplier"))
	refining_button = _create_upgrade_button("Upgrade refining", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, Callable(self, "_on_upgrade_refining"))

	mining_button = _create_upgrade_button("Upgrade drone mining amount", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0, Callable(self, "_on_upgrade_mining"))
	mining_speed_button = _create_upgrade_button("Upgrade drone mining speed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP, Callable(self, "_on_upgrade_mining_speed"))
	capacity_button = _create_upgrade_button("Upgrade drone cargo capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, Callable(self, "_on_upgrade_capacity"))
	speed_button = _create_upgrade_button("Upgrade drone move speed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, Callable(self, "_on_upgrade_speed"))

	flagship_speed_button = _create_upgrade_button("Upgrade flagship speed", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 4.0, Callable(self, "_on_upgrade_flagship_speed"))
	command_capacity_button = _create_upgrade_button("Upgrade command capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, Callable(self, "_on_buy_drone"))
	var primary_upgrade_tooltips = [
		[click_output_text, click_output_button, "click_output"],
		[click_multiplier_text, click_multiplier_button, "click_multiplier"],
		[command_capacity_text, command_capacity_button, "drones"],
		[flagship_speed_text, flagship_speed_button, "flagship_speed"],
		[refining_text, refining_button, "refining"],
		[mining_text, mining_button, "mining"],
		[mining_speed_text, mining_speed_button, "mining_speed"],
		[capacity_text, capacity_button, "capacity"],
		[speed_text, speed_button, "speed"]
	]
	for tooltip_data in primary_upgrade_tooltips:
		var description = str(ORE_UPGRADE_DESCRIPTIONS[tooltip_data[2]])
		(tooltip_data[0] as Control).tooltip_text = description
		(tooltip_data[1] as Control).tooltip_text = description
	var base_autobuy_rows = [
		["base", "click_output", "player", 0], ["base", "click_multiplier", "player", 1],
		["base", "drones", "player", 2], ["base", "refining", "player", 3],
		["base", "flagship_speed", "player", 4], ["base", "mining", "drone", 0],
		["base", "mining_speed", "drone", 1], ["base", "capacity", "drone", 2],
		["base", "speed", "drone", 3]
	]
	for auto_data in base_autobuy_rows:
		_create_autobuy_toggle(str(auto_data[0]), str(auto_data[1]), str(auto_data[2]), int(auto_data[3]))

	var refinery_y = RIGHT_UPGRADE_TOP_Y + 388.0
	refinery_panel = Panel.new()
	refinery_panel.name = "RefineryUpgradePanel"
	refinery_panel.position = Vector2(btn_x - 8.0, refinery_y)
	refinery_panel.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, RIGHT_UPGRADE_REFINERY_HEIGHT)
	refinery_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refinery_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	add_child(refinery_panel)

	refinery_signal_button = Button.new()
	refinery_signal_button.name = "RefineryUpgradeSignalButton"
	refinery_signal_button.text = ">"
	refinery_signal_button.tooltip_text = "Toggle Romius upgrades"
	refinery_signal_button.position = Vector2(btn_x, refinery_y + 8.0)
	refinery_signal_button.size = Vector2(28.0, 28.0)
	add_child(refinery_signal_button)
	refinery_signal_button.pressed.connect(Callable(self, "_on_refinery_signal_pressed"))

	refinery_upgrade_label = Label.new()
	refinery_upgrade_label.name = "RefineryUpgradeLabel"
	refinery_upgrade_label.text = "ROMIUS UPGRADES"
	refinery_upgrade_label.position = Vector2(btn_x + RIGHT_UPGRADE_LABEL_X, refinery_y + 8.0)
	refinery_upgrade_label.size = Vector2(300.0, 24.0)
	refinery_upgrade_label.clip_text = true
	refinery_upgrade_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	refinery_upgrade_label.add_theme_font_size_override("font_size", 14)
	refinery_upgrade_label.add_theme_color_override("font_color", CIVILIAN_FONT_COLOR)
	add_child(refinery_upgrade_label)

	for index in range(REFINERY_HUD_UPGRADES.size()):
		var upgrade_data = REFINERY_HUD_UPGRADES[index]
		var row_y = refinery_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index
		var row_label = _create_upgrade_row("Refinery%s" % str(upgrade_data["stat_key"]).to_pascal_case(), btn_x, row_y, "refinery")
		row_label.tooltip_text = str(upgrade_data["description"])
		refinery_upgrade_texts.append(row_label)
		var upgrade_button = _create_upgrade_button("Upgrade Romius %s" % upgrade_data["label"], btn_x, row_y, Callable(self, "_on_upgrade_refinery_stat").bind(str(upgrade_data["stat_key"])))
		upgrade_button.tooltip_text = str(upgrade_data["description"])
		refinery_upgrade_buttons.append(upgrade_button)
	_set_refinery_upgrade_contents_visible(true)
	refinery_signal_button.visible = false
	refinery_upgrade_label.visible = false
	for ship_key in Catalog.get_ship_ids():
		ship_upgrades_visible[ship_key] = true
		_build_ship_upgrade_hud(ship_key, panel_style)
	for companion_id in Catalog.get_companion_ids():
		companion_upgrades_visible[companion_id] = true
		_build_ship_upgrade_hud(companion_id, panel_style, true)
	_build_ore_upgrade_tabs()
	_build_ore_upgrade_scroll()
	_build_pause_menu()

	# last action label
	last_action_label = Label.new()
	last_action_label.name = "ActionLabel"
	last_action_label.text = ""
	add_child(last_action_label)
	last_action_label.position = Vector2(18, 128)

	action_timer = Timer.new()
	action_timer.one_shot = true
	action_timer.wait_time = 2.0
	add_child(action_timer)
	action_timer.timeout.connect(Callable(self, "_on_action_timer_timeout"))

	# connect resource updates
	if resource_manager and resource_manager.has_signal("resource_changed"):
		resource_manager.connect("resource_changed", Callable(self, "_on_resource_changed"))
	get_viewport().size_changed.connect(Callable(self, "_layout_hud"))
	_set_mining_hud_visibility(true)

func _build_pause_menu() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	add_child(pause_overlay)

	pause_panel = Panel.new()
	pause_panel.name = "PausePanel"
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-190.0, -190.0)
	pause_panel.size = Vector2(380.0, 380.0)
	pause_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.04, 0.08, 0.12, 0.98), Color.WHITE, 2, 4))
	pause_overlay.add_child(pause_panel)

	var title = Label.new()
	title.text = "PAUSED"
	title.position = Vector2(30.0, 22.0)
	title.size = Vector2(320.0, 30.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f4d06f"))
	pause_panel.add_child(title)

	var menu_actions = [
		["Resume", "Continue the current run.", Callable(self, "_on_pause_resume_pressed")],
		["Save Game", "Save the current field, fleet, upgrades, research, nodes, and drones.", Callable(self, "_on_pause_save_pressed")],
		["Load Game", "Load the latest manual or automatic save and resume the game.", Callable(self, "_on_pause_load_pressed")],
		["Restart Game", "Start a fresh run without deleting the existing save. Press twice to confirm.", Callable(self, "_on_pause_restart_pressed")],
		["Refresh Game", "Development tool: reload the current scene without saving first.", Callable(self, "_on_pause_refresh_pressed")]
	]
	for index in range(menu_actions.size()):
		var action = menu_actions[index]
		var button = Button.new()
		button.text = str(action[0])
		button.tooltip_text = str(action[1])
		button.position = Vector2(40.0, 66.0 + float(index) * 50.0)
		button.size = Vector2(300.0, 38.0)
		button.pressed.connect(action[2])
		pause_panel.add_child(button)
		if str(action[0]) == "Restart Game":
			pause_restart_button = button

	pause_status_label = Label.new()
	pause_status_label.text = "Refresh discards changes made since the last save."
	pause_status_label.position = Vector2(30.0, 324.0)
	pause_status_label.size = Vector2(320.0, 38.0)
	pause_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_status_label.add_theme_font_size_override("font_size", 11)
	pause_status_label.add_theme_color_override("font_color", Color("8da8b8"))
	pause_panel.add_child(pause_status_label)

func _set_pause_menu_visibility(visible: bool) -> void:
	pause_menu_visible = visible
	restart_confirmation_pending = false
	if pause_restart_button:
		pause_restart_button.text = "Restart Game"
	if pause_overlay:
		pause_overlay.visible = visible
		if visible:
			pause_overlay.move_to_front()
	if pause_status_label and visible:
		pause_status_label.text = "Refresh discards changes made since the last save."
	get_tree().paused = visible

func _on_pause_resume_pressed() -> void:
	_set_pause_menu_visibility(false)

func _on_pause_save_pressed() -> void:
	var saved = resource_manager and resource_manager.has_method("save_game") and bool(resource_manager.save_game())
	if pause_status_label:
		pause_status_label.text = "Game saved." if saved else "Save failed. Check the Godot output."

func _on_pause_load_pressed() -> void:
	var loaded = resource_manager and resource_manager.has_method("load_game") and bool(resource_manager.load_game())
	if loaded:
		_set_pause_menu_visibility(false)
		_show_action("Game loaded")
	elif pause_status_label:
		pause_status_label.text = "No manual or automatic save was found."

func _on_pause_restart_pressed() -> void:
	if not restart_confirmation_pending:
		restart_confirmation_pending = true
		if pause_restart_button:
			pause_restart_button.text = "Confirm Restart"
		if pause_status_label:
			pause_status_label.text = "Fresh run: current progress resets, but the save file is kept."
		return
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("reset_for_new_game"):
		if pause_status_label:
			pause_status_label.text = "Restart failed. GameState could not be reset."
		return
	game_state.reset_for_new_game()
	get_tree().paused = false
	pause_menu_visible = false
	get_tree().reload_current_scene()

func _on_pause_refresh_pressed() -> void:
	get_tree().paused = false
	pause_menu_visible = false
	get_tree().reload_current_scene()

func _build_research_panel() -> void:
	research_panel = Panel.new()
	research_panel.name = "ResearchPanel"
	research_panel.position = get_viewport().get_visible_rect().size * 0.5 - RESEARCH_PANEL_SIZE * 0.5
	research_panel.size = RESEARCH_PANEL_SIZE
	research_panel.visible = false
	research_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	research_panel.clip_contents = true
	research_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.04, 0.08, 0.12, 0.82), Color(0.4, 0.86, 0.72, 0.7), 2, 12))
	add_child(research_panel)

	research_toggle_button = Button.new()
	research_toggle_button.name = "ResearchToggleButton"
	research_toggle_button.text = "X"
	research_toggle_button.tooltip_text = "Close row-based research panel"
	research_toggle_button.position = Vector2(18.0, 18.0)
	research_toggle_button.size = Vector2(26.0, 26.0)
	research_panel.add_child(research_toggle_button)
	research_toggle_button.pressed.connect(Callable(self, "_on_research_toggle_pressed"))

	research_status_label = Label.new()
	research_status_label.name = "ResearchStatusLabel"
	research_status_label.text = "VICTORY APPLIES RESEARCH"
	research_status_label.position = Vector2(58.0, 20.0)
	research_status_label.size = Vector2(300.0, 28.0)
	research_status_label.add_theme_font_size_override("font_size", 18)
	research_status_label.add_theme_color_override("font_color", Color("f4d06f"))
	research_panel.add_child(research_status_label)

	var title_label = Label.new()
	title_label.name = "ResearchRowsTitle"
	title_label.text = "SHIP RESEARCH"
	title_label.position = Vector2(420.0, 20.0)
	title_label.size = Vector2(300.0, 28.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color("72d6e8"))
	research_panel.add_child(title_label)

	research_tab_button = Button.new()
	research_tab_button.name = "ResearchTabButton"
	research_tab_button.text = "Research"
	research_tab_button.position = Vector2(780.0, 18.0)
	research_tab_button.size = Vector2(150.0, 28.0)
	research_panel.add_child(research_tab_button)
	research_tab_button.pressed.connect(Callable(self, "_on_research_tab_pressed"))

	rewards_tab_button = Button.new()
	rewards_tab_button.name = "RewardsTabButton"
	rewards_tab_button.text = "Rewards"
	rewards_tab_button.position = Vector2(946.0, 18.0)
	rewards_tab_button.size = Vector2(150.0, 28.0)
	research_panel.add_child(rewards_tab_button)
	rewards_tab_button.pressed.connect(Callable(self, "_on_rewards_tab_pressed"))

	next_prestige_button = Button.new()
	next_prestige_button.name = "NextPrestigeButton"
	next_prestige_button.text = "Complete Expedition"
	next_prestige_button.position = Vector2(886.0, 52.0)
	next_prestige_button.size = Vector2(210.0, 34.0)
	next_prestige_button.tooltip_text = "Recall the fleet and complete this expedition to commission the next ship."
	research_panel.add_child(next_prestige_button)
	next_prestige_button.pressed.connect(Callable(self, "_on_next_prestige_pressed"))

	expedition_confirmation_dialog = ConfirmationDialog.new()
	expedition_confirmation_dialog.name = "ExpeditionConfirmationDialog"
	expedition_confirmation_dialog.title = "Complete Expedition"
	expedition_confirmation_dialog.min_size = Vector2i(360, 260)
	expedition_confirmation_dialog.dialog_text = "Recall the fleet and complete the current expedition?"
	expedition_confirmation_dialog.get_ok_button().text = "Complete Expedition"
	expedition_confirmation_dialog.get_cancel_button().text = "Continue Mining"
	expedition_confirmation_dialog.confirmed.connect(Callable(self, "_on_expedition_completion_confirmed"))
	expedition_confirmation_dialog.canceled.connect(Callable(self, "_close_expedition_ui"))
	add_child(expedition_confirmation_dialog)
	_build_research_category_tabs()

	research_scroll_container = ScrollContainer.new()
	research_scroll_container.name = "ResearchScrollContainer"
	research_scroll_container.position = Vector2(20.0, 104.0)
	research_scroll_container.size = Vector2(1100.0, 456.0)
	research_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	research_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	research_scroll_container.follow_focus = true
	research_panel.add_child(research_scroll_container)
	research_row_controls.append(research_scroll_container)

	research_scroll_content = Control.new()
	research_scroll_content.name = "ResearchScrollContent"
	research_scroll_content.custom_minimum_size = Vector2(1080.0, 456.0)
	research_scroll_container.add_child(research_scroll_content)

	research_empty_label = Label.new()
	research_empty_label.name = "ResearchEmptyLabel"
	research_empty_label.text = EMPTY_SHIP_CLASS_MESSAGE
	research_empty_label.position = Vector2(120.0, 140.0)
	research_empty_label.size = Vector2(840.0, 80.0)
	research_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	research_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	research_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	research_empty_label.add_theme_font_size_override("font_size", 16)
	research_empty_label.add_theme_color_override("font_color", Color("8da8b8"))
	research_scroll_content.add_child(research_empty_label)

	rewards_scroll_container = ScrollContainer.new()
	rewards_scroll_container.name = "RewardsScrollContainer"
	rewards_scroll_container.position = Vector2(20.0, 96.0)
	rewards_scroll_container.size = Vector2(1100.0, 464.0)
	rewards_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rewards_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rewards_scroll_container.follow_focus = true
	research_panel.add_child(rewards_scroll_container)
	reward_controls.append(rewards_scroll_container)

	rewards_scroll_content = Control.new()
	rewards_scroll_content.name = "RewardsScrollContent"
	rewards_scroll_content.custom_minimum_size = Vector2(1080.0, 540.0)
	rewards_scroll_container.add_child(rewards_scroll_content)

	var catalog_rows = _get_catalog_research_rows()
	for row_index in range(catalog_rows.size()):
		_build_research_row(catalog_rows[row_index], row_index)
	_layout_research_rows()

	_build_rewards_tab()

	_set_expedition_tab("research")

func _build_research_category_tabs() -> void:
	for tab_key in UPGRADE_TAB_ORDER:
		var tab_index = research_category_buttons.size()
		var button = Button.new()
		button.name = "%sResearchCategoryTab" % str(tab_key).to_pascal_case()
		button.text = "%d %s" % [tab_index + 1, str(UPGRADE_TAB_TITLES[tab_key]).capitalize()]
		button.toggle_mode = true
		button.position = Vector2(20.0 + float(tab_index) * 220.0, 60.0)
		button.size = Vector2(212.0, 32.0)
		button.add_theme_font_size_override("font_size", 12)
		_style_upgrade_tab(button, tab_key)
		button.tooltip_text = str(UPGRADE_TAB_DESCRIPTIONS.get(tab_key, "Show %s research." % str(UPGRADE_TAB_TITLES[tab_key]).to_lower()))
		research_panel.add_child(button)
		button.pressed.connect(Callable(self, "_on_research_category_tab_pressed").bind(tab_key))
		research_category_buttons[tab_key] = button

func _on_research_category_tab_pressed(tab_key: String) -> void:
	selected_research_category = tab_key
	_layout_research_rows()

func _get_ship_category_key(ship_id: String) -> String:
	if ship_id == "mining_drone":
		return "drones"
	var catalog_category = Catalog.get_category(ship_id)
	if not catalog_category.is_empty():
		return catalog_category
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_ship_profile"):
		var profile = game_state.get_ship_profile(StringName(ship_id)) as ShipProfile
		if profile:
			match int(profile.category):
				ShipProfile.Category.MILITARY:
					return "military"
				ShipProfile.Category.SUPPORT:
					return "support"
				ShipProfile.Category.UTILITY:
					return "utility"
	return "civilian"

func _get_catalog_research_rows() -> Array:
	var rows: Array = []
	for ship_id in Catalog.get_ship_ids(true):
		var ship_data = Catalog.get_ship_data(ship_id)
		var upgrades: Array = []
		var cap_key = str(ship_data.get("cap_key", "%s_general_cap" % ship_id))
		if not cap_key.is_empty():
			upgrades.append({
				"label": "Upgrade Cap",
				"type": "cap",
				"key": cap_key,
				"description": "Win each rank to add 2 levels to every %s ore-upgrade cap." % Catalog.get_display_name(ship_id)
			})
		for research_data in Catalog.get_research_rows(ship_id):
			if Catalog.is_companion_research_key(str(research_data["key"])):
				continue
			upgrades.append({
				"label": str(research_data["label"]),
				"type": "passive",
				"key": str(research_data["key"]),
				"description": str(research_data["description"])
			})
		rows.append({
			"title": Catalog.get_display_name(ship_id).to_upper(),
			"ship_id": ship_id,
			"requires_ship": "" if int(ship_data.get("rank", 0)) <= 0 else ship_id,
			"upgrades": upgrades,
			"placeholder": "NO UNIQUE TECHNOLOGIES YET"
		})
	for companion_id in Catalog.get_companion_ids():
		var companion_data = Catalog.get_companion_data(companion_id)
		var companion_upgrades: Array = []
		var companion_cap_key = str(companion_data.get("cap_key", ""))
		if not companion_cap_key.is_empty():
			companion_upgrades.append({
				"label": "Upgrade Cap",
				"type": "cap",
				"key": companion_cap_key,
				"description": "Win each rank to add 2 levels to every %s ore-upgrade cap." % Catalog.get_companion_display_name(companion_id)
			})
		for research_data in Array(companion_data.get("research", [])):
			companion_upgrades.append({
				"label": str(research_data["label"]),
				"type": "passive",
				"key": str(research_data["key"]),
				"description": str(research_data["description"]),
				"requires_ship": str(research_data.get("requires_ship", companion_data.get("required_ship", "")))
			})
		rows.append({
			"title": Catalog.get_companion_display_name(companion_id).to_upper(),
			"ship_id": companion_id,
			"category": "drones",
			"requires_ship": str(companion_data.get("required_ship", "")),
			"description": str(companion_data.get("description", "")),
			"upgrades": companion_upgrades,
			"placeholder": "NO UNIQUE TECHNOLOGIES YET"
		})
	return rows

func _layout_research_rows() -> void:
	if research_scroll_content == null:
		return
	var game_state = get_node_or_null("/root/GameState")
	var row_y = 8.0
	var visible_rows = 0
	for row_data in research_rows:
		var required_ship = str(row_data["requires_ship"])
		var unlocked = _is_research_ship_unlocked(required_ship, game_state)
		var row_visible = str(row_data["category"]) == selected_research_category and unlocked
		var panel = row_data["panel"] as Panel
		panel.visible = row_visible
		if row_visible:
			panel.position = Vector2(4.0, row_y)
			row_y += panel.size.y + 10.0
			visible_rows += 1
	if research_empty_label:
		research_empty_label.visible = visible_rows == 0
		research_empty_label.move_to_front()
	for tab_key in research_category_buttons:
		var button = research_category_buttons[tab_key] as Button
		button.button_pressed = str(tab_key) == selected_research_category
	research_scroll_content.custom_minimum_size.y = max(456.0, row_y)

func _is_research_ship_unlocked(ship_key: String, game_state: Node) -> bool:
	if ship_key.is_empty():
		return true
	if ship_key in ["flagship", "mining_drone"]:
		return true
	return game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked(ship_key)

func _build_rewards_tab() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_prestige_boss_levels"):
		prestige_boss_levels = game_state.get_prestige_boss_levels()
	for index in range(prestige_boss_levels.size()):
		var target_prestige = prestige_boss_levels[index]
		var prestige_data: Dictionary = game_state.get_prestige_data(target_prestige)
		var reward_panel = Panel.new()
		reward_panel.name = "Prestige%dPanel" % target_prestige
		reward_panel.position = Vector2(4.0, 4.0 + index * 138.0)
		reward_panel.size = Vector2(1068.0, 128.0)
		reward_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward_panel.clip_contents = true
		reward_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.06, 0.11, 0.14, 0.78), Color(0.4, 0.86, 0.72, 0.7), 1, 4))
		rewards_scroll_content.add_child(reward_panel)

		var reward_title = Label.new()
		reward_title.text = "PRESTIGE %d | %s CREDITS" % [target_prestige, _format_number(int(prestige_data["cost"]))]
		reward_title.position = Vector2(18.0, 10.0)
		reward_title.size = Vector2(650.0, 24.0)
		reward_title.add_theme_font_size_override("font_size", 14)
		reward_title.add_theme_color_override("font_color", Color("f4d06f"))
		reward_panel.add_child(reward_title)

		var reset_description = Label.new()
		reset_description.text = "Consumes Credits and resets the field, drones, Credit upgrade levels, and Upgrade Cap research. One-time research is kept."
		reset_description.position = Vector2(18.0, 40.0)
		reset_description.size = Vector2(650.0, 22.0)
		reset_description.clip_text = true
		reset_description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		reset_description.tooltip_text = reset_description.text
		reset_description.add_theme_font_size_override("font_size", 12)
		reset_description.add_theme_color_override("font_color", Color("ffaaa3"))
		reward_panel.add_child(reset_description)

		var reward_description = RichTextLabel.new()
		var full_reward_text = "REWARD  %s" % str(prestige_data["reward"])
		reward_description.text = full_reward_text
		reward_description.position = Vector2(18.0, 66.0)
		reward_description.size = Vector2(650.0, 52.0)
		reward_description.fit_content = false
		reward_description.scroll_active = false
		reward_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_description.tooltip_text = full_reward_text
		reward_description.add_theme_font_size_override("normal_font_size", 12)
		reward_description.add_theme_color_override("default_color", Color("d9f4ff"))
		reward_panel.add_child(reward_description)

		var status_label = Label.new()
		status_label.text = "LOCKED"
		status_label.position = Vector2(820.0, 12.0)
		status_label.size = Vector2(210.0, 24.0)
		status_label.clip_text = true
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_label.add_theme_font_size_override("font_size", 13)
		status_label.add_theme_color_override("font_color", Color("f4d06f"))
		reward_panel.add_child(status_label)

		var attempt_button = Button.new()
		attempt_button.text = "Complete Expedition"
		attempt_button.position = Vector2(870.0, 70.0)
		attempt_button.size = Vector2(176.0, 40.0)
		reward_panel.add_child(attempt_button)
		attempt_button.pressed.connect(Callable(self, "_on_prestige_purchase_pressed").bind(target_prestige))

		var ship_key = str(prestige_data.get("ship", ""))
		var dev_ship_button = Button.new()
		dev_ship_button.name = "Dev%sShipToggle" % ship_key.to_pascal_case()
		dev_ship_button.text = "DEV SHIP: OFF"
		dev_ship_button.toggle_mode = true
		dev_ship_button.position = Vector2(690.0, 80.0)
		dev_ship_button.size = Vector2(164.0, 30.0)
		dev_ship_button.tooltip_text = "Add or remove only %s for testing. Prestige, ore, research, and ship upgrade levels are unchanged." % Catalog.get_display_name(ship_key)
		reward_panel.add_child(dev_ship_button)
		dev_ship_button.pressed.connect(Callable(self, "_on_dev_ship_toggle_pressed").bind(ship_key))
		reward_entries[target_prestige] = {"status": status_label, "button": attempt_button, "dev_button": dev_ship_button, "description": reward_description, "ship": ship_key}
	rewards_scroll_content.custom_minimum_size.y = max(540.0, 8.0 + prestige_boss_levels.size() * 138.0)

func _format_number(value: int) -> String:
	var raw = str(value)
	var formatted = ""
	while raw.length() > 3:
		formatted = "," + raw.right(3) + formatted
		raw = raw.left(raw.length() - 3)
	return raw + formatted

func _format_header_value(value: float) -> String:
	var magnitude = abs(value)
	if magnitude >= 1000000000.0:
		return "%.1fB" % (value / 1000000000.0)
	if magnitude >= 1000000.0:
		return "%.1fM" % (value / 1000000.0)
	if magnitude >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	if magnitude >= 100.0:
		return "%.0f" % value
	if magnitude >= 10.0:
		return "%.1f" % value
	return "%.2f" % value

func _set_compact_header(label: Label, candidates: Array[String], tooltip: String) -> void:
	if label == null or candidates.is_empty():
		return
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = tooltip
	label.text = candidates.back()
	var font = label.get_theme_font("font")
	var font_size = label.get_theme_font_size("font_size")
	var available_width = max(1.0, label.size.x)
	for candidate in candidates:
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= available_width:
			label.text = candidate
			break

func _compact_numeric_effect(description: String) -> String:
	var values: Array[String] = []
	for result in upgrade_effect_number_regex.search_all(description):
		var value = result.get_string()
		if not value.is_empty() and value not in values:
			values.append(value)
		if values.size() >= 2:
			break
	return " | ".join(values)

func _get_category_font_color(category: int) -> Color:
	match category:
		ShipProfile.Category.MILITARY:
			return MILITARY_FONT_COLOR
		ShipProfile.Category.UTILITY:
			return UTILITY_FONT_COLOR
		ShipProfile.Category.SUPPORT:
			return SUPPORT_FONT_COLOR
		_:
			return CIVILIAN_FONT_COLOR

func _build_research_row(row_data: Dictionary, row_index: int) -> void:
	var row_height = 128.0
	var row_y = 8.0 + float(row_index) * (row_height + 10.0)
	var ship_id = str(row_data.get("ship_id", ""))
	var category_key = str(row_data.get("category", _get_ship_category_key(ship_id)))
	var category_color = _get_upgrade_tab_color(category_key)
	var row_panel = Panel.new()
	row_panel.name = "%sResearchRow" % row_data["title"]
	row_panel.position = Vector2(4.0, row_y)
	row_panel.size = Vector2(1068.0, row_height)
	row_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_panel.clip_contents = true
	row_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(category_color.r, category_color.g, category_color.b, 0.08), Color(category_color.r, category_color.g, category_color.b, 0.62), 1, 4))
	research_scroll_content.add_child(row_panel)
	research_rows.append({
		"panel": row_panel,
		"category": str(row_data.get("category", _get_ship_category_key(str(row_data.get("ship_id", ""))))),
		"requires_ship": str(row_data.get("requires_ship", ""))
	})

	var ship_label = Label.new()
	ship_label.name = "%sResearchRowLabel" % row_data["title"]
	ship_label.text = str(row_data["title"])
	ship_label.position = Vector2(28.0, 22.0)
	ship_label.size = Vector2(84.0, 84.0)
	ship_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ship_font_color = CIVILIAN_FONT_COLOR
	var game_state = get_node_or_null("/root/GameState")
	ship_label.text = "%s\n%s" % [str(row_data["title"]), str(UPGRADE_TAB_TITLES.get(category_key, category_key)).to_upper()]
	ship_label.tooltip_text = str(row_data.get("description", Catalog.get_ship_data(ship_id).get("description", "")))
	ship_font_color = Catalog.CATEGORY_COLORS.get(category_key, CIVILIAN_FONT_COLOR)
	if game_state and game_state.has_method("get_ship_profile"):
		var profile = game_state.get_ship_profile(StringName(ship_id)) as ShipProfile
		if profile:
			ship_label.tooltip_text = "Roles: %s" % ", ".join(profile.get_role_names())
	ship_label.add_theme_font_size_override("font_size", 14)
	ship_label.add_theme_color_override("font_color", ship_font_color)
	row_panel.add_child(ship_label)

	var ship_body = Panel.new()
	ship_body.name = "%sResearchShipBody" % row_data["title"]
	ship_body.position = Vector2(126.0, 14.0)
	ship_body.size = Vector2(936.0, max(64.0, row_height - 28.0))
	ship_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_body.add_theme_stylebox_override("panel", _make_flat_style(Color(category_color.r, category_color.g, category_color.b, 0.05), Color(category_color.r, category_color.g, category_color.b, 0.35), 1, 3))
	row_panel.add_child(ship_body)

	var upgrades = row_data["upgrades"]
	if upgrades.is_empty():
		var placeholder = Label.new()
		placeholder.name = "PlaceholderResearchLabel"
		placeholder.text = str(row_data.get("placeholder", "NO UNIQUE TECHNOLOGIES YET"))
		placeholder.position = Vector2(170.0, row_height * 0.5 - 14.0)
		placeholder.size = Vector2(872.0, 28.0)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 14)
		placeholder.add_theme_color_override("font_color", Color("8da8b8"))
		row_panel.add_child(placeholder)
		return

	for tile_index in range(upgrades.size()):
		var upgrade_data = upgrades[tile_index].duplicate(true)
		upgrade_data["category_color"] = category_color
		if row_data.has("requires_ship") and not upgrade_data.has("requires_ship"):
			upgrade_data["requires_ship"] = str(row_data["requires_ship"])
		_build_research_tile(row_panel, upgrade_data, tile_index, upgrades.size())
	if row_data.has("requires_ship"):
		var lock_label = Label.new()
		lock_label.name = "%sResearchLockLabel" % row_data["title"]
		lock_label.text = "Locked - reach its prestige reward"
		lock_label.position = Vector2(330.0, row_height * 0.5 - 14.0)
		lock_label.size = Vector2(560.0, 28.0)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 14)
		lock_label.add_theme_color_override("font_color", Color("8da8b8"))
		row_panel.add_child(lock_label)
		var lock_key = str(row_data["requires_ship"])
		if not research_ship_lock_labels.has(lock_key):
			research_ship_lock_labels[lock_key] = []
		research_ship_lock_labels[lock_key].append(lock_label)

func _build_research_tile(row_panel: Panel, upgrade_data: Dictionary, tile_index: int, tile_count: int) -> void:
	var tile_rect = _get_research_tile_rect(upgrade_data, tile_index, tile_count)
	var tile = Panel.new()
	tile.name = "%sResearchTile" % upgrade_data["key"]
	tile.position = tile_rect.position
	tile.size = tile_rect.size
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.tooltip_text = upgrade_data["description"]
	var category_color: Color = upgrade_data.get("category_color", Color("72d6e8"))
	tile.add_theme_stylebox_override("panel", _make_flat_style(Color(category_color.r, category_color.g, category_color.b, 0.09), Color(category_color.r, category_color.g, category_color.b, 0.58), 1, 3))
	row_panel.add_child(tile)

	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = "Development\nProtocol" if str(upgrade_data["key"]) == "flagship_development_protocol" else str(upgrade_data["label"])
	name_label.position = Vector2(6.0, 4.0)
	name_label.size = Vector2(max(1.0, tile_rect.size.x - 12.0), 32.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color("d9f4ff"))
	tile.add_child(name_label)

	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "L0"
	var button_y = max(28.0, tile_rect.size.y - 30.0)
	level_label.position = Vector2(8.0, max(22.0, button_y - 16.0))
	level_label.size = Vector2(max(1.0, tile_rect.size.x - 16.0), 12.0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color("f4d06f"))
	tile.add_child(level_label)

	var action_key = str(upgrade_data["key"])

	var battle_card_button = Button.new()
	battle_card_button.name = "BattleButton"
	battle_card_button.text = "Battle"
	battle_card_button.position = Vector2(4.0, button_y)
	battle_card_button.size = Vector2(max(1.0, tile_rect.size.x - 8.0), 22.0)
	battle_card_button.add_theme_font_size_override("font_size", 10)
	battle_card_button.tooltip_text = "Battle to unlock this research"
	tile.add_child(battle_card_button)
	battle_card_button.pressed.connect(Callable(self, "_on_research_battle_pressed").bind(action_key))

	research_upgrade_tiles.append({
		"type": str(upgrade_data["type"]),
		"key": str(upgrade_data["key"]),
		"stat_key": str(upgrade_data.get("stat_key", "")),
		"requires_ship": str(upgrade_data.get("requires_ship", "")),
		"description": str(upgrade_data["description"]),
		"label": name_label,
		"level": level_label,
		"battle": battle_card_button,
		"tile": tile
	})

func _get_research_tile_rect(upgrade_data: Dictionary, tile_index: int, tile_count: int) -> Rect2:
	if upgrade_data.has("rect"):
		var rect = upgrade_data["rect"]
		return Rect2(Vector2(float(rect[0]), float(rect[1])), Vector2(float(rect[2]), float(rect[3])))
	if upgrade_data.has("pos"):
		var pos = upgrade_data["pos"]
		return Rect2(Vector2(float(pos[0]), float(pos[1])), RESEARCH_UPGRADE_TILE_SIZE)
	var tile_gap = 12.0
	var ship_body_x = 126.0
	var ship_body_width = 936.0
	var total_width = RESEARCH_UPGRADE_TILE_SIZE.x * float(tile_count) + tile_gap * float(max(0, tile_count - 1))
	var start_x = ship_body_x + max(0.0, (ship_body_width - total_width) * 0.5)
	return Rect2(Vector2(start_x + float(tile_index) * (RESEARCH_UPGRADE_TILE_SIZE.x + tile_gap), 20.0), RESEARCH_UPGRADE_TILE_SIZE)

func _make_flat_style(bg_color: Color, border_color: Color, border_width: int = 1, radius: int = 4) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _layout_hud() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var aspect_ratio = viewport_size.x / max(viewport_size.y, 1.0)
	var scroll_width = min(RIGHT_UPGRADE_PANEL_WIDTH, max(260.0, viewport_size.x - 20.0))
	var group_panel_width = max(246.0, scroll_width - 14.0)
	var screen_panel_x = max(8.0, viewport_size.x - scroll_width - 12.0)
	var drone_panel_x = 8.0
	var ship_panel_x = 8.0
	var panel_width = group_panel_width
	var content_width = panel_width - RIGHT_UPGRADE_LABEL_X - 8.0
	var upgrade_columns = _get_upgrade_column_positions(panel_width)
	var level_column_x = float(upgrade_columns.x)
	var effect_column_x = float(upgrade_columns.y)
	var upgrade_font_size = 14 if aspect_ratio >= 1.4 else 12
	var help_y = viewport_size.y - 48.0
	var ore_y = RIGHT_UPGRADE_TOP_Y - 32.0
	var flagship_height = RIGHT_UPGRADE_FLAGSHIP_HEIGHT if player_upgrades_visible else RIGHT_UPGRADE_HEADER_HEIGHT
	var drone_height = RIGHT_UPGRADE_DRONE_HEIGHT if drone_upgrades_visible else RIGHT_UPGRADE_HEADER_HEIGHT
	var refinery_height = RIGHT_UPGRADE_REFINERY_HEIGHT if refinery_upgrades_visible else RIGHT_UPGRADE_HEADER_HEIGHT
	var game_state = get_node_or_null("/root/GameState")
	var drone_y = 0.0
	var companion_positions := {}
	var drone_stack_end = 0.0
	var ship_positions := {}
	var ship_stack_end = 0.0
	var selected_card_count = 0
	if selected_ore_upgrade_tab == "drones":
		drone_stack_end = drone_y + drone_height
		selected_card_count = 1
		var companion_cursor = drone_stack_end + RIGHT_UPGRADE_SECTION_GAP
		for ship_key in Catalog.get_companion_ids():
			if not companion_upgrade_huds.has(ship_key) or not _is_companion_unlocked(ship_key, game_state):
				continue
			companion_positions[ship_key] = companion_cursor
			companion_cursor += _get_upgrade_hud_height(companion_upgrade_huds[ship_key], bool(companion_upgrades_visible.get(ship_key, false))) + RIGHT_UPGRADE_SECTION_GAP
			selected_card_count += 1
		drone_stack_end = companion_cursor - RIGHT_UPGRADE_SECTION_GAP
	else:
		for ship_key in _get_ore_upgrade_tab_ships(selected_ore_upgrade_tab):
			if not _is_ore_ship_unlocked(ship_key, game_state):
				continue
			ship_positions[ship_key] = ship_stack_end
			ship_stack_end += _get_ore_ship_height(ship_key, flagship_height, refinery_height) + RIGHT_UPGRADE_SECTION_GAP
			selected_card_count += 1
	var content_bottom = max(drone_stack_end, ship_stack_end - RIGHT_UPGRADE_SECTION_GAP)
	var upgrade_content_height = max(120.0, content_bottom)
	var flagship_y = float(ship_positions.get("flagship", 0.0))
	var refinery_y = float(ship_positions.get("refinery", 0.0))
	var control_x = 18.0
	var control_y = max(142.0, help_y - 214.0)
	var control_width = min(280.0, max(220.0, viewport_size.x - 36.0))
	if dev_panel:
		dev_panel.position = Vector2(control_x, control_y - 112.0)
		dev_panel.size = Vector2(control_width, 102.0)
	if dev_label:
		dev_label.size = Vector2(control_width - 20.0, 22.0)
	if dev_add_ore_button:
		dev_add_ore_button.position = Vector2(8.0, 31.0)
		dev_add_ore_button.size = Vector2(max(1.0, control_width - 16.0), 28.0)
	if dev_prestige_button:
		dev_prestige_button.position = Vector2(8.0, 65.0)
		dev_prestige_button.size = Vector2(max(1.0, control_width - 16.0), 28.0)
	if income_log_panel:
		var log_width = min(320.0, max(220.0, viewport_size.x - control_x - control_width - 36.0))
		var log_x = control_x + control_width + 12.0
		income_log_panel.position = Vector2(log_x, control_y)
		income_log_panel.size = Vector2(log_width, 176.0)
		income_log_panel.visible = log_x + log_width + 12.0 <= screen_panel_x and not _has_open_research_overlay()
		if income_log_label:
			income_log_label.size = Vector2(log_width - 20.0, 160.0)
	if controls_toggle_button:
		controls_toggle_button.position = Vector2(control_x, control_y)
		controls_toggle_button.size = Vector2(28.0, 28.0)
		controls_toggle_button.text = ">" if control_buttons_visible else "<"
	if controls_label:
		controls_label.position = Vector2(control_x + 36.0, control_y + 2.0)
		controls_label.size = Vector2(180.0, 24.0)
	var controls = {
		"CenterButton": [control_x, control_y + 36.0, control_width, 26.0],
		"LockFocusButton": [control_x, control_y + 72.0, control_width, 26.0],
		"SplitFocusButton": [control_x, control_y + 108.0, control_width, 26.0],
		"NewFieldButton": [control_x, control_y + 144.0, control_width, 26.0]
	}
	for control_name in controls:
		var control = get_node_or_null(control_name) as Control
		if control:
			var rect = controls[control_name]
			control.position = Vector2(rect[0], rect[1])
			control.size = Vector2(rect[2], rect[3])
	var automation_width = clamp((scroll_width - 120.0) * 0.5, 74.0, 118.0)
	var automation_gap = 4.0
	if right_ore_label:
		var ore_x = screen_panel_x + automation_width * 2.0 + automation_gap * 2.0
		right_ore_label.position = Vector2(ore_x, ore_y)
		right_ore_label.size = Vector2(max(1.0, screen_panel_x + scroll_width - ore_x), 24.0)
	if fleet_maneuver_button:
		fleet_maneuver_button.position = Vector2(screen_panel_x, ore_y - 1.0)
		fleet_maneuver_button.size = Vector2(automation_width, 26.0)
	if development_protocol_button:
		development_protocol_button.position = Vector2(screen_panel_x + automation_width + automation_gap, ore_y - 1.0)
		development_protocol_button.size = Vector2(automation_width, 26.0)
	var mining_hud_visible = not _has_open_research_overlay()
	var tab_gap = 3.0
	var tab_width = (scroll_width - tab_gap * float(UPGRADE_TAB_ORDER.size() - 1)) / float(UPGRADE_TAB_ORDER.size())
	for tab_index in range(UPGRADE_TAB_ORDER.size()):
		var tab_key = UPGRADE_TAB_ORDER[tab_index]
		var tab_button = ore_upgrade_tab_buttons.get(tab_key) as Button
		if tab_button:
			tab_button.position = Vector2(screen_panel_x + float(tab_index) * (tab_width + tab_gap), RIGHT_UPGRADE_TOP_Y)
			tab_button.size = Vector2(tab_width, 32.0)
			tab_button.visible = mining_hud_visible
			tab_button.button_pressed = tab_key == selected_ore_upgrade_tab
	var upgrade_scroll_top = RIGHT_UPGRADE_TOP_Y + 40.0
	if ore_upgrade_scroll:
		ore_upgrade_scroll.position = Vector2(screen_panel_x, upgrade_scroll_top)
		var available_scroll_height = max(120.0, viewport_size.y - upgrade_scroll_top - 18.0)
		ore_upgrade_scroll.size = Vector2(scroll_width, min(upgrade_content_height, available_scroll_height))
	if ore_upgrade_empty_label:
		ore_upgrade_empty_label.position = Vector2(20.0, 28.0)
		ore_upgrade_empty_label.size = Vector2(max(1.0, scroll_width - 40.0), 96.0)
		ore_upgrade_empty_label.visible = mining_hud_visible and selected_card_count == 0
	if upgrade_panel:
		upgrade_panel.position = Vector2(ship_panel_x - 8.0, flagship_y)
		upgrade_panel.size = Vector2(panel_width, flagship_height)
		upgrade_panel.visible = mining_hud_visible and ship_positions.has("flagship")
	if drone_panel:
		drone_panel.position = Vector2(drone_panel_x - 8.0, drone_y)
		drone_panel.size = Vector2(panel_width, drone_height)
		drone_panel.visible = mining_hud_visible and selected_ore_upgrade_tab == "drones"
	if refinery_panel:
		refinery_panel.visible = false
	if research_button:
		var research_button_width = 280.0 if viewport_size.x >= 620.0 else min(260.0, max(140.0, viewport_size.x - 36.0))
		research_button.position = Vector2(max(18.0, viewport_size.x * 0.5 - research_button_width * 0.5), 12.0)
		research_button.size = Vector2(research_button_width, 38.0)
	if research_panel:
		var research_scale = _get_research_panel_scale(viewport_size)
		research_panel.scale = Vector2(research_scale, research_scale)
		research_panel.position = viewport_size * 0.5 - RESEARCH_PANEL_SIZE * research_scale * 0.5
		research_panel.size = RESEARCH_PANEL_SIZE
	if research_toggle_button:
		research_toggle_button.position = Vector2(18.0, 18.0)
	if research_status_label:
		research_status_label.position = Vector2(58.0, 20.0)
	var heading_controls = [
		[signal_button, ship_panel_x, flagship_y + 8.0, 28.0, 28.0],
		[upgrade_label, ship_panel_x + RIGHT_UPGRADE_LABEL_X, flagship_y + 8.0, content_width, 24.0],
		[drone_signal_button, drone_panel_x, drone_y + 8.0, 28.0, 28.0],
		[drone_upgrade_label, drone_panel_x + RIGHT_UPGRADE_LABEL_X, drone_y + 8.0, content_width, 24.0],
		[refinery_signal_button, ship_panel_x, refinery_y + 8.0, 28.0, 28.0],
		[refinery_upgrade_label, ship_panel_x + RIGHT_UPGRADE_LABEL_X, refinery_y + 8.0, content_width, 24.0]
	]
	for heading in heading_controls:
		var control = heading[0] as Control
		if control:
			control.position = Vector2(heading[1], heading[2])
			control.size = Vector2(heading[3], heading[4])
			if control is Label:
				control.add_theme_font_size_override("font_size", upgrade_font_size)
	var upgrade_controls = [
		[click_output_button, click_output_text, ship_panel_x, flagship_y + 38.0],
		[click_multiplier_button, click_multiplier_text, ship_panel_x, flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP],
		[command_capacity_button, command_capacity_text, ship_panel_x, flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0],
		[refining_button, refining_text, ship_panel_x, flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0],
		[flagship_speed_button, flagship_speed_text, ship_panel_x, flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 4.0],
		[mining_button, mining_text, drone_panel_x, drone_y + 38.0],
		[mining_speed_button, mining_speed_text, drone_panel_x, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP],
		[capacity_button, capacity_text, drone_panel_x, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0],
		[speed_button, speed_text, drone_panel_x, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0]
	]
	for index in range(refinery_upgrade_buttons.size()):
		upgrade_controls.append([refinery_upgrade_buttons[index], refinery_upgrade_texts[index], ship_panel_x, refinery_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index])
	for row in upgrade_controls:
		var button = row[0] as Control
		var label = row[1] as Label
		var row_x = row[2]
		var row_y = row[3]
		button.position = Vector2(row_x, row_y)
		button.size = Vector2(30.0, 26.0)
		label.position = Vector2(row_x + RIGHT_UPGRADE_LABEL_X, row_y)
		label.size = Vector2(max(1.0, level_column_x - RIGHT_UPGRADE_LABEL_X - 6.0), 24.0)
		label.add_theme_font_size_override("font_size", upgrade_font_size)
	for auto_data in autobuy_toggle_buttons:
		if str(auto_data.get("section", "")) not in ["player", "drone"]:
			continue
		var auto_button = auto_data["button"] as Button
		var section = str(auto_data["section"])
		var row_index = int(auto_data["index"])
		var row_y = flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * row_index if section == "player" else drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * row_index
		var row_x = ship_panel_x if section == "player" else drone_panel_x
		auto_button.position = Vector2(row_x + level_column_x - 20.0, row_y + 4.0)
		var autobuy_unlocked = game_state and game_state.has_method("is_development_protocol_unlocked") and game_state.is_development_protocol_unlocked()
		auto_button.visible = autobuy_unlocked and mining_hud_visible and ((section == "player" and ship_positions.has("flagship") and player_upgrades_visible) or (section == "drone" and selected_ore_upgrade_tab == "drones" and drone_upgrades_visible))
	var row_positions = [
		flagship_y + 38.0,
		flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP,
		flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0,
		flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0,
		flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 4.0
	]
	for index in range(player_separators.size()):
		player_separators[index].position = Vector2(ship_panel_x + RIGHT_UPGRADE_LABEL_X, row_positions[index] + 25.0)
		player_separators[index].size = Vector2(max(1.0, content_width - 8.0), 1.0)
	for index in range(player_level_texts.size()):
		player_level_texts[index].position = Vector2(ship_panel_x + level_column_x, row_positions[index])
		player_level_texts[index].size = Vector2(max(1.0, effect_column_x - level_column_x - 4.0), 24.0)
		player_effect_texts[index].position = Vector2(ship_panel_x + effect_column_x, row_positions[index])
		player_effect_texts[index].size = Vector2(max(1.0, panel_width - effect_column_x - 8.0), 24.0)
	row_positions = [
		drone_y + 38.0,
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP,
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0,
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0
	]
	for index in range(drone_separators.size()):
		drone_separators[index].position = Vector2(drone_panel_x + RIGHT_UPGRADE_LABEL_X, row_positions[index] + 25.0)
		drone_separators[index].size = Vector2(max(1.0, content_width - 8.0), 1.0)
	for index in range(drone_level_texts.size()):
		drone_level_texts[index].position = Vector2(drone_panel_x + level_column_x, row_positions[index])
		drone_level_texts[index].size = Vector2(max(1.0, effect_column_x - level_column_x - 4.0), 24.0)
		drone_effect_texts[index].position = Vector2(drone_panel_x + effect_column_x, row_positions[index])
		drone_effect_texts[index].size = Vector2(max(1.0, panel_width - effect_column_x - 8.0), 24.0)
	row_positions = []
	for index in range(REFINERY_HUD_UPGRADES.size()):
		row_positions.append(refinery_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index)
	for index in range(refinery_separators.size()):
		refinery_separators[index].position = Vector2(ship_panel_x + RIGHT_UPGRADE_LABEL_X, row_positions[index] + 25.0)
		refinery_separators[index].size = Vector2(max(1.0, content_width - 8.0), 1.0)
	for index in range(refinery_level_texts.size()):
		refinery_level_texts[index].position = Vector2(ship_panel_x + level_column_x, row_positions[index])
		refinery_level_texts[index].size = Vector2(max(1.0, effect_column_x - level_column_x - 4.0), 24.0)
		refinery_effect_texts[index].position = Vector2(ship_panel_x + effect_column_x, row_positions[index])
		refinery_effect_texts[index].size = Vector2(max(1.0, panel_width - effect_column_x - 8.0), 24.0)
	_layout_grouped_ship_upgrade_huds(ship_positions, companion_positions, ship_panel_x, drone_panel_x, panel_width, content_width, mining_hud_visible)
	_apply_ore_ship_highlights()
	if ore_upgrade_content:
		ore_upgrade_content.custom_minimum_size = Vector2(group_panel_width, upgrade_content_height)
	if resource_label:
		resource_label.position = Vector2(18.0, 16.0)
	if fleet_label:
		fleet_label.position = Vector2(18.0, 76.0)
	if stage_label:
		stage_label.position = Vector2(18.0, 100.0)
		stage_label.size = Vector2(min(520.0, max(260.0, viewport_size.x - 360.0)), 24.0)
	if last_action_label:
		last_action_label.position = Vector2(18.0, 128.0)
	var help_label = get_node_or_null("HelpLabel") as Control
	if help_label:
		help_label.position = Vector2(18.0, help_y)
		help_label.size = Vector2(max(180.0, viewport_size.x - 36.0), 24.0)

func _is_ore_ship_unlocked(ship_key: String, game_state: Node) -> bool:
	return ship_key == "flagship" or (game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked(ship_key))

func _is_companion_unlocked(companion_id: String, game_state: Node) -> bool:
	if companion_id == "fighter":
		var fighter_bays_unlocked = game_state and int(game_state.get_passive_level("hammond_fighter_bays")) > 0
		var brooder_fighters = resource_manager and resource_manager.has_method("get_fighter_drone_count") and int(resource_manager.get_fighter_drone_count()) > 0
		return fighter_bays_unlocked or brooder_fighters
	var companion_data = Catalog.get_companion_data(companion_id)
	return _is_research_ship_unlocked(str(companion_data.get("required_ship", "")), game_state)

func _get_ore_upgrade_tab_ships(tab_key: String) -> Array[String]:
	var ships: Array[String] = []
	if tab_key == "civilian":
		ships.append("flagship")
	for ship_key in Catalog.get_ship_ids():
		if Catalog.get_category(ship_key) == tab_key:
			ships.append(ship_key)
	return ships

func _get_upgrade_hud_height(hud: Dictionary, expanded: bool) -> float:
	if hud.is_empty():
		return 0.0
	return 38.0 + float(Array(hud["rows"]).size()) * RIGHT_UPGRADE_ROW_GAP if expanded else RIGHT_UPGRADE_HEADER_HEIGHT

func _get_ore_ship_height(ship_key: String, flagship_height: float, refinery_height: float) -> float:
	if ship_key == "flagship":
		return flagship_height
	return _get_upgrade_hud_height(ship_upgrade_huds.get(ship_key, {}), bool(ship_upgrades_visible.get(ship_key, false)))

func _get_upgrade_column_positions(panel_width: float) -> Vector2:
	var level_x = min(RIGHT_UPGRADE_LEVEL_X, max(146.0, panel_width * 0.58))
	var effect_x = min(RIGHT_UPGRADE_EFFECT_X, max(level_x + 42.0, panel_width * 0.72))
	return Vector2(level_x, effect_x)

func _layout_grouped_ship_upgrade_huds(ship_positions: Dictionary, companion_positions: Dictionary, ship_panel_x: float, companion_panel_x: float, panel_width: float, content_width: float, mining_hud_visible: bool) -> void:
	for ship_key in ship_upgrade_huds:
		var hud: Dictionary = ship_upgrade_huds[ship_key]
		var visible = mining_hud_visible and ship_positions.has(ship_key)
		var y = float(ship_positions.get(ship_key, 0.0))
		_layout_upgrade_hud(hud, ship_panel_x, y, panel_width, content_width, visible, bool(ship_upgrades_visible.get(ship_key, false)))
	for ship_key in companion_upgrade_huds:
		var hud: Dictionary = companion_upgrade_huds[ship_key]
		var visible = mining_hud_visible and selected_ore_upgrade_tab == "drones" and companion_positions.has(ship_key)
		var y = float(companion_positions.get(ship_key, 0.0))
		_layout_upgrade_hud(hud, companion_panel_x, y, panel_width, content_width, visible, bool(companion_upgrades_visible.get(ship_key, false)))

func _layout_upgrade_hud(hud: Dictionary, panel_x: float, y: float, panel_width: float, content_width: float, visible: bool, expanded: bool) -> float:
	var rows: Array = hud["rows"]
	var upgrade_columns = _get_upgrade_column_positions(panel_width)
	var level_column_x = float(upgrade_columns.x)
	var effect_column_x = float(upgrade_columns.y)
	var full_height = 38.0 + float(rows.size()) * RIGHT_UPGRADE_ROW_GAP
	var height = full_height if expanded else RIGHT_UPGRADE_HEADER_HEIGHT
	var panel = hud["panel"] as Panel
	var toggle = hud["toggle"] as Button
	var title = hud["title"] as Label
	var game_state = get_node_or_null("/root/GameState")
	var autobuy_unlocked = game_state and game_state.has_method("is_development_protocol_unlocked") and game_state.is_development_protocol_unlocked()
	panel.visible = visible
	toggle.visible = visible
	title.visible = visible
	panel.position = Vector2(panel_x - 8.0, y)
	panel.size = Vector2(panel_width, height)
	toggle.position = Vector2(panel_x, y + 8.0)
	toggle.text = ">" if expanded else "<"
	title.position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, y + 8.0)
	title.size = Vector2(content_width, 24.0)
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var row_visible = visible and expanded
		var row_y = y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index
		var button = row["button"] as Button
		var name_label = row["name"] as Label
		var level_label = row["level"] as Label
		var effect_label = row["effect"] as Label
		var separator = row["separator"] as HSeparator
		var autobuy = row["autobuy"] as Button
		for control in [button, name_label, level_label, effect_label, separator, autobuy]:
			control.visible = row_visible
		autobuy.visible = row_visible and autobuy_unlocked and str(row["config"].get("fixed_passive", "")).is_empty()
		button.position = Vector2(panel_x, row_y)
		name_label.position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_y)
		name_label.size = Vector2(max(1.0, level_column_x - RIGHT_UPGRADE_LABEL_X - 28.0), 24.0)
		autobuy.position = Vector2(panel_x + level_column_x - 20.0, row_y + 4.0)
		level_label.position = Vector2(panel_x + level_column_x, row_y)
		level_label.size = Vector2(max(1.0, effect_column_x - level_column_x - 4.0), 24.0)
		effect_label.position = Vector2(panel_x + effect_column_x, row_y)
		effect_label.size = Vector2(max(1.0, panel_width - effect_column_x - 8.0), 24.0)
		separator.position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_y + 25.0)
		separator.size = Vector2(max(1.0, panel_width - RIGHT_UPGRADE_LABEL_X - 12.0), 1.0)
	return height

func _get_research_panel_scale(viewport_size: Vector2) -> float:
	var max_panel_size = viewport_size * RESEARCH_PANEL_VIEWPORT_RATIO
	return min(1.0, min(max_panel_size.x / RESEARCH_PANEL_SIZE.x, max_panel_size.y / RESEARCH_PANEL_SIZE.y))

func _format_ore_text(amount: float) -> String:
	return "CREDITS  %06d" % int(round(amount))

func _update_ore_labels(amount: float) -> void:
	var ore_text = _format_ore_text(amount)
	var tooltip = "Exact Credits: %.2f" % amount
	if resource_label:
		resource_label.text = ore_text
		resource_label.tooltip_text = tooltip
	if right_ore_label:
		right_ore_label.text = ore_text
		right_ore_label.tooltip_text = tooltip

func _update_income_log() -> void:
	if income_log_label == null or resource_manager == null:
		return
	var entries: Array[Dictionary] = []
	if resource_manager.has_method("get_income_summary"):
		var summary: Dictionary = resource_manager.get_income_summary()
		for source in summary:
			entries.append({"source": str(source), "amount": float(summary[source])})
	entries.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["amount"]) > float(b["amount"]))
	var lines: Array[String] = ["INCOME | LAST 10 SEC"]
	for index in range(min(5, entries.size())):
		var entry = entries[index]
		lines.append("%s  +%.1f" % [str(entry["source"]).replace("_", " ").capitalize(), float(entry["amount"])])
	if entries.is_empty():
		lines.append("No recent Credit income")
	lines.append("")
	lines.append("LAST PURCHASE")
	lines.append(resource_manager.get_last_purchase_text() if resource_manager.has_method("get_last_purchase_text") else "None")
	income_log_label.text = "\n".join(lines)

func _on_resource_changed(amount):
	_update_ore_labels(float(amount))

func _process(delta: float) -> void:
	fps_refresh_elapsed += delta
	if fps_label and fps_refresh_elapsed >= FPS_REFRESH_INTERVAL:
		fps_refresh_elapsed = fmod(fps_refresh_elapsed, FPS_REFRESH_INTERVAL)
		fps_label.text = "FPS  %d" % Engine.get_frames_per_second()
		var frame_msec = float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
		var physics_msec = float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
		var draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var map_build_msec = float(map_view.get("last_draw_build_msec")) if map_view else 0.0
		var renderer = "%s/%s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name()]
		fps_label.tooltip_text = "Frame: %.2f ms | Physics: %.2f ms | HUD: %.2f ms | Map build: %.2f ms | Draw calls: %d | Renderer: %s | Cap: %d" % [frame_msec, physics_msec, last_hud_refresh_msec, map_build_msec, draw_calls, renderer, Engine.max_fps]
	if fleet_label == null:
		return
	hud_refresh_elapsed += delta
	if hud_refresh_elapsed < HUD_REFRESH_INTERVAL:
		return
	hud_refresh_elapsed = fmod(hud_refresh_elapsed, HUD_REFRESH_INTERVAL)
	var hud_refresh_started_usec = Time.get_ticks_usec()
	_update_development_protocol_button()
	_update_fleet_maneuver_button()
	_update_manual_control_buttons()
	if research_visible:
		_update_expedition_panel_values(false)
		last_hud_refresh_msec = float(Time.get_ticks_usec() - hud_refresh_started_usec) / 1000.0
		return
	var asteroid_count = get_tree().get_nodes_in_group("asteroids").size()
	var mining_count = 0
	for drone in get_tree().get_nodes_in_group("drones"):
		if int(drone.state) == 2:
			mining_count += 1
	fleet_label.text = "MINERS  %d ACTIVE     FIELD NODES  %d" % [mining_count, asteroid_count]
	if stage_label and resource_manager:
		var stage_prestige_level = 0
		var stage_game_state = get_node_or_null("/root/GameState")
		if stage_game_state:
			stage_prestige_level = int(stage_game_state.prestige_level)
		var field_name = resource_manager.get_field_display_name() if resource_manager.has_method("get_field_display_name") else "Field %d" % int(resource_manager.asteroid_field_level + 1)
		if resource_manager.next_stage_timer >= 0.0:
			stage_label.text = "PRESTIGE %d | FIELD %s | NEXT IN %02d" % [stage_prestige_level, field_name, int(ceil(resource_manager.next_stage_timer))]
		else:
			stage_label.text = "PRESTIGE %d | FIELD %s" % [stage_prestige_level, field_name]
	if upgrade_label and resource_manager:
		var speed_level = int(resource_manager.speed_level)
		var mining_level = int(resource_manager.mining_level)
		var mining_speed_level = int(resource_manager.mining_speed_level)
		var capacity_level = int(resource_manager.capacity_level)
		var drone_level = int(resource_manager.drone_level)
		var flagship_drone_count = int(resource_manager.get_active_drone_count("flagship"))
		var flagship_speed_level = int(resource_manager.flagship_speed_level)
		var click_gain = float(resource_manager.get_click_output()) * resource_manager.get_refinery_click_multiplier() * resource_manager.get_ship_ore_multiplier("flagship")
		var battle_click_damage = int(resource_manager.get_battle_click_damage())
		_update_ore_labels(float(resource_manager.total_resources))
		var click_income_rate = float(resource_manager.get_ship_income_rate("flagship"))
		var drone_income_rate = float(resource_manager.get_ship_income_rate("mining_drone"))
		var click_gain_text = _format_header_value(click_gain)
		var click_rate_text = _format_header_value(click_income_rate)
		_set_compact_header(upgrade_label, [
			"FLAGSHIP | %s C/CLICK | %s C/S" % [click_gain_text, click_rate_text],
			"FLAGSHIP | %s C/CLK | %s C/S" % [click_gain_text, click_rate_text],
			"FLAG | %s C/CLK | %s C/S" % [click_gain_text, click_rate_text],
			"FLAG | %s C/C | %s C/S" % [click_gain_text, click_rate_text]
		], "Flagship: %.2f Credits per click | %.2f Credits per second. Income is measured over the last 10 seconds. Mining clicks work within 1,000 units of the Flagship." % [click_gain, click_income_rate])
		click_output_text.text = "CLICK OUTPUT"
		click_multiplier_text.text = "INPUT RATE"
		mining_text.text = "MINING AMOUNT"
		mining_speed_text.text = "MINING SPEED"
		refining_text.text = "REFINING"
		capacity_text.text = "CAPACITY"
		speed_text.text = "MOVE SPEED"
		command_capacity_text.text = "COMMAND CAPACITY"
		flagship_speed_text.text = "MOVE SPEED"
		var click_rate = resource_manager.get_click_rate_cap()
		var hold_rate = resource_manager.get_hold_click_rate()
		var owned_flagship_drones = int(resource_manager.get_owned_drone_count("flagship"))
		_update_table_values(
			player_level_texts,
			player_effect_texts,
			[int(resource_manager.click_output_level), int(resource_manager.click_multiplier_level), drone_level, int(resource_manager.refining_level), flagship_speed_level],
			[click_gain_text, "%d / %d" % [int(hold_rate), int(click_rate)], "%d/%d" % [flagship_drone_count, owned_flagship_drones], "%.3fx" % resource_manager.get_refining_multiplier(), str(int(resource_manager.get_flagship_speed()))],
			[
				"Current mining output: %.2f Credits per accepted click. Current battle click damage: %d before temporary in-battle modifiers." % [click_gain, battle_click_damage],
				"Holding: %d activations per second. Manual input limit: %d registered clicks per second." % [int(hold_rate), int(click_rate)],
				"Active Flagship mining drones: %d of %d owned." % [flagship_drone_count, owned_flagship_drones],
				"Current global Credit multiplier: %.3fx." % resource_manager.get_refining_multiplier(),
				"Current Flagship movement speed: %d." % int(resource_manager.get_flagship_speed())
			]
		)
		_update_table_values(
			drone_level_texts,
			drone_effect_texts,
			[mining_level, mining_speed_level, capacity_level, speed_level],
			[str(int(resource_manager.get_mining_amount())), "%.1f" % resource_manager.get_mining_speed(), str(int(resource_manager.get_capacity())), str(int(resource_manager.get_speed()))],
			[
				"Current mining amount: %d Credits extracted per tick." % int(resource_manager.get_mining_amount()),
				"Current mining rate: %.1f ticks per second." % resource_manager.get_mining_speed(),
				"Current cargo capacity: %d Credits per mining drone." % int(resource_manager.get_capacity()),
				"Current mining-drone movement speed: %d." % int(resource_manager.get_speed())
			]
		)
		_update_upgrade_button(click_output_button, "Upgrade click output", int(resource_manager.click_output_level), resource_manager.get_ore_upgrade_cost("click_output"), resource_manager.get_ore_upgrade_cap("click_output"), ORE_UPGRADE_DESCRIPTIONS["click_output"])
		_update_upgrade_button(click_multiplier_button, "Upgrade input rate", int(resource_manager.click_multiplier_level), resource_manager.get_ore_upgrade_cost("click_multiplier"), resource_manager.get_ore_upgrade_cap("click_multiplier"), ORE_UPGRADE_DESCRIPTIONS["click_multiplier"])
		_update_upgrade_button(speed_button, "Upgrade drone move speed", speed_level, resource_manager.get_ore_upgrade_cost("speed"), resource_manager.get_ore_upgrade_cap("speed"), ORE_UPGRADE_DESCRIPTIONS["speed"])
		_update_upgrade_button(mining_button, "Upgrade mining power", mining_level, resource_manager.get_ore_upgrade_cost("mining"), resource_manager.get_ore_upgrade_cap("mining"), ORE_UPGRADE_DESCRIPTIONS["mining"])
		_update_upgrade_button(mining_speed_button, "Upgrade drone mining speed", mining_speed_level, resource_manager.get_ore_upgrade_cost("mining_speed"), resource_manager.get_ore_upgrade_cap("mining_speed"), ORE_UPGRADE_DESCRIPTIONS["mining_speed"])
		_update_upgrade_button(refining_button, "Upgrade refining", int(resource_manager.refining_level), resource_manager.get_ore_upgrade_cost("refining"), resource_manager.get_ore_upgrade_cap("refining"), ORE_UPGRADE_DESCRIPTIONS["refining"])
		_update_upgrade_button(capacity_button, "Upgrade cargo capacity", capacity_level, resource_manager.get_ore_upgrade_cost("capacity"), resource_manager.get_ore_upgrade_cap("capacity"), ORE_UPGRADE_DESCRIPTIONS["capacity"])
		_update_upgrade_button(drone_button, "Buy active drone", drone_level, resource_manager.get_drone_purchase_cost(), resource_manager.get_ore_upgrade_cap("drones"))
		_update_upgrade_button(flagship_speed_button, "Upgrade flagship speed", flagship_speed_level, resource_manager.get_ore_upgrade_cost("flagship_speed"), resource_manager.get_ore_upgrade_cap("flagship_speed"), ORE_UPGRADE_DESCRIPTIONS["flagship_speed"])
		if resource_manager.has_missing_owned_drones("flagship"):
			_update_upgrade_button(command_capacity_button, "Replace lost drone", flagship_drone_count, resource_manager.get_drone_purchase_cost(), drone_level, ORE_UPGRADE_DESCRIPTIONS["drones"])
		else:
			_update_upgrade_button(command_capacity_button, "Upgrade command capacity", drone_level, resource_manager.get_drone_purchase_cost(), resource_manager.get_ore_upgrade_cap("drones"), ORE_UPGRADE_DESCRIPTIONS["drones"])
		var drone_trip_gain = float(resource_manager.get_capacity()) * resource_manager.get_global_ore_multiplier()
		var drone_trip_text = _format_header_value(drone_trip_gain)
		var drone_rate_text = _format_header_value(drone_income_rate)
		_set_compact_header(drone_upgrade_label, [
			"MINING DRONES | %s C/TRIP | %s C/S" % [drone_trip_text, drone_rate_text],
			"DRONES | %s C/TRIP | %s C/S" % [drone_trip_text, drone_rate_text],
			"DRONES | %s C/T | %s C/S" % [drone_trip_text, drone_rate_text],
			"DRN | %s C/T | %s C/S" % [drone_trip_text, drone_rate_text]
		], "Mining Drones: %.2f Credits per trip | %.2f Credits per second. Combined income is measured over the last 10 seconds." % [drone_trip_gain, drone_income_rate])
	_update_refinery_upgrade_hud()
	_update_ship_upgrade_huds()
	_update_income_log()
	_update_autobuy_toggles()
	last_hud_refresh_msec = float(Time.get_ticks_usec() - hud_refresh_started_usec) / 1000.0

func _on_battle_pressed() -> void:
	if resource_manager and resource_manager.has_method("start_battle"):
		resource_manager.start_battle()
	else:
		_show_action("Battle unavailable")

func _set_expedition_tab(tab_name: String) -> void:
	expedition_tab = tab_name
	var showing_research = expedition_tab == "research"
	for control in research_row_controls:
		if control:
			control.visible = showing_research
	for control in reward_controls:
		if control:
			control.visible = not showing_research
	if research_tab_button:
		research_tab_button.disabled = showing_research
	if rewards_tab_button:
		rewards_tab_button.disabled = not showing_research
	if next_prestige_button:
		next_prestige_button.visible = not showing_research
	for button in research_category_buttons.values():
		(button as Button).visible = showing_research
	if showing_research:
		_layout_research_rows()
	_update_expedition_panel_values()

func _on_research_tab_pressed() -> void:
	_set_expedition_tab("research")

func _on_rewards_tab_pressed() -> void:
	_set_expedition_tab("rewards")

func _update_expedition_panel_values(refresh_layout: bool = true) -> void:
	_update_research_panel_values(refresh_layout)
	_update_rewards_panel_values()

func _update_research_panel_values(refresh_layout: bool = true) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	for tile_data in research_upgrade_tiles:
		var upgrade_type = str(tile_data["type"])
		var upgrade_key = str(tile_data["key"])
		var required_ship = str(tile_data.get("requires_ship", ""))
		var level_label = tile_data["level"] as Label
		var card_battle_button = tile_data["battle"] as Button
		var tile = tile_data["tile"] as Control
		var description = str(tile_data["description"])
		var ship_unlocked = _is_research_ship_unlocked(required_ship, game_state)
		var requirement_status = {"met": true, "summary": "", "details": []}
		if resource_manager and resource_manager.has_method("get_research_battle_requirement_status"):
			requirement_status = resource_manager.get_research_battle_requirement_status(upgrade_key)
		var requirement_met = bool(requirement_status.get("met", true))
		var requirement_summary = str(requirement_status.get("summary", ""))
		var requirement_progress = "%d/%d" % [int(requirement_status.get("current", 0)), int(requirement_status.get("required", 0))]
		var requirement_tooltip = ""
		if not Array(requirement_status.get("details", [])).is_empty():
			requirement_tooltip = "\nRequirement: %s" % requirement_summary
		if tile:
			tile.visible = ship_unlocked
		if not ship_unlocked:
			continue
		if upgrade_type == "cap":
			var cap_level = int(game_state.cap_levels.get(upgrade_key, 0))
			var cap_bonus = int(game_state.get_research_cap_value(upgrade_key))
			if level_label:
				level_label.text = "R%d | +%d CAP" % [cap_level, cap_bonus]
			if tile:
				tile.tooltip_text = "%s\nEach victory immediately adds one rank." % description
			if card_battle_button:
				var next_multiplier = float(game_state.get_research_battle_multiplier(upgrade_key))
				card_battle_button.disabled = not game_state.can_battle_research_card(upgrade_key) or not requirement_met
				card_battle_button.text = "Battle Rank %d" % (cap_level + 1)
				card_battle_button.tooltip_text = "Battle strength: %.2fx\nVictory immediately applies rank %d.%s" % [next_multiplier, cap_level + 1, requirement_tooltip]
		elif upgrade_type == "passive":
			var committed_passive_level = int(game_state.get_passive_level(upgrade_key))
			if level_label:
				level_label.text = "ACTIVE" if committed_passive_level > 0 else "NOT ACTIVE"
			if tile:
				tile.tooltip_text = "%s\nOne victory permanently activates this research." % description
			if card_battle_button:
				var next_multiplier = float(game_state.get_research_battle_multiplier(upgrade_key))
				if upgrade_key == "flagship_autor" and committed_passive_level > 0:
					var maneuver_enabled = bool(game_state.autor_enabled)
					card_battle_button.disabled = false
					card_battle_button.text = "Autor: ON" if maneuver_enabled else "Autor: OFF"
					card_battle_button.tooltip_text = "Toggle Autor: automatically mine or attack at the held-input rate. Manual input remains active."
				elif upgrade_key == "flagship_development_protocol" and committed_passive_level > 0:
					var protocol_enabled = bool(game_state.development_protocol_enabled)
					card_battle_button.disabled = false
					card_battle_button.text = "Auto Buy: ON" if protocol_enabled else "Auto Buy: OFF"
					card_battle_button.tooltip_text = "Toggle Development Protocol: Buy the most affordable enabled ship upgrade every 5 seconds. Prestige and research are never purchased."
				elif upgrade_key == "merlinda_derby_picks" and committed_passive_level > 0:
					var derby_enabled = bool(game_state.merlinda_derby_picks_enabled)
					card_battle_button.disabled = false
					card_battle_button.text = "Derby: ON" if derby_enabled else "Derby: OFF"
					card_battle_button.tooltip_text = "Toggle hazardous Pick Me Ups. Mishaps pay ore but may slow, stop, or temporarily remove a racer."
				else:
					card_battle_button.disabled = not game_state.can_battle_research_card(upgrade_key) or not requirement_met
					card_battle_button.text = "Completed" if committed_passive_level > 0 else ("Requires %s" % requirement_progress if not requirement_met else "Battle")
					card_battle_button.tooltip_text = "Permanently unlocked and retained through prestige." if committed_passive_level > 0 else "Battle strength: %.2fx\nVictory permanently applies this research.%s" % [next_multiplier, requirement_tooltip]
	for ship_key in research_ship_lock_labels:
		for lock_label in Array(research_ship_lock_labels[ship_key]):
			if lock_label:
				lock_label.visible = not _is_research_ship_unlocked(str(ship_key), game_state)
	if refresh_layout:
		_layout_research_rows()

func _format_ship_stat(stat_key: String, value) -> String:
	if stat_key == "click_multiplier":
		return "%.2fx" % float(value)
	if stat_key == "shield":
		return "%.0f%%" % (float(value) * 100.0)
	if stat_key == "global_income_bonus":
		return "+%.1f%%" % (float(value) * 100.0)
	return str(int(value))

func _update_refinery_upgrade_hud() -> void:
	if refinery_signal_button:
		refinery_signal_button.visible = false
	if refinery_upgrade_label:
		refinery_upgrade_label.visible = false
	_set_refinery_upgrade_contents_visible(false)

func _update_ship_upgrade_huds() -> void:
	if resource_manager == null:
		return
	var game_state = get_node_or_null("/root/GameState")
	for hud_collection in [ship_upgrade_huds, companion_upgrade_huds]:
		for ship_key in hud_collection:
			var hud: Dictionary = hud_collection[ship_key]
			var is_companion = bool(hud.get("is_companion", false))
			var panel = hud["panel"] as Control
			if panel == null or not panel.visible or not _is_upgrade_panel_in_scroll_view(panel):
				continue
			var display_name = str(hud.get("display_name", Catalog.get_display_name(ship_key)))
			var income_source = _get_companion_income_source(ship_key) if is_companion else ship_key
			var income_rate = float(resource_manager.get_ship_income_rate(income_source))
			var title_label = hud["title"] as Label
			_set_compact_header(title_label, ["%s UPGRADES" % display_name.to_upper(), display_name.to_upper()], "%s upgrades" % display_name)
			if ship_key == "ambrossa" and not is_companion and resource_manager.has_method("get_ambrossa_countdown"):
				var income_amount = float(resource_manager.get_ambrossa_income_amount())
				var countdown = int(ceil(resource_manager.get_ambrossa_countdown()))
				var income_text = _format_header_value(income_amount)
				_set_compact_header(title_label, [
					"AMBRESSA | %s C IN %02ds" % [income_text, countdown],
					"AMBRESSA | %s C/%02ds" % [income_text, countdown]
				], "Ambressa: %.2f Credits in %d seconds." % [income_amount, countdown])
			if income_rate > 0.0:
				if ship_key != "ambrossa" or is_companion:
					var rate_text = _format_header_value(income_rate)
					_set_compact_header(title_label, [
						"%s | %s C/S" % [display_name.to_upper(), rate_text],
						"%s %s C/S" % [display_name.to_upper(), rate_text]
					], "%s: %.2f Credits per second. Income is measured over the last 10 seconds." % [display_name, income_rate])
			var expanded = bool(companion_upgrades_visible.get(ship_key, false)) if is_companion else bool(ship_upgrades_visible.get(ship_key, false))
			if not expanded:
				continue
			for row in hud["rows"]:
				var stat_key = str(row["config"]["stat_key"])
				var owner_ship = str(row["config"].get("owner_ship", ship_key))
				var required_ship = str(row["config"].get("requires_ship", owner_ship))
				var fixed_passive = str(row["config"].get("fixed_passive", ""))
				var available = _is_research_ship_unlocked(required_ship, game_state)
				var effect = str(row["config"]["description"])
				if not available:
					row["level"].text = "LOCKED"
					row["effect"].text = "Requires %s" % Catalog.get_display_name(required_ship)
					row["button"].disabled = true
					continue
				if not fixed_passive.is_empty():
					var active = game_state and int(game_state.get_passive_level(fixed_passive)) > 0
					row["level"].text = "5/5" if active else "0/5"
					row["effect"].text = _compact_numeric_effect(effect)
					row["effect"].tooltip_text = effect
					row["button"].disabled = true
					row["button"].tooltip_text = "Activate this through its research battle."
					continue
				var level = int(resource_manager.get_companion_upgrade_level(ship_key, stat_key)) if is_companion else int(resource_manager.get_ship_upgrade_level(owner_ship, stat_key))
				var cap = int(resource_manager.get_companion_upgrade_cap(ship_key, stat_key)) if is_companion else int(resource_manager.get_ship_upgrade_cap(owner_ship, stat_key))
				var drone_stat = "" if is_companion else str(resource_manager._get_ship_mining_drone_stat(owner_ship))
				var replacing_drone = not is_companion and stat_key == drone_stat and not drone_stat.is_empty() and resource_manager.has_missing_owned_drones(owner_ship)
				var cost = int(resource_manager.get_companion_upgrade_cost(ship_key, stat_key)) if is_companion else int(resource_manager.get_ship_upgrade_cost(owner_ship, stat_key, 0 if replacing_drone else -1))
				if not is_companion and stat_key == drone_stat and not drone_stat.is_empty():
					var active_drones = int(resource_manager.get_active_drone_count(owner_ship))
					effect = "%d/%d" % [active_drones, level]
					row["effect"].tooltip_text = "%s\nActive drones: %d of %d owned." % [str(row["config"]["description"]), active_drones, level]
				else:
					effect = _compact_numeric_effect(effect)
					row["effect"].tooltip_text = str(row["config"]["description"])
				row["level"].text = "L%d" % level
				row["effect"].text = effect
				row["button"].disabled = not replacing_drone and level >= cap
				var purchase_text = "Replace lost drone: %d Credits" % cost if replacing_drone else ("MAX" if level >= cap else "Cost: %d Credits" % cost)
				row["button"].tooltip_text = "%s\n%s\nLevel: %d / %d\n%s" % [str(row["config"]["label"]), str(row["config"]["description"]), level, cap, purchase_text]
				if not is_companion:
					var effective = float(resource_manager.get_effective_ship_levels(owner_ship).get(stat_key, level))
					row["button"].tooltip_text += "\nEffective level: %.3f (includes overflow)" % effective
					var warning = resource_manager.get_ship_upgrade_warning(owner_ship, stat_key)
					if not warning.is_empty():
						row["effect"].text = "CAP / OVERFLOW"
						row["button"].tooltip_text += "\n" + warning
					if not replacing_drone and resource_manager.get_ship_upgrade_gains(owner_ship, stat_key).is_empty():
						row["button"].disabled = true

func _is_upgrade_panel_in_scroll_view(panel: Control) -> bool:
	if ore_upgrade_scroll == null:
		return true
	var margin = RIGHT_UPGRADE_ROW_GAP
	var visible_top = float(ore_upgrade_scroll.scroll_vertical) - margin
	var visible_bottom = float(ore_upgrade_scroll.scroll_vertical) + ore_upgrade_scroll.size.y + margin
	return panel.position.y + panel.size.y >= visible_top and panel.position.y <= visible_bottom

func _get_companion_income_source(companion_id: String) -> String:
	match companion_id:
		"vacuum":
			return "tobias"
		"racer":
			return "merlinda"
		"dyson":
			return "stapledon"
		"trader":
			return "tarrip"
	return companion_id

func _update_rewards_panel_values() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var next_target = int(game_state.prestige_level) + 1
	var next_data = game_state.get_prestige_data(next_target)
	if next_prestige_button:
		if next_data.is_empty():
			next_prestige_button.text = "All Expeditions Complete"
			next_prestige_button.disabled = true
		else:
			var next_cost = int(next_data.get("cost", 0))
			next_prestige_button.text = "Complete Expedition | %s C" % _format_number(next_cost)
			next_prestige_button.disabled = resource_manager == null or float(resource_manager.total_resources) < float(next_cost)
	for target_prestige in prestige_boss_levels:
		if not reward_entries.has(target_prestige):
			continue
		var completed = int(game_state.prestige_level) >= target_prestige
		var is_next = target_prestige == int(game_state.prestige_level) + 1
		var cost = int(game_state.get_prestige_data(target_prestige).get("cost", 0))
		var can_purchase = is_next and resource_manager and float(resource_manager.total_resources) >= float(cost)
		var status_label = reward_entries[target_prestige]["status"] as Label
		var attempt_button = reward_entries[target_prestige]["button"] as Button
		if status_label:
			if completed:
				status_label.text = "COMPLETED"
			elif is_next:
				status_label.text = "READY" if can_purchase else "NEED %s CREDITS" % _format_number(cost)
			else:
				status_label.text = "LOCKED"
		if attempt_button:
			attempt_button.disabled = not can_purchase
			attempt_button.text = "Completed" if completed else "Complete Expedition"
			attempt_button.tooltip_text = "Reward permanently active." if completed else ("Requires %s Credits. Recall the fleet, reset the current Credit balance, and commission this ship." % _format_number(cost) if is_next else "Complete the previous expedition first.")
		var dev_ship_button = reward_entries[target_prestige].get("dev_button") as Button
		var ship_key = str(reward_entries[target_prestige].get("ship", ""))
		if dev_ship_button:
			var ship_enabled = game_state.is_ship_unlocked(ship_key)
			dev_ship_button.button_pressed = ship_enabled
			dev_ship_button.text = "DEV SHIP: ON" if ship_enabled else "DEV SHIP: OFF"

func _on_next_prestige_pressed() -> void:
	_request_expedition_completion()

func _on_prestige_purchase_pressed(target_prestige: int) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or target_prestige != int(game_state.prestige_level) + 1:
		_show_action("Complete the previous expedition first")
		return
	_request_expedition_completion(target_prestige)

func _request_expedition_completion(target_prestige: int = -1) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or resource_manager == null or expedition_confirmation_dialog == null:
		return
	var next_target = int(game_state.prestige_level) + 1
	if target_prestige >= 0 and target_prestige != next_target:
		_show_action("Complete the previous expedition first")
		return
	var prestige_data: Dictionary = game_state.get_prestige_data(next_target)
	if prestige_data.is_empty():
		_show_action("All expeditions complete")
		return
	var cost = int(prestige_data.get("cost", 0))
	if float(resource_manager.total_resources) < float(cost):
		_show_action("Need %s Credits to complete this expedition" % _format_number(cost))
		return
	var ship_key = str(prestige_data.get("ship", ""))
	var ship_name = Catalog.get_display_name(ship_key)
	pending_expedition_target = next_target
	expedition_confirmation_dialog.dialog_text = "Complete Expedition %d?\n\nRecall the fleet and commission: %s\nRequired Credits: %s\n\nResets:\n- Current Credit balance, field, and fleet position\n- Active drones and Credit upgrade levels\n- Upgrade Cap research ranks\n- Automation toggles\n\nRetained:\n- One-time research\n- Previously commissioned ships" % [next_target, ship_name, _format_number(cost)]
	var viewport_size = get_viewport().get_visible_rect().size
	var popup_size = Vector2i(int(min(560.0, max(280.0, viewport_size.x - 40.0))), int(min(360.0, max(260.0, viewport_size.y - 40.0))))
	expedition_confirmation_dialog.popup_centered(popup_size)

func _on_expedition_completion_confirmed() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or pending_expedition_target != int(game_state.prestige_level) + 1:
		pending_expedition_target = 0
		return
	pending_expedition_target = 0
	_perform_prestige(false)

func _close_expedition_ui() -> void:
	pending_expedition_target = 0
	if expedition_confirmation_dialog and expedition_confirmation_dialog.visible:
		expedition_confirmation_dialog.hide()
	if research_visible:
		_set_research_visibility(false)

func _on_research_battle_pressed(research_key: String) -> void:
	if research_key == "flagship_autor":
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.is_autor_unlocked():
			_on_autor_toggle_pressed()
			return
	if research_key == "flagship_development_protocol":
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.is_development_protocol_unlocked():
			_on_development_protocol_toggle_pressed()
			return
	if research_key == "merlinda_derby_picks":
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.is_merlinda_derby_picks_unlocked():
			game_state.set_merlinda_derby_picks_enabled(not bool(game_state.merlinda_derby_picks_enabled))
			_update_research_panel_values(false)
			_show_action("Derby Picks enabled" if game_state.merlinda_derby_picks_enabled else "Derby Picks disabled")
			return
	if resource_manager and resource_manager.has_method("get_research_battle_requirement_status"):
		var requirement_status: Dictionary = resource_manager.get_research_battle_requirement_status(research_key)
		if not bool(requirement_status.get("met", true)):
			_show_action("Research requirement: %s" % str(requirement_status.get("summary", "ore upgrades required")))
			return
	if resource_manager and resource_manager.has_method("start_research_hunt") and resource_manager.start_research_hunt(research_key):
		return
	_show_action("This research battle is currently unavailable")

func _on_autor_toggle_pressed() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("set_autor_enabled"):
		return
	game_state.set_autor_enabled(not bool(game_state.autor_enabled))
	_update_fleet_maneuver_button()
	_update_research_panel_values()
	_show_action("Autor enabled" if game_state.autor_enabled else "Autor disabled")

func _update_fleet_maneuver_button() -> void:
	if fleet_maneuver_button == null:
		return
	var game_state = get_node_or_null("/root/GameState")
	var unlocked = game_state and game_state.has_method("is_autor_unlocked") and game_state.is_autor_unlocked()
	var enabled = unlocked and bool(game_state.autor_enabled)
	fleet_maneuver_button.visible = unlocked and not _has_open_research_overlay()
	fleet_maneuver_button.button_pressed = enabled
	var compact_label = fleet_maneuver_button.size.x < 100.0
	fleet_maneuver_button.text = ("Autor ON" if enabled else "Autor OFF") if compact_label else ("Autor: ON" if enabled else "Autor: OFF")
	fleet_maneuver_button.tooltip_text = "Toggle Autor: automatically mine or attack at the held-input rate while manual input remains available."

func _on_development_protocol_toggle_pressed() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("set_development_protocol_enabled"):
		return
	game_state.set_development_protocol_enabled(not bool(game_state.development_protocol_enabled))
	_update_development_protocol_button()
	_update_research_panel_values()
	_show_action("Development Protocol enabled" if game_state.development_protocol_enabled else "Development Protocol disabled")

func _update_development_protocol_button() -> void:
	if development_protocol_button == null:
		return
	var game_state = get_node_or_null("/root/GameState")
	var unlocked = game_state and game_state.has_method("is_development_protocol_unlocked") and game_state.is_development_protocol_unlocked()
	var enabled = unlocked and bool(game_state.development_protocol_enabled)
	development_protocol_button.visible = unlocked and not _has_open_research_overlay()
	development_protocol_button.button_pressed = enabled
	var compact_label = development_protocol_button.size.x < 100.0
	development_protocol_button.text = ("Auto: ON" if enabled else "Auto: OFF") if compact_label else ("Auto Buy: ON" if enabled else "Auto Buy: OFF")
	development_protocol_button.tooltip_text = "Toggle Development Protocol: Buy most affordable ship upgrade every 5 seconds."

func _refresh_drones_after_reward() -> void:
	if resource_manager == null or not resource_manager.has_method("configure_drone"):
		return
	var parent = resource_manager.get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			resource_manager.configure_drone(drone)

func _set_research_visibility(visible: bool) -> void:
	research_visible = visible
	if research_panel:
		research_panel.visible = visible
	if research_toggle_button:
		research_toggle_button.visible = visible
	if research_status_label:
		research_status_label.visible = visible
	_set_mining_hud_visibility(not _has_open_research_overlay())
	if research_button:
		research_button.visible = true
		research_button.text = "Close Expedition Details" if visible else "Expedition Details"
		research_button.move_to_front()
	if visible:
		_update_expedition_panel_values()

func _on_research_toggle_pressed() -> void:
	var next_visible = not research_visible
	_set_research_visibility(next_visible)

func _has_open_research_overlay() -> bool:
	return research_visible

func _set_mining_hud_visibility(visible: bool) -> void:
	var civilian_visible = visible and selected_ore_upgrade_tab == "civilian"
	var drones_visible = visible and selected_ore_upgrade_tab == "drones"
	for hud_control in [resource_label, fleet_label, stage_label, fps_label, last_action_label, get_node_or_null("TitleLabel"), get_node_or_null("HelpLabel")]:
		if hud_control:
			hud_control.visible = visible
	if research_button:
		research_button.visible = true
	if income_log_panel and not visible:
		income_log_panel.visible = false
	if map_view:
		map_view.visible = true
		var selection_label = map_view.get_node_or_null("Label") as Control
		if selection_label:
			selection_label.visible = visible
	if right_ore_label:
		right_ore_label.visible = visible
	_update_development_protocol_button()
	_update_fleet_maneuver_button()
	if ore_upgrade_scroll:
		ore_upgrade_scroll.visible = visible
	for button in ore_upgrade_tab_buttons.values():
		(button as Button).visible = visible
	if dev_panel:
		dev_panel.visible = visible
	if controls_toggle_button:
		controls_toggle_button.visible = visible
	if controls_label:
		controls_label.visible = visible and control_buttons_visible
	_set_control_buttons_visibility(visible and control_buttons_visible)
	if signal_button:
		signal_button.visible = civilian_visible
	if upgrade_label:
		upgrade_label.visible = civilian_visible
	_set_player_upgrade_contents_visible(civilian_visible and player_upgrades_visible)
	if drone_signal_button:
		drone_signal_button.visible = drones_visible
	if drone_upgrade_label:
		drone_upgrade_label.visible = drones_visible
	_set_drone_upgrade_contents_visible(drones_visible and drone_upgrades_visible)
	_update_refinery_upgrade_hud()
	if not visible:
		for hud_collection in [ship_upgrade_huds, companion_upgrade_huds]:
			for hud in hud_collection.values():
				hud["panel"].visible = false
				hud["toggle"].visible = false
				hud["title"].visible = false
				for row in hud["rows"]:
					for control_key in ["button", "name", "level", "effect", "separator"]:
						row[control_key].visible = false
	else:
		_layout_hud()

func _set_control_buttons_visibility(visible: bool) -> void:
	for node_name in ["CenterButton", "LockFocusButton", "SplitFocusButton", "NewFieldButton"]:
		var node = get_node_or_null(node_name) as Control
		if node:
			var requires_manual_control = node_name in ["LockFocusButton", "SplitFocusButton"]
			var game_state = get_node_or_null("/root/GameState")
			var manual_control_unlocked = game_state and game_state.has_method("is_manual_drone_control_unlocked") and game_state.is_manual_drone_control_unlocked()
			node.visible = visible and (not requires_manual_control or manual_control_unlocked)

func _update_manual_control_buttons() -> void:
	var game_state = get_node_or_null("/root/GameState")
	var unlocked = game_state and game_state.has_method("is_manual_drone_control_unlocked") and game_state.is_manual_drone_control_unlocked()
	for node_name in ["LockFocusButton", "SplitFocusButton"]:
		var node = get_node_or_null(node_name) as Button
		if node:
			node.visible = unlocked and control_buttons_visible and not _has_open_research_overlay()

func _on_controls_signal_pressed() -> void:
	control_buttons_visible = not control_buttons_visible
	_set_control_buttons_visibility(control_buttons_visible and not _has_open_research_overlay())
	if controls_label:
		controls_label.visible = control_buttons_visible and not _has_open_research_overlay()
	if controls_toggle_button:
		controls_toggle_button.text = ">" if control_buttons_visible else "<"

func _on_dev_add_ore_pressed() -> void:
	if resource_manager and resource_manager.has_method("add_resources"):
		resource_manager.add_resources(100000.0)
		_show_action("Dev: +100,000 Credits")

func _on_dev_prestige_pressed() -> void:
	_perform_prestige(true)

func _on_dev_ship_toggle_pressed(ship_key: String) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("dev_set_ship_enabled"):
		return
	var enabled = not game_state.is_ship_unlocked(ship_key)
	game_state.dev_set_ship_enabled(ship_key, enabled)
	if resource_manager and resource_manager.has_method("apply_dev_ship_toggle"):
		resource_manager.apply_dev_ship_toggle(ship_key, enabled)
	_show_action("Dev: %s %s" % [Catalog.get_display_name(ship_key), "added" if enabled else "removed"])
	_layout_hud()
	_update_expedition_panel_values()

func _perform_prestige(force_prestige: bool) -> void:
	if resource_manager and resource_manager.has_method("purchase_prestige"):
		if resource_manager.purchase_prestige(force_prestige):
			var game_state = get_node_or_null("/root/GameState")
			var prestige = int(game_state.prestige_level) if game_state else 0
			var prestige_data: Dictionary = game_state.get_prestige_data(prestige) if game_state else {}
			var ship_name = Catalog.get_display_name(str(prestige_data.get("ship", ""))) if not prestige_data.is_empty() else "new ship"
			_show_action("Expedition complete: %s commissioned | Prestige %d" % [ship_name, prestige])
			_set_research_visibility(false)
			_layout_hud()
		else:
			_show_action("Not enough Credits to complete the expedition")
	_update_expedition_panel_values()

func _create_upgrade_button(description: String, x: float, y: float, callback: Callable) -> Button:
	var button = Button.new()
	button.text = "+"
	button.tooltip_text = description
	button.position = Vector2(x, y)
	button.size = Vector2(28, 24)
	add_child(button)
	button.pressed.connect(callback)
	return button

func _create_autobuy_toggle(owner: String, stat_key: String, section: String, row_index: int) -> Button:
	var button = Button.new()
	button.text = "●"
	button.flat = true
	button.size = Vector2(18.0, 18.0)
	button.tooltip_text = "Development Protocol can buy this upgrade. Click to exclude it."
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(Callable(self, "_on_autobuy_upgrade_toggled").bind(owner, stat_key))
	add_child(button)
	autobuy_toggle_buttons.append({"button": button, "owner": owner, "stat": stat_key, "section": section, "index": row_index})
	return button

func _on_autobuy_upgrade_toggled(owner: String, stat_key: String) -> void:
	if resource_manager and resource_manager.has_method("toggle_autobuy_upgrade"):
		resource_manager.toggle_autobuy_upgrade(owner, stat_key)
		_update_autobuy_toggles()

func _update_autobuy_toggles() -> void:
	if resource_manager == null:
		return
	for auto_data in autobuy_toggle_buttons:
		var enabled = resource_manager.is_autobuy_upgrade_enabled(str(auto_data["owner"]), str(auto_data["stat"]))
		var button = auto_data["button"] as Button
		button.add_theme_color_override("font_color", Color("64e58a") if enabled else Color("ef6262"))
		button.tooltip_text = "Development Protocol can buy this upgrade. Click to exclude it." if enabled else "Development Protocol skips this upgrade. Click to include it."

func _get_upgrade_tab_color(tab_key: String) -> Color:
	match tab_key:
		"military":
			return MILITARY_FONT_COLOR
		"support":
			return SUPPORT_FONT_COLOR
		"utility":
			return UTILITY_FONT_COLOR
		"drones":
			return Color("72d6e8")
		_:
			return CIVILIAN_FONT_COLOR

func _style_upgrade_tab(button: Button, tab_key: String) -> void:
	var color = _get_upgrade_tab_color(tab_key)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", color.lightened(0.2))
	button.add_theme_color_override("font_focus_color", color.lightened(0.2))
	button.add_theme_stylebox_override("normal", _make_flat_style(Color(color.r, color.g, color.b, 0.10), Color(color.r, color.g, color.b, 0.48), 1, 3))
	button.add_theme_stylebox_override("hover", _make_flat_style(Color(color.r, color.g, color.b, 0.18), Color(color.r, color.g, color.b, 0.78), 1, 3))
	button.add_theme_stylebox_override("pressed", _make_flat_style(Color(color.r, color.g, color.b, 0.30), color, 2, 3))
	button.add_theme_stylebox_override("focus", _make_flat_style(Color(color.r, color.g, color.b, 0.24), color.lightened(0.12), 2, 3))

func _build_ore_upgrade_tabs() -> void:
	for tab_key in UPGRADE_TAB_ORDER:
		var button = Button.new()
		button.name = "%sOreUpgradeTab" % str(tab_key).to_pascal_case()
		button.text = "%d %s" % [UPGRADE_TAB_ORDER.find(tab_key) + 1, str(UPGRADE_TAB_TITLES[tab_key]).capitalize()]
		button.toggle_mode = true
		button.tooltip_text = str(UPGRADE_TAB_DESCRIPTIONS.get(tab_key, "Show %s ore upgrades." % str(UPGRADE_TAB_TITLES[tab_key]).to_lower()))
		button.add_theme_font_size_override("font_size", 11)
		_style_upgrade_tab(button, tab_key)
		add_child(button)
		button.pressed.connect(Callable(self, "_on_ore_upgrade_tab_pressed").bind(tab_key))
		ore_upgrade_tab_buttons[tab_key] = button

	ore_upgrade_empty_label = Label.new()
	ore_upgrade_empty_label.name = "OreUpgradeEmptyLabel"
	ore_upgrade_empty_label.text = EMPTY_SHIP_CLASS_MESSAGE
	ore_upgrade_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ore_upgrade_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ore_upgrade_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ore_upgrade_empty_label.add_theme_font_size_override("font_size", 14)
	ore_upgrade_empty_label.add_theme_color_override("font_color", Color("8da8b8"))
	add_child(ore_upgrade_empty_label)

func _on_ore_upgrade_tab_pressed(tab_key: String) -> void:
	selected_ore_upgrade_tab = tab_key
	focused_ore_ship_key = ""
	_layout_hud()
	_set_mining_hud_visibility(not _has_open_research_overlay())

func focus_ore_upgrade_ship(ship_key: String) -> void:
	if ship_key.is_empty():
		return
	var game_state = get_node_or_null("/root/GameState")
	if not _is_ore_ship_unlocked(ship_key, game_state):
		return
	selected_ore_upgrade_tab = "civilian" if ship_key == "flagship" else Catalog.get_category(ship_key)
	focused_ore_ship_key = ship_key
	if ship_key == "flagship":
		player_upgrades_visible = true
	elif ship_upgrades_visible.has(ship_key):
		ship_upgrades_visible[ship_key] = true
	_layout_hud()
	_set_mining_hud_visibility(not _has_open_research_overlay())
	call_deferred("_scroll_to_focused_ore_ship")

func _apply_ore_ship_highlights() -> void:
	if upgrade_panel and flagship_upgrade_panel_style:
		upgrade_panel.add_theme_stylebox_override("panel", _get_ore_ship_panel_style(flagship_upgrade_panel_style, CIVILIAN_FONT_COLOR, focused_ore_ship_key == "flagship"))
	for ship_key in ship_upgrade_huds:
		var hud: Dictionary = ship_upgrade_huds[ship_key]
		var panel = hud["panel"] as Panel
		var base_style = hud.get("base_style") as StyleBoxFlat
		var color: Color = hud.get("color", Catalog.CATEGORY_COLORS.get(Catalog.get_category(ship_key), Color.WHITE))
		if panel and base_style:
			panel.add_theme_stylebox_override("panel", _get_ore_ship_panel_style(base_style, color, focused_ore_ship_key == ship_key))

func _get_ore_ship_panel_style(base_style: StyleBoxFlat, color: Color, highlighted: bool) -> StyleBoxFlat:
	if not highlighted:
		return base_style
	var style = base_style.duplicate() as StyleBoxFlat
	style.bg_color = Color(color.r, color.g, color.b, 0.18)
	style.border_color = color.lightened(0.18)
	style.set_border_width_all(3)
	return style

func _scroll_to_focused_ore_ship() -> void:
	if ore_upgrade_scroll == null or focused_ore_ship_key.is_empty():
		return
	var target_panel: Control = upgrade_panel if focused_ore_ship_key == "flagship" else null
	if target_panel == null and ship_upgrade_huds.has(focused_ore_ship_key):
		target_panel = ship_upgrade_huds[focused_ore_ship_key]["panel"] as Control
	if target_panel and target_panel.visible:
		ore_upgrade_scroll.scroll_vertical = int(max(0.0, target_panel.position.y - 6.0))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if (expedition_confirmation_dialog and expedition_confirmation_dialog.visible) or research_visible:
			_close_expedition_ui()
			get_viewport().set_input_as_handled()
			return
		_set_pause_menu_visibility(not pause_menu_visible)
		get_viewport().set_input_as_handled()
		return
	if pause_menu_visible:
		get_viewport().set_input_as_handled()
		return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return
	var focus = get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	if event.keycode == KEY_E:
		_set_research_visibility(not research_visible)
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_TAB:
		if research_visible:
			_set_expedition_tab("rewards" if expedition_tab == "research" else "research")
		else:
			var current_index = UPGRADE_TAB_ORDER.find(selected_ore_upgrade_tab)
			_on_ore_upgrade_tab_pressed(UPGRADE_TAB_ORDER[(current_index + 1) % UPGRADE_TAB_ORDER.size()])
		get_viewport().set_input_as_handled()
		return
	var index = int(event.keycode) - KEY_1
	if index >= 0 and index < UPGRADE_TAB_ORDER.size():
		if research_visible:
			_on_research_category_tab_pressed(UPGRADE_TAB_ORDER[index])
		else:
			_on_ore_upgrade_tab_pressed(UPGRADE_TAB_ORDER[index])
		get_viewport().set_input_as_handled()

func _build_ore_upgrade_scroll() -> void:
	ore_upgrade_scroll = ScrollContainer.new()
	ore_upgrade_scroll.name = "OreUpgradeScroll"
	ore_upgrade_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ore_upgrade_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ore_upgrade_scroll.follow_focus = true
	add_child(ore_upgrade_scroll)
	ore_upgrade_content = Control.new()
	ore_upgrade_content.name = "OreUpgradeContent"
	ore_upgrade_scroll.add_child(ore_upgrade_content)
	var controls: Array = [
		upgrade_panel, signal_button, upgrade_label,
		drone_panel, drone_signal_button, drone_upgrade_label,
		refinery_panel, refinery_signal_button, refinery_upgrade_label,
		ore_upgrade_empty_label,
		click_output_text, click_multiplier_text, command_capacity_text, flagship_speed_text, refining_text,
		mining_text, mining_speed_text, capacity_text, speed_text,
		click_output_button, click_multiplier_button, command_capacity_button, flagship_speed_button, refining_button,
		mining_button, mining_speed_button, capacity_button, speed_button
	]
	controls.append_array(player_level_texts)
	controls.append_array(player_effect_texts)
	controls.append_array(player_separators)
	controls.append_array(drone_level_texts)
	controls.append_array(drone_effect_texts)
	controls.append_array(drone_separators)
	controls.append_array(refinery_upgrade_texts)
	controls.append_array(refinery_upgrade_buttons)
	controls.append_array(refinery_level_texts)
	controls.append_array(refinery_effect_texts)
	controls.append_array(refinery_separators)
	for auto_data in autobuy_toggle_buttons:
		controls.append(auto_data["button"])
	for hud in ship_upgrade_huds.values():
		controls.append(hud["panel"])
		controls.append(hud["toggle"])
		controls.append(hud["title"])
		for row in hud["rows"]:
			controls.append(row["button"])
			controls.append(row["name"])
			controls.append(row["level"])
			controls.append(row["effect"])
			controls.append(row["separator"])
			controls.append(row["autobuy"])
	for hud in companion_upgrade_huds.values():
		controls.append(hud["panel"])
		controls.append(hud["toggle"])
		controls.append(hud["title"])
		for row in hud["rows"]:
			controls.append(row["button"])
			controls.append(row["name"])
			controls.append(row["level"])
			controls.append(row["effect"])
			controls.append(row["separator"])
			controls.append(row["autobuy"])
	for control in controls:
		if control and control.get_parent() == self:
			control.reparent(ore_upgrade_content, false)

func _build_ship_upgrade_hud(ship_key: String, panel_style: StyleBoxFlat, is_companion: bool = false) -> void:
	var ship_data = Catalog.get_companion_data(ship_key) if is_companion else Catalog.get_ship_data(ship_key)
	var rows: Array = []
	var ore_rows = Array(ship_data.get("ore", [])) if is_companion else Catalog.get_ore_rows(ship_key)
	if ore_rows.is_empty() and is_companion and ship_key == "fighter":
		rows.append({
			"label": "FIGHTER BAYS", "stat_key": "fighter_bays", "owner_ship": "hammond",
			"requires_ship": "hammond", "fixed_passive": "hammond_fighter_bays",
			"description": "Deploy five fighter companions at the beginning of every battle."
		})
	elif ore_rows.is_empty():
		return
	for ore_row in ore_rows:
		rows.append({
			"label": str(ore_row["label"]),
			"stat_key": str(ore_row.get("stat", "")),
			"owner_ship": ship_key,
			"requires_ship": str(ore_row.get("requires_ship", ship_data.get("required_ship", ""))),
			"fixed_passive": str(ore_row.get("fixed_passive", "")),
			"description": str(ore_row.get("effect", ore_row.get("description", "")))
		})
	var display_name = Catalog.get_companion_display_name(ship_key) if is_companion else Catalog.get_display_name(ship_key)
	var config: Dictionary = {
		"title": "%s UPGRADES" % display_name.to_upper(),
		"color": Color("72d6e8") if is_companion else Catalog.CATEGORY_COLORS.get(Catalog.get_category(ship_key), CIVILIAN_FONT_COLOR),
		"rows": rows
	}
	var node_prefix = "%sCompanion" % ship_key.to_pascal_case() if is_companion else ship_key.to_pascal_case()
	var font_color: Color = config["color"]
	var panel = Panel.new()
	panel.name = "%sUpgradePanel" % node_prefix
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var generated_panel_style = panel_style.duplicate() as StyleBoxFlat
	generated_panel_style.border_color = Color(font_color.r, font_color.g, font_color.b, 0.65)
	panel.add_theme_stylebox_override("panel", generated_panel_style)
	add_child(panel)
	var toggle = Button.new()
	toggle.text = "<"
	toggle.tooltip_text = "Toggle %s" % str(config["title"]).to_lower()
	toggle.size = Vector2(28.0, 28.0)
	add_child(toggle)
	var toggle_callback = "_on_companion_upgrade_toggle" if is_companion else "_on_ship_upgrade_toggle"
	toggle.pressed.connect(Callable(self, toggle_callback).bind(ship_key))
	var title = Label.new()
	title.text = str(config["title"])
	title.size = Vector2(300.0, 24.0)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", font_color)
	add_child(title)
	rows = []
	for row_data in config["rows"]:
		var button = Button.new()
		button.text = "+" if str(row_data["fixed_passive"]).is_empty() else "-"
		button.tooltip_text = str(row_data["description"])
		button.size = Vector2(30.0, 26.0)
		add_child(button)
		if str(row_data["fixed_passive"]).is_empty():
			var callback = "_on_upgrade_companion_stat" if is_companion else "_on_upgrade_ship_stat"
			button.pressed.connect(Callable(self, callback).bind(ship_key, str(row_data["stat_key"])))
		else:
			button.disabled = true
		var name_label = Label.new()
		name_label.text = str(row_data["label"])
		name_label.tooltip_text = str(row_data["description"])
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", font_color)
		add_child(name_label)
		var level_label = Label.new()
		level_label.clip_text = true
		level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.add_theme_color_override("font_color", font_color)
		add_child(level_label)
		var effect_label = Label.new()
		effect_label.tooltip_text = str(row_data["description"])
		effect_label.clip_text = true
		effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		effect_label.add_theme_font_size_override("font_size", 12)
		effect_label.add_theme_color_override("font_color", font_color)
		add_child(effect_label)
		var separator = HSeparator.new()
		separator.name = "%s%sUpgradeSeparator" % [node_prefix, str(row_data["stat_key"]).to_pascal_case()]
		separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(separator)
		var autobuy_owner = "companion:%s" % ship_key if is_companion else ship_key
		var autobuy = _create_autobuy_toggle(autobuy_owner, str(row_data["stat_key"]), "dynamic", rows.size())
		rows.append({"config": row_data, "button": button, "name": name_label, "level": level_label, "effect": effect_label, "separator": separator, "autobuy": autobuy})
	var target_huds = companion_upgrade_huds if is_companion else ship_upgrade_huds
	target_huds[ship_key] = {"panel": panel, "toggle": toggle, "title": title, "rows": rows, "is_companion": is_companion, "display_name": display_name, "base_style": generated_panel_style, "color": font_color}

func _on_ship_upgrade_toggle(ship_key: String) -> void:
	ship_upgrades_visible[ship_key] = not bool(ship_upgrades_visible.get(ship_key, false))
	_layout_hud()

func _on_companion_upgrade_toggle(ship_key: String) -> void:
	companion_upgrades_visible[ship_key] = not bool(companion_upgrades_visible.get(ship_key, false))
	_layout_hud()

func _on_upgrade_ship_stat(ship_key: String, stat_key: String) -> void:
	var warning = resource_manager.get_ship_upgrade_warning(ship_key, stat_key) if resource_manager else ""
	if resource_manager and resource_manager.upgrade_ship_stat(ship_key, stat_key):
		var display_name = ship_key.capitalize()
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.has_method("get_ship_profile"):
			var profile = game_state.get_ship_profile(StringName(ship_key)) as ShipProfile
			if profile:
				display_name = profile.display_name
		_show_action(warning if not warning.is_empty() else "%s %s upgraded" % [display_name, stat_key.capitalize()])
	else:
		_show_action("Upgrade unavailable")

func _on_upgrade_companion_stat(companion_id: String, stat_key: String) -> void:
	if resource_manager and resource_manager.upgrade_companion_stat(companion_id, stat_key):
		_show_action("%s %s upgraded" % [Catalog.get_companion_display_name(companion_id), stat_key.capitalize()])
	else:
		_show_action("Upgrade unavailable")

func _create_upgrade_row(row_name: String, x: float, y: float, section: String) -> Label:
	var font_color = CIVILIAN_FONT_COLOR
	var row_label = Label.new()
	row_label.name = "%sUpgradeLabel" % row_name
	row_label.position = Vector2(x + RIGHT_UPGRADE_LABEL_X, y)
	row_label.size = Vector2(RIGHT_UPGRADE_LEVEL_X - RIGHT_UPGRADE_LABEL_X - 6.0, 24)
	row_label.clip_text = true
	row_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row_label.add_theme_font_size_override("font_size", 12)
	row_label.add_theme_color_override("font_color", font_color)
	add_child(row_label)
	var level_label = Label.new()
	level_label.name = "%sLevelText" % row_name
	level_label.position = Vector2(x + RIGHT_UPGRADE_LEVEL_X, y)
	level_label.size = Vector2(44, 24)
	level_label.clip_text = true
	level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", font_color)
	add_child(level_label)
	var effect_label = Label.new()
	effect_label.name = "%sEffectText" % row_name
	effect_label.position = Vector2(x + RIGHT_UPGRADE_EFFECT_X, y)
	effect_label.size = Vector2(106, 24)
	effect_label.clip_text = true
	effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", font_color)
	add_child(effect_label)
	var separator = HSeparator.new()
	separator.name = "%sUpgradeSeparator" % row_name
	separator.position = Vector2(x + RIGHT_UPGRADE_LABEL_X, y + 25)
	separator.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH - RIGHT_UPGRADE_LABEL_X - 12.0, 1)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(separator)
	if section == "player":
		player_separators.append(separator)
		player_level_texts.append(level_label)
		player_effect_texts.append(effect_label)
	elif section == "drone":
		drone_separators.append(separator)
		drone_level_texts.append(level_label)
		drone_effect_texts.append(effect_label)
	else:
		refinery_separators.append(separator)
		refinery_level_texts.append(level_label)
		refinery_effect_texts.append(effect_label)
	return row_label

func _update_table_values(level_labels: Array[Label], effect_labels: Array[Label], levels: Array, effects: Array, tooltips: Array = []) -> void:
	for index in range(level_labels.size()):
		level_labels[index].text = "L%d" % int(levels[index])
		effect_labels[index].text = str(effects[index])
		if index < tooltips.size():
			effect_labels[index].tooltip_text = str(tooltips[index])

func _update_upgrade_button(button: Button, label: String, level: int, cost: int = -1, max_level: int = 10, description: String = "") -> void:
	if button == null:
		return
	button.text = "+"
	var details = "\n%s" % description if not description.is_empty() else ""
	if level >= max_level:
		button.tooltip_text = "%s%s\nLevel: %d\nMAX UPGRADE" % [label, details, max_level]
		button.disabled = true
	else:
		var purchase_cost = cost
		button.tooltip_text = "%s%s\nLevel: %d -> %d\nCost: %d Credits" % [label, details, level, level + 1, purchase_cost]
		button.disabled = false

func _on_signal_pressed() -> void:
	player_upgrades_visible = not player_upgrades_visible
	_layout_hud()
	_set_mining_hud_visibility(not _has_open_research_overlay())
	if signal_button:
		signal_button.text = ">" if player_upgrades_visible else "<"

func _set_player_upgrade_contents_visible(visible: bool) -> void:
	for label in [click_output_text, click_multiplier_text, command_capacity_text, flagship_speed_text, refining_text]:
		if label:
			label.visible = visible
	for label in player_level_texts + player_effect_texts:
		if label:
			label.visible = visible
	for separator in player_separators:
		if separator:
			separator.visible = visible
	for button in [click_output_button, click_multiplier_button, command_capacity_button, flagship_speed_button, refining_button]:
		if button:
			button.visible = visible
	if upgrade_panel:
		upgrade_panel.visible = visible

func _on_drone_signal_pressed() -> void:
	drone_upgrades_visible = not drone_upgrades_visible
	_layout_hud()
	_set_mining_hud_visibility(not _has_open_research_overlay())
	if drone_signal_button:
		drone_signal_button.text = ">" if drone_upgrades_visible else "<"

func _set_drone_upgrade_contents_visible(visible: bool) -> void:
	for label in [mining_text, mining_speed_text, capacity_text, speed_text]:
		if label:
			label.visible = visible
	for label in drone_level_texts + drone_effect_texts:
		if label:
			label.visible = visible
	for separator in drone_separators:
		if separator:
			separator.visible = visible
	for button in [mining_button, mining_speed_button, capacity_button, speed_button]:
		if button:
			button.visible = visible
	if drone_panel:
		drone_panel.visible = visible

func _on_refinery_signal_pressed() -> void:
	refinery_upgrades_visible = not refinery_upgrades_visible
	_layout_hud()
	_update_refinery_upgrade_hud()

func _set_refinery_upgrade_contents_visible(visible: bool) -> void:
	for label in refinery_upgrade_texts + refinery_level_texts + refinery_effect_texts:
		if label:
			label.visible = visible
	for separator in refinery_separators:
		if separator:
			separator.visible = visible
	for button in refinery_upgrade_buttons:
		if button:
			button.visible = visible
	if refinery_panel:
		refinery_panel.visible = visible

func _on_upgrade_refinery_stat(stat_key: String) -> void:
	if resource_manager and resource_manager.has_method("upgrade_refinery_stat") and resource_manager.upgrade_refinery_stat(stat_key):
		_show_action("Romius %s upgraded" % stat_key.replace("_", " "))
	else:
		_show_action("Not enough Credits or upgrade at cap")
	_update_refinery_upgrade_hud()

func _on_center_pressed():
	var flotillas = get_tree().get_nodes_in_group("flotilla")
	if flotillas.size() > 0 and map_view:
		map_view.center_on_node(flotillas[0])

func _on_new_field_pressed():
	if resource_manager and resource_manager.has_method("regenerate_asteroid_field"):
		resource_manager.regenerate_asteroid_field()
		if map_view:
			map_view.selected = null
			map_view._update_selection_label()
		_show_action("New asteroid field generated")

func _on_split_focus_pressed() -> void:
	if resource_manager and resource_manager.has_method("split_drones_across_asteroids"):
		var assigned = resource_manager.split_drones_across_asteroids()
		if assigned > 0:
			_show_action("Split focus across the field")
		else:
			_show_action("No drones or asteroids available")

func _on_lock_focus_pressed() -> void:
	if resource_manager == null or not resource_manager.has_method("lock_drone_focus"):
		return
	if resource_manager.get_active_drone_count() <= 0:
		_show_action("No active drones available")
		return
	var selected_target = map_view.selected if map_view else null
	if selected_target != null and not is_instance_valid(selected_target):
		selected_target = null
		map_view.selected = null
	var target = resource_manager.lock_drone_focus(selected_target)
	if target:
		if map_view:
			map_view.selected = target
			map_view._update_selection_label()
		_show_action("Focus locked on selected asteroid" if target == selected_target else "Focus locked on closest asteroid")
	else:
		_show_action("No asteroid available")

func _on_upgrade_speed():
	_buy_upgrade("upgrade_speed", "Speed upgraded")

func _on_upgrade_flagship_speed():
	_buy_upgrade("upgrade_flagship_speed", "Flagship speed upgraded")

func _on_upgrade_click_output():
	_buy_upgrade("upgrade_click_output", "Click output upgraded")

func _on_upgrade_click_multiplier():
	_buy_upgrade("upgrade_click_multiplier", "Input rate upgraded")

func _on_upgrade_mining():
	_buy_upgrade("upgrade_mining", "Mining power upgraded")

func _on_upgrade_mining_speed():
	_buy_upgrade("upgrade_mining_speed", "Mining speed upgraded")

func _on_upgrade_refining():
	_buy_upgrade("upgrade_refining", "Flagship refining upgraded")

func _on_upgrade_capacity():
	_buy_upgrade("upgrade_capacity", "Cargo capacity upgraded")

func _on_buy_drone():
	_buy_upgrade("buy_drone", "Mining drone purchased")

func _buy_upgrade(method_name: String, success_text: String) -> void:
	if resource_manager and resource_manager.has_method(method_name):
		if resource_manager.call(method_name):
			_show_action(success_text)
		else:
			_show_action("Not enough Credits")

func _on_pr_up():
	var sel = map_view.selected if map_view else null
	if sel != null and not is_instance_valid(sel):
		sel = null
		map_view.selected = null
	if sel != null and sel.is_in_group("asteroids"):
		if resource_manager and resource_manager.has_method("set_asteroid_priority"):
			resource_manager.set_asteroid_priority(sel, 1)
			_show_action("Increased priority")
	else:
		_show_action("Select an asteroid first")

func _on_pr_dn():
	var sel = map_view.selected if map_view else null
	if sel != null and not is_instance_valid(sel):
		sel = null
		map_view.selected = null
	if sel != null and sel.is_in_group("asteroids"):
		if resource_manager and resource_manager.has_method("set_asteroid_priority"):
			resource_manager.set_asteroid_priority(sel, -1)
			_show_action("Decreased priority")
	else:
		_show_action("Select an asteroid first")

func _on_save_pressed():
	if resource_manager and resource_manager.has_method("save_game"):
		resource_manager.save_game()
		_show_action("Saved")

func _on_load_pressed():
	if resource_manager and resource_manager.has_method("load_game"):
		resource_manager.load_game()
		_show_action("Loaded")

func _show_action(text: String) -> void:
	if last_action_label:
		last_action_label.text = text
	if action_timer:
		action_timer.start()

func _on_action_timer_timeout():
	if last_action_label:
		last_action_label.text = ""
