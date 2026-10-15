class_name EchoBattle
extends RefCounted
## 1v1 turn resolution for Echo duels. No scene, no save, no mid-fight persist.
## Damage uses BATTLE_SCENE_DRAFT v4 §4 (`BattleResolver` + `BattleRng`).

const ECHO_ID: String = "echo_keeper_01"
const STAT_ORDER: Array[String] = [
	"might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"
]
const ROUND_CAP: int = 60

var echo_name: String = "Elaia"
## magical | physical | hybrid. Echo 1 stays magical (Arcana vs Ward).
var foe_attack_profile: String = "magical"
## snare (physical) or knot (magic) on a hybrid foe; arcana on a magical foe.
var last_foe_swing: String = ""
var foe_art_path: String = ""
var keeper_max_hp: int = 25
var echo_max_hp: int = 31
var keeper_hp: int = 25
var echo_hp: int = 31
var keeper: Dictionary = {}
var echo: Dictionary = {}
var spare_window: bool = false
var outcome: String = ""
var enemy_attacks: int = 0
var last_keeper_damage: int = 0
var last_echo_damage: int = 0
var last_keeper_crit: bool = false
var log: PackedStringArray = PackedStringArray()
## physical | magical | hybrid. Hybrid reads arrow_mode. Fists and stone_sword stay physical.
var strike_kind: String = "physical"
var arrow_mode: String = "physical"

var round: int = 0
var enemy_turns: int = 0
var rootbound: bool = false
var first_hit_used: bool = false
var timed_out: bool = false
var rootbind_every: int = 0
var salves_used: int = 0
var keeper_brace: bool = false
## Pack count after the last salve spend, so a load cannot quietly refund them.
var salves_remembered: int = -1
var turn_log: Array[Dictionary] = []

var _dice: BattleRng = BattleRng.new()


func _log_line(key: String, tokens: Dictionary = {}) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var cs: Node = tree.root.get_node_or_null("ContentStrings")
		if cs != null and cs.has_method("get_text"):
			log.append(str(cs.call("get_text", key, tokens)))
			return
	log.append(key)


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


func set_seed(seed: int) -> void:
	_dice = BattleRng.new()
	_dice.set_seed(seed)


func set_dice(dice: BattleRng) -> void:
	_dice = dice


func configure(keeper_totals: Dictionary, echo_def: Dictionary) -> void:
	_dice = BattleRng.new()
	_dice.set_seed(randi() & BattleRng.SEED_MASK)
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
		"arcana": int(estats.get("arcana", 6)),
		"resilience": int(estats.get("resilience", 7)),
		"ward": int(estats.get("ward", 8)),
		"vitality": int(estats.get("vitality", 7)),
		"swiftness": int(estats.get("swiftness", 7)),
		"fate": int(estats.get("fate", 30)),
	}
	echo_name = str(echo_def.get("display_name", "Elaia"))
	foe_art_path = str(echo_def.get("battle_art_path", ""))
	var profile: String = str(echo_def.get("attack_profile", "magical"))
	if profile == "physical" or profile == "hybrid":
		foe_attack_profile = profile
	else:
		foe_attack_profile = "magical"
	rootbind_every = int(echo_def.get("rootbind_every", 0))
	last_foe_swing = ""
	keeper_max_hp = BattleResolver.max_hp_for(int(keeper["vitality"]))
	echo_max_hp = BattleResolver.max_hp_for(int(echo["vitality"]))
	keeper_hp = keeper_max_hp
	echo_hp = echo_max_hp
	spare_window = false
	outcome = ""
	enemy_attacks = 0
	last_keeper_damage = 0
	last_echo_damage = 0
	last_keeper_crit = false
	log = PackedStringArray()
	round = 0
	enemy_turns = 0
	rootbound = false
	first_hit_used = false
	timed_out = false
	salves_used = 0
	keeper_brace = false
	salves_remembered = -1
	turn_log = []


func keeper_acts_first() -> bool:
	var ks: int = int(keeper.get("swiftness", 5))
	var es: int = int(echo.get("swiftness", 6))
	if ks == es:
		return true
	return ks > es


func available_actions() -> PackedStringArray:
	if outcome != "":
		return PackedStringArray()
	if spare_window:
		return PackedStringArray(["strike", "brace", "salve", "spare"])
	return PackedStringArray(["strike", "brace", "salve", "flee"])


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
		if action == "brace":
			return _brace()
		if action == "salve" or action == "item":
			return _salve()
		return "invalid"
	if action == "flee":
		return _flee()
	if action == "strike":
		return _strike_round()
	if action == "brace":
		return _brace()
	if action == "salve" or action == "item":
		return _salve()
	if action == "spare":
		return "locked"
	return "invalid"


func salves_left() -> int:
	var pack: int = 0
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var bag: Node = tree.root.get_node_or_null("Backpack")
		if bag != null and bag.has_method("get_count"):
			pack = int(bag.call("get_count", "heart_salve"))
	return mini(EchoTheme.SALVE_MAX - salves_used, pack)


func _spend_salve() -> bool:
	if salves_used >= EchoTheme.SALVE_MAX:
		return false
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var bag: Node = tree.root.get_node_or_null("Backpack")
	if bag == null or not bag.has_method("try_spend"):
		return false
	if not bool(bag.call("try_spend", "heart_salve", 1)):
		return false
	salves_used += 1
	salves_remembered = int(bag.call("get_count", "heart_salve"))
	return true


func _brace() -> String:
	## Costs the Strike. The next landed Echo hit is halved (minimum 1).
	keeper_brace = true
	round += 1
	_log_line("battle_log_brace")
	_echo_turn()
	if outcome != "":
		return outcome
	_maybe_timeout()
	return "continue"


func _salve() -> String:
	if not _spend_salve():
		return "no_salve"
	var heal: int = BattleResolver.round_half_up(keeper_max_hp, 3, 10)
	keeper_hp = mini(keeper_max_hp, keeper_hp + heal)
	_log_line("battle_log_salve", {"amount": heal})
	round += 1
	_echo_turn()
	if outcome != "":
		return outcome
	_maybe_timeout()
	return "continue"


func _flee() -> String:
	if not keeper_acts_first():
		_echo_turn()
		if outcome != "":
			return outcome
	_finish("flee")
	_log_line("battle_log_flee")
	return "flee"


func _strike_round() -> String:
	round += 1
	if keeper_acts_first():
		_keeper_strike()
		if outcome != "" or spare_window:
			_maybe_timeout()
			return "spare_window" if spare_window and outcome == "" else outcome
		_echo_turn()
		if outcome != "":
			_maybe_timeout()
			return outcome
		_maybe_timeout()
		return "continue"
	_echo_turn()
	if outcome != "":
		_maybe_timeout()
		return outcome
	_keeper_strike()
	if spare_window and outcome == "":
		_maybe_timeout()
		return "spare_window"
	if outcome != "":
		_maybe_timeout()
		return outcome
	_maybe_timeout()
	return "continue"


func _maybe_timeout() -> void:
	if outcome != "" or spare_window:
		return
	if round >= ROUND_CAP:
		_timed_out_loss()


func _timed_out_loss() -> void:
	timed_out = true
	keeper_hp = maxi(0, keeper_hp)
	_log_line("battle_log_echo_timeout", {"enemy": echo_name})
	_finish("ko")


func resolved_strike_kind() -> String:
	if strike_kind == "hybrid":
		return "magical" if arrow_mode == "magical" else "physical"
	if strike_kind == "magical":
		return "magical"
	return "physical"


func toggle_arrow_mode() -> String:
	if strike_kind != "hybrid":
		return arrow_mode
	arrow_mode = "physical" if arrow_mode == "magical" else "magical"
	_log_line("battle_log_mode_mag" if arrow_mode == "magical" else "battle_log_mode_phys")
	return arrow_mode


func _keeper_attack_mode() -> String:
	return "magic" if resolved_strike_kind() == "magical" else "physical"


func _echo_attack_mode() -> String:
	if foe_attack_profile == "hybrid":
		var phys_margin: int = int(echo.get("might", 0)) - int((int(keeper.get("resilience", 5)) + int(keeper.get("swiftness", 5))) / 2)
		var mag_margin: int = int(echo.get("arcana", 0)) - int((int(keeper.get("ward", 5)) + int(keeper.get("swiftness", 5))) / 2)
		if mag_margin > phys_margin:
			return "magic"
		return "physical"
	if foe_attack_profile == "physical":
		return "physical"
	return "magic"


func _set_foe_swing(mode: String) -> void:
	if mode == "physical":
		last_foe_swing = "snare" if foe_attack_profile == "hybrid" else "might"
	else:
		last_foe_swing = "knot" if foe_attack_profile == "hybrid" else "arcana"


func _log_keeper_hit(dealt: int) -> void:
	if dealt <= 0:
		_log_line("battle_log_miss")
	elif last_keeper_crit:
		_log_line("battle_log_crit_you")
	else:
		_log_line("battle_log_strike_you")


func _keeper_strike() -> void:
	var mode: String = _keeper_attack_mode()
	var was_rootbound: bool = rootbound
	if was_rootbound:
		_log_line("battle_log_rootbound")
	var res: Dictionary = _resolve_swing("keeper", mode, echo, echo_hp, echo_max_hp, "echo")
	var resolver_damage: int = int(res.get("damage", 0))
	var damage: int = resolver_damage
	if was_rootbound:
		rootbound = false
		if resolver_damage > 0:
			damage = maxi(1, BattleResolver.round_half_up(resolver_damage, 1, 2))
	last_keeper_damage = damage
	last_keeper_crit = bool(res.get("fate_crit", false))
	var target_hp_before: int = echo_hp
	echo_hp -= damage
	_append_turn({
		"round": round,
		"actor": "keeper",
		"mode": mode,
		"band": str(res.get("band", "miss")),
		"fate_crit": last_keeper_crit,
		"resolver_damage": resolver_damage,
		"target_hp_before": target_hp_before,
		"rootbound": was_rootbound,
		"damage": damage,
		"keeper_hp": keeper_hp,
		"echo_hp": echo_hp,
	})
	_log_keeper_hit(damage)
	if echo_hp * 10 <= echo_max_hp:
		if echo_hp < 1:
			echo_hp = 1
			_log_line("battle_log_mercy_floor", {"enemy": echo_name})
		spare_window = true
	elif echo_hp <= 0:
		_finish("defeat")
		_log_line("battle_log_defeat", {"enemy": echo_name})


func _strike_to_finish() -> void:
	var mode: String = _keeper_attack_mode()
	var was_rootbound: bool = rootbound
	if was_rootbound:
		_log_line("battle_log_rootbound")
	var res: Dictionary = _resolve_swing("keeper", mode, echo, echo_hp, echo_max_hp, "echo")
	var resolver_damage: int = int(res.get("damage", 0))
	var damage: int = resolver_damage
	if was_rootbound:
		rootbound = false
		if resolver_damage > 0:
			damage = maxi(1, BattleResolver.round_half_up(resolver_damage, 1, 2))
	last_keeper_damage = damage
	last_keeper_crit = bool(res.get("fate_crit", false))
	echo_hp = 0
	_log_keeper_hit(damage)
	_finish("defeat")
	_log_line("battle_log_defeat", {"enemy": echo_name})


func _echo_turn() -> void:
	enemy_turns += 1
	if rootbind_every > 0 and enemy_turns % rootbind_every == 0:
		_do_rootbind()
		return
	enemy_attacks += 1
	var mode: String = _echo_attack_mode()
	_set_foe_swing(mode)
	var res: Dictionary = _resolve_swing("echo", mode, keeper, keeper_hp, keeper_max_hp, "party")
	var resolver_damage: int = int(res.get("damage", 0))
	var damage: int = resolver_damage
	if keeper_brace and damage > 0:
		damage = maxi(1, BattleResolver.round_half_up(damage, 1, 2))
		keeper_brace = false
	var first_hit_floor: bool = false
	if damage > 0 and not first_hit_used:
		first_hit_used = true
		var floor_hp: int = keeper_max_hp / 10 + 1
		var next_hp: int = keeper_hp - damage
		if next_hp < floor_hp:
			damage = keeper_hp - floor_hp
			first_hit_floor = true
	last_echo_damage = damage
	var target_hp_before: int = keeper_hp
	keeper_hp -= damage
	if first_hit_floor:
		_log_line("battle_log_t1_floor", {"enemy": echo_name})
	_append_turn({
		"round": round,
		"actor": "echo",
		"mode": mode,
		"band": str(res.get("band", "miss")),
		"fate_crit": bool(res.get("fate_crit", false)),
		"resolver_damage": resolver_damage,
		"target_hp_before": target_hp_before,
		"first_hit_floor": first_hit_floor,
		"damage": damage,
		"keeper_hp": keeper_hp,
		"echo_hp": echo_hp,
	})
	_log_line("battle_log_strike_enemy", {"enemy": echo_name})
	if keeper_hp * 10 <= keeper_max_hp:
		keeper_hp = maxi(0, keeper_hp)
		_finish("ko")


func _do_rootbind() -> void:
	last_foe_swing = "rootbind"
	rootbound = true
	_log_line("battle_log_rootbind", {"enemy": echo_name})
	_append_turn({
		"round": round,
		"actor": "echo",
		"rootbind": true,
		"keeper_hp": keeper_hp,
		"echo_hp": echo_hp,
	})


func _resolve_swing(actor_side: String, mode: String, defender_stats: Dictionary, defender_hp: int, defender_max_hp: int, defender_side: String) -> Dictionary:
	var attacker: Dictionary = {}
	if actor_side == "keeper":
		attacker = {
			"attack": mode,
			"might": int(keeper.get("might", 0)),
			"arcana": int(keeper.get("arcana", 0)),
			"fate": int(keeper.get("fate", 0)),
		}
	else:
		attacker = {
			"attack": mode,
			"might": int(echo.get("might", 0)),
			"arcana": int(echo.get("arcana", 0)),
			"fate": int(echo.get("fate", 0)),
		}
	var defender: Dictionary = {
		"resilience": int(defender_stats.get("resilience", 0)),
		"ward": int(defender_stats.get("ward", 0)),
		"swiftness": int(defender_stats.get("swiftness", 0)),
		"hp": defender_hp,
		"max_hp": defender_max_hp,
		"side": defender_side,
	}
	return BattleResolver.resolve(attacker, defender, 0, 1, 1, _dice)


func _append_turn(entry: Dictionary) -> void:
	turn_log.append(entry)


func keeper_fate() -> int:
	return int(keeper.get("fate", 0))


func _finish(result: String) -> void:
	outcome = result
	spare_window = false
