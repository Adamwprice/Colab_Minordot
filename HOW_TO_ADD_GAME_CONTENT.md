# Adding Ships, Drones, and Research

This is the short workflow for adding or changing game content.

## Main Files

| File | Purpose |
| --- | --- |
| `scripts/data/ship_catalog.gd` | Shared prestige costs, lookup helpers, and the combined ship catalog. |
| `scripts/data/ships/*.gd` | Ship definitions grouped into Civilian, Military, Support, Utility, and foundation data. |
| `scripts/data/research/research_requirements.gd` | Ore-level requirements for starting research battles. |
| `scripts/systems/mining/resource_manager.gd` | Mining, income, movement, drone behavior, ore-upgrade effects, and saving. |
| `scripts/systems/combat/battle.gd` | Battle behavior, attacks, health, and combat effects. |
| `scripts/ui/map.gd` | Ship and drone placeholder visuals. |
| `scripts/core/game_state.gd` | Prestige, research victories, unlocks, and permanent stat modifiers. |

The catalog creates the UI and stores levels automatically. Gameplay effects still need to be implemented in the mining or combat system.

## Add A Ship

### 1. Add its prestige cost

In `PRESTIGE_COSTS` inside `ship_catalog.gd`, add the ship's prestige rank and ore cost:

```gdscript
21: 6374118109
```

Every ship rank must have a matching prestige cost.

### 2. Add the ship to its category file

Open the matching file in `scripts/data/ships`, then add the ship to its `SHIPS` dictionary. Use a unique lowercase ID. Do not change this ID later because saves use it.

```gdscript
"new_ship": {
	"rank": 21,
	"name": "New Ship",
	"category": "support",
	"description": "A short description of the ship.",
	"ore": [
		{"label": "ENGINE", "stat": "engine", "cost": 1000, "effect": "+10 movement speed"},
		{"label": "OUTPUT", "stat": "output", "cost": 2500, "effect": "+5 income"}
	],
	"research": [
		{"label": "Overdrive", "key": "new_ship_overdrive", "description": "Double engine speed.", "difficulty": 4.0}
	],
	"offset": Vector2(-40, 20)
}
```

Valid categories are:

- `civilian`
- `military`
- `support`
- `utility`

The ship will automatically receive:

- A prestige reward entry and dev unlock toggle.
- An ore-upgrade container under its category tab.
- An Upgrade Cap research card.
- Ore level saving, loading, and prestige resetting.
- A basic fleet marker and formation position.

### 3. Implement each ore effect

Read a ship upgrade with:

```gdscript
var engine_level = get_ship_upgrade_level("new_ship", "engine")
var speed = 200.0 + float(engine_level) * 10.0
```

Add mining and income effects to `resource_manager.gd`. Add combat effects to `battle.gd` or expose them through a getter in `resource_manager.gd`.

An upgrade belongs to the ship that contains it in `SHIPS`. It may affect the fleet only when its description explicitly says so.

### 4. Add special visuals or movement

- Add custom mining-scene behavior in `resource_manager.gd`.
- Add custom placeholder drawing in `map.gd`.
- Add battle movement or attacks in `battle.gd`.

The catalog's `offset` controls the ship's place in the mining-scene formation.

### 5. Optional ship profile

Only create a `ShipProfile` resource when the ship must use the category/role modifier system.

1. Add `scenes/resources/ship_profiles/new_ship.tres`.
2. Give it the same `ship_id` as the catalog.
3. Register it in `SHIP_PROFILES` in `game_state.gd`.

## Add A Drone Type

Drone types are called companions in the code.

### 1. Add it to `COMPANIONS`

```gdscript
"scout": {
	"name": "Scout Drones",
	"required_ship": "new_ship",
	"description": "Fast drones that inspect resource nodes.",
	"ore": [
		{"label": "SPEED", "stat": "speed", "cost": 500, "description": "+10 movement speed"},
		{"label": "SCANNER", "stat": "scanner", "cost": 1200, "description": "+5 scan range"}
	],
	"research": []
}
```

This automatically adds independent drone ore levels, costs, UI, save data, and prestige resetting.

### 2. Keep drone upgrades independent

Read a drone upgrade with:

```gdscript
var speed_level = get_companion_upgrade_level("scout", "speed")
```

Do not add `owner_ship` to a companion ore row. That would make the drone button modify a ship upgrade instead of its own upgrade.

Ship command upgrades can control how many drones exist. The drone's own upgrades should control that drone type's speed, output, capacity, or other behavior.

### 3. Implement behavior and visuals

1. Add spawn and activity logic to `resource_manager.gd` or `battle.gd`.
2. Return its visual data from `get_visual_subcraft()`.
3. Add its visual `kind` to `map.gd`.
4. Use the required ship's world position as its launch and return point.

## Add Research

### 1. Add a card to its ship

```gdscript
{"label": "Overdrive", "key": "new_ship_overdrive", "description": "Double engine speed.", "difficulty": 4.0}
```

Use a unique key beginning with the ship ID. The card, battle button, battle scaling, permanent victory state, and save data are generated automatically.

### 2. Implement the reward

Check whether the research battle has been won:

```gdscript
var game_state = get_node_or_null("/root/GameState")
if game_state and int(game_state.get_passive_level("new_ship_overdrive")) > 0:
	speed *= 2.0
```

One-time research effects are permanent after one victory, and their battles remain completed across prestige. Only repeated Upgrade Cap research resets on prestige.

### 3. Show ship research under a drone

Add the research card to the parent ship's `research` list first. Then reference the same key in the companion's `research` list:

```gdscript
{"label": "Drone Overdrive", "key": "new_ship_drone_overdrive", "description": "Double scout speed.", "requires_ship": "new_ship"}
```

Use the exact same key in both places. The UI will move that card from the ship row to the drone row.

## Design Endless Ore Upgrades

Avoid formulas such as this for an endlessly expandable upgrade:

```gdscript
interval = max(0.1, base_interval - level * 0.05)
```

Once the minimum is reached, later levels do nothing. Use a formula that continues improving instead.

### Output, damage, range, or capacity

Use additive growth:

```gdscript
value = base_value + effective_level * amount_per_level
```

### Timers, reload speed, or marker waiting

Convert levels into rate and calculate the interval from that rate:

```gdscript
interval = base_interval / (1.0 + effective_level * 0.12)
```

This is the recommended pattern for Racer Awareness. Every level helps, but later levels give a smaller absolute time reduction and the interval never reaches zero.

### Percentage bonuses

Use multiplicative growth when the effect may grow forever:

```gdscript
multiplier = pow(1.05, effective_level)
```

Use an approaching curve when the percentage must stay below a limit:

```gdscript
bonus = maximum_bonus * (1.0 - exp(-0.08 * effective_level))
```

### Counts and unlocks

Use whole levels for ships, drones, projectiles, and other objects:

```gdscript
drone_count = int(floor(effective_level))
```

Fractional effective levels can still accumulate until another whole object is earned.

### True hard limits

Only add a limit to `scripts/systems/upgrades/ship_upgrade_overflow.gd` when every effect of that upgrade must stop improving for technical or gameplay reasons. Excess levels are then distributed among that ship's other upgrades with available capacity.

Runtime effects should read:

```gdscript
get_effective_ship_upgrade_level("new_ship", "engine")
```

Purchase levels and UI costs should read:

```gdscript
get_ship_upgrade_level("new_ship", "engine")
```

## Change Existing Content

- Change names, costs, descriptions, ranks, and categories in `ship_catalog.gd`.
- Change numerical effects where they are calculated in `resource_manager.gd` or `battle.gd`.
- Keep existing ship IDs, ore `stat` keys, and research `key` values stable to preserve saves.
- When changing an effect, update both its displayed description and its runtime calculation.
- Ship ore rows belong to ships. Companion ore rows belong to drone types.

## Quick Test Checklist

1. Use the prestige menu's dev toggle to unlock only the new ship.
2. Confirm the ship appears in the correct category tab.
3. Buy every ore upgrade once and confirm only the intended ship or drone changes.
4. Start its research battle and confirm victory activates the effect.
5. Save and reload to confirm levels remain.
6. Prestige and confirm ore upgrades and Upgrade Cap research reset, while one-time research stays active and completed.
7. Test mining and battle scenes for script errors.

