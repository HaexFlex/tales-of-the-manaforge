extends Node
## R5 brewing stand: queue, wisps, offline raw gap. Data in data/brewing.json.

const DATA_PATH: String = "res://data/brewing.json"
const STATION_ID: String = "brewing"

var _data: Dictionary = {}
var _recipe_index: Dictionary = {}
var _job: Dictionary = {
	"recipe_id": "",
	"remaining_sec": 0.0,
	"queue_left": 0,
	"worker": "",
	"working": false,
}
var _bubble_next_ms: int = 0
var _done_throttle_ms: int = 0
var _in_hub_scene: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load()


func _load() -> void:
	_data = _read_json(DATA_PATH)
	_recipe_index.clear()
	for entry_v: Variant in (_data.get("recipes", []) as Array):
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		_recipe_index[str(entry.get("id", ""))] = entry


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func unlocked() -> bool:
	return GameState.brewing_unlocked


func is_brewing_station(node_id: String) -> bool:
	return node_id == STATION_ID and unlocked()


func wisp_cap() -> int:
	var station: Dictionary = _data.get("station", {}) as Dictionary
	return int(station.get("wisp_cap", 2))


func queue_max() -> int:
	var station: Dictionary = _data.get("station", {}) as Dictionary
	return int(station.get("queue_max_outputs", 20))


func hub_pos() -> Vector2:
	var station: Dictionary = _data.get("station", {}) as Dictionary
	var pos_v: Variant = station.get("hub_pos", [1688, 2580])
	if pos_v is Array and (pos_v as Array).size() >= 2:
		return Vector2(float(pos_v[0]), float(pos_v[1]))
	return Vector2(1688, 2580)


func recipe(id: String) -> Dictionary:
	var found: Variant = _recipe_index.get(id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func moss_tonic_buff() -> Dictionary:
	var buff_v: Variant = _data.get("moss_tonic_buff", {})
	return buff_v if typeof(buff_v) == TYPE_DICTIONARY else {}


func note_hub_scene(active: bool) -> void:
	_in_hub_scene = active


func _process(delta: float) -> void:
	if not unlocked() or not _job.get("working", false):
		return
	var play_delta: float = GameState.active_play_delta(delta)
	if play_delta <= 0.0:
		return
	_tick_brew(play_delta)
	_tick_bubble_sfx()


func station_speed_mult() -> float:
	var staffing: Dictionary = (_data.get("staffing", {}) as Dictionary)
	var worker: String = str(_job.get("worker", ""))
	var base: float = 1.0
	if worker == "keeper":
		base = float(staffing.get("keeper_speed", 1.0))
	elif worker == "puff":
		base = GameState.actor_brew_rate("puff")
	elif worker != "":
		base = GameState.actor_brew_rate(worker)
	var wisps: int = mini(GameState.count_wisps_on_node(STATION_ID), wisp_cap())
	var wisp_term: float = float(wisps) * float(staffing.get("wisp_speed", 0.1))
	var mult: float = base + wisp_term
	mult *= GameState.moss_tonic_wisp_mult()
	return maxf(0.01, mult)


func try_start(recipe_id: String, worker: String, count: int = 1) -> String:
	if not unlocked():
		return "locked"
	var rec: Dictionary = recipe(recipe_id)
	if rec.is_empty():
		return "unknown"
	if not _can_pay(rec, count):
		return "cant_afford"
	if _job.get("working", false):
		return "busy"
	_spend_inputs(rec, count)
	_job = {
		"recipe_id": recipe_id,
		"remaining_sec": float(rec.get("duration_sec", 60)) * float(count),
		"queue_left": clampi(count - 1, 0, queue_max() - 1),
		"worker": worker,
		"working": true,
	}
	return "ok"


func _can_pay(rec: Dictionary, count: int) -> bool:
	var inputs_v: Variant = rec.get("inputs", {})
	if typeof(inputs_v) != TYPE_DICTIONARY:
		return true
	for key_v: Variant in (inputs_v as Dictionary).keys():
		var need: int = int((inputs_v as Dictionary)[key_v]) * count
		if str(key_v) == "essence":
			if GameState.essence < need:
				return false
		elif Backpack.get_count(str(key_v)) < need:
			return false
	return true


func _spend_inputs(rec: Dictionary, count: int) -> void:
	var inputs_v: Variant = rec.get("inputs", {})
	if typeof(inputs_v) != TYPE_DICTIONARY:
		return
	for key_v: Variant in (inputs_v as Dictionary).keys():
		var need: int = int((inputs_v as Dictionary)[key_v]) * count
		if str(key_v) == "essence":
			GameState.add_resource(&"essence", -need)
		else:
			Backpack.try_spend(str(key_v), need)


func _tick_brew(delta: float) -> void:
	var mult: float = station_speed_mult()
	_job["remaining_sec"] = float(_job.get("remaining_sec", 0.0)) - delta * mult
	if float(_job["remaining_sec"]) > 0.0:
		return
	_finish_one()


func _finish_one() -> void:
	var recipe_id: String = str(_job.get("recipe_id", ""))
	var rec: Dictionary = recipe(recipe_id)
	if rec.is_empty():
		_job["working"] = false
		return
	var out_id: String = str(rec.get("output_id", recipe_id))
	var out_n: int = int(rec.get("output_count", 1))
	if str(rec.get("use", "")) == "hub_buff":
		GameState.drink_moss_tonic()
	else:
		Backpack.add_item(out_id, out_n)
	_play_done_sfx()
	var left: int = int(_job.get("queue_left", 0))
	if left > 0 and bool((_data.get("station", {}) as Dictionary).get("auto_repeat", true)):
		if _can_pay(rec, 1):
			_spend_inputs(rec, 1)
			_job["queue_left"] = left - 1
			_job["remaining_sec"] = float(rec.get("duration_sec", 60))
			return
	_job["working"] = false
	_job["queue_left"] = 0


func apply_offline_seconds(raw_sec: float) -> Dictionary:
	var result: Dictionary = {"brew_completed": 0, "outputs": {}}
	if not unlocked() or raw_sec <= 0.0 or not _job.get("working", false):
		return result
	var left: float = float(_job.get("remaining_sec", 0.0))
	var mult: float = station_speed_mult()
	var craft_sec: float = raw_sec * mult
	while craft_sec > 0.0 and _job.get("working", false):
		if craft_sec < left:
			_job["remaining_sec"] = left - craft_sec
			craft_sec = 0.0
			break
		craft_sec -= left
		_finish_one_offline(result)
		left = float(_job.get("remaining_sec", 0.0))
	return result


func _finish_one_offline(result: Dictionary) -> void:
	var recipe_id: String = str(_job.get("recipe_id", ""))
	var rec: Dictionary = recipe(recipe_id)
	if rec.is_empty():
		_job["working"] = false
		return
	var out_id: String = str(rec.get("output_id", recipe_id))
	if str(rec.get("use", "")) == "hub_buff":
		GameState.drink_moss_tonic()
	else:
		Backpack.add_item(out_id, int(rec.get("output_count", 1)))
		result["brew_completed"] = int(result.get("brew_completed", 0)) + 1
		var outs: Dictionary = result.get("outputs", {}) as Dictionary
		outs[out_id] = int(outs.get(out_id, 0)) + int(rec.get("output_count", 1))
		result["outputs"] = outs
	var left: int = int(_job.get("queue_left", 0))
	if left > 0:
		_job["queue_left"] = left - 1
		_job["remaining_sec"] = float(rec.get("duration_sec", 60))
	else:
		_job["working"] = false


func _tick_bubble_sfx() -> void:
	if not _in_hub_scene or not has_node("/root/GameAudio"):
		return
	var now: int = Time.get_ticks_msec()
	if now < _bubble_next_ms:
		return
	_bubble_next_ms = now + randi_range(3000, 4000)
	var pitch: float = randf_range(0.95, 1.05)
	GameAudio.play(&"sfx_brew_bubble", 0.0, pitch)


func _play_done_sfx() -> void:
	if not _in_hub_scene or not has_node("/root/GameAudio"):
		return
	var now: int = Time.get_ticks_msec()
	if now - _done_throttle_ms < 2000:
		return
	_done_throttle_ms = now
	GameAudio.play(&"sfx_brew_done")


func capture_save_fields() -> Dictionary:
	return {"brewing_job": _job.duplicate(true)}


func apply_save_fields(data: Dictionary) -> void:
	var job_v: Variant = data.get("brewing_job", {})
	if typeof(job_v) == TYPE_DICTIONARY:
		_job = (job_v as Dictionary).duplicate(true)


func job_working() -> bool:
	return bool(_job.get("working", false))


func advance_brew_seconds(sec: float) -> void:
	if not _job.get("working", false):
		return
	_tick_brew(sec)
