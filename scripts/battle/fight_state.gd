class_name FightState
extends RefCounted
## Stepwise, serializable fight. One action per step. No scene calls this yet.
## Weave is a flat 30 on party fighters and 0 on beasts (they have none yet).
## Job 12 fills effective_swiftness, _on_turn_start, _beast_action and
## _apply_landed_damage. This job leaves those as the single call sites.


const RESOLVER_VERSION: int = 1
const WEAVE_BASE: int = 30
const LOG_TAIL_MAX: int = 20
const ROUND_CAP: int = 60
const BEASTS_PATH: String = "res://data/beasts.json"

var round: int = 0
var turn_cursor: int = 0
var order: Array[String] = []
var ambush: bool = false
var _outcome: String = ""
var twist: String = ""
var salves_used: int = 0
var controller: String = "manual"
var resolver_version: int = RESOLVER_VERSION
var rng_combat_seed: int = 1
var rng_combat_state: String = "0"
var log_tail: Array = []

var _rng: BattleRng
var _scripted_dice: BattleRng
var _fighters: Dictionary = {}

static var _catalog: Dictionary = {}
static var _catalog_ready: bool = false


func _init() -> void:
	_rng = BattleRng.new()
	set_combat_seed(1)


func set_combat_seed(seed_value: int) -> void:
	rng_combat_seed = BattleRng.mask_seed(seed_value)
	_rng.set_seed(rng_combat_seed)
	rng_combat_state = _rng.state_string()
	_scripted_dice = null


func add_member(member: String, stats: Dictionary, slot: int = 0, row: String = "front", fighter_id: String = "") -> String:
	var id: String = fighter_id if fighter_id != "" else member
	var attack: String = str(stats.get("attack", stats.get("kind", "physical")))
	return add_fighter(id, "party", stats, slot, row, attack, "", member)


func add_beast(species_id: String, slot: int = 0, row: String = "front", fighter_id: String = "") -> String:
	var spec: Dictionary = beast_row(species_id)
	if spec.is_empty():
		push_error("FightState: unknown beast %s" % species_id)
		return ""
	var id: String = fighter_id if fighter_id != "" else species_id
	return add_fighter(id, "beast", spec, slot, row, str(spec.get("attack", "physical")), species_id, "")


func add_fighter(fighter_id: String, side: String, stats: Dictionary, slot: int = 0, row: String = "front", attack: String = "", species: String = "", member: String = "") -> String:
	var id: String = _unique_id(fighter_id if fighter_id != "" else "fighter")
	var who := Fighter.new()
	who.id = id
	who.side = "party" if side == "party" else "beast"
	who.slot = slot
	who.row = "back" if row == "back" else "front"
	who.species = species
	who.member = member
	who.might = _stat(stats, "might", "mig")
	who.arcana = _stat(stats, "arcana", "arc")
	who.resilience = _stat(stats, "resilience", "res")
	who.ward = _stat(stats, "ward", "ward")
	who.vitality = _stat(stats, "vitality", "vit")
	who.swiftness = _stat(stats, "swiftness", "swi")
	who.fate = _stat(stats, "fate", "fate")
	var kind: String = attack if attack != "" else str(stats.get("attack", stats.get("kind", "physical")))
	who.attack = "magic" if (kind == "magic" or kind == "mag") else "physical"
	who.max_hp = BattleResolver.max_hp_for(who.vitality)
	who.hp = who.max_hp
	if stats.has("hp"):
		who.hp = int(stats["hp"])
	who.weave = WEAVE_BASE if who.side == "party" else 0
	who.shield = 0
	who.brace = false
	who.poison_ticks = []
	who.poison_left = 0
	who.turns = 0
	who.intent_move = ""
	who.intent_mult = 1
	who.boss = false
	who.status = BattleResolver.status_for(who.side, who.hp, who.max_hp)
	_fighters[id] = who
	order.append(id)
	return id


func set_hp(fighter_id: String, hp: int) -> void:
	var who := _fighter(fighter_id)
	if who == null:
		return
	who.hp = hp
	who.status = BattleResolver.status_for(who.side, who.hp, who.max_hp)


func set_scripted_dice(faces: Array) -> void:
	var queued: Array[int] = []
	for face: Variant in faces:
		queued.append(int(face))
	_scripted_dice = BattleRng.with_faces(queued)


func clear_scripted_dice() -> void:
	_scripted_dice = null


func scripted_remaining() -> int:
	if _scripted_dice == null:
		return 0
	return _scripted_dice.remaining()


func scripted_underrun() -> int:
	if _scripted_dice == null:
		return 0
	return _scripted_dice.underrun()


func scripted_queue() -> Array[int]:
	if _scripted_dice == null:
		return []
	return _scripted_dice.queued_faces()


func fighter_dict(fighter_id: String) -> Dictionary:
	var who := _fighter(fighter_id)
	if who == null:
		return {}
	return who.to_dict()


func strike(attacker: String, defender: String, to_hit_mod: int = 0, telegraph_mult: Variant = 1) -> Dictionary:
	## The blow `step` resolves. Ids are the refs stored in `order`.
	## telegraph_mult is an int (n/1), a Vector2i(num, den), or a float on a
	## half step (JSON 1.5 is 3/2). Damage itself never uses a float.
	var atk := _fighter(attacker)
	var dfn := _fighter(defender)
	if atk == null or dfn == null:
		push_error("FightState: strike missing fighter")
		return _empty_strike(dfn)
	var ratio: Vector2i = telegraph_ratio(telegraph_mult)
	var dice: BattleRng = _scripted_dice if _scripted_dice != null else _rng
	var result: Dictionary = BattleResolver.resolve(atk.to_dict(), dfn.to_dict(), to_hit_mod, ratio.x, ratio.y, dice)
	var damage: int = int(result["damage"])
	if damage > 0:
		_apply_landed_damage(dfn, damage)
	else:
		dfn.status = BattleResolver.status_for(dfn.side, dfn.hp, dfn.max_hp)
	result["defender_hp_after"] = dfn.hp
	result["defender_status"] = dfn.status
	if _scripted_dice == null:
		rng_combat_state = _rng.state_string()
	return result


func start_fight() -> void:
	## Round 1, order rebuilt (Ambush applies this round only), cursor on the first active actor.
	_outcome = ""
	_begin_round(1)
	_resolve_outcome(false)


func current_actor() -> String:
	if _outcome != "":
		return ""
	if turn_cursor < 0 or turn_cursor >= order.size():
		return ""
	var actor_id: String = order[turn_cursor]
	if not _is_active(_fighter(actor_id)):
		return ""
	return actor_id


func outcome() -> String:
	return _outcome


func effective_swiftness(id: String) -> int:
	## Job 12's Thicket change lands here. Ordering reads Swiftness only through this.
	var who := _fighter(id)
	if who == null:
		return 0
	return who.swiftness


func legal_targets(actor_id: String) -> Array[String]:
	var actor := _fighter(actor_id)
	var found: Array[String] = []
	if actor == null:
		return found
	var enemy: String = "beast" if actor.side == "party" else "party"
	var front_up: bool = _front_standing(enemy)
	var melee: bool = actor.attack != "magic"
	for key: Variant in _fighters.keys():
		var target_id: String = str(key)
		var foe := _fighter(target_id)
		if foe == null or foe.side != enemy or not _is_active(foe):
			continue
		if melee and front_up and foe.row != "front":
			continue
		found.append(target_id)
	return _sort_targets(found)


func to_hit_mod_for(actor_id: String, target_id: String) -> int:
	## Ranged into a back row while that side's front still stands is −2. Melee is 0.
	var actor := _fighter(actor_id)
	var target := _fighter(target_id)
	if actor == null or target == null or actor.side == target.side:
		return 0
	if actor.attack != "magic":
		return 0
	if target.row == "back" and _front_standing(target.side):
		return -2
	return 0


func beast_target(beast_id: String) -> String:
	## Weakest defense the beast can reach. Physical uses Resilience, magic uses Ward.
	## Ties: front row, then slot.
	var who := _fighter(beast_id)
	if who == null:
		return ""
	var best: String = ""
	for target_id: String in legal_targets(beast_id):
		if best == "" or _beast_prefers(who, target_id, best):
			best = target_id
	return best


func step(action: Dictionary = {}) -> Dictionary:
	## One action. Beasts ignore `action`. An illegal party action spends no turn and no dice.
	if _outcome != "":
		return _step_packet("", "", "", {}, round, "fight over")
	if round <= 0:
		return _step_packet("", "", "", {}, round, "not started")
	_advance_to_active()
	if turn_cursor >= order.size():
		_roll_round_if_spent()
		if _outcome != "":
			return _step_packet("", "", "", {}, round, "fight over")
	var actor_id: String = current_actor()
	if actor_id == "":
		return _step_packet("", "", "", {}, round, "no actor")
	var actor := _fighter(actor_id)
	if actor == null:
		return _step_packet("", "", "", {}, round, "no actor")
	var action_round: int = round
	var chosen: Dictionary = _beast_action(actor_id) if actor.side == "beast" else action
	var kind: String = str(chosen.get("kind", ""))
	var target_v: Variant = chosen.get("target", "")
	var target_id: String = "" if target_v == null else str(target_v)
	if kind != "strike" or not legal_targets(actor_id).has(target_id):
		if actor.side == "beast":
			_advance_cursor()
			if _outcome == "":
				_roll_round_if_spent()
			var beast_error: String = "no target" if kind == "strike" else "illegal action"
			return _step_packet(actor_id, kind, target_id, {}, action_round, beast_error)
		var party_error: String = "illegal target" if kind == "strike" else "illegal action"
		return _step_packet(actor_id, kind, target_id, {}, action_round, party_error)
	_on_turn_start(actor_id)
	if not _is_active(_fighter(actor_id)):
		_advance_cursor()
		if _outcome == "":
			_roll_round_if_spent()
		return _step_packet(actor_id, "", "", {}, action_round, "")
	var blow: Dictionary = strike(actor_id, target_id, to_hit_mod_for(actor_id, target_id), 1)
	actor.turns += 1
	_resolve_outcome(false)
	_advance_cursor()
	if _outcome == "":
		_roll_round_if_spent()
	return _step_packet(actor_id, "strike", target_id, blow, action_round, "")


func _on_turn_start(_id: String) -> void:
	## Job 12: poison ticks and Brace expiring, before the action.
	pass


func _beast_action(beast_id: String) -> Dictionary:
	## Job 12: a telegraphed intent replaces this plain Strike.
	return {"kind": "strike", "target": beast_target(beast_id)}


func _apply_landed_damage(defender: Fighter, damage: int) -> void:
	## Job 12: Brace halves this, then the shield absorbs the rest.
	defender.hp -= damage
	defender.status = BattleResolver.status_for(defender.side, defender.hp, defender.max_hp)


func to_dict() -> Dictionary:
	_sync_rng_state()
	_trim_log()
	var rows: Array = []
	var seen: Dictionary = {}
	for fighter_id: String in order:
		var who := _fighter(fighter_id)
		if who == null:
			continue
		rows.append(who.to_dict())
		seen[fighter_id] = true
	for key: Variant in _fighters.keys():
		var fighter_id: String = str(key)
		if seen.has(fighter_id):
			continue
		var extra := _fighter(fighter_id)
		if extra != null:
			rows.append(extra.to_dict())
	return {
		"round": round,
		"turn_cursor": turn_cursor,
		"order": order.duplicate(),
		"ambush": ambush,
		"outcome": _outcome,
		"twist": twist,
		"salves_used": salves_used,
		"controller": controller,
		"resolver_version": resolver_version,
		"rng_combat_seed": rng_combat_seed,
		"rng_combat_state": rng_combat_state,
		"log_tail": log_tail.duplicate(true),
		"fighters": rows,
	}


static func from_dict(data: Dictionary) -> FightState:
	var fight := FightState.new()
	fight.round = _as_int(data.get("round", 0))
	fight.turn_cursor = _as_int(data.get("turn_cursor", 0))
	fight.order.clear()
	var order_v: Variant = data.get("order", [])
	if order_v is Array:
		for item: Variant in order_v:
			fight.order.append(str(item))
	fight.ambush = _as_bool(data.get("ambush", false))
	var saved_outcome: String = str(data.get("outcome", ""))
	if saved_outcome == "win" or saved_outcome == "overwhelmed" or saved_outcome == "flee":
		fight._outcome = saved_outcome
	else:
		fight._outcome = ""
	fight.twist = str(data.get("twist", ""))
	fight.salves_used = _as_int(data.get("salves_used", 0))
	var saved_controller: String = str(data.get("controller", "manual"))
	fight.controller = saved_controller if saved_controller != "" else "manual"
	fight.resolver_version = _as_int(data.get("resolver_version", RESOLVER_VERSION))
	fight.rng_combat_seed = BattleRng.mask_seed(_as_int(data.get("rng_combat_seed", 1)))
	fight.rng_combat_state = str(data.get("rng_combat_state", "0"))
	fight.log_tail.clear()
	var tail: Variant = data.get("log_tail", [])
	if tail is Array:
		for entry: Variant in tail:
			fight.log_tail.append(entry)
	fight._trim_log()
	fight._fighters.clear()
	var listed: Dictionary = {}
	var rows: Variant = data.get("fighters", [])
	if rows is Array:
		for row_v: Variant in rows:
			if row_v is Dictionary:
				var who := Fighter.from_dict(row_v)
				fight._fighters[who.id] = who
				listed[who.id] = true
				if not fight.order.has(who.id):
					fight.order.append(who.id)
	var kept: Array[String] = []
	for fighter_id: String in fight.order:
		if listed.has(fighter_id):
			kept.append(fighter_id)
	fight.order = kept
	fight._rng.set_seed(fight.rng_combat_seed)
	fight._rng.set_state_string(fight.rng_combat_state)
	fight._scripted_dice = null
	return fight


static func beast_row(species_id: String) -> Dictionary:
	var catalog: Dictionary = _beast_catalog()
	if not catalog.has(species_id):
		return {}
	return (catalog[species_id] as Dictionary).duplicate(true)


static func telegraph_ratio(mult: Variant) -> Vector2i:
	if mult is Vector2i:
		var pair: Vector2i = mult as Vector2i
		return Vector2i(pair.x, pair.y if pair.y > 0 else 1)
	if mult is Dictionary:
		var ratio: Dictionary = mult as Dictionary
		return Vector2i(_as_int(ratio.get("num", 1)), maxi(1, _as_int(ratio.get("den", 1))))
	if mult is float:
		var halves: int = int(round(float(mult) * 2.0))
		if halves % 2 == 0:
			return Vector2i(halves / 2, 1)
		return Vector2i(halves, 2)
	return Vector2i(_as_int(mult, 1), 1)


static func _stat(stats: Dictionary, full_name: String, short_name: String) -> int:
	if stats.has(full_name):
		return int(stats[full_name])
	if short_name != "" and stats.has(short_name):
		return int(stats[short_name])
	return 0


static func _as_int(v: Variant, fallback: int = 0) -> int:
	if v == null:
		return fallback
	if v is String:
		return (v as String).to_int()
	return int(v)


static func _as_bool(v: Variant, fallback: bool = false) -> bool:
	if v == null:
		return fallback
	if v is bool:
		return v
	if v is int or v is float:
		return int(v) != 0
	return fallback


func _begin_round(next_round: int) -> void:
	round = next_round
	order = _sorted_ids()
	turn_cursor = 0
	_advance_to_active()


func _sorted_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in _fighters.keys():
		ids.append(str(key))
	var sorted: Array[String] = []
	for fighter_id: String in ids:
		var placed: bool = false
		for i: int in sorted.size():
			if _order_before(fighter_id, sorted[i]):
				sorted.insert(i, fighter_id)
				placed = true
				break
		if not placed:
			sorted.append(fighter_id)
	return sorted


func _order_before(a: String, b: String) -> bool:
	var ka: Array[int] = _order_key(a)
	var kb: Array[int] = _order_key(b)
	var n: int = ka.size()
	if kb.size() < n:
		n = kb.size()
	for i: int in n:
		if ka[i] < kb[i]:
			return true
		if ka[i] > kb[i]:
			return false
	return false


func _order_key(id: String) -> Array[int]:
	var who := _fighter(id)
	if who == null:
		return [1, 0, 0]
	var swift: int = effective_swiftness(id)
	var slot: int = who.slot
	if ambush and round == 1:
		var ambush_rank: int = 0 if who.side == "beast" else 1
		return [ambush_rank, -swift, slot]
	var side_rank: int = 0 if who.side == "party" else 1
	return [-swift, side_rank, slot]


func _advance_to_active() -> void:
	while turn_cursor < order.size():
		if _is_active(_fighter(order[turn_cursor])):
			return
		turn_cursor += 1


func _advance_cursor() -> void:
	turn_cursor += 1
	_advance_to_active()


func _roll_round_if_spent() -> void:
	_advance_to_active()
	if _outcome != "" or turn_cursor < order.size():
		return
	_resolve_outcome(true)
	if _outcome != "":
		return
	_begin_round(round + 1)
	_resolve_outcome(false)


func _resolve_outcome(round_finished: bool) -> void:
	## Win before overwhelmed. Flee only once round 60 has been played out.
	if _outcome != "":
		return
	if not _side_has_active("beast"):
		_outcome = "win"
		return
	if not _side_has_active("party"):
		_outcome = "overwhelmed"
		return
	if round_finished and round >= ROUND_CAP:
		_outcome = "flee"


func _side_has_active(side: String) -> bool:
	for key: Variant in _fighters.keys():
		var who := _fighter(str(key))
		if who != null and who.side == side and _is_active(who):
			return true
	return false


func _front_standing(side: String) -> bool:
	for key: Variant in _fighters.keys():
		var who := _fighter(str(key))
		if who != null and who.side == side and who.row == "front" and _is_active(who):
			return true
	return false


func _is_active(who: Fighter) -> bool:
	return who != null and who.status == "active"


func _sort_targets(ids: Array[String]) -> Array[String]:
	var sorted: Array[String] = []
	for fighter_id: String in ids:
		var placed: bool = false
		for i: int in sorted.size():
			if _target_list_before(fighter_id, sorted[i]):
				sorted.insert(i, fighter_id)
				placed = true
				break
		if not placed:
			sorted.append(fighter_id)
	return sorted


func _target_list_before(a: String, b: String) -> bool:
	var fa := _fighter(a)
	var fb := _fighter(b)
	var a_row: int = 0 if fa != null and fa.row == "front" else 1
	var b_row: int = 0 if fb != null and fb.row == "front" else 1
	if a_row != b_row:
		return a_row < b_row
	var a_slot: int = fa.slot if fa != null else 0
	var b_slot: int = fb.slot if fb != null else 0
	if a_slot != b_slot:
		return a_slot < b_slot
	return a < b


func _beast_prefers(who: Fighter, candidate: String, current: String) -> bool:
	var a := _fighter(candidate)
	var b := _fighter(current)
	if a == null:
		return false
	if b == null:
		return true
	var a_stat: int = a.ward if who.attack == "magic" else a.resilience
	var b_stat: int = b.ward if who.attack == "magic" else b.resilience
	if a_stat != b_stat:
		return a_stat < b_stat
	var a_row: int = 0 if a.row == "front" else 1
	var b_row: int = 0 if b.row == "front" else 1
	if a_row != b_row:
		return a_row < b_row
	if a.slot != b.slot:
		return a.slot < b.slot
	return candidate < current


func _step_packet(actor_id: String, kind: String, target_id: String, blow: Dictionary, action_round: int, error: String) -> Dictionary:
	return {
		"actor": actor_id,
		"kind": kind,
		"target": target_id,
		"strike": blow,
		"round": action_round,
		"outcome": _outcome,
		"error": error,
	}


func _sync_rng_state() -> void:
	rng_combat_state = _rng.state_string()


func _trim_log() -> void:
	while log_tail.size() > LOG_TAIL_MAX:
		log_tail.remove_at(0)


func _unique_id(wanted: String) -> String:
	if not _fighters.has(wanted):
		return wanted
	var n: int = 2
	var candidate: String = "%s_%d" % [wanted, n]
	while _fighters.has(candidate):
		n += 1
		candidate = "%s_%d" % [wanted, n]
	return candidate


func _fighter(fighter_id: String) -> Fighter:
	if not _fighters.has(fighter_id):
		return null
	return _fighters[fighter_id] as Fighter


func _empty_strike(defender: Fighter) -> Dictionary:
	var hp: int = 0
	var status: String = "active"
	if defender != null:
		hp = defender.hp
		status = defender.status
	return {
		"attack_total": 0,
		"defense_total": 0,
		"margin": 0,
		"band": "miss",
		"damage": 0,
		"fate_crit": false,
		"defender_hp_after": hp,
		"defender_status": status,
	}


static func _beast_catalog() -> Dictionary:
	if _catalog_ready:
		return _catalog
	_catalog = {}
	if FileAccess.file_exists(BEASTS_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BEASTS_PATH))
		if parsed is Dictionary:
			var data: Dictionary = parsed
			for key: String in ["species", "variants"]:
				var rows: Variant = data.get(key, [])
				if rows is Array:
					for row_v: Variant in rows:
						if row_v is Dictionary:
							var row: Dictionary = row_v
							var bid: String = str(row.get("id", ""))
							if bid != "":
								_catalog[bid] = row
	_catalog_ready = true
	return _catalog


class Fighter extends RefCounted:
	var id: String = ""
	var side: String = "beast"
	var slot: int = 0
	var row: String = "front"
	var species: String = ""
	var member: String = ""
	var might: int = 0
	var arcana: int = 0
	var resilience: int = 0
	var ward: int = 0
	var vitality: int = 0
	var swiftness: int = 0
	var fate: int = 0
	var attack: String = "physical"
	var hp: int = 0
	var max_hp: int = 0
	var weave: int = 0
	var shield: int = 0
	var brace: bool = false
	var poison_ticks: Array[int] = []
	var poison_left: int = 0
	var turns: int = 0
	var intent_move: String = ""
	var intent_mult: int = 1
	var boss: bool = false
	var status: String = "active"

	func to_dict() -> Dictionary:
		var ticks: Array[int] = poison_ticks.duplicate()
		return {
			"id": id,
			"side": side,
			"slot": slot,
			"row": row,
			"species": species,
			"member": member,
			"might": might,
			"arcana": arcana,
			"resilience": resilience,
			"ward": ward,
			"vitality": vitality,
			"swiftness": swiftness,
			"fate": fate,
			"attack": attack,
			"hp": hp,
			"max_hp": max_hp,
			"weave": weave,
			"shield": shield,
			"brace": brace,
			"poison": {"ticks": ticks, "left": poison_left},
			"turns": turns,
			"intent": {"move": intent_move, "mult": intent_mult},
			"boss": boss,
			"status": status,
		}

	static func from_dict(data: Dictionary) -> Fighter:
		var who := Fighter.new()
		who.id = str(data.get("id", ""))
		var side: String = str(data.get("side", "beast"))
		who.side = "party" if side == "party" else "beast"
		who.slot = FightState._as_int(data.get("slot", 0))
		who.row = "back" if str(data.get("row", "front")) == "back" else "front"
		who.species = str(data.get("species", ""))
		who.member = str(data.get("member", ""))
		who.might = FightState._as_int(data.get("might", 0))
		who.arcana = FightState._as_int(data.get("arcana", 0))
		who.resilience = FightState._as_int(data.get("resilience", 0))
		who.ward = FightState._as_int(data.get("ward", 0))
		who.vitality = FightState._as_int(data.get("vitality", 0))
		who.swiftness = FightState._as_int(data.get("swiftness", 0))
		who.fate = FightState._as_int(data.get("fate", 0))
		var kind: String = str(data.get("attack", "physical"))
		who.attack = "magic" if kind == "magic" else "physical"
		who.hp = FightState._as_int(data.get("hp", 0))
		who.max_hp = FightState._as_int(data.get("max_hp", BattleResolver.max_hp_for(who.vitality)))
		who.weave = FightState._as_int(data.get("weave", 0))
		who.shield = FightState._as_int(data.get("shield", 0))
		who.brace = FightState._as_bool(data.get("brace", false))
		who.poison_ticks = []
		var poison_v: Variant = data.get("poison", {})
		var poison: Dictionary = poison_v as Dictionary if poison_v is Dictionary else {}
		var ticks_v: Variant = poison.get("ticks", [])
		if ticks_v is Array:
			for tick_v: Variant in ticks_v:
				who.poison_ticks.append(int(tick_v))
		who.poison_left = FightState._as_int(poison.get("left", 0))
		who.turns = FightState._as_int(data.get("turns", 0))
		var intent_v: Variant = data.get("intent", {})
		var intent: Dictionary = intent_v as Dictionary if intent_v is Dictionary else {}
		who.intent_move = str(intent.get("move", ""))
		who.intent_mult = FightState._as_int(intent.get("mult", 1))
		who.boss = FightState._as_bool(data.get("boss", false))
		var saved_status: String = str(data.get("status", "active"))
		if saved_status == "ko" or saved_status == "calmed" or saved_status == "active":
			who.status = saved_status
		else:
			who.status = "active"
		return who
