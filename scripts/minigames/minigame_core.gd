class_name MinigameCore
extends RefCounted
## Pure minigame logic: clock, tokens, pace. No nodes or autoloads.

signal spawned(token_id: int, info: Dictionary)
signal resolved(token_id: int, success: bool, weight: int)
signal perfect_cycle()

var cfg: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var clock_sec: float = 0.0
var successes: int = 0
var fails: int = 0
var spawned_count: int = 0
var weight_sum: int = 0
var paused: bool = false
var last_results: Array[int] = []

var _live: Dictionary = {}
var _next_token_id: int = 1
var _resolved_ids: Dictionary = {}


func start(p_cfg: Dictionary, seed: int) -> void:
	cfg = p_cfg.duplicate(true)
	rng.seed = seed
	clock_sec = 0.0
	successes = 0
	fails = 0
	spawned_count = 0
	weight_sum = 0
	paused = false
	last_results.clear()
	_live.clear()
	_next_token_id = 1
	_resolved_ids.clear()
	_on_start()


func advance(real_dt: float) -> void:
	if paused:
		return
	clock_sec += real_dt
	_on_advance(real_dt)


func input(ev: Dictionary) -> void:
	if paused:
		return
	_on_input(ev)


func set_paused(on: bool) -> void:
	paused = on


func state() -> Dictionary:
	return {}


func finish() -> Dictionary:
	var game_id: String = str(cfg.get("_game_id", cfg.get("id", "")))
	var k: float = float(cfg.get("k", 0.0))
	return {
		"game_id": game_id,
		"successes": successes,
		"fails": fails,
		"spawned": spawned_count,
		"weight_sum": weight_sum,
		"bonus_sec": float(weight_sum) * k,
		"clock_sec": clock_sec,
		"pace": pace(),
	}


func pace() -> float:
	var max_pace: float = float(cfg.get("_max_pace", 3.0))
	var k: float = float(cfg.get("k", 0.0))
	var cycle: float = float(cfg.get("cycle_sec", 1.0))
	var denom: float = maxf(clock_sec, cycle)
	return clampf(1.0 + float(weight_sum) * k / denom, 1.0, max_pace)


func _on_start() -> void:
	pass


func _on_advance(_real_dt: float) -> void:
	pass


func _on_input(_ev: Dictionary) -> void:
	pass


func _spawn(info: Dictionary) -> int:
	var token_id: int = _next_token_id
	_next_token_id += 1
	spawned_count += 1
	_live[token_id] = info.duplicate(true)
	spawned.emit(token_id, info)
	return token_id


func _resolve(token_id: int, success: bool, weight: int = 1) -> void:
	if _resolved_ids.has(token_id):
		return
	if not _live.has(token_id):
		return
	_resolved_ids[token_id] = true
	_live.erase(token_id)
	var w: int = maxi(1, weight)
	if success:
		successes += 1
		weight_sum += w
		last_results.append(2 if w > 1 else 1)
	else:
		fails += 1
		last_results.append(0)
	while last_results.size() > 10:
		last_results.pop_front()
	resolved.emit(token_id, success, w if success else 0)
