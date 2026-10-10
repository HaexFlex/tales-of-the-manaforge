class_name BattleLog
extends RefCounted
## Pure log lines for fight events. Reads copy through ContentStrings when present.


static func line_for(event: Dictionary, fight: FightState) -> String:
	var kind: String = str(event.get("kind", ""))
	match kind:
		"round_start":
			return _text("adv_log_round", {"round": str(event.get("round", 0))})
		"poison_tick":
			return _text("adv_log_poison_tick", {
				"name": _fighter_name(fight, str(event.get("target", ""))),
				"amount": str(event.get("amount", 0)),
			})
		"brace":
			return _text("adv_log_brace", {"name": _fighter_name(fight, str(event.get("actor", "")))})
		"item":
			return _text("adv_log_salve", {
				"name": _fighter_name(fight, str(event.get("actor", ""))),
				"target": _fighter_name(fight, str(event.get("target", ""))),
				"amount": str(event.get("healed", 0)),
			})
		"intent_reveal":
			var move: String = str(event.get("move", ""))
			if move == "heavy":
				return _text("adv_log_heavy_reveal", {
					"beast": _fighter_name(fight, str(event.get("actor", ""))),
					"mult": _intent_mult_label(event),
				})
			if move == "poison":
				return ""
			return ""
		"poison_apply":
			return _text("adv_log_poison_apply", {
				"beast": _fighter_name(fight, str(event.get("actor", ""))),
				"target": _fighter_name(fight, str(event.get("target", ""))),
				"total": str(event.get("total", 0)),
			})
		"strike":
			return _strike_line(event, fight)
		"knocked_out":
			return _text("adv_knocked_out_log", {"name": _fighter_name(fight, str(event.get("target", "")))})
		"calmed":
			return _text("adv_calmed_log", {"beast": _fighter_name(fight, str(event.get("target", "")))})
		"outcome":
			var result: String = str(event.get("result", ""))
			if result == "win":
				return _text("adv_log_victory", {})
			if result == "overwhelmed":
				return _text("adv_overwhelmed_log", {})
			return ""
		_:
			return ""


static func _strike_line(event: Dictionary, fight: FightState) -> String:
	var band: String = str(event.get("band", ""))
	var attacker: String = _fighter_name(fight, str(event.get("actor", "")))
	var defender: String = _fighter_name(fight, str(event.get("target", "")))
	var atk: String = _attack_total_label(event)
	var def: String = _defense_total_label(event)
	if band == "miss":
		return _text("adv_log_miss", {"attacker": attacker, "atk": atk, "defender": defender, "def": def})
	var result_word: String = _band_word(band)
	var line: String = _text("adv_log_strike", {
		"attacker": attacker,
		"atk": atk,
		"defender": defender,
		"def": def,
		"result": result_word,
		"damage": str(event.get("damage", 0)),
	})
	if bool(event.get("fate_crit", false)):
		line += _text("adv_log_crit_suffix", {})
	var absorbed: int = int(event.get("shield_absorbed", 0))
	if absorbed > 0:
		line += _text("adv_log_shield_suffix", {"amount": str(absorbed)})
	return line


static func _attack_total_label(event: Dictionary) -> String:
	var dice: int = int(event.get("attack_dice", 0))
	var stat: int = int(event.get("attack_stat", 0))
	var mod: int = int(event.get("attack_mod", 0))
	var total: int = int(event.get("attack_total", 0))
	var head: String = "%d+%d" % [dice, stat]
	if mod != 0:
		head += "%+d" % mod
	return "%s=%d" % [head, total]


static func _defense_total_label(event: Dictionary) -> String:
	var faces_v: Variant = event.get("defense_faces", [])
	var faces: Array[int] = []
	if faces_v is Array:
		for face_v: Variant in faces_v:
			faces.append(int(face_v))
	var dice: int = int(event.get("defense_dice", 0))
	var stat: int = int(event.get("defense_stat", 0))
	var total: int = int(event.get("defense_total", 0))
	if faces.size() == 3:
		var kept: Array[int] = _best_two_faces(faces)
		return "[%s → %d+%d]=%d+%d=%d" % [
			_join_faces(faces), kept[0], kept[1], dice, stat, total,
		]
	return "%d+%d=%d" % [dice, stat, total]


static func _best_two_faces(faces: Array[int]) -> Array[int]:
	var sorted: Array[int] = faces.duplicate()
	sorted.sort()
	sorted.reverse()
	return [sorted[0], sorted[1]]


static func _join_faces(faces: Array[int]) -> String:
	var parts: PackedStringArray = []
	for face: int in faces:
		parts.append(str(face))
	return ",".join(parts)


static func _band_word(band: String) -> String:
	match band:
		"graze":
			return _text("adv_band_graze", {})
		"hit":
			return _text("adv_band_hit", {})
		"crush":
			return _text("adv_band_crush", {})
		_:
			return band


static func _intent_mult_label(event: Dictionary) -> String:
	var mult_v: Variant = event.get("mult", 1)
	if mult_v is Vector2i:
		var pair: Vector2i = mult_v as Vector2i
		if pair.y == 2 and pair.x % 2 == 1:
			return str(float(pair.x) / 2.0)
		if pair.y > 1:
			return "%d/%d" % [pair.x, pair.y]
		return str(pair.x)
	if mult_v is float:
		return str(mult_v)
	return str(mult_v)


static func _fighter_name(fight: FightState, fighter_id: String) -> String:
	return fight.display_name(fighter_id)


static func _text(key: String, tokens: Dictionary) -> String:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var cs: Node = tree.root.get_node_or_null("ContentStrings")
		if cs != null:
			return str(cs.call("get_text", key, tokens))
	return _fallback(key, tokens)


static func _fallback(key: String, tokens: Dictionary) -> String:
	var table: Dictionary = {
		"adv_log_strike": "{attacker} {atk} vs {defender} {def} → {result} for {damage}",
		"adv_log_miss": "{attacker} {atk} vs {defender} {def} → miss",
		"adv_band_graze": "graze",
		"adv_band_hit": "hit",
		"adv_band_crush": "crushing blow",
		"adv_log_crit_suffix": " (Fate crit)",
		"adv_log_shield_suffix": " ({amount} absorbed by the shield)",
		"adv_log_brace": "{name} braces (3d6 keep 2, damage halved)",
		"adv_log_salve": "{name} uses a Heart Salve on {target}: +{amount} HP.",
		"adv_log_heavy_reveal": "{beast} winds up a heavy blow (×{mult}).",
		"adv_log_poison_apply": "{beast} poisons {target} ({total} over 3 turns).",
		"adv_log_poison_tick": "{name} takes {amount} poison.",
		"adv_log_round": "Round {round}",
		"adv_log_victory": "All beasts are Calmed.",
		"adv_knocked_out_log": "{name} is knocked out.",
		"adv_calmed_log": "{beast} is Calmed.",
		"adv_overwhelmed_log": "The party is overwhelmed.",
		"beast_acorn_imp_name": "Acorn imp",
	}
	var raw: String = str(table.get(key, key))
	for t: Variant in tokens.keys():
		raw = raw.replace("{%s}" % str(t), str(tokens[t]))
	return raw
