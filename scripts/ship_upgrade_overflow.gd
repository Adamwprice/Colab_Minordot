extends RefCounted

# Effective level at which every benefit of an upgrade reaches its hard limit.
# Do not list visual limits or upgrades with other, still-growing effects.
static func hard_cap(ship: String, stat: String) -> float:
	match ship + "/" + stat:
		"starburst/combat_engines": return 14.0
		"stapledon/flare_catcher": return 18.0
		"hammond/arming_time", "ambrossa/trader_reputation": return log(0.1) / log(0.99)
		"ravager/magnetic_lining": return log(0.2) / log(0.98)
	return INF

static func resolve(ship: String, purchased: Dictionary, caps: Dictionary) -> Dictionary:
	var effective := {}
	var overflow := 0.0
	for stat in purchased:
		var level = float(purchased[stat])
		var limit = min(hard_cap(ship, stat), float(caps[stat]))
		effective[stat] = min(level, limit)
		overflow += max(0.0, level - limit)
	# Redistribute excess again when a recipient fills during allocation.
	for iteration in range(purchased.size() + 1):
		var recipients: Array = []
		for stat in effective:
			if float(effective[stat]) + 0.000001 < min(hard_cap(ship, stat), float(caps[stat])):
				recipients.append(stat)
		if recipients.is_empty() or overflow <= 0.000001:
			break
		var share = overflow / recipients.size()
		for stat in recipients:
			var gain = min(share, min(hard_cap(ship, stat), float(caps[stat])) - float(effective[stat]))
			effective[stat] += gain
			overflow -= gain
	return effective
