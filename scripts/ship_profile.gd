class_name ShipProfile
extends Resource

enum Category {
	CIVILIAN,
	MILITARY,
	SUPPORT,
	UTILITY
}

enum Role {
	MINING = 1,
	COMBAT = 2,
	COMMAND = 4,
	SUPPORT = 8,
	UTILITY = 16,
	REFINING = 32,
	DRONE = 64
}

const STAT_UPGRADE_CAP := &"upgrade_cap"
const STAT_MAX_HP := &"max_hp"
const STAT_ARMOR := &"armor"
const STAT_SHIELD := &"shield"
const STAT_STARTING_COMMAND_LEVEL := &"starting_command_level"
const STAT_COMMAND_CAPACITY := &"command_capacity"
const STAT_MOVE_SPEED := &"move_speed"
const STAT_MINING_CLICK_OUTPUT := &"mining_click_output"
const STAT_CLICK_RATE := &"click_rate"
const STAT_BATTLE_CLICK_DAMAGE := &"battle_click_damage"
const STAT_BATTLE_DAMAGE := &"battle_damage"
const STAT_MINING_AMOUNT := &"mining_amount"
const STAT_MINING_SPEED := &"mining_speed"
const STAT_ORE_MULTIPLIER := &"ore_multiplier"
const STAT_CARRY_CAPACITY := &"carry_capacity"
const STAT_CLICK_MULTIPLIER := &"click_multiplier"
const STAT_GLOBAL_INCOME_BONUS := &"global_income_bonus"

@export var ship_id: StringName
@export var display_name: String
@export var category: Category = Category.CIVILIAN
@export_flags("Mining", "Combat", "Command", "Support", "Utility", "Refining", "Drone") var roles: int = 0

func has_role(role: Role) -> bool:
	return (roles & int(role)) != 0

func has_any_role(role_mask: int) -> bool:
	return role_mask == 0 or (roles & role_mask) != 0

func has_all_roles(role_mask: int) -> bool:
	return role_mask == 0 or (roles & role_mask) == role_mask

func get_category_name() -> String:
	return Category.keys()[int(category)].capitalize()

func get_role_names() -> Array[String]:
	var names: Array[String] = []
	for role_name in Role:
		if has_role(Role[role_name]):
			names.append(str(role_name).capitalize())
	return names
