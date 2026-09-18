extends Node

signal ship_modifiers_changed

const BATTLE_TIME_LIMIT := 60.0
const BASE_RESEARCH_REWARD := 5
const MAX_UPGRADE_BASE := 10
const PRESTIGE_BOSS_TIER_INTERVAL := 5
const FLAGSHIP_BASE_HP := 100
const CLICK_RATE_CAP_UPGRADE := "click_multiplier"
const REFINERY_GLOBAL_ORE_BONUS := 0.012
const RESEARCH_CAP_COST_BASE := 10.0
const RESEARCH_CAP_COST_MULTIPLIER := 1.36
const RESEARCH_CAP_INCREASE := 10
const PASSIVE_SINGLE_PURCHASES := [
	"flagship_readiness",
	"flagship_ion_thrusters",
	"flagship_railgun",
	"drone_mining_lasers",
	"drone_ion_thrusts"
]
const PASSIVE_COSTS := {
	"flagship_readiness": 15,
	"flagship_ion_thrusters": 27,
	"flagship_railgun": 40,
	"drone_mining_lasers": 60,
	"drone_ion_thrusts": 40
}
const PRESTIGE_LEVELS := {
	1: {"cost": 90000, "ship": "refinery", "reward": "Unlock Romius, the global refinery ship."},
	2: {"cost": 225000, "ship": "hammond", "reward": "Unlock Hammond, a military damage ship."},
	3: {"cost": 500000, "ship": "drone_carrier", "reward": "Unlock the Drone Carrier and fighter drones."}
}
const DRONE_CAP_UPGRADES := ["speed", "mining", "mining_speed", "drone_multiplier", "capacity"]
const FLAGSHIP_CAP_UPGRADES := ["click_output", "click_multiplier", "drones", "flagship_speed"]
const SHIP_PROFILES := {
	&"flagship": preload("res://scenes/ship_profiles/flagship.tres"),
	&"mining_drone": preload("res://scenes/ship_profiles/mining_drone.tres"),
	&"refinery": preload("res://scenes/ship_profiles/refinery.tres"),
	&"hammond": preload("res://scenes/ship_profiles/hammond.tres"),
	&"drone_carrier": preload("res://scenes/ship_profiles/drone_carrier.tres")
}

const RESEARCH_CAP_UPGRADES := {
	"flagship_command_capacity": {"ship": "flagship", "ore_upgrade": "drones", "name": "Command Capacity"},
	"flagship_click_rate": {"ship": "flagship", "ore_upgrade": "click_multiplier", "name": "Click Rate"},
	"refinery_command_capacity": {"ship": "refinery", "ore_upgrade": "refinery_command_capacity", "name": "Command Capacity"},
	"refinery_click_rate": {"ship": "refinery", "ore_upgrade": "refinery_click_rate", "name": "Click Rate"},
	"hammond_command_capacity": {"ship": "hammond", "ore_upgrade": "hammond_command_capacity", "name": "Command Capacity"},
	"hammond_click_rate": {"ship": "hammond", "ore_upgrade": "hammond_click_rate", "name": "Click Rate"},
	"drone_carrier_command_capacity": {"ship": "drone_carrier", "ore_upgrade": "drone_carrier_command_capacity", "name": "Command Capacity"},
	"drone_carrier_click_rate": {"ship": "drone_carrier", "ore_upgrade": "drone_carrier_click_rate", "name": "Click Rate"}
}

var research_points: int = 0
var cap_levels := {
	"click_output": 0,
	"click_multiplier": 0,
	"speed": 0,
	"mining": 0,
	"mining_speed": 0,
	"drone_multiplier": 0,
	"capacity": 0,
	"drones": 0,
	"flagship_speed": 0,
	"refinery_command_capacity": 0,
	"refinery_click_multiplier": 0,
	"refinery_global_income_bonus": 0,
	"flagship_command_capacity": 0,
	"flagship_click_rate": 0,
	"refinery_click_rate": 0,
	"hammond_command_capacity": 0,
	"hammond_click_rate": 0,
	"drone_carrier_command_capacity": 0,
	"drone_carrier_click_rate": 0
}
var pending_cap_levels := {}
var passive_levels := {
	"flagship_readiness": 0,
	"flagship_ion_thrusters": 0,
	"flagship_railgun": 0,
	"drone_mining_lasers": 0,
	"drone_ion_thrusts": 0
}
var pending_passive_levels := {}
var boss_tier: int = 0
var prestige_level: int = 0
var prestige_ready: bool = false
var auto_claim_rewards: bool = false
var ship_stat_modifiers: Array[ShipStatModifier] = []
var claimed_prestige_rewards := {}
var unlocked_ships := {
	"refinery": false,
	"hammond": false,
	"drone_carrier": false
}
var ship_stats := {
	"refinery": {
		"command_capacity": 0,
		"click_multiplier": 1.0,
		"hull": 100,
		"armor": 0,
		"shield": 0.0,
		"global_income_bonus": REFINERY_GLOBAL_ORE_BONUS
	}
}
var pending_battle := {}
var research_card_unlocks := {}
var research_hunt_count: int = 0
var saved_run_state := {}
var battle_return_pending: bool = false
var battle_was_victory: bool = false
var battle_was_prestige: bool = false
var battle_advance_field_pending: bool = false
var prestige_reset_pending: bool = false
var surviving_drone_count: int = 0
var last_battle_message: String = ""

func _ready() -> void:
	for upgrade in cap_levels:
		pending_cap_levels[upgrade] = int(cap_levels[upgrade])
	for upgrade in passive_levels:
		pending_passive_levels[upgrade] = int(passive_levels[upgrade])

func get_ship_profile(ship_id: StringName) -> ShipProfile:
	return SHIP_PROFILES.get(ship_id) as ShipProfile

func get_registered_ship_ids() -> Array[StringName]:
	var ship_ids: Array[StringName] = []
	for ship_id in SHIP_PROFILES:
		ship_ids.append(StringName(ship_id))
	return ship_ids

func resolve_ship_stat(ship_id: StringName, stat: StringName, base_value: float) -> float:
	var profile = get_ship_profile(ship_id)
	if profile == null:
		return base_value
	return ShipStatResolver.resolve(base_value, profile, stat, ship_stat_modifiers)

func add_ship_stat_modifier(modifier: ShipStatModifier) -> bool:
	if modifier == null or modifier.stat.is_empty():
		return false
	ship_stat_modifiers.append(modifier)
	emit_signal("ship_modifiers_changed")
	return true

func remove_ship_stat_modifiers(source_id: StringName) -> int:
	var removed = 0
	for index in range(ship_stat_modifiers.size() - 1, -1, -1):
		if ship_stat_modifiers[index].source_id == source_id:
			ship_stat_modifiers.remove_at(index)
			removed += 1
	if removed > 0:
		emit_signal("ship_modifiers_changed")
	return removed

func clear_ship_stat_modifiers() -> void:
	if ship_stat_modifiers.is_empty():
		return
	ship_stat_modifiers.clear()
	emit_signal("ship_modifiers_changed")

func _get_upgrade_ship_id(upgrade: String) -> StringName:
	if DRONE_CAP_UPGRADES.has(upgrade):
		return &"mining_drone"
	if FLAGSHIP_CAP_UPGRADES.has(upgrade):
		return &"flagship"
	if upgrade.begins_with("refinery_"):
		return &"refinery"
	return &""

func get_upgrade_cap(upgrade: String) -> int:
	var cap = 50.0 if upgrade == "drone_carrier_command_capacity" else float(MAX_UPGRADE_BASE)
	for research_key in RESEARCH_CAP_UPGRADES:
		var research_data: Dictionary = RESEARCH_CAP_UPGRADES[research_key]
		if str(research_data["ore_upgrade"]) == upgrade:
			cap += float(int(cap_levels.get(research_key, 0)) * RESEARCH_CAP_INCREASE)
			break
	var ship_id = _get_upgrade_ship_id(upgrade)
	if ship_id.is_empty():
		if upgrade.begins_with("hammond_"):
			ship_id = &"hammond"
		elif upgrade.begins_with("drone_carrier_"):
			ship_id = &"drone_carrier"
	if not ship_id.is_empty():
		cap = resolve_ship_stat(ship_id, ShipProfile.STAT_UPGRADE_CAP, cap)
	return max(0, int(round(cap)))

func get_pending_upgrade_cap(upgrade: String) -> int:
	return get_upgrade_cap(upgrade)

func get_click_rate_cap() -> int:
	return get_upgrade_cap(CLICK_RATE_CAP_UPGRADE)

func get_pending_click_rate_cap() -> int:
	return get_pending_upgrade_cap(CLICK_RATE_CAP_UPGRADE)

func get_research_cost(upgrade: String) -> int:
	if not RESEARCH_CAP_UPGRADES.has(upgrade):
		return 0
	return int(ceil(RESEARCH_CAP_COST_BASE * pow(RESEARCH_CAP_COST_MULTIPLIER, float(int(cap_levels.get(upgrade, 0))))))

func get_research_cap_value(upgrade: String) -> int:
	if not RESEARCH_CAP_UPGRADES.has(upgrade):
		return MAX_UPGRADE_BASE
	var data: Dictionary = RESEARCH_CAP_UPGRADES[upgrade]
	return get_upgrade_cap(str(data["ore_upgrade"]))

func add_research_points(amount: int) -> void:
	if amount > 0:
		research_points += amount

func get_passive_level(upgrade: String) -> int:
	return int(passive_levels.get(upgrade, 0))

func get_pending_passive_level(upgrade: String) -> int:
	return get_passive_level(upgrade)

func get_passive_cost(upgrade: String) -> int:
	return int(PASSIVE_COSTS.get(upgrade, 0))

func is_single_purchase_passive(upgrade: String) -> bool:
	return PASSIVE_SINGLE_PURCHASES.has(upgrade)

func get_flagship_max_hp() -> int:
	return max(1, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_MAX_HP, float(FLAGSHIP_BASE_HP)))))

func get_flagship_armor_reduction() -> int:
	return max(0, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_ARMOR, 0.0))))

func get_flagship_shield_reduction() -> float:
	return clamp(resolve_ship_stat(&"flagship", ShipProfile.STAT_SHIELD, 0.0), 0.0, 0.95)

func get_drone_max_hp() -> int:
	return 10

func get_flagship_starting_command_level() -> int:
	var base_level = 1.0 if get_passive_level("flagship_readiness") > 0 else 0.0
	return max(0, int(round(resolve_ship_stat(&"flagship", ShipProfile.STAT_STARTING_COMMAND_LEVEL, base_level))))

func get_flagship_speed_multiplier() -> float:
	return 1.5 if get_passive_level("flagship_ion_thrusters") > 0 else 1.0

func get_flagship_battle_click_bonus() -> int:
	return 10 if get_passive_level("flagship_railgun") > 0 else 0

func get_prestige_data(target_prestige: int) -> Dictionary:
	return PRESTIGE_LEVELS.get(target_prestige, {}).duplicate(true)

func get_prestige_boss(prestige: int) -> Dictionary:
	return get_prestige_data(prestige)

func get_prestige_boss_levels() -> Array[int]:
	var levels: Array[int] = []
	for prestige in PRESTIGE_LEVELS:
		levels.append(int(prestige))
	levels.sort()
	return levels

func can_start_prestige_battle(target_prestige: int) -> bool:
	return false

func can_prestige(total_ore: float) -> bool:
	var target = prestige_level + 1
	return PRESTIGE_LEVELS.has(target) and total_ore >= float(PRESTIGE_LEVELS[target]["cost"])

func get_next_prestige_cost() -> int:
	var target = prestige_level + 1
	return int(PRESTIGE_LEVELS.get(target, {}).get("cost", 0))

func is_ship_unlocked(ship_key: String) -> bool:
	return bool(unlocked_ships.get(ship_key, false))

func is_reward_claimed(reward_key: String) -> bool:
	return bool(claimed_prestige_rewards.get(reward_key, false))

func get_prestige_reward_level(reward_key: String) -> int:
	for target_prestige in PRESTIGE_LEVELS:
		if str(PRESTIGE_LEVELS[target_prestige]["ship"]) == reward_key:
			return int(target_prestige)
	return -1

func get_global_ore_multiplier() -> float:
	var multiplier = 1.0
	if is_ship_unlocked("refinery"):
		multiplier += REFINERY_GLOBAL_ORE_BONUS
	return multiplier

func can_claim_prestige_reward(reward_key: String) -> bool:
	return false

func claim_prestige_reward(reward_key: String) -> bool:
	return false

func claim_available_prestige_rewards() -> Array[String]:
	return []

func set_auto_claim_rewards(enabled: bool) -> Array[String]:
	auto_claim_rewards = false
	return []

func _synchronize_prestige_rewards() -> void:
	for target_prestige in PRESTIGE_LEVELS:
		if prestige_level >= int(target_prestige):
			var ship_key = str(PRESTIGE_LEVELS[target_prestige]["ship"])
			unlocked_ships[ship_key] = true
			claimed_prestige_rewards[ship_key] = true

func get_effective_boss_tier() -> int:
	return boss_tier + int(floor(float(prestige_level) / float(PRESTIGE_BOSS_TIER_INTERVAL)))

func buy_cap_upgrade(upgrade: String) -> bool:
	if not RESEARCH_CAP_UPGRADES.has(upgrade):
		return false
	var level = int(cap_levels.get(upgrade, 0))
	if get_research_card_unlock_level(upgrade) <= level:
		return false
	var cost = get_research_cost(upgrade)
	if research_points < cost:
		return false
	research_points -= cost
	cap_levels[upgrade] = level + 1
	pending_cap_levels[upgrade] = level + 1
	emit_signal("ship_modifiers_changed")
	return true

func buy_passive_upgrade(upgrade: String) -> bool:
	if not passive_levels.has(upgrade):
		return false
	if is_single_purchase_passive(upgrade) and get_passive_level(upgrade) > 0:
		return false
	if get_research_card_unlock_level(upgrade) <= 0:
		return false
	var cost = get_passive_cost(upgrade)
	if research_points < cost:
		return false
	research_points -= cost
	passive_levels[upgrade] = get_passive_level(upgrade) + 1
	pending_passive_levels[upgrade] = passive_levels[upgrade]
	emit_signal("ship_modifiers_changed")
	return true

func refund_cap_upgrade(upgrade: String) -> bool:
	if not RESEARCH_CAP_UPGRADES.has(upgrade):
		return false
	var level = int(cap_levels.get(upgrade, 0))
	if level <= 0:
		return false
	var refunded_cost = int(ceil(RESEARCH_CAP_COST_BASE * pow(RESEARCH_CAP_COST_MULTIPLIER, float(level - 1))))
	cap_levels[upgrade] = level - 1
	pending_cap_levels[upgrade] = level - 1
	research_points += refunded_cost
	emit_signal("ship_modifiers_changed")
	return true

func refund_passive_upgrade(upgrade: String) -> bool:
	return false

func commit_research() -> void:
	for upgrade in passive_levels:
		pending_passive_levels[upgrade] = int(passive_levels[upgrade])

func get_research_card_unlock_level(upgrade: String) -> int:
	return max(0, int(research_card_unlocks.get(upgrade, 0)))

func is_research_card_unlocked(upgrade: String) -> bool:
	if RESEARCH_CAP_UPGRADES.has(upgrade):
		return get_research_card_unlock_level(upgrade) > int(cap_levels.get(upgrade, 0))
	return get_research_card_unlock_level(upgrade) > 0

func _is_research_ship_available(ship_key: String) -> bool:
	return ship_key == "flagship" or ship_key == "mining_drone" or is_ship_unlocked(ship_key)

func get_research_hunt_candidates() -> Array[String]:
	var candidates: Array[String] = []
	for upgrade in RESEARCH_CAP_UPGRADES:
		var data: Dictionary = RESEARCH_CAP_UPGRADES[upgrade]
		if _is_research_ship_available(str(data["ship"])) and get_research_card_unlock_level(upgrade) <= int(cap_levels.get(upgrade, 0)):
			candidates.append(str(upgrade))
	for upgrade in passive_levels:
		var ship_key = "mining_drone" if str(upgrade).begins_with("drone_") else "flagship"
		if _is_research_ship_available(ship_key) and get_passive_level(upgrade) <= 0 and get_research_card_unlock_level(upgrade) <= 0:
			candidates.append(str(upgrade))
	return candidates

func create_research_hunt() -> Dictionary:
	var candidates = get_research_hunt_candidates()
	if candidates.is_empty():
		return {}
	var hunt_index = research_hunt_count
	research_hunt_count += 1
	var target_key = candidates[hunt_index % candidates.size()]
	var rank = int(cap_levels.get(target_key, 0)) + 1 if RESEARCH_CAP_UPGRADES.has(target_key) else 1
	var difficulty_scale = pow(1.5, float(max(0, rank - 1))) * (1.0 + float(prestige_level) * 0.2)
	var target_name = target_key.capitalize()
	if RESEARCH_CAP_UPGRADES.has(target_key):
		var cap_data: Dictionary = RESEARCH_CAP_UPGRADES[target_key]
		target_name = "%s %s Rank %d" % [str(cap_data["ship"]).capitalize(), str(cap_data["name"]), rank]
	return {
		"battle_type": "research_hunt",
		"enemy_name": get_boss_name(hunt_index),
		"enemy_max_hp": max(500, int(round(1500.0 * difficulty_scale))),
		"enemy_dps": max(2, int(round(5.0 * difficulty_scale))),
		"enemy_drone_count": 0,
		"enemy_drone_hp": 0,
		"enemy_drone_dps": 0,
		"research_card": target_key,
		"research_card_rank": rank,
		"research_card_name": target_name
	}

const boss_names: Array[String] = [
	"Argoai the Pirate",
	"Rouge Drone Center",
	"Vania",
	"The Iron Warden",
	"Void Herald",
	"Admiral Kestrel",
	"Victoria, Undesirable",
	"Captain Williams, Isolationist Govenor",
	"Demon Hunter; Kalia",
	"Algoes Raider",
	"Rouge Drone Unit",
	"Blasto The Constipated",
	"Greeny The Gardener",
	"Riley The Unbeaten",
	"Sweet Connoisseur",
	"Malazahar, Cosmic Sucker",
	"Gummy Eater Lucy",
	"Titan-Ussop",
	"Admiral Strat",
	"Blood Thirsty Doli",
	"Volt Bringer",
	"Ancient Xakar",
	"Josh The Maybe Desirable",
	"Emma, Cosmic Queen",
	"Voyager Timeless",
	"Matt, Orange Cats Collector",
	"Vegtable, Dragon Rider X",
	"Admiral Roland",
	"Garp Thruster",
	"Designated Survivor",
	"Cuddly Aragog",
	"Hairy Giant Gridih",
	"Unknown Alien L",
	"Unknown Alien R",
	"Seven Eyed Humanoid",
	"Kyle, Swimming with ducks",
	"Disgruntled Voice Actor Krib",
	"Cleaning Lady",
	"Cleaner Lady",
	"Grimlock",
	"Parry Crazed Scientist",
	"Eight Armed Willy",
	"Shelob",
	"Shemanian, confused individual",
	"Spider-species Acromants",
	"Lizard-species Nomaerain",
	"Dragon-species Drakons",
	"Baron of Ninth corner",
	"Large Mom",
	"Aligator, Croc hunter",
	"Portu, Donqui",
	"Carrot and Rabbit",
	"Rob, Brick layer",
	"Smoker of fine vintages",
	"Mayor Cameron",
	"Galaxies greatest pilot",
	"Galaxies worst mechanic",
	"Yeltrah, The summoner",
	"Spicey Kiwi Holder",
	"Axe Wielding Susan",
	"Commander Selpard",
	"Captain Pryce",
	"Forged Drone Unit XYANS",
	"Drone KoK0",
	"Drone Z3ro0r",
	"IamHuman",
	"Clone Leader Zoras",
	"Magic Wizard Ricardo, Staff Weilder of Cosmic Powers",
	"Songoeku",
	"Captain Bego",
	"Lonesome Wielder of Three swords",
	"Sir. 3",
	"Copier of Clerif",
	"Plague carrier Ship Xeris",
	"Pirate Broggy",
	"Overunned Merchant Ship",
	"Dougin, Jewerly Merchant",
	"Mitch of Platinum Plates",
]

func get_boss_name(boss_index: int) -> String:
	if boss_names.is_empty():
		return "unknown enemy"
	return boss_names[posmod(boss_index, boss_names.size())]

func get_save_state() -> Dictionary:
	return {
		"research_points": research_points,
		"cap_levels": cap_levels.duplicate(true),
		"pending_cap_levels": pending_cap_levels.duplicate(true),
		"passive_levels": passive_levels.duplicate(true),
		"pending_passive_levels": pending_passive_levels.duplicate(true),
		"claimed_prestige_rewards": claimed_prestige_rewards.duplicate(true),
		"unlocked_ships": unlocked_ships.duplicate(true),
		"ship_stats": ship_stats.duplicate(true),
		"research_card_unlocks": research_card_unlocks.duplicate(true),
		"research_hunt_count": research_hunt_count,
		"boss_tier": boss_tier,
		"prestige_level": prestige_level,
		"prestige_ready": prestige_ready,
		"auto_claim_rewards": auto_claim_rewards
	}

func apply_save_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	research_points = int(state.get("research_points", research_points))
	if state.has("boss_tier"):
		boss_tier = int(state.get("boss_tier", boss_tier))
	else:
		boss_tier = _boss_tier_from_difficulty(int(state.get("boss_difficulty", 1)))
	prestige_level = max(0, int(state.get("prestige_level", prestige_level)))
	prestige_ready = false
	auto_claim_rewards = false
	claimed_prestige_rewards = state.get("claimed_prestige_rewards", claimed_prestige_rewards).duplicate(true)
	var saved_unlocked_ships = state.get("unlocked_ships", {})
	for ship_key in unlocked_ships:
		unlocked_ships[ship_key] = bool(saved_unlocked_ships.get(ship_key, unlocked_ships[ship_key]))
	_synchronize_prestige_rewards()
	var saved_ship_stats = state.get("ship_stats", {})
	for ship_key in ship_stats:
		if saved_ship_stats.has(ship_key):
			ship_stats[ship_key] = saved_ship_stats[ship_key]
	var saved_cap_levels = state.get("cap_levels", {})
	var saved_pending_cap_levels = state.get("pending_cap_levels", saved_cap_levels)
	for upgrade in cap_levels:
		cap_levels[upgrade] = int(saved_cap_levels.get(upgrade, cap_levels[upgrade]))
		pending_cap_levels[upgrade] = int(saved_pending_cap_levels.get(upgrade, cap_levels[upgrade]))
	var saved_passive_levels = state.get("passive_levels", {})
	var saved_pending_passive_levels = state.get("pending_passive_levels", saved_passive_levels)
	for upgrade in passive_levels:
		var saved_level = int(saved_passive_levels.get(upgrade, passive_levels[upgrade]))
		var old_pending_level = int(saved_pending_passive_levels.get(upgrade, saved_level))
		passive_levels[upgrade] = _sanitize_passive_level(upgrade, max(saved_level, old_pending_level))
		pending_passive_levels[upgrade] = passive_levels[upgrade]
	research_card_unlocks = state.get("research_card_unlocks", {}).duplicate(true)
	research_hunt_count = max(0, int(state.get("research_hunt_count", 0)))
	# Purchased cards from older saves remain usable after card hunts were introduced.
	for upgrade in cap_levels:
		if int(cap_levels[upgrade]) > 0:
			research_card_unlocks[upgrade] = max(int(research_card_unlocks.get(upgrade, 0)), int(cap_levels[upgrade]))
	for upgrade in passive_levels:
		if int(passive_levels[upgrade]) > 0:
			research_card_unlocks[upgrade] = 1
	emit_signal("ship_modifiers_changed")

func _sanitize_passive_level(upgrade: String, level: int) -> int:
	if is_single_purchase_passive(upgrade):
		return min(1, max(0, level))
	return max(0, level)

func prepare_battle(run_state: Dictionary, battle_stats: Dictionary) -> void:
	saved_run_state = run_state.duplicate(true)
	pending_battle = battle_stats.duplicate(true)
	battle_return_pending = false
	battle_was_victory = false
	battle_was_prestige = false
	battle_advance_field_pending = false
	prestige_reset_pending = false
	surviving_drone_count = 0
	last_battle_message = ""

func calculate_research_reward(elapsed_time: float, field_level: int) -> int:
	var remaining_time = max(0.0, BATTLE_TIME_LIMIT - elapsed_time)
	var speed_bonus = int(floor(remaining_time / 20.0))
	var field_penalty = min(9, int(floor(float(field_level) / 3.0)))
	var boss_bonus = int(floor(float(boss_tier) / 2.0))
	return max(1, BASE_RESEARCH_REWARD + speed_bonus + boss_bonus - field_penalty)

func _boss_tier_from_difficulty(difficulty: int) -> int:
	var tier = 0
	var remaining_difficulty = max(1, difficulty)
	while remaining_difficulty > 1:
		tier += 1
		remaining_difficulty = int(floor(float(remaining_difficulty) / 2.0))
	return tier

func complete_battle(victory: bool, elapsed_time: float, battle_surviving_drone_count: int = 0) -> int:
	var reward = 0
	var battle_type = str(pending_battle.get("battle_type", "standard"))
	battle_return_pending = true
	battle_was_victory = victory
	battle_was_prestige = false
	surviving_drone_count = max(0, battle_surviving_drone_count)
	if battle_type == "research_hunt":
		if victory:
			var card_key = str(pending_battle.get("research_card", ""))
			var card_rank = max(1, int(pending_battle.get("research_card_rank", 1)))
			if not card_key.is_empty():
				research_card_unlocks[card_key] = max(get_research_card_unlock_level(card_key), card_rank)
			reward = calculate_research_reward(elapsed_time, int(pending_battle.get("field_level", 0))) + int(floor(float(card_rank - 1) / 2.0))
			research_points += reward
			last_battle_message = "Research hunt won: %s unlocked, +%d research" % [str(pending_battle.get("research_card_name", "card")), reward]
		else:
			last_battle_message = "Research hunt failed: returned to mining"
	elif victory:
		reward = calculate_research_reward(elapsed_time, int(pending_battle.get("field_level", 0)))
		research_points += reward
		boss_tier += 1
		battle_advance_field_pending = true
		last_battle_message = "Battle won: +%d research, enemy fleet strengthened" % reward
	else:
		battle_advance_field_pending = true
		last_battle_message = "Battle failed: returned to mining"
	pending_battle = {}
	return reward

func reset_for_prestige(force: bool = false) -> bool:
	var target_prestige = prestige_level + 1
	if not PRESTIGE_LEVELS.has(target_prestige):
		return false
	commit_research()
	prestige_level = target_prestige
	boss_tier = 0
	prestige_ready = false
	_synchronize_prestige_rewards()
	return true

func consume_battle_return_pending() -> bool:
	var was_pending = battle_return_pending
	battle_return_pending = false
	battle_advance_field_pending = false
	prestige_reset_pending = false
	battle_was_prestige = false
	return was_pending
