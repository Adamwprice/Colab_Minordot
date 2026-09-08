extends Node

const BATTLE_TIME_LIMIT := 60.0
const BASE_RESEARCH_REWARD := 5
const MAX_UPGRADE_BASE := 10
const CAP_INCREASE_PER_RESEARCH := 1
const CAP_RESEARCH_COST := 1
const PRESTIGE_BOSS_TIER_INTERVAL := 5
const PASSIVE_COSTS := {
	"drone_mining_lasers": 60,
	"drone_ion_thrusts": 40,
	"flagship_hull": 10,
	"flagship_armor": 10,
	"flagship_shield": 10,
}

var research_points: int = 0
var cap_levels := {
	"click_output": 0,
	"click_multiplier": 0,
	"speed": 0,
	"mining": 0,
	"drone_multiplier": 0,
	"capacity": 0,
	"drones": 0,
	"flagship_speed": 0
}
var pending_cap_levels := {}
var passive_levels := {
	"drone_mining_lasers": 0,
	"drone_ion_thrusts": 0,
	"flagship_hull": 0,
	"flagship_armor": 0,
	"flagship_shield": 0,
}
var pending_passive_levels := {}
var boss_tier: int = 0
var prestige_level: int = 0

var pending_battle := {}
var saved_run_state := {}
var battle_return_pending: bool = false
var battle_was_victory: bool = false
var surviving_drone_count: int = 0
var last_battle_message: String = ""

func _ready() -> void:
	for upgrade in cap_levels:
		pending_cap_levels[upgrade] = int(cap_levels[upgrade])
	for upgrade in passive_levels:
		pending_passive_levels[upgrade] = int(passive_levels[upgrade])

func get_upgrade_cap(upgrade: String) -> int:
	return MAX_UPGRADE_BASE + int(cap_levels.get(upgrade, 0)) * CAP_INCREASE_PER_RESEARCH

func get_pending_upgrade_cap(upgrade: String) -> int:
	return MAX_UPGRADE_BASE + int(pending_cap_levels.get(upgrade, cap_levels.get(upgrade, 0))) * CAP_INCREASE_PER_RESEARCH

func get_research_cost(upgrade: String) -> int:
	return CAP_RESEARCH_COST

func get_passive_level(upgrade: String) -> int:
	return int(passive_levels.get(upgrade, 0))

func get_pending_passive_level(upgrade: String) -> int:
	return int(pending_passive_levels.get(upgrade, passive_levels.get(upgrade, 0)))

func get_passive_cost(upgrade: String) -> int:
	return int(PASSIVE_COSTS.get(upgrade, 0))

func get_effective_boss_tier() -> int:
	return boss_tier + int(floor(float(prestige_level) / float(PRESTIGE_BOSS_TIER_INTERVAL)))

func buy_cap_upgrade(upgrade: String) -> bool:
	if not cap_levels.has(upgrade):
		return false
	var cost = get_research_cost(upgrade)
	if research_points < cost:
		return false
	research_points -= cost
	pending_cap_levels[upgrade] = int(pending_cap_levels.get(upgrade, cap_levels[upgrade])) + 1
	return true

func buy_passive_upgrade(upgrade: String) -> bool:
	if not passive_levels.has(upgrade):
		return false
	if get_pending_passive_level(upgrade) > 0:
		return false
	var cost = get_passive_cost(upgrade)
	if research_points < cost:
		return false
	research_points -= cost
	pending_passive_levels[upgrade] = 1
	return true

func refund_cap_upgrade(upgrade: String) -> bool:
	var committed_level = int(cap_levels.get(upgrade, 0))
	var pending_level = int(pending_cap_levels.get(upgrade, committed_level))
	if pending_level <= committed_level:
		return false
	pending_cap_levels[upgrade] = pending_level - 1
	research_points += CAP_RESEARCH_COST
	return true

func refund_passive_upgrade(upgrade: String) -> bool:
	var committed_level = get_passive_level(upgrade)
	var pending_level = get_pending_passive_level(upgrade)
	if pending_level <= committed_level:
		return false
	pending_passive_levels[upgrade] = 0
	research_points += get_passive_cost(upgrade)
	return true

func commit_research() -> void:
	for upgrade in cap_levels:
		cap_levels[upgrade] = int(pending_cap_levels.get(upgrade, cap_levels[upgrade]))
	for upgrade in passive_levels:
		passive_levels[upgrade] = int(pending_passive_levels.get(upgrade, passive_levels[upgrade]))

func get_save_state() -> Dictionary:
	return {
		"research_points": research_points,
		"cap_levels": cap_levels.duplicate(true),
		"pending_cap_levels": pending_cap_levels.duplicate(true),
		"passive_levels": passive_levels.duplicate(true),
		"pending_passive_levels": pending_passive_levels.duplicate(true),
		"boss_tier": boss_tier,
		"prestige_level": prestige_level
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
	var saved_cap_levels = state.get("cap_levels", {})
	var saved_pending_cap_levels = state.get("pending_cap_levels", saved_cap_levels)
	for upgrade in cap_levels:
		cap_levels[upgrade] = int(saved_cap_levels.get(upgrade, cap_levels[upgrade]))
		pending_cap_levels[upgrade] = int(saved_pending_cap_levels.get(upgrade, cap_levels[upgrade]))
	var saved_passive_levels = state.get("passive_levels", {})
	var saved_pending_passive_levels = state.get("pending_passive_levels", saved_passive_levels)
	for upgrade in passive_levels:
		passive_levels[upgrade] = min(1, int(saved_passive_levels.get(upgrade, passive_levels[upgrade])))
		pending_passive_levels[upgrade] = min(1, int(saved_pending_passive_levels.get(upgrade, passive_levels[upgrade])))

func prepare_battle(run_state: Dictionary, battle_stats: Dictionary) -> void:
	saved_run_state = run_state.duplicate(true)
	pending_battle = battle_stats.duplicate(true)
	battle_return_pending = false
	battle_was_victory = false
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
	battle_return_pending = true
	battle_was_victory = victory
	surviving_drone_count = max(0, battle_surviving_drone_count)
	if victory:
		reward = calculate_research_reward(elapsed_time, int(pending_battle.get("field_level", 0)))
		research_points += reward
		boss_tier += 1
		last_battle_message = "Battle won: +%d research, enemy fleet strengthened" % reward
	else:
		last_battle_message = "Battle failed: returned to mining"
	pending_battle = {}
	return reward

func reset_for_prestige() -> void:
	commit_research()
	prestige_level += 1
	boss_tier = 0

func consume_battle_return_pending() -> bool:
	var was_pending = battle_return_pending
	battle_return_pending = false
	return was_pending
