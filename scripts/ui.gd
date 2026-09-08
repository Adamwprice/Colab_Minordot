extends CanvasLayer

var resource_manager: Node = null
var resource_label: Label = null
var last_action_label: Label = null
var fleet_label: Label = null
var stage_label: Label = null
var right_ore_label: Label = null
var upgrade_label: Label = null
var speed_button: Button = null
var mining_button: Button = null
var drone_multiplier_button: Button = null
var capacity_button: Button = null
var drone_button: Button = null
var click_output_button: Button = null
var click_multiplier_button: Button = null
var signal_button: Button = null
var drone_signal_button: Button = null
var speed_text: Label = null
var mining_text: Label = null
var drone_multiplier_text: Label = null
var capacity_text: Label = null
var drone_text: Label = null
var click_output_text: Label = null
var click_multiplier_text: Label = null
var drone_upgrade_label: Label = null
var flagship_speed_text: Label = null
var flagship_speed_button: Button = null
var command_capacity_text: Label = null
var command_capacity_button: Button = null
var battle_button: Button = null
var controls_toggle_button: Button = null
var controls_label: Label = null
var technology_button: Button = null
var prestige_toggle_button: Button = null
var prestige_panel: Panel = null
var prestige_research_label: Label = null
var prestige_button: Button = null
var technology_column_headers: Array[Label] = []
var technology_column_items: Array[Label] = []
var technology_column_separators: Array[ColorRect] = []
var technology_passive_labels: Array[Label] = []
var technology_cap_level_labels: Array[Label] = []
var technology_passive_level_labels: Array[Label] = []
var technology_passive_buttons: Array[Button] = []
var technology_passive_refund_buttons: Array[Button] = []
var upgrade_panel: Panel = null
var drone_panel: Panel = null
var player_separators: Array[Control] = []
var drone_separators: Array[Control] = []
var player_level_texts: Array[Label] = []
var player_effect_texts: Array[Label] = []
var drone_level_texts: Array[Label] = []
var drone_effect_texts: Array[Label] = []
var prestige_separators: Array[Control] = []
var action_timer: Timer = null
var player_upgrades_visible: bool = true
var drone_upgrades_visible: bool = true
var control_buttons_visible: bool = true
var prestige_visible: bool = false

const PRESTIGE_PANEL_SIZE := Vector2(1140.0, 630.0)
const PRESTIGE_COLUMN_X := [24.0, 314.0, 604.0, 894.0]
const PRESTIGE_SEPARATOR_X := [292.0, 582.0, 872.0]
const RIGHT_UPGRADE_PANEL_WIDTH := 380.0
const RIGHT_UPGRADE_TOP_Y := 88.0
const RIGHT_UPGRADE_ROW_GAP := 30.0
const RIGHT_UPGRADE_LABEL_X := 42.0
const RIGHT_UPGRADE_LEVEL_X := 214.0
const RIGHT_UPGRADE_EFFECT_X := 262.0
const RIGHT_UPGRADE_HEADER_HEIGHT := 38.0
const RIGHT_UPGRADE_FLAGSHIP_HEIGHT := 158.0
const RIGHT_UPGRADE_DRONE_HEIGHT := 168.0
const RIGHT_UPGRADE_SECTION_GAP := 16.0
const CAP_RESEARCH_DESCRIPTIONS := [
	"Raises the maximum Click Amount level by 1.",
	"Raises the maximum Flagship Speed level by 1.",
	"Raises the maximum Command Capacity level by 1.",
	"Raises the maximum Drone Mining level by 1.",
	"Raises the maximum Drone Multiplier level by 1.",
	"Raises the maximum Drone Speed level by 1."
]
const PASSIVE_RESEARCH_DISPLAY := [
	{
		"label": "MINING LASERS",
		"name": "Mining lasers",
		"key": "drone_mining_lasers",
		"description": "Permanent boon: doubles drone mining amount."
	},
	{
		"label": "ION THRUSTERS",
		"name": "Ion thrusters",
		"key": "drone_ion_thrusts",
		"description": "Permanent boon: multiplies drone speed by 3."
	},
	{
		"label": "FLAGSHIP HULL",
		"name": "Flagship Hull",
		"key": "flagship_hull",
		"description": "Increases flagship permanent hull by 10."
	},
	{
		"label": "FLAGSHIP ARMOR",
		"name": "Flagship Armor",
		"key": "flagship_armor",
		"description": "Increases flagship permanent armor by 10."
	},
	{
		"label": "FLAGSHIP SHIELD",
		"name": "Flagship Shield",
		"key": "flagship_shield",
		"description": "Increases flagship permanent shield by 10."
	},		
]

func _ready():
	var cur_scene = get_tree().get_current_scene()
	resource_manager = cur_scene.get_node("ResourceManager") if cur_scene.has_node("ResourceManager") else null

	# Compact command overlay
	resource_label = Label.new()
	resource_label.name = "ResourceLabel"
	resource_label.text = "ORE  0"
	add_child(resource_label)
	resource_label.position = Vector2(18, 16)
	resource_label.add_theme_font_size_override("font_size", 22)
	resource_label.tooltip_text = "Exact ore: 0.00"

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
	stage_label.size = Vector2(260, 24)
	stage_label.add_theme_color_override("font_color", Color("f4d06f"))

	var help_label = Label.new()
	help_label.name = "HelpLabel"
	help_label.text = "Click to mine | Right-click to move flagship | Middle-drag to pan"
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

	battle_button = Button.new()
	battle_button.name = "BattleButton"
	battle_button.text = "Enter Battle"
	battle_button.position = Vector2(btn_x, btn_y + 184)
	battle_button.size = Vector2(280, 26)
	add_child(battle_button)
	battle_button.pressed.connect(Callable(self, "_on_battle_pressed"))

	var btn_new_field = Button.new()
	btn_new_field.name = "NewFieldButton"
	btn_new_field.text = "New Asteroid Field"
	btn_new_field.position = Vector2(btn_x, btn_y + 220)
	btn_new_field.size = Vector2(280, 26)
	add_child(btn_new_field)
	btn_new_field.pressed.connect(Callable(self, "_on_new_field_pressed"))

	var btn_send = Button.new()
	btn_send.name = "SendButton"
	btn_send.text = "Send Drones"
	btn_send.position = Vector2(btn_x, btn_y + 36)
	btn_send.size = Vector2(280, 26)
	add_child(btn_send)
	btn_send.pressed.connect(Callable(self, "_on_send_pressed"))

	var btn_send1 = Button.new()
	btn_send1.name = "Send1Button"
	btn_send1.text = "Send 1"
	btn_send1.position = Vector2(btn_x, btn_y + 72)
	btn_send1.size = Vector2(132, 26)
	add_child(btn_send1)
	btn_send1.pressed.connect(Callable(self, "_on_send1_pressed"))

	var btn_send3 = Button.new()
	btn_send3.name = "Send3Button"
	btn_send3.text = "Send 3"
	btn_send3.position = Vector2(btn_x + 148, btn_y + 72)
	btn_send3.size = Vector2(132, 26)
	add_child(btn_send3)
	btn_send3.pressed.connect(Callable(self, "_on_send3_pressed"))

	var btn_send5 = Button.new()
	btn_send5.name = "Send5Button"
	btn_send5.text = "Send 5"
	btn_send5.position = Vector2(btn_x, btn_y + 108)
	btn_send5.size = Vector2(132, 26)
	add_child(btn_send5)
	btn_send5.pressed.connect(Callable(self, "_on_send5_pressed"))

	var btn_send10 = Button.new()
	btn_send10.name = "Send10Button"
	btn_send10.text = "Send 10"
	btn_send10.position = Vector2(btn_x + 148, btn_y + 108)
	btn_send10.size = Vector2(132, 26)
	add_child(btn_send10)
	btn_send10.pressed.connect(Callable(self, "_on_send10_pressed"))

	var btn_split = Button.new()
	btn_split.name = "SplitButton"
	btn_split.text = "Split All Across Field"
	btn_split.position = Vector2(btn_x, btn_y + 146)
	btn_split.size = Vector2(280, 26)
	add_child(btn_split)
	btn_split.pressed.connect(Callable(self, "_on_split_all_pressed"))

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.08, 0.13, 0.92)
	panel_style.border_color = Color(0.25, 0.65, 0.75, 0.65)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4

	technology_button = Button.new()
	technology_button.name = "TechnologyButton"
	technology_button.text = "Technology"
	technology_button.position = Vector2(max(18.0, get_viewport().get_visible_rect().size.x * 0.5 - 120.0), 12.0)
	technology_button.size = Vector2(240, 32)
	technology_button.tooltip_text = "Toggle research and prestige panel"
	add_child(technology_button)
	technology_button.pressed.connect(Callable(self, "_on_prestige_toggle_pressed"))

	prestige_panel = Panel.new()
	prestige_panel.name = "PrestigePanel"
	prestige_panel.position = get_viewport().get_visible_rect().size * 0.5 - PRESTIGE_PANEL_SIZE * 0.5
	prestige_panel.size = PRESTIGE_PANEL_SIZE
	prestige_panel.visible = false
	prestige_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var prestige_style = StyleBoxFlat.new()
	prestige_style.bg_color = Color(0.05, 0.09, 0.14, 0.78)
	prestige_style.border_color = Color(0.22, 0.78, 0.96, 0.7)
	prestige_style.set_border_width_all(2)
	prestige_style.corner_radius_top_left = 12
	prestige_style.corner_radius_top_right = 12
	prestige_style.corner_radius_bottom_left = 12
	prestige_style.corner_radius_bottom_right = 12
	prestige_panel.add_theme_stylebox_override("panel", prestige_style)
	add_child(prestige_panel)

	prestige_toggle_button = Button.new()
	prestige_toggle_button.name = "PrestigeToggleButton"
	prestige_toggle_button.text = ""
	prestige_toggle_button.visible = false
	prestige_toggle_button.tooltip_text = "Collapse panel"
	prestige_toggle_button.position = Vector2(18, 18)
	prestige_toggle_button.size = Vector2(26, 26)
	prestige_panel.add_child(prestige_toggle_button)
	prestige_toggle_button.pressed.connect(Callable(self, "_on_prestige_toggle_pressed"))

	prestige_research_label = Label.new()
	prestige_research_label.name = "PrestigeResearchLabel"
	prestige_research_label.text = "RESEARCH 0"
	prestige_research_label.position = Vector2(58, 20)
	prestige_research_label.size = Vector2(220, 28)
	prestige_research_label.add_theme_font_size_override("font_size", 18)
	prestige_research_label.add_theme_color_override("font_color", Color("f4d06f"))
	prestige_panel.add_child(prestige_research_label)

	var column_titles = ["UPGRADE CAP", "PASSIVE EFFECTS", "UTILITY", "EXCLUSIVES"]
	for i in range(column_titles.size()):
		var header = Label.new()
		header.name = "TechnologyColumnHeader%d" % i
		header.text = column_titles[i]
		header.position = Vector2(PRESTIGE_COLUMN_X[i], 62.0)
		header.size = Vector2(240, 24)
		header.add_theme_font_size_override("font_size", 12)
		header.add_theme_color_override("font_color", Color("72d6e8"))
		prestige_panel.add_child(header)
		technology_column_headers.append(header)
	for separator_x in PRESTIGE_SEPARATOR_X:
		var separator = ColorRect.new()
		separator.name = "TechnologyColumnSeparator%d" % technology_column_separators.size()
		separator.position = Vector2(separator_x, 58.0)
		separator.size = Vector2(1.0, 520.0)
		separator.color = Color(0.35, 0.72, 0.82, 0.32)
		separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prestige_panel.add_child(separator)
		technology_column_separators.append(separator)

	var column_items = [
		["", "", ""],
		["", "", ""],
		["Locked", "Locked", "Locked"],
		["Locked", "Locked", "Locked"]
	]
	for column in range(column_items.size()):
		for row in range(column_items[column].size()):
			var item = Label.new()
			item.name = "TechnologyColumn%dItem%d" % [column, row]
			item.text = column_items[column][row] if column > 0 else ""
			item.position = Vector2(PRESTIGE_COLUMN_X[column], 98.0 + row * 50.0)
			item.size = Vector2(250, 30)
			item.add_theme_font_size_override("font_size", 12)
			item.add_theme_color_override("font_color", Color("8da8b8") if column > 0 else Color("d9f4ff"))
			prestige_panel.add_child(item)
			technology_column_items.append(item)
	for passive_data in PASSIVE_RESEARCH_DISPLAY:
		var passive_label = Label.new()
		passive_label.name = "%sTechnologyLabel" % passive_data["key"]
		passive_label.text = passive_data["name"]
		passive_label.position = Vector2(PRESTIGE_COLUMN_X[1], 98.0 + technology_passive_labels.size() * 50.0)
		passive_label.size = Vector2(140, 30)
		passive_label.add_theme_font_size_override("font_size", 11)
		passive_label.add_theme_color_override("font_color", Color("d9f4ff"))
		passive_label.mouse_filter = Control.MOUSE_FILTER_STOP
		passive_label.tooltip_text = passive_data["description"]
		prestige_panel.add_child(passive_label)
		technology_passive_labels.append(passive_label)
		var passive_level = Label.new()
		passive_level.name = "%sTechnologyLevelLabel" % passive_data["key"]
		passive_level.text = "OFF"
		passive_level.position = Vector2(PRESTIGE_COLUMN_X[1] + 148.0, 98.0 + technology_passive_level_labels.size() * 50.0)
		passive_level.size = Vector2(64, 30)
		passive_level.add_theme_font_size_override("font_size", 12)
		passive_level.add_theme_color_override("font_color", Color("f4d06f"))
		prestige_panel.add_child(passive_level)
		technology_passive_level_labels.append(passive_level)
		var passive_button = Button.new()
		passive_button.name = "%sTechnologyButton" % passive_data["key"]
		passive_button.text = "+"
		passive_button.position = Vector2(PRESTIGE_COLUMN_X[1] + 240.0, 98.0 + technology_passive_buttons.size() * 50.0)
		passive_button.size = Vector2(20, 28)
		prestige_panel.add_child(passive_button)
		technology_passive_buttons.append(passive_button)
		passive_button.pressed.connect(Callable(self, "_on_passive_upgrade_%s" % passive_data["key"]))
		var passive_refund = Button.new()
		passive_refund.name = "%sTechnologyRefundButton" % passive_data["key"]
		passive_refund.text = "-"
		passive_refund.position = Vector2(PRESTIGE_COLUMN_X[1] + 216.0, 98.0 + technology_passive_refund_buttons.size() * 50.0)
		passive_refund.size = Vector2(20, 28)
		passive_refund.tooltip_text = "Remove uncommitted allocation"
		prestige_panel.add_child(passive_refund)
		technology_passive_refund_buttons.append(passive_refund)
		passive_refund.pressed.connect(Callable(self, "_on_passive_refund_%s" % passive_data["key"]))

	var prestige_row_y = [98, 138, 178, 218, 258, 298]
	var prestige_names = ["ClickAmountCap", "FlagshipSpeedCap", "CommandCapacityCap", "DroneMiningCap", "DroneMultiplierCap", "DroneSpeedCap"]
	var prestige_keys = ["click_output", "flagship_speed", "drones", "mining", "drone_multiplier", "speed"]
	var prestige_display_names = ["Click amount", "Flagship speed", "Command capacity", "Drone mining", "Drone multiplier", "Drone speed"]
	for i in range(prestige_keys.size()):
		var row_label = Label.new()
		row_label.name = "%sResearchLabel" % prestige_names[i]
		row_label.position = Vector2(24, prestige_row_y[i])
		row_label.size = Vector2(120, 26)
		row_label.add_theme_font_size_override("font_size", 11)
		row_label.add_theme_color_override("font_color", Color("d9f4ff"))
		row_label.mouse_filter = Control.MOUSE_FILTER_STOP
		row_label.tooltip_text = CAP_RESEARCH_DESCRIPTIONS[i]
		row_label.text = prestige_display_names[i]
		prestige_panel.add_child(row_label)
		prestige_separators.append(row_label)
		var level_label = Label.new()
		level_label.name = "%sResearchLevelLabel" % prestige_names[i]
		level_label.position = Vector2(150, prestige_row_y[i])
		level_label.size = Vector2(28, 26)
		level_label.text = "L0"
		level_label.add_theme_font_size_override("font_size", 13)
		level_label.add_theme_color_override("font_color", Color("f4d06f"))
		prestige_panel.add_child(level_label)
		technology_cap_level_labels.append(level_label)
		var button = Button.new()
		button.name = "%sResearchButton" % prestige_names[i]
		button.text = "+"
		button.position = Vector2(234, prestige_row_y[i])
		button.size = Vector2(20, 28)
		prestige_panel.add_child(button)
		button.pressed.connect(Callable(self, "_on_research_upgrade_%s" % prestige_keys[i]))
		var refund_button = Button.new()
		refund_button.name = "%sResearchRefundButton" % prestige_names[i]
		refund_button.text = "-"
		refund_button.tooltip_text = "Remove uncommitted allocation"
		refund_button.position = Vector2(210, prestige_row_y[i])
		refund_button.size = Vector2(20, 28)
		prestige_panel.add_child(refund_button)
		refund_button.pressed.connect(Callable(self, "_on_research_refund_%s" % prestige_keys[i]))

	prestige_button = Button.new()
	prestige_button.name = "PrestigeButton"
	prestige_button.text = "Prestige"
	prestige_button.position = Vector2(20, 570)
	prestige_button.size = Vector2(1100, 34)
	prestige_button.visible = false
	prestige_panel.add_child(prestige_button)
	prestige_button.pressed.connect(Callable(self, "_on_prestige_pressed"))

	right_ore_label = Label.new()
	right_ore_label.name = "RightOreLabel"
	right_ore_label.text = "ORE  0"
	right_ore_label.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, 24)
	right_ore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_ore_label.add_theme_font_size_override("font_size", 18)
	right_ore_label.add_theme_color_override("font_color", Color("f4d06f"))
	add_child(right_ore_label)

	upgrade_panel = Panel.new()
	upgrade_panel.name = "UpgradePanel"
	upgrade_panel.position = Vector2(btn_x - 8, RIGHT_UPGRADE_TOP_Y)
	upgrade_panel.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, 158)
	upgrade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_panel.add_theme_stylebox_override("panel", panel_style)
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
	upgrade_label.add_theme_font_size_override("font_size", 14)
	upgrade_label.add_theme_color_override("font_color", Color("f4d06f"))

	click_output_text = _create_upgrade_row("ClickOutput", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0, "player")
	click_multiplier_text = _create_upgrade_row("ClickMultiplier", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP, "player")
	command_capacity_text = _create_upgrade_row("CommandCapacity", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, "player")
	flagship_speed_text = _create_upgrade_row("MoveSpeed", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, "player")

	drone_panel = Panel.new()
	drone_panel.name = "DroneUpgradePanel"
	drone_panel.position = Vector2(btn_x - 8, RIGHT_UPGRADE_TOP_Y + 174.0)
	drone_panel.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, 168)
	drone_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drone_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(drone_panel)

	drone_signal_button = Button.new()
	drone_signal_button.name = "DroneUpgradeSignalButton"
	drone_signal_button.text = ">"
	drone_signal_button.tooltip_text = "Toggle drone upgrades"
	drone_signal_button.position = Vector2(btn_x, RIGHT_UPGRADE_TOP_Y + 182.0)
	drone_signal_button.size = Vector2(28, 28)
	add_child(drone_signal_button)
	drone_signal_button.pressed.connect(Callable(self, "_on_drone_signal_pressed"))

	drone_upgrade_label = Label.new()
	drone_upgrade_label.name = "DroneUpgradeLabel"
	drone_upgrade_label.text = "DRONE UPGRADES"
	drone_upgrade_label.position = Vector2(btn_x + RIGHT_UPGRADE_LABEL_X, RIGHT_UPGRADE_TOP_Y + 182.0)
	drone_upgrade_label.size = Vector2(244, 24)
	drone_upgrade_label.add_theme_font_size_override("font_size", 14)
	drone_upgrade_label.add_theme_color_override("font_color", Color("f4d06f"))
	add_child(drone_upgrade_label)

	mining_text = _create_upgrade_row("MiningAmount", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0, "drone")
	drone_multiplier_text = _create_upgrade_row("Multiplier", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP, "drone")
	capacity_text = _create_upgrade_row("Capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, "drone")
	speed_text = _create_upgrade_row("MoveSpeed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, "drone")

	click_output_button = _create_upgrade_button("Upgrade click output", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0, Callable(self, "_on_upgrade_click_output"))
	click_multiplier_button = _create_upgrade_button("Upgrade click multiplier", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP, Callable(self, "_on_upgrade_click_multiplier"))

	mining_button = _create_upgrade_button("Upgrade drone mining amount", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0, Callable(self, "_on_upgrade_mining"))
	drone_multiplier_button = _create_upgrade_button("Upgrade drone multiplier", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP, Callable(self, "_on_upgrade_drone_multiplier"))
	capacity_button = _create_upgrade_button("Upgrade drone cargo capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, Callable(self, "_on_upgrade_capacity"))
	speed_button = _create_upgrade_button("Upgrade drone move speed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, Callable(self, "_on_upgrade_speed"))

	flagship_speed_button = _create_upgrade_button("Upgrade flagship speed", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, Callable(self, "_on_upgrade_flagship_speed"))
	command_capacity_button = _create_upgrade_button("Upgrade command capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, Callable(self, "_on_buy_drone"))

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
	_set_prestige_visibility(false)
	_layout_hud()

func _layout_hud() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var aspect_ratio = viewport_size.x / max(viewport_size.y, 1.0)
	var panel_width = min(RIGHT_UPGRADE_PANEL_WIDTH, max(260.0, viewport_size.x - 20.0))
	var panel_x = max(8.0, viewport_size.x - panel_width - 12.0)
	var content_width = panel_width - RIGHT_UPGRADE_LABEL_X - 8.0
	var upgrade_font_size = 14 if aspect_ratio >= 1.4 else 12
	var help_y = viewport_size.y - 48.0
	var ore_y = RIGHT_UPGRADE_TOP_Y - 32.0
	var flagship_y = RIGHT_UPGRADE_TOP_Y
	var flagship_height = RIGHT_UPGRADE_FLAGSHIP_HEIGHT if player_upgrades_visible else RIGHT_UPGRADE_HEADER_HEIGHT
	var drone_y = flagship_y + flagship_height + RIGHT_UPGRADE_SECTION_GAP
	var control_x = 18.0
	var control_y = max(142.0, help_y - 286.0)
	var control_width = min(280.0, max(220.0, viewport_size.x - 36.0))
	var control_half_width = (control_width - 8.0) * 0.5
	if controls_toggle_button:
		controls_toggle_button.position = Vector2(control_x, control_y)
		controls_toggle_button.size = Vector2(28.0, 28.0)
		controls_toggle_button.text = ">" if control_buttons_visible else "<"
	if controls_label:
		controls_label.position = Vector2(control_x + 36.0, control_y + 2.0)
		controls_label.size = Vector2(180.0, 24.0)
	var controls = {
		"CenterButton": [control_x, control_y + 36.0, control_width, 26.0],
		"SendButton": [control_x, control_y + 72.0, control_width, 26.0],
		"Send1Button": [control_x, control_y + 108.0, control_half_width, 26.0],
		"Send3Button": [control_x + control_half_width + 8.0, control_y + 108.0, control_half_width, 26.0],
		"Send5Button": [control_x, control_y + 144.0, control_half_width, 26.0],
		"Send10Button": [control_x + control_half_width + 8.0, control_y + 144.0, control_half_width, 26.0],
		"SplitButton": [control_x, control_y + 180.0, control_width, 26.0],
		"BattleButton": [control_x, control_y + 216.0, control_width, 26.0],
		"NewFieldButton": [control_x, control_y + 252.0, control_width, 26.0]
	}
	for control_name in controls:
		var control = get_node_or_null(control_name) as Control
		if control:
			var rect = controls[control_name]
			control.position = Vector2(rect[0], rect[1])
			control.size = Vector2(rect[2], rect[3])
	if right_ore_label:
		right_ore_label.position = Vector2(panel_x - 8.0, ore_y)
		right_ore_label.size = Vector2(panel_width, 24.0)
	if upgrade_panel:
		upgrade_panel.position = Vector2(panel_x - 8.0, flagship_y)
		upgrade_panel.size = Vector2(panel_width, RIGHT_UPGRADE_FLAGSHIP_HEIGHT)
	if drone_panel:
		drone_panel.position = Vector2(panel_x - 8.0, drone_y)
		drone_panel.size = Vector2(panel_width, RIGHT_UPGRADE_DRONE_HEIGHT)
	if technology_button:
		technology_button.position = Vector2(max(18.0, viewport_size.x * 0.5 - 120.0), 12.0)
		technology_button.size = Vector2(240.0, 32.0)
	if prestige_panel:
		prestige_panel.position = viewport_size * 0.5 - PRESTIGE_PANEL_SIZE * 0.5
		prestige_panel.size = PRESTIGE_PANEL_SIZE
	if prestige_toggle_button:
		prestige_toggle_button.position = Vector2(18.0, 18.0)
	if prestige_research_label:
		prestige_research_label.position = Vector2(58.0, 20.0)
	if prestige_button:
		prestige_button.position = Vector2(20.0, 570.0)
		prestige_button.size = Vector2(1100.0, 34.0)
	for index in range(technology_column_headers.size()):
		technology_column_headers[index].position = Vector2(PRESTIGE_COLUMN_X[index], 62.0)
		technology_column_headers[index].size = Vector2(240.0, 24.0)
	for index in range(technology_column_separators.size()):
		technology_column_separators[index].position = Vector2(PRESTIGE_SEPARATOR_X[index], 58.0)
		technology_column_separators[index].size = Vector2(1.0, 520.0)
	for index in range(technology_column_items.size()):
		var column = int(index / 3)
		var row = index % 3
		technology_column_items[index].position = Vector2(PRESTIGE_COLUMN_X[column], 98.0 + row * 50.0)
		technology_column_items[index].size = Vector2(250.0, 30.0)
	var cap_row_y = [98.0, 138.0, 178.0, 218.0, 258.0, 298.0]
	var cap_row_names = ["ClickAmountCap", "FlagshipSpeedCap", "CommandCapacityCap", "DroneMiningCap", "DroneMultiplierCap", "DroneSpeedCap"]
	for i in range(cap_row_names.size()):
		var node_name = "%sResearchLabel" % cap_row_names[i]
		var row_node = prestige_panel.get_node_or_null(node_name) if prestige_panel else null
		if row_node:
			row_node.position = Vector2(24.0, cap_row_y[i])
			row_node.size = Vector2(120.0, 26.0)
		var level_node = prestige_panel.get_node_or_null("%sResearchLevelLabel" % cap_row_names[i]) if prestige_panel else null
		if level_node:
			level_node.position = Vector2(150.0, cap_row_y[i])
		var button_name = "%sResearchButton" % cap_row_names[i]
		var button_node = prestige_panel.get_node_or_null(button_name) if prestige_panel else null
		if button_node:
			button_node.position = Vector2(234.0, cap_row_y[i])
		var refund_node = prestige_panel.get_node_or_null("%sResearchRefundButton" % cap_row_names[i]) if prestige_panel else null
		if refund_node:
			refund_node.position = Vector2(210.0, cap_row_y[i])
	for index in range(technology_passive_labels.size()):
		var passive_y = 98.0 + index * 50.0
		technology_passive_labels[index].position = Vector2(PRESTIGE_COLUMN_X[1], passive_y)
		technology_passive_labels[index].size = Vector2(140.0, 30.0)
		technology_passive_level_labels[index].position = Vector2(PRESTIGE_COLUMN_X[1] + 148.0, passive_y)
		technology_passive_level_labels[index].size = Vector2(64.0, 30.0)
		technology_passive_refund_buttons[index].position = Vector2(PRESTIGE_COLUMN_X[1] + 216.0, passive_y)
		technology_passive_buttons[index].position = Vector2(PRESTIGE_COLUMN_X[1] + 240.0, passive_y)
	var heading_controls = {
		"UpgradeSignalButton": [panel_x, flagship_y + 8.0, 28.0, 28.0],
		"UpgradeLabel": [panel_x + RIGHT_UPGRADE_LABEL_X, flagship_y + 8.0, content_width, 24.0],
		"DroneUpgradeSignalButton": [panel_x, drone_y + 8.0, 28.0, 28.0],
		"DroneUpgradeLabel": [panel_x + RIGHT_UPGRADE_LABEL_X, drone_y + 8.0, content_width, 24.0]
	}
	for control_name in heading_controls:
		var control = get_node_or_null(control_name) as Control
		if control:
			var rect = heading_controls[control_name]
			control.position = Vector2(rect[0], rect[1])
			control.size = Vector2(rect[2], rect[3])
			if control is Label:
				control.add_theme_font_size_override("font_size", upgrade_font_size)
	var upgrade_controls = [
		[click_output_button, click_output_text, flagship_y + 38.0],
		[click_multiplier_button, click_multiplier_text, flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP],
		[command_capacity_button, command_capacity_text, flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0],
		[flagship_speed_button, flagship_speed_text, flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0],
		[mining_button, mining_text, drone_y + 38.0],
		[drone_multiplier_button, drone_multiplier_text, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP],
		[capacity_button, capacity_text, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0],
		[speed_button, speed_text, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0]
	]
	for row in upgrade_controls:
		var button = row[0] as Control
		var label = row[1] as Label
		var row_y = row[2]
		button.position = Vector2(panel_x, row_y)
		button.size = Vector2(30.0, 26.0)
		label.position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_y)
		label.size = Vector2(RIGHT_UPGRADE_LEVEL_X - RIGHT_UPGRADE_LABEL_X - 6.0, 24.0)
		label.add_theme_font_size_override("font_size", upgrade_font_size)
	var row_positions = [
		flagship_y + 38.0,
		flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP,
		flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0,
		flagship_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0
	]
	for index in range(player_separators.size()):
		player_separators[index].position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_positions[index] + 25.0)
		player_separators[index].size = Vector2(max(1.0, content_width - 8.0), 1.0)
	for index in range(player_level_texts.size()):
		player_level_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_LEVEL_X, row_positions[index])
		player_level_texts[index].size = Vector2(44.0, 24.0)
		player_effect_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_EFFECT_X, row_positions[index])
		player_effect_texts[index].size = Vector2(max(72.0, panel_width - RIGHT_UPGRADE_EFFECT_X - 8.0), 24.0)
	row_positions = [
		drone_y + 38.0,
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP,
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0,
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0
	]
	for index in range(drone_separators.size()):
		drone_separators[index].position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_positions[index] + 25.0)
		drone_separators[index].size = Vector2(max(1.0, content_width - 8.0), 1.0)
	for index in range(drone_level_texts.size()):
		drone_level_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_LEVEL_X, row_positions[index])
		drone_level_texts[index].size = Vector2(44.0, 24.0)
		drone_effect_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_EFFECT_X, row_positions[index])
		drone_effect_texts[index].size = Vector2(max(72.0, panel_width - RIGHT_UPGRADE_EFFECT_X - 8.0), 24.0)
	if resource_label:
		resource_label.position = Vector2(18.0, 16.0)
	if fleet_label:
		fleet_label.position = Vector2(18.0, 76.0)
	if stage_label:
		stage_label.position = Vector2(18.0, 100.0)
		stage_label.size = Vector2(320.0, 24.0)
	if last_action_label:
		last_action_label.position = Vector2(18.0, 128.0)
	var help_label = get_node_or_null("HelpLabel") as Control
	if help_label:
		help_label.position = Vector2(18.0, help_y)
		help_label.size = Vector2(max(180.0, viewport_size.x - 36.0), 24.0)

func _on_resource_changed(amount):
	if resource_label:
		resource_label.text = "ORE  %06d" % int(round(float(amount)))
		resource_label.tooltip_text = "Exact ore: %.2f" % float(amount)
	if right_ore_label:
		right_ore_label.text = "ORE  %06d" % int(round(float(amount)))
		right_ore_label.tooltip_text = "Exact ore: %.2f" % float(amount)

func _process(_delta):
	if fleet_label == null:
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
		if resource_manager.next_stage_timer >= 0.0:
			stage_label.text = "PRESTIGE %d | NEXT FIELD IN %02d" % [stage_prestige_level, int(ceil(resource_manager.next_stage_timer))]
		else:
			stage_label.text = "PRESTIGE %d | FIELD %d" % [stage_prestige_level, int(resource_manager.asteroid_field_level + 1)]
	if battle_button:
		if resource_manager and resource_manager.can_enter_battle():
			battle_button.disabled = false
			battle_button.text = "Enter Battle"
		else:
			battle_button.disabled = true
			battle_button.text = "Battle Lv 10+"
	if upgrade_label and resource_manager:
		var speed_level = int(resource_manager.speed_level)
		var mining_level = int(resource_manager.mining_level)
		var capacity_level = int(resource_manager.capacity_level)
		var drone_level = int(resource_manager.drone_level)
		var active_drone_count = int(resource_manager.get_active_drone_count())
		var flagship_speed_level = int(resource_manager.flagship_speed_level)
		var click_gain = float(resource_manager.get_click_output()) * resource_manager.get_click_multiplier()
		if right_ore_label:
			right_ore_label.text = "ORE  %06d" % int(resource_manager.total_resources)
			right_ore_label.tooltip_text = "Exact ore: %.2f" % float(resource_manager.total_resources)
		upgrade_label.text = "FLAGSHIP UPGRADES    %.1f / PER CLICK" % click_gain
		click_output_text.text = "CLICK OUTPUT"
		click_multiplier_text.text = "CLICK MULTIPLIER"
		mining_text.text = "MINING AMOUNT"
		drone_multiplier_text.text = "MULTIPLIER"
		capacity_text.text = "CAPACITY"
		speed_text.text = "MOVE SPEED"
		command_capacity_text.text = "COMMAND CAPACITY"
		flagship_speed_text.text = "MOVE SPEED"
		_update_table_values(player_level_texts, player_effect_texts, [int(resource_manager.click_output_level), int(resource_manager.click_multiplier_level), drone_level, flagship_speed_level], ["%d /per click" % int(resource_manager.get_click_output()), "%.2fx" % resource_manager.get_click_multiplier(), "%d/%d active" % [active_drone_count, int(resource_manager.get_drone_cap())], "%d speed" % int(resource_manager.get_flagship_speed())])
		_update_table_values(drone_level_texts, drone_effect_texts, [mining_level, int(resource_manager.drone_multiplier_level), capacity_level, speed_level], ["%d /per sec" % int(resource_manager.get_mining_amount()), "%.1fx gain" % resource_manager.get_drone_multiplier(), "%d capacity" % int(resource_manager.get_capacity()), "%d speed" % int(resource_manager.get_speed())])
		_update_upgrade_button(click_output_button, "Upgrade click output", int(resource_manager.click_output_level), resource_manager.get_ore_upgrade_cost("click_output"), resource_manager.get_ore_upgrade_cap("click_output"))
		_update_upgrade_button(click_multiplier_button, "Upgrade click multiplier", int(resource_manager.click_multiplier_level), resource_manager.get_ore_upgrade_cost("click_multiplier"), resource_manager.get_ore_upgrade_cap("click_multiplier"))
		_update_upgrade_button(speed_button, "Upgrade drone move speed", speed_level, resource_manager.get_ore_upgrade_cost("speed"), resource_manager.get_ore_upgrade_cap("speed"))
		_update_upgrade_button(mining_button, "Upgrade mining power", mining_level, resource_manager.get_ore_upgrade_cost("mining"), resource_manager.get_ore_upgrade_cap("mining"))
		_update_upgrade_button(drone_multiplier_button, "Upgrade drone multiplier", int(resource_manager.drone_multiplier_level), resource_manager.get_ore_upgrade_cost("drone_multiplier"), resource_manager.get_ore_upgrade_cap("drone_multiplier"))
		_update_upgrade_button(capacity_button, "Upgrade cargo capacity", capacity_level, resource_manager.get_ore_upgrade_cost("capacity"), resource_manager.get_ore_upgrade_cap("capacity"))
		_update_upgrade_button(drone_button, "Buy active drone", drone_level, resource_manager.get_drone_purchase_cost(), resource_manager.get_ore_upgrade_cap("drones"))
		_update_upgrade_button(flagship_speed_button, "Upgrade flagship speed", flagship_speed_level, resource_manager.get_ore_upgrade_cost("flagship_speed"), resource_manager.get_ore_upgrade_cap("flagship_speed"))
		if active_drone_count < drone_level:
			_update_upgrade_button(command_capacity_button, "Replace lost drone", active_drone_count, resource_manager.get_drone_purchase_cost(), drone_level)
		else:
			_update_upgrade_button(command_capacity_button, "Upgrade command capacity", drone_level, resource_manager.get_drone_purchase_cost(), resource_manager.get_ore_upgrade_cap("drones"))
		var drone_trip_gain = float(resource_manager.get_capacity()) * resource_manager.get_drone_multiplier()
		drone_upgrade_label.text = "DRONE UPGRADES    %.1f / PER TRIP" % drone_trip_gain
	if prestige_research_label and resource_manager:
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			prestige_research_label.text = "RESEARCH %d" % int(game_state.research_points)
		var cap_keys = ["click_output", "flagship_speed", "drones", "mining", "drone_multiplier", "speed"]
		var cap_names = ["ClickAmountCap", "FlagshipSpeedCap", "CommandCapacityCap", "DroneMiningCap", "DroneMultiplierCap", "DroneSpeedCap"]
		var cap_display_names = ["Click amount", "Flagship speed", "Command capacity", "Drone mining", "Drone multiplier", "Drone speed"]
		for idx in range(cap_keys.size()):
			var row_label = prestige_panel.get_node_or_null("%sResearchLabel" % cap_names[idx])
			if row_label:
				var key = cap_keys[idx]
				var game_state2 = get_node_or_null("/root/GameState")
				var level = 0
				if game_state2:
					level = int(game_state2.pending_cap_levels.get(key, game_state2.cap_levels.get(key, 0)))
					var cap_button = prestige_panel.get_node_or_null("%sResearchButton" % cap_names[idx])
					if cap_button:
						var cap_description = CAP_RESEARCH_DESCRIPTIONS[idx]
						cap_button.tooltip_text = "%s\nCost: %d research" % [cap_description, int(game_state2.get_research_cost(key))]
						row_label.tooltip_text = cap_button.tooltip_text
					var cap_refund = prestige_panel.get_node_or_null("%sResearchRefundButton" % cap_names[idx])
					if cap_refund:
						cap_refund.tooltip_text = "Remove one uncommitted cap allocation."
				row_label.text = cap_display_names[idx]
				if idx < technology_cap_level_labels.size():
					technology_cap_level_labels[idx].text = "L%d" % level
		for idx in range(technology_passive_labels.size()):
			var passive_data = PASSIVE_RESEARCH_DISPLAY[idx]
			var passive_key = passive_data["key"]
			var passive_state = get_node_or_null("/root/GameState")
			if passive_state:
				var committed_level = int(passive_state.get_passive_level(passive_key))
				var pending_level = int(passive_state.get_pending_passive_level(passive_key))
				var passive_status = "OWNED" if committed_level > 0 else ("PENDING" if pending_level > 0 else "OFF")
				var passive_description = passive_data["description"]
				technology_passive_labels[idx].text = passive_data["label"]
				technology_passive_level_labels[idx].text = passive_status
				technology_passive_buttons[idx].disabled = pending_level > 0
				technology_passive_buttons[idx].tooltip_text = "%s\nCost: %d research" % [passive_description, int(passive_state.get_passive_cost(passive_key))]
				technology_passive_labels[idx].tooltip_text = technology_passive_buttons[idx].tooltip_text
				technology_passive_refund_buttons[idx].disabled = pending_level <= committed_level
				technology_passive_refund_buttons[idx].tooltip_text = "Remove uncommitted passive allocation."

func _on_battle_pressed() -> void:
	if resource_manager and resource_manager.has_method("start_battle"):
		resource_manager.start_battle()
	else:
		_show_action("Battle unavailable")

func _set_prestige_visibility(visible: bool) -> void:
	prestige_visible = visible
	if prestige_panel:
		prestige_panel.visible = visible
	_set_mining_hud_visibility(not visible)
	if prestige_toggle_button:
		prestige_toggle_button.visible = false
	if prestige_research_label:
		prestige_research_label.visible = visible
	if prestige_button:
		prestige_button.visible = visible
	for node_name in ["ClickAmountCapResearchLabel", "FlagshipSpeedCapResearchLabel", "CommandCapacityCapResearchLabel", "DroneMiningCapResearchLabel", "DroneMultiplierCapResearchLabel", "DroneSpeedCapResearchLabel", "ClickAmountCapResearchButton", "FlagshipSpeedCapResearchButton", "CommandCapacityCapResearchButton", "DroneMiningCapResearchButton", "DroneMultiplierCapResearchButton", "DroneSpeedCapResearchButton", "ClickAmountCapResearchRefundButton", "FlagshipSpeedCapResearchRefundButton", "CommandCapacityCapResearchRefundButton", "DroneMiningCapResearchRefundButton", "DroneMultiplierCapResearchRefundButton", "DroneSpeedCapResearchRefundButton"]:
		var node = prestige_panel.get_node_or_null(node_name) if prestige_panel else null
		if node:
			node.visible = visible

func _on_prestige_toggle_pressed() -> void:
	_set_prestige_visibility(not prestige_visible)

func _set_mining_hud_visibility(visible: bool) -> void:
	if right_ore_label:
		right_ore_label.visible = visible
	if controls_toggle_button:
		controls_toggle_button.visible = visible
	if controls_label:
		controls_label.visible = visible and control_buttons_visible
	_set_control_buttons_visibility(visible and control_buttons_visible)
	if signal_button:
		signal_button.visible = visible
	if upgrade_label:
		upgrade_label.visible = visible
	_set_player_upgrade_contents_visible(visible and player_upgrades_visible)
	if drone_signal_button:
		drone_signal_button.visible = visible
	if drone_upgrade_label:
		drone_upgrade_label.visible = visible
	_set_drone_upgrade_contents_visible(visible and drone_upgrades_visible)

func _set_control_buttons_visibility(visible: bool) -> void:
	for node_name in ["CenterButton", "SendButton", "Send1Button", "Send3Button", "Send5Button", "Send10Button", "SplitButton", "BattleButton", "NewFieldButton"]:
		var node = get_node_or_null(node_name) as Control
		if node:
			node.visible = visible

func _on_controls_signal_pressed() -> void:
	control_buttons_visible = not control_buttons_visible
	_set_control_buttons_visibility(control_buttons_visible and not prestige_visible)
	if controls_label:
		controls_label.visible = control_buttons_visible and not prestige_visible
	if controls_toggle_button:
		controls_toggle_button.text = ">" if control_buttons_visible else "<"

func _on_prestige_pressed() -> void:
	if resource_manager and resource_manager.has_method("reset_run_for_prestige"):
		resource_manager.reset_run_for_prestige()
		_show_action("Run reset: ore upgrades cleared")
		_set_prestige_visibility(false)
		if technology_button:
			technology_button.text = "Technology"

func _upgrade_research(key: String) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if game_state.buy_cap_upgrade(key):
		_show_action("Research cap +1 for %s" % key)
	else:
		_show_action("Not enough research")

func _on_research_upgrade_click_output() -> void:
	_upgrade_research("click_output")

func _on_research_upgrade_speed() -> void:
	_upgrade_research("speed")

func _on_research_upgrade_drones() -> void:
	_upgrade_research("drones")

func _on_research_upgrade_mining() -> void:
	_upgrade_research("mining")

func _on_research_upgrade_flagship_speed() -> void:
	_upgrade_research("flagship_speed")

func _on_research_upgrade_drone_multiplier() -> void:
	_upgrade_research("drone_multiplier")

func _on_research_refund_click_output() -> void:
	_refund_research("click_output")

func _on_research_refund_speed() -> void:
	_refund_research("speed")

func _on_research_refund_drones() -> void:
	_refund_research("drones")

func _on_research_refund_mining() -> void:
	_refund_research("mining")

func _on_research_refund_flagship_speed() -> void:
	_refund_research("flagship_speed")

func _on_research_refund_drone_multiplier() -> void:
	_refund_research("drone_multiplier")

func _on_passive_upgrade_drone_mining_lasers() -> void:
	_upgrade_passive("drone_mining_lasers")

func _on_passive_upgrade_drone_ion_thrusts() -> void:
	_upgrade_passive("drone_ion_thrusts")

func _on_passive_upgrade_drone_flagship_hull() -> void:
	_upgrade_passive("flagship_hull")
	
func _on_passive_upgrade_drone_flagship_armor() -> void:
	_upgrade_passive("flagship_armor")	
	
func _on_passive_upgrade_drone_flagship_shield() -> void:
	_upgrade_passive("flagship_shield")

func _on_passive_refund_drone_mining_lasers() -> void:
	_refund_passive("drone_mining_lasers")

func _on_passive_refund_drone_ion_thrusts() -> void:
	_refund_passive("drone_ion_thrusts")
	
func _on_passive_refund_flagship_hull() -> void:
	_refund_passive("flagship_hull")

func _on_passive_refund_flagship_armor() -> void:
	_refund_passive("flagship_armor")
	
func _on_passive_refund_flagship_shield() -> void:
	_refund_passive("flagship_shield")

func _upgrade_passive(key: String) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.buy_passive_upgrade(key):
		_show_action("Passive allocation added")
	else:
		_show_action("Not enough research or already owned")

func _refund_passive(key: String) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.refund_passive_upgrade(key):
		_show_action("Passive allocation removed")
	else:
		_show_action("No pending allocation")

func _refund_research(key: String) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.refund_cap_upgrade(key):
		_show_action("Research allocation removed")
	else:
		_show_action("No pending allocation")

func _create_upgrade_button(description: String, x: float, y: float, callback: Callable) -> Button:
	var button = Button.new()
	button.text = "+"
	button.tooltip_text = description
	button.position = Vector2(x, y)
	button.size = Vector2(28, 24)
	add_child(button)
	button.pressed.connect(callback)
	return button

func _create_upgrade_row(row_name: String, x: float, y: float, section: String) -> Label:
	var row_label = Label.new()
	row_label.name = "%sUpgradeLabel" % row_name
	row_label.position = Vector2(x + RIGHT_UPGRADE_LABEL_X, y)
	row_label.size = Vector2(RIGHT_UPGRADE_LEVEL_X - RIGHT_UPGRADE_LABEL_X - 6.0, 24)
	row_label.add_theme_font_size_override("font_size", 12)
	row_label.add_theme_color_override("font_color", Color("f4d06f"))
	add_child(row_label)
	var level_label = Label.new()
	level_label.name = "%sLevelText" % row_name
	level_label.position = Vector2(x + RIGHT_UPGRADE_LEVEL_X, y)
	level_label.size = Vector2(44, 24)
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color("f4d06f"))
	add_child(level_label)
	var effect_label = Label.new()
	effect_label.name = "%sEffectText" % row_name
	effect_label.position = Vector2(x + RIGHT_UPGRADE_EFFECT_X, y)
	effect_label.size = Vector2(106, 24)
	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", Color("d9f4ff"))
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
	else:
		drone_separators.append(separator)
		drone_level_texts.append(level_label)
		drone_effect_texts.append(effect_label)
	return row_label

func _update_table_values(level_labels: Array[Label], effect_labels: Array[Label], levels: Array, effects: Array) -> void:
	for index in range(level_labels.size()):
		level_labels[index].text = "L%d" % int(levels[index])
		effect_labels[index].text = str(effects[index])

func _update_upgrade_button(button: Button, label: String, level: int, cost: int = -1, max_level: int = 10) -> void:
	if button == null:
		return
	button.text = "+"
	if level >= max_level:
		button.tooltip_text = "%s\nLevel: %d\nMAX UPGRADE" % [label, max_level]
		button.disabled = true
	else:
		var purchase_cost = cost
		button.tooltip_text = "%s\nLevel: %d -> %d\nCost: %d ore" % [label, level, level + 1, purchase_cost]
		button.disabled = false

func _on_signal_pressed() -> void:
	player_upgrades_visible = not player_upgrades_visible
	_layout_hud()
	_set_mining_hud_visibility(not prestige_visible)
	if signal_button:
		signal_button.text = ">" if player_upgrades_visible else "<"

func _set_player_upgrade_contents_visible(visible: bool) -> void:
	for label in [click_output_text, click_multiplier_text, command_capacity_text, flagship_speed_text]:
		if label:
			label.visible = visible
	for label in player_level_texts + player_effect_texts:
		if label:
			label.visible = visible
	for separator in player_separators:
		if separator:
			separator.visible = visible
	for button in [click_output_button, click_multiplier_button, command_capacity_button, flagship_speed_button]:
		if button:
			button.visible = visible
	if upgrade_panel:
		upgrade_panel.visible = visible

func _on_drone_signal_pressed() -> void:
	drone_upgrades_visible = not drone_upgrades_visible
	_layout_hud()
	_set_mining_hud_visibility(not prestige_visible)
	if drone_signal_button:
		drone_signal_button.text = ">" if drone_upgrades_visible else "<"

func _set_drone_upgrade_contents_visible(visible: bool) -> void:
	for label in [mining_text, drone_multiplier_text, capacity_text, speed_text]:
		if label:
			label.visible = visible
	for label in drone_level_texts + drone_effect_texts:
		if label:
			label.visible = visible
	for separator in drone_separators:
		if separator:
			separator.visible = visible
	for button in [mining_button, drone_multiplier_button, capacity_button, speed_button]:
		if button:
			button.visible = visible
	if drone_panel:
		drone_panel.visible = visible

func _on_center_pressed():
	var map = get_node("Map") if has_node("Map") else null
	var flotillas = get_tree().get_nodes_in_group("flotilla")
	if flotillas.size() > 0 and map:
		map.center_on_node(flotillas[0])

func _on_new_field_pressed():
	if resource_manager and resource_manager.has_method("regenerate_asteroid_field"):
		resource_manager.regenerate_asteroid_field()
		var map = get_node("Map") if has_node("Map") else null
		if map:
			map.selected = null
			map._update_selection_label()
		_show_action("New asteroid field generated")

func _on_send5_pressed():
	_send_selected_drones(5)

func _on_send10_pressed():
	_send_selected_drones(10)

func _send_selected_drones(count: int) -> void:
	var map = get_node("Map") if has_node("Map") else null
	var sel = map.selected if map else null
	if sel and sel.is_in_group("asteroids"):
		if resource_manager and resource_manager.has_method("send_n_drones_to"):
			resource_manager.send_n_drones_to(sel, count)
			_show_action("Sent %d drones" % count)
	else:
		_show_action("Select an asteroid first")

func _on_split_all_pressed():
	if resource_manager and resource_manager.has_method("split_drones_across_asteroids"):
		var assigned = resource_manager.split_drones_across_asteroids()
		if assigned > 0:
			_show_action("Split %d drones across the field" % assigned)
		else:
			_show_action("No drones or asteroids available")

func _on_upgrade_speed():
	_buy_upgrade("upgrade_speed", "Speed upgraded")

func _on_upgrade_flagship_speed():
	_buy_upgrade("upgrade_flagship_speed", "Flagship speed upgraded")

func _on_upgrade_click_output():
	_buy_upgrade("upgrade_click_output", "Click output upgraded")

func _on_upgrade_click_multiplier():
	_buy_upgrade("upgrade_click_multiplier", "Click multiplier upgraded")

func _on_upgrade_mining():
	_buy_upgrade("upgrade_mining", "Mining power upgraded")

func _on_upgrade_drone_multiplier():
	_buy_upgrade("upgrade_drone_multiplier", "Drone multiplier upgraded")

func _on_upgrade_capacity():
	_buy_upgrade("upgrade_capacity", "Cargo capacity upgraded")

func _on_buy_drone():
	_buy_upgrade("buy_drone", "Mining drone purchased")

func _buy_upgrade(method_name: String, success_text: String) -> void:
	if resource_manager and resource_manager.has_method(method_name):
		if resource_manager.call(method_name):
			_show_action(success_text)
		else:
			_show_action("Not enough ore")

func _on_send_pressed():
	var map = get_node("Map") if has_node("Map") else null
	var sel = map.selected if map else null
	if sel and sel.is_in_group("asteroids"):
		if resource_manager and resource_manager.has_method("command_send_drones_to"):
			resource_manager.command_send_drones_to(sel)
			_show_action("Ordered all drones to asteroid")
	else:
		_show_action("Select an asteroid first")

func _on_send1_pressed():
	var map = get_node("Map") if has_node("Map") else null
	var sel = map.selected if map else null
	if sel and sel.is_in_group("asteroids"):
		if resource_manager and resource_manager.has_method("send_n_drones_to"):
			resource_manager.send_n_drones_to(sel, 1)
			_show_action("Sent 1 drone")
	else:
		_show_action("Select an asteroid first")

func _on_send3_pressed():
	var map = get_node("Map") if has_node("Map") else null
	var sel = map.selected if map else null
	if sel and sel.is_in_group("asteroids"):
		if resource_manager and resource_manager.has_method("send_n_drones_to"):
			resource_manager.send_n_drones_to(sel, 3)
			_show_action("Sent 3 drones")
	else:
		_show_action("Select an asteroid first")

func _on_pr_up():
	var map = get_node("Map") if has_node("Map") else null
	var sel = map.selected if map else null
	if sel and sel.is_in_group("asteroids"):
		if resource_manager and resource_manager.has_method("set_asteroid_priority"):
			resource_manager.set_asteroid_priority(sel, 1)
			_show_action("Increased priority")
	else:
		_show_action("Select an asteroid first")

func _on_pr_dn():
	var map = get_node("Map") if has_node("Map") else null
	var sel = map.selected if map else null
	if sel and sel.is_in_group("asteroids"):
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
