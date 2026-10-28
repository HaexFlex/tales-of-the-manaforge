class_name WeatherState
extends RefCounted
## Session weather. Default clear. Tests set the state. A load rerolls it.
## Bonuses apply only while the game is open. Offline catch-up suspends them.

const DATA_PATH: String = "res://data/weather_harvests.json"

static var state: String = "clear"
static var _loaded: bool = false
static var _data: Dictionary = {}
static var _suspend: int = 0
static var _trickle_pulses: float = 0.0
static var _roll_queue: Array[String] = []
static var _force_auto: bool = false
static var _chance_override: float = -1.0


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	state = str(_data.get("default", "clear"))
	if not _states().has(state):
		state = "clear"


static func _states() -> Array:
	_ensure()
	var raw: Variant = _data.get("states", [])
	return raw if typeof(raw) == TYPE_ARRAY else ["clear", "soft_rain", "mist", "snow", "blossom"]


static func _row(key: String) -> Dictionary:
	_ensure()
	var found: Variant = _data.get(key, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


static func bonuses_live() -> bool:
	return _suspend <= 0


static func push_offline() -> void:
	_suspend += 1


static func pop_offline() -> void:
	_suspend = maxi(0, _suspend - 1)


static func reset_default() -> void:
	_ensure()
	state = str(_data.get("default", "clear"))
	_trickle_pulses = 0.0
	_chance_override = -1.0
	_suspend = 0


static func set_state(next: String) -> void:
	_ensure()
	state = next if _states().has(next) else str(_data.get("default", "clear"))


static func get_state() -> String:
	_ensure()
	return state


static func label_key() -> String:
	return "weather_%s" % get_state()


static func label_text() -> String:
	var key: String = label_key()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return key
	var strings: Node = tree.root.get_node_or_null("ContentStrings")
	if strings == null:
		return key
	return str(strings.call("get_text", key))


static func push_test_roll(next: String) -> void:
	_roll_queue.append(next)


static func on_save_loaded() -> void:
	## Every load rerolls. Headless stays on clear unless a test queued a roll,
	## so the suite's harvest counts do not move. A windowed load uses the real roll.
	_ensure()
	_trickle_pulses = 0.0
	var next: String = ""
	if not _roll_queue.is_empty():
		next = _roll_queue.pop_front()
	elif _is_headless():
		next = str(_data.get("default", "clear"))
	else:
		var states: Array = _states()
		if states.is_empty():
			next = "clear"
		else:
			next = str(states[randi() % states.size()])
	set_state(next)


static func set_force_auto(on: bool) -> void:
	_force_auto = on


static func set_frostberry_chance_override(chance: float) -> void:
	_chance_override = chance


static func water_essence_mult() -> float:
	if not bonuses_live() or get_state() != "blossom":
		return 1.0
	return float(_row("blossom").get("water_essence_mult", 1.0))


static func glowcap_weight_mult() -> float:
	if not bonuses_live() or get_state() != "mist":
		return 1.0
	return float(_row("mist").get("glowcap_weight_mult", 1.0))


static func frostberry_spec() -> Dictionary:
	if not bonuses_live() or get_state() != "snow":
		return {}
	var row: Dictionary = _row("snow")
	var chance: float = float(row.get("frostberry_chance", 0.0))
	if _chance_override >= 0.0:
		chance = _chance_override
	return {
		"chance": chance,
		"bonus": int(row.get("frostberry_bonus", 1)),
		"item_id": str(row.get("item_id", "frostberry")),
	}


static func trickle_pulses_per_sec() -> float:
	if not bonuses_live() or get_state() != "soft_rain":
		return 0.0
	if not bool(_row("soft_rain").get("auto_water", false)):
		return 0.0
	var configured: float = float(_row("soft_rain").get("trickle_pulses_per_sec", 0.0))
	if configured <= 0.0:
		return 0.0
	var cap: float = 1.0
	if Engine.get_main_loop() != null:
		var gs: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameState")
		if gs != null:
			cap = 1.0 / maxf(float(gs.call("get_water_essence_pulse_sec")), 0.05)
	return minf(configured, cap)


static func active_watering() -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var jobs: Node = tree.root.get_node_or_null("ForgeJobs")
	if jobs == null:
		return false
	for who: String in ["keeper", "elaia"]:
		var task: Dictionary = jobs.call("keeper_task") if who == "keeper" else jobs.call("elaia_task")
		if str(task.get("kind", "")) == "water" and bool(task.get("working", false)):
			return true
	return false


static func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


static func tick(delta: float) -> void:
	if not _force_auto and _is_headless():
		return
	tick_rain(delta)


static func tick_rain(delta: float) -> void:
	if delta <= 0.0:
		return
	var rate: float = trickle_pulses_per_sec()
	if rate <= 0.0 or active_watering():
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return
	if bool(gs.get("fruit_committed")) or bool(gs.call("is_world_frozen")):
		return
	_trickle_pulses += delta * rate
	while _trickle_pulses >= 1.0 - 0.00001:
		_trickle_pulses -= 1.0
		gs.call("apply_water_pulse", true, true, 1.0, "")
