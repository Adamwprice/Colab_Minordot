class_name ShipStatModifier
extends Resource

enum Operation {
	FLAT,
	ADDITIVE_PERCENT,
	MULTIPLY
}

@export var source_id: StringName
@export var stat: StringName
@export var operation: Operation = Operation.FLAT
@export var value: float = 0.0
@export var target_ship_id: StringName
@export_enum("Any:-1", "Civilian:0", "Military:1") var target_category: int = -1
@export_flags("Mining", "Combat", "Command", "Support", "Utility", "Refining", "Drone") var required_roles: int = 0
@export var require_all_roles: bool = true

func matches(profile: ShipProfile, requested_stat: StringName) -> bool:
	if profile == null or stat != requested_stat:
		return false
	if not target_ship_id.is_empty() and target_ship_id != profile.ship_id:
		return false
	if target_category >= 0 and target_category != int(profile.category):
		return false
	if require_all_roles:
		return profile.has_all_roles(required_roles)
	return profile.has_any_role(required_roles)
