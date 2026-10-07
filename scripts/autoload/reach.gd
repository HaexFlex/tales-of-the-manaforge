extends Node
## Endless reach rooms. Idle rolls and manual fights share one outing.
## Offline catch-up of an open run uses raw closed seconds. Play speed never multiplies it.
## The locked draft's Fate term, every-5 start checkpoints, room twists, crates, and Amberbind are not in this pass.
## Any unlocked depth can be started. Every 10th room attempted in an expedition is a boss at that room's depth.

signal changed

const ROOM_SEC: float = 720.0
const REST_SEC: float = 1440.0
const DC: int = 6
const PUSH_STOP: float = 0.75
const HOURS: Array[int] = [1, 2, 4, 8]
const SOLO_BUDGET: float = 3.0
const ART_MINION := "res://assets/art/echo/battle_root_snapper_idle.png"
const ART_CASTER := "res://assets/art/echo/battle_wilt_wisp_idle.png"
const ART_BRUTE := "res://assets/art/echo/battle_moss_brute_idle.png"

var deepest_depth: int = 0
var reaches_cleared: int = 0
var dojo_exp: int = 0
var briarwood: int = 0
var herbs: int = 0
var heart_salve: int = 0
var bile_vial: int = 0
var running: bool = false
var pace: String = "hold"
var control: String = "idle"
var depth: int = 1
var hours: float = 1.0
var elapsed: float = 0.0
var room_left: float = 0.0
var phase: String = "home"
var run_clears: int = 0
## Rooms begun this expedition, cleared or failed. Room 10, 20, 30… is the boss. A new Depart starts at 0.
var rooms_attempted: int = 0
var salve_used: bool = false
var rush: bool = false
var test_pp: float = -1.0
var party_size: int = 1
var mix: Array[String] = []

var _faces: Array[int] = []
var _drops: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _fight: ReachFight
var _view: Node
var _home_after_fight: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	rush = false


func _process(delta: float) -> void:
	if not running:
		return
	if not _session_open():
		return
	var step := delta
	if has_node("/root/GameState"):
		step = GameState.active_play_delta(delta)
	if rush and debug_tools():
		step *= 60.0
	advance_clock(step)


func debug_tools() -> bool:
	if OS.has_feature("manaforge_stable"):
		return false
	if has_node("/root/AnimPreviewHotkey"):
		return bool(AnimPreviewHotkey.debug_tools_enabled())
	return OS.is_debug_build()


func reset_for_new_game() -> void:
	deepest_depth = 0
	reaches_cleared = 0
	dojo_exp = 0
	briarwood = 0
	herbs = 0
	heart_salve = 0
	bile_vial = 0
	_end_run("dark")
	pace = "hold"
	control = "idle"
	depth = 1
	hours = 1.0
	test_pp = -1.0
	party_size = 1
	_faces.clear()
	_drops.clear()
	rush = false
	changed.emit()


func on_ascend() -> void:
	## Deepest depth, the lifetime reach counter, and the dojo pool stay.
	_end_run("dark")
	changed.emit()


func max_start_depth() -> int:
	return maxi(1, deepest_depth)


func room_level(room_depth: int) -> float:
	var d := maxi(1, room_depth)
	return 4.0 + 1.2 * pow(float(d), 0.6)


func room_exp(room_depth: int) -> int:
	return maxi(0, int(round(10.0 * pow(float(maxi(1, room_depth)), 0.8))))


func idle_bonus(pp: float, level: float) -> int:
	if level <= 0.0:
		return 0
	return clampi(int(round(20.0 * (pp / level - 1.0))), -10, 10)


func idle_clears(face: int, bonus: int) -> bool:
	if face <= 1:
		return false
	if face >= 20:
		return true
	return face + bonus >= DC


func clear_chance(bonus: int) -> float:
	var wins := 0
	for face: int in range(1, 21):
		if idle_clears(face, bonus):
			wins += 1
	return float(wins) / 20.0


func odds_line(bonus: int) -> String:
	var pct := int(round(clear_chance(bonus) * 100.0))
	var sign := "+" if bonus >= 0 else ""
	return "Clear chance %d%% (d20 %s%d vs 6)" % [pct, sign, bonus]


func party_power() -> float:
	if test_pp >= 0.0:
		return test_pp
	var off := _offense()
	var defense := (float(_stat("resilience")) + float(_stat("ward"))) * 0.5
	var pp := (off + defense + float(_stat("vitality")) + float(_stat("swiftness"))) / 4.0
	if party_size > 1:
		pp *= 1.15
	return pp


func preview_bonus(room_depth: int) -> int:
	return idle_bonus(party_power(), room_level(room_depth))


func preview_line(room_depth: int) -> String:
	return odds_line(preview_bonus(room_depth))


func push_would_stop(room_depth: int) -> bool:
	return clear_chance(preview_bonus(room_depth)) < PUSH_STOP


func is_boss_room() -> bool:
	return rooms_attempted > 0 and rooms_attempted % 10 == 0


func rooms_until_boss() -> int:
	## While the boss room is open this is 0. Otherwise it is how many rooms remain through that boss.
	var entered := rooms_attempted
	if running and (phase == "idle_room" or phase == "manual") and is_boss_room():
		return 0
	if entered % 10 == 0:
		return 10
	return 10 - (entered % 10)


func boss_line() -> String:
	if rooms_until_boss() == 0:
		return "Boss room"
	return "Rooms until boss: %d" % rooms_until_boss()


func set_test_pp(value: float) -> void:
	test_pp = value


func push_faces(faces: Array) -> void:
	for entry: Variant in faces:
		_faces.append(int(entry))


func push_drops(drops: Array) -> void:
	for entry: Variant in drops:
		_drops.append(int(entry))


func grant_salve(n: int) -> void:
	heart_salve = maxi(0, heart_salve + n)


func grant_vial(n: int) -> void:
	bile_vial = maxi(0, bile_vial + n)


func depart(start_depth: int, length_hours: float, pace_mode: String, control_mode: String) -> String:
	if running:
		return "busy"
	depth = clampi(start_depth, 1, max_start_depth())
	var picked := int(round(length_hours))
	hours = float(picked if HOURS.has(picked) else 1)
	pace = "push" if pace_mode == "push" else "hold"
	control = "manual" if control_mode == "manual" else "idle"
	running = true
	elapsed = 0.0
	run_clears = 0
	rooms_attempted = 0
	_home_after_fight = false
	salve_used = false
	_begin_room()
	_set_lantern("amber")
	changed.emit()
	return "ok"


func set_control(mode: String) -> void:
	if mode != "idle" and mode != "manual":
		return
	control = mode
	if not running or phase == "rest" or phase == "home":
		changed.emit()
		return
	if phase == "idle_room" and mode == "manual":
		_start_fight()
	elif phase == "manual" and mode == "idle":
		_fight = null
		_close_view()
		phase = "idle_room"
		if room_left <= 0.0:
			room_left = ROOM_SEC
	changed.emit()


func set_rush(on: bool) -> void:
	if not debug_tools():
		rush = false
		return
	rush = on


func debug_skip_room() -> void:
	if not debug_tools() or not running:
		return
	if phase == "manual":
		return
	advance_clock(room_left + 0.001)


func apply_offline_seconds(closed_sec: float) -> void:
	## Wall-clock seconds only. The play-speed button and Rush do not apply.
	if closed_sec <= 0.0 or not running:
		return
	advance_clock(closed_sec)


func advance_clock(seconds: float) -> void:
	var left := seconds
	var guard := 0
	while left > 0.0000001 and running and guard < 10000:
		guard += 1
		if phase == "manual":
			var budget := _length_left()
			if budget <= 0.0000001:
				_home_after_fight = true
				break
			var slice := minf(left, budget)
			elapsed += slice
			left -= slice
			if _length_left() <= 0.0000001:
				_home_after_fight = true
			break
		var budget_left := _length_left()
		if budget_left <= 0.0000001:
			_finish_run()
			break
		var step := minf(left, minf(room_left, budget_left))
		if step <= 0.0:
			break
		elapsed += step
		room_left -= step
		left -= step
		if room_left <= 0.0001:
			if phase == "rest":
				_begin_room()
			elif phase == "idle_room":
				_resolve_idle()
		elif _length_left() <= 0.0001:
			if phase == "idle_room":
				_resolve_idle()
			if running:
				_finish_run()
			break
	changed.emit()


func fight_active() -> bool:
	return _fight != null and running and phase == "manual"


func fight_snapshot() -> Dictionary:
	if _fight == null:
		return {}
	var snap: Dictionary = _fight.snapshot()
	snap["salve"] = heart_salve
	snap["vial"] = bile_vial
	return snap


func fight_choose(action: String, target: int = 0) -> String:
	if _fight == null:
		return "none"
	if action == "salve" and heart_salve <= 0:
		return "empty"
	if action == "bile" and bile_vial <= 0:
		return "empty"
	if action == "salve":
		heart_salve -= 1
	elif action == "bile":
		bile_vial -= 1
	var result := _fight.choose(action, target)
	if result == "invalid":
		if action == "salve":
			heart_salve += 1
		elif action == "bile":
			bile_vial += 1
		return result
	_after_fight()
	changed.emit()
	return result


func debug_wound(amount: int) -> String:
	if _fight == null:
		return "none"
	var result := _fight.debug_wound(amount)
	_after_fight()
	changed.emit()
	return result


func capture_save_fields() -> Dictionary:
	var saved_phase := phase
	if saved_phase == "manual":
		saved_phase = "idle_room"
	return {
		"reach": {
			"deepest_depth": deepest_depth,
			"reaches_cleared": reaches_cleared,
			"dojo_exp": dojo_exp,
			"briarwood": briarwood,
			"herbs": herbs,
			"heart_salve": heart_salve,
			"bile_vial": bile_vial,
			"running": running,
			"pace": pace,
			"control": control,
			"depth": depth,
			"hours": hours,
			"elapsed": elapsed,
			"room_left": room_left,
			"phase": saved_phase,
			"run_clears": run_clears,
			"rooms_attempted": rooms_attempted,
			"salve_used": salve_used,
		}
	}


func apply_save_fields(data: Dictionary) -> void:
	if data.is_empty():
		reset_for_new_game()
		return
	deepest_depth = maxi(0, int(data.get("deepest_depth", 0)))
	reaches_cleared = maxi(0, int(data.get("reaches_cleared", 0)))
	dojo_exp = maxi(0, int(data.get("dojo_exp", 0)))
	briarwood = maxi(0, int(data.get("briarwood", 0)))
	herbs = maxi(0, int(data.get("herbs", 0)))
	heart_salve = maxi(0, int(data.get("heart_salve", 0)))
	bile_vial = maxi(0, int(data.get("bile_vial", 0)))
	pace = "push" if str(data.get("pace", "hold")) == "push" else "hold"
	control = "manual" if str(data.get("control", "idle")) == "manual" else "idle"
	depth = maxi(1, int(data.get("depth", 1)))
	hours = float(data.get("hours", 1.0))
	elapsed = maxf(0.0, float(data.get("elapsed", 0.0)))
	room_left = maxf(0.0, float(data.get("room_left", 0.0)))
	run_clears = maxi(0, int(data.get("run_clears", 0)))
	rooms_attempted = maxi(0, int(data.get("rooms_attempted", 0)))
	salve_used = bool(data.get("salve_used", false))
	var saved_phase := str(data.get("phase", "home"))
	running = bool(data.get("running", false))
	if not running:
		_end_run(str(GameState.expedition_lantern) if has_node("/root/GameState") else "dark")
		return
	if saved_phase != "rest" and saved_phase != "idle_room":
		saved_phase = "idle_room"
	phase = saved_phase
	_fight = null
	_close_view()
	changed.emit()


func default_save_fields() -> Dictionary:
	return {
		"deepest_depth": 0,
		"reaches_cleared": 0,
		"dojo_exp": 0,
		"briarwood": 0,
		"herbs": 0,
		"heart_salve": 0,
		"bile_vial": 0,
		"running": false,
		"pace": "hold",
		"control": "idle",
		"depth": 1,
		"hours": 1.0,
		"elapsed": 0.0,
		"room_left": 0.0,
		"phase": "home",
		"run_clears": 0,
		"rooms_attempted": 0,
		"salve_used": false,
	}


func _resolve_idle() -> void:
	var cleared := _roll_idle()
	if cleared:
		_grant_room()
	_advance_depth()
	if _length_left() <= 0.0001:
		_finish_run()
		return
	if cleared:
		_begin_room()
		return
	phase = "rest"
	room_left = REST_SEC
	_fight = null
	_close_view()


func _roll_idle() -> bool:
	var bonus := preview_bonus(depth)
	var face := _next_face()
	var cleared := idle_clears(face, bonus)
	if not cleared and heart_salve > 0 and not salve_used:
		heart_salve -= 1
		salve_used = true
		face = _next_face()
		cleared = idle_clears(face, bonus)
	return cleared


func _grant_room() -> void:
	var mult := 2 if is_boss_room() else 1
	briarwood += _next_drop() * mult
	herbs += _next_drop() * mult
	dojo_exp += room_exp(depth) * mult
	reaches_cleared += 1
	run_clears += 1
	if depth > deepest_depth:
		deepest_depth = depth


func _advance_depth() -> void:
	if pace != "push":
		return
	var nxt := depth + 1
	if push_would_stop(nxt):
		pace = "hold"
		return
	depth = nxt


func _begin_room() -> void:
	rooms_attempted += 1
	salve_used = false
	mix = _roll_mix(SOLO_BUDGET if party_size <= 1 else 4.0)
	room_left = ROOM_SEC
	if control == "manual":
		_start_fight()
		return
	phase = "idle_room"
	_fight = null
	_close_view()


func _start_fight() -> void:
	phase = "manual"
	_fight = ReachFight.new()
	_fight.force_miss = 0
	_fight.setup(depth, room_level(depth), _keeper_block(), mix, _champion_index(), _names(), _arts())
	_open_view()


func _after_fight() -> void:
	if _fight == null:
		return
	var result := _fight.outcome
	if result == "":
		return
	_fight = null
	_close_view()
	if result == "victory":
		_grant_room()
		_advance_depth()
		if _home_after_fight or _length_left() <= 0.0001:
			_finish_run()
		else:
			_begin_room()
		return
	_finish_run()


func _finish_run() -> void:
	var brought := run_clears > 0
	_end_run("cyan" if brought else "dark")


func _end_run(lantern: String) -> void:
	running = false
	phase = "home"
	room_left = 0.0
	rooms_attempted = 0
	_home_after_fight = false
	_fight = null
	mix.clear()
	_close_view()
	_set_lantern(lantern)


func _roll_mix(budget: float) -> Array[String]:
	var roles: Array[String] = ["minion", "caster", "brute"]
	var costs := {"minion": 1.0, "caster": 1.5, "brute": 2.5}
	var out: Array[String] = []
	var left := budget
	var guard := 0
	while left >= 1.0 - 0.001 and guard < 8:
		guard += 1
		var options: Array[String] = []
		for role: String in roles:
			if float(costs[role]) <= left + 0.001:
				options.append(role)
		if options.is_empty():
			break
		var pick: String = options[_rng.randi() % options.size()]
		out.append(pick)
		left -= float(costs[pick])
	if out.is_empty():
		out.append("minion")
	return out


func _champion_index() -> int:
	if not is_boss_room() or mix.is_empty():
		return -1
	return 0


func _names() -> Dictionary:
	return {
		"minion": _minion_name(),
		"caster": "Caster",
		"brute": "Brute",
	}


func _minion_name() -> String:
	if has_node("/root/ContentStrings"):
		var named := ContentStrings.get_text("adventure_reach_foe_name")
		if named != "" and named != "adventure_reach_foe_name":
			return named
	return "Thornling"


func _arts() -> Dictionary:
	return {"minion": ART_MINION, "caster": ART_CASTER, "brute": ART_BRUTE}


func _keeper_block() -> Dictionary:
	return {
		"might": _stat("might"),
		"arcana": _stat("arcana"),
		"resilience": _stat("resilience"),
		"ward": _stat("ward"),
		"vitality": _stat("vitality"),
		"swiftness": _stat("swiftness"),
		"fate": _stat("fate"),
		"offense": _offense(),
	}


func _offense() -> float:
	var might := float(_stat("might"))
	var arcana := float(_stat("arcana"))
	var kind := "physical"
	if has_node("/root/Equipment"):
		var wid := Equipment.equipped_id("weapon")
		kind = str(Equipment.get_item_def(wid).get("damage_kind", "physical"))
	if kind == "magical":
		return arcana
	if kind == "hybrid":
		return (might + arcana) * 0.5
	return might


func _stat(stat_id: String) -> int:
	if has_node("/root/Equipment"):
		return int(Equipment.total_for(stat_id))
	if has_node("/root/KeeperStats"):
		return int(KeeperStats.get_base(stat_id))
	return 5


func _next_face() -> int:
	if not _faces.is_empty():
		return int(_faces.pop_front())
	return _rng.randi_range(1, 20)


func _next_drop() -> int:
	if not _drops.is_empty():
		return 1 if int(_drops.pop_front()) > 0 else 0
	return 1 if _rng.randf() < 0.5 else 0


func _length_left() -> float:
	return maxf(0.0, hours * 3600.0 - elapsed)


func _session_open() -> bool:
	return has_node("/root/SaveService") and SaveService.session_active


func _set_lantern(state: String) -> void:
	if not has_node("/root/GameState"):
		return
	if state != "amber" and state != "cyan" and state != "dark":
		state = "dark"
	GameState.expedition_lantern = state
	GameState.echo_flags_changed.emit()


func _open_view() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _view != null and is_instance_valid(_view):
		_view.call("refresh")
		return
	var script: Script = load("res://scripts/reach_fight_view.gd") as Script
	if script == null:
		return
	_view = Node.new()
	_view.set_script(script)
	_view.name = "ReachFightView"
	get_tree().root.add_child(_view)


func _close_view() -> void:
	if _view != null and is_instance_valid(_view):
		_view.queue_free()
	_view = null
