class_name UtilityShipData
extends RefCounted

const SHIPS := {
	"kradle": {
		"rank": 1, "name": "Kradle", "category": "utility",
		"description": "An automated drone-support container and antenna platform.",
		"ore": [
			{"label": "OUTPUT", "stat": "output", "cost": 50, "effect": "+1 Flagship mining output and base battle click damage"},
			{"label": "INPUT RATE", "stat": "input_rate", "cost": 1000, "effect": "+1 held activation/sec and +1 manual click/sec in mining and battle"},
			{"label": "COMMAND CAP", "stat": "command_capacity", "cost": 500, "effect": "+1 Kradle mining drone"},
			{"label": "ADJUSTER", "stat": "adjuster", "cost": 900, "effect": "+100 Flagship mining-aura radius"}
		],
		"research": [
			{"label": "Joint Focus", "key": "kradle_manual_control", "description": "Unlock Joint Focus and Split Focus drone controls.", "difficulty": 2.0},
			{"label": "Local Antenna", "key": "kradle_local_antenna", "description": "Every 300 seconds, attempt to detect a local asteroid containing 100 Credits.", "difficulty": 2.5}
		],
		"offset": Vector2(-28, 18)
	},
	"gethica": {
		"rank": 6, "name": "Gethica", "category": "utility",
		"description": "A science vessel for richer systems and fleet coordination.",
		"ore": [
			{"label": "SPECTROMETER", "stat": "spectrometer", "cost": 1750, "effect": "+500 Credits to every normal node"},
			{"label": "LOCAL SFC", "stat": "local_sfc", "cost": 600, "effect": "+10 movement speed to every fleet ship"},
			{"label": "DRONE FC", "stat": "drone_fc", "cost": 500, "effect": "+5 movement speed to every companion"},
			{"label": "ADJUSTER", "stat": "adjuster", "cost": 900, "effect": "+100 Flagship mining-aura radius"}
		],
		"research": [
			{"label": "Scan Enrichment", "key": "gethica_scan_enrichment", "description": "Enriched pink nodes contain 5,000 Credits.", "difficulty": 3.0},
			{"label": "Deep Space Arrays", "key": "gethica_deep_space_arrays", "description": "Generate five additional normal nodes in every future field.", "difficulty": 3.0}
		],
		"offset": Vector2(-52, -12)
	},
	"tobias": {
		"rank": 12, "name": "Tobias", "category": "utility",
		"description": "A cylindrical gas harvester collecting directly into fleet storage.",
		"ore": [
			{"label": "COMPRESSOR", "stat": "compressor", "cost": 3000, "effect": "+5% gas collection speed"},
			{"label": "DUAL CHAMBER", "stat": "dual_chamber", "cost": 5000, "effect": "+10 gas per cycle"},
			{"label": "INPUT RATE", "stat": "input_rate", "cost": 125, "effect": "+1 held activation/sec and +1 manual click/sec in mining and battle"},
			{"label": "ELONGATION", "stat": "elongation", "cost": 2270, "effect": "+100 Tobias gas-collection range"},
			{"label": "SPEED", "stat": "speed", "cost": 800, "effect": "+10 Tobias movement speed"}
		],
		"research": [
			{"label": "Vacuum Drone Bays", "key": "tobias_vacuum_drone_bays", "description": "Deploy five fixed vacuum drones for gas collection.", "difficulty": 5.0},
			{"label": "Helium-injected Fuel", "key": "tobias_helium_fuel", "description": "Significantly increase Tobias movement speed.", "difficulty": 5.0}
		],
		"offset": Vector2(-60, -28)
	},
	"parallax": {
		"rank": 13, "name": "Parallax", "category": "utility",
		"description": "A celestial-navigation vessel coordinating fleet movement and positioning.",
		"ore": [
			{"label": "MATILDA ARRAY", "stat": "matilda_array", "cost": 2800, "effect": "+1 normal node per field"},
			{"label": "COORDINATOR", "stat": "coordinator", "cost": 1900, "effect": "+2 movement speed to every fleet ship"},
			{"label": "BOOSTER", "stat": "booster", "cost": 2400, "effect": "+2% mining speed to drones within 2,000 units of Parallax"}
		],
		"research": [
			{"label": "Armilla Designator", "key": "parallax_armilla_designator", "description": "Reduce the delay before travelling to the next field.", "difficulty": 5.0},
			{"label": "Broad Tether", "key": "parallax_broad_tether", "description": "Destroyed drones have a 5% chance to be recalled after battle.", "difficulty": 5.5}
		],
		"offset": Vector2(-72, -4)
	},
}
