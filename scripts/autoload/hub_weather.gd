extends Node
## R6 hub weather: season wheel, state machine, soft rain auto-water. PLACEHOLDER tuning from data/weather.json.

signal state_changed(state_id: StringName)

const DATA_PATH: String = "res://data/weather.json"

var weather_state: StringName = &"clear"
var weather_elapsed_sec: float = 0.0
var weather_duration_sec: float = 0.0
var weather_season_index: int = 0
var weather_season_elapsed_sec: float = 0.0
var weather_essence_frac: float = 0.0

var _data: Dictionary = {}
var _season_order: Array[String] = []
var _season_duration_sec: float = 259200.0
var _rain_accum: float = 0.0
var _loaded: bool = false


func _ready() -> void:
	_load_data()
	_reroll_state_and_duration()
	set_process(true)


func _load_data() -> void:
	if _loaded:
		return
	var txt: String = FileAccess.get_file_as_string(DATA_PATH)
	var parsed: Variant = JSON.parse_string(txt)
	_data = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	var wheel: Dictionary = (_data.get("season_wheel", {}) as Dictionary)
	var order_v: Variant = wheel.get("order", ["spring", "summer", "autumn", "winter"])
	_season_order.clear()
	if typeof(order_v) == TYPE_ARRAY:
		for item: Variant in order_v as Array:
			_season_order.append(String(item))
	if _season_order.is_empty():
		_season_order = ["spring", "summer", "autumn", "winter"]
	_season_duration_sec = maxf(1.0, float(wheel.get("season_duration_real_sec", 259200.0)))
	_loaded = true


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_advance_season(delta)
	if not _hub_foreground():
		return
	weather_elapsed_sec += delta
	while weather_elapsed_sec >= weather_duration_sec and weather_duration_sec > 0.0:
		weather_elapsed_sec -= weather_duration_sec
		_transition_to_next()
	_tick_soft_rain(delta)


func current_state() -> StringName:
	return weather_state


func wisp_glow_add() -> float:
	if weather_state != &"mist":
		return 0.0
	var fx: Dictionary = (_data.get("effects", {}) as Dictionary).get("wisp_glow", {}) as Dictionary
	return float(fx.get("modulate_add", 0.15))


func is_raining() -> bool:
	return weather_state == &"soft_rain"


func to_save_dict() -> Dictionary:
	return {
		"weather_season_index": weather_season_index,
		"weather_season_elapsed_sec": weather_season_elapsed_sec,
		"weather_essence_frac": weather_essence_frac,
	}


func apply_from_save(data: Dictionary, reroll_on_load: bool) -> void:
	_load_data()
	weather_season_index = int(data.get("weather_season_index", 0))
	weather_season_elapsed_sec = maxf(0.0, float(data.get("weather_season_elapsed_sec", 0.0)))
	weather_essence_frac = maxf(0.0, float(data.get("weather_essence_frac", 0.0)))
	_clamp_season_index()
	if reroll_on_load:
		_reroll_state_and_duration()
	else:
		weather_state = StringName(str(data.get("weather_state", "clear")))
		weather_elapsed_sec = 0.0
		weather_duration_sec = roll_duration(weather_state)
	_rain_accum = 0.0
	state_changed.emit(weather_state)


func on_ascend() -> void:
	weather_essence_frac = 0.0
	_reroll_state_and_duration()


func reset_for_new_game() -> void:
	_load_data()
	weather_season_index = 0
	weather_season_elapsed_sec = 0.0
	weather_essence_frac = 0.0
	_reroll_state_and_duration()


func force_state_for_debug(state_id: StringName) -> void:
	weather_state = state_id
	weather_elapsed_sec = 0.0
	weather_duration_sec = roll_duration(state_id)
	state_changed.emit(weather_state)


func roll_duration(state_id: StringName) -> float:
	var states: Dictionary = _data.get("states", {}) as Dictionary
	var def: Dictionary = states.get(String(state_id), {}) as Dictionary
	var min_s: float = float(def.get("duration_min_sec", 60.0))
	var max_s: float = float(def.get("duration_max_sec", min_s))
	if max_s < min_s:
		max_s = min_s
	return randf_range(min_s, max_s)


func pick_initial_state() -> StringName:
	return _weighted_pick(&"clear", true)


func _transition_to_next() -> void:
	var next: StringName = _weighted_pick(weather_state, false)
	weather_state = next
	weather_duration_sec = roll_duration(next)
	state_changed.emit(weather_state)


func _weighted_pick(from_state: StringName, allow_self: bool) -> StringName:
	var trans: Dictionary = _data.get("transition_weights", {}) as Dictionary
	var row: Dictionary = trans.get(String(from_state), {}) as Dictionary
	if row.is_empty():
		return &"clear"
	var season_key: String = _season_key()
	var bias: Dictionary = (
		(_data.get("season_wheel", {}) as Dictionary).get("bias", {}) as Dictionary
	).get(season_key, {}) as Dictionary
	var total: float = 0.0
	var keys: Array[StringName] = []
	var weights: Array[float] = []
	for key: Variant in row.keys():
		var sid: StringName = StringName(String(key))
		var w: float = float(row[key])
		if not allow_self and sid == from_state:
			continue
		if w <= 0.0:
			continue
		w *= float(bias.get(String(sid), 1.0))
		keys.append(sid)
		weights.append(w)
		total += w
	if total <= 0.0 or keys.is_empty():
		return &"clear"
	var roll: float = randf() * total
	var acc: float = 0.0
	for i: int in keys.size():
		acc += weights[i]
		if roll <= acc:
			return keys[i]
	return keys[keys.size() - 1]


func _season_key() -> String:
	if _season_order.is_empty():
		return "spring"
	return _season_order[weather_season_index % _season_order.size()]


func _advance_season(delta: float) -> void:
	weather_season_elapsed_sec += delta
	while weather_season_elapsed_sec >= _season_duration_sec:
		weather_season_elapsed_sec -= _season_duration_sec
		weather_season_index = (weather_season_index + 1) % maxi(1, _season_order.size())


func _clamp_season_index() -> void:
	var n: int = maxi(1, _season_order.size())
	weather_season_index = ((weather_season_index % n) + n) % n


func _reroll_state_and_duration() -> void:
	weather_state = pick_initial_state()
	weather_elapsed_sec = 0.0
	weather_duration_sec = roll_duration(weather_state)
	state_changed.emit(weather_state)


func _hub_foreground() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	if tree.get_first_node_in_group("main_root") == null:
		return false
	if tree.get_first_node_in_group("forge_room") != null:
		return false
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return false
	return true


func _tick_soft_rain(delta: float) -> void:
	if weather_state != &"soft_rain":
		_rain_accum = 0.0
		return
	var auto_v: Dictionary = (_data.get("effects", {}) as Dictionary).get("auto_water", {}) as Dictionary
	var interval: float = maxf(0.1, float(auto_v.get("pulse_interval_sec", 8.0)))
	_rain_accum += delta
	while _rain_accum >= interval:
		_rain_accum -= interval
		GameState.apply_weather_water_pulse(auto_v)


func duration_bounds(state_id: StringName) -> Vector2:
	var states: Dictionary = _data.get("states", {}) as Dictionary
	var def: Dictionary = states.get(String(state_id), {}) as Dictionary
	return Vector2(
		float(def.get("duration_min_sec", 0.0)),
		float(def.get("duration_max_sec", 0.0))
	)
