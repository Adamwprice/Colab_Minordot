extends Node

const Catalog = preload("res://scripts/ship_catalog.gd")

signal ship_modifiers_changed

const BATTLE_TIME_LIMIT := 60.0
const MAX_UPGRADE_BASE := 10
const PRESTIGE_BOSS_TIER_INTERVAL := 5
const FLAGSHIP_BASE_HP := 100
const CLICK_RATE_CAP_UPGRADE := "click_multiplier"
const REFINERY_GLOBAL_ORE_BONUS := 0.012
const RESEARCH_CAP_INCREASE := 2
const RESEARCH_BATTLE_SCALE := 1.3
var PASSIVE_RESEARCH_SHIPS := Catalog.get_passive_ship_map()
var PASSIVE_SINGLE_PURCHASES := PASSIVE_RESEARCH_SHIPS.keys()
var FIXED_RESEARCH_DIFFICULTY := Catalog.get_fixed_research_difficulty()
var PRESTIGE_LEVELS := Catalog.get_prestige_levels()
const DRONE_CAP_UPGRADES := ["speed", "mining", "mining_speed", "capacity"]
const FLAGSHIP_CAP_UPGRADES := ["click_output", "click_multiplier", "drones", "flagship_speed", "refining"]
const SHIP_PROFILES := {
	&"flagship": preload("res://scenes/ship_profiles/flagship.tres"),
	&"mining_drone": preload("res://scenes/ship_profiles/mining_drone.tres"),
	&"refinery": preload("res://scenes/ship_profiles/refinery.tres"),
	&"hammond": preload("res://scenes/ship_profiles/hammond.tres"),
	&"drone_carrier": preload("res://scenes/ship_profiles/drone_carrier.tres"),
	&"gethica": preload("res://scenes/ship_profiles/gethica.tres"),
	&"ambrossa": preload("res://scenes/ship_profiles/ambrossa.tres")
}

var RESEARCH_CAP_UPGRADES := Catalog.get_cap_definitions()
const GENERAL_CAP_MIGRATION := {
	"flagship_general_cap": ["flagship_command_capacity", "flagship_click_rate"],
	"mining_drone_general_cap": [],
	"refinery_general_cap": ["refinery_click_rate"],
	"hammond_general_cap": ["hammond_command_capacity", "hammond_click_rate"],
	"drone_carrier_general_cap": ["drone_carrier_command_capacity", "drone_carrier_click_rate"],
	"ambrossa_general_cap": []
}

var cap_levels := Catalog.get_default_cap_levels()
var pending_cap_levels := {}
var passive_levels := Catalog.get_default_passive_levels()
var pending_passive_levels := {}
var boss_tier: int = 0
var prestige_level: int = 0
var prestige_ready: bool = false
var auto_claim_rewards: bool = false
var fleet_maneuver_enabled: bool = false
var development_protocol_enabled: bool = false
var ship_stat_modifiers: Array[ShipStatModifier] = []
var claimed_prestige_rewards := {}
var unlocked_ships := Catalog.get_default_unlocked_ships()
var dev_ship_overrides := {}
var ship_stats := {
	"refinery": {
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
var research_battle_attempts := {}
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
	for ship_id in Catalog.get_ship_ids():
		if upgrade.begins_with("%s_" % ship_id):
			return StringName(ship_id)
	return &""

func get_upgrade_cap(upgrade: String) -> int:
	var cap = float(MAX_UPGRADE_BASE)
	var ship_id = _get_upgrade_ship_id(upgrade)
	if not ship_id.is_empty():
		var ship_data = Catalog.get_ship_data(str(ship_id))
		if not ship_data.is_empty() and upgrade.ends_with("_command_capacity"):
			cap = float(ship_data.get("base_cap", MAX_UPGRADE_BASE))
	for research_key in RESEARCH_CAP_UPGRADES:
		var research_data: Dictionary = RESEARCH_CAP_UPGRADES[research_key]
		if Array(research_data["ore_upgrades"]).has(upgrade):
			cap += float(int(cap_levels.get(research_key, 0)) * RESEARCH_CAP_INCREASE)
			break
	if not ship_id.is_empty():
		cap = resolve_ship_stat(ship_id, ShipProfile.STAT_UPGRADE_CAP, cap)
	return max(0, int(round(cap)))

func get_pending_upgrade_cap(upgrade: String) -> int:
	return get_upgrade_cap(upgrade)

func get_click_rate_cap() -> int:
	return get_upgrade_cap(CLICK_RATE_CAP_UPGRADE)

func get_pending_click_rate_cap() -> int:
	return get_pending_upgrade_cap(CLICK_RATE_CAP_UPGRADE)

func get_research_cap_value(upgrade: String) -> int:
	if not RESEARCH_CAP_UPGRADES.has(upgrade):
		return MAX_UPGRADE_BASE
	return int(cap_levels.get(upgrade, 0)) * RESEARCH_CAP_INCREASE

func get_passive_level(upgrade: String) -> int:
	return int(passive_levels.get(upgrade, 0))

func get_pending_passive_level(upgrade: String) -> int:
	return get_passive_level(upgrade)

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

func get_flagship_picket_damage() -> float:
	return 2.0 if get_passive_level("flagship_picket_array") > 0 else 0.0

func is_fleet_maneuver_active() -> bool:
	return is_fleet_maneuver_unlocked() and fleet_maneuver_enabled

func is_fleet_maneuver_unlocked() -> bool:
	return get_passive_level("flagship_fleet_maneuver") > 0

func set_fleet_maneuver_enabled(enabled: bool) -> bool:
	fleet_maneuver_enabled = enabled and is_fleet_maneuver_unlocked()
	return fleet_maneuver_enabled

func is_development_protocol_unlocked() -> bool:
	return get_passive_level("flagship_development_protocol") > 0

func is_manual_drone_control_unlocked() -> bool:
	return get_passive_level("kradle_manual_control") > 0

func set_development_protocol_enabled(enabled: bool) -> bool:
	development_protocol_enabled = enabled and is_development_protocol_unlocked()
	return development_protocol_enabled

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

func dev_set_ship_enabled(ship_key: String, enabled: bool) -> bool:
	var ship_data = Catalog.get_ship_data(ship_key)
	if ship_data.is_empty() or int(ship_data.get("rank", 0)) <= 0:
		return false
	dev_ship_overrides[ship_key] = enabled
	emit_signal("ship_modifiers_changed")
	return enabled

func has_dev_ship_override(ship_key: String) -> bool:
	return dev_ship_overrides.has(ship_key)

func is_ship_unlocked(ship_key: String) -> bool:
	if dev_ship_overrides.has(ship_key):
		return bool(dev_ship_overrides[ship_key])
	if bool(unlocked_ships.get(ship_key, false)):
		return true
	var ship_data = Catalog.get_ship_data(ship_key)
	return not ship_data.is_empty() and int(ship_data.get("rank", 0)) > 0 and prestige_level >= int(ship_data["rank"])

func is_reward_claimed(reward_key: String) -> bool:
	return bool(claimed_prestige_rewards.get(reward_key, false))

func get_prestige_reward_level(reward_key: String) -> int:
	for target_prestige in PRESTIGE_LEVELS:
		if str(PRESTIGE_LEVELS[target_prestige]["ship"]) == reward_key:
			return int(target_prestige)
	return -1

func get_global_ore_multiplier() -> float:
	return 1.0

func get_ship_display_name(ship_key: String) -> String:
	return Catalog.get_display_name(ship_key)

func get_ship_category(ship_key: String) -> String:
	return Catalog.get_category(ship_key)

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
	return false

func buy_passive_upgrade(upgrade: String) -> bool:
	return false

func refund_cap_upgrade(upgrade: String) -> bool:
	return false

func refund_passive_upgrade(upgrade: String) -> bool:
	return false

func commit_research() -> void:
	for upgrade in passive_levels:
		pending_passive_levels[upgrade] = int(passive_levels[upgrade])

func get_research_card_unlock_level(upgrade: String) -> int:
	if RESEARCH_CAP_UPGRADES.has(upgrade):
		return max(0, int(cap_levels.get(upgrade, 0)))
	if passive_levels.has(upgrade):
		return max(0, int(passive_levels.get(upgrade, 0)))
	return 0

func is_research_card_unlocked(upgrade: String) -> bool:
	return get_research_card_unlock_level(upgrade) > 0

func _is_research_ship_available(ship_key: String) -> bool:
	return ship_key == "flagship" or ship_key == "mining_drone" or is_ship_unlocked(ship_key)

func _get_research_card_ship(upgrade: String) -> String:
	if RESEARCH_CAP_UPGRADES.has(upgrade):
		return str(RESEARCH_CAP_UPGRADES[upgrade]["ship"])
	return str(PASSIVE_RESEARCH_SHIPS.get(upgrade, ""))

func can_battle_research_card(upgrade: String) -> bool:
	var ship_key = _get_research_card_ship(upgrade)
	if ship_key.is_empty() or not _is_research_ship_available(ship_key):
		return false
	if passive_levels.has(upgrade):
		return get_passive_level(upgrade) <= 0
	return RESEARCH_CAP_UPGRADES.has(upgrade)

func get_research_battle_attempts(upgrade: String) -> int:
	return max(0, int(research_battle_attempts.get(upgrade, 0)))

func get_research_battle_multiplier(upgrade: String) -> float:
	if RESEARCH_CAP_UPGRADES.has(upgrade):
		return pow(RESEARCH_BATTLE_SCALE, float(int(cap_levels.get(upgrade, 0))))
	return float(FIXED_RESEARCH_DIFFICULTY.get(upgrade, 1.5))

func create_research_hunt(target_key: String) -> Dictionary:
	if not can_battle_research_card(target_key):
		return {}
	var hunt_index = research_hunt_count
	research_hunt_count += 1
	var rank = int(cap_levels.get(target_key, 0)) + 1 if RESEARCH_CAP_UPGRADES.has(target_key) else 1
	var difficulty_scale = get_research_battle_multiplier(target_key) * (1.0 + float(prestige_level) * 0.2)
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
		"cap_levels": cap_levels.duplicate(true),
		"pending_cap_levels": pending_cap_levels.duplicate(true),
		"passive_levels": passive_levels.duplicate(true),
		"pending_passive_levels": pending_passive_levels.duplicate(true),
		"claimed_prestige_rewards": claimed_prestige_rewards.duplicate(true),
		"unlocked_ships": unlocked_ships.duplicate(true),
		"dev_ship_overrides": dev_ship_overrides.duplicate(true),
		"ship_stats": ship_stats.duplicate(true),
		"research_card_unlocks": research_card_unlocks.duplicate(true),
		"research_hunt_count": research_hunt_count,
		"research_battle_attempts": research_battle_attempts.duplicate(true),
		"boss_tier": boss_tier,
		"prestige_level": prestige_level,
		"prestige_ready": prestige_ready,
		"auto_claim_rewards": auto_claim_rewards,
		"fleet_maneuver_enabled": fleet_maneuver_enabled,
		"development_protocol_enabled": development_protocol_enabled
	}

func apply_save_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	if state.has("boss_tier"):
		boss_tier = int(state.get("boss_tier", boss_tier))
	else:
		boss_tier = _boss_tier_from_difficulty(int(state.get("boss_difficulty", 1)))
	prestige_level = max(0, int(state.get("prestige_level", prestige_level)))
	prestige_ready = false
	auto_claim_rewards = false
	fleet_maneuver_enabled = bool(state.get("fleet_maneuver_enabled", false))
	development_protocol_enabled = bool(state.get("development_protocol_enabled", false))
	claimed_prestige_rewards = state.get("claimed_prestige_rewards", claimed_prestige_rewards).duplicate(true)
	var saved_unlocked_ships = state.get("unlocked_ships", {})
	for ship_key in unlocked_ships:
		unlocked_ships[ship_key] = bool(saved_unlocked_ships.get(ship_key, unlocked_ships[ship_key]))
	dev_ship_overrides = state.get("dev_ship_overrides", {}).duplicate(true)
	_synchronize_prestige_rewards()
	var saved_ship_stats = state.get("ship_stats", {})
	for ship_key in ship_stats:
		if saved_ship_stats.has(ship_key):
			ship_stats[ship_key] = saved_ship_stats[ship_key].duplicate(true)
	if ship_stats.has("refinery"):
		ship_stats["refinery"].erase("command_capacity")
	var saved_cap_levels = state.get("cap_levels", {})
	var saved_pending_cap_levels = state.get("pending_cap_levels", saved_cap_levels)
	for upgrade in cap_levels:
		var legacy_upgrade = "drone_multiplier" if upgrade == "refining" else upgrade
		cap_levels[upgrade] = int(saved_cap_levels.get(upgrade, saved_cap_levels.get(legacy_upgrade, cap_levels[upgrade])))
		pending_cap_levels[upgrade] = int(saved_pending_cap_levels.get(upgrade, saved_pending_cap_levels.get(legacy_upgrade, cap_levels[upgrade])))
	var saved_passive_levels = state.get("passive_levels", {})
	var saved_pending_passive_levels = state.get("pending_passive_levels", saved_passive_levels)
	for upgrade in passive_levels:
		var saved_level = int(saved_passive_levels.get(upgrade, passive_levels[upgrade]))
		var old_pending_level = int(saved_pending_passive_levels.get(upgrade, saved_level))
		passive_levels[upgrade] = _sanitize_passive_level(upgrade, max(saved_level, old_pending_level))
		pending_passive_levels[upgrade] = passive_levels[upgrade]
	fleet_maneuver_enabled = fleet_maneuver_enabled and is_fleet_maneuver_unlocked()
	development_protocol_enabled = development_protocol_enabled and is_development_protocol_unlocked()
	research_card_unlocks = state.get("research_card_unlocks", {}).duplicate(true)
	research_hunt_count = max(0, int(state.get("research_hunt_count", 0)))
	research_battle_attempts = state.get("research_battle_attempts", {}).duplicate(true)
	for general_key in GENERAL_CAP_MIGRATION:
		if not saved_cap_levels.has(general_key):
			var migrated_level = 0
			var migrated_unlock = 0
			for old_key in GENERAL_CAP_MIGRATION[general_key]:
				migrated_level = max(migrated_level, int(saved_cap_levels.get(old_key, 0)))
				migrated_unlock = max(migrated_unlock, int(research_card_unlocks.get(old_key, 0)))
			cap_levels[general_key] = migrated_level
			pending_cap_levels[general_key] = migrated_level
			research_card_unlocks[general_key] = max(migrated_level, migrated_unlock)
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
	battle_advance_field_pending = true
	surviving_drone_count = max(0, battle_surviving_drone_count)
	if get_passive_level("parallax_broad_tether") > 0:
		var original_drone_count = max(0, int(pending_battle.get("drone_count", surviving_drone_count)))
		for lost_drone in range(max(0, original_drone_count - surviving_drone_count)):
			if randf() < 0.05:
				surviving_drone_count += 1
	if battle_type == "research_hunt":
		if victory:
			var card_key = str(pending_battle.get("research_card", ""))
			var card_rank = max(1, int(pending_battle.get("research_card_rank", 1)))
			if RESEARCH_CAP_UPGRADES.has(card_key):
				cap_levels[card_key] = max(int(cap_levels.get(card_key, 0)), card_rank)
				pending_cap_levels[card_key] = cap_levels[card_key]
				research_card_unlocks[card_key] = cap_levels[card_key]
			elif passive_levels.has(card_key):
				passive_levels[card_key] = 1
				pending_passive_levels[card_key] = 1
				research_card_unlocks[card_key] = 1
			emit_signal("ship_modifiers_changed")
			last_battle_message = "Research victory: %s applied" % str(pending_battle.get("research_card_name", "card"))
		else:
			last_battle_message = "Research hunt failed: returned to mining"
	elif victory:
		boss_tier += 1
		last_battle_message = "Battle won: enemy fleet strengthened"
	else:
		last_battle_message = "Battle failed: returned to mining"
	pending_battle = {}
	return reward

func reset_for_prestige(force: bool = false) -> bool:
	var target_prestige = prestige_level + 1
	if not PRESTIGE_LEVELS.has(target_prestige):
		return false
	prestige_level = target_prestige
	boss_tier = 0
	prestige_ready = false
	for upgrade in cap_levels:
		cap_levels[upgrade] = 0
		pending_cap_levels[upgrade] = 0
	for upgrade in passive_levels:
		passive_levels[upgrade] = 0
		pending_passive_levels[upgrade] = 0
	development_protocol_enabled = false
	fleet_maneuver_enabled = false
	research_card_unlocks.clear()
	research_battle_attempts.clear()
	research_hunt_count = 0
	_synchronize_prestige_rewards()
	emit_signal("ship_modifiers_changed")
	return true

func consume_battle_return_pending() -> bool:
	var was_pending = battle_return_pending
	battle_return_pending = false
	battle_advance_field_pending = false
	prestige_reset_pending = false
	battle_was_prestige = false
	return was_pending
