class_name SupportShipData
extends RefCounted

const SHIPS := {
	"minotard": {
		"rank": 3, "name": "Minotard", "category": "support",
		"description": "A snub-nosed mining barge with twin forward stripping arms. Mines 10 Credits per cycle before upgrades directly into fleet storage.",
		"ore": [
			{"label": "MINING ARRAY", "stat": "mining_array", "cost": 3000, "effect": "+10 mined per cycle"},
			{"label": "OPTIMISED MINING", "stat": "optimized_mining", "cost": 2275, "effect": "+5% mining speed"},
			{"label": "INPUT RATE", "stat": "input_rate", "cost": 125, "effect": "+1 held activation/sec and +1 manual click/sec in mining and battle"},
			{"label": "SPEED", "stat": "speed", "cost": 100, "effect": "+10 Minotard movement speed"}
		],
		"research": [
			{"label": "Ion Thrusters", "key": "minotard_ion_thrusters", "description": "Double Minotard movement speed.", "difficulty": 2.5},
			{"label": "Optical Lens A", "key": "minotard_optical_lens", "description": "Recover 10% additional Credits from Minotard extraction.", "difficulty": 3.0},
			{"label": "Bifocal Lens", "key": "minotard_bifocal_lens", "description": "Increase Minotard mining speed by 5%.", "difficulty": 3.0}
		],
		"offset": Vector2(-46, 26)
	},
	"atlas": {
		"rank": 4, "name": "Atlas", "category": "support",
		"description": "A linked industrial hauler that receives drone deposits in the field.",
		"ore": [
			{"label": "COMMAND CAP", "stat": "command_capacity", "cost": 500, "effect": "+1 mining drone"},
			{"label": "INDUSTRIAL LINK", "stat": "industrial_link", "cost": 2500, "effect": "+10% mining speed to drones within 2,000 units of Atlas"},
			{"label": "STORAGE BINS", "stat": "storage_bins", "cost": 200, "effect": "+10 cargo capacity to every mining drone"},
			{"label": "OPTIMISER LENS", "stat": "optimizer_lens", "cost": 125, "effect": "+100% Credit income created within Atlas work range"},
			{"label": "SPEED", "stat": "speed", "cost": 100, "effect": "+10 Atlas movement speed"}
		],
		"research": [
			{"label": "Calculated Ejector", "key": "atlas_calculated_ejector", "description": "Drones can deposit from farther away while within Atlas range.", "difficulty": 3.0},
			{"label": "Industrial Thruster", "key": "atlas_industrial_thruster", "description": "Add 20 Atlas movement speed.", "difficulty": 2.5},
			{"label": "Ion Thruster", "key": "atlas_ion_thruster", "description": "Double Atlas movement speed.", "difficulty": 3.5}
		],
		"offset": Vector2(-58, 14)
	},
	"refinery": {
		"rank": 5, "name": "Romius", "category": "support",
		"description": "A heavy industrial furnace ship refining every source of fleet income.",
		"ore": [
			{"label": "FURNACE", "stat": "furnace", "cost": 2500, "effect": "+2% support-ship income"},
			{"label": "RECLAMATION", "stat": "reclamation", "cost": 990, "effect": "+100 per 1,000 collected"},
			{"label": "SHELL FACTORY", "stat": "shell_factory", "cost": 2100, "effect": "+1% Hammond firing speed"}
		],
		"research": [
			{"label": "Heavy Furnace", "key": "refinery_heavy_furnaces", "description": "Double Romius Furnace bonuses.", "difficulty": 3.0},
			{"label": "Recycling", "key": "refinery_recycling", "description": "Reduce every civilian ship's Credit-upgrade cost by 10%.", "difficulty": 3.2},
			{"label": "Waste Processes", "key": "refinery_waste_processes", "description": "Produce 0.25 bonus Credits for every 10 Credits earned.", "difficulty": 3.0}
		],
		"offset": Vector2(-14, 32)
	},
	"drone_carrier": {
		"rank": 10, "name": "Brooder", "category": "support",
		"description": "A carrier with extensive command systems and expandable fighter bays.",
		"base_cap": 50,
		"ore": [
			{"label": "COMMAND CAP", "stat": "command_capacity", "cost": 1170, "effect": "+1 mining drone"},
			{"label": "FIGHTER BAYS", "stat": "fighter_bays", "cost": 3365, "effect": "+1 battle fighter"},
			{"label": "ACCELERATION", "stat": "acceleration", "cost": 1200, "effect": "+0.5% outbound drone speed"},
			{"label": "OUTPUT", "stat": "output", "cost": 50, "effect": "+1 Flagship mining output and base battle click damage"},
			{"label": "INPUT RATE", "stat": "input_rate", "cost": 1000, "effect": "+1 held activation/sec and +1 manual click/sec in mining and battle"}
		],
		"research": [
			{"label": "Military Command", "key": "brooder_military_command", "description": "Unlock advanced fleet formation and attack controls.", "difficulty": 4.5},
			{"label": "Drone Reconfiguration", "key": "brooder_drone_reconfiguration", "description": "Increase every drone type's primary stats by 5%.", "difficulty": 5.0},
			{"label": "Last Effort", "key": "brooder_last_effort", "description": "A dying companion rushes the enemy and deals damage equal to its maximum hull.", "difficulty": 5.2},
			{"label": "Readiness", "key": "brooder_readiness", "description": "Begin and return from battle with at least five mining drones and one fighter.", "difficulty": 5.3},
			{"label": "Cooperation", "key": "brooder_cooperation", "description": "Every 10 active companions add 1 Flagship input per second.", "difficulty": 5.5}
		],
		"offset": Vector2(-62, 38)
	},
	"boschore": {
		"rank": 15, "name": "Boschore", "category": "support",
		"description": "A slender support entourage carrying specialized gas-harvesting drones.",
		"ore": [
			{"label": "VACUUM COMMAND", "stat": "vacuum_command_capacity", "cost": 1550, "effect": "+1 vacuum drone"},
			{"label": "EXTENSION", "stat": "extension", "cost": 2300, "effect": "+250 Tobias range"},
			{"label": "EXCITER", "stat": "exciter", "cost": 2700, "effect": "+2% Tobias efficiency per drone"}
		],
		"research": [
			{"label": "Dust Bunnies", "key": "boschore_dust_bunnies", "description": "Gain 100 excess gas each Tobias cycle.", "difficulty": 5.5},
			{"label": "Nozzle Selection", "key": "boschore_nozzle_selection", "description": "Triple specialized gas collection speed.", "difficulty": 6.0}
		],
		"offset": Vector2(-76, 20)
	},
	"stapledon": {
		"rank": 18, "name": "Stapledon", "category": "support",
		"description": "A stacked solar-drone carrier collecting energy from the system star.",
		"ore": [
			{"label": "DYSON CAPACITY", "stat": "dyson_capacity", "cost": 1750, "effect": "+1 Dyson drone"},
			{"label": "SOLAR COLLECTORS", "stat": "solar_collectors", "cost": 4250, "effect": "+5% solar income"},
			{"label": "FLARE CATCHER", "stat": "flare_catcher", "cost": 5000, "effect": "Faster flare income"}
		],
		"research": [
			{"label": "Monocrystalline", "key": "stapledon_monocrystalline", "description": "Increase solar income by 20%.", "difficulty": 6.0},
			{"label": "Nanofilm", "key": "stapledon_nanofilm", "description": "Reduce solar collection time by 2%.", "difficulty": 6.0}
		],
		"offset": Vector2(-96, 10)
	},
}
