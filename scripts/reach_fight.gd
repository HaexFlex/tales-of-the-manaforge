class_name ReachFight
extends RefCounted
## One room, one fight. Several foes are fine. No turn timer.

const MERCY_FRACTION: float = 0.10
const MISS_CHANCE: float = 0.08
const KEEPER_CRIT_MULT: float = 2.0
const ENEMY_CRIT_CHANCE: float = 0.05
const ENEMY_CRIT_MULT: float = 1.5
const PARTY_K: float = 1.0
const ENEMY_K: float = 1.1
const HEAVY_MULT: float = 2.5

var depth: int = 1
var level: float = 5.2
var keeper: Dictionary = {}
var keeper_hp: int = 50
var keeper_max_hp: int = 50
var enemies: Array[Dictionary] = []
var brace: bool = false
var hex_per: int = 0
var hex_left: int = 0
var outcome: String = ""
var round_i: int = 0
var telegraph: String = ""
var log: PackedStringArray = PackedStringArray()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## -1 roll, 0 never, 1 always.
var force_miss: int = -1
var force_crit: int = -1


static func road_damage(k: float, attack: float, defense: float, variance: float, crit_mult: float) -> int:
	if attack <= 0.0:
		return 0
	var denom: float = attack + maxf(0.0, defense)
	if denom <= 0.0:
		return 1
	var dealt: float = k * attack * attack / denom
	dealt *= 1.0 + clampf(variance, -0.10, 0.10)
	if crit_mult > 1.0:
		dealt *= crit_mult
	return maxi(1, int(round(dealt)))


func setup(room_depth: int, room_level: float, keeper_stats: Dictionary, roles: Array, champion_index: int, names: Dictionary, arts: Dictionary) -> void:
	rng.randomize()
	depth = room_depth
	level = room_level
	keeper = keeper_stats.duplicate()
	keeper_max_hp = maxi(1, int(keeper.get("vitality", 5)) * 10)
	keeper_hp = keeper_max_hp
	brace = false
	hex_per = 0
	hex_left = 0
	outcome = ""
	round_i = 0
	telegraph = ""
	log = PackedStringArray()
	enemies.clear()
	for i: int in range(roles.size()):
		var role: String = str(roles[i])
		enemies.append(_make_enemy(role, i == champion_index, names, arts))


func snapshot() -> Dictionary:
	var rows: Array[Dictionary] = []
	for foe_v: Dictionary in enemies:
		rows.append({
			"name": str(foe_v.get("name", "")),
			"hp": int(foe_v.get("hp", 0)),
			"max_hp": int(foe_v.get("max_hp", 1)),
			"telegraph": str(foe_v.get("telegraph", "")),
			"art": str(foe_v.get("art", "")),
			"alive": int(foe_v.get("hp", 0)) > 0,
		})
	var tail := ""
	if log.size() > 0:
		tail = log[log.size() - 1]
	return {
		"depth": depth,
		"outcome": outcome,
		"keeper_hp": keeper_hp,
		"keeper_max": keeper_max_hp,
		"telegraph": telegraph,
		"log": tail,
		"enemies": rows,
		"brace": brace,
	}


func choose(action: String, target: int) -> String:
	if outcome != "":
		return outcome
	if enemies.is_empty():
		## A room with no beasts is not a fight and never a free victory.
		return "invalid"
	if action != "strike" and action != "brace" and action != "salve" and action != "bile" and action != "retreat":
		return "invalid"
	if action == "retreat":
		_defeat()
		return outcome
	round_i += 1
	var order: Array[Dictionary] = _turn_order()
	for step: Dictionary in order:
		if outcome != "":
			break
		if str(step.get("side", "")) == "keeper":
			_player_act(action, target)
		else:
			_enemy_act(int(step.get("index", 0)))
	if outcome == "" and _living_count() <= 0:
		outcome = "victory"
	return outcome if outcome != "" else "continue"


func debug_wound(amount: int) -> String:
	if outcome != "":
		return outcome
	_hurt_keeper(amount)
	return outcome if outcome != "" else "continue"


func _make_enemy(role: String, champion: bool, names: Dictionary, arts: Dictionary) -> Dictionary:
	var atk_m := 0.85
	var def_m := 0.85
	var swift_m := 0.9
	var hp_m := 2.9
	var profile := "physical"
	if role == "caster":
		atk_m = 0.95
		def_m = 0.7
		swift_m = 1.0
		hp_m = 2.2
		profile = "magical"
	elif role == "brute":
		atk_m = 1.0
		def_m = 1.1
		swift_m = 0.7
		hp_m = 5.6
	var hp := maxi(1, int(round(hp_m * level)))
	if champion:
		hp = maxi(1, int(round(float(hp) * 1.5)))
	var label := str(names.get(role, role))
	if champion:
		label = "%s Champion" % label
	return {
		"role": role,
		"name": label,
		"profile": profile,
		"atk": atk_m * level,
		"def": def_m * level,
		"swift": swift_m * level,
		"hp": hp,
		"max_hp": hp,
		"turns": 0,
		"champion": champion,
		"telegraph": "",
		"queued_heavy": false,
		"bile_left": 0,
		"bile_per": 0,
		"art": str(arts.get(role, "")),
	}


func _turn_order() -> Array[Dictionary]:
	var rows: Array[Dictionary] = [{"side": "keeper", "index": -1, "swift": float(keeper.get("swiftness", 5))}]
	for i: int in range(enemies.size()):
		if int(enemies[i].get("hp", 0)) <= 0:
			continue
		rows.append({"side": "foe", "index": i, "swift": float(enemies[i].get("swift", 0.0))})
	## Total order: Swiftness (highest first, snapped so float noise is a tie), then the keeper, then slot.
	## sort_custom is not stable, so every tie must be broken by the key.
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: int = _swift_key(float(a.get("swift", 0.0)))
		var sb: int = _swift_key(float(b.get("swift", 0.0)))
		if sa != sb:
			return sa > sb
		var ka: int = 0 if str(a.get("side", "")) == "keeper" else 1
		var kb: int = 0 if str(b.get("side", "")) == "keeper" else 1
		if ka != kb:
			return ka < kb
		return int(a.get("index", 0)) < int(b.get("index", 0))
	)
	return rows


static func _swift_key(swift: float) -> int:
	return roundi(swift * 1000.0)


func _player_act(action: String, target: int) -> void:
	_tick_hex()
	if outcome != "":
		return
	if action == "brace":
		brace = true
		log.append("Brace")
		return
	if action == "salve":
		var heal := maxi(1, int(round(float(keeper_max_hp) * 0.30)))
		keeper_hp = mini(keeper_max_hp, keeper_hp + heal)
		log.append("Salve +%d" % heal)
		return
	if action == "bile":
		var foe := _living_at(target)
		if foe < 0:
			return
		var row := enemies[foe]
		var per := maxi(1, int(round(float(row.get("max_hp", 1)) * 0.25 / 3.0)))
		row["bile_per"] = per
		row["bile_left"] = 3
		enemies[foe] = row
		log.append("Bile")
		return
	var idx := _living_at(target)
	if idx < 0:
		return
	_strike_foe(idx)


func _strike_foe(idx: int) -> void:
	var row := enemies[idx]
	if _miss():
		log.append("Miss")
		return
	var variance := rng.randf_range(-0.10, 0.10)
	var crit := _keeper_crit()
	var dealt := road_damage(PARTY_K, float(keeper.get("offense", 5.0)), float(row.get("def", 1.0)), variance, KEEPER_CRIT_MULT if crit else 1.0)
	row["hp"] = maxi(0, int(row.get("hp", 0)) - dealt)
	enemies[idx] = row
	log.append("%s %d" % [str(row.get("name", "")), dealt])
	if _living_count() <= 0:
		outcome = "victory"


func _enemy_act(idx: int) -> void:
	if idx < 0 or idx >= enemies.size():
		return
	var row := enemies[idx]
	if int(row.get("hp", 0)) <= 0:
		return
	row["turns"] = int(row.get("turns", 0)) + 1
	if int(row.get("bile_left", 0)) > 0:
		row["hp"] = int(row.get("hp", 0)) - int(row.get("bile_per", 0))
		row["bile_left"] = int(row.get("bile_left", 0)) - 1
		enemies[idx] = row
		if int(row.get("hp", 0)) <= 0:
			if _living_count() <= 0:
				outcome = "victory"
			return
	var heavy := bool(row.get("queued_heavy", false))
	row["queued_heavy"] = false
	var role := str(row.get("role", "minion"))
	var turn := int(row.get("turns", 0))
	if role == "brute" and turn % 3 == 2:
		row["queued_heavy"] = true
		row["telegraph"] = "Heavy Swing"
	elif bool(row.get("champion", false)) and turn % 3 == 2:
		row["queued_heavy"] = true
		row["telegraph"] = "Heavy Swing"
	elif role == "caster" and turn % 3 == 0:
		row["telegraph"] = "Hex"
		enemies[idx] = row
		telegraph = "%s: Hex" % str(row.get("name", ""))
		var per := maxi(1, int(round(0.10 * level)))
		hex_per = per
		hex_left = 3
		log.append("Hex")
		return
	else:
		row["telegraph"] = ""
	enemies[idx] = row
	telegraph = str(row.get("telegraph", ""))
	if _miss():
		log.append("%s misses" % str(row.get("name", "")))
		return
	var defense := float(keeper.get("ward", 5)) if str(row.get("profile", "")) == "magical" else float(keeper.get("resilience", 5))
	var variance := rng.randf_range(-0.10, 0.10)
	var crit := _enemy_crit()
	var dealt := road_damage(ENEMY_K, float(row.get("atk", 1.0)), defense, variance, ENEMY_CRIT_MULT if crit else 1.0)
	if heavy:
		dealt = maxi(1, int(round(float(dealt) * HEAVY_MULT)))
	if brace:
		dealt = maxi(1, int(floor(float(dealt) * 0.5)))
		brace = false
	_hurt_keeper(dealt)
	log.append("%s hits %d" % [str(row.get("name", "")), dealt])


func _tick_hex() -> void:
	if hex_left <= 0 or outcome != "":
		return
	_hurt_keeper(hex_per)
	hex_left -= 1
	log.append("Hex %d" % hex_per)


func _hurt_keeper(dealt: int) -> void:
	if dealt <= 0 or outcome != "":
		return
	var floor_hp := maxi(1, int(floor(float(keeper_max_hp) * MERCY_FRACTION)))
	if keeper_hp - dealt <= floor_hp:
		keeper_hp = floor_hp
		_defeat()
		return
	keeper_hp -= dealt


func _defeat() -> void:
	outcome = "defeat"


func _miss() -> bool:
	if force_miss == 0:
		return false
	if force_miss > 0:
		return true
	return rng.randf() < MISS_CHANCE


func _keeper_crit() -> bool:
	if force_crit == 0:
		return false
	if force_crit > 0:
		return true
	return rng.randf() < float(keeper.get("fate", 5)) * 0.01


func _enemy_crit() -> bool:
	if force_crit == 0:
		return false
	if force_crit > 0:
		return true
	return rng.randf() < ENEMY_CRIT_CHANCE


func _living_count() -> int:
	var n := 0
	for row: Dictionary in enemies:
		if int(row.get("hp", 0)) > 0:
			n += 1
	return n


func _living_at(target: int) -> int:
	if target >= 0 and target < enemies.size() and int(enemies[target].get("hp", 0)) > 0:
		return target
	for i: int in range(enemies.size()):
		if int(enemies[i].get("hp", 0)) > 0:
			return i
	return -1
