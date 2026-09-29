class_name ShipCatalog
extends RefCounted

const CATEGORY_COLORS := {
	"civilian": Color("f4d06f"),
	"military": Color("ff7770"),
	"support": Color("7ce0b8"),
	"utility": Color("c3a6ff")
}

const PRESTIGE_BASE_COST := 10000.0
const PRESTIGE_COST_SCALE := 1.4

const FoundationShips = preload("res://scripts/data/ships/foundation_ships.gd")
const CivilianShips = preload("res://scripts/data/ships/civilian_ships.gd")
const MilitaryShips = preload("res://scripts/data/ships/military_ships.gd")
const SupportShips = preload("res://scripts/data/ships/support_ships.gd")
const UtilityShips = preload("res://scripts/data/ships/utility_ships.gd")

static var SHIPS: Dictionary = _build_ship_catalog()

static func _build_ship_catalog() -> Dictionary:
	var ships := {}
	for source in [FoundationShips, CivilianShips, MilitaryShips, SupportShips, UtilityShips]:
		ships.merge(source.SHIPS, true)
	return ships

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
		"cap_key": "racer_general_cap",
		"ore": [
			{"label": "SPEED", "stat": "speed", "cost": 4000, "description": "+5% individual racer speed (base stat 200-300)"},
			{"label": "SWIVEL", "stat": "swivel", "cost": 2600, "description": "+10% racer turn speed"},
			{"label": "ENCORE", "stat": "encore", "cost": 3100, "description": "Passing fleet units briefly boosts both the racer and the unit"},
			{"label": "SPONSORSHIP", "stat": "sponsorship", "cost": 2100, "description": "Reduce future Merlinda Participant costs by 2% per level"}
		],
		"research": [
			{"label": "Ion Thrusters", "key": "racer_ion_thrusters", "description": "Double racer and race-warden speed.", "difficulty": 6.5, "requires_ship": "merlinda"},
			{"label": "Afterburn", "key": "racer_afterburn", "description": "Increase racer turn speed by 50%.", "difficulty": 6.5, "requires_ship": "merlinda"},
			{"label": "Grand Prize", "key": "racer_grand_prize", "description": "Multiply the final race prize by five.", "difficulty": 7.0, "requires_ship": "merlinda"},
			{"label": "Racer Guidelines", "key": "racer_guidelines", "description": "Significantly lengthen obstacle bypasses and the overall race course.", "difficulty": 7.0, "requires_ship": "merlinda"},
			{"label": "Taggers", "key": "racer_taggers", "description": "Double the number of racers supplied by Participants.", "difficulty": 7.5, "requires_ship": "merlinda"}
		]
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

const ResearchRequirements = preload("res://scripts/data/research/research_requirements.gd")
const RESEARCH_REQUIREMENTS := ResearchRequirements.REQUIREMENTS

static func get_prestige_levels() -> Dictionary:
	var levels := {}
	for ship_id in SHIPS:
		var data: Dictionary = SHIPS[ship_id]
		var rank = int(data.get("rank", 0))
		if rank <= 0:
			continue
		levels[rank] = {
			"cost": int(ceil(PRESTIGE_BASE_COST * pow(PRESTIGE_COST_SCALE, float(rank - 1)))),
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

static func get_research_requirements(research_key: String) -> Array:
	return []

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
	for companion_id in get_companion_ids():
		var companion_data: Dictionary = COMPANIONS[companion_id]
		var cap_key = str(companion_data.get("cap_key", ""))
		if cap_key.is_empty():
			continue
		var upgrades: Array[String] = []
		for row in Array(companion_data.get("ore", [])):
			upgrades.append("%s_%s" % [companion_id, str(row["stat"])])
		definitions[cap_key] = {"ship": str(companion_data.get("required_ship", "")), "name": "Upgrade Cap", "ore_upgrades": upgrades}
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
	for companion_id in COMPANIONS:
		var companion_data: Dictionary = COMPANIONS[companion_id]
		for row in Array(companion_data.get("research", [])):
			mapping[str(row["key"])] = str(row.get("requires_ship", companion_data.get("required_ship", "")))
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
	for companion_id in COMPANIONS:
		for row in Array(COMPANIONS[companion_id].get("research", [])):
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
