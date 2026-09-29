class_name FoundationShipData
extends RefCounted

const SHIPS := {
	"flagship": {
		"rank": 0, "name": "Flagship", "category": "civilian",
		"description": "The fleet's first ship and the core of every large expedition.",
		"cap_key": "flagship_general_cap",
		"research": [
			{"label": "Ion Thrusters", "key": "flagship_ion_thrusters", "description": "Multiply Flagship movement speed by 1.5.", "difficulty": 2.5},
			{"label": "Autor", "key": "flagship_autor", "description": "Toggle automatic held mining and attacks. Manual input remains active.", "difficulty": 1.8},
			{"label": "Development Protocol", "key": "flagship_development_protocol", "description": "Toggle buying the cheapest enabled ore upgrade every 5 seconds.", "difficulty": 2.0},
			{"label": "Readiness", "key": "flagship_readiness", "description": "Keep at least one Flagship mining drone active after prestige and battles without using command capacity.", "difficulty": 2.2}
		]
	},
	"mining_drone": {
		"rank": 0, "name": "Mining Drones", "category": "drones",
		"description": "Shared mining-drone systems used throughout the fleet.",
		"cap_key": "mining_drone_general_cap",
		"research": [
			{"label": "Mining Lasers", "key": "drone_mining_lasers", "description": "Double mining-drone extraction output.", "difficulty": 2.0},
			{"label": "Ion Thrusters", "key": "drone_ion_thrusts", "description": "Triple mining-drone movement speed.", "difficulty": 2.5}
		]
	},
}
