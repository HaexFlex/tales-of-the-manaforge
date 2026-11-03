extends Node
## Run state: Grow, Ancient timeout freeze, Forge visit, wisps, and Echo flags.

signal resources_changed(resource_id: StringName, new_amount: int)
signal stage_changed(stage_id: StringName)
signal needs_changed
signal fruit_ready_changed(ready: bool)
signal upgrades_changed
signal status_message(text: String)
signal load_completed
signal wisps_changed
signal selection_changed
signal wisp_assigned(wisp_id: int, node_id: String, result: String)
signal wisp_assign_failed(reason: String, node_id: String)
signal wisp_unassigned(wisp_id: int)
signal wisp_pulsed(resource_id: StringName)
signal echo_flags_changed
signal ancient_expired
signal keeper_harvested(resource_id: StringName, amount: int)
signal lucky_harvest(resource_id: StringName, bonus: int)

const STAGE_ORDER: Array[StringName] = [
	&"sapling", &"young", &"mature", &"elder", &"ancient"
]
const HARVEST_IDS: Array[StringName] = [&"wood", &"stone", &"food"]
## Grow spends Fertilizer + Essence only. green_thumb retargets to fertilizer *craft* cost (not Grow).
const NEED_ORDER: Array[StringName] = [&"essence", &"fertilizer"]
## Assignment target id for the Manatree. Stored as a string in SAVE_VERSION 5 — no schema bump.
## Playtest: multiple wisps may stack on the same target (harvest nodes and Manatree).
const NODE_ID_MANATREE: String = "manatree"

var wood: int = 0
var stone: int = 0
var food: int = 0
var manashards: int = 0
var essence: int = 0

var stage_id: StringName = &"sapling"
var fruit_ready: bool = false
## SYSTEMS v0.3.3: true after Fruit COMMIT (paused shop until Ascend). Design save field.
var fruit_committed: bool = false
## Legacy alias of fruit_committed (kept for existing call sites / SAVE_VERSION 5 payloads).
var fruit_harvested_pending_ascend: bool = false
## True after first-boot welcome was dismissed (once per new save).
var welcome_shown: bool = false
## True once the card has been shown this session. Not saved. Rebuilding the
## clearing (Forge view switch) must not play it again.
var welcome_presented: bool = false
## Echo Chamber v1. Portal after the first Ascend. No mid-fight HP.
var portal_unlocked: bool = false
var portal_fee_paid: bool = false
var echo_01_resolved: bool = false
var echo_01_redeemed: bool = false
## Set when the first Reliquary relic lands in the gear inventory. Not the Forge Key.
var first_relic_crafted: bool = false
## v9 saves from before this gate already had her in the party after Spare alone.
var elaia_legacy_joined: bool = false
var forge_key: bool = false
var echo_01_narrator_heard: bool = false
## Echo 2 (Bramble). Fee, resolution, and the last ending stay through Ascend.
var echo_02_fee_paid: bool = false
var echo_02_resolved: bool = false
## "" | spare | defeat | flee | ko. Spare and defeat open the east road.
var echo_02_outcome: String = ""
## Lifetime reach room wins before spared Bramble appears in the clearing (companion gate).
const BRAMBLE_JOIN_CLEARS: int = 30
var echo_02_narrator_heard: bool = false
## Expedition board lantern. dark | amber | cyan. Amber is a run out, cyan is done.
var expedition_lantern: String = "dark"
## Hybrid bows: "physical" or "magical". Optional on old saves — missing means physical.
var arrow_mode: String = "physical"
## True after the Ancient timer hits 0. The Fruit stays committed and the clearing holds still.
var ancient_frozen: bool = false
## Set on the first successful Forge entry. Old saves infer it in the v10 migrate.
var forge_visited: bool = false
## True while apply_save_dict is writing state. Milestone cues stay silent.
var applying_save: bool = false
var _frozen_deny_msec: int = -100000000

## Session play speed. 1, 2, 4, or 8. Launch resets it. It is not a save field.
const PLAY_SPEEDS: Array[int] = [1, 2, 4, 8]
var play_speed: int = 1
## Accumulated unpaused sim time (freezes while SceneTree.paused).
var run_time_sec: float = 0.0
## Shuffle bag for Manatree whispers (string keys). Saved with the run.
var tree_whisper_bag: Array = []
## Next whisper when run_time_sec reaches this value.
var tree_whisper_next_at: float = TreeWhispers.INTERVAL_SEC
## Fractional harvest remainders, one float per resource (wood/stone/food/manashards).
var harvest_accum: Dictionary = {}
## Counts down only while Ancient, the game is open, and the tree is unpaused.
var ancient_remaining_sec: float = 0.0
## Wall-clock seconds already priced on the offline curve. A short reopen continues from here.
var offline_closed_sec: float = 0.0
## Unpaused seconds since the last load. The curve restarts after offline_reset_active_sec.
var active_since_load_sec: float = 0.0
var _idle_tuning: Dictionary = {}
var _idle_tuning_loaded: bool = false

var ascensions: int = 0
var lifetime_waters: int = 0
var lifetime_shards_from_water: int = 0
var lifetime_essence_from_water: int = 0
var lifetime_fruit_harvested: int = 0
var lifetime_harvested: Dictionary = {}
var upgrade_ranks: Dictionary = {}
## Ascension shop UI (per save). Both default on.
var shop_hide_locked: bool = true
var shop_hide_maxed: bool = true
## Spoiler confirm when turning Hide locked off (first 3 times per save).
var shop_spoiler_shown_count: int = 0
var first_wisp_gained: bool = false
var first_tool_crafted: bool = false
var first_pack_lost: bool = false
var first_minigame_played: bool = false

## node_id is harvest_tree/stone/berry or NODE_ID_MANATREE ("manatree"). String stays
## SAVE_VERSION 5 compatible — no schema bump for the new Manatree target type.
## Stacking allowed: any number of wisps may share one harvest node or the Manatree
## (WISP_PER_NODE / WISP_PER_MANATREE = 0 → unlimited). Each assigned wisp pulses independently.
var wisp_count: int = 0
var wisp_assignments: Dictionary = {}
var wisp_pulse_accum: Dictionary = {}
## Real-calendar morning gift (YYYY-MM-DD at MORNING_GIFT_RESET_HOUR local). Not cleared on Ascend.
var last_gift_day: String = ""
## Wisp id string → first-assigned harvest node id. Cleared on Ascend.
var wisp_favourites: Dictionary = {}
## Headless/tests only. When non-empty, morning_gift_day_key() returns this value.
var _morning_gift_day_override: String = ""
## Runtime selection (RTS: LMB select unit; mutually exclusive Keeper XOR one Wisp).
## Wisp select does not require Keeper selected.
var keeper_selected: bool = false
var selected_wisp_id: int = -1
## Drag-box set. A single click still replaces this with one id.
var selected_wisp_ids: Array[int] = []
## "elaia" when her portrait or sprite is selected. The marquee never sets this:
## box-select is Wisps plus the Keeper. Click her sprite or HUD portrait to select her.
var selected_companion_id: String = ""
## One-time Clearing dialogue. Migrated saves that already had her set this true.
var elaia_join_seen: bool = false
## Persisted body. Only the instance whose home matches elaia_area simulates.
var elaia_area: String = "clearing"
var elaia_pos: Vector2 = Vector2.ZERO
var elaia_has_pos: bool = false
var elaia_facing: String = "south"
## Shown once in the Forge when the first Relic finishes and she is waiting outside.
var elaia_footsteps_seen: bool = false
## The Keeper's scene, same idea as elaia_area. The view switch does not change it.
var keeper_area: String = "clearing"
var keeper_pos: Vector2 = Vector2.ZERO
var keeper_has_pos: bool = false
var keeper_facing: String = "south"
## Set by a portrait double-click so the destination scene centres the camera.
var pending_focus_actor: String = ""
## Fractional essence from her 0.8 watering gift so the integer grant does not drop to 0.
var elaia_water_essence_frac: float = 0.0
var _hero_water_accum: Dictionary = {}
var _companions: Dictionary = {}

var stages_data: Array = []
var upgrades_data: Array = []
var params: Dictionary = {}
## Bench rest buff (wall clock, not saved). Cleared on Ascend.
var _sit_started_ms: int = -1
var rested_until_ms: int = 0
var _rested_sit_granted: bool = false


func _ready() -> void:
	# Autoloads inherit root ALWAYS — force pausable so pause freezes run_time / logic.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	reset_play_speed()
	_load_tables()
	_ensure_upgrade_keys()
	_ensure_harvest_keys()
	_ensure_wisp_slots()
	_ensure_character_sheet_action()
	if has_node("/root/Backpack") and not Backpack.inventory_changed.is_connected(_on_backpack_changed):
		Backpack.inventory_changed.connect(_on_backpack_changed)
	if not stage_changed.is_connected(_on_tree_whisper_stage_changed):
		stage_changed.connect(_on_tree_whisper_stage_changed)


func _ensure_character_sheet_action() -> void:
	## SYSTEMS v0.5.0: InputMap action character_sheet on C.
	if not InputMap.has_action("character_sheet"):
		InputMap.add_action("character_sheet", 0.5)
	var already: bool = false
	for ev: InputEvent in InputMap.action_get_events("character_sheet"):
		if ev is InputEventKey and (ev as InputEventKey).keycode == KEY_C:
			already = true
			break
	if already:
		return
	var key := InputEventKey.new()
	key.keycode = KEY_C
	InputMap.action_add_event("character_sheet", key)


func _process(delta: float) -> void:
	## Pausable by default — stops when get_tree().paused (pause menu).
	## A frozen Ancient does not bank run time, so staring at Ascend does not reset the offline curve.
	advance_open_play(delta)


func reset_play_speed() -> void:
	play_speed = 1


func set_play_speed(step: int) -> void:
	play_speed = step if PLAY_SPEEDS.has(step) else 1


func cycle_play_speed() -> int:
	var idx: int = PLAY_SPEEDS.find(play_speed)
	if idx < 0:
		play_speed = 1
		return play_speed
	play_speed = PLAY_SPEEDS[(idx + 1) % PLAY_SPEEDS.size()]
	return play_speed


func play_speed_scale() -> float:
	if not PLAY_SPEEDS.has(play_speed):
		return 1.0
	return float(play_speed)


func play_speed_in_stable() -> bool:
	## The control lives on the HUD, which the Stable export keeps.
	return true


func active_play_delta(delta: float) -> float:
	## Live session only. Offline grants and idle catch-up pass raw seconds instead.
	if delta <= 0.0:
		return 0.0
	if not _play_session_open():
		return delta
	return delta * play_speed_scale()


func _play_session_open() -> bool:
	return has_node("/root/SaveService") and SaveService.session_active


func advance_open_play(delta: float) -> void:
	if ancient_frozen:
		return
	var play_delta: float = active_play_delta(delta)
	run_time_sec += play_delta
	## The idle-curve reset stays on the wall clock, whatever the speed button says.
	active_since_load_sec += delta
	tick_ancient(play_delta)
	apply_wisp_pulses(play_delta)
	_tick_tree_whispers()
	_tick_rested_sit_timer()


func _tick_rested_sit_timer() -> void:
	if _sit_started_ms < 0 or _rested_sit_granted:
		return
	var sit_sec: float = param_float("RESTED_SIT_SEC", 20.0)
	if float(Time.get_ticks_msec() - _sit_started_ms) >= sit_sec * 1000.0:
		_grant_rested_hands_buff()


func on_keeper_bench_sat() -> void:
	_sit_started_ms = Time.get_ticks_msec()
	_rested_sit_granted = false
	status_message.emit(ContentStrings.random_bench_saying())


func on_keeper_bench_stood() -> void:
	if _sit_started_ms >= 0 and not _rested_sit_granted:
		var sit_sec: float = param_float("RESTED_SIT_SEC", 20.0)
		if float(Time.get_ticks_msec() - _sit_started_ms) >= sit_sec * 1000.0:
			_grant_rested_hands_buff()
	_sit_started_ms = -1


func _grant_rested_hands_buff() -> void:
	var duration_sec: float = param_float("RESTED_DURATION_SEC", 120.0)
	rested_until_ms = Time.get_ticks_msec() + int(duration_sec * 1000.0)
	_rested_sit_granted = true


func keeper_rested_mult() -> float:
	if Time.get_ticks_msec() < rested_until_ms:
		return param_float("RESTED_GATHER_MULT", 1.15)
	return 1.0


func _clear_rested_hands_buff() -> void:
	_sit_started_ms = -1
	rested_until_ms = 0
	_rested_sit_granted = false


## Headless verify: backdate an active bench sit without waiting on wall clock.
func debug_backdate_bench_sit_sec(elapsed_sec: float) -> void:
	if _sit_started_ms < 0:
		return
	_sit_started_ms = Time.get_ticks_msec() - int(elapsed_sec * 1000.0)


func clear_rested_hands_bench_buff() -> void:
	_clear_rested_hands_buff()


func debug_complete_bench_sit_sec(elapsed_sec: float) -> void:
	on_keeper_bench_sat()
	_sit_started_ms = Time.get_ticks_msec() - int(elapsed_sec * 1000.0)
	var sit_sec: float = param_float("RESTED_SIT_SEC", 20.0)
	if elapsed_sec + 0.001 >= sit_sec and not _rested_sit_granted:
		_grant_rested_hands_buff()
	on_keeper_bench_stood()


func idle_catch_up_seconds(gap_sec: float) -> float:
	## Same 1× curve as a closed game. Play speed is not a factor.
	return offline_effective_seconds(gap_sec)


func _reset_tree_whispers() -> void:
	tree_whisper_bag.clear()
	tree_whisper_next_at = TreeWhispers.INTERVAL_SEC


func _on_tree_whisper_stage_changed(_stage_id: StringName) -> void:
	TreeWhispers.prune_bag(tree_whisper_bag, stage_id)


func _tick_tree_whispers() -> void:
	if applying_save:
		return
	if not _play_session_open():
		return
	if run_time_sec + 0.0001 < tree_whisper_next_at:
		return
	while tree_whisper_next_at <= run_time_sec:
		tree_whisper_next_at += TreeWhispers.INTERVAL_SEC
	_emit_tree_whisper()


func _emit_tree_whisper() -> void:
	var key: String = TreeWhispers.draw_key(tree_whisper_bag, stage_id)
	if key == "":
		return
	status_message.emit(ContentStrings.get_text(key))


func _load_tables() -> void:
	var file := FileAccess.open("res://data/manatree_stages.json", FileAccess.READ)
	if file == null:
		push_error("GameState: cannot open manatree_stages.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	params = root.get("params", {}) as Dictionary
	var stages: Variant = root.get("stages", [])
	stages_data = stages if typeof(stages) == TYPE_ARRAY else []
	var uf := FileAccess.open("res://data/fruit_upgrades.json", FileAccess.READ)
	if uf == null:
		return
	var up: Variant = JSON.parse_string(uf.get_as_text())
	uf.close()
	if typeof(up) == TYPE_DICTIONARY:
		var uroot: Dictionary = up
		var arr: Variant = uroot.get("upgrades", [])
		upgrades_data = arr if typeof(arr) == TYPE_ARRAY else []
	_load_companions()


func _load_companions() -> void:
	var file := FileAccess.open("res://data/companions.json", FileAccess.READ)
	if file == null:
		push_error("GameState: cannot open companions.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_companions = parsed


func _companion_row(actor: String) -> Dictionary:
	var found: Variant = _companions.get(actor, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func actor_walk_ref_speed(actor: String) -> float:
	var fallback: float = 88.0 if actor == "elaia" else 80.0
	return float(_companion_row(actor).get("walk_ref_speed", fallback))


func actor_move_mult(actor: String) -> float:
	return float(_companion_row(actor).get("move_speed_mult", 1.0))


func actor_work_rate(actor: String, station_id: String = "") -> float:
	## Reliquary replaces the shared work rate. It is not stacked on top of it.
	var row: Dictionary = _companion_row(actor)
	if station_id == "reliquary":
		return float(row.get("reliquary_work_rate", row.get("work_rate", 1.0)))
	return float(row.get("work_rate", 1.0))


func actor_craft_rate(actor: String) -> float:
	## Crafting uses the shared work rate until a companion carries its own craft_rate.
	var row: Dictionary = _companion_row(actor)
	if row.has("craft_rate"):
		return float(row.get("craft_rate", 1.0))
	return float(row.get("work_rate", 1.0))


func actor_brew_rate(actor: String) -> float:
	return float(_companion_row(actor).get("brew_rate", 1.0))


func actor_water_mult(actor: String) -> float:
	return float(_companion_row(actor).get("water_reward_mult", 1.0))


func actor_portrait_texture(actor: String) -> Texture2D:
	## HUD portrait. Path and optional region live in companions.json.
	var row: Dictionary = _companion_row(actor)
	var path: String = str(row.get("portrait_path", ""))
	if path == "" or not ResourceLoader.exists(path):
		path = CharacterSheet.ELAIA_PARTY_PORTRAIT_PATH if actor == "elaia" else CharacterSheet.KEEPER_PARTY_PORTRAIT_PATH
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var region_v: Variant = row.get("portrait_region", null)
	if typeof(region_v) != TYPE_ARRAY or (region_v as Array).size() < 4:
		return tex
	var reg: Array = region_v
	var rect := Rect2i(int(reg[0]), int(reg[1]), int(reg[2]), int(reg[3]))
	var img: Image = tex.get_image()
	if img == null:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(rect)
		return atlas
	return ImageTexture.create_from_image(img.get_region(rect))


func hero_display_name(actor: String) -> String:
	## Display name from companions.json. "The Keeper" only when that string is missing.
	var row: Dictionary = _companion_row(actor)
	var key: String = str(row.get("display_name_key", ""))
	var fallback: String = "The Keeper" if actor == "keeper" else "Elaia"
	if key == "":
		return fallback
	var text: String = ContentStrings.get_text(key)
	if text == "" or text == key:
		return fallback
	return text


func elaia_join_pending() -> bool:
	if not elaia_in_party() or elaia_join_seen:
		return false
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return false
	return true


func member_away(member: String) -> bool:
	if not has_node("/root/Reach"):
		return false
	return Reach.member_away(member)


func _wisp_job_scene(node_id: String) -> String:
	if has_node("/root/ForgeJobs") and ForgeJobs.is_craft_spot(node_id):
		return "forge"
	return "clearing"


func selected_hero_id() -> String:
	## Elaia and the Keeper are exclusive. Wisps are not heroes.
	if selected_companion_id == "elaia" and elaia_portrait_visible() and not member_away("elaia"):
		return "elaia"
	if keeper_selected and not member_away("keeper"):
		return "keeper"
	return ""


func find_selected_hero() -> Node:
	var hero_id: String = selected_hero_id()
	var tree: SceneTree = get_tree()
	if hero_id == "" or tree == null:
		return null
	if hero_id == "elaia":
		return tree.get_first_node_in_group("elaia")
	return tree.get_first_node_in_group("keeper")


func command_selected_hero(target: Node2D, type_id: String, claim_key: String = "") -> void:
	var hero: Node = find_selected_hero()
	if hero != null and hero.has_method("command_work"):
		hero.call("command_work", target, type_id, claim_key)


func tick_hero_water(actor: String, delta: float) -> void:
	## Same pulse as the Keeper's channel, used when her body is not in the current view.
	if fruit_committed or ancient_frozen or delta <= 0.0:
		return
	var acc: float = float(_hero_water_accum.get(actor, 0.0)) + delta
	var pulse: float = get_water_essence_pulse_sec()
	if pulse <= 0.0:
		_hero_water_accum[actor] = acc
		return
	while acc >= pulse:
		acc -= pulse
		var gained: Dictionary = apply_water_pulse(true, true, actor_water_mult(actor))
		if bool(gained.get("ok", false)):
			status_message.emit(ContentStrings.get_text("tree_water_pulse_hud", {
				"shards": int(gained.get("shards", 0)),
				"essence": int(gained.get("essence", 0)),
			}))
	_hero_water_accum[actor] = acc


func _ensure_upgrade_keys() -> void:
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var uid: String = str(d.get("id", ""))
		if uid != "" and not upgrade_ranks.has(uid):
			upgrade_ranks[uid] = 0


func _ensure_harvest_keys() -> void:
	for rid: StringName in HARVEST_IDS:
		var key: String = String(rid)
		if not lifetime_harvested.has(key):
			lifetime_harvested[key] = 0


func param_int(key: String, default_v: int = 0) -> int:
	return int(params.get(key, default_v))


func param_float(key: String, default_v: float = 0.0) -> float:
	return float(params.get(key, default_v))



func get_wisp_pulse_sec() -> float:
	## Wisp pulse interval. Swift Wisps: ×(1 − 0.08×rank), 10 s floor.
	var base_s: float = param_float("WISP_PULSE_SEC", 20.0)
	var haste: int = get_upgrade_rank("wisp_haste")
	var mult: float = 1.0 - float(get_upgrade_def("wisp_haste").get("value_per_rank", 0.08)) * float(haste)
	var min_s: float = param_float("WISP_HARVEST_MIN_SEC", 10.0)
	return maxf(min_s, base_s * maxf(0.0, mult))


func get_wisp_capacity() -> int:
	return param_int("WISP_FROM_STAGES_MAX", 4) + get_upgrade_rank("bonus_wisp")


func get_wisp_assignment(wisp_id: int) -> String:
	return str(wisp_assignments.get(str(wisp_id), ""))


func wisp_free_count() -> int:
	var free: int = 0
	for wid: int in range(wisp_count):
		if get_wisp_assignment(wid) == "":
			free += 1
	return free


func node_id_for_resource(resource_id: StringName) -> String:
	match resource_id:
		&"wood":
			return "harvest_tree"
		&"stone":
			return "harvest_stone"
		&"food":
			return "harvest_berry"
		&"manashards":
			return NODE_ID_MANATREE
		_:
			return ""


func resource_for_node_id(node_id: String) -> StringName:
	match node_id:
		"harvest_tree":
			return &"wood"
		"harvest_stone":
			return &"stone"
		"harvest_berry":
			return &"food"
		"manatree":
			return &"manashards"
		_:
			return &""


func assignment_target_display(node_id: String) -> String:
	match node_id:
		"harvest_tree":
			return ContentStrings.get_text("node_wood_prompt")
		"harvest_stone":
			return ContentStrings.get_text("node_stone_prompt")
		"harvest_berry":
			return ContentStrings.get_text("node_food_prompt")
		NODE_ID_MANATREE:
			return ContentStrings.get_text("tree_menu_title")
		_:
			if node_id == "workbench":
				return ContentStrings.get_text("bench_title")
			if has_node("/root/ForgeJobs") and ForgeJobs.is_forge_station(node_id):
				return ForgeJobs.station_display(node_id)
			return node_id


func is_valid_wisp_node_id(node_id: String) -> bool:
	if resource_for_node_id(node_id) != &"":
		return true
	return has_node("/root/ForgeJobs") and ForgeJobs.is_craft_spot(node_id)


func _ensure_wisp_slots() -> void:
	for i: int in range(wisp_count):
		var key: String = str(i)
		if not wisp_assignments.has(key):
			wisp_assignments[key] = ""
		if not wisp_pulse_accum.has(key):
			wisp_pulse_accum[key] = 0.0
	var keys: Array = wisp_assignments.keys()
	for k: Variant in keys:
		var ks: String = str(k)
		if int(ks) >= wisp_count:
			wisp_assignments.erase(ks)
			wisp_pulse_accum.erase(ks)
			wisp_favourites.erase(ks)


func grant_wisp_from_stage() -> void:
	## +1 per successful Grow (Young→Ancient); capacity = 4 + bonus_wisp.
	if wisp_count >= get_wisp_capacity():
		return
	wisp_count += 1
	first_wisp_gained = true
	_ensure_wisp_slots()
	wisps_changed.emit()
	status_message.emit(ContentStrings.get_text("wisp_gained"))


func count_wisps_on_node(node_id: String) -> int:
	var n: int = 0
	for k: Variant in wisp_assignments.keys():
		if str(wisp_assignments[k]) == node_id:
			n += 1
	return n


func wisp_slot_index_on_node(wisp_id: int, node_id: String) -> int:
	## Stable 0-based index among wisps assigned to node_id (by wisp id order).
	var ids: Array[int] = []
	for k: Variant in wisp_assignments.keys():
		if str(wisp_assignments[k]) == node_id:
			ids.append(int(str(k)))
	ids.sort()
	var idx: int = ids.find(wisp_id)
	return idx if idx >= 0 else 0


func try_assign_wisp(wisp_id: int, node_id: String) -> String:
	## Returns "ok" | "reassign" | "invalid". Stacking allowed (no slot-full busy deny).
	if fruit_committed:
		wisp_assign_failed.emit("invalid", node_id)
		return "invalid"
	if wisp_id < 0 or wisp_id >= wisp_count:
		wisp_assign_failed.emit("invalid", node_id)
		return "invalid"
	if not is_valid_wisp_node_id(node_id):
		wisp_assign_failed.emit("invalid", node_id)
		return "invalid"
	var key: String = str(wisp_id)
	var prev: String = str(wisp_assignments.get(key, ""))
	if has_node("/root/ForgeJobs") and ForgeJobs.is_craft_spot(node_id) and prev != node_id:
		if count_wisps_on_node(node_id) >= ForgeJobs.wisp_cap_for(node_id):
			wisp_assign_failed.emit("full", node_id)
			if has_node("/root/GameAudio"):
				GameAudio.play(&"sfx_wisp_deny")
			return "full"
	if prev == node_id:
		_forget_selected_wisp(wisp_id)
		selection_changed.emit()
		return "ok"
	if member_away("keeper") and prev != "":
		var prev_scene: String = _wisp_job_scene(prev)
		var next_scene: String = _wisp_job_scene(node_id)
		if prev_scene != next_scene:
			wisp_assign_failed.emit("cross_scene", node_id)
			status_message.emit(ContentStrings.get_text("wisp_cross_scene_away"))
			return "cross_scene"
	var joining: bool = count_wisps_on_node(node_id) > 0
	var first_assign: bool = prev == ""
	wisp_assignments[key] = node_id
	wisp_pulse_accum[key] = 0.0
	if first_assign and resource_for_node_id(node_id) != &"":
		if not wisp_favourites.has(key):
			wisp_favourites[key] = node_id
			var toast_key: String = "wisp_favourite_toast_%d" % randi_range(1, 3)
			status_message.emit(
				ContentStrings.get_text(toast_key, {"node": assignment_target_display(node_id)})
			)
	_forget_selected_wisp(wisp_id)
	wisps_changed.emit()
	selection_changed.emit()
	var result: String
	if joining:
		result = "join"
	elif prev != "":
		result = "reassign"
	else:
		result = "ok"
	wisp_assigned.emit(wisp_id, node_id, result)
	return result


func toast_wisp_assign(result: String, node_id: String) -> void:
	match result:
		"ok":
			if node_id == NODE_ID_MANATREE:
				status_message.emit(ContentStrings.get_text("wisp_assign_manatree_ok"))
			else:
				status_message.emit(ContentStrings.get_text("wisp_assign_ok"))
		"join":
			status_message.emit(ContentStrings.get_text("wisp_assign_join_ok"))
		"reassign":
			status_message.emit(ContentStrings.get_text("wisp_reassign_ok"))
		_:
			pass


func unassign_wisp(wisp_id: int) -> bool:
	if fruit_committed:
		return false
	if wisp_id < 0 or wisp_id >= wisp_count:
		return false
	var key: String = str(wisp_id)
	if str(wisp_assignments.get(key, "")) == "":
		return false
	wisp_assignments[key] = ""
	wisp_pulse_accum[key] = 0.0
	wisps_changed.emit()
	wisp_unassigned.emit(wisp_id)
	return true


func apply_wisp_pulses(delta: float) -> void:
	## Continuous gather into the shared per-source accumulator. Stage + Forager apply while active.
	## Forge-station wisps do not gather. One pulse signal per node that banks a whole unit.
	if fruit_committed or delta <= 0.0:
		return
	var pulsed_nodes: Dictionary = {}
	for i: int in range(wisp_count):
		var key: String = str(i)
		var nid: String = str(wisp_assignments.get(key, ""))
		if nid == "":
			continue
		if has_node("/root/ForgeJobs") and ForgeJobs.is_forge_station(nid):
			continue
		var rid: StringName = resource_for_node_id(nid)
		if rid == &"":
			continue
		var fav_mult: float = 1.0
		if str(wisp_favourites.get(key, "")) == nid:
			fav_mult = param_float("WISP_FAVOURITE_RATE_MULT", 1.2)
		if accumulate_wisp_harvest(rid, delta * fav_mult) > 0:
			pulsed_nodes[nid] = rid
	for nid2: Variant in pulsed_nodes.keys():
		wisp_pulsed.emit(pulsed_nodes[nid2] as StringName)


func set_keeper_selected(value: bool) -> void:
	if value:
		select_keeper()
		return
	if not keeper_selected:
		return
	keeper_selected = false
	selection_changed.emit()


func select_keeper() -> void:
	## LMB on Keeper: select Keeper, deselect any Wisp.
	if member_away("keeper"):
		status_message.emit(ContentStrings.get_text("keeper_away_select"))
		return
	if keeper_selected and selected_wisp_id < 0 and selected_wisp_ids.is_empty() and selected_companion_id == "":
		return
	keeper_selected = true
	selected_wisp_id = -1
	selected_wisp_ids.clear()
	selected_companion_id = ""
	selection_changed.emit()


func toggle_keeper_selected() -> void:
	if keeper_selected:
		set_keeper_selected(false)
	else:
		select_keeper()


func select_wisp(wisp_id: int) -> void:
	## LMB on Wisp: select that wisp (does NOT require Keeper). Deselects Keeper.
	if wisp_id < 0 or wisp_id >= wisp_count:
		return
	if selected_wisp_id == wisp_id and not keeper_selected and selected_wisp_ids.size() <= 1 and selected_companion_id == "":
		return
	keeper_selected = false
	selected_companion_id = ""
	selected_wisp_id = wisp_id
	selected_wisp_ids.clear()
	selected_wisp_ids.append(wisp_id)
	selection_changed.emit()


func elaia_in_party() -> bool:
	## Spare is the story beat. Her body waits after the first Reliquary relic,
	## unless this save already had her from before that gate.
	return echo_01_redeemed and (first_relic_crafted or elaia_legacy_joined)


func elaia_portrait_visible() -> bool:
	## Portrait, selection and companion status wait until the Clearing dialogue.
	return elaia_in_party() and elaia_join_seen


func elaia_body_visible() -> bool:
	## Her sprite waits until the player has gone to look in the Clearing.
	if not elaia_in_party():
		return false
	if elaia_join_seen:
		return true
	return elaia_footsteps_seen


func elaia_footsteps_pending() -> bool:
	return echo_01_redeemed and first_relic_crafted and not elaia_join_seen and not elaia_footsteps_seen


func note_first_relic_crafted() -> void:
	if first_relic_crafted:
		return
	first_relic_crafted = true
	if echo_01_redeemed and not elaia_join_seen:
		elaia_footsteps_seen = false
	echo_flags_changed.emit()
	call_deferred("_prompt_elaia_footsteps_if_ready")


func _prompt_elaia_footsteps_if_ready() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node: Node in tree.get_nodes_in_group("game_hud"):
		if node.has_method("maybe_show_elaia_footsteps"):
			node.call("maybe_show_elaia_footsteps")
			return


func begin_elaia_join_clearing() -> void:
	## Called when the player leaves the Forge to meet Elaia at the Manatree.
	if not has_node("/root/ForgeJobs"):
		return
	keeper_area = "clearing"
	keeper_has_pos = true
	keeper_pos = ForgeJobs.clearing_door_stand()
	keeper_facing = "east"
	elaia_area = "clearing"
	elaia_has_pos = true
	elaia_pos = ForgeJobs.elaia_join_stand()
	elaia_facing = "west"
	echo_flags_changed.emit()


func select_companion(companion_id: String) -> void:
	## Portrait or sprite click. Refused until the join dialogue has played.
	if companion_id != "elaia" or not elaia_portrait_visible():
		return
	if member_away("elaia"):
		status_message.emit(ContentStrings.get_text("member_away_select", {
			"name": ContentStrings.get_text("echo_elaia_name"),
		}))
		return
	if selected_companion_id == companion_id and not keeper_selected and selected_wisp_ids.is_empty() and selected_wisp_id < 0:
		return
	keeper_selected = false
	selected_wisp_id = -1
	selected_wisp_ids.clear()
	selected_companion_id = companion_id
	selection_changed.emit()


func select_group(wisp_ids: Array, include_keeper: bool) -> void:
	## Drag box. Wisps, and the Keeper when his sprite is inside the box.
	## Elaia is not part of the marquee; a box-select clears her selection.
	if member_away("keeper"):
		include_keeper = false
	selected_companion_id = ""
	selected_wisp_ids.clear()
	for raw: Variant in wisp_ids:
		var id: int = int(raw)
		if id < 0 or id >= wisp_count:
			continue
		if not selected_wisp_ids.has(id):
			selected_wisp_ids.append(id)
	selected_wisp_ids.sort()
	selected_wisp_id = selected_wisp_ids[0] if not selected_wisp_ids.is_empty() else -1
	keeper_selected = include_keeper
	selection_changed.emit()


func is_wisp_selected(wisp_id: int) -> bool:
	if selected_wisp_ids.has(wisp_id):
		return true
	return selected_wisp_ids.is_empty() and selected_wisp_id == wisp_id


func selected_wisp_list() -> Array[int]:
	var out: Array[int] = []
	if not selected_wisp_ids.is_empty():
		for id: int in selected_wisp_ids:
			if id >= 0 and id < wisp_count:
				out.append(id)
		return out
	if selected_wisp_id >= 0 and selected_wisp_id < wisp_count:
		out.append(selected_wisp_id)
	return out


func command_selected_wisps(node_id: String) -> String:
	var ids: Array[int] = selected_wisp_list()
	if ids.is_empty():
		return ""
	var last: String = "ok"
	var assigned: int = 0
	for id: int in ids:
		last = try_assign_wisp(id, node_id)
		if last == "full" or last == "invalid":
			if assigned == 0:
				return last
			break
		assigned += 1
	return last


func clear_wisp_selection() -> void:
	if selected_wisp_id < 0 and selected_wisp_ids.is_empty():
		return
	selected_wisp_id = -1
	selected_wisp_ids.clear()
	selection_changed.emit()


func clear_selection() -> bool:
	var had: bool = keeper_selected or selected_wisp_id >= 0 or not selected_wisp_ids.is_empty() or selected_companion_id != ""
	keeper_selected = false
	selected_wisp_id = -1
	selected_wisp_ids.clear()
	selected_companion_id = ""
	if had:
		selection_changed.emit()
	return had


func _forget_selected_wisp(wisp_id: int) -> void:
	selected_wisp_ids.erase(wisp_id)
	if selected_wisp_id == wisp_id:
		selected_wisp_id = selected_wisp_ids[0] if not selected_wisp_ids.is_empty() else -1


func get_resource(resource_id: StringName) -> int:
	match resource_id:
		&"wood":
			return wood
		&"stone":
			return stone
		&"food":
			return food
		&"manashards":
			return manashards
		&"essence":
			return essence
		_:
			return 0


func bramble_joined() -> bool:
	if echo_02_outcome != "spare":
		return false
	if not has_node("/root/Reach"):
		return false
	return Reach.reaches_cleared >= BRAMBLE_JOIN_CLEARS


func set_resource(resource_id: StringName, amount: int) -> void:
	amount = maxi(amount, 0)
	match resource_id:
		&"wood":
			wood = amount
		&"stone":
			stone = amount
		&"food":
			food = amount
		&"manashards":
			manashards = amount
		&"essence":
			essence = amount
		_:
			return
	resources_changed.emit(resource_id, amount)
	needs_changed.emit()


func add_resource(resource_id: StringName, delta: int) -> void:
	set_resource(resource_id, get_resource(resource_id) + delta)


func get_stage_index(id: StringName = stage_id) -> int:
	return STAGE_ORDER.find(id)


func get_stage_def(id: StringName = stage_id) -> Dictionary:
	for entry: Variant in stages_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		if str(d.get("id", "")) == String(id):
			return d
	return {}


func get_next_stage_id() -> StringName:
	var idx: int = get_stage_index()
	if idx < 0 or idx >= STAGE_ORDER.size() - 1:
		return &""
	return STAGE_ORDER[idx + 1]


func get_upgrade_rank(upgrade_id: String) -> int:
	return int(upgrade_ranks.get(upgrade_id, 0))


func total_upgrade_ranks_owned() -> int:
	## Each bought rank counts. A stale key that is not in the blessing list does not.
	var n: int = 0
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		n += maxi(0, get_upgrade_rank(str((entry as Dictionary).get("id", ""))))
	return n


func offline_shard_mult() -> float:
	## Offline Manashards only. Derived from ranks. Not stored.
	return minf(1.0, 0.25 + 0.05 * float(total_upgrade_ranks_owned()))


func get_upgrade_def(upgrade_id: String) -> Dictionary:
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		if str(d.get("id", "")) == upgrade_id:
			return d
	return {}


func upgrade_art_path(upgrade_id: String) -> String:
	## Same lookup as Equipment.item_art_path (assets_extra/ascension/ first for blessings).
	var art_name: String = str(get_upgrade_def(upgrade_id).get("art_name", ""))
	if art_name == "":
		return ""
	for extra_dir: String in [AssetsExtra.ROOT + "ascension/", AssetsExtra.SHARED]:
		var extra: String = "%s%s.png" % [extra_dir, art_name]
		if ResourceLoader.exists(extra):
			return extra
	var direct: String = "res://assets/art/ui/%s.png" % art_name
	if ResourceLoader.exists(direct):
		return direct
	var nested: String = "res://assets/art/ui/icons/%s.png" % art_name
	if ResourceLoader.exists(nested):
		return nested
	return ""


func get_effect_total(effect_name: String) -> float:
	var total: float = 0.0
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		if str(d.get("effect", "")) != effect_name:
			continue
		var uid: String = str(d.get("id", ""))
		total += float(d.get("value_per_rank", 0)) * float(get_upgrade_rank(uid))
	return total


func get_water_essence_amount() -> int:
	## Base + Deep Roots (+1 Essence per rank, capped at blessing max).
	var base_amt: int = param_int("WATER_ESSENCE_PER_SEC", 1)
	var roots: int = mini(get_upgrade_rank("deep_roots"), upgrade_max_rank("deep_roots"))
	return base_amt + roots


func get_stage_gather_mult() -> float:
	var def: Dictionary = get_stage_def()
	return float(def.get("gather_mult", 1.0))


func active_harvest_factor() -> float:
	## Active harvest only: stage multiplier plus Forager. Watering does not use this.
	return get_stage_gather_mult() + get_effect_total("gather_mult_bonus")


func offline_harvest_factor() -> float:
	## Offline harvest drops the stage multiplier. Forager still adds.
	return 1.0 + get_effect_total("gather_mult_bonus")


func get_global_gather_mult() -> float:
	## Fate and the other combat stats do not modify gather.
	return active_harvest_factor()


func get_move_speed() -> float:
	var base_s: float = param_float("BASE_MOVE_SPEED", 180.0)
	var mult: float = 1.0 + get_effect_total("move_speed_mult")
	return base_s * mult


func get_channel_pulse_sec() -> float:
	return param_float("CHANNEL_PULSE_SEC", 1.0)


func _tool_speed_divisor() -> float:
	## 2× Keeper channel speed → half wait between yields. Yield/pulse unchanged.
	return maxf(1.0, param_float("TOOL_CHANNEL_SPEED_MULT", 2.0))


func get_keeper_harvest_pulse_sec(resource_id: StringName) -> float:
	## Bare hands: one yield per KEEPER_HARVEST_SEC (2s). A matching tool halves that to 1s.
	var base_s: float = param_float("KEEPER_HARVEST_SEC", 2.0)
	if Backpack.owns_tool_for_resource(resource_id):
		return base_s / _tool_speed_divisor()
	return base_s


func get_water_essence_pulse_sec() -> float:
	## Stone Watering Can never speeds Essence — base CHANNEL_PULSE_SEC.
	return get_channel_pulse_sec()


func get_water_shard_pulse_sec() -> float:
	## v0.4.0: can doubles shard_roll, not pulse wait. Both grants share CHANNEL_PULSE_SEC.
	return get_channel_pulse_sec()


func get_water_shard_roll_mult() -> int:
	## Watering Can owned → shard_roll ×2. Essence grant unchanged.
	if Backpack.owns_watering_can():
		return maxi(1, int(round(param_float("WATER_CAN_SHARD_ROLL_MULT", 2.0))))
	return 1


func _on_backpack_changed(_item_id: StringName, _new_amount: int) -> void:
	needs_changed.emit()


func get_need_have(resource_id: StringName) -> int:
	if resource_id == &"fertilizer":
		return Backpack.get_count("fertilizer")
	return get_resource(resource_id)


func spend_need(resource_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	if resource_id == &"fertilizer":
		Backpack.try_spend("fertilizer", amount)
		return
	add_resource(resource_id, -amount)


func get_harvest_range() -> float:
	return param_float("HARVEST_RANGE_PX", 48.0)


func _harvest_base_units(resource_id: StringName) -> float:
	var key: String = "HARVEST_%s_PER_SEC" % String(resource_id).to_upper()
	return float(param_int(key, 1))


func accumulate_harvest(resource_id: StringName, units: float) -> int:
	## Bank whole units and keep the fraction on this source. No per-pulse floor.
	if fruit_committed or units <= 0.0:
		return 0
	if resource_id != &"manashards" and not resource_id in HARVEST_IDS:
		return 0
	var key: String = String(resource_id)
	var acc: float = float(harvest_accum.get(key, 0.0)) + units
	var grant: int = int(floor(acc))
	if grant < 0:
		grant = 0
	harvest_accum[key] = acc - float(grant)
	if grant > 0:
		add_resource(resource_id, grant)
		lifetime_harvested[key] = int(lifetime_harvested.get(key, 0)) + grant
	return grant


func morning_gift_day_key() -> String:
	if _morning_gift_day_override != "":
		return _morning_gift_day_override
	var reset_hour: int = param_int("MORNING_GIFT_RESET_HOUR", 4)
	var tz: Dictionary = Time.get_time_zone_from_system()
	var bias_sec: int = int(tz.get("bias", 0)) * 60
	var shifted: int = int(Time.get_unix_time_from_system()) + bias_sec - reset_hour * 3600
	return Time.get_date_string_from_unix_time(shifted)


func try_morning_gift(resource_id: StringName) -> int:
	if fruit_committed or ancient_frozen:
		return 0
	if not resource_id in HARVEST_IDS:
		return 0
	var day: String = morning_gift_day_key()
	if last_gift_day != "":
		if day == last_gift_day or day < last_gift_day:
			return 0
	var units_base: int = param_int("MORNING_GIFT_UNITS", 10)
	var scale_by_stage: bool = bool(params.get("MORNING_GIFT_SCALE_BY_STAGE", true))
	var stage_mult: int = get_stage_index() + 1 if scale_by_stage else 1
	if stage_mult < 1:
		stage_mult = 1
	var gift: int = units_base * stage_mult
	add_resource(resource_id, gift)
	last_gift_day = day
	var item_key: String = "hud_%s" % String(resource_id)
	status_message.emit(
		ContentStrings.get_text("harvest_pulse_hud", {
			"amount": str(gift),
			"item": ContentStrings.get_text(item_key),
		})
	)
	return gift


func accumulate_keeper_harvest(resource_id: StringName, delta: float, rate: float = 1.0) -> int:
	if fruit_committed or ancient_frozen or delta <= 0.0 or not resource_id in HARVEST_IDS:
		return 0
	var interval: float = maxf(get_keeper_harvest_pulse_sec(resource_id), 0.05)
	var units: float = (delta / interval) * _harvest_base_units(resource_id) * active_harvest_factor() * rate
	var grant: int = accumulate_harvest(resource_id, units)
	if grant > 0:
		keeper_harvested.emit(resource_id, grant)
		_apply_lucky_harvest_bonus(resource_id, grant)
	return grant


func accumulate_wisp_harvest(resource_id: StringName, delta: float) -> int:
	if fruit_committed or delta <= 0.0:
		return 0
	var interval: float = maxf(get_wisp_pulse_sec(), 0.05)
	var grant_per: float = float(param_int("WISP_PULSE_GRANT", 1))
	var units: float = (delta / interval) * grant_per * active_harvest_factor()
	return accumulate_harvest(resource_id, units)


func apply_offline_keeper_harvest(eff_sec: float, resource_id: StringName, rate: float = 1.0) -> int:
	if eff_sec <= 0.0 or not resource_id in HARVEST_IDS:
		return 0
	var interval: float = maxf(get_keeper_harvest_pulse_sec(resource_id), 0.05)
	var units: float = (eff_sec / interval) * _harvest_base_units(resource_id) * offline_harvest_factor() * rate
	return accumulate_harvest(resource_id, units)


func apply_offline_wisp_harvest(eff_sec: float, resource_id: StringName) -> int:
	if eff_sec <= 0.0:
		return 0
	var interval: float = maxf(get_wisp_pulse_sec(), 0.05)
	var grant_per: float = float(param_int("WISP_PULSE_GRANT", 1))
	var units: float = (eff_sec / interval) * grant_per * offline_harvest_factor()
	if resource_id == &"manashards":
		units *= offline_shard_mult()
	return accumulate_harvest(resource_id, units)


## One base yield at the active factor, remainder kept. Not a one-second pulse.
func apply_harvest_pulse(resource_id: StringName, rate: float = 1.0) -> int:
	if not resource_id in HARVEST_IDS:
		return 0
	var grant: int = accumulate_harvest(resource_id, _harvest_base_units(resource_id) * active_harvest_factor() * rate)
	if grant > 0:
		_apply_lucky_harvest_bonus(resource_id, grant)
	return grant


func _apply_lucky_harvest_bonus(resource_id: StringName, grant: int) -> void:
	if grant <= 0:
		return
	var chance: float = param_float("LUCKY_HARVEST_CHANCE", 0.0)
	if chance <= 0.0:
		return
	if randf() >= chance:
		return
	var mult: int = param_int("LUCKY_HARVEST_MULT", 2)
	var bonus: int = grant * (mult - 1)
	if bonus <= 0:
		return
	add_resource(resource_id, bonus)
	var key: String = String(resource_id)
	lifetime_harvested[key] = int(lifetime_harvested.get(key, 0)) + bonus
	lucky_harvest.emit(resource_id, bonus)


func get_harvest_grant(resource_id: StringName) -> int:
	return apply_harvest_pulse(resource_id)


func get_gather_grant(resource_id: StringName) -> int:
	return apply_harvest_pulse(resource_id)


## Water channel pulse: manashards U{1,3}×can + shard_sight, essence income only (no growth).
## At Ancient: still pays shards+essence. Split flags are test-only; Keeper grants both.
func apply_water_pulse(grant_shards: bool = true, grant_essence: bool = true, reward_mult: float = 1.0) -> Dictionary:
	if fruit_committed:
		return {"ok": false, "reason": "pending_ascend", "shards": 0, "essence": 0}
	if not grant_shards and not grant_essence:
		return {"ok": false, "reason": "empty", "shards": 0, "essence": 0}
	var shards: int = 0
	var ess: int = 0
	if grant_shards:
		var shard_min: int = param_int("WATER_SHARD_MIN", 1)
		var shard_max: int = param_int("WATER_SHARD_MAX", 3)
		## U{1,3} plus Shard Sight (+0.5 per rank), then the Can ×2. Fractions stay in the accumulator.
		var shard_roll: float = float(randi_range(shard_min, shard_max)) + get_effect_total("water_shard_bonus")
		var units: float = shard_roll * float(get_water_shard_roll_mult()) * reward_mult
		shards = accumulate_harvest(&"manashards", units)
		lifetime_shards_from_water += shards
	if grant_essence:
		## A 1.0 Keeper pulse stays a whole Essence. Her 0.8 banks the fraction.
		if is_equal_approx(reward_mult, 1.0):
			ess = get_water_essence_amount()
			add_resource(&"essence", ess)
		else:
			elaia_water_essence_frac += float(get_water_essence_amount()) * reward_mult
			ess = int(floor(elaia_water_essence_frac))
			elaia_water_essence_frac -= float(ess)
			if ess > 0:
				add_resource(&"essence", ess)
		lifetime_essence_from_water += ess
	lifetime_waters += 1
	return {"ok": true, "reason": "ok", "shards": shards, "essence": ess}


## k seconds of this hero's gather yield (tool interval, stage, Forager, work rate).
## Fractions stay in harvest_accum. Wisps are not a caller.
func grant_played_gather_seconds(actor: String, resource_id: StringName, seconds: float) -> Dictionary:
	if actor != "keeper" and actor != "elaia":
		return {"ok": false, "reason": "wisp", "units": 0.0, "granted": 0}
	if is_world_frozen() or fruit_committed or seconds <= 0.0:
		return {"ok": false, "reason": "frozen", "units": 0.0, "granted": 0}
	if not resource_id in HARVEST_IDS:
		return {"ok": false, "reason": "resource", "units": 0.0, "granted": 0}
	var key: String = String(resource_id)
	var before: float = float(harvest_accum.get(key, 0.0))
	var rate: float = actor_work_rate(actor)
	if actor == "keeper":
		rate *= keeper_rested_mult()
	var granted: int = accumulate_keeper_harvest(resource_id, seconds, rate)
	var after: float = float(harvest_accum.get(key, 0.0))
	return {"ok": true, "reason": "ok", "granted": granted, "units": float(granted) + after - before}


## k seconds of this hero's watering income. Whole pulses use the normal roll.
## A leftover fraction is banked through the same accumulators as a short pulse.
func grant_played_water_seconds(actor: String, seconds: float) -> Dictionary:
	if actor != "keeper" and actor != "elaia":
		return {"ok": false, "reason": "wisp", "shards": 0, "essence": 0}
	if is_world_frozen() or fruit_committed or seconds <= 0.0:
		return {"ok": false, "reason": "frozen", "shards": 0, "essence": 0}
	var pulse: float = maxf(get_water_essence_pulse_sec(), 0.05)
	var mult: float = actor_water_mult(actor)
	var shards_before: int = get_resource(&"manashards")
	var ess_before: int = get_resource(&"essence")
	var left: float = seconds
	while left >= pulse - 0.00001:
		apply_water_pulse(true, true, mult)
		left -= pulse
	if left > 0.0001:
		apply_water_pulse(true, true, mult * (left / pulse))
	return {
		"ok": true,
		"reason": "ok",
		"shards": get_resource(&"manashards") - shards_before,
		"essence": get_resource(&"essence") - ess_before,
	}


## Legacy one-shot entry used by older verify paths — delegates to a single water pulse.
func try_water() -> String:
	var result: Dictionary = apply_water_pulse()
	if not bool(result.get("ok", false)):
		return str(result.get("reason", "fail"))
	return "ok"


func upgrade_max_rank(upgrade_id: String) -> int:
	var def: Dictionary = get_upgrade_def(upgrade_id)
	var cap: int = int(def.get("max_rank", 1))
	return cap if cap >= 0 else 1_000_000


func is_upgrade_unlocked(upgrade_id: String) -> bool:
	var def: Dictionary = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return false
	var unlock: String = str(def.get("unlock", "always"))
	match unlock:
		"always":
			return true
		"first_wisp_gained":
			return first_wisp_gained or wisp_count > 0 or get_upgrade_rank("bonus_wisp") > 0
		"first_tool_crafted":
			return first_tool_crafted
		"ascensions_1":
			return ascensions >= 1
		"ascensions_2":
			return ascensions >= 2
		"forge_visited":
			return forge_visited
		"reach_cleared_1":
			return has_node("/root/Reach") and int(Reach.reaches_cleared) >= 1
		"first_pack_lost":
			return first_pack_lost
		"dojo_exp":
			return has_node("/root/Reach") and int(Reach.dojo_exp) > 0
		"first_relic_crafted":
			return first_relic_crafted
		"adventure_unlocked":
			return echo_02_resolved
		"first_minigame_played":
			return first_minigame_played
		_:
			return true


func get_upgrade_cost(upgrade_id: String) -> int:
	var def: Dictionary = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return 999999
	var rank: int = get_upgrade_rank(upgrade_id)
	if rank >= upgrade_max_rank(upgrade_id):
		return -1
	var kind: String = str(def.get("cost_kind", "linear"))
	match kind:
		"flat":
			return int(def.get("cost_base", 0)) if rank < 1 else -1
		"exponential":
			var base: int = int(def.get("cost_base", 1))
			var mult: float = float(def.get("cost_mult", 2.0))
			return int(floor(float(base) * pow(mult, float(rank)) + 0.0000001))
		_:
			return int(def.get("cost_base", 1)) + int(def.get("cost_per_rank", 1)) * rank


func keep_manashards_fraction() -> float:
	return minf(0.5, float(get_upgrade_rank("keep_manashards")) * float(get_upgrade_def("keep_manashards").get("value_per_rank", 0.1)))


func expedition_loot_mult() -> float:
	return 1.0 + float(get_upgrade_rank("expedition_satchel")) * float(get_upgrade_def("expedition_satchel").get("value_per_rank", 0.1))


func dojo_exp_mult() -> float:
	return 1.0 + float(get_upgrade_rank("dojo_echo")) * float(get_upgrade_def("dojo_echo").get("value_per_rank", 0.05))


func forge_warmth_mult() -> float:
	var rank: int = get_upgrade_rank("forge_warmth")
	return maxf(0.25, pow(0.95, float(rank)))


func minigame_reward_mult() -> float:
	return 1.0 + float(get_upgrade_rank("minigame_knack")) * float(get_upgrade_def("minigame_knack").get("value_per_rank", 0.1))


func sturdy_pack_safe_ratio() -> float:
	return minf(0.45, float(get_upgrade_rank("sturdy_pack")) * float(get_upgrade_def("sturdy_pack").get("value_per_rank", 0.15)))


func max_expedition_party() -> int:
	return 2 + get_upgrade_rank("party_banner")


func note_first_tool_crafted() -> void:
	first_tool_crafted = true


func note_first_pack_lost() -> void:
	first_pack_lost = true


func note_first_minigame_played() -> void:
	first_minigame_played = true


func can_afford_any_ascension() -> bool:
	## True when leftover Manashards can still buy at least one blessing.
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var upgrade_id: String = str((entry as Dictionary).get("id", ""))
		if upgrade_id == "":
			continue
		var def: Dictionary = entry as Dictionary
		if not is_upgrade_unlocked(upgrade_id):
			continue
		if get_upgrade_rank(upgrade_id) >= upgrade_max_rank(upgrade_id):
			continue
		if manashards >= get_upgrade_cost(upgrade_id):
			return true
	return false


func can_buy_upgrade(upgrade_id: String) -> bool:
	## Manashard shop — only while awaiting Ascend after Fruit commit.
	if not fruit_committed:
		return false
	var def: Dictionary = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return false
	if not is_upgrade_unlocked(upgrade_id):
		return false
	if get_upgrade_rank(upgrade_id) >= upgrade_max_rank(upgrade_id):
		return false
	var cost: int = get_upgrade_cost(upgrade_id)
	return cost >= 0 and manashards >= cost


func buy_upgrade(upgrade_id: String) -> bool:
	## Spend Manashards for +1 blessing rank (multi-buy OK). Essence untouched.
	if not can_buy_upgrade(upgrade_id):
		return false
	var cost: int = get_upgrade_cost(upgrade_id)
	add_resource(&"manashards", -cost)
	upgrade_ranks[upgrade_id] = get_upgrade_rank(upgrade_id) + 1
	upgrades_changed.emit()
	needs_changed.emit()
	return true


func _raw_needs_for_next() -> Dictionary:
	## Grow spends Fertilizer + Essence only (playtest 3/6/12/24 + 20/40/60/80).
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return {}
	var def: Dictionary = get_stage_def(next_id)
	return {
		"essence": int(def.get("cost_essence", 0)),
		"fertilizer": int(def.get("cost_fertilizer", 0)),
	}


## Grow costs are raw Fertilizer + Essence. green_thumb does not cut Grow (craft only).
func get_next_stage_needs() -> Dictionary:
	var raw: Dictionary = _raw_needs_for_next()
	if raw.is_empty():
		return {}
	var out: Dictionary = {}
	for rid: StringName in NEED_ORDER:
		var key: String = String(rid)
		var need: int = int(raw.get(key, 0))
		if need > 0:
			out[key] = need
	return out


func has_needs_for_next() -> bool:
	var needs: Dictionary = get_next_stage_needs()
	if needs.is_empty():
		return false
	for key: Variant in needs.keys():
		var rid: StringName = StringName(str(key))
		if get_need_have(rid) < int(needs[key]):
			return false
	return true


func _set_fruit_committed(value: bool) -> void:
	## Keep Design field and legacy alias in lockstep (no SAVE_VERSION bump).
	fruit_committed = value
	fruit_harvested_pending_ascend = value


func can_pay_stage() -> bool:
	if stage_id == &"ancient" or fruit_committed:
		return false
	return has_needs_for_next()


func get_remaining_needs() -> Dictionary:
	var needs: Dictionary = get_next_stage_needs()
	var rem: Dictionary = {}
	for key: Variant in needs.keys():
		var k: String = str(key)
		var need: int = int(needs[k])
		var have: int = get_need_have(StringName(k))
		rem[k] = maxi(0, need - have)
	return rem


func _item_display(resource_id: String) -> String:
	match resource_id:
		"essence":
			return ContentStrings.get_text("hud_essence")
		"fertilizer":
			return ContentStrings.get_text("fertilizer_name")
		"food":
			return ContentStrings.get_text("hud_food")
		"wood":
			return ContentStrings.get_text("hud_wood")
		"stone":
			return ContentStrings.get_text("hud_stone")
		"manashards":
			return ContentStrings.get_text("hud_manashards")
		_:
			return resource_id.capitalize()


func format_need_checklist_lines() -> PackedStringArray:
	var needs: Dictionary = get_next_stage_needs()
	var lines: PackedStringArray = PackedStringArray()
	for rid: StringName in NEED_ORDER:
		var key: String = String(rid)
		if not needs.has(key):
			continue
		var need: int = int(needs[key])
		if need <= 0:
			continue
		var have: int = get_need_have(rid)
		var item: String = _item_display(key)
		var toks: Dictionary = {"item": item, "have": have, "need": need}
		var cost_key: String = "tree_grow_cost_line"
		if key == "fertilizer":
			cost_key = "tree_grow_cost_fertilizer_met" if have >= need else "tree_grow_cost_fertilizer"
		elif key == "essence":
			cost_key = "tree_grow_cost_essence_met" if have >= need else "tree_grow_cost_essence"
		elif have >= need:
			cost_key = "tree_need_line_met"
		else:
			cost_key = "tree_need_line"
		lines.append(ContentStrings.get_text(cost_key, toks))
	return lines


func format_missing_needs() -> String:
	return _join_cost_parts(_remaining_need_parts())


func _remaining_need_parts() -> PackedStringArray:
	var needs: Dictionary = get_next_stage_needs()
	var parts: PackedStringArray = PackedStringArray()
	for rid: StringName in NEED_ORDER:
		var key: String = String(rid)
		if not needs.has(key):
			continue
		var need: int = int(needs[key])
		var have: int = get_need_have(rid)
		if have >= need:
			continue
		var toks: Dictionary = {"have": have, "need": need, "count": need - have}
		match rid:
			&"essence":
				parts.append(ContentStrings.get_text("tree_stage_blocked_essence", toks))
			&"fertilizer":
				parts.append(ContentStrings.get_text("tree_stage_blocked_fertilizer", toks))
			&"food":
				parts.append(ContentStrings.get_text("tree_stage_blocked_food", toks))
			&"wood":
				parts.append(ContentStrings.get_text("tree_stage_blocked_wood", toks))
			&"stone":
				parts.append(ContentStrings.get_text("tree_stage_blocked_stone", toks))
			&"manashards":
				parts.append(ContentStrings.get_text("tree_stage_blocked_shards", {
					"count": need - have, "have": have, "need": need
				}))
	return parts


func _join_cost_parts(parts: PackedStringArray) -> String:
	## Content: commas + "and".
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return parts[0]
	if parts.size() == 2:
		return "%s and %s" % [parts[0], parts[1]]
	var head: PackedStringArray = PackedStringArray()
	for i: int in range(parts.size() - 1):
		head.append(parts[i])
	return "%s, and %s" % [", ".join(head), parts[parts.size() - 1]]


## Care-menu / HUD helper: next-stage needs checklist, or Ancient fruit/ascend state.
func get_care_next_stage_info() -> Dictionary:
	if stage_id == &"ancient" or fruit_committed:
		## tree_at_ancient_idle stays in the string table and is not shown. "Waiting" fights the timed fall.
		var ancient_line: String = ""
		if fruit_committed:
			ancient_line = ContentStrings.get_text("ascension_paused_body")
		elif fruit_ready:
			ancient_line = ContentStrings.get_text("tree_ancient_care_hint")
		return {
			"is_ancient": true,
			"title": str(get_stage_def().get("display_name", "Ancient")),
			"needs_header": "",
			"needs_lines": PackedStringArray([ancient_line]),
			"needs_status": ancient_line,
			"can_pay": false,
			"can_grow": false,
			"ready_for_fruit": fruit_ready,
			"pending_ascend": fruit_committed,
		}
	var next_id: StringName = get_next_stage_id()
	var next_def: Dictionary = get_stage_def(next_id)
	var next_display: String = str(next_def.get("display_name", next_id))
	var lines: PackedStringArray = format_need_checklist_lines()
	var needs: Dictionary = get_next_stage_needs()
	var status: String
	if needs.is_empty():
		status = ContentStrings.get_text("tree_next_stage_needs_none")
	elif has_needs_for_next():
		status = ContentStrings.get_text("tree_grow_ready")
	else:
		status = ContentStrings.get_text("tree_grow_cant_afford", {"costs": format_missing_needs()})
	return {
		"is_ancient": false,
		"title": ContentStrings.get_text("tree_next_stage_title", {"next_stage": next_display}),
		"needs_header": ContentStrings.get_text("tree_next_stage_needs_header"),
		"needs_lines": lines,
		"needs_status": status,
		"can_pay": has_needs_for_next(),
		"can_grow": has_needs_for_next(),
		"next_stage_display": next_display,
		"next_stage_id": String(next_id),
		"ready_for_fruit": false,
		"pending_ascend": false,
		"needs": needs,
	}


## One-click Grow: spend Fertilizer + Essence to advance one stage.
## Returns "ok" | "cant_afford" | "ancient" | "no_next".
func try_grow_stage() -> String:
	if stage_id == &"ancient" or fruit_committed:
		return "ancient"
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return "no_next"
	var needs: Dictionary = get_next_stage_needs()
	if needs.is_empty():
		return "no_next"
	if not has_needs_for_next():
		status_message.emit(ContentStrings.get_text("tree_grow_cant_afford", {"costs": format_missing_needs()}))
		return "cant_afford"
	for key: Variant in needs.keys():
		spend_need(StringName(str(key)), int(needs[key]))
	_set_stage(next_id)
	grant_wisp_from_stage()
	var next_display: String = str(get_stage_def(next_id).get("display_name", next_id))
	status_message.emit(ContentStrings.get_text("tree_grow_ok", {"next_stage": next_display}))
	needs_changed.emit()
	return "ok"


## Alias — CTA is Grow (tree_pay string).
func try_pay_stage() -> String:
	return try_grow_stage()


func can_grow_stage() -> bool:
	return can_pay_stage()


## Alias for Content tree_advance* keys.
func try_advance() -> String:
	return try_grow_stage()


func ancient_duration_sec() -> float:
	_ensure_idle_tuning()
	return maxf(1.0, float(_idle_tuning.get("ancient_duration_sec", 600.0)))


func ancient_duration_minutes() -> int:
	## Whole minutes from ancient_duration_sec. 600 s is 10. Not a hardcoded label.
	return maxi(1, int(ancient_duration_sec() / 60.0))


func offline_reset_active_sec() -> float:
	_ensure_idle_tuning()
	return maxf(0.0, float(_idle_tuning.get("offline_reset_active_sec", 180.0)))


## Confirmed by Haex. The away panel waits for this much real time.
const OFFLINE_PANEL_MIN_SEC: float = 600.0


func tick_ancient(delta: float) -> void:
	## Open and unpaused only — _process does not run while the tree is paused, and offline never calls this.
	if stage_id != &"ancient" or fruit_committed or delta <= 0.0:
		return
	if ancient_remaining_sec <= 0.0:
		return
	ancient_remaining_sec = maxf(0.0, ancient_remaining_sec - delta)
	if ancient_remaining_sec > 0.0:
		return
	ancient_remaining_sec = 0.0
	if harvest_fruit() > 0:
		ancient_frozen = true
		ancient_expired.emit()


func offline_effective_seconds(closed_sec: float) -> float:
	## Shared curve from a fresh closure. Tiers are [end_hours, rate]; end_hours <= 0 runs to the end.
	if closed_sec <= 0.0:
		return 0.0
	_ensure_idle_tuning()
	var tiers_v: Variant = _idle_tuning.get("offline_tiers", [])
	var tiers: Array = tiers_v if typeof(tiers_v) == TYPE_ARRAY else []
	if tiers.is_empty():
		tiers = _default_offline_tiers()
	tiers = _offline_tiers_with_quiet_hours(tiers)
	var cursor: float = 0.0
	var total: float = 0.0
	var remain: float = closed_sec
	for entry: Variant in tiers:
		if typeof(entry) != TYPE_ARRAY:
			continue
		var pair: Array = entry
		if pair.size() < 2:
			continue
		var end_hours: float = float(pair[0])
		var rate: float = float(pair[1])
		var span: float = remain
		if end_hours > 0.0:
			var end_sec: float = end_hours * 3600.0
			span = minf(remain, maxf(0.0, end_sec - cursor))
			cursor = end_sec
		if span > 0.0:
			total += span * rate
			remain -= span
		if remain <= 0.0000001:
			break
	return total


func commit_offline_gap(gap_sec: float) -> float:
	## Price this closure on the curve. 180s of active play since load restarts at 1/10; a shorter reopen continues.
	## Ancient (and a committed Fruit) grant nothing and do not consume curve time.
	if gap_sec <= 0.0:
		return 0.0
	if stage_id == &"ancient" or fruit_committed:
		active_since_load_sec = 0.0
		return 0.0
	var origin: float = offline_closed_sec
	if active_since_load_sec + 0.0001 >= offline_reset_active_sec():
		origin = 0.0
	var end_sec: float = origin + gap_sec
	var eff: float = offline_effective_seconds(end_sec) - offline_effective_seconds(origin)
	offline_closed_sec = end_sec
	active_since_load_sec = 0.0
	return eff


func _ensure_idle_tuning() -> void:
	if _idle_tuning_loaded:
		return
	_idle_tuning_loaded = true
	_idle_tuning = {}
	var file := FileAccess.open("res://data/forge_tuning.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_idle_tuning = parsed


func _offline_tiers_with_quiet_hours(tiers: Array) -> Array:
	var rank: int = get_upgrade_rank("quiet_hours")
	if rank <= 0 or tiers.is_empty():
		return tiers
	var out: Array = []
	for i: int in range(tiers.size()):
		var entry: Variant = tiers[i]
		if typeof(entry) != TYPE_ARRAY:
			out.append(entry)
			continue
		var pair: Array = (entry as Array).duplicate()
		if i == 0 and pair.size() >= 2:
			var end_h: float = float(pair[0])
			if end_h > 0.0:
				var bonus_h: float = float(get_upgrade_def("quiet_hours").get("value_per_rank", 0.25)) * float(rank)
				pair[0] = end_h + bonus_h
		out.append(pair)
	return out


func _default_offline_tiers() -> Array:
	## Mirror of data/forge_tuning.json offline_tiers. 2 min at full rate, then the locked steps.
	return [
		[1.0 / 30.0, 1.0],
		[1.0 / 6.0, 3.0 / 8.0],
		[0.5, 0.25],
		[2.0, 1.0 / 9.0],
		[8.0, 1.0 / 18.0],
		[24.0, 1.0 / 48.0],
		[-1.0, 1.0 / 144.0],
	]


func _set_stage(id: StringName) -> void:
	stage_id = id
	if id == &"ancient":
		ancient_remaining_sec = ancient_duration_sec()
	else:
		ancient_remaining_sec = 0.0
	var def: Dictionary = get_stage_def(id)
	fruit_ready = bool(def.get("grants_fruit", false)) and not fruit_committed
	stage_changed.emit(stage_id)
	fruit_ready_changed.emit(fruit_ready)
	needs_changed.emit()


func harvest_fruit() -> int:
	## SYSTEMS v0.3.4: commit only — do NOT bank ESSENCE_PER_HARVEST (wiped on Ascend anyway).
	if stage_id != &"ancient" or fruit_committed:
		return 0
	lifetime_fruit_harvested += 1
	fruit_ready = false
	_set_fruit_committed(true)
	fruit_ready_changed.emit(false)
	return 1


func can_ascend() -> bool:
	## Ascend after Fruit commit; Manashard purchases optional.
	return fruit_committed


func register_forge_upgrades(entries: Array) -> void:
	for entry: Variant in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = (entry as Dictionary).duplicate(true)
		var uid: String = str(d.get("id", ""))
		if uid == "" or not get_upgrade_def(uid).is_empty():
			continue
		upgrades_data.append(d)
	_ensure_upgrade_keys()


func ascend() -> void:
	if not fruit_committed:
		return
	if has_node("/root/MinigameHost") and MinigameHost.has_method("close_immediate"):
		MinigameHost.close_immediate()
	var forge_snap: Dictionary = {}
	if has_node("/root/ForgeJobs"):
		forge_snap = ForgeJobs.prepare_ascend()
	ascensions += 1
	## First Ascend opens the Echo. A paid fee, Key, and companion flag stay.
	portal_unlocked = true
	echo_flags_changed.emit()
	wood = 0
	stone = 0
	food = 0
	var shard_keep: float = keep_manashards_fraction()
	if shard_keep > 0.0 and manashards > 0:
		manashards = int(floor(float(manashards) * shard_keep))
	else:
		manashards = 0
	essence = 0
	_set_fruit_committed(false)
	ancient_frozen = false
	fruit_ready = false
	wisp_count = get_upgrade_rank("bonus_wisp")
	wisp_assignments.clear()
	wisp_pulse_accum.clear()
	wisp_favourites.clear()
	var farewell_idx: int = (ascensions - 1) % 8 + 1
	status_message.emit(ContentStrings.get_text("fruit_farewell_%02d" % farewell_idx))
	harvest_accum.clear()
	_clear_rested_hands_buff()
	_ensure_wisp_slots()
	clear_selection()
	wisps_changed.emit()
	_set_stage(&"sapling")
	resources_changed.emit(&"wood", wood)
	resources_changed.emit(&"stone", stone)
	resources_changed.emit(&"food", food)
	resources_changed.emit(&"manashards", manashards)
	resources_changed.emit(&"essence", essence)
	Backpack.on_ascend()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.finish_ascend(forge_snap)
	if has_node("/root/Reach"):
		Reach.on_ascend()
	## Combat ranks and battle gear persist. The soft Manashard bank above is already 0.
	if has_node("/root/KeeperStats"):
		KeeperStats.on_ascend()
	if has_node("/root/Equipment"):
		Equipment.on_ascend()
	needs_changed.emit()
	status_message.emit(ContentStrings.get_text("ascend_toast"))
	status_message.emit(ContentStrings.get_text("ascend_essence_reset_toast"))
	if get_upgrade_rank("keep_tools") > 0:
		status_message.emit(ContentStrings.get_text("upgrade_keep_tools_toast"))
		status_message.emit(ContentStrings.get_text("keep_tools_regrant_toast"))
		var keep_wipe: String = ContentStrings.get_text("backpack_wiped_keep_tools_toast")
		if keep_wipe != "backpack_wiped_keep_tools_toast":
			status_message.emit(keep_wipe)
	else:
		var wipe: String = ContentStrings.get_text("backpack_wiped_toast")
		if wipe != "backpack_wiped_toast":
			status_message.emit(wipe)
		else:
			status_message.emit(ContentStrings.get_text("ascend_backpack_wipe_toast"))
	gather_party_at_manatree()


const ASCEND_GATHER_KEEPER := Vector2(-56, 48)
const ASCEND_GATHER_ELAIA := Vector2(56, 48)


func ascend_gather_spot(actor: String) -> Vector2:
	## South of the sill, one on each side, so the party stands around the trunk.
	var origin := Vector2(2160, 2106)
	if has_node("/root/ForgeJobs") and ForgeJobs.has_method("manatree_origin"):
		origin = ForgeJobs.manatree_origin()
	if actor == "elaia":
		return origin + ASCEND_GATHER_ELAIA
	return origin + ASCEND_GATHER_KEEPER


func gather_party_at_manatree() -> void:
	## Jobs are already idle. The bodies stop the channel they were playing and come to the tree.
	var keeper_spot: Vector2 = ascend_gather_spot("keeper")
	var elaia_spot: Vector2 = ascend_gather_spot("elaia")
	var tree := get_tree()
	var bring_elaia: bool = elaia_in_party()
	if tree != null:
		for node: Node in tree.get_nodes_in_group("keeper"):
			if node.has_method("gather_at"):
				node.call("gather_at", keeper_spot)
		if bring_elaia:
			for node: Node in tree.get_nodes_in_group("companion"):
				if node.has_method("gather_at"):
					node.call("gather_at", elaia_spot)
	keeper_area = "clearing"
	keeper_has_pos = true
	keeper_pos = keeper_spot
	keeper_facing = "north"
	if bring_elaia:
		elaia_area = "clearing"
		elaia_has_pos = true
		elaia_pos = elaia_spot
		elaia_facing = "north"
	if tree != null:
		_show_gathered_bodies(tree)
		var current: Node = tree.current_scene
		if current != null and str(current.scene_file_path).ends_with("forge_room.tscn"):
			if has_node("/root/ForgeJobs"):
				ForgeJobs.switch_view(false, true)


func _show_gathered_bodies(tree: SceneTree) -> void:
	## A body that is already walking stays on that walk. Anyone left in the Forge is hidden.
	for node: Node in tree.get_nodes_in_group("keeper"):
		if bool(node.get("_moving")):
			continue
		if node.has_method("apply_keeper_presence"):
			node.call("apply_keeper_presence")
	if not elaia_in_party():
		return
	for node: Node in tree.get_nodes_in_group("companion"):
		if bool(node.get("_moving")):
			continue
		if node.has_method("_apply_presence"):
			node.call("_apply_presence")


func to_save_dict() -> Dictionary:
	return {
		"wood": wood,
		"stone": stone,
		"food": food,
		"manashards": manashards,
		"essence": essence,
		"stage_id": String(stage_id),
		"fruit_ready": fruit_ready,
		"fruit_committed": fruit_committed,
		"fruit_harvested_pending_ascend": fruit_harvested_pending_ascend,
		"welcome_shown": welcome_shown,
		"run_time_sec": run_time_sec,
		"tree_whisper_bag": tree_whisper_bag.duplicate(true),
		"tree_whisper_next_at": tree_whisper_next_at,
		"harvest_accum": harvest_accum.duplicate(true),
		"ancient_remaining_sec": ancient_remaining_sec,
		"offline_closed_sec": offline_closed_sec,
		"active_since_load_sec": active_since_load_sec,
		"ascensions": ascensions,
		"lifetime_waters": lifetime_waters,
		"lifetime_shards_from_water": lifetime_shards_from_water,
		"lifetime_essence_from_water": lifetime_essence_from_water,
		"lifetime_fruit_harvested": lifetime_fruit_harvested,
		"lifetime_harvested": lifetime_harvested.duplicate(true),
		"upgrades": upgrade_ranks.duplicate(true),
		"shop_hide_locked": shop_hide_locked,
		"shop_hide_maxed": shop_hide_maxed,
		"shop_spoiler_shown_count": shop_spoiler_shown_count,
		"first_wisp_gained": first_wisp_gained,
		"first_tool_crafted": first_tool_crafted,
		"first_pack_lost": first_pack_lost,
		"first_minigame_played": first_minigame_played,
		"wisp_count": wisp_count,
		"wisp_assignments": wisp_assignments.duplicate(true),
		"last_gift_day": last_gift_day,
		"wisp_favourites": wisp_favourites.duplicate(true),
		"backpack": Backpack.to_save_dict(),
		"owns_stone_axe": Backpack.owns_item("stone_axe"),
		"owns_stone_pickaxe": Backpack.owns_item("stone_pickaxe"),
		"owns_wooden_basket": Backpack.owns_item("wooden_basket"),
		"owns_stone_watering_can": Backpack.owns_item("stone_watering_can"),
		"keeper_stats": KeeperStats.to_save_dict() if has_node("/root/KeeperStats") else {},
		"equipment_unlocked": _equipment_save_field("equipment_unlocked"),
		"equipment_equipped": _equipment_save_field("equipment_equipped"),
		"gear_inventory": _equipment_save_field("gear_inventory"),
		"elaia_equipped": Equipment.elaia_equipped_to_save() if has_node("/root/Equipment") else {},
		"portal_unlocked": portal_unlocked,
		"portal_fee_paid": portal_fee_paid,
		"echo_01_resolved": echo_01_resolved,
		"echo_01_redeemed": echo_01_redeemed,
		"first_relic_crafted": first_relic_crafted,
		"elaia_legacy_joined": elaia_legacy_joined,
		"elaia_join_seen": elaia_join_seen,
		"elaia_footsteps_seen": elaia_footsteps_seen,
		"elaia_area": elaia_area,
		"elaia_pos_x": elaia_pos.x,
		"elaia_pos_y": elaia_pos.y,
		"elaia_has_pos": elaia_has_pos,
		"elaia_facing": elaia_facing,
		"keeper_area": keeper_area,
		"keeper_pos_x": keeper_pos.x,
		"keeper_pos_y": keeper_pos.y,
		"keeper_has_pos": keeper_has_pos,
		"keeper_facing": keeper_facing,
		"elaia_water_essence_frac": elaia_water_essence_frac,
		"forge_key": forge_key,
		"echo_01_narrator_heard": echo_01_narrator_heard,
		"echo_02_fee_paid": echo_02_fee_paid,
		"echo_02_resolved": echo_02_resolved,
		"echo_02_outcome": echo_02_outcome,
		"echo_02_narrator_heard": echo_02_narrator_heard,
		"expedition_lantern": expedition_lantern,
		"arrow_mode": arrow_mode,
		"ancient_frozen": ancient_frozen,
		"forge_visited": forge_visited,
	}.merged(ForgeJobs.capture_save_fields() if has_node("/root/ForgeJobs") else {}).merged(
		Reach.capture_save_fields() if has_node("/root/Reach") else {}
	)


func apply_save_dict(data: Dictionary) -> void:
	applying_save = true
	wood = int(data.get("wood", 0))
	stone = int(data.get("stone", 0))
	food = int(data.get("food", 0))
	manashards = int(data.get("manashards", 0))
	essence = int(data.get("essence", 0))
	stage_id = StringName(str(data.get("stage_id", "sapling")))
	# growth ignored (SAVE_VERSION 4 / v3 migrate)
	fruit_ready = bool(data.get("fruit_ready", false))
	## Prefer Design field; migrate from legacy alias without SAVE_VERSION bump.
	_set_fruit_committed(bool(data.get("fruit_committed", data.get("fruit_harvested_pending_ascend", false))))
	if fruit_committed:
		fruit_ready = false
	var accum_v: Variant = data.get("harvest_accum", {})
	if typeof(accum_v) == TYPE_DICTIONARY:
		harvest_accum = (accum_v as Dictionary).duplicate(true)
	else:
		harvest_accum = {}
	if stage_id == &"ancient" and not fruit_committed:
		if data.has("ancient_remaining_sec"):
			ancient_remaining_sec = maxf(0.0, float(data.get("ancient_remaining_sec", 0.0)))
		else:
			ancient_remaining_sec = ancient_duration_sec()
	else:
		ancient_remaining_sec = 0.0
	offline_closed_sec = maxf(0.0, float(data.get("offline_closed_sec", 0.0)))
	active_since_load_sec = maxf(0.0, float(data.get("active_since_load_sec", 0.0)))
	welcome_shown = bool(data.get("welcome_shown", false))
	run_time_sec = float(data.get("run_time_sec", 0.0))
	var whisper_bag_v: Variant = data.get("tree_whisper_bag", [])
	if typeof(whisper_bag_v) == TYPE_ARRAY:
		tree_whisper_bag = (whisper_bag_v as Array).duplicate(true)
	else:
		tree_whisper_bag.clear()
	if data.has("tree_whisper_next_at"):
		tree_whisper_next_at = maxf(TreeWhispers.INTERVAL_SEC, float(data.get("tree_whisper_next_at", TreeWhispers.INTERVAL_SEC)))
	else:
		tree_whisper_next_at = maxf(run_time_sec + TreeWhispers.INTERVAL_SEC, TreeWhispers.INTERVAL_SEC)
	TreeWhispers.prune_bag(tree_whisper_bag, stage_id)
	ascensions = int(data.get("ascensions", data.get("ascension_count", 0)))
	portal_unlocked = bool(data.get("portal_unlocked", false)) or ascensions >= 1
	portal_fee_paid = bool(data.get("portal_fee_paid", false))
	echo_01_resolved = bool(data.get("echo_01_resolved", false))
	echo_01_redeemed = bool(data.get("echo_01_redeemed", false))
	if data.has("first_relic_crafted"):
		first_relic_crafted = bool(data.get("first_relic_crafted", false))
	else:
		first_relic_crafted = _save_holds_relic(data)
	if data.has("elaia_legacy_joined"):
		elaia_legacy_joined = bool(data.get("elaia_legacy_joined", false))
	else:
		## Missing gate: Spare had already put her in the party, even with no relic.
		elaia_legacy_joined = echo_01_redeemed and not data.has("first_relic_crafted")
	## A save that already had her joined never replays the first-join lines.
	if data.has("elaia_join_seen"):
		elaia_join_seen = bool(data.get("elaia_join_seen", false))
	else:
		elaia_join_seen = elaia_in_party()
	elaia_area = str(data.get("elaia_area", "clearing"))
	if elaia_area != "forge":
		elaia_area = "clearing"
	elaia_has_pos = bool(data.get("elaia_has_pos", false))
	elaia_pos = Vector2(float(data.get("elaia_pos_x", 0.0)), float(data.get("elaia_pos_y", 0.0)))
	elaia_facing = str(data.get("elaia_facing", "south"))
	if elaia_facing != "north" and elaia_facing != "east" and elaia_facing != "west":
		elaia_facing = "south"
	if data.has("elaia_footsteps_seen"):
		elaia_footsteps_seen = bool(data.get("elaia_footsteps_seen", false))
	else:
		## Already joined, or she is not waiting: do not replay the Forge popup.
		## Mid-way (relic done, dialogue not seen) still owes the popup.
		elaia_footsteps_seen = not (first_relic_crafted and echo_01_redeemed and not elaia_join_seen)
	if elaia_footsteps_seen and elaia_join_pending() and not elaia_has_pos:
		begin_elaia_join_clearing()
	keeper_area = str(data.get("keeper_area", "clearing"))
	if keeper_area != "forge":
		keeper_area = "clearing"
	keeper_has_pos = bool(data.get("keeper_has_pos", false))
	keeper_pos = Vector2(float(data.get("keeper_pos_x", 0.0)), float(data.get("keeper_pos_y", 0.0)))
	keeper_facing = str(data.get("keeper_facing", "south"))
	elaia_water_essence_frac = maxf(0.0, float(data.get("elaia_water_essence_frac", 0.0)))
	_hero_water_accum.clear()
	forge_key = bool(data.get("forge_key", false))
	echo_01_narrator_heard = bool(data.get("echo_01_narrator_heard", false))
	echo_02_fee_paid = bool(data.get("echo_02_fee_paid", false))
	echo_02_resolved = bool(data.get("echo_02_resolved", false))
	echo_02_outcome = str(data.get("echo_02_outcome", ""))
	echo_02_narrator_heard = bool(data.get("echo_02_narrator_heard", false))
	var lantern: String = str(data.get("expedition_lantern", "dark"))
	expedition_lantern = lantern if lantern == "amber" or lantern == "cyan" else "dark"
	arrow_mode = "magical" if str(data.get("arrow_mode", "physical")) == "magical" else "physical"
	ancient_frozen = bool(data.get("ancient_frozen", false))
	forge_visited = bool(data.get("forge_visited", false))
	if ancient_frozen:
		_set_fruit_committed(true)
		fruit_ready = false
		ancient_remaining_sec = 0.0
	lifetime_waters = int(data.get("lifetime_waters", 0))
	lifetime_shards_from_water = int(data.get("lifetime_shards_from_water", 0))
	lifetime_essence_from_water = int(data.get("lifetime_essence_from_water", 0))
	lifetime_fruit_harvested = int(data.get("lifetime_fruit_harvested", 0))
	var harvested: Variant = data.get("lifetime_harvested", {})
	if typeof(harvested) == TYPE_DICTIONARY:
		lifetime_harvested = (harvested as Dictionary).duplicate(true)
	else:
		lifetime_harvested = {}
	_ensure_harvest_keys()
	var ranks: Variant = data.get("upgrades", data.get("upgrade_ranks", {}))
	if typeof(ranks) == TYPE_DICTIONARY:
		upgrade_ranks = (ranks as Dictionary).duplicate(true)
		upgrade_ranks.erase("keep_forge_intermediates")
	_ensure_upgrade_keys()
	shop_hide_locked = bool(data.get("shop_hide_locked", true))
	shop_hide_maxed = bool(data.get("shop_hide_maxed", true))
	shop_spoiler_shown_count = int(data.get("shop_spoiler_shown_count", 0))
	first_wisp_gained = bool(data.get("first_wisp_gained", false))
	first_tool_crafted = bool(data.get("first_tool_crafted", false))
	first_pack_lost = bool(data.get("first_pack_lost", false))
	first_minigame_played = bool(data.get("first_minigame_played", false))
	wisp_count = int(data.get("wisp_count", 0))
	if wisp_count > 0:
		first_wisp_gained = true
	var assigns: Variant = data.get("wisp_assignments", {})
	if typeof(assigns) == TYPE_DICTIONARY:
		wisp_assignments = (assigns as Dictionary).duplicate(true)
	else:
		wisp_assignments = {}
	last_gift_day = str(data.get("last_gift_day", ""))
	var fav_v: Variant = data.get("wisp_favourites", {})
	if typeof(fav_v) == TYPE_DICTIONARY:
		wisp_favourites = (fav_v as Dictionary).duplicate(true)
	else:
		wisp_favourites = {}
	wisp_pulse_accum.clear()
	_ensure_wisp_slots()
	Backpack.apply_save_dict(data.get("backpack", {}))
	## SYSTEMS v0.4.0 prefers unique-tool flags; backpack stacks (max 1) also OK.
	if bool(data.get("owns_stone_axe", false)):
		Backpack.set_count("stone_axe", 1)
	if bool(data.get("owns_stone_pickaxe", false)):
		Backpack.set_count("stone_pickaxe", 1)
	if bool(data.get("owns_wooden_basket", false)):
		Backpack.set_count("wooden_basket", 1)
	if bool(data.get("owns_stone_watering_can", false)):
		Backpack.set_count("stone_watering_can", 1)
	if has_node("/root/KeeperStats"):
		KeeperStats.apply_save_dict(data.get("keeper_stats", {}))
	if has_node("/root/Equipment"):
		Equipment.apply_save_dict(_equipment_payload(data))
		Equipment.apply_elaia_equipped(data.get("elaia_equipped", {}))
		if forge_key:
			Equipment.ensure_forge_key_from_load()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.apply_save_fields(data)
	if has_node("/root/Reach"):
		var reach_v: Variant = data.get("reach", {})
		Reach.apply_save_fields(reach_v if typeof(reach_v) == TYPE_DICTIONARY else {})
		var exp_v: Variant = data.get("expedition", {})
		Reach.apply_expedition(exp_v if typeof(exp_v) == TYPE_DICTIONARY else {})
	keeper_selected = false
	selected_wisp_id = -1
	selected_wisp_ids.clear()
	selected_companion_id = ""
	wisps_changed.emit()
	resources_changed.emit(&"wood", wood)
	resources_changed.emit(&"stone", stone)
	resources_changed.emit(&"food", food)
	resources_changed.emit(&"manashards", manashards)
	resources_changed.emit(&"essence", essence)
	stage_changed.emit(stage_id)
	fruit_ready_changed.emit(fruit_ready)
	needs_changed.emit()
	upgrades_changed.emit()
	echo_flags_changed.emit()
	load_completed.emit()
	applying_save = false


func _save_holds_relic(data: Dictionary) -> bool:
	## Missing first_relic_crafted defaults true when the save already holds a relic.
	## The Forge Key counts: it is a relic. A crafted Reliquary relic counts too.
	if not has_node("/root/Equipment"):
		return false
	var ids: Array[String] = []
	var bag: Variant = data.get("gear_inventory", {})
	if typeof(bag) == TYPE_DICTIONARY:
		for key: Variant in (bag as Dictionary).keys():
			if int((bag as Dictionary)[key]) > 0:
				ids.append(str(key))
	var equipped: Variant = data.get("equipment_equipped", {})
	if typeof(equipped) == TYPE_DICTIONARY:
		for key: Variant in (equipped as Dictionary).keys():
			var raw: Variant = (equipped as Dictionary)[key]
			if raw == null:
				continue
			var iid: String = str(raw)
			if iid != "" and iid != "Null":
				ids.append(iid)
	for iid: String in ids:
		if str(Equipment.get_item_def(iid).get("category", "")) == "relic":
			return true
	return false


func _equipment_save_field(key: String) -> Dictionary:
	if not has_node("/root/Equipment"):
		return {}
	var blob: Dictionary = Equipment.to_save_dict()
	var found: Variant = blob.get(key, {})
	return (found as Dictionary).duplicate(true) if typeof(found) == TYPE_DICTIONARY else {}


func _equipment_payload(data: Dictionary) -> Dictionary:
	var has_new: bool = data.has("gear_inventory") or data.has("equipment_equipped")
	if has_new:
		return {
			"equipment_unlocked": data.get("equipment_unlocked", {}),
			"equipment_equipped": data.get("equipment_equipped", {}),
			"gear_inventory": data.get("gear_inventory", {}),
		}
	var legacy: Variant = data.get("equipment", {})
	return legacy if typeof(legacy) == TYPE_DICTIONARY else {}


func reset_for_new_game() -> void:
	wood = 0
	stone = 0
	food = 0
	manashards = 0
	essence = 0
	stage_id = &"sapling"
	fruit_ready = false
	_set_fruit_committed(false)
	welcome_shown = false
	welcome_presented = false
	ascensions = 0
	lifetime_waters = 0
	lifetime_shards_from_water = 0
	lifetime_essence_from_water = 0
	lifetime_fruit_harvested = 0
	lifetime_harvested.clear()
	_ensure_harvest_keys()
	upgrade_ranks.clear()
	_ensure_upgrade_keys()
	shop_hide_locked = true
	shop_hide_maxed = true
	shop_spoiler_shown_count = 0
	first_wisp_gained = false
	first_tool_crafted = false
	first_pack_lost = false
	first_minigame_played = false
	wisp_count = 0
	wisp_assignments.clear()
	wisp_favourites.clear()
	wisp_pulse_accum.clear()
	harvest_accum.clear()
	ancient_remaining_sec = 0.0
	offline_closed_sec = 0.0
	active_since_load_sec = 0.0
	keeper_selected = false
	selected_wisp_id = -1
	selected_wisp_ids.clear()
	selected_companion_id = ""
	run_time_sec = 0.0
	_reset_tree_whispers()
	portal_unlocked = false
	portal_fee_paid = false
	echo_01_resolved = false
	echo_01_redeemed = false
	first_relic_crafted = false
	elaia_legacy_joined = false
	elaia_join_seen = false
	elaia_footsteps_seen = false
	elaia_area = "clearing"
	keeper_area = "clearing"
	keeper_pos = Vector2.ZERO
	keeper_has_pos = false
	keeper_facing = "south"
	pending_focus_actor = ""
	elaia_pos = Vector2.ZERO
	elaia_has_pos = false
	elaia_facing = "south"
	elaia_water_essence_frac = 0.0
	_hero_water_accum.clear()
	forge_key = false
	echo_01_narrator_heard = false
	echo_02_fee_paid = false
	echo_02_resolved = false
	echo_02_outcome = ""
	echo_02_narrator_heard = false
	expedition_lantern = "dark"
	arrow_mode = "physical"
	ancient_frozen = false
	forge_visited = false
	echo_flags_changed.emit()
	Backpack.reset_for_new_game()
	if has_node("/root/KeeperStats"):
		KeeperStats.reset_for_new_game()
	if has_node("/root/Equipment"):
		Equipment.reset_for_new_game()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.reset_for_new_game()
	if has_node("/root/Reach"):
		Reach.reset_for_new_game()
	wisps_changed.emit()
	selection_changed.emit()
	resources_changed.emit(&"wood", wood)
	resources_changed.emit(&"stone", stone)
	resources_changed.emit(&"food", food)
	resources_changed.emit(&"manashards", manashards)
	resources_changed.emit(&"essence", essence)
	stage_changed.emit(stage_id)
	fruit_ready_changed.emit(fruit_ready)
	needs_changed.emit()
	upgrades_changed.emit()


func is_world_frozen() -> bool:
	return ancient_frozen


func note_frozen_deny() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _frozen_deny_msec < 1600:
		return
	_frozen_deny_msec = now
	status_message.emit(ContentStrings.get_text("ascend_frozen_deny"))


func cancel_fruit_commit() -> void:
	## A manual harvest can still be cancelled. The Ancient timeout cannot.
	if ancient_frozen or not fruit_committed:
		return
	_set_fruit_committed(false)
	var def: Dictionary = get_stage_def(stage_id)
	fruit_ready = bool(def.get("grants_fruit", false))
	fruit_ready_changed.emit(fruit_ready)
	needs_changed.emit()


func debug_tools() -> bool:
	if has_node("/root/AnimPreviewHotkey"):
		return bool(AnimPreviewHotkey.debug_tools_enabled())
	return OS.is_debug_build()


func debug_set_resource_exact(resource_id: StringName, amount: int) -> void:
	if not debug_tools():
		return
	set_resource(resource_id, amount)


func debug_set_upgrade_rank(upgrade_id: String, rank: int) -> void:
	if not debug_tools():
		return
	upgrade_ranks[upgrade_id] = maxi(0, rank)
	upgrades_changed.emit()
	needs_changed.emit()


func debug_reset_upgrade_ranks() -> void:
	if not debug_tools():
		return
	upgrade_ranks.clear()
	_ensure_upgrade_keys()
	upgrades_changed.emit()
	needs_changed.emit()


func debug_set_ancient_timer(sec: float, frozen: bool) -> void:
	if not debug_tools():
		return
	if stage_id != &"ancient":
		_set_stage(&"ancient")
	ancient_remaining_sec = maxf(0.0, sec)
	ancient_frozen = frozen
	if frozen:
		_set_fruit_committed(true)
		fruit_ready = false
		fruit_ready_changed.emit(false)


func debug_commit_fruit() -> void:
	if not debug_tools() or stage_id != &"ancient" or fruit_committed:
		return
	harvest_fruit()


func debug_cancel_fruit() -> void:
	if not debug_tools():
		return
	cancel_fruit_commit()


func debug_skip_offline_hours(hours: float) -> float:
	if not debug_tools() or hours <= 0.0:
		return 0.0
	var sec: float = hours * 3600.0
	var eff: float = commit_offline_gap(sec)
	if has_node("/root/Reach"):
		Reach.apply_offline_seconds(sec)
	if has_node("/root/ForgeJobs"):
		ForgeJobs.apply_offline_seconds(sec)
	return eff
