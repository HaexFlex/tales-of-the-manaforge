class_name SteepingCore
extends MinigameCore

var _spawned_cycle_idx: int = -1
var _draw: Dictionary = {}


func _on_start() -> void:
	_spawned_cycle_idx = -1
	_reset_draw()


func _on_advance(_real_dt: float) -> void:
	_update_show()
	_expire_tokens()
	_ensure_cycles()


func _on_input(ev: Dictionary) -> void:
	if str(ev.get("type", "")) != "press":
		return
	var token_id: int = int(_draw.get("token_id", -1))
	if token_id < 0 or not _live.has(token_id):
		return
	if bool(_draw.get("resolved", false)):
		return
	if str(_draw.get("phase", "")) != "input":
		return
	var herb: int = _herb_from_ev(ev)
	if herb < 0:
		return
	var order: Array = _draw.get("order", []) as Array
	var pick_i: int = int(_draw.get("pick_i", 0))
	if pick_i >= order.size():
		return
	if int(order[pick_i]) != herb:
		_draw["resolved"] = true
		_resolve(token_id, false, 1)
		return
	pick_i += 1
	_draw["pick_i"] = pick_i
	_draw["picks"] = (_draw.get("picks", []) as Array) + [herb]
	if pick_i >= order.size():
		_draw["resolved"] = true
		_resolve(token_id, true, 1)


func state() -> Dictionary:
	return _draw.duplicate(true)


func _herb_from_ev(ev: Dictionary) -> int:
	var key: String = str(ev.get("key", ""))
	if key.length() == 1 and key >= "1" and key <= "5":
		return int(key) - 1
	var hx: float = float(ev.get("x", -1.0))
	if hx < 0.0:
		return -1
	var herbs: int = int(cfg.get("herbs", 5))
	var slot: int = int(floorf(hx * float(herbs)))
	return clampi(slot, 0, herbs - 1)


func _update_show() -> void:
	if str(_draw.get("phase", "")) != "show":
		return
	var order: Array = _draw.get("order", []) as Array
	var per: float = float(cfg.get("show_sec_per_herb", 0.5))
	var show_start: float = float(_draw.get("show_start", 0.0))
	var elapsed: float = maxf(0.0, clock_sec - show_start)
	var revealed: int = int(floorf(elapsed / per)) + 1
	var show_end: float = float(_draw.get("show_end", 0.0))
	revealed = clampi(revealed, 0, order.size())
	_draw["revealed"] = revealed
	if clock_sec >= show_end:
		_draw["phase"] = "input"


func _reset_draw() -> void:
	_draw = {
		"token_id": -1,
		"phase": "show",
		"order": [],
		"revealed": 0,
		"pick_i": 0,
		"picks": [],
		"resolved": false,
		"show_start": 0.0,
		"show_end": 0.0,
	}


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 5.0))


func _ensure_cycles() -> void:
	var cycle: float = _cycle_sec()
	if cycle <= 0.0:
		return
	var idx: int = int(floorf(clock_sec / cycle))
	while _spawned_cycle_idx < idx:
		_spawned_cycle_idx += 1
		_spawn_cycle_token(_spawned_cycle_idx)


func _spawn_cycle_token(cycle_idx: int) -> void:
	for live_id: Variant in _live.keys():
		_resolve(int(live_id), false, 1)
	var o_min: int = int(cfg.get("order_min", 3))
	var o_max: int = int(cfg.get("order_max", 5))
	var count: int = rng.randi_range(o_min, o_max)
	var herbs: int = int(cfg.get("herbs", 5))
	var bag: Array[int] = []
	for i: int in herbs:
		bag.append(i)
	var order: Array = []
	for _i: int in count:
		var pick: int = rng.randi_range(0, bag.size() - 1)
		order.append(bag[pick])
		bag.remove_at(pick)
	var cycle: float = _cycle_sec()
	var start_t: float = float(cycle_idx) * cycle
	var per: float = float(cfg.get("show_sec_per_herb", 0.5))
	var show_end: float = start_t + per * float(count)
	var expire_at: float = float(cycle_idx + 1) * cycle
	var token_id: int = _spawn({
		"cycle_idx": cycle_idx,
		"expire_at": expire_at,
		"order": order.duplicate(),
	})
	_draw = {
		"token_id": token_id,
		"phase": "show",
		"order": order.duplicate(),
		"revealed": 0,
		"pick_i": 0,
		"picks": [],
		"resolved": false,
		"show_start": start_t,
		"show_end": show_end,
	}


func _expire_tokens() -> void:
	for token_id: Variant in _live.keys():
		var info: Dictionary = _live[token_id] as Dictionary
		if clock_sec >= float(info.get("expire_at", 0.0)):
			_resolve(int(token_id), false, 1)
			if int(_draw.get("token_id", -1)) == int(token_id):
				_draw["token_id"] = -1
				_draw["resolved"] = true
