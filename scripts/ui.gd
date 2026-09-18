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
var mining_speed_button: Button = null
var drone_multiplier_button: Button = null
var capacity_button: Button = null
var drone_button: Button = null
var click_output_button: Button = null
var click_multiplier_button: Button = null
var signal_button: Button = null
var drone_signal_button: Button = null
var speed_text: Label = null
var mining_text: Label = null
var mining_speed_text: Label = null
var drone_multiplier_text: Label = null
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
var battle_button: Button = null
var controls_toggle_button: Button = null
var controls_label: Label = null
var dev_panel: Panel = null
var dev_label: Label = null
var dev_add_ore_button: Button = null
var dev_add_research_button: Button = null
var dev_prestige_button: Button = null
var technology_button: Button = null
var research_button: Button = null
var prestige_toggle_button: Button = null
var prestige_panel: Panel = null
var prestige_research_label: Label = null
var prestige_button: Button = null
var research_panel: Panel = null
var research_toggle_button: Button = null
var research_points_label: Label = null
var research_tab_button: Button = null
var rewards_tab_button: Button = null
var hunt_research_button: Button = null
var research_scroll_container: ScrollContainer = null
var rewards_scroll_container: ScrollContainer = null
var research_scroll_content: Control = null
var rewards_scroll_content: Control = null
var research_upgrade_tiles: Array = []
var research_row_controls: Array[Control] = []
var research_ship_lock_labels := {}
var reward_controls: Array[Control] = []
var reward_entries := {}
var prestige_boss_levels: Array[int] = []
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
var refinery_panel: Panel = null
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
var ship_upgrades_visible := {"hammond": false, "drone_carrier": false}
var prestige_separators: Array[Control] = []
var action_timer: Timer = null
var player_upgrades_visible: bool = true
var drone_upgrades_visible: bool = true
var refinery_upgrades_visible: bool = true
var control_buttons_visible: bool = true
var prestige_visible: bool = false
var research_visible: bool = false
var expedition_tab: String = "research"

const PRESTIGE_PANEL_SIZE := Vector2(1140.0, 630.0)
const PRESTIGE_PANEL_VIEWPORT_RATIO := 0.8
const RESEARCH_PANEL_SIZE := Vector2(1140.0, 630.0)
const RESEARCH_PANEL_VIEWPORT_RATIO := 0.8
const RESEARCH_UPGRADE_TILE_SIZE := Vector2(132.0, 66.0)
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
const RIGHT_UPGRADE_DRONE_HEIGHT := 198.0
const RIGHT_UPGRADE_REFINERY_HEIGHT := 158.0
const RIGHT_UPGRADE_SECTION_GAP := 16.0
const REFINERY_HUD_UPGRADES := [
	{"label": "COMMAND CAP", "stat_key": "command_capacity"},
	{"label": "CLICK RATE", "stat_key": "click_rate"},
	{"label": "CLICK MULT", "stat_key": "click_multiplier"},
	{"label": "GLOBAL BONUS", "stat_key": "global_income_bonus"}
]
const SHIP_HUD_UPGRADES := {
	"hammond": {
		"title": "HAMMOND UPGRADES",
		"color": Color("e88a83"),
		"rows": [
			{"label": "COMMAND CAP", "stat_key": "command_capacity"},
			{"label": "CLICK RATE", "stat_key": "click_rate"},
			{"label": "AUTOCANNON", "stat_key": "autocannon"},
			{"label": "AMMO CONVEYOR", "stat_key": "ammo_conveyor"},
			{"label": "TORPEDO", "stat_key": "torpedo"}
		]
	},
	"drone_carrier": {
		"title": "DRONE CARRIER UPGRADES",
		"color": Color("b9a6ff"),
		"rows": [
			{"label": "COMMAND CAP", "stat_key": "command_capacity"},
			{"label": "CLICK RATE", "stat_key": "click_rate"},
			{"label": "COORDINATION", "stat_key": "drone_coordination"},
			{"label": "FIGHTER DRONES", "stat_key": "fighter_drones"}
		]
	}
}
const CAP_RESEARCH_DESCRIPTIONS := [
	"Raises the maximum Click Amount level by 1.",
	"Raises the maximum accepted clicks per second by 1.",
	"Raises the maximum Flagship Speed level by 1.",
	"Raises the maximum Command Capacity level by 1.",
	"Raises the maximum Drone Mining level by 1.",
	"Raises the maximum Drone Mining Speed level by 1.",
	"Raises the maximum Drone Multiplier level by 1.",
	"Raises the maximum Carry Capacity level by 1.",
	"Raises the maximum Drone Speed level by 1."
]
const PASSIVE_RESEARCH_DISPLAY := [
	{
		"label": "READINESS",
		"name": "Readiness",
		"key": "flagship_readiness",
		"description": "Permanent boon: begin every run at Command Capacity level 1."
	},
	{
		"label": "FLAGSHIP THRUSTERS",
		"name": "Flagship thrusters",
		"key": "flagship_ion_thrusters",
		"description": "Permanent boon: multiplies flagship speed by 1.5."
	},
	{
		"label": "RAILGUN",
		"name": "Railgun",
		"key": "flagship_railgun",
		"description": "Permanent boon: adds 10 click damage against battle enemies only."
	},
	{
		"label": "MINING LASERS",
		"name": "Mining lasers",
		"key": "drone_mining_lasers",
		"description": "Permanent boon: doubles drone mining amount."
	},
	{
		"label": "DRONE THRUSTERS",
		"name": "Drone thrusters",
		"key": "drone_ion_thrusts",
		"description": "Permanent boon: multiplies drone speed by 3."
	}
]
const RESEARCH_ROW_DISPLAY := [
	{
		"title": "FLAGSHIP",
		"ship_id": "flagship",
		"upgrades": [
			{"label": "Command Cap", "type": "cap", "key": "flagship_command_capacity", "description": "Add 10 levels to the Flagship Command Capacity ore cap."},
			{"label": "Click Rate Cap", "type": "cap", "key": "flagship_click_rate", "description": "Add 10 levels to the Flagship Click Rate ore cap."},
			{"label": "Readiness", "type": "passive", "key": "flagship_readiness", "description": "Start every run at Command Capacity level 1."},
			{"label": "Ion Thrusters", "type": "passive", "key": "flagship_ion_thrusters", "description": "Multiply flagship speed by 1.5."},
			{"label": "Railgun", "type": "passive", "key": "flagship_railgun", "description": "Add 10 click damage against battle enemies only."}
		]
	},
	{
		"title": "DRONES",
		"ship_id": "mining_drone",
		"upgrades": [
			{"label": "Mining Lasers", "type": "passive", "key": "drone_mining_lasers", "description": "Double drone mining amount."},
			{"label": "Ion Thrusters", "type": "passive", "key": "drone_ion_thrusts", "description": "Multiply drone speed by 3."}
		]
	},
	{
		"title": "ROMIUS",
		"ship_id": "refinery",
		"requires_ship": "refinery",
		"upgrades": [
			{"label": "Command Cap", "type": "cap", "key": "refinery_command_capacity", "description": "Add 10 levels to Romius Command Capacity ore cap."},
			{"label": "Click Rate Cap", "type": "cap", "key": "refinery_click_rate", "description": "Add 10 levels to Romius Click Rate ore cap."}
		]
	},
	{
		"title": "HAMMOND",
		"ship_id": "hammond",
		"requires_ship": "hammond",
		"upgrades": [
			{"label": "Command Cap", "type": "cap", "key": "hammond_command_capacity", "description": "Add 10 levels to Hammond Command Capacity ore cap."},
			{"label": "Click Rate Cap", "type": "cap", "key": "hammond_click_rate", "description": "Add 10 levels to Hammond Click Rate ore cap."}
		]
	},
	{
		"title": "DRONE CARRIER",
		"ship_id": "drone_carrier",
		"requires_ship": "drone_carrier",
		"upgrades": [
			{"label": "Command Cap", "type": "cap", "key": "drone_carrier_command_capacity", "description": "Add 10 levels to the Carrier Command Capacity ore cap."},
			{"label": "Click Rate Cap", "type": "cap", "key": "drone_carrier_click_rate", "description": "Add 10 levels to the Carrier Click Rate ore cap."}
		]
	}
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
	dev_add_ore_button.text = "+1,000 Ore"
	dev_add_ore_button.position = Vector2(8.0, 31.0)
	dev_add_ore_button.size = Vector2(128.0, 28.0)
	dev_panel.add_child(dev_add_ore_button)
	dev_add_ore_button.pressed.connect(Callable(self, "_on_dev_add_ore_pressed"))

	dev_add_research_button = Button.new()
	dev_add_research_button.name = "DevAddResearchButton"
	dev_add_research_button.text = "+10 Research"
	dev_add_research_button.position = Vector2(144.0, 31.0)
	dev_add_research_button.size = Vector2(128.0, 28.0)
	dev_panel.add_child(dev_add_research_button)
	dev_add_research_button.pressed.connect(Callable(self, "_on_dev_add_research_pressed"))

	dev_prestige_button = Button.new()
	dev_prestige_button.name = "DevPrestigeButton"
	dev_prestige_button.text = "Prestige +1"
	dev_prestige_button.tooltip_text = "Perform a normal prestige without requiring a battle victory"
	dev_prestige_button.position = Vector2(8.0, 65.0)
	dev_prestige_button.size = Vector2(264.0, 28.0)
	dev_panel.add_child(dev_prestige_button)
	dev_prestige_button.pressed.connect(Callable(self, "_on_dev_prestige_pressed"))

	research_button = Button.new()
	research_button.name = "ResearchButton"
	research_button.text = "Expedition Details"
	research_button.position = Vector2(max(18.0, get_viewport().get_visible_rect().size.x * 0.5 - 120.0), 12.0)
	research_button.size = Vector2(240, 32)
	research_button.tooltip_text = "Toggle expedition research and rewards"
	add_child(research_button)
	research_button.pressed.connect(Callable(self, "_on_research_toggle_pressed"))

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
	prestige_toggle_button.text = "X"
	prestige_toggle_button.visible = false
	prestige_toggle_button.tooltip_text = "Close technology panel"
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
		passive_button.pressed.connect(Callable(self, "_upgrade_passive").bind(str(passive_data["key"])))
		var passive_refund = Button.new()
		passive_refund.name = "%sTechnologyRefundButton" % passive_data["key"]
		passive_refund.text = "-"
		passive_refund.position = Vector2(PRESTIGE_COLUMN_X[1] + 216.0, 98.0 + technology_passive_refund_buttons.size() * 50.0)
		passive_refund.size = Vector2(20, 28)
		passive_refund.tooltip_text = "Remove uncommitted allocation"
		prestige_panel.add_child(passive_refund)
		passive_refund.visible = false
		technology_passive_refund_buttons.append(passive_refund)
		passive_refund.pressed.connect(Callable(self, "_refund_passive").bind(str(passive_data["key"])))

	var prestige_row_y = [98, 138, 178, 218, 258, 298, 338, 378, 418]
	var prestige_names = ["ClickAmountCap", "ClickMultiplierCap", "FlagshipSpeedCap", "CommandCapacityCap", "DroneMiningCap", "DroneMiningSpeedCap", "DroneMultiplierCap", "CarryCapacityCap", "DroneSpeedCap"]
	var prestige_keys = ["click_output", "click_multiplier", "flagship_speed", "drones", "mining", "mining_speed", "drone_multiplier", "capacity", "speed"]
	var prestige_display_names = ["Click amount", "Click rate", "Flagship speed", "Command capacity", "Drone mining", "Mining speed", "Drone multiplier", "Carry capacity", "Drone speed"]
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
		level_label.size = Vector2(58, 26)
		level_label.text = "CAP 10"
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.add_theme_color_override("font_color", Color("f4d06f"))
		prestige_panel.add_child(level_label)
		technology_cap_level_labels.append(level_label)
		var button = Button.new()
		button.name = "%sResearchButton" % prestige_names[i]
		button.text = "+"
		button.position = Vector2(244, prestige_row_y[i])
		button.size = Vector2(20, 28)
		prestige_panel.add_child(button)
		button.pressed.connect(Callable(self, "_on_research_upgrade_%s" % prestige_keys[i]))
		var refund_button = Button.new()
		refund_button.name = "%sResearchRefundButton" % prestige_names[i]
		refund_button.text = "-"
		refund_button.tooltip_text = "Remove uncommitted allocation"
		refund_button.position = Vector2(220, prestige_row_y[i])
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

	_build_research_panel()

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
	drone_panel.size = Vector2(RIGHT_UPGRADE_PANEL_WIDTH, RIGHT_UPGRADE_DRONE_HEIGHT)
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
	mining_speed_text = _create_upgrade_row("MiningSpeed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP, "drone")
	drone_multiplier_text = _create_upgrade_row("Multiplier", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, "drone")
	capacity_text = _create_upgrade_row("Capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, "drone")
	speed_text = _create_upgrade_row("MoveSpeed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 4.0, "drone")

	click_output_button = _create_upgrade_button("Upgrade click output", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0, Callable(self, "_on_upgrade_click_output"))
	click_multiplier_button = _create_upgrade_button("Upgrade click rate", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP, Callable(self, "_on_upgrade_click_multiplier"))

	mining_button = _create_upgrade_button("Upgrade drone mining amount", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0, Callable(self, "_on_upgrade_mining"))
	mining_speed_button = _create_upgrade_button("Upgrade drone mining speed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP, Callable(self, "_on_upgrade_mining_speed"))
	drone_multiplier_button = _create_upgrade_button("Upgrade drone multiplier", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, Callable(self, "_on_upgrade_drone_multiplier"))
	capacity_button = _create_upgrade_button("Upgrade drone cargo capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, Callable(self, "_on_upgrade_capacity"))
	speed_button = _create_upgrade_button("Upgrade drone move speed", btn_x, RIGHT_UPGRADE_TOP_Y + 212.0 + RIGHT_UPGRADE_ROW_GAP * 4.0, Callable(self, "_on_upgrade_speed"))

	flagship_speed_button = _create_upgrade_button("Upgrade flagship speed", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0, Callable(self, "_on_upgrade_flagship_speed"))
	command_capacity_button = _create_upgrade_button("Upgrade command capacity", btn_x, RIGHT_UPGRADE_TOP_Y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0, Callable(self, "_on_buy_drone"))

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
	refinery_upgrade_label.add_theme_font_size_override("font_size", 14)
	refinery_upgrade_label.add_theme_color_override("font_color", Color("7ce0b8"))
	add_child(refinery_upgrade_label)

	for index in range(REFINERY_HUD_UPGRADES.size()):
		var upgrade_data = REFINERY_HUD_UPGRADES[index]
		var row_y = refinery_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index
		var row_label = _create_upgrade_row("Refinery%s" % str(upgrade_data["stat_key"]).to_pascal_case(), btn_x, row_y, "refinery")
		refinery_upgrade_texts.append(row_label)
		var upgrade_button = _create_upgrade_button("Upgrade Romius %s" % upgrade_data["label"], btn_x, row_y, Callable(self, "_on_upgrade_refinery_stat").bind(str(upgrade_data["stat_key"])))
		refinery_upgrade_buttons.append(upgrade_button)
	_set_refinery_upgrade_contents_visible(false)
	refinery_signal_button.visible = false
	refinery_upgrade_label.visible = false
	for ship_key in ["hammond", "drone_carrier"]:
		_build_ship_upgrade_hud(ship_key, panel_style)

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

func _build_research_panel() -> void:
	research_panel = Panel.new()
	research_panel.name = "ResearchPanel"
	research_panel.position = get_viewport().get_visible_rect().size * 0.5 - RESEARCH_PANEL_SIZE * 0.5
	research_panel.size = RESEARCH_PANEL_SIZE
	research_panel.visible = false
	research_panel.mouse_filter = Control.MOUSE_FILTER_STOP
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

	research_points_label = Label.new()
	research_points_label.name = "ResearchRowsPointsLabel"
	research_points_label.text = "RESEARCH 0"
	research_points_label.position = Vector2(58.0, 20.0)
	research_points_label.size = Vector2(260.0, 28.0)
	research_points_label.add_theme_font_size_override("font_size", 18)
	research_points_label.add_theme_color_override("font_color", Color("f4d06f"))
	research_panel.add_child(research_points_label)

	var title_label = Label.new()
	title_label.name = "ResearchRowsTitle"
	title_label.text = "SHIP RESEARCH"
	title_label.position = Vector2(330.0, 20.0)
	title_label.size = Vector2(220.0, 28.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color("72d6e8"))
	research_panel.add_child(title_label)

	hunt_research_button = Button.new()
	hunt_research_button.name = "HuntResearchButton"
	hunt_research_button.text = "Hunt for Research"
	hunt_research_button.position = Vector2(570.0, 18.0)
	hunt_research_button.size = Vector2(190.0, 28.0)
	hunt_research_button.tooltip_text = "Launch a named fight to unlock a research card"
	research_panel.add_child(hunt_research_button)
	hunt_research_button.pressed.connect(Callable(self, "_on_hunt_research_pressed"))

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

	research_scroll_container = ScrollContainer.new()
	research_scroll_container.name = "ResearchScrollContainer"
	research_scroll_container.position = Vector2(20.0, 60.0)
	research_scroll_container.size = Vector2(1100.0, 500.0)
	research_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	research_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	research_scroll_container.follow_focus = true
	research_panel.add_child(research_scroll_container)
	research_row_controls.append(research_scroll_container)

	research_scroll_content = Control.new()
	research_scroll_content.name = "ResearchScrollContent"
	research_scroll_content.custom_minimum_size = Vector2(1080.0, 540.0)
	research_scroll_container.add_child(research_scroll_content)

	rewards_scroll_container = ScrollContainer.new()
	rewards_scroll_container.name = "RewardsScrollContainer"
	rewards_scroll_container.position = Vector2(20.0, 60.0)
	rewards_scroll_container.size = Vector2(1100.0, 500.0)
	rewards_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rewards_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rewards_scroll_container.follow_focus = true
	research_panel.add_child(rewards_scroll_container)
	reward_controls.append(rewards_scroll_container)

	rewards_scroll_content = Control.new()
	rewards_scroll_content.name = "RewardsScrollContent"
	rewards_scroll_content.custom_minimum_size = Vector2(1080.0, 540.0)
	rewards_scroll_container.add_child(rewards_scroll_content)

	for row_index in range(RESEARCH_ROW_DISPLAY.size()):
		_build_research_row(RESEARCH_ROW_DISPLAY[row_index], row_index)
	research_scroll_content.custom_minimum_size.y = max(540.0, 8.0 + RESEARCH_ROW_DISPLAY.size() * 138.0)

	_build_rewards_tab()

	_set_expedition_tab("research")

func _build_rewards_tab() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_prestige_boss_levels"):
		prestige_boss_levels = game_state.get_prestige_boss_levels()
	for index in range(prestige_boss_levels.size()):
		var target_prestige = prestige_boss_levels[index]
		var prestige_data: Dictionary = game_state.get_prestige_data(target_prestige)
		var reward_panel = Panel.new()
		reward_panel.name = "Prestige%dPanel" % target_prestige
		reward_panel.position = Vector2(4.0, 4.0 + index * 126.0)
		reward_panel.size = Vector2(1068.0, 116.0)
		reward_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.06, 0.11, 0.14, 0.78), Color(0.4, 0.86, 0.72, 0.7), 1, 4))
		rewards_scroll_content.add_child(reward_panel)

		var reward_title = Label.new()
		reward_title.text = "PRESTIGE %d | %s ORE" % [target_prestige, _format_number(int(prestige_data["cost"]))]
		reward_title.position = Vector2(18.0, 10.0)
		reward_title.size = Vector2(650.0, 24.0)
		reward_title.add_theme_font_size_override("font_size", 14)
		reward_title.add_theme_color_override("font_color", Color("f4d06f"))
		reward_panel.add_child(reward_title)

		var reset_description = Label.new()
		reset_description.text = "Consumes the required ore and resets field, drones, and every ore-bought level."
		reset_description.position = Vector2(18.0, 40.0)
		reset_description.size = Vector2(820.0, 22.0)
		reset_description.add_theme_font_size_override("font_size", 12)
		reset_description.add_theme_color_override("font_color", Color("ffaaa3"))
		reward_panel.add_child(reset_description)

		var reward_description = Label.new()
		reward_description.text = "REWARD  %s" % str(prestige_data["reward"])
		reward_description.position = Vector2(18.0, 70.0)
		reward_description.size = Vector2(820.0, 36.0)
		reward_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_description.add_theme_font_size_override("font_size", 12)
		reward_description.add_theme_color_override("font_color", Color("d9f4ff"))
		reward_panel.add_child(reward_description)

		var status_label = Label.new()
		status_label.text = "LOCKED"
		status_label.position = Vector2(820.0, 12.0)
		status_label.size = Vector2(210.0, 24.0)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_label.add_theme_font_size_override("font_size", 13)
		status_label.add_theme_color_override("font_color", Color("f4d06f"))
		reward_panel.add_child(status_label)

		var attempt_button = Button.new()
		attempt_button.text = "Prestige"
		attempt_button.position = Vector2(870.0, 58.0)
		attempt_button.size = Vector2(176.0, 40.0)
		reward_panel.add_child(attempt_button)
		attempt_button.pressed.connect(Callable(self, "_on_prestige_purchase_pressed").bind(target_prestige))
		reward_entries[target_prestige] = {"status": status_label, "button": attempt_button}
	rewards_scroll_content.custom_minimum_size.y = max(540.0, 8.0 + prestige_boss_levels.size() * 126.0)

func _format_number(value: int) -> String:
	var raw = str(value)
	var formatted = ""
	while raw.length() > 3:
		formatted = "," + raw.right(3) + formatted
		raw = raw.left(raw.length() - 3)
	return raw + formatted

func _build_research_row(row_data: Dictionary, row_index: int) -> void:
	var row_height = 128.0
	var row_y = 8.0 + float(row_index) * (row_height + 10.0)
	var row_panel = Panel.new()
	row_panel.name = "%sResearchRow" % row_data["title"]
	row_panel.position = Vector2(4.0, row_y)
	row_panel.size = Vector2(1068.0, row_height)
	row_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.07, 0.12, 0.16, 0.72), Color(0.25, 0.65, 0.75, 0.55), 1, 4))
	research_scroll_content.add_child(row_panel)

	var ship_label = Label.new()
	ship_label.name = "%sResearchRowLabel" % row_data["title"]
	ship_label.text = str(row_data["title"])
	ship_label.position = Vector2(18.0, row_height * 0.5 - 28.0)
	ship_label.size = Vector2(112.0, 56.0)
	ship_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_ship_profile"):
		var profile = game_state.get_ship_profile(StringName(row_data.get("ship_id", ""))) as ShipProfile
		if profile:
			ship_label.text = "%s\n%s" % [str(row_data["title"]), profile.get_category_name().to_upper()]
			ship_label.tooltip_text = "Roles: %s" % ", ".join(profile.get_role_names())
	ship_label.add_theme_font_size_override("font_size", 14)
	ship_label.add_theme_color_override("font_color", Color("f4d06f"))
	row_panel.add_child(ship_label)

	var ship_body = Panel.new()
	ship_body.name = "%sResearchShipBody" % row_data["title"]
	ship_body.position = Vector2(150.0, 14.0)
	ship_body.size = Vector2(912.0, max(64.0, row_height - 28.0))
	ship_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_body.add_theme_stylebox_override("panel", _make_flat_style(Color(0.05, 0.11, 0.15, 0.42), Color(0.31, 0.8, 0.9, 0.35), 1, 3))
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
		if row_data.has("requires_ship"):
			upgrade_data["requires_ship"] = str(row_data["requires_ship"])
		_build_research_tile(row_panel, upgrade_data, tile_index)
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
		research_ship_lock_labels[str(row_data["requires_ship"])] = lock_label

func _build_research_tile(row_panel: Panel, upgrade_data: Dictionary, tile_index: int) -> void:
	var tile_rect = _get_research_tile_rect(upgrade_data, tile_index)
	var tile = Panel.new()
	tile.name = "%sResearchTile" % upgrade_data["key"]
	tile.position = tile_rect.position
	tile.size = tile_rect.size
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.tooltip_text = upgrade_data["description"]
	tile.add_theme_stylebox_override("panel", _make_flat_style(Color(0.02, 0.06, 0.1, 0.86), Color(0.36, 0.78, 0.88, 0.55), 1, 3))
	row_panel.add_child(tile)

	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = upgrade_data["label"]
	name_label.position = Vector2(6.0, 4.0)
	name_label.size = Vector2(max(1.0, tile_rect.size.x - 12.0), 18.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

	var refund_button = Button.new()
	refund_button.name = "RefundButton"
	refund_button.text = "-"
	refund_button.position = Vector2(tile_rect.size.x * 0.5 - 30.0, button_y)
	refund_button.size = Vector2(26.0, 22.0)
	refund_button.tooltip_text = "Remove one uncommitted allocation"
	tile.add_child(refund_button)
	var action_key = str(upgrade_data["key"])
	refund_button.pressed.connect(Callable(self, "_on_research_tile_pressed").bind(str(upgrade_data["type"]), action_key, -1))
	if str(upgrade_data["type"]) == "passive":
		refund_button.visible = false

	var buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "+"
	buy_button.position = Vector2(tile_rect.size.x * 0.5 + 4.0, button_y)
	buy_button.size = Vector2(26.0, 22.0)
	tile.add_child(buy_button)
	buy_button.pressed.connect(Callable(self, "_on_research_tile_pressed").bind(str(upgrade_data["type"]), action_key, 1))

	research_upgrade_tiles.append({
		"type": str(upgrade_data["type"]),
		"key": str(upgrade_data["key"]),
		"stat_key": str(upgrade_data.get("stat_key", "")),
		"requires_ship": str(upgrade_data.get("requires_ship", "")),
		"description": str(upgrade_data["description"]),
		"label": name_label,
		"level": level_label,
		"buy": buy_button,
		"refund": refund_button,
		"tile": tile
	})

func _get_research_tile_rect(upgrade_data: Dictionary, tile_index: int) -> Rect2:
	if upgrade_data.has("rect"):
		var rect = upgrade_data["rect"]
		return Rect2(Vector2(float(rect[0]), float(rect[1])), Vector2(float(rect[2]), float(rect[3])))
	if upgrade_data.has("pos"):
		var pos = upgrade_data["pos"]
		return Rect2(Vector2(float(pos[0]), float(pos[1])), RESEARCH_UPGRADE_TILE_SIZE)
	return Rect2(Vector2(150.0 + tile_index * 122.0, 22.0), Vector2(112.0, 88.0))

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
	var panel_width = min(RIGHT_UPGRADE_PANEL_WIDTH, max(260.0, viewport_size.x - 20.0))
	var panel_x = max(8.0, viewport_size.x - panel_width - 12.0)
	var content_width = panel_width - RIGHT_UPGRADE_LABEL_X - 8.0
	var upgrade_font_size = 14 if aspect_ratio >= 1.4 else 12
	var help_y = viewport_size.y - 48.0
	var ore_y = RIGHT_UPGRADE_TOP_Y - 32.0
	var flagship_y = RIGHT_UPGRADE_TOP_Y
	var flagship_height = RIGHT_UPGRADE_FLAGSHIP_HEIGHT if player_upgrades_visible else RIGHT_UPGRADE_HEADER_HEIGHT
	var drone_y = flagship_y + flagship_height + RIGHT_UPGRADE_SECTION_GAP
	var drone_height = RIGHT_UPGRADE_DRONE_HEIGHT if drone_upgrades_visible else RIGHT_UPGRADE_HEADER_HEIGHT
	var refinery_y = drone_y + drone_height + RIGHT_UPGRADE_SECTION_GAP
	var refinery_height = RIGHT_UPGRADE_REFINERY_HEIGHT if refinery_upgrades_visible else RIGHT_UPGRADE_HEADER_HEIGHT
	var control_x = 18.0
	var control_y = max(142.0, help_y - 286.0)
	var control_width = min(280.0, max(220.0, viewport_size.x - 36.0))
	var control_half_width = (control_width - 8.0) * 0.5
	if dev_panel:
		dev_panel.position = Vector2(control_x, control_y - 112.0)
		dev_panel.size = Vector2(control_width, 102.0)
	if dev_label:
		dev_label.size = Vector2(control_width - 20.0, 22.0)
	if dev_add_ore_button:
		dev_add_ore_button.position = Vector2(8.0, 31.0)
		dev_add_ore_button.size = Vector2(control_half_width, 28.0)
	if dev_add_research_button:
		dev_add_research_button.position = Vector2(control_half_width + 16.0, 31.0)
		dev_add_research_button.size = Vector2(control_half_width, 28.0)
	if dev_prestige_button:
		dev_prestige_button.position = Vector2(8.0, 65.0)
		dev_prestige_button.size = Vector2(max(1.0, control_width - 16.0), 28.0)
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
	if refinery_panel:
		refinery_panel.position = Vector2(panel_x - 8.0, refinery_y)
		refinery_panel.size = Vector2(panel_width, RIGHT_UPGRADE_REFINERY_HEIGHT)
	if research_button:
		var research_button_width = 240.0 if viewport_size.x >= 560.0 else min(220.0, max(120.0, viewport_size.x - 36.0))
		research_button.position = Vector2(max(18.0, viewport_size.x * 0.5 - research_button_width * 0.5), 12.0)
		research_button.size = Vector2(research_button_width, 32.0)
	if prestige_panel:
		var prestige_scale = _get_prestige_panel_scale(viewport_size)
		prestige_panel.scale = Vector2(prestige_scale, prestige_scale)
		prestige_panel.position = viewport_size * 0.5 - PRESTIGE_PANEL_SIZE * prestige_scale * 0.5
		prestige_panel.size = PRESTIGE_PANEL_SIZE
	if research_panel:
		var research_scale = _get_research_panel_scale(viewport_size)
		research_panel.scale = Vector2(research_scale, research_scale)
		research_panel.position = viewport_size * 0.5 - RESEARCH_PANEL_SIZE * research_scale * 0.5
		research_panel.size = RESEARCH_PANEL_SIZE
	if prestige_toggle_button:
		prestige_toggle_button.position = Vector2(18.0, 18.0)
	if research_toggle_button:
		research_toggle_button.position = Vector2(18.0, 18.0)
	if prestige_research_label:
		prestige_research_label.position = Vector2(58.0, 20.0)
	if research_points_label:
		research_points_label.position = Vector2(58.0, 20.0)
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
	var cap_row_y = [98.0, 138.0, 178.0, 218.0, 258.0, 298.0, 338.0, 378.0, 418.0]
	var cap_row_names = ["ClickAmountCap", "ClickMultiplierCap", "FlagshipSpeedCap", "CommandCapacityCap", "DroneMiningCap", "DroneMiningSpeedCap", "DroneMultiplierCap", "CarryCapacityCap", "DroneSpeedCap"]
	for i in range(cap_row_names.size()):
		var node_name = "%sResearchLabel" % cap_row_names[i]
		var row_node = prestige_panel.get_node_or_null(node_name) if prestige_panel else null
		if row_node:
			row_node.position = Vector2(24.0, cap_row_y[i])
			row_node.size = Vector2(120.0, 26.0)
		var level_node = prestige_panel.get_node_or_null("%sResearchLevelLabel" % cap_row_names[i]) if prestige_panel else null
		if level_node:
			level_node.position = Vector2(150.0, cap_row_y[i])
			level_node.size = Vector2(58.0, 26.0)
		var button_name = "%sResearchButton" % cap_row_names[i]
		var button_node = prestige_panel.get_node_or_null(button_name) if prestige_panel else null
		if button_node:
			button_node.position = Vector2(244.0, cap_row_y[i])
		var refund_node = prestige_panel.get_node_or_null("%sResearchRefundButton" % cap_row_names[i]) if prestige_panel else null
		if refund_node:
			refund_node.position = Vector2(220.0, cap_row_y[i])
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
		"DroneUpgradeLabel": [panel_x + RIGHT_UPGRADE_LABEL_X, drone_y + 8.0, content_width, 24.0],
		"RefineryUpgradeSignalButton": [panel_x, refinery_y + 8.0, 28.0, 28.0],
		"RefineryUpgradeLabel": [panel_x + RIGHT_UPGRADE_LABEL_X, refinery_y + 8.0, content_width, 24.0]
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
		[mining_speed_button, mining_speed_text, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP],
		[drone_multiplier_button, drone_multiplier_text, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 2.0],
		[capacity_button, capacity_text, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0],
		[speed_button, speed_text, drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 4.0]
	]
	for index in range(refinery_upgrade_buttons.size()):
		upgrade_controls.append([refinery_upgrade_buttons[index], refinery_upgrade_texts[index], refinery_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index])
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
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 3.0,
		drone_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * 4.0
	]
	for index in range(drone_separators.size()):
		drone_separators[index].position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_positions[index] + 25.0)
		drone_separators[index].size = Vector2(max(1.0, content_width - 8.0), 1.0)
	for index in range(drone_level_texts.size()):
		drone_level_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_LEVEL_X, row_positions[index])
		drone_level_texts[index].size = Vector2(44.0, 24.0)
		drone_effect_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_EFFECT_X, row_positions[index])
		drone_effect_texts[index].size = Vector2(max(72.0, panel_width - RIGHT_UPGRADE_EFFECT_X - 8.0), 24.0)
	row_positions = []
	for index in range(REFINERY_HUD_UPGRADES.size()):
		row_positions.append(refinery_y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index)
	for index in range(refinery_separators.size()):
		refinery_separators[index].position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_positions[index] + 25.0)
		refinery_separators[index].size = Vector2(max(1.0, content_width - 8.0), 1.0)
	for index in range(refinery_level_texts.size()):
		refinery_level_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_LEVEL_X, row_positions[index])
		refinery_level_texts[index].size = Vector2(44.0, 24.0)
		refinery_effect_texts[index].position = Vector2(panel_x + RIGHT_UPGRADE_EFFECT_X, row_positions[index])
		refinery_effect_texts[index].size = Vector2(max(72.0, panel_width - RIGHT_UPGRADE_EFFECT_X - 8.0), 24.0)
	_layout_ship_upgrade_huds(panel_x, refinery_y + refinery_height + RIGHT_UPGRADE_SECTION_GAP, panel_width, content_width)
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

func _layout_ship_upgrade_huds(panel_x: float, start_y: float, panel_width: float, content_width: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	var y = start_y
	for ship_key in ["hammond", "drone_carrier"]:
		var hud: Dictionary = ship_upgrade_huds.get(ship_key, {})
		if hud.is_empty():
			continue
		var unlocked = game_state and game_state.is_ship_unlocked(ship_key)
		var hud_visible = unlocked and not _has_open_research_overlay()
		var expanded = bool(ship_upgrades_visible.get(ship_key, false))
		var rows: Array = hud["rows"]
		var full_height = 38.0 + float(rows.size()) * RIGHT_UPGRADE_ROW_GAP
		var height = full_height if expanded else RIGHT_UPGRADE_HEADER_HEIGHT
		var panel = hud["panel"] as Panel
		var toggle = hud["toggle"] as Button
		var title = hud["title"] as Label
		panel.visible = hud_visible
		toggle.visible = hud_visible
		title.visible = hud_visible
		panel.position = Vector2(panel_x - 8.0, y)
		panel.size = Vector2(panel_width, height)
		toggle.position = Vector2(panel_x, y + 8.0)
		toggle.text = ">" if expanded else "<"
		title.position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, y + 8.0)
		title.size = Vector2(content_width, 24.0)
		for index in range(rows.size()):
			var row: Dictionary = rows[index]
			var row_visible = hud_visible and expanded
			var row_y = y + 38.0 + RIGHT_UPGRADE_ROW_GAP * index
			var button = row["button"] as Button
			var name_label = row["name"] as Label
			var level_label = row["level"] as Label
			var effect_label = row["effect"] as Label
			for control in [button, name_label, level_label, effect_label]:
				control.visible = row_visible
			button.position = Vector2(panel_x, row_y)
			name_label.position = Vector2(panel_x + RIGHT_UPGRADE_LABEL_X, row_y)
			name_label.size = Vector2(RIGHT_UPGRADE_LEVEL_X - RIGHT_UPGRADE_LABEL_X - 6.0, 24.0)
			level_label.position = Vector2(panel_x + RIGHT_UPGRADE_LEVEL_X, row_y)
			level_label.size = Vector2(44.0, 24.0)
			effect_label.position = Vector2(panel_x + RIGHT_UPGRADE_EFFECT_X, row_y)
			effect_label.size = Vector2(max(72.0, panel_width - RIGHT_UPGRADE_EFFECT_X - 8.0), 24.0)
		if hud_visible:
			y += height + RIGHT_UPGRADE_SECTION_GAP

func _get_prestige_panel_scale(viewport_size: Vector2) -> float:
	var max_panel_size = viewport_size * PRESTIGE_PANEL_VIEWPORT_RATIO
	return min(1.0, min(max_panel_size.x / PRESTIGE_PANEL_SIZE.x, max_panel_size.y / PRESTIGE_PANEL_SIZE.y))

func _get_research_panel_scale(viewport_size: Vector2) -> float:
	var max_panel_size = viewport_size * RESEARCH_PANEL_VIEWPORT_RATIO
	return min(1.0, min(max_panel_size.x / RESEARCH_PANEL_SIZE.x, max_panel_size.y / RESEARCH_PANEL_SIZE.y))

func _format_ore_text(amount: float) -> String:
	return "ORE  %06d" % int(round(amount))

func _update_ore_labels(amount: float) -> void:
	var ore_text = _format_ore_text(amount)
	var tooltip = "Exact ore: %.2f" % amount
	if resource_label:
		resource_label.text = ore_text
		resource_label.tooltip_text = tooltip
	if right_ore_label:
		right_ore_label.text = ore_text
		right_ore_label.tooltip_text = tooltip

func _on_resource_changed(amount):
	_update_ore_labels(float(amount))

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
		var mining_speed_level = int(resource_manager.mining_speed_level)
		var capacity_level = int(resource_manager.capacity_level)
		var drone_level = int(resource_manager.drone_level)
		var active_drone_count = int(resource_manager.get_active_drone_count())
		var flagship_speed_level = int(resource_manager.flagship_speed_level)
		var click_gain = float(resource_manager.get_click_output()) * resource_manager.get_refinery_click_multiplier() * resource_manager.get_global_ore_multiplier()
		_update_ore_labels(float(resource_manager.total_resources))
		upgrade_label.text = "FLAGSHIP UPGRADES    %.1f / PER CLICK" % click_gain
		click_output_text.text = "CLICK OUTPUT"
		click_multiplier_text.text = "CLICK RATE"
		mining_text.text = "MINING AMOUNT"
		mining_speed_text.text = "MINING SPEED"
		drone_multiplier_text.text = "MULTIPLIER"
		capacity_text.text = "CAPACITY"
		speed_text.text = "MOVE SPEED"
		command_capacity_text.text = "COMMAND CAPACITY"
		flagship_speed_text.text = "MOVE SPEED"
		var click_rate = resource_manager.get_click_rate_cap()
		_update_table_values(player_level_texts, player_effect_texts, [int(resource_manager.click_output_level), int(resource_manager.click_multiplier_level), drone_level, flagship_speed_level], ["%.1f /per click" % click_gain, "%d/sec (%.3fs)" % [int(click_rate), 1.0 / click_rate], "%d/%d active" % [active_drone_count, int(resource_manager.get_drone_cap())], "%d speed" % int(resource_manager.get_flagship_speed())])
		_update_table_values(drone_level_texts, drone_effect_texts, [mining_level, mining_speed_level, int(resource_manager.drone_multiplier_level), capacity_level, speed_level], ["%d /tick" % int(resource_manager.get_mining_amount()), "%.1f ticks/sec" % resource_manager.get_mining_speed(), "%.2fx gain" % resource_manager.get_drone_multiplier(), "%d capacity" % int(resource_manager.get_capacity()), "%d speed" % int(resource_manager.get_speed())])
		_update_upgrade_button(click_output_button, "Upgrade click output", int(resource_manager.click_output_level), resource_manager.get_ore_upgrade_cost("click_output"), resource_manager.get_ore_upgrade_cap("click_output"))
		_update_upgrade_button(click_multiplier_button, "Upgrade click rate", int(resource_manager.click_multiplier_level), resource_manager.get_ore_upgrade_cost("click_multiplier"), resource_manager.get_ore_upgrade_cap("click_multiplier"))
		_update_upgrade_button(speed_button, "Upgrade drone move speed", speed_level, resource_manager.get_ore_upgrade_cost("speed"), resource_manager.get_ore_upgrade_cap("speed"))
		_update_upgrade_button(mining_button, "Upgrade mining power", mining_level, resource_manager.get_ore_upgrade_cost("mining"), resource_manager.get_ore_upgrade_cap("mining"))
		_update_upgrade_button(mining_speed_button, "Upgrade drone mining speed", mining_speed_level, resource_manager.get_ore_upgrade_cost("mining_speed"), resource_manager.get_ore_upgrade_cap("mining_speed"))
		_update_upgrade_button(drone_multiplier_button, "Upgrade drone multiplier", int(resource_manager.drone_multiplier_level), resource_manager.get_ore_upgrade_cost("drone_multiplier"), resource_manager.get_ore_upgrade_cap("drone_multiplier"))
		_update_upgrade_button(capacity_button, "Upgrade cargo capacity", capacity_level, resource_manager.get_ore_upgrade_cost("capacity"), resource_manager.get_ore_upgrade_cap("capacity"))
		_update_upgrade_button(drone_button, "Buy active drone", drone_level, resource_manager.get_drone_purchase_cost(), resource_manager.get_ore_upgrade_cap("drones"))
		_update_upgrade_button(flagship_speed_button, "Upgrade flagship speed", flagship_speed_level, resource_manager.get_ore_upgrade_cost("flagship_speed"), resource_manager.get_ore_upgrade_cap("flagship_speed"))
		if active_drone_count < drone_level:
			_update_upgrade_button(command_capacity_button, "Replace lost drone", active_drone_count, resource_manager.get_drone_purchase_cost(), drone_level)
		else:
			_update_upgrade_button(command_capacity_button, "Upgrade command capacity", drone_level, resource_manager.get_drone_purchase_cost(), resource_manager.get_ore_upgrade_cap("drones"))
		var drone_trip_gain = float(resource_manager.get_capacity()) * resource_manager.get_drone_multiplier() * resource_manager.get_global_ore_multiplier()
		drone_upgrade_label.text = "DRONE UPGRADES    %.1f / PER TRIP" % drone_trip_gain
	_update_refinery_upgrade_hud()
	_update_ship_upgrade_huds()
	if prestige_research_label and resource_manager:
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			prestige_research_label.text = "RESEARCH %d" % int(game_state.research_points)
		var cap_keys = ["click_output", "click_multiplier", "flagship_speed", "drones", "mining", "mining_speed", "drone_multiplier", "capacity", "speed"]
		var cap_names = ["ClickAmountCap", "ClickMultiplierCap", "FlagshipSpeedCap", "CommandCapacityCap", "DroneMiningCap", "DroneMiningSpeedCap", "DroneMultiplierCap", "CarryCapacityCap", "DroneSpeedCap"]
		var cap_display_names = ["Click amount", "Click rate", "Flagship speed", "Command capacity", "Drone mining", "Mining speed", "Drone multiplier", "Carry capacity", "Drone speed"]
		for idx in range(cap_keys.size()):
			var row_label = prestige_panel.get_node_or_null("%sResearchLabel" % cap_names[idx])
			if row_label:
				var key = cap_keys[idx]
				var game_state2 = get_node_or_null("/root/GameState")
				var cap_value = 10
				if game_state2:
					cap_value = int(game_state2.get_pending_upgrade_cap(key))
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
					technology_cap_level_labels[idx].text = "CAP %d" % cap_value
		for idx in range(technology_passive_labels.size()):
			var passive_data = PASSIVE_RESEARCH_DISPLAY[idx]
			var passive_key = passive_data["key"]
			var passive_state = get_node_or_null("/root/GameState")
			if passive_state:
				var committed_level = int(passive_state.get_passive_level(passive_key))
				var pending_level = int(passive_state.get_pending_passive_level(passive_key))
				var single_purchase = passive_state.has_method("is_single_purchase_passive") and passive_state.is_single_purchase_passive(passive_key)
				var passive_status = "OWNED" if committed_level > 0 else ("PENDING" if pending_level > 0 else "OFF")
				if not single_purchase:
					passive_status = "L%d" % pending_level
				var passive_description = passive_data["description"]
				technology_passive_labels[idx].text = passive_data["label"]
				technology_passive_level_labels[idx].text = passive_status
				technology_passive_buttons[idx].disabled = single_purchase and pending_level > 0
				technology_passive_buttons[idx].tooltip_text = "%s\nCost: %d research" % [passive_description, int(passive_state.get_passive_cost(passive_key))]
				technology_passive_labels[idx].tooltip_text = technology_passive_buttons[idx].tooltip_text
				technology_passive_refund_buttons[idx].disabled = pending_level <= committed_level
				technology_passive_refund_buttons[idx].tooltip_text = "Remove uncommitted passive allocation."
	_update_expedition_panel_values()

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
	if hunt_research_button:
		hunt_research_button.visible = showing_research
	_update_expedition_panel_values()

func _on_research_tab_pressed() -> void:
	_set_expedition_tab("research")

func _on_rewards_tab_pressed() -> void:
	_set_expedition_tab("rewards")

func _update_expedition_panel_values() -> void:
	_update_research_panel_values()
	_update_rewards_panel_values()
	_update_prestige_button_state()

func _update_research_panel_values() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if research_points_label:
		research_points_label.text = "RESEARCH %d" % int(game_state.research_points)
	for tile_data in research_upgrade_tiles:
		var upgrade_type = str(tile_data["type"])
		var upgrade_key = str(tile_data["key"])
		var required_ship = str(tile_data.get("requires_ship", ""))
		var level_label = tile_data["level"] as Label
		var buy_button = tile_data["buy"] as Button
		var refund_button = tile_data["refund"] as Button
		var tile = tile_data["tile"] as Control
		var description = str(tile_data["description"])
		var ship_unlocked = required_ship.is_empty() or (game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked(required_ship))
		if tile:
			tile.visible = ship_unlocked
		if not ship_unlocked:
			continue
		if upgrade_type == "cap":
			var cap_level = int(game_state.cap_levels.get(upgrade_key, 0))
			var cap_value = int(game_state.get_research_cap_value(upgrade_key))
			var cap_cost = int(game_state.get_research_cost(upgrade_key))
			var card_unlocked = game_state.is_research_card_unlocked(upgrade_key)
			if level_label:
				level_label.text = "CAP %d" % cap_value if card_unlocked or cap_level > 0 else "HUNT LOCKED"
			if buy_button:
				buy_button.disabled = not card_unlocked or int(game_state.research_points) < cap_cost
				buy_button.tooltip_text = "%s\nCost: %d research" % [description, cap_cost]
			if refund_button:
				refund_button.disabled = cap_level <= 0
				refund_button.tooltip_text = "Refund the most recent rank at its exact purchase cost."
			if tile:
				tile.tooltip_text = "%s\nCost: %d research" % [description, cap_cost]
		elif upgrade_type == "passive":
			var committed_passive_level = int(game_state.get_passive_level(upgrade_key))
			var single_purchase = game_state.has_method("is_single_purchase_passive") and game_state.is_single_purchase_passive(upgrade_key)
			var passive_cost = int(game_state.get_passive_cost(upgrade_key))
			var card_unlocked = game_state.is_research_card_unlocked(upgrade_key)
			var passive_status = "OWNED" if committed_passive_level > 0 else ("%d RP" % passive_cost if card_unlocked else "HUNT LOCKED")
			if not single_purchase:
				passive_status = "L%d" % committed_passive_level
			if level_label:
				level_label.text = passive_status
			if buy_button:
				buy_button.disabled = not card_unlocked or (single_purchase and committed_passive_level > 0) or int(game_state.research_points) < passive_cost
				buy_button.tooltip_text = "%s\nCost: %d research" % [description, passive_cost]
			if refund_button:
				refund_button.visible = false
			if tile:
				tile.tooltip_text = "%s\nCost: %d research" % [description, passive_cost]
	for ship_key in research_ship_lock_labels:
		var lock_label = research_ship_lock_labels[ship_key] as Label
		if lock_label:
			lock_label.visible = not (game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked(str(ship_key)))
	if hunt_research_button:
		var candidates = game_state.get_research_hunt_candidates()
		hunt_research_button.disabled = candidates.is_empty()
		hunt_research_button.text = "All Cards Unlocked" if candidates.is_empty() else "Hunt for Research"

func _format_ship_stat(stat_key: String, value) -> String:
	if stat_key == "click_multiplier":
		return "%.2fx" % float(value)
	if stat_key == "shield":
		return "%.0f%%" % (float(value) * 100.0)
	if stat_key == "global_income_bonus":
		return "+%.1f%%" % (float(value) * 100.0)
	return str(int(value))

func _update_refinery_upgrade_hud() -> void:
	var game_state = get_node_or_null("/root/GameState")
	var unlocked = game_state and game_state.has_method("is_ship_unlocked") and game_state.is_ship_unlocked("refinery")
	var hud_visible = not _has_open_research_overlay()
	if refinery_signal_button:
		refinery_signal_button.visible = unlocked and hud_visible
		refinery_signal_button.text = ">" if refinery_upgrades_visible else "<"
	if refinery_upgrade_label:
		refinery_upgrade_label.visible = unlocked and hud_visible
	if not unlocked or not hud_visible:
		_set_refinery_upgrade_contents_visible(false)
		return
	_set_refinery_upgrade_contents_visible(refinery_upgrades_visible)
	refinery_upgrade_label.text = "ROMIUS UPGRADES"
	var levels: Array = []
	var effects: Array = []
	for index in range(REFINERY_HUD_UPGRADES.size()):
		var upgrade_data = REFINERY_HUD_UPGRADES[index]
		var stat_key = str(upgrade_data["stat_key"])
		var level = int(resource_manager.get_refinery_upgrade_level(stat_key))
		var cap = int(resource_manager.get_refinery_upgrade_cap(stat_key))
		var effect = resource_manager.get_refinery_stat_value(stat_key)
		var cost = int(resource_manager.get_refinery_upgrade_cost(stat_key))
		levels.append(level)
		effects.append(_format_ship_stat(stat_key, effect))
		var button = refinery_upgrade_buttons[index]
		button.text = "+"
		button.disabled = level >= cap
		button.tooltip_text = "Upgrade Romius %s\nLevel: %d / %d\n%s" % [upgrade_data["label"], level, cap, "MAX" if level >= cap else "Cost: %d ore" % cost]
		refinery_upgrade_texts[index].text = str(upgrade_data["label"])
	_update_table_values(refinery_level_texts, refinery_effect_texts, levels, effects)

func _update_ship_upgrade_huds() -> void:
	if resource_manager == null:
		return
	for ship_key in ship_upgrade_huds:
		var hud: Dictionary = ship_upgrade_huds[ship_key]
		for row in hud["rows"]:
			var stat_key = str(row["config"]["stat_key"])
			var level = int(resource_manager.get_ship_upgrade_level(ship_key, stat_key))
			var cap = int(resource_manager.get_ship_upgrade_cap(ship_key, stat_key))
			var cost = int(resource_manager.get_ship_upgrade_cost(ship_key, stat_key))
			var effect = ""
			match stat_key:
				"command_capacity": effect = "+%d drones" % level
				"click_rate": effect = "+%d/sec" % level
				"autocannon": effect = "%.2f DPS" % resource_manager.get_hammond_damage()
				"ammo_conveyor": effect = "%.3fs" % resource_manager.get_hammond_interval()
				"torpedo": effect = "+%d click" % level
				"drone_coordination": effect = "+%d speed" % (level * 5)
				"fighter_drones": effect = "%d x 2 DPS" % level
			row["level"].text = "L%d" % level
			row["effect"].text = effect
			row["button"].disabled = level >= cap
			row["button"].tooltip_text = "%s\nLevel: %d / %d\n%s" % [str(row["config"]["label"]), level, cap, "MAX" if level >= cap else "Cost: %d ore" % cost]

func _update_rewards_panel_values() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
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
				status_label.text = "READY" if can_purchase else "NEED %s ORE" % _format_number(cost)
			else:
				status_label.text = "LOCKED"
		if attempt_button:
			attempt_button.disabled = not can_purchase
			attempt_button.text = "Completed" if completed else "Prestige"
			attempt_button.tooltip_text = "Reward permanently active." if completed else ("Consume %s ore and reset this run." % _format_number(cost) if is_next else "Complete the previous prestige first.")

func _update_prestige_button_state() -> void:
	var game_state = get_node_or_null("/root/GameState")
	var can_prestige = game_state and resource_manager and game_state.has_method("can_prestige") and game_state.can_prestige(resource_manager.total_resources)
	var tooltip = "Accumulate the ore required by the next reward." if not can_prestige else "Consume ore, reset the run, and increase prestige."
	for button in [prestige_button]:
		if button:
			button.disabled = not can_prestige
			button.tooltip_text = tooltip

func _on_prestige_purchase_pressed(target_prestige: int) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null or target_prestige != int(game_state.prestige_level) + 1:
		_show_action("Complete the previous prestige first")
		return
	_perform_prestige(false)

func _on_hunt_research_pressed() -> void:
	if resource_manager and resource_manager.has_method("start_research_hunt") and resource_manager.start_research_hunt():
		return
	_show_action("No research card is currently available to hunt")

func _refresh_drones_after_reward() -> void:
	if resource_manager == null or not resource_manager.has_method("configure_drone"):
		return
	var parent = resource_manager.get_parent()
	if parent and parent.has_node("Drones"):
		for drone in parent.get_node("Drones").get_children():
			resource_manager.configure_drone(drone)

func _on_research_tile_pressed(upgrade_type: String, key: String, direction: int) -> void:
	if direction > 0:
		if upgrade_type == "cap":
			_upgrade_research(key)
		else:
			_upgrade_passive(key)
	else:
		if upgrade_type == "cap":
			_refund_research(key)
		else:
			_refund_passive(key)
	_update_expedition_panel_values()

func _set_prestige_visibility(visible: bool) -> void:
	prestige_visible = visible
	if prestige_panel:
		prestige_panel.visible = visible
	_set_mining_hud_visibility(not _has_open_research_overlay())
	if prestige_toggle_button:
		prestige_toggle_button.visible = visible
	if prestige_research_label:
		prestige_research_label.visible = visible
	if prestige_button:
		prestige_button.visible = visible
	for node_name in ["ClickAmountCapResearchLabel", "ClickMultiplierCapResearchLabel", "FlagshipSpeedCapResearchLabel", "CommandCapacityCapResearchLabel", "DroneMiningCapResearchLabel", "DroneMiningSpeedCapResearchLabel", "DroneMultiplierCapResearchLabel", "CarryCapacityCapResearchLabel", "DroneSpeedCapResearchLabel", "ClickAmountCapResearchButton", "ClickMultiplierCapResearchButton", "FlagshipSpeedCapResearchButton", "CommandCapacityCapResearchButton", "DroneMiningCapResearchButton", "DroneMiningSpeedCapResearchButton", "DroneMultiplierCapResearchButton", "CarryCapacityCapResearchButton", "DroneSpeedCapResearchButton", "ClickAmountCapResearchRefundButton", "ClickMultiplierCapResearchRefundButton", "FlagshipSpeedCapResearchRefundButton", "CommandCapacityCapResearchRefundButton", "DroneMiningCapResearchRefundButton", "DroneMiningSpeedCapResearchRefundButton", "DroneMultiplierCapResearchRefundButton", "CarryCapacityCapResearchRefundButton", "DroneSpeedCapResearchRefundButton"]:
		var node = prestige_panel.get_node_or_null(node_name) if prestige_panel else null
		if node:
			node.visible = visible

func _on_prestige_toggle_pressed() -> void:
	var next_visible = not prestige_visible
	if next_visible:
		_set_research_visibility(false)
	_set_prestige_visibility(next_visible)

func _set_research_visibility(visible: bool) -> void:
	research_visible = visible
	if research_panel:
		research_panel.visible = visible
	if research_toggle_button:
		research_toggle_button.visible = visible
	if research_points_label:
		research_points_label.visible = visible
	_set_mining_hud_visibility(not _has_open_research_overlay())
	if visible:
		_update_expedition_panel_values()

func _on_research_toggle_pressed() -> void:
	var next_visible = not research_visible
	if next_visible:
		_set_prestige_visibility(false)
	_set_research_visibility(next_visible)

func _has_open_research_overlay() -> bool:
	return prestige_visible or research_visible

func _set_mining_hud_visibility(visible: bool) -> void:
	if right_ore_label:
		right_ore_label.visible = visible
	if dev_panel:
		dev_panel.visible = visible
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
	_update_refinery_upgrade_hud()
	if not visible:
		for hud in ship_upgrade_huds.values():
			hud["panel"].visible = false
			hud["toggle"].visible = false
			hud["title"].visible = false
			for row in hud["rows"]:
				for control_key in ["button", "name", "level", "effect"]:
					row[control_key].visible = false
	else:
		_layout_hud()

func _set_control_buttons_visibility(visible: bool) -> void:
	for node_name in ["CenterButton", "SendButton", "Send1Button", "Send3Button", "Send5Button", "Send10Button", "SplitButton", "BattleButton", "NewFieldButton"]:
		var node = get_node_or_null(node_name) as Control
		if node:
			node.visible = visible

func _on_controls_signal_pressed() -> void:
	control_buttons_visible = not control_buttons_visible
	_set_control_buttons_visibility(control_buttons_visible and not _has_open_research_overlay())
	if controls_label:
		controls_label.visible = control_buttons_visible and not _has_open_research_overlay()
	if controls_toggle_button:
		controls_toggle_button.text = ">" if control_buttons_visible else "<"

func _on_dev_add_ore_pressed() -> void:
	if resource_manager and resource_manager.has_method("add_resources"):
		resource_manager.add_resources(1000.0)
		_show_action("Dev: +1,000 ore")

func _on_dev_add_research_pressed() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("add_research_points"):
		game_state.add_research_points(10)
		_update_expedition_panel_values()
		_show_action("Dev: +10 research")

func _on_dev_prestige_pressed() -> void:
	_perform_prestige(true)

func _on_prestige_pressed() -> void:
	_perform_prestige(false)

func _perform_prestige(force_prestige: bool) -> void:
	if resource_manager and resource_manager.has_method("purchase_prestige"):
		if resource_manager.purchase_prestige(force_prestige):
			var game_state = get_node_or_null("/root/GameState")
			var prestige = int(game_state.prestige_level) if game_state else 0
			_show_action("Prestige %d: ore upgrades cleared" % prestige)
			_set_prestige_visibility(false)
			_set_research_visibility(false)
			_layout_hud()
		else:
			_show_action("Not enough ore for the next prestige")
	_update_expedition_panel_values()

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

func _on_research_upgrade_click_multiplier() -> void:
	_upgrade_research("click_multiplier")

func _on_research_upgrade_speed() -> void:
	_upgrade_research("speed")

func _on_research_upgrade_drones() -> void:
	_upgrade_research("drones")

func _on_research_upgrade_mining() -> void:
	_upgrade_research("mining")

func _on_research_upgrade_mining_speed() -> void:
	_upgrade_research("mining_speed")

func _on_research_upgrade_flagship_speed() -> void:
	_upgrade_research("flagship_speed")

func _on_research_upgrade_drone_multiplier() -> void:
	_upgrade_research("drone_multiplier")

func _on_research_upgrade_capacity() -> void:
	_upgrade_research("capacity")

func _on_research_refund_click_output() -> void:
	_refund_research("click_output")

func _on_research_refund_click_multiplier() -> void:
	_refund_research("click_multiplier")

func _on_research_refund_speed() -> void:
	_refund_research("speed")

func _on_research_refund_drones() -> void:
	_refund_research("drones")

func _on_research_refund_mining() -> void:
	_refund_research("mining")

func _on_research_refund_mining_speed() -> void:
	_refund_research("mining_speed")

func _on_research_refund_flagship_speed() -> void:
	_refund_research("flagship_speed")

func _on_research_refund_drone_multiplier() -> void:
	_refund_research("drone_multiplier")

func _on_research_refund_capacity() -> void:
	_refund_research("capacity")

func _upgrade_passive(key: String) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.buy_passive_upgrade(key):
		_show_action("Permanent research purchased and active")
	else:
		_show_action("Not enough research or already owned")

func _refund_passive(key: String) -> void:
	_show_action("Permanent research cannot be refunded")

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

func _build_ship_upgrade_hud(ship_key: String, panel_style: StyleBoxFlat) -> void:
	var config: Dictionary = SHIP_HUD_UPGRADES[ship_key]
	var panel = Panel.new()
	panel.name = "%sUpgradePanel" % ship_key.to_pascal_case()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	add_child(panel)
	var toggle = Button.new()
	toggle.text = "<"
	toggle.tooltip_text = "Toggle %s" % str(config["title"]).to_lower()
	toggle.size = Vector2(28.0, 28.0)
	add_child(toggle)
	toggle.pressed.connect(Callable(self, "_on_ship_upgrade_toggle").bind(ship_key))
	var title = Label.new()
	title.text = str(config["title"])
	title.size = Vector2(300.0, 24.0)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", config["color"])
	add_child(title)
	var rows: Array = []
	for row_data in config["rows"]:
		var button = Button.new()
		button.text = "+"
		button.size = Vector2(30.0, 26.0)
		add_child(button)
		button.pressed.connect(Callable(self, "_on_upgrade_ship_stat").bind(ship_key, str(row_data["stat_key"])))
		var name_label = Label.new()
		name_label.text = str(row_data["label"])
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", config["color"])
		add_child(name_label)
		var level_label = Label.new()
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.add_theme_color_override("font_color", config["color"])
		add_child(level_label)
		var effect_label = Label.new()
		effect_label.add_theme_font_size_override("font_size", 12)
		effect_label.add_theme_color_override("font_color", Color("d9f4ff"))
		add_child(effect_label)
		rows.append({"config": row_data, "button": button, "name": name_label, "level": level_label, "effect": effect_label})
	ship_upgrade_huds[ship_key] = {"panel": panel, "toggle": toggle, "title": title, "rows": rows}

func _on_ship_upgrade_toggle(ship_key: String) -> void:
	ship_upgrades_visible[ship_key] = not bool(ship_upgrades_visible.get(ship_key, false))
	_layout_hud()

func _on_upgrade_ship_stat(ship_key: String, stat_key: String) -> void:
	if resource_manager and resource_manager.upgrade_ship_stat(ship_key, stat_key):
		_show_action("%s %s upgraded" % [ship_key.capitalize(), stat_key.capitalize()])
	else:
		_show_action("Upgrade unavailable")

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
	elif section == "drone":
		drone_separators.append(separator)
		drone_level_texts.append(level_label)
		drone_effect_texts.append(effect_label)
	else:
		refinery_separators.append(separator)
		refinery_level_texts.append(level_label)
		refinery_effect_texts.append(effect_label)
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
	_set_mining_hud_visibility(not _has_open_research_overlay())
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
	_set_mining_hud_visibility(not _has_open_research_overlay())
	if drone_signal_button:
		drone_signal_button.text = ">" if drone_upgrades_visible else "<"

func _set_drone_upgrade_contents_visible(visible: bool) -> void:
	for label in [mining_text, mining_speed_text, drone_multiplier_text, capacity_text, speed_text]:
		if label:
			label.visible = visible
	for label in drone_level_texts + drone_effect_texts:
		if label:
			label.visible = visible
	for separator in drone_separators:
		if separator:
			separator.visible = visible
	for button in [mining_button, mining_speed_button, drone_multiplier_button, capacity_button, speed_button]:
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
		_show_action("Not enough ore or upgrade at cap")
	_update_refinery_upgrade_hud()

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
	_buy_upgrade("upgrade_click_multiplier", "Click rate upgraded")

func _on_upgrade_mining():
	_buy_upgrade("upgrade_mining", "Mining power upgraded")

func _on_upgrade_mining_speed():
	_buy_upgrade("upgrade_mining_speed", "Mining speed upgraded")

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
