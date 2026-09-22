class_name EchoBattle
extends RefCounted
## 1v1 turn resolution for Echo 01. No scene, no save, no mid-fight persist.
## Mercy floor and turn-1 protection apply to the Keeper only.

const ECHO_ID: String = "echo_keeper_01"
const MERCY_FRACTION: float = 0.10
const KEEPER_CRIT_MULT: float = 2.0
const STAT_ORDER: Array[String] = [
	"might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"
]

var echo_name: String = "Elaia"
var keeper_max_hp: int = 50
var echo_max_hp: int = 60
var keeper_hp: int = 50
var echo_hp: int = 60
var keeper: Dictionary = {}
var echo: Dictionary = {}
var echo_crit_mult: float = 1.2
var spare_window: bool = false
var outcome: String = ""
var enemy_attacks: int = 0
var last_keeper_damage: int = 0
var last_echo_damage: int = 0
var last_keeper_crit: bool = false
var log: PackedStringArray = PackedStringArray()
## 0 = never, 1 = always, -1 = roll Fate × 1%.
var force_crit: int = -1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _log_line(key: String, tokens: Dictionary = {}) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var cs: Node = tree.root.get_node_or_null("ContentStrings")
		if cs != null and cs.has_method("get_text"):
			log.append(str(cs.call("get_text", key, tokens)))
			return
	log.append(key)


static func hp_max_for(vitality: int) -> int:
	return maxi(1, vitality * 10)


static func raw_damage(attack: int, defense: int) -> int:
	return maxi(0, (attack - defense) * 10)


static func rank_cost(rank: int, base: int = 100, growth: float = 1.65) -> int:
	return int(floor(float(base) * pow(growth, float(rank)) + 0.0000001))


static func ranked_stat_ids(ranks: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for sid: String in STAT_ORDER:
		ids.append(sid)
	for i: int in range(1, ids.size()):
		var key: String = ids[i]
		var j: int = i - 1
		while j >= 0 and _sorts_after(ids[j], key, ranks):
			ids[j + 1] = ids[j]
			j -= 1
		ids[j + 1] = key
	return ids


static func _sorts_after(left: String, right: String, ranks: Dictionary) -> bool:
	## True when `left` belongs later than `right` (lower rank, then later tie-break).
	var left_rank: int = int(ranks.get(left, 0))
	var right_rank: int = int(ranks.get(right, 0))
	if left_rank != right_rank:
		return left_rank < right_rank
	return STAT_ORDER.find(left) > STAT_ORDER.find(right)


static func payout(kind: String, ranks: Dictionary, fate_total: int, base: int = 100, growth: float = 1.65) -> int:
	var ordered: Array[String] = ranked_stat_ids(ranks)
	if ordered.size() < 3:
		return 0
	var mult: float = 1.0 + float(fate_total) / 100.0
	var shards: float = 0.0
	if kind == "spare":
		var third: String = ordered[2]
		shards = float(rank_cost(int(ranks.get(third, 0)), base, growth)) * mult
	elif kind == "defeat":
		var highest: String = ordered[0]
		var highest_rank: int = int(ranks.get(highest, 0))
		shards = float(rank_cost(highest_rank, base, growth) + rank_cost(highest_rank + 1, base, growth)) * mult
	else:
		return 0
	return int(floor(shards))


func configure(keeper_totals: Dictionary, echo_def: Dictionary) -> void:
	_rng.randomize()
	var estats_v: Variant = echo_def.get("stats", {})
	var estats: Dictionary = estats_v if typeof(estats_v) == TYPE_DICTIONARY else {}
	keeper = {
		"might": int(keeper_totals.get("might", 5)),
		"arcana": int(keeper_totals.get("arcana", 5)),
		"resilience": int(keeper_totals.get("resilience", 5)),
		"ward": int(keeper_totals.get("ward", 5)),
		"vitality": int(keeper_totals.get("vitality", 5)),
		"swiftness": int(keeper_totals.get("swiftness", 5)),
		"fate": int(keeper_totals.get("fate", 5)),
	}
	echo = {
		"might": int(estats.get("might", 4)),
		"arcana": int(estats.get("arcana", 7)),
		"resilience": int(estats.get("resilience", 5)),
		"ward": int(estats.get("ward", 7)),
		"vitality": int(estats.get("vitality", 6)),
		"swiftness": int(estats.get("swiftness", 6)),
		"fate": int(estats.get("fate", 5)),
	}
	echo_name = str(echo_def.get("display_name", "Elaia"))
	echo_crit_mult = float(echo_def.get("crit_multiplier", 1.2))
	keeper_max_hp = hp_max_for(int(keeper["vitality"]))
	echo_max_hp = hp_max_for(int(echo["vitality"]))
	keeper_hp = keeper_max_hp
	echo_hp = echo_max_hp
	spare_window = false
	outcome = ""
	enemy_attacks = 0
	last_keeper_damage = 0
	last_echo_damage = 0
	last_keeper_crit = false
	log = PackedStringArray()


func keeper_acts_first() -> bool:
	return int(keeper.get("swiftness", 5)) >= int(echo.get("swiftness", 6))


func available_actions() -> PackedStringArray:
	if outcome != "":
		return PackedStringArray()
	if spare_window:
		return PackedStringArray(["strike", "spare"])
	return PackedStringArray(["strike", "flee"])


func choose(action: String) -> String:
	if outcome != "":
		return "resolved"
	if spare_window:
		if action == "flee":
			return "no_flee"
		if action == "spare":
			_log_line("battle_log_spare", {"enemy": echo_name})
			_finish("spare")
			return "spare"
		if action == "strike":
			_strike_to_finish()
			return "defeat"
		return "invalid"
	if action == "flee":
		return _flee()
	if action == "strike":
		return _strike_round()
	if action == "spare":
		return "locked"
	return "invalid"


func _flee() -> String:
	if not keeper_acts_first():
		_echo_attack()
		if outcome != "":
			return outcome
	_finish("flee")
	_log_line("battle_log_flee")
	return "flee"


func _strike_round() -> String:
	if keeper_acts_first():
		_keeper_strike()
		if outcome != "" or spare_window:
			return "spare_window" if spare_window and outcome == "" else outcome
		_echo_attack()
		if outcome != "":
			return outcome
		return "continue"
	_echo_attack()
	if outcome != "":
		return outcome
	_keeper_strike()
	if spare_window and outcome == "":
		return "spare_window"
	if outcome != "":
		return outcome
	return "continue"


func _keeper_strike() -> void:
	var dealt: int = _rolled_damage(
		int(keeper["might"]),
		int(echo["resilience"]),
		int(keeper["fate"]),
		KEEPER_CRIT_MULT,
		true
	)
	last_keeper_damage = dealt
	var above_mercy: bool = float(echo_hp) > MERCY_FRACTION * float(echo_max_hp)
	var next_hp: int = echo_hp - dealt
	if dealt <= 0:
		_log_line("battle_log_miss")
	elif above_mercy and next_hp <= 0:
		echo_hp = 1
		_log_line("battle_log_mercy_floor", {"enemy": echo_name})
	else:
		echo_hp = maxi(0, next_hp)
		if last_keeper_crit:
			_log_line("battle_log_crit_you")
		else:
			_log_line("battle_log_strike_you")
	if echo_hp <= 0:
		_finish("defeat")
		_log_line("battle_log_defeat", {"enemy": echo_name})
		return
	if float(echo_hp) < MERCY_FRACTION * float(echo_max_hp):
		spare_window = true


func _strike_to_finish() -> void:
	var dealt: int = _rolled_damage(
		int(keeper["might"]),
		int(echo["resilience"]),
		int(keeper["fate"]),
		KEEPER_CRIT_MULT,
		true
	)
	last_keeper_damage = dealt
	echo_hp = 0
	if last_keeper_crit:
		_log_line("battle_log_crit_you")
	else:
		_log_line("battle_log_strike_you")
	_finish("defeat")
	_log_line("battle_log_defeat", {"enemy": echo_name})


func _echo_attack() -> void:
	var first_hit: bool = enemy_attacks == 0
	var dealt: int = _rolled_damage(
		int(echo["arcana"]),
		int(keeper["ward"]),
		int(echo["fate"]),
		echo_crit_mult,
		false
	)
	last_echo_damage = dealt
	var next_hp: int = keeper_hp - dealt
	if first_hit and next_hp <= 0:
		keeper_hp = 1
		_log_line("battle_log_t1_floor", {"enemy": echo_name})
	else:
		keeper_hp = maxi(0, next_hp)
		_log_line("battle_log_strike_enemy", {"enemy": echo_name})
	enemy_attacks += 1
	if keeper_hp <= 0:
		_finish("ko")


func _rolled_damage(attack: int, defense: int, fate: int, crit_mult: float, track_keeper_crit: bool) -> int:
	var raw: int = raw_damage(attack, defense)
	var crit: bool = raw > 0 and _is_crit(fate)
	if track_keeper_crit:
		last_keeper_crit = crit
	if raw <= 0 or not crit:
		return raw
	return int(floor(float(raw) * crit_mult + 0.0000001))


func _is_crit(fate: int) -> bool:
	if force_crit == 0:
		return false
	if force_crit > 0:
		return true
	return _rng.randf() < float(fate) * 0.01


func _finish(result: String) -> void:
	outcome = result
	spare_window = false
