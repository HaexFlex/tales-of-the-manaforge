extends Node
class_name BattlePlayback

signal queue_empty

const RULES_PATH: String = "res://data/audio_cues.json"
const GAP_STRIKE_SEC: float = 2.0
const GAP_SHORT_SEC: float = 0.6
const GAP_KO_SEC: float = 0.8
const NUDGE_PX: float = 12.0
const NUDGE_SEC: float = 0.25
const REACT_SEC: float = 0.4
const HURT_END_SEC: float = 0.75
const FLOAT_RISE_PX: float = 24.0
const FLOAT_FADE_SEC: float = 0.8
const FLASH_SEC: float = 0.15

var instant: bool = false
var speed: int = 1
var clock_sec: float = 0.0

var _view: BattleView = null
var _fight: FightState = null
var _queue: Array = []
var _active: bool = false
var _event: Dictionary = {}
var _event_started_at: float = 0.0
var _event_duration: float = 0.0
var _phase: int = 0
var _rules: Dictionary = {}
var _impact_by_band: Dictionary = {}
var _crit_cue: String = ""
var _crit_skip_fast: bool = true
var _beast_hurt_cue: String = ""
var _beast_hurt_delay: float = 0.06
var _jitter_pitch_min: float = 0.96
var _jitter_pitch_max: float = 1.04
var _jitter_gain_db: float = 1.0
var _world_max: int = 3
var _throttle_sec: Dictionary = {}
var _throttle_last: Dictionary = {}
var _victory_played: bool = false
var _nudge_base_x: float = 0.0
var _nudge_actor: String = ""
var _scheduled_sounds: Array[Dictionary] = []
var _float_nodes: Array[Control] = []
var _flash_until: float = -1.0
var _flash_sprite: CanvasItem = null
var _flash_base: Color = Color.WHITE

static var _rules_cache: Dictionary = {}


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		instant = true
	_load_rules()


func bind_view(view: BattleView, fight: FightState) -> void:
	_view = view
	_fight = fight
	_victory_played = false
	_throttle_last.clear()


func reset_for_fight() -> void:
	_queue.clear()
	_active = false
	_event = {}
	_phase = 0
	_scheduled_sounds.clear()
	_clear_floats()
	_nudge_actor = ""
	_victory_played = false
	_throttle_last.clear()
	clock_sec = 0.0


func is_busy() -> bool:
	return _active or not _queue.is_empty()


func enqueue_events(events: Array) -> void:
	if events.is_empty():
		if not _active:
			call_deferred("_emit_queue_empty")
		return
	if instant:
		for entry: Variant in events:
			if entry is Dictionary:
				_apply_event_instant(entry as Dictionary)
		call_deferred("_emit_queue_empty")
		return
	for entry: Variant in events:
		if entry is Dictionary:
			_queue.append(entry)
	if not _active:
		_start_next_event()


func advance(sec: float) -> void:
	if instant:
		return
	clock_sec += sec
	_tick(sec)


func _process(delta: float) -> void:
	if instant:
		_tick_floats(delta * float(speed))
		return
	var dt: float = delta * float(speed)
	clock_sec += dt
	_tick(dt)


func _tick(dt: float) -> void:
	_drain_scheduled_sounds()
	_tick_floats(dt)
	if not _active:
		return
	var local_t: float = clock_sec - _event_started_at
	_update_nudge(local_t)
	_update_flash(local_t)
	if _phase == 0 and local_t >= 0.0:
		_phase = 1
		_on_event_start()
	if _phase == 1 and _needs_react() and local_t >= _scaled(REACT_SEC):
		_phase = 2
		_on_target_react()
	if _phase == 2 and _needs_hurt_end() and local_t >= _scaled(HURT_END_SEC):
		_phase = 3
		_on_hurt_end()
	if local_t >= _event_duration:
		_finish_event()


func _scaled(sec: float) -> float:
	return sec / float(maxi(1, speed))


func _emit_queue_empty() -> void:
	queue_empty.emit()


func _start_next_event() -> void:
	if _queue.is_empty():
		_active = false
		call_deferred("_emit_queue_empty")
		return
	_event = _queue.pop_front() as Dictionary
	_event_started_at = clock_sec
	_event_duration = _scaled(_duration_for(_event))
	_phase = 0
	_active = true
	_nudge_actor = ""
	_schedule_event_sounds()


func _finish_event() -> void:
	_clear_nudge()
	_event = {}
	_active = false
	_start_next_event()


func _duration_for(event: Dictionary) -> float:
	var kind: String = str(event.get("kind", ""))
	match kind:
		"knocked_out", "calmed":
			return GAP_KO_SEC
		"round_start", "poison_tick", "intent_reveal", "flee", "outcome":
			return GAP_SHORT_SEC
		"strike", "brace", "item", "poison_apply":
			return GAP_STRIKE_SEC
		_:
			return GAP_SHORT_SEC


func _needs_react() -> bool:
	return str(_event.get("kind", "")) in ["strike", "item", "poison_apply"]


func _needs_hurt_end() -> bool:
	return _needs_react()


func _on_event_start() -> void:
	var kind: String = str(_event.get("kind", ""))
	_view.call("playback_reveal_log", _event)
	match kind:
		"strike", "item", "poison_apply":
			_begin_nudge(str(_event.get("actor", "")))
			_view.call("set_fighter_pose", str(_event.get("actor", "")), "attack")
		"brace":
			_begin_nudge(str(_event.get("actor", "")))
			_view.call("set_fighter_pose", str(_event.get("actor", "")), "brace")
		"intent_reveal":
			_view.call("playback_refresh_intent", str(_event.get("actor", "")))
		"knocked_out", "calmed":
			_view.call("refresh_fighter_row", str(_event.get("target", "")))
		"outcome":
			_play_outcome_sound(str(_event.get("result", "")))


func _on_target_react() -> void:
	var target_id: String = str(_event.get("target", ""))
	if target_id == "":
		return
	if _fight != null:
		_view.call("refresh_fighter_row", target_id)
	_view.call("playback_show_float", _event)
	if str(_event.get("kind", "")) in ["strike", "item", "poison_apply"]:
		_apply_hurt_pose(target_id)


func _on_hurt_end() -> void:
	var target_id: String = str(_event.get("target", ""))
	if target_id == "" or _fight == null:
		return
	var row: Dictionary = _fight.fighter_dict(target_id)
	var status: String = str(row.get("status", "active"))
	if str(row.get("side", "")) == "party":
		_view.call("set_fighter_pose", target_id, "ko" if status == "ko" else "idle")
	else:
		_view.call("playback_set_beast_idle", target_id)


func _apply_hurt_pose(target_id: String) -> void:
	if _fight == null:
		return
	var row: Dictionary = _fight.fighter_dict(target_id)
	if str(row.get("side", "")) == "party":
		_view.call("set_fighter_pose", target_id, "hurt")
		return
	var species: String = str(row.get("species", ""))
	if _view.call("playback_set_beast_hurt", target_id, species):
		return
	_flash_sprite = _view.call("playback_sprite_for", target_id) as CanvasItem
	if _flash_sprite != null:
		_flash_base = _flash_sprite.modulate
		_flash_until = clock_sec + _scaled(FLASH_SEC)


func _update_flash(_local_t: float) -> void:
	if _flash_sprite == null:
		return
	if clock_sec >= _flash_until:
		_flash_sprite.modulate = _flash_base
		_flash_sprite = null
	else:
		_flash_sprite.modulate = Color(1.0, 1.0, 1.0, _flash_base.a)


func _begin_nudge(actor_id: String) -> void:
	_nudge_actor = actor_id
	var root: Control = _view.call("playback_fighter_root", actor_id) as Control
	if root != null:
		_nudge_base_x = root.position.x


func _update_nudge(local_t: float) -> void:
	if _nudge_actor == "":
		return
	var root: Control = _view.call("playback_fighter_root", _nudge_actor) as Control
	if root == null:
		return
	var dur: float = _scaled(NUDGE_SEC)
	var offset: float = 0.0
	if local_t < dur:
		var half: float = dur * 0.5
		var toward: float = 1.0 if str(_fight.fighter_dict(_nudge_actor).get("side", "")) == "party" else -1.0
		if local_t < half:
			offset = NUDGE_PX * (local_t / half) * toward
		else:
			offset = NUDGE_PX * (1.0 - (local_t - half) / half) * toward
	root.position.x = _nudge_base_x + offset


func _clear_nudge() -> void:
	if _nudge_actor != "":
		var root: Control = _view.call("playback_fighter_root", _nudge_actor) as Control
		if root != null:
			root.position.x = _nudge_base_x
	_nudge_actor = ""


func _apply_event_instant(event: Dictionary) -> void:
	var kind: String = str(event.get("kind", ""))
	_view.call("playback_reveal_log", event)
	match kind:
		"strike", "item", "poison_apply":
			var target_id: String = str(event.get("target", ""))
			if target_id != "" and _fight != null:
				_view.call("refresh_fighter_row", target_id)
			_view.call("playback_show_float", event)
			if target_id != "":
				_on_hurt_end_instant(target_id)
		"brace":
			_view.call("set_fighter_pose", str(event.get("actor", "")), "brace")
		"intent_reveal":
			_view.call("playback_refresh_intent", str(event.get("actor", "")))
		"knocked_out", "calmed":
			if _fight != null:
				_view.call("refresh_fighter_row", str(event.get("target", "")))
	_play_event_sounds_instant(event)


func _on_hurt_end_instant(target_id: String) -> void:
	if _fight == null:
		return
	var row: Dictionary = _fight.fighter_dict(target_id)
	if str(row.get("side", "")) == "party":
		var status: String = str(row.get("status", "active"))
		_view.call("set_fighter_pose", target_id, "ko" if status == "ko" else "idle")
	else:
		_view.call("playback_set_beast_idle", target_id)


func _schedule_event_sounds() -> void:
	if not _sound_allowed():
		return
	for cue: Dictionary in cues_for_event(_event, speed):
		_scheduled_sounds.append({
			"at": clock_sec + float(cue.get("at_sec", 0.0)),
			"id": str(cue.get("id", "")),
			"offset_db_base": float(cue.get("offset_db_base", 0.0)),
		})


func _play_event_sounds_instant(event: Dictionary) -> void:
	if not _sound_allowed():
		return
	for cue: Dictionary in cues_for_event(event, speed):
		_try_play_cue(str(cue.get("id", "")), float(cue.get("offset_db_base", 0.0)))


func _drain_scheduled_sounds() -> void:
	if not _sound_allowed():
		_scheduled_sounds.clear()
		return
	var keep: Array[Dictionary] = []
	for row: Dictionary in _scheduled_sounds:
		if clock_sec + 0.0001 < float(row.get("at", 0.0)):
			keep.append(row)
		else:
			_try_play_cue(str(row.get("id", "")), float(row.get("offset_db_base", 0.0)))
	_scheduled_sounds = keep


func _try_play_cue(cue_id: String, offset_db_base: float) -> void:
	if cue_id == "" or not _throttle_allows(cue_id):
		return
	var bus: String = _cue_bus(cue_id)
	if bus == "SFX_World":
		var audio: Node = get_node_or_null("/root/GameAudio")
		if audio != null and int(audio.call("busy_voices", "SFX_World")) >= _world_max:
			return
	var audio_node: Node = get_node_or_null("/root/GameAudio")
	if audio_node != null:
		audio_node.call(
			"play",
			cue_id,
			offset_db_base + randf_range(-_jitter_gain_db, _jitter_gain_db),
			randf_range(_jitter_pitch_min, _jitter_pitch_max),
		)
	if cue_id in ["sfx_battle_turn", "sfx_battle_victory"]:
		_throttle_last[cue_id] = clock_sec
		if cue_id == "sfx_battle_victory":
			_victory_played = true


func throttle_allows(cue_id: String) -> bool:
	_load_rules()
	return _throttle_allows(cue_id)


func _throttle_allows(cue_id: String) -> bool:
	if not _throttle_sec.has(cue_id):
		return true
	return clock_sec - float(_throttle_last.get(cue_id, -999.0)) >= float(_throttle_sec[cue_id])


func play_ui_cue(cue_id: String) -> void:
	_load_rules()
	if not _sound_allowed() or not _throttle_allows(cue_id):
		return
	_try_play_cue(cue_id, 0.0)


func play_battle_select() -> void:
	play_ui_cue(_menu_cue("select"))


func play_battle_confirm() -> void:
	play_ui_cue(_menu_cue("confirm"))


func _menu_cue(which: String) -> String:
	var table: Dictionary = {"select": "sfx_battle_select", "confirm": "sfx_battle_confirm", "turn": "sfx_battle_turn"}
	return str(table.get(which, ""))


func notify_party_turn() -> void:
	play_ui_cue(_menu_cue("turn"))


func _play_outcome_sound(result: String) -> void:
	if result == "win" and not _victory_played:
		play_ui_cue("sfx_battle_victory")
	elif result == "overwhelmed":
		play_ui_cue("sfx_battle_overwhelmed")


func _sound_allowed() -> bool:
	return DisplayServer.get_name() != "headless" and _fight != null and str(_fight.controller) == "manual"


func _cue_bus(cue_id: String) -> String:
	var audio: Node = get_node_or_null("/root/GameAudio")
	return str(audio.call("cue_bus", cue_id)) if audio != null else ""


func _load_rules() -> void:
	if not _rules_cache.is_empty():
		_apply_rules(_rules_cache)
		return
	var file := FileAccess.open(RULES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_rules_cache = (parsed as Dictionary).get("battle_playback", {}) as Dictionary
		_apply_rules(_rules_cache)


func _apply_rules(rules: Dictionary) -> void:
	_rules = rules
	_impact_by_band = rules.get("impact_by_band", {}) as Dictionary
	var crit_v: Variant = rules.get("crit_layer", {})
	if crit_v is Dictionary:
		_crit_cue = str((crit_v as Dictionary).get("cue", "sfx_battle_crit"))
		_crit_skip_fast = str((crit_v as Dictionary).get("at_fast_speed", "")) == "skip"
	var beast_v: Variant = rules.get("beast_hurt", {})
	if beast_v is Dictionary:
		_beast_hurt_cue = str((beast_v as Dictionary).get("cue", "sfx_battle_beast_hurt"))
		_beast_hurt_delay = float((beast_v as Dictionary).get("delay_sec", 0.06))
	var jitter_v: Variant = rules.get("jitter", {})
	if jitter_v is Dictionary:
		_jitter_pitch_min = float((jitter_v as Dictionary).get("pitch_min", 0.96))
		_jitter_pitch_max = float((jitter_v as Dictionary).get("pitch_max", 1.04))
		_jitter_gain_db = float((jitter_v as Dictionary).get("gain_db", 1.0))
	_world_max = int((rules.get("voices", {}) as Dictionary).get("world_max", 3))
	_throttle_sec = rules.get("throttle_sec", {}) as Dictionary


static func cues_for_event(event: Dictionary, speed: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_ensure_rules_static()
	var rules: Dictionary = _rules_cache
	var impact: Dictionary = rules.get("impact_by_band", {}) as Dictionary
	var crit_layer: Dictionary = rules.get("crit_layer", {}) as Dictionary
	var beast_hurt: Dictionary = rules.get("beast_hurt", {}) as Dictionary
	var crit_id: String = str(crit_layer.get("cue", "sfx_battle_crit"))
	var crit_skip: bool = str(crit_layer.get("at_fast_speed", "")) == "skip"
	var beast_id: String = str(beast_hurt.get("cue", "sfx_battle_beast_hurt"))
	var beast_delay: float = float(beast_hurt.get("delay_sec", 0.06))
	var fast: bool = speed == 2 or speed == 4
	var kind: String = str(event.get("kind", ""))
	var react: float = REACT_SEC / float(maxi(1, speed))
	match kind:
		"strike":
			var band: String = str(event.get("band", "hit"))
			out.append(_cue_row(str(impact.get(band, impact.get("hit", "sfx_battle_hit"))), react, 0.0))
			if bool(event.get("fate_crit", false)) and not (fast and crit_skip):
				out.append(_cue_row(crit_id, react, 0.0))
			if str(event.get("target_side", "")) == "beast" and int(event.get("damage", 0)) > 0:
				out.append(_cue_row(beast_id, react + beast_delay / float(maxi(1, speed)), 0.0))
		"brace":
			out.append(_cue_row("sfx_battle_brace", 0.0, 0.0))
		"item":
			if str(event.get("item", "")) == "heart_salve":
				out.append(_cue_row("sfx_battle_salve", react, 0.0))
		"flee":
			out.append(_cue_row("sfx_battle_flee", 0.0, 0.0))
		"knocked_out":
			out.append(_cue_row("sfx_battle_ko", 0.0, 0.0))
		"outcome":
			var result: String = str(event.get("result", ""))
			if result == "overwhelmed":
				out.append(_cue_row("sfx_battle_overwhelmed", 0.0, 0.0))
			elif result == "win":
				out.append(_cue_row("sfx_battle_victory", 0.0, 0.0))
	return out


static func _cue_row(id: String, at_sec: float, offset_db_base: float) -> Dictionary:
	return {"id": id, "at_sec": at_sec, "offset_db_base": offset_db_base}


static func _ensure_rules_static() -> void:
	if not _rules_cache.is_empty():
		return
	var file := FileAccess.open(RULES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_rules_cache = (parsed as Dictionary).get("battle_playback", {}) as Dictionary


func _tick_floats(dt: float) -> void:
	var alive: Array[Control] = []
	for node: Control in _float_nodes:
		if not is_instance_valid(node):
			continue
		var age: float = float(node.get_meta("age", 0.0)) + dt
		node.set_meta("age", age)
		var dur: float = float(node.get_meta("dur", FLOAT_FADE_SEC))
		node.position.y = float(node.get_meta("base_y", node.position.y)) - FLOAT_RISE_PX * clampf(age / dur, 0.0, 1.0)
		node.modulate.a = 1.0 - clampf(age / dur, 0.0, 1.0)
		if age >= dur:
			node.queue_free()
		else:
			alive.append(node)
	_float_nodes = alive


func register_float(node: Control) -> void:
	_float_nodes.append(node)


func _clear_floats() -> void:
	for node: Control in _float_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_float_nodes.clear()
