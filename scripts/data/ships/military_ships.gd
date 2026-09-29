class_name MilitaryShipData
extends RefCounted

const SHIPS := {
	"starburst": {
		"rank": 2, "name": "Starburst", "category": "military",
		"description": "A fast strike craft built to make repeated attack runs.",
		"ore": [
			{"label": "COMBAT ENGINES", "stat": "combat_engines", "cost": 2350, "effect": "-0.5s Starburst attack-run interval (minimum 3s)"},
			{"label": "SALVO", "stat": "salvo", "cost": 1130, "effect": "+1 battle click damage while Starburst is within attack range"},
			{"label": "TARGETING ATTACK", "stat": "targeting_attack", "cost": 900, "effect": "+10% battle click and Starburst contact damage"},
			{"label": "TIGHT MANOEUVRES", "stat": "tight_manoeuvres", "cost": 1800, "effect": "+8% tighter transit phases, extending Starburst's in-range attack window"}
		],
		"research": [
			{"label": "Opening Salvo", "key": "starburst_opening_salvo", "description": "Starburst attacks immediately when a battle begins.", "difficulty": 2.5},
			{"label": "Return Run", "key": "starburst_return_run", "description": "Double Starburst damage during the latter half of each close attack run.", "difficulty": 3.0}
		],
		"offset": Vector2(42, -34)
	},
	"hammond": {
		"rank": 8, "name": "Hammond", "category": "military",
		"description": "A mid-range corvette equipped with kinetic and photon artillery.",
		"ore": [
			{"label": "LORI CANNONS", "stat": "lori_cannons", "cost": 5120, "effect": "+2 damage per shot"},
			{"label": "INTENSITY", "stat": "intensity", "cost": 4200, "effect": "+1 Hammond shot per volley"},
			{"label": "ARMING SEQUENCES", "stat": "arming_sequences", "cost": 1800, "effect": "-2% Hammond firing interval (minimum 1s)"},
			{"label": "SALVO BAYS", "stat": "salvo_bays", "cost": 2100, "effect": "+1 damage to every manual and Autor battle click"}
		],
		"research": [
			{"label": "Fighter Bays", "key": "hammond_fighter_bays", "description": "Install a fixed wing of five fighters.", "difficulty": 4.5}
		],
		"offset": Vector2(40, -56)
	},
	"jackal": {
		"rank": 11, "name": "Jackal", "category": "military",
		"description": "Elite fighter squadrons that exploit weak points and recover at the fleet.",
		"ore": [
			{"label": "COHORTS", "stat": "cohorts", "cost": 2600, "effect": "+0.25 fighter strength"},
			{"label": "STIMPACK", "stat": "stimpack", "cost": 1800, "effect": "+5% recovery speed"},
			{"label": "RATIONS", "stat": "rations", "cost": 1500, "effect": "+1 health recovered"},
			{"label": "STRAFE", "stat": "strafe", "cost": 2200, "effect": "+5% attack speed"}
		],
		"research": [
			{"label": "Plating", "key": "jackal_plating", "description": "Increase Jackal fighter hit points.", "difficulty": 4.5},
			{"label": "Speed", "key": "jackal_speed", "description": "Reduce fighter travel time between runs.", "difficulty": 4.5},
			{"label": "Opening Salvo", "key": "jackal_opening_salvo", "description": "Launch one attack while approaching the enemy.", "difficulty": 5.0}
		],
		"offset": Vector2(58, -22)
	},
	"ravager": {
		"rank": 14, "name": "Ravager", "category": "military",
		"description": "Heavy artillery built around a massive long-range cannon.",
		"ore": [
			{"label": "MAGNETIC LINING", "stat": "magnetic_lining", "cost": 4200, "effect": "-2% charge interval"},
			{"label": "IMPACT RADIUS", "stat": "impact_radius", "cost": 3600, "effect": "+5% area damage"},
			{"label": "MATERIAL", "stat": "material", "cost": 5000, "effect": "+5 artillery damage"}
		],
		"research": [
			{"label": "Siege", "key": "ravager_siege", "description": "Launch two attacks on the first artillery cycle.", "difficulty": 5.5},
			{"label": "Cracking Rounds", "key": "ravager_cracking_rounds", "description": "Each round weakens enemy armor.", "difficulty": 6.0},
			{"label": "Polarised Material", "key": "ravager_polarised_material", "description": "Reduce enemy shields by a flat percentage.", "difficulty": 6.0}
		],
		"offset": Vector2(72, 8)
	},
}
