class_name ShipCatalog
extends RefCounted

const CATEGORY_COLORS := {
	"civilian": Color("f4d06f"),
	"military": Color("ff7770"),
	"support": Color("7ce0b8"),
	"utility": Color("c3a6ff")
}

const PRESTIGE_COSTS := {
	1: 50000, 2: 90000, 3: 162000, 4: 291600, 5: 524880,
	6: 944784, 7: 1700611, 8: 3061100, 9: 5509980, 10: 9917965,
	11: 17852336, 12: 32134205, 13: 57841569, 14: 104114824, 15: 187406684,
	16: 337332031, 17: 607197655, 18: 1092955780, 19: 1967320404, 20: 3541176727
}

const SHIPS := {
	"flagship": {
		"rank": 0, "name": "Flagship", "category": "civilian",
		"description": "The fleet's first ship and the core of every large expedition.",
		"cap_key": "flagship_general_cap",
		"research": [
			{"label": "Fleet Maneuver", "key": "flagship_fleet_maneuver", "description": "Automatically approach the nearest mineable node unless given another order.", "difficulty": 2.0},
			{"label": "Development Protocol", "key": "flagship_development_protocol", "description": "Automatically buy the cheapest affordable ore upgrade every 5 seconds.", "difficulty": 2.5},
			{"label": "Picket Array", "key": "flagship_picket_array", "description": "Deal 2 passive damage per second in battle.", "difficulty": 2.0}
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
	"kradle": {
		"rank": 1, "name": "Kradle", "category": "utility",
		"description": "An automated drone-support container and antenna platform.",
		"ore": [
			{"label": "OUTPUT", "stat": "output", "cost": 50, "effect": "+1 click output"},
			{"label": "INPUT RATE", "stat": "input_rate", "cost": 1000, "effect": "+1 held and manual input/sec"},
			{"label": "COMMAND CAP", "stat": "command_capacity", "cost": 500, "effect": "+1 mining drone"}
		],
		"research": [
			{"label": "Joint Focus", "key": "kradle_manual_control", "description": "Unlock Joint Focus and Split Focus drone controls.", "difficulty": 2.0},
			{"label": "Local Antenna", "key": "kradle_local_antenna", "description": "Every 300 seconds, attempt to detect a local 100-ore asteroid.", "difficulty": 2.5}
		],
		"offset": Vector2(-28, 18)
	},
	"starburst": {
		"rank": 2, "name": "Starburst", "category": "military",
		"description": "A fast strike craft built to make repeated attack runs.",
		"ore": [
			{"label": "COMBAT ENGINES", "stat": "combat_engines", "cost": 2350, "effect": "+0.5 combat speed"},
			{"label": "SALVO", "stat": "salvo", "cost": 1130, "effect": "+1 missile damage every 5 clicks"},
			{"label": "TARGETING ATTACK", "stat": "targeting_attack", "cost": 900, "effect": "+0.1 strike multiplier"}
		],
		"research": [
			{"label": "Opening Salvo", "key": "starburst_opening_salvo", "description": "Starburst attacks immediately when a battle begins.", "difficulty": 2.5},
			{"label": "Return Run", "key": "starburst_return_run", "description": "Starburst launches a second strike during each attack run.", "difficulty": 3.0}
		],
		"offset": Vector2(42, -34)
	},
	"minotard": {
		"rank": 3, "name": "Minotard", "category": "support",
		"description": "A snub-nosed mining barge with twin forward stripping arms.",
		"ore": [
			{"label": "MINING ARRAY", "stat": "mining_array", "cost": 3000, "effect": "+10 mined per cycle"},
			{"label": "OPTIMISED MINING", "stat": "optimized_mining", "cost": 2275, "effect": "+5% mining speed"},
			{"label": "CARGO CAPACITY", "stat": "cargo_capacity", "cost": 125, "effect": "+50 cargo"},
			{"label": "SPEED", "stat": "speed", "cost": 100, "effect": "+10 movement speed"}
		],
		"research": [
			{"label": "Ion Thrusters", "key": "minotard_ion_thrusters", "description": "Double Minotard movement speed.", "difficulty": 2.5},
			{"label": "Optical Lens A", "key": "minotard_optical_lens", "description": "Recover 10% additional ore from Minotard extraction.", "difficulty": 3.0},
			{"label": "Bifocal Lens", "key": "minotard_bifocal_lens", "description": "Increase Minotard mining speed by 5%.", "difficulty": 3.0}
		],
		"offset": Vector2(-46, 26)
	},
	"atlas": {
		"rank": 4, "name": "Atlas", "category": "support",
		"description": "A linked industrial hauler that receives drone deposits in the field.",
		"ore": [
			{"label": "INDUSTRIAL LINK", "stat": "industrial_link", "cost": 2500, "effect": "+10% nearby drone mining speed"},
			{"label": "STORAGE BINS", "stat": "storage_bins", "cost": 200, "effect": "+10 drone cargo"},
			{"label": "OPTIMISER LENS", "stat": "optimizer_lens", "cost": 125, "effect": "+100% click income within Atlas range"},
			{"label": "SPEED", "stat": "speed", "cost": 100, "effect": "+10 movement speed"}
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
			{"label": "FURNACE", "stat": "furnace", "cost": 2500, "effect": "+0.0012x global income"},
			{"label": "CYCLING", "stat": "cycling", "cost": 990, "effect": "+100 per 1,000 collected"}
		],
		"research": [
			{"label": "Heavy Furnace", "key": "refinery_heavy_furnaces", "description": "Double Romius Furnace bonuses.", "difficulty": 3.0},
			{"label": "Waste Processes", "key": "refinery_waste_processes", "description": "Produce 0.25 bonus ore for every 10 ore earned.", "difficulty": 3.0}
		],
		"offset": Vector2(-14, 32)
	},
	"gethica": {
		"rank": 6, "name": "Gethica", "category": "utility",
		"description": "A science vessel for richer systems and fleet coordination.",
		"ore": [
			{"label": "SPECTROMETER ALPHA", "stat": "spectrometer_alpha", "cost": 1750, "effect": "+100 ore to every normal node"},
			{"label": "LOCAL SFC", "stat": "local_sfc", "cost": 600, "effect": "+1 fleet ship speed"},
			{"label": "DRONE FC", "stat": "drone_fc", "cost": 500, "effect": "+0.5 all drone speed"},
			{"label": "FLEET ADJUSTER", "stat": "fleet_adjuster", "cost": 900, "effect": "+100 click-mining range"}
		],
		"research": [
			{"label": "Scan Enrichment", "key": "gethica_scan_enrichment", "description": "Enriched pink nodes contain 5,000 ore.", "difficulty": 3.0},
			{"label": "Deep Space Arrays", "key": "gethica_deep_space_arrays", "description": "Generate three additional normal nodes in future fields.", "difficulty": 3.0}
		],
		"offset": Vector2(-52, -12)
	},
	"ambrossa": {
		"rank": 7, "name": "Ambressa", "category": "civilian",
		"description": "A civilian workshop ship producing consumer goods over time.",
		"ore": [
			{"label": "WORKSHOPS", "stat": "workshops", "cost": 770, "effect": "+5 income per cycle"},
			{"label": "QUALITY ASSURANCE", "stat": "quality_assurance", "cost": 1000, "effect": "+0.22x Ambressa income"},
			{"label": "TRADER REPUTATION", "stat": "trader_reputation", "cost": 850, "effect": "-1% cycle interval"}
		],
		"research": [
			{"label": "Market Demands", "key": "ambrossa_market_demands", "description": "Double Ambressa passive income.", "difficulty": 3.0},
			{"label": "Commission Work", "key": "ambrossa_commission_work", "description": "Each cycle has a 20% chance to earn 1,000 bonus ore.", "difficulty": 3.5}
		],
		"offset": Vector2(-18, -24)
	},
	"hammond": {
		"rank": 8, "name": "Hammond", "category": "military",
		"description": "A mid-range corvette equipped with kinetic and photon artillery.",
		"ore": [
			{"label": "LORI CANNONS", "stat": "lori_cannons", "cost": 5120, "effect": "+1 battle DPS"},
			{"label": "ARMING TIME", "stat": "arming_time", "cost": 1800, "effect": "-1% firing interval"}
		],
		"research": [
			{"label": "Reinforced Framework", "key": "hammond_reinforced_framework", "description": "Increase Hammond hull and armor effectiveness by 5%.", "difficulty": 4.0},
			{"label": "Fighter Bays", "key": "hammond_fighter_bays", "description": "Install a fixed wing of five fighters.", "difficulty": 4.5}
		],
		"offset": Vector2(40, -56)
	},
	"nelson": {
		"rank": 9, "name": "Nelson", "category": "civilian",
		"description": "A creative broadcast ship supporting art, music, and fleet culture.",
		"ore": [
			{"label": "LOCAL COMMS", "stat": "local_comms", "cost": 1760, "effect": "+0.75 passive income/sec"},
			{"label": "COMMISSIONS", "stat": "commissions", "cost": 2400, "effect": "+1 income per unique ship"},
			{"label": "LOCAL FM", "stat": "local_fm", "cost": 3200, "effect": "+2.5% civilian efficiency"}
		],
		"research": [
			{"label": "Art Commission", "key": "nelson_art_commission", "description": "Grant each unique ship a 2% efficiency paintjob.", "difficulty": 4.0},
			{"label": "Channels", "key": "nelson_channels", "description": "Local FM levels unlock tracks; track changes grant 2,000 ore.", "difficulty": 4.5}
		],
		"offset": Vector2(-34, -36)
	},
	"drone_carrier": {
		"rank": 10, "name": "Brooder", "category": "support",
		"description": "A carrier with extensive command systems and expandable fighter bays.",
		"base_cap": 50,
		"ore": [
			{"label": "COMMAND CAP", "stat": "command_capacity", "cost": 1170, "effect": "+1 mining drone"},
			{"label": "FIGHTER BAYS", "stat": "fighter_bays", "cost": 3365, "effect": "+1 battle fighter"},
			{"label": "ACCELERATION", "stat": "acceleration", "cost": 1200, "effect": "+0.5% outbound drone speed"},
			{"label": "OUTPUT", "stat": "output", "cost": 50, "effect": "+1 click output"},
			{"label": "INPUT RATE", "stat": "input_rate", "cost": 1000, "effect": "+1 held and manual input/sec"}
		],
		"research": [
			{"label": "Military Command", "key": "brooder_military_command", "description": "Unlock advanced fleet formation and attack controls.", "difficulty": 4.5},
			{"label": "Drone Reconfiguration", "key": "brooder_drone_reconfiguration", "description": "Increase every drone type's primary stats by 5%.", "difficulty": 5.0}
		],
		"offset": Vector2(-62, 38)
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
	"tobias": {
		"rank": 12, "name": "Tobias", "category": "utility",
		"description": "A cylindrical gas harvester with a dedicated collection nozzle.",
		"ore": [
			{"label": "COMPRESSOR", "stat": "compressor", "cost": 3000, "effect": "+5% gas collection speed"},
			{"label": "DUAL CHAMBER", "stat": "dual_chamber", "cost": 5000, "effect": "+10 gas per cycle"},
			{"label": "ELONGATION", "stat": "elongation", "cost": 2270, "effect": "+100 gas collection range"},
			{"label": "SPEED", "stat": "speed", "cost": 800, "effect": "+10 movement speed"}
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
			{"label": "COORDINATOR", "stat": "coordinator", "cost": 1900, "effect": "+2 fleet ship speed"},
			{"label": "BOOSTER", "stat": "booster", "cost": 2400, "effect": "+2% nearby drone efficiency"}
		],
		"research": [
			{"label": "Armilla Designator", "key": "parallax_armilla_designator", "description": "Reduce the delay before travelling to the next field.", "difficulty": 5.0},
			{"label": "Broad Tether", "key": "parallax_broad_tether", "description": "Destroyed drones have a 5% chance to be recalled after battle.", "difficulty": 5.5}
		],
		"offset": Vector2(-72, -4)
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
	"fruegal": {
		"rank": 16, "name": "Fruegal", "category": "civilian",
		"description": "A broad mining ship capable of working several mineral and gas nodes.",
		"ore": [
			{"label": "DRONE COMMAND", "stat": "drone_command_capacity", "cost": 500, "effect": "+1 mining drone"},
			{"label": "VACUUM COMMAND", "stat": "vacuum_command_capacity", "cost": 1550, "effect": "+1 vacuum drone"},
			{"label": "ADJACENTOR", "stat": "adjacentor", "cost": 2000, "effect": "+2% speed per nearby node"},
			{"label": "DIAMOND TIP", "stat": "diamond_tip", "cost": 2600, "effect": "+5% mining speed"},
			{"label": "MICRON LASER", "stat": "micron_laser", "cost": 2800, "effect": "+5 mined per cycle"},
			{"label": "FUNNELING", "stat": "funneling", "cost": 1800, "effect": "+100 work range"},
			{"label": "SPEED", "stat": "speed", "cost": 900, "effect": "+10 movement speed"}
		],
		"research": [],
		"offset": Vector2(-44, 42)
	},
	"merlinda": {
		"rank": 17, "name": "Merlinda", "category": "civilian",
		"description": "A glass observation ship broadcasting races through each system.",
		"ore": [
			{"label": "PARTICIPANTS", "stat": "participants", "cost": 1470, "effect": "+1 racer"},
			{"label": "CONSOLATION", "stat": "consolation", "cost": 2100, "effect": "+25 lap income per racer"},
			{"label": "CELEBRATIONS", "stat": "celebrations", "cost": 10000, "effect": "+500 course completion income"},
			{"label": "ENCORE", "stat": "encore", "cost": 3100, "effect": "+2% racer boost near ships"},
			{"label": "TUNING", "stat": "tuning", "cost": 4000, "effect": "+5% racer speed"}
		],
		"research": [
			{"label": "Checkpoint Markers", "key": "merlinda_checkpoint_markers", "description": "Racers earn a small amount of ore at every checkpoint.", "difficulty": 6.0}
		],
		"offset": Vector2(-58, -44)
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
	"tarrip": {
		"rank": 19, "name": "Tarrip", "category": "civilian",
		"description": "An orbital trade station coordinating deliveries and fleet contracts.",
		"ore": [
			{"label": "TRADER CAPACITY", "stat": "trader_capacity", "cost": 2650, "effect": "+1 trade drone"},
			{"label": "MICRO-TRANSITS", "stat": "micro_transits", "cost": 2380, "effect": "+5 trade cargo"},
			{"label": "TRADEHUB", "stat": "tradehub", "cost": 3180, "effect": "+50 trade payout"},
			{"label": "HIGHSTREET TRAFFIC", "stat": "highstreet_traffic", "cost": 1800, "effect": "+10 income/sec per ship"}
		],
		"research": [
			{"label": "Efficient Bureaucracy", "key": "tarrip_efficient_bureaucracy", "description": "Trade drones work 25% faster.", "difficulty": 6.5},
			{"label": "Specialised Cargo", "key": "tarrip_specialised_cargo", "description": "Double trade-drone cargo.", "difficulty": 6.5}
		],
		"offset": Vector2(-30, 56)
	},
	"elysium_air": {
		"rank": 20, "name": "Elysium Air", "category": "civilian",
		"description": "A ring-shaped broadcast and interpretation station for alien visitors.",
		"ore": [
			{"label": "TRADER CAPACITY", "stat": "trader_capacity", "cost": 2650, "effect": "+1 trade drone"},
			{"label": "EXHIBITS", "stat": "exhibits", "cost": 2000, "effect": "+0.25x trade rewards"},
			{"label": "MONOLITH", "stat": "monolith", "cost": 5150, "effect": "+5,000 per new field"},
			{"label": "INVITATION", "stat": "invitation", "cost": 4325, "effect": "Faster and longer alien visits"}
		],
		"research": [
			{"label": "Xeno Trade", "key": "elysium_xeno_trade", "description": "Trade drones fill faster from every ship.", "difficulty": 7.0},
			{"label": "Visitors", "key": "elysium_visitors", "description": "Trade drones fill substantially faster from alien ships.", "difficulty": 7.0}
		],
		"offset": Vector2(-92, -24)
	}
}

const SPECIAL_NODES := {
	"enriched": {"name": "Enriched Node", "required_ship": "gethica", "amount": 2500, "rings": [6, 7]},
	"gas_planet": {"name": "Gas Giant", "required_ship": "tobias", "amount": 8000, "rings": [8, 9, 10]},
	"gas_cloud": {"name": "Gas Cloud", "required_ship": "tobias", "amount": 1500, "rings": [6, 7, 8, 9, 10]}
}

const COMPANIONS := {
	"fighter": {
		"name": "Fighter Drones", "required_ship": "hammond",
		"description": "Combat drones launched by Hammond and Brooder.",
		"ore": [],
		"research": [
			{"label": "Fighter Bays", "key": "hammond_fighter_bays", "description": "Install Hammond's fixed wing of five fighters.", "requires_ship": "hammond"},
			{"label": "Drone Reconfiguration", "key": "brooder_drone_reconfiguration", "description": "Increase every drone type's primary stats by 5%.", "requires_ship": "drone_carrier"}
		]
	},
	"vacuum": {
		"name": "Vacuum Drones", "required_ship": "tobias",
		"description": "Gas-harvesting drones operated by Tobias and Boschore.",
		"ore": [],
		"research": [
			{"label": "Vacuum Drone Bays", "key": "tobias_vacuum_drone_bays", "description": "Deploy five fixed vacuum drones.", "requires_ship": "tobias"},
			{"label": "Dust Bunnies", "key": "boschore_dust_bunnies", "description": "Collect 100 excess gas each Tobias cycle.", "requires_ship": "boschore"},
			{"label": "Nozzle Selection", "key": "boschore_nozzle_selection", "description": "Triple specialized gas collection speed.", "requires_ship": "boschore"}
		]
	},
	"racer": {
		"name": "Racers", "required_ship": "merlinda",
		"description": "Racing craft launched by Merlinda to follow node-marked courses through each field.",
		"ore": [
			{"label": "AWARENESS", "stat": "awareness", "cost": 1800, "description": "-0.08 seconds waiting at each marker"},
			{"label": "SPEED", "stat": "speed", "cost": 4000, "description": "+5% individual racer speed (base stat 200-300)"},
			{"label": "SWIVEL", "stat": "swivel", "cost": 2600, "description": "+10% racer turn speed"},
			{"label": "SPONSORSHIP", "stat": "sponsorship", "cost": 2100, "description": "+25 ore per racer that finishes"}
		],
		"research": []
	},
	"dyson": {
		"name": "Dyson Drones", "required_ship": "stapledon",
		"description": "Solar collectors orbiting the current system star.",
		"ore": [],
		"research": [
			{"label": "Monocrystalline", "key": "stapledon_monocrystalline", "description": "Increase solar income by 20%.", "requires_ship": "stapledon"},
			{"label": "Nanofilm", "key": "stapledon_nanofilm", "description": "Reduce solar collection time by 2%.", "requires_ship": "stapledon"}
		]
	},
	"trader": {
		"name": "Trader Drones", "required_ship": "tarrip",
		"description": "Micro-drones carrying goods and contracts between ships.",
		"ore": [],
		"research": [
			{"label": "Efficient Bureaucracy", "key": "tarrip_efficient_bureaucracy", "description": "Trade drones work 25% faster.", "requires_ship": "tarrip"},
			{"label": "Specialised Cargo", "key": "tarrip_specialised_cargo", "description": "Double trade-drone cargo.", "requires_ship": "tarrip"},
			{"label": "Xeno Trade", "key": "elysium_xeno_trade", "description": "Trade drones fill faster from every ship.", "requires_ship": "elysium_air"},
			{"label": "Visitors", "key": "elysium_visitors", "description": "Trade drones fill faster from alien visitors.", "requires_ship": "elysium_air"}
		]
	}
}

static func get_prestige_levels() -> Dictionary:
	var levels := {}
	for ship_id in SHIPS:
		var data: Dictionary = SHIPS[ship_id]
		var rank = int(data.get("rank", 0))
		if rank <= 0:
			continue
		levels[rank] = {
			"cost": int(PRESTIGE_COSTS[rank]),
			"ship": ship_id,
			"reward": "Unlock %s: %s" % [str(data["name"]), str(data["description"])]
		}
	return levels

static func get_ship_ids(include_foundation: bool = false) -> Array[String]:
	var ids: Array[String] = []
	for ship_id in SHIPS:
		if include_foundation or int(SHIPS[ship_id].get("rank", 0)) > 0:
			ids.append(str(ship_id))
	ids.sort_custom(func(a: String, b: String): return int(SHIPS[a]["rank"]) < int(SHIPS[b]["rank"]))
	return ids

static func get_ship_data(ship_id: String) -> Dictionary:
	return SHIPS.get(ship_id, {}).duplicate(true)

static func get_display_name(ship_id: String) -> String:
	return str(SHIPS.get(ship_id, {}).get("name", ship_id.capitalize()))

static func get_category(ship_id: String) -> String:
	return str(SHIPS.get(ship_id, {}).get("category", "civilian"))

static func get_ore_rows(ship_id: String) -> Array:
	return Array(SHIPS.get(ship_id, {}).get("ore", [])).duplicate(true)

static func get_research_rows(ship_id: String) -> Array:
	return Array(SHIPS.get(ship_id, {}).get("research", [])).duplicate(true)

static func get_cap_definitions() -> Dictionary:
	var definitions := {
		"flagship_general_cap": {"ship": "flagship", "name": "Upgrade Cap", "ore_upgrades": ["click_output", "click_multiplier", "drones", "flagship_speed", "refining"]},
		"mining_drone_general_cap": {"ship": "mining_drone", "name": "Upgrade Cap", "ore_upgrades": ["speed", "mining", "mining_speed", "capacity"]}
	}
	for ship_id in get_ship_ids():
		var cap_key = "%s_general_cap" % ship_id
		var upgrades: Array[String] = []
		for row in get_ore_rows(ship_id):
			upgrades.append("%s_%s" % [ship_id, str(row["stat"])])
		definitions[cap_key] = {"ship": ship_id, "name": "Upgrade Cap", "ore_upgrades": upgrades}
	return definitions

static func get_default_cap_levels() -> Dictionary:
	var levels := {}
	for key in get_cap_definitions():
		levels[key] = 0
	return levels

static func get_passive_ship_map() -> Dictionary:
	var mapping := {}
	for ship_id in SHIPS:
		for row in get_research_rows(ship_id):
			mapping[str(row["key"])] = ship_id
	return mapping

static func get_default_passive_levels() -> Dictionary:
	var levels := {}
	for key in get_passive_ship_map():
		levels[key] = 0
	return levels

static func get_fixed_research_difficulty() -> Dictionary:
	var difficulties := {}
	for ship_id in SHIPS:
		for row in get_research_rows(ship_id):
			difficulties[str(row["key"])] = float(row.get("difficulty", 2.0))
	return difficulties

static func get_default_unlocked_ships() -> Dictionary:
	var unlocked := {}
	for ship_id in get_ship_ids():
		unlocked[ship_id] = false
	return unlocked

static func get_default_upgrade_levels() -> Dictionary:
	var levels := {}
	for ship_id in get_ship_ids():
		var ship_levels := {}
		for row in get_ore_rows(ship_id):
			ship_levels[str(row["stat"])] = 0
		levels[ship_id] = ship_levels
	return levels

static func get_default_companion_upgrade_levels() -> Dictionary:
	var levels := {}
	for companion_id in get_companion_ids():
		var companion_levels := {}
		for row in Array(COMPANIONS[companion_id].get("ore", [])):
			if row.has("stat"):
				companion_levels[str(row["stat"])] = 0
		levels[companion_id] = companion_levels
	return levels

static func get_ore_base_cost(ship_id: String, stat_key: String) -> int:
	for row in get_ore_rows(ship_id):
		if str(row["stat"]) == stat_key:
			return int(row["cost"])
	return 0

static func get_companion_ore_base_cost(companion_id: String, stat_key: String) -> int:
	for row in Array(COMPANIONS.get(companion_id, {}).get("ore", [])):
		if str(row.get("stat", "")) == stat_key:
			return int(row.get("cost", 0))
	return 0

static func get_ship_count_at_rank(rank: int) -> int:
	var count = 1
	for ship_id in get_ship_ids():
		if int(SHIPS[ship_id]["rank"]) <= rank:
			count += 1
	return count

static func get_companion_ids() -> Array[String]:
	var ids: Array[String] = []
	for companion_id in COMPANIONS:
		ids.append(str(companion_id))
	return ids

static func get_companion_data(companion_id: String) -> Dictionary:
	return COMPANIONS.get(companion_id, {}).duplicate(true)

static func get_companion_display_name(companion_id: String) -> String:
	return str(COMPANIONS.get(companion_id, {}).get("name", companion_id.capitalize()))

static func is_companion_research_key(research_key: String) -> bool:
	for companion_id in COMPANIONS:
		for row in Array(COMPANIONS[companion_id].get("research", [])):
			if str(row.get("key", "")) == research_key:
				return true
	return false
