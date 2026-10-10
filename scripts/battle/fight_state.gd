class_name FightState
extends RefCounted
## Stepwise, serializable fight. One action per step. No scene calls this yet.
## Weave is a flat 30 on party fighters and 0 on beasts (they have none yet).
## Statuses: Brace, Heart Salve, refreshing poison, beast intents, the boss,
## and one twist (Thicket, Fog, Ambush, Sap Spring, Rich Hollow).


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
var twist: String = "":
	set(value):
		twist = value
		if value == "ambush":
			ambush = true
var salves_used: int = 0
var loadout: Dictionary = {}
var controller: String = "manual"
var resolver_version: int = RESOLVER_VERSION
var rng_combat_seed: int = 1
var rng_combat_state: String = "0"
var log_tail: Array = []

var _rng: BattleRng
var _emit_round_on_step: bool = false
var _scripted_dice: BattleRng
var _fighters: Dictionary = {}

static var _catalog: Dictionary = {}
static var _catalog_ready: bool = false


func _init() -> void:
	_rng = BattleRng.new()
	loadout = {}
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
	who.intent_num = 1
	who.intent_den = 1
	who.poison_total = 0
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


func display_name(fighter_id: String) -> String:
	var who := _fighter(fighter_id)
	if who == null:
		return fighter_id
	if who.side == "party":
		var member: String = who.member if who.member != "" else who.id
		var lower: String = member.to_lower()
		if lower == "keeper":
			return "Keeper"
		if lower == "elaia":
			return "Elaia"
		return member
	var base_key: String = "beast_%s_name" % who.species
	var base: String = base_key
	if who.species != "":
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null:
			var cs: Node = tree.root.get_node_or_null("ContentStrings")
			if cs != null:
				base = str(cs.call("get_text", base_key))
	if base == base_key:
		base = who.species if who.species != "" else who.id
	var same: Array[String] = []
	for key: Variant in _fighters.keys():
		var other := _fighter(str(key))
		if other != null and other.side == "beast" and other.species == who.species:
			same.append(other.id)
	if same.size() <= 1:
		return base
	same.sort()
	for i: int in same.size():
		if same[i] == who.id:
			return "%s %s" % [base, String.chr(65 + i)]
	return base


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
	var defender_row: Dictionary = dfn.to_dict()
	defender_row["swiftness"] = effective_swiftness(defender)
	var mod: int = to_hit_mod
	if twist == "fog":
		mod -= 2
	var result: Dictionary = BattleResolver.resolve(atk.to_dict(), defender_row, mod, ratio.x, ratio.y, dice)
	var shield_absorbed: int = 0
	var damage: int = int(result["damage"])
	result["resolver_damage"] = damage
	if damage > 0:
		var shield_before: int = dfn.shield
		var applied: int = _apply_landed_damage(dfn, damage)
		shield_absorbed = mini(shield_before, applied)
		result["damage"] = applied
	else:
		dfn.status = BattleResolver.status_for(dfn.side, dfn.hp, dfn.max_hp)
	result["defender_hp_after"] = dfn.hp
	result["defender_status"] = dfn.status
	result["shield_absorbed"] = shield_absorbed
	result["braced_defender"] = bool(defender_row.get("brace", false))
	result["to_hit_mod"] = mod
	result["telegraph_mult"] = telegraph_mult
	if _scripted_dice == null:
		rng_combat_state = _rng.state_string()
	return result


func start_fight() -> void:
	## Round 1, order rebuilt (Ambush applies this round only), cursor on the first active actor.
	## Boss HP, Sap Spring shields, and the first intents are applied here.
	_outcome = ""
	if twist == "ambush":
		ambush = true
	_apply_boss_hp()
	_apply_sap_spring()
	_begin_round(1)
	_refresh_intents()
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
	## Thicket takes 2 Swiftness off everyone, floored at 0. Ordering and defense
	## both read Swiftness only through this, so the stored stat stays put.
	var who := _fighter(id)
	if who == null:
		return 0
	if twist == "thicket":
		return maxi(0, who.swiftness - 2)
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


func flee_check() -> Dictionary:
	## KO members count as 0. The Sap Spring shield is not counted.
	## should_flee when the party is under half and the beasts are over a third.
	var party_hp: int = 0
	var party_max: int = 0
	var beast_hp: int = 0
	var beast_max: int = 0
	for key: Variant in _fighters.keys():
		var who := _fighter(str(key))
		if who == null:
			continue
		if who.side == "party":
			party_max += who.max_hp
			if who.status == "active":
				party_hp += who.hp
		else:
			beast_max += who.max_hp
			if who.status != "calmed":
				beast_hp += who.hp
	var should_flee: bool = party_hp * 2 < party_max and beast_hp * 3 > beast_max
	return {
		"party_hp": party_hp,
		"party_max": party_max,
		"beast_hp": beast_hp,
		"beast_max": beast_max,
		"should_flee": should_flee,
	}


func apply_poison(fighter_id: String, total: int) -> void:
	## One poison per target. A new one resets the duration to 3 and keeps the
	## stronger total. Bile will call this same function.
	var who := _fighter(fighter_id)
	if who == null:
		return
	var kept: int = maxi(0, total)
	if who.poison_left > 0 and not who.poison_ticks.is_empty():
		kept = maxi(kept, who.poison_total)
	who.poison_total = kept
	who.poison_ticks = BattleResolver.poison_schedule(kept)
	who.poison_left = who.poison_ticks.size()


func tick_poison(fighter_id: String) -> void:
	## The next tick. The shield absorbs it first; the rest comes off HP.
	var who := _fighter(fighter_id)
	if who == null:
		return
	if who.poison_ticks.is_empty():
		who.poison_left = 0
		who.poison_total = 0
		return
	var tick: int = who.poison_ticks[0]
	who.poison_ticks.remove_at(0)
	who.poison_left = who.poison_ticks.size()
	if who.poison_ticks.is_empty():
		who.poison_total = 0
	_absorb(who, tick)


func set_boss(fighter_id: String, on: bool = true) -> void:
	## Set before start_fight(). The HP bonus is applied when the fight starts.
	var who := _fighter(fighter_id)
	if who == null:
		return
	who.boss = on


func step(action: Dictionary = {}) -> Dictionary:
	## One action. Beasts ignore `action` and play their intent. An illegal party
	## action spends no turn and no dice.
	if _outcome != "":
		return _step_packet("", "", "", {}, round, "fight over", [])
	if round <= 0:
		return _step_packet("", "", "", {}, round, "not started", [])
	_advance_to_active()
	if turn_cursor >= order.size():
		_roll_round_if_spent()
		if _outcome != "":
			return _step_packet("", "", "", {}, round, "fight over", [])
	var actor_id: String = current_actor()
	if actor_id == "":
		return _step_packet("", "", "", {}, round, "no actor", [])
	var actor := _fighter(actor_id)
	if actor == null:
		return _step_packet("", "", "", {}, round, "no actor", [])
	var action_round: int = round
	if actor.side == "beast":
		return _step_beast(actor, action_round)
	return _step_party(actor, action, action_round)


func _step_party(actor: Fighter, action: Dictionary, action_round: int) -> Dictionary:
	var kind: String = str(action.get("kind", ""))
	var target_v: Variant = action.get("target", "")
	var target_id: String = "" if target_v == null else str(target_v)
	if kind == "strike":
		if not legal_targets(actor.id).has(target_id):
			return _step_packet(actor.id, kind, target_id, {}, action_round, "illegal target", [])
		return _act_strike(actor, target_id, to_hit_mod_for(actor.id, target_id), 1, action_round)
	if kind == "brace":
		return _act_brace(actor, action_round)
	if kind == "item":
		return _act_item(actor, action, action_round)
	return _step_packet(actor.id, kind, target_id, {}, action_round, "illegal action", [])


func _step_beast(actor: Fighter, action_round: int) -> Dictionary:
	var chosen: Dictionary = _beast_action(actor.id)
	var kind: String = str(chosen.get("kind", ""))
	var target_id: String = str(chosen.get("target", ""))
	if kind == "poison":
		if target_id == "" or not legal_targets(actor.id).has(target_id):
			return _skip_beast(actor.id, kind, target_id, action_round, "no target")
		return _act_poison(actor, target_id, int(chosen.get("total", 0)), action_round)
	var mult: Variant = chosen.get("mult", 1)
	if kind != "strike" or not legal_targets(actor.id).has(target_id):
		var beast_error: String = "no target" if kind == "strike" else "illegal action"
		return _skip_beast(actor.id, kind, target_id, action_round, beast_error)
	return _act_strike(actor, target_id, to_hit_mod_for(actor.id, target_id), mult, action_round, chosen)


func _skip_beast(actor_id: String, kind: String, target_id: String, action_round: int, error: String) -> Dictionary:
	_advance_cursor()
	if _outcome == "":
		_roll_round_if_spent()
	return _step_packet(actor_id, kind, target_id, {}, action_round, error, [])


func _act_strike(actor: Fighter, target_id: String, mod: int, mult: Variant, action_round: int, beast_chosen: Dictionary = {}) -> Dictionary:
	var actor_id: String = actor.id
	var events: Array = []
	_maybe_round_start(events, action_round)
	_poison_ticks_at_turn_start(actor_id, events)
	if not _is_active(_fighter(actor_id)):
		return _lost_turn(actor_id, action_round, events)
	if actor.side == "beast":
		_append_intent_reveal(actor, beast_chosen, events)
	var target := _fighter(target_id)
	var status_before: String = target.status if target != null else "active"
	var blow: Dictionary = strike(actor_id, target_id, mod, mult)
	events.append(_strike_event_from_blow(actor_id, target_id, blow, mod, mult))
	_status_events(target_id, status_before, events)
	var acted := _fighter(actor_id)
	if acted != null:
		acted.turns += 1
		if acted.side == "beast":
			_set_intent(acted)
	var outcome_before: String = _outcome
	_commit_turn()
	_outcome_events(outcome_before, events)
	return _step_packet(actor_id, "strike", target_id, blow, action_round, "", events)


func _act_brace(actor: Fighter, action_round: int) -> Dictionary:
	var actor_id: String = actor.id
	var events: Array = []
	_maybe_round_start(events, action_round)
	_poison_ticks_at_turn_start(actor_id, events)
	if not _is_active(_fighter(actor_id)):
		return _lost_turn(actor_id, action_round, events)
	var acted := _fighter(actor_id)
	if acted != null:
		acted.brace = true
		acted.turns += 1
	events.append({"kind": "brace", "actor": actor_id})
	var outcome_before: String = _outcome
	_commit_turn()
	_outcome_events(outcome_before, events)
	return _step_packet(actor_id, "brace", "", {}, action_round, "", events)


func _act_poison(actor: Fighter, target_id: String, total: int, action_round: int) -> Dictionary:
	var actor_id: String = actor.id
	var events: Array = []
	_maybe_round_start(events, action_round)
	_poison_ticks_at_turn_start(actor_id, events)
	if not _is_active(_fighter(actor_id)):
		return _lost_turn(actor_id, action_round, events)
	_append_intent_reveal(actor, {"kind": "poison", "total": total}, events)
	apply_poison(target_id, total)
	events.append({"kind": "poison_apply", "actor": actor_id, "target": target_id, "total": total})
	var acted := _fighter(actor_id)
	if acted != null:
		acted.turns += 1
		_set_intent(acted)
	var outcome_before: String = _outcome
	_commit_turn()
	_outcome_events(outcome_before, events)
	return _step_packet(actor_id, "poison", target_id, {}, action_round, "", events)


func _act_item(actor: Fighter, action: Dictionary, action_round: int) -> Dictionary:
	var actor_id: String = actor.id
	var target_v: Variant = action.get("target", "")
	var target_id: String = "" if target_v == null else str(target_v)
	if not _salve_ok(action, target_id):
		return _step_packet(actor_id, "item", target_id, {}, action_round, "illegal action", [])
	var events: Array = []
	_maybe_round_start(events, action_round)
	_poison_ticks_at_turn_start(actor_id, events)
	if not _is_active(_fighter(actor_id)):
		return _lost_turn(actor_id, action_round, events)
	var target := _fighter(target_id)
	if target == null:
		return _step_packet(actor_id, "item", target_id, {}, action_round, "illegal action", events)
	var heal: int = BattleResolver.round_half_up(target.max_hp, 3, 10)
	var hp_before: int = target.hp
	target.hp = mini(target.max_hp, target.hp + heal)
	target.status = BattleResolver.status_for(target.side, target.hp, target.max_hp)
	var healed: int = target.hp - hp_before
	salves_used += 1
	loadout["heart_salve"] = maxi(0, int(loadout.get("heart_salve", 0)) - 1)
	events.append({
		"kind": "item",
		"actor": actor_id,
		"item": "heart_salve",
		"target": target_id,
		"healed": healed,
	})
	var acted := _fighter(actor_id)
	if acted != null:
		acted.turns += 1
	var outcome_before: String = _outcome
	_commit_turn()
	_outcome_events(outcome_before, events)
	return _step_packet(actor_id, "item", target_id, {}, action_round, "", events)


func _salve_ok(action: Dictionary, target_id: String) -> bool:
	## Heart Salve only. Bile is not defined yet. Active party, stock, and the cap of 2.
	if str(action.get("item", "")) != "heart_salve":
		return false
	if salves_used >= 2:
		return false
	if int(loadout.get("heart_salve", 0)) < 1:
		return false
	var target := _fighter(target_id)
	return target != null and target.side == "party" and _is_active(target)


func _commit_turn() -> void:
	_resolve_outcome(false)
	_advance_cursor()
	if _outcome == "":
		_roll_round_if_spent()


func _lost_turn(actor_id: String, action_round: int, events: Array) -> Dictionary:
	## A poison tick knocked them out or Calmed them before they could act.
	var outcome_before: String = _outcome
	_resolve_outcome(false)
	_outcome_events(outcome_before, events)
	if _outcome == "":
		_advance_cursor()
		_roll_round_if_spent()
	return _step_packet(actor_id, "", "", {}, action_round, "", events)


func _maybe_round_start(events: Array, action_round: int) -> void:
	if not _emit_round_on_step:
		return
	_emit_round_on_step = false
	events.append({"kind": "round_start", "round": action_round})


func _poison_ticks_at_turn_start(actor_id: String, events: Array) -> void:
	## Brace ends as their turn starts, then poison ticks. The tick is not a
	## landed blow, so Brace does not halve it. The shield still absorbs it.
	var who := _fighter(actor_id)
	if who == null:
		return
	who.brace = false
	if who.poison_left <= 0 or who.poison_ticks.is_empty():
		return
	var tick: int = who.poison_ticks[0]
	who.poison_ticks.remove_at(0)
	who.poison_left = who.poison_ticks.size()
	if who.poison_ticks.is_empty():
		who.poison_total = 0
	var status_before: String = who.status
	var shield_before: int = who.shield
	_absorb(who, tick)
	var absorbed: int = shield_before - who.shield
	events.append({
		"kind": "poison_tick",
		"target": actor_id,
		"amount": tick,
		"shield_absorbed": absorbed,
		"hp_after": who.hp,
	})
	_status_events(actor_id, status_before, events)


func _append_intent_reveal(actor: Fighter, chosen: Dictionary, events: Array) -> void:
	var move: String = actor.intent_move
	if move != "heavy" and move != "poison":
		return
	var mult: Variant = chosen.get("mult", actor._intent_mult())
	events.append({"kind": "intent_reveal", "actor": actor.id, "move": move, "mult": mult})


func _strike_event_from_blow(actor_id: String, target_id: String, blow: Dictionary, mod: int, mult: Variant) -> Dictionary:
	var target := _fighter(target_id)
	var event: Dictionary = {
		"kind": "strike",
		"actor": actor_id,
		"target": target_id,
		"to_hit_mod": mod,
		"telegraph_mult": mult,
		"braced": bool(blow.get("braced_defender", false)),
		"shield_absorbed": int(blow.get("shield_absorbed", 0)),
		"hp_after": int(blow.get("defender_hp_after", 0)),
		"target_side": target.side if target != null else "beast",
	}
	for key: String in [
		"attack_total", "attack_dice", "attack_stat", "attack_mod",
		"defense_total", "defense_dice", "defense_stat", "defense_faces",
		"margin", "band", "damage_face", "fate_crit",
	]:
		if blow.has(key):
			event[key] = blow[key]
	# damage = what lands after Brace, before the shield (the log's "for N");
	# resolver_damage = the raw resolver number before Brace.
	event["resolver_damage"] = int(blow.get("resolver_damage", blow.get("damage", 0)))
	event["damage"] = int(blow.get("damage", 0))
	return event


func _status_events(target_id: String, before: String, events: Array) -> void:
	var who := _fighter(target_id)
	if who == null or who.status == before:
		return
	if who.status == "ko":
		events.append({"kind": "knocked_out", "target": target_id})
	elif who.status == "calmed":
		events.append({"kind": "calmed", "target": target_id})


func _outcome_events(before: String, events: Array) -> void:
	if _outcome != "" and _outcome != before:
		events.append({"kind": "outcome", "result": _outcome})


func _record_log(events: Array) -> void:
	for entry: Variant in events:
		if entry is Dictionary:
			var line: String = BattleLog.line_for(entry as Dictionary, self)
			if line != "":
				log_tail.append(line)
	_trim_log()


func _beast_action(beast_id: String) -> Dictionary:
	## Whatever the intent already shows. Poison deals no strike.
	var who := _fighter(beast_id)
	var target_id: String = beast_target(beast_id)
	if who == null:
		return {"kind": "strike", "target": target_id, "mult": 1}
	if who.intent_move == "poison":
		return {"kind": "poison", "target": target_id, "total": _poison_total(who)}
	if who.intent_move == "heavy":
		return {"kind": "strike", "target": target_id, "mult": Vector2i(who.intent_num, maxi(1, who.intent_den))}
	return {"kind": "strike", "target": target_id, "mult": 1}


func _apply_landed_damage(defender: Fighter, damage: int) -> int:
	## Brace halves first (round half up, minimum 1), then the shield absorbs the rest.
	var amount: int = damage
	if defender.brace:
		amount = maxi(1, BattleResolver.round_half_up(amount, 1, 2))
	_absorb(defender, amount)
	return amount


func _absorb(who: Fighter, amount: int) -> void:
	var spent: int = maxi(0, amount)
	var absorbed: int = mini(maxi(0, who.shield), spent)
	who.shield -= absorbed
	who.hp -= spent - absorbed
	who.status = BattleResolver.status_for(who.side, who.hp, who.max_hp)


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
		"loadout": loadout.duplicate(),
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
	fight.loadout = {}
	var load_v: Variant = data.get("loadout", {})
	if load_v is Dictionary:
		var load: Dictionary = load_v
		for load_key: Variant in load.keys():
			fight.loadout[str(load_key)] = _as_int(load[load_key])
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


func _apply_boss_hp() -> void:
	for key: Variant in _fighters.keys():
		var who := _fighter(str(key))
		if who == null or who.side != "beast" or not who.boss:
			continue
		var boosted: int = BattleResolver.round_half_up(who.max_hp, 3, 2)
		who.max_hp = boosted
		who.hp = boosted
		who.status = BattleResolver.status_for(who.side, who.hp, who.max_hp)


func _apply_sap_spring() -> void:
	if twist != "sap_spring":
		return
	for key: Variant in _fighters.keys():
		var who := _fighter(str(key))
		if who == null or who.side != "party":
			continue
		who.shield = BattleResolver.round_half_up(who.max_hp, 1, 5)


func _refresh_intents() -> void:
	for fighter_id: String in order:
		var who := _fighter(fighter_id)
		if who != null and who.side == "beast":
			_set_intent(who)


func _set_intent(who: Fighter) -> void:
	## The turn about to be taken is turns + 1. A boss with a move uses it
	## every 2nd own turn; everyone else specials on every 3rd.
	var upcoming: int = who.turns + 1
	var move: Dictionary = _move_spec(who)
	var period: int = 3
	if who.boss and not move.is_empty():
		period = 2
	var special: bool = period > 0 and upcoming % period == 0
	who.intent_num = 1
	who.intent_den = 1
	if not special:
		who.intent_move = "strike"
		return
	var kind: String = str(move.get("kind", ""))
	if kind == "poison":
		who.intent_move = "poison"
		return
	if kind == "heavy":
		who.intent_move = "heavy"
		var ratio: Vector2i = telegraph_ratio(move.get("mult", 1))
		who.intent_num = ratio.x
		who.intent_den = maxi(1, ratio.y)
		return
	if who.boss and move.is_empty():
		who.intent_move = "heavy"
		who.intent_num = 3
		who.intent_den = 2
		return
	who.intent_move = "strike"


func _move_spec(who: Fighter) -> Dictionary:
	if who.species == "":
		return {}
	var spec: Dictionary = beast_row(who.species)
	var move_v: Variant = spec.get("move", null)
	if move_v is Dictionary:
		return move_v
	return {}


func _poison_total(who: Fighter) -> int:
	return int(_move_spec(who).get("total", 0))


func _begin_round(next_round: int) -> void:
	round = next_round
	order = _sorted_ids()
	turn_cursor = 0
	_emit_round_on_step = true
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


func _step_packet(actor_id: String, kind: String, target_id: String, blow: Dictionary, action_round: int, error: String, events: Array = []) -> Dictionary:
	var logged: Array = events
	if error == "illegal target" or error == "illegal action":
		logged = []
	elif logged.size() > 0:
		_record_log(logged)
	return {
		"actor": actor_id,
		"kind": kind,
		"target": target_id,
		"strike": blow,
		"round": action_round,
		"outcome": _outcome,
		"error": error,
		"events": logged.duplicate(true),
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
		"attack_dice": 0,
		"attack_stat": 0,
		"attack_mod": 0,
		"defense_total": 0,
		"defense_dice": 0,
		"defense_stat": 0,
		"defense_faces": [] as Array[int],
		"margin": 0,
		"band": "miss",
		"damage": 0,
		"damage_face": 0,
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
	var intent_num: int = 1
	var intent_den: int = 1
	var poison_total: int = 0
	var boss: bool = false
	var status: String = "active"

	func _intent_mult() -> Variant:
		if intent_den <= 1:
			return intent_num
		if intent_den == 2:
			return float(intent_num) / 2.0
		return {"num": intent_num, "den": intent_den}

	func _poison_body() -> Dictionary:
		## `total` is kept only when a tick has spent part of it. A fresh
		## schedule sums to the total, so the old {ticks, left} shape still
		## round-trips and the stronger total survives a mid-fight save.
		var ticks: Array[int] = poison_ticks.duplicate()
		var tick_sum: int = 0
		for tick: int in ticks:
			tick_sum += tick
		var body: Dictionary = {"ticks": ticks, "left": poison_left}
		if poison_total != tick_sum:
			body["total"] = poison_total
		return body

	func to_dict() -> Dictionary:
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
			"poison": _poison_body(),
			"turns": turns,
			"intent": {"move": intent_move, "mult": _intent_mult()},
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
		var tick_sum: int = 0
		if ticks_v is Array:
			for tick_v: Variant in ticks_v:
				var tick_n: int = int(tick_v)
				who.poison_ticks.append(tick_n)
				tick_sum += tick_n
		who.poison_left = FightState._as_int(poison.get("left", who.poison_ticks.size()))
		if poison.has("total"):
			who.poison_total = FightState._as_int(poison.get("total", 0))
		else:
			who.poison_total = tick_sum
		who.turns = FightState._as_int(data.get("turns", 0))
		var intent_v: Variant = data.get("intent", {})
		var intent: Dictionary = intent_v as Dictionary if intent_v is Dictionary else {}
		who.intent_move = str(intent.get("move", ""))
		var ratio: Vector2i = FightState.telegraph_ratio(intent.get("mult", 1))
		who.intent_num = ratio.x
		who.intent_den = maxi(1, ratio.y)
		who.boss = FightState._as_bool(data.get("boss", false))
		var saved_status: String = str(data.get("status", "active"))
		if saved_status == "ko" or saved_status == "calmed" or saved_status == "active":
			who.status = saved_status
		else:
			who.status = "active"
		return who
