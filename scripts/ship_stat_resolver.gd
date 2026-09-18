class_name ShipStatResolver
extends RefCounted

static func resolve(base_value: float, profile: ShipProfile, stat: StringName, modifiers: Array[ShipStatModifier]) -> float:
	var flat_bonus := 0.0
	var additive_percent := 0.0
	var multiplier := 1.0
	for modifier in modifiers:
		if modifier == null or not modifier.matches(profile, stat):
			continue
		match modifier.operation:
			ShipStatModifier.Operation.FLAT:
				flat_bonus += modifier.value
			ShipStatModifier.Operation.ADDITIVE_PERCENT:
				additive_percent += modifier.value
			ShipStatModifier.Operation.MULTIPLY:
				multiplier *= modifier.value
	return (base_value + flat_bonus) * (1.0 + additive_percent) * multiplier
