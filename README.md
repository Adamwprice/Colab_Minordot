Godot Mining Prototype "Astrobor"

Prototype for a 2D isometric mining/flotilla sim (Godot 4, GDScript).

How to open
- Install Godot 4.x
- Open this folder as a project in Godot
- Open `res://scenes/core/Main.tscn` and run

What is included
- Scenes are grouped under `scenes/core`, `scenes/combat`, and `scenes/entities`.
- Ship resources live in `scenes/resources/ship_profiles`.
- Scripts are grouped by responsibility under `scripts/core`, `scripts/data`, `scripts/entities`, `scripts/systems`, and `scripts/ui`.
- Integration checks live in `tests/integration`.

Notes
- Visuals are placeholder shapes and Labels for prototyping. Tweak values in scripts for balance.

Ship classification and modifiers
- Ship identity is stored in `ShipProfile` resources. A ship has one Civilian/Military category and any number of role flags.
- Current roles are Mining, Combat, Command, Support, Utility, Refining, and Drone.
- Runtime effects use `ShipStatModifier` resources registered through `GameState.add_ship_stat_modifier()`.
- A modifier can target one ship ID, one category, role flags, or a combination of those filters.
- Stats resolve in this order: base plus flat bonuses, then additive percentages, then multipliers.

Example: add 20% ore multiplier to every Civilian mining ship.
```gdscript
var modifier = ShipStatModifier.new()
modifier.source_id = &"civilian_mining_reward"
modifier.stat = ShipProfile.STAT_ORE_MULTIPLIER
modifier.operation = ShipStatModifier.Operation.ADDITIVE_PERCENT
modifier.value = 0.20
modifier.target_category = ShipProfile.Category.CIVILIAN
modifier.required_roles = ShipProfile.Role.MINING
GameState.add_ship_stat_modifier(modifier)
```

Remove all effects from that source with `GameState.remove_ship_stat_modifiers(&"civilian_mining_reward")`.


plans:

-Mining
-autobattler
-prestiging
