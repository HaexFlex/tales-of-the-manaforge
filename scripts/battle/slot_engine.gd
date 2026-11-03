class_name SlotEngine
extends RefCounted
## Pure slot helpers. No autoload writes. Idle rooms resolve through FightState.


const ROOM_SEC: float = 720.0
const REST_SLOTS: int = 2
const BOSS_EVERY: int = 10
const BOSS_ESSENCE: int = 15
const ROOMS_PER_HOUR: int = 5

const _KEEPER_STATS: Array[String] = [
	"might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate",
]


static func room_seed_for(run_seed: int, room_index: int) -> int:
	return BattleRng.mix_stream(run_seed, "room:%d" % room_index)


static func is_boss_index(room_index: int) -> bool:
	return room_index > 0 and room_index % BOSS_EVERY == 0


static func build_room(depth: int, room_seed: int, boss: bool) -> Array[Dictionary]:
	## Beasts roll first. Mossmites spend only the leftover threat, and boss rooms stay beast-only.
	return SpawnRoller.roll_room_with_mossmites(depth, SpawnRoller.room_seed_rng(room_seed), boss)


static func member_stats(member: String) -> Dictionary:
	var id: String = CompanionRoster.canonical_id(member)
	if id == "keeper" or CompanionRoster.has_id(id):
		return _sheet_stats_for(id)
	push_error("SlotEngine: unknown member %s" % member)
	return {}


static func _sheet_stats_for(actor: String) -> Dictionary:
	var stats: Dictionary = {}
	var equipment: Node = _autoload("Equipment")
	var keeper_stats: Node = _autoload("KeeperStats")
	for stat_id: String in _KEEPER_STATS:
		var value: int = 5
		if actor == "keeper":
			if equipment != null:
				value = int(equipment.call("total_for", stat_id))
			elif keeper_stats != null:
				value = int(keeper_stats.call("get_base", stat_id))
		else:
			var base: int = 0
			if keeper_stats != null:
				base = int(keeper_stats.call("get_base_for", actor, stat_id))
			var gear: int = 0
			if equipment != null:
				gear = int(equipment.call("gear_bonus_for", actor, stat_id))
			value = base + gear
		stats[stat_id] = value
	var attack: String = str(CompanionRoster.row(actor).get("attack", "physical"))
	if attack == "":
		attack = "physical"
	var weapon_abilities: Array[String] = []
	if equipment != null:
		var weapon_id: String = str(equipment.call("equipped_id_for", actor, "weapon"))
		var item_def: Dictionary = equipment.call("get_item_def", weapon_id)
		var abilities_v: Variant = item_def.get("abilities", [])
		if abilities_v is Array:
			for ability_v: Variant in abilities_v as Array:
				var ability_id: String = str(ability_v).strip_edges()
				if ability_id != "":
					weapon_abilities.append(ability_id)
		if str(item_def.get("damage_kind", "")) == "magical":
			attack = "magic"
		elif str(item_def.get("damage_kind", "")) == "physical":
			attack = "physical"
		elif str(item_def.get("damage_kind", "")) == "hybrid":
			var mode_node: Node = _autoload("GameState")
			var mode: String = str(mode_node.get("arrow_mode")) if mode_node != null else "physical"
			attack = "magic" if mode == "magical" else "physical"
	stats["attack"] = attack
	stats["weapon_abilities"] = weapon_abilities
	return stats


static func fight_for_room(party: Array, loadout: Dictionary, room: Array[Dictionary], room_seed: int) -> FightState:
	var fight: FightState = FightState.new()
	var index: int = 0
	for entry_v: Variant in party:
		if typeof(entry_v) != TYPE_DICTIONARY:
			index += 1
			continue
		var entry: Dictionary = entry_v
		var who: String = str(entry.get("member", ""))
		var row: String = str(entry.get("row", "front"))
		var stats_v: Variant = entry.get("stats", {})
		var stats: Dictionary = stats_v if typeof(stats_v) == TYPE_DICTIONARY else {}
		var formation_cell: int = -1
		if entry.has("cell"):
			formation_cell = int(entry.get("cell", -1))
		fight.add_member(who, stats, index, row, who, formation_cell)
		index += 1
	for beast_row: Dictionary in room:
		var bugs: int = int(beast_row.get("bugs", -1))
		var beast_id: String = fight.add_beast(
			str(beast_row.get("beast", "")),
			int(beast_row.get("slot", 0)),
			str(beast_row.get("row", "front")),
			"",
			bugs
		)
		if bool(beast_row.get("boss", false)) and beast_id != "":
			fight.set_boss(beast_id)
	fight.set_combat_seed(BattleRng.mix_stream(room_seed, "combat"))
	fight.loadout = loadout.duplicate()
	return fight


static func resolve_idle_room(party: Array, loadout: Dictionary, depth: int, room_index: int, room_seed: int) -> Dictionary:
	var boss: bool = is_boss_index(room_index)
	var room: Array[Dictionary] = build_room(depth, room_seed, boss)
	var fight: FightState = fight_for_room(party, loadout, room, room_seed)
	fight.controller = "idle"
	var outcome: String = AutoPolicy.run_idle(fight)
	if outcome != "win" and outcome != "flee" and outcome != "overwhelmed":
		push_error("SlotEngine: unexpected outcome %s" % outcome)
		outcome = "overwhelmed"
	var loot: Dictionary = {}
	var exp_mult: int = 1
	if outcome == "win":
		loot = RoomLoot.roll(depth, party.size(), boss, RoomLoot.loot_rng(room_seed))
		if boss:
			exp_mult = 2
	return {
		"outcome": outcome,
		"boss": boss,
		"loot": loot,
		"exp_mult": exp_mult,
		"loadout_after": fight.loadout.duplicate(),
		"salves_used": fight.salves_used,
		"rounds": fight.round,
		"fight": fight,
	}


static func _autoload(node_name: String) -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(node_name)
