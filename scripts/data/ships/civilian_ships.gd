class_name CivilianShipData
extends RefCounted

const SHIPS := {
	"ambrossa": {
		"rank": 7, "name": "Ambressa", "category": "civilian",
		"description": "A civilian workshop ship producing consumer goods over time.",
		"ore": [
			{"label": "WORKSHOPS", "stat": "workshops", "cost": 660, "effect": "+100 Credits per cycle"},
			{"label": "QUALITY ASSURANCE", "stat": "quality_assurance", "cost": 1000, "effect": "+2% chance for 1,000 bonus Credits"},
			{"label": "TRADER REPUTATION", "stat": "trader_reputation", "cost": 850, "effect": "-1% production time"},
			{"label": "WORK SCHEDULES", "stat": "work_schedules", "cost": 1100, "effect": "-2% rest time (minimum 20%)"}
		],
		"research": [
			{"label": "Market Demands", "key": "ambrossa_market_demands", "description": "Double Ambressa passive income.", "difficulty": 3.0},
			{"label": "Efficient Planning", "key": "ambrossa_efficient_planning", "description": "Run two production cycles before Ambressa must rest.", "difficulty": 3.5}
		],
		"offset": Vector2(-18, -24)
	},
	"nelson": {
		"rank": 9, "name": "Nelson", "category": "civilian",
		"description": "A creative broadcast ship supporting art, music, and fleet culture.",
		"ore": [
			{"label": "LOCAL COMMS", "stat": "local_comms", "cost": 1760, "effect": "+5 Credits per second"},
			{"label": "COMMISSIONS", "stat": "commissions", "cost": 2400, "effect": "+1 income per unique ship"},
			{"label": "LOCAL FM", "stat": "local_fm", "cost": 3200, "effect": "+2.5% civilian efficiency"},
			{"label": "BAND PRACTICE", "stat": "band_practice", "cost": 2800, "effect": "+1% Nelson efficiency per 60-second cycle"}
		],
		"research": [
			{"label": "Art Commission", "key": "nelson_art_commission", "description": "Grant each unique ship a 2% efficiency paintjob.", "difficulty": 4.0},
			{"label": "Concerts", "key": "nelson_concerts", "description": "Gain 1,000 Credits whenever a new field is generated.", "difficulty": 4.3},
			{"label": "Channels", "key": "nelson_channels", "description": "Local FM levels unlock tracks; track changes grant 2,000 Credits.", "difficulty": 4.5}
		],
		"offset": Vector2(-34, -36)
	},
	"fruegal": {
		"rank": 16, "name": "Fruegal", "category": "civilian",
		"description": "A broad mining ship collecting from several mineral and gas nodes directly into fleet storage.",
		"ore": [
			{"label": "DRONE COMMAND", "stat": "drone_command_capacity", "cost": 500, "effect": "+1 mining drone"},
			{"label": "VACUUM COMMAND", "stat": "vacuum_command_capacity", "cost": 1550, "effect": "+1 vacuum drone"},
			{"label": "ADJACENTOR", "stat": "adjacentor", "cost": 2000, "effect": "+2% speed per nearby node"},
			{"label": "DIAMOND TIP", "stat": "diamond_tip", "cost": 2600, "effect": "+5% mining speed"},
			{"label": "MICRON LASER", "stat": "micron_laser", "cost": 2800, "effect": "+5 mined per cycle"},
			{"label": "INPUT RATE", "stat": "input_rate", "cost": 125, "effect": "+1 held activation/sec and +1 manual click/sec in mining and battle"},
			{"label": "FUNNELING", "stat": "funneling", "cost": 1800, "effect": "+100 Fruegal mining range"},
			{"label": "SPEED", "stat": "speed", "cost": 900, "effect": "+10 Fruegal movement speed"}
		],
		"research": [],
		"offset": Vector2(-44, 42)
	},
	"merlinda": {
		"rank": 17, "name": "Merlinda", "category": "utility",
		"description": "A glass observation ship broadcasting races through each system. Each finisher earns Credits based on the number of checkpoints raced.",
		"ore": [
			{"label": "PARTICIPANTS", "stat": "participants", "cost": 1470, "effect": "+1 racer"},
			{"label": "AWARENESS", "stat": "awareness", "cost": 1800, "effect": "Widens racer lanes and allows broader arcs around node obstacles"},
			{"label": "CONSOLATION", "stat": "consolation", "cost": 2100, "effect": "+25 lap income per racer"},
			{"label": "CELEBRATIONS", "stat": "celebrations", "cost": 10000, "effect": "+500 course completion income"},
			{"label": "PICK ME UPS", "stat": "pick_me_ups", "cost": 4000, "effect": "+2% burst chance and +3% burst speed per level"}
		],
		"research": [
			{"label": "Checkpoint Markers", "key": "merlinda_checkpoint_markers", "description": "Racers earn a small amount of Credits at every checkpoint.", "difficulty": 6.0},
			{"label": "Pitstop", "key": "merlinda_pitstop", "description": "Each racer has a 50% chance to slow briefly before receiving a significant speed boost.", "difficulty": 6.5},
			{"label": "Derby Picks", "key": "merlinda_derby_picks", "description": "Toggle risky Pick Me Ups that can slow, stop, or temporarily destroy racers in exchange for Credits.", "difficulty": 7.0}
		],
		"offset": Vector2(-58, -44)
	},
	"tarrip": {
		"rank": 19, "name": "Tarrip", "category": "civilian",
		"description": "An orbital trade station coordinating deliveries and fleet contracts.",
		"ore": [
			{"label": "TRADER CAPACITY", "stat": "trader_capacity", "cost": 2650, "effect": "+1 trade drone"},
			{"label": "MICRO-TRANSITS", "stat": "micro_transits", "cost": 2380, "effect": "+5 trade cargo"},
			{"label": "TRADEHUB", "stat": "tradehub", "cost": 3180, "effect": "+50 trade payout"},
			{"label": "HIGHSTREET TRAFFIC", "stat": "highstreet_traffic", "cost": 1800, "effect": "+100 Credits per cycle for every constructed ship"}
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
			{"label": "INVITATION", "stat": "invitation", "cost": 4325, "effect": "-2s between alien visits and +1% visit duration"}
		],
		"research": [
			{"label": "Xeno Trade", "key": "elysium_xeno_trade", "description": "Trade drones fill faster from every ship.", "difficulty": 7.0},
			{"label": "Visitors", "key": "elysium_visitors", "description": "Trade drones fill substantially faster from alien ships.", "difficulty": 7.0}
		],
		"offset": Vector2(-92, -24)
	}
}
