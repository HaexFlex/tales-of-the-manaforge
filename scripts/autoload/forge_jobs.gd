extends Node
## Always-on Forge job manager. Runs in every scene. Pausable with the pause menu.
## Numbers come from data/forge_tuning.json. Player copy comes from data/forge_copy.json.

const TUNING_PATH: String = "res://data/forge_tuning.json"
const COPY_PATH: String = "res://data/forge_copy.json"
const FORGE_SCENE: String = "res://scenes/forge_room.tscn"
const HUB_SCENE: String = "res://scenes/main.tscn"
const STATION_IDS: PackedStringArray = ["crucible", "mill", "press", "anvil", "reliquary"]
const RESOURCE_IDS: PackedStringArray = ["wood", "stone", "food", "manashards", "essence"]
const MAX_COMPLETIONS: int = 10000

var _tuning: Dictionary = {}
var _copy: Dictionary = {}
var _jobs: Dictionary = {}
var _keeper_station: String = ""
var _keeper_working: bool = false
var _companions: Dictionary = {}
var _keeper_task: Dictionary = {"kind": "none", "target": "", "working": false}
var _elaia_task: Dictionary = {"kind": "none", "target": "", "working": false}
var _elaia_station: String = ""
var _elaia_working: bool = false
## Target key held while a hero is walking, before the job is marked working.
var _hero_claims: Dictionary = {}
var _silent: bool = false
var _pending_toast: String = ""
var _return_to_clearing: bool = false
var _dev_override: float = -1.0
var _autosave_enabled: bool = true
var _autosave_accum: float = 0.0
var _last_big_done_msec: int = -1000000
var _allow_scene_change: bool = true
## -1 follows the live scene. 0/1 forces the upcycle tick inside or outside the Forge.
var _in_forge_override: int = -1
var _materials_snapshot: Dictionary = {}
var _repeat_override: Dictionary = {}
## One phase for every wisp on every target. Advanced once per frame, not once per wisp.
var _wisp_orbit_phase: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_files()
	if has_node("/root/GameState"):
		GameState.register_forge_upgrades(upgrade_defs())


func _process(delta: float) -> void:
	step_jobs(delta)


func step_jobs(delta: float) -> void:
	## Shared by the live frame and the jobs-survive check. One clock for income.
	var speed: float = float(_tuning.get("wisp_orbit_speed", 1.45))
	_wisp_orbit_phase = fposmod(_wisp_orbit_phase + speed * delta, TAU)
	advance_seconds(delta * dev_time_scale())
	_tick_absent_elaia(delta)
	_tick_absent_keeper(delta)
	if not _autosave_enabled:
		return
	var every: float = float(_tuning.get("autosave_sec", 300.0))
	if every <= 0.0 or not has_node("/root/SaveService"):
		return
	_autosave_accum += delta
	if _autosave_accum < every:
		return
	_autosave_accum = 0.0
	if EchoChamber.in_battle or not SaveService.session_active:
		return
	SaveService.save_autosave(true)


func _load_files() -> void:
	_tuning = _read_dict(TUNING_PATH)
	_copy = _read_dict(COPY_PATH)


func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("ForgeJobs: missing %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func dev_time_scale() -> float:
	## Editor playtest runs at 1x. dev_speed_multiplier (60) is opt-in only:
	## MANAFORGE_DEV_SPEED=1 in a debug build. A release build is always 1x.
	if not OS.is_debug_build():
		return 1.0
	if _dev_override >= 0.0:
		return _dev_override
	if OS.get_environment("MANAFORGE_DEV_SPEED") == "1":
		return float(_tuning.get("dev_speed_multiplier", 1.0))
	return 1.0


func set_dev_speed_override(scale: float) -> void:
	if not OS.is_debug_build():
		_dev_override = 1.0
		return
	_dev_override = scale


func set_autosave_enabled(enabled: bool) -> void:
	_autosave_enabled = enabled


func upgrade_defs() -> Array:
	var raw: Variant = _tuning.get("ascend_upgrades", [])
	return raw if typeof(raw) == TYPE_ARRAY else []


func is_forge_station(node_id: String) -> bool:
	return STATION_IDS.has(node_id)


func wisp_cap() -> int:
	return maxi(1, int(_tuning.get("wisp_cap", 4)))


func station_display(station_id: String) -> String:
	var def: Dictionary = _station_def(station_id)
	var named: String = str(def.get("display_name", station_id))
	return named if named != "" else station_id


func stand_radius() -> float:
	return float(_tuning.get("stand_radius", 56.0))


func room_size() -> Vector2:
	return Vector2(float(_tuning.get("room_width", 1600.0)), float(_tuning.get("room_height", 1200.0)))


func camera_pan_speed() -> float:
	return float(_tuning.get("camera_pan_speed", 420.0))


func audio_lowpass_hz() -> float:
	return float(_tuning.get("lowpass_cutoff_hz", 1500.0))


func audio_reverb_room() -> float:
	return float(_tuning.get("reverb_room_size", 0.35))


func audio_music_db() -> float:
	return float(_tuning.get("forge_music_db", -3.0))


func copy_text(key: String, vars: Dictionary = {}) -> String:
	var text: String = str(_copy.get(key, key))
	for var_key: Variant in vars.keys():
		text = text.replace("{%s}" % str(var_key), str(vars[var_key]))
	return text


func examine_line(station_id: String) -> String:
	return copy_text("examine_%s" % station_id)


func recipe_ids_for(station_id: String) -> PackedStringArray:
	var def: Dictionary = _station_def(station_id)
	var out: PackedStringArray = PackedStringArray()
	var one: String = str(def.get("recipe", ""))
	if one != "":
		out.append(one)
	var many: Variant = def.get("recipes", [])
	if typeof(many) == TYPE_ARRAY:
		for entry: Variant in many:
			var rid: String = str(entry)
			if rid != "":
				out.append(rid)
	return out


func recipe_output_id(recipe_id: String) -> String:
	var recipe: Dictionary = _recipe(recipe_id)
	return str(recipe.get("output", recipe_id))


func output_icon(item_id: String) -> Texture2D:
	var path: String = _output_icon_path(item_id)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func recipe_hover_bbcode(recipe_id: String) -> String:
	var recipe: Dictionary = _recipe(recipe_id)
	if recipe.is_empty():
		return recipe_id
	var lines: PackedStringArray = PackedStringArray()
	var output: String = recipe_output_id(recipe_id)
	lines.append("[b]%s[/b]" % _item_label(output))
	if bool(recipe.get("output_gear", false)):
		var bits: PackedStringArray = _bonus_bits(recipe)
		if bits.size() > 0:
			lines.append(" ".join(bits))
	var inputs: Dictionary = _inputs(recipe)
	for key: Variant in inputs.keys():
		var need: int = int(inputs[key])
		if need <= 0:
			continue
		var owned: int = _have(str(key))
		var row: String = "%s %d/%d" % [_counted_name(str(key), need), owned, need]
		if owned < need:
			row = "[color=#e07050]%s[/color]" % row
		lines.append(row)
	return "\n".join(lines)


func _bonus_bits(recipe: Dictionary) -> PackedStringArray:
	var bits: PackedStringArray = PackedStringArray()
	var bonuses: Variant = recipe.get("bonuses", {})
	if typeof(bonuses) == TYPE_DICTIONARY:
		for stat_id: String in ["might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"]:
			var amount: int = int((bonuses as Dictionary).get(stat_id, 0))
			if amount == 0:
				continue
			var stat_name: String = stat_id.capitalize()
			if has_node("/root/KeeperStats"):
				stat_name = KeeperStats.stat_display_name(stat_id)
			bits.append("%s %+d" % [stat_name, amount])
	var kind: String = str(recipe.get("damage_kind", ""))
	if kind != "":
		bits.append(kind.capitalize())
	return bits


func _counted_name(item_id: String, need: int) -> String:
	var base: String = _item_label(item_id)
	if has_node("/root/Backpack") and Backpack.has_method("counted_item_name"):
		return Backpack.counted_item_name(item_id, need, base)
	return base


func _item_label(item_id: String) -> String:
	if has_node("/root/ContentStrings"):
		var hud_key: String = "hud_%s" % item_id
		var labeled: String = ContentStrings.get_text(hud_key)
		if labeled != hud_key and labeled != "":
			return labeled
	if has_node("/root/Equipment") and Equipment.is_known_item(item_id):
		return Equipment.item_display_name(item_id)
	if has_node("/root/Backpack") and Backpack.is_known_item(item_id):
		return Backpack.item_display_name(item_id)
	return item_id.capitalize().replace("_", " ")


func _output_icon_path(item_id: String) -> String:
	if has_node("/root/Equipment"):
		var from_art: String = Equipment.item_art_path(item_id)
		if from_art != "":
			return from_art
	match item_id:
		"wood":
			return "res://assets/art/ui/icon_wood.png"
		"stone":
			return "res://assets/art/ui/icon_stone.png"
		"food":
			return "res://assets/art/ui/icon_food.png"
		"essence":
			return "res://assets/art/ui/icon_essence.png"
		_:
			return ""


func recipe_button_text(recipe_id: String) -> String:
	var recipe: Dictionary = _recipe(recipe_id)
	var output: String = str(recipe.get("output", recipe_id))
	return "%s  (%ss)" % [output.capitalize().replace("_", " "), str(int(recipe.get("duration_sec", 0)))]


func gear_overlay(item_id: String) -> Dictionary:
	for key: Variant in _recipes().keys():
		var recipe: Dictionary = _recipe(str(key))
		if str(recipe.get("output", "")) != item_id:
			continue
		var overlay: Dictionary = {}
		var bonuses: Variant = recipe.get("bonuses", {})
		if typeof(bonuses) == TYPE_DICTIONARY and not (bonuses as Dictionary).is_empty():
			overlay["bonuses"] = bonuses
		var kind: String = str(recipe.get("damage_kind", ""))
		if kind != "":
			overlay["damage_kind"] = kind
		var category: String = str(recipe.get("category", ""))
		if category != "":
			overlay["category"] = category
		return overlay
	return {}


func category_of(item_id: String) -> String:
	var resources: Dictionary = _tuning.get("resource_categories", {}) if typeof(_tuning.get("resource_categories", {})) == TYPE_DICTIONARY else {}
	if resources.has(item_id):
		return str(resources[item_id])
	if has_node("/root/Backpack") and Backpack.is_known_item(item_id):
		var cat: String = str(Backpack.get_item_def(item_id).get("category", ""))
		if cat != "":
			return cat
	if has_node("/root/Equipment") and Equipment.is_known_item(item_id):
		var gear_cat: String = str(Equipment.get_item_def(item_id).get("category", ""))
		if gear_cat != "":
			return gear_cat
	var overlay: Dictionary = gear_overlay(item_id)
	return str(overlay.get("category", ""))


func item_categories() -> Dictionary:
	var out: Dictionary = {}
	var resources: Variant = _tuning.get("resource_categories", {})
	if typeof(resources) == TYPE_DICTIONARY:
		for key: Variant in (resources as Dictionary).keys():
			out[str(key)] = str((resources as Dictionary)[key])
	if has_node("/root/Backpack"):
		for entry: Variant in Backpack.items_data:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var iid: String = str((entry as Dictionary).get("id", ""))
			if iid != "":
				out[iid] = category_of(iid)
	if has_node("/root/Equipment"):
		for entry: Variant in Equipment.items_data:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var iid: String = str((entry as Dictionary).get("id", ""))
			if iid != "":
				out[iid] = category_of(iid)
	return out


func backpack_filters() -> PackedStringArray:
	var raw: Variant = _tuning.get("backpack_filters", [])
	var out: PackedStringArray = PackedStringArray()
	if typeof(raw) == TYPE_ARRAY:
		for entry: Variant in raw:
			out.append(str(entry))
	return out


func matches_backpack_filter(item_id: String, filter_id: String) -> bool:
	if filter_id == "" or filter_id == "all":
		return true
	var want: String = filter_id
	match filter_id:
		"tools":
			want = "tool"
		"weapons":
			want = "weapon"
		"relics":
			want = "relic"
	return category_of(item_id) == want


func open_bench_hook() -> void:
	## Pass B wires the Keeper's Bench here. The cue fails safe if the file is missing.
	if has_node("/root/GameAudio"):
		GameAudio.play(&"sfx_bench_open")


func owns_forge_key() -> bool:
	if has_node("/root/GameState") and GameState.forge_key:
		return true
	if has_node("/root/Equipment") and Equipment.owns_anywhere("forge_key_relic"):
		return true
	return false


func can_enter_forge() -> bool:
	if not owns_forge_key() or not has_node("/root/GameState"):
		return false
	var stage: String = String(GameState.stage_id)
	return stage == "elder" or stage == "ancient"


func try_enter_forge() -> String:
	if has_node("/root/GameState") and GameState.is_world_frozen():
		return "denied"
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return "denied"
	if not can_enter_forge():
		return "denied"
	if _keeper_task_kind() == "water" or _keeper_task_kind() == "harvest":
		note_keeper_idle()
	return commit_actor_enter("keeper")


func travel_to_forge() -> String:
	## View switch. Walking through the door is what moves a character.
	if not has_node("/root/GameState") or not GameState.forge_visited:
		return try_enter_forge()
	if GameState.is_world_frozen() or (has_node("/root/EchoChamber") and EchoChamber.in_battle):
		return "denied"
	switch_view(true)
	return "entered"


func note_entered_forge() -> void:
	pass


func exit_forge() -> void:
	if has_node("/root/GameState") and GameState.is_world_frozen():
		return
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return
	if _keeper_station != "":
		set_keeper_working("", false)
	_return_to_clearing = true
	_play(&"sfx_door_bark")
	if has_node("/root/GameAudio"):
		GameAudio.set_forge_room_mix(false)
	if _allow_scene_change:
		if has_node("/root/SaveService"):
			SaveService.boot_intent = "forge_return"
		get_tree().change_scene_to_file(HUB_SCENE)


func take_clearing_return() -> bool:
	var pending: bool = _return_to_clearing
	_return_to_clearing = false
	return pending


func return_offset() -> Vector2:
	var raw: Variant = _tuning.get("return_offset", [-80, 354])
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	return Vector2(-80, 354)


func station_work_anim_speed() -> float:
	## data/forge_tuning.json station_work_anim_speed. Animation playback only.
	return maxf(0.05, float(_tuning.get("station_work_anim_speed", 0.5)))


func _tuning_vec(key: String, fallback: Vector2) -> Vector2:
	var raw: Variant = _tuning.get(key, [])
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	return fallback


func manatree_origin() -> Vector2:
	if get_tree() != null:
		var nodes: Array[Node] = get_tree().get_nodes_in_group("manatree")
		if not nodes.is_empty() and nodes[0] is Node2D:
			return (nodes[0] as Node2D).global_position
	return Vector2(2160, 2106)


func forge_arch_spawn() -> Vector2:
	return _tuning_vec("forge_arch_spawn", Vector2(800, 1048))


func clearing_door_stand() -> Vector2:
	return manatree_origin() + _tuning_vec("clearing_door_stand", Vector2(0, 28))


func elaia_join_stand() -> Vector2:
	return clearing_door_stand() + _tuning_vec("elaia_join_east", Vector2(84, 6))


func door_entry_point() -> Vector2:
	## Inside the sill trigger, closer than the care stand at clearing_door_stand.
	return manatree_origin() + Vector2(0, 8)


func wisp_work_radius(count: int) -> float:
	## Legacy count ramp. Orbits no longer use this; harvest rates never did.
	var base: float = float(_tuning.get("wisp_work_radius", 34.0))
	var step: float = float(_tuning.get("wisp_work_radius_step", 12.0))
	return base + step * float(maxi(0, count - 1))


func wisp_orbit_phase() -> float:
	return _wisp_orbit_phase


func debug_set_wisp_orbit_phase(phase: float) -> void:
	_wisp_orbit_phase = fposmod(phase, TAU)


func wisp_orbit_pad() -> float:
	return float(_tuning.get("wisp_orbit_pad", 14.0))


func wisp_orbit_radius_for_size(size: Vector2) -> float:
	## Half the footprint's long side, plus a data pad. Larger trunks orbit wider.
	var scale: float = float(_tuning.get("wisp_orbit_foot_scale", 0.5))
	return maxf(size.x, size.y) * scale + wisp_orbit_pad()


func station_supports_repeat(station_id: String) -> bool:
	return station_id == "crucible" or station_id == "mill" or station_id == "press"


func station_repeat_enabled(station_id: String) -> bool:
	if _repeat_override.has(station_id):
		return bool(_repeat_override[station_id])
	return bool(_station_def(station_id).get("auto_repeat", false))


func set_station_repeat(station_id: String, enabled: bool) -> void:
	if not station_supports_repeat(station_id):
		return
	_repeat_override[station_id] = enabled


func switch_view(to_forge: bool) -> void:
	## Scene and camera only. Does not move the Keeper, Elaia, or any Wisp.
	if has_node("/root/GameState") and GameState.is_world_frozen():
		return
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return
	_return_to_clearing = false
	_play(&"sfx_door_bark")
	if to_forge:
		if has_node("/root/GameAudio"):
			GameAudio.set_forge_room_mix(true, audio_lowpass_hz(), audio_reverb_room(), audio_music_db())
		if _allow_scene_change and get_tree() != null:
			get_tree().change_scene_to_file(FORGE_SCENE)
		return
	if has_node("/root/GameAudio"):
		GameAudio.set_forge_room_mix(false)
	if _allow_scene_change and get_tree() != null:
		get_tree().change_scene_to_file(HUB_SCENE)


func commit_actor_enter(actor_id: String) -> String:
	var spot: Vector2 = forge_arch_spawn()
	if has_node("/root/GameState"):
		if actor_id == "elaia":
			GameState.elaia_area = "forge"
			GameState.elaia_has_pos = true
			GameState.elaia_pos = spot
			GameState.elaia_facing = "north"
		else:
			GameState.keeper_area = "forge"
			GameState.keeper_has_pos = true
			GameState.keeper_pos = spot
			GameState.keeper_facing = "north"
		GameState.forge_visited = true
	_return_to_clearing = false
	_play(&"sfx_door_bark")
	if has_node("/root/GameAudio"):
		GameAudio.set_forge_room_mix(true, audio_lowpass_hz(), audio_reverb_room(), audio_music_db())
	if _allow_scene_change and get_tree() != null:
		get_tree().change_scene_to_file(FORGE_SCENE)
	return "entered"


func commit_actor_exit(actor_id: String) -> void:
	var spot: Vector2 = clearing_door_stand()
	if has_node("/root/GameState"):
		if actor_id == "elaia":
			GameState.elaia_area = "clearing"
			GameState.elaia_has_pos = true
			GameState.elaia_pos = spot
			GameState.elaia_facing = "south"
		else:
			GameState.keeper_area = "clearing"
			GameState.keeper_has_pos = true
			GameState.keeper_pos = spot
			GameState.keeper_facing = "south"
	switch_view(false)


func try_door_entry(actor_id: String) -> String:
	if has_node("/root/GameState") and GameState.is_world_frozen():
		return "denied"
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return "denied"
	var visited: bool = has_node("/root/GameState") and GameState.forge_visited
	if not visited and not can_enter_forge():
		return "denied"
	## Door entry changes the scene. It does not clear the job the hero was doing.
	return commit_actor_enter(actor_id)


func request_door_walk() -> String:
	## The selected hero walks into the sill. The other stays where they are.
	if not has_node("/root/GameState"):
		return "denied"
	var actor: String = GameState.selected_hero_id()
	if actor == "":
		actor = "keeper"
	var area: String = GameState.elaia_area if actor == "elaia" else GameState.keeper_area
	if area != "clearing" or in_forge_scene():
		return "away"
	var hero: Node = null
	if actor == "elaia":
		hero = get_tree().get_first_node_in_group("elaia") if get_tree() != null else null
	else:
		hero = get_tree().get_first_node_in_group("keeper") if get_tree() != null else null
	if hero == null or not hero.has_method("move_to"):
		return "denied"
	var dest: Vector2 = door_entry_point()
	if hero is Node2D and (hero as Node2D).global_position.distance_to(dest) <= 18.0:
		return try_door_entry(actor)
	hero.call("move_to", dest, null)
	return "walking"


func set_scene_changes_enabled(enabled: bool) -> void:
	_allow_scene_change = enabled


func set_in_forge_override(mode: int) -> void:
	_in_forge_override = mode


func in_forge_scene() -> bool:
	if _in_forge_override >= 0:
		return _in_forge_override == 1
	return get_tree() != null and get_tree().get_first_node_in_group("forge_room") != null


func wisp_should_show(assigned_node: String, in_forge: bool) -> bool:
	## Station Wisps stay in the Forge. Clearing jobs stay in the clearing.
	## Free Wisps follow the Keeper's area, not whichever scene the camera is showing.
	if is_forge_station(assigned_node):
		return in_forge
	if assigned_node != "":
		return not in_forge
	var keeper_in_forge: bool = has_node("/root/GameState") and GameState.keeper_area == "forge"
	return keeper_in_forge == in_forge


func set_keeper_task(kind: String, target: String, working: bool) -> void:
	_keeper_task = {"kind": kind, "target": target, "working": working}
	if working and target != "":
		_hero_claims["keeper"] = target
	if kind == "forge":
		_keeper_station = target if working else ""
		_keeper_working = working
	elif working:
		_keeper_station = ""
		_keeper_working = false


func note_keeper_idle() -> void:
	_keeper_working = false
	_keeper_station = ""
	_keeper_task = {"kind": "none", "target": "", "working": false}
	_hero_claims.erase("keeper")


func set_keeper_working(station_id: String, working: bool) -> void:
	if working and station_id != "":
		set_keeper_task("forge", station_id, true)
		return
	if station_id == "" or station_id == _keeper_station:
		if _keeper_task_kind() == "forge":
			note_keeper_idle()
		else:
			_keeper_working = false
			_keeper_station = ""


func set_keeper_present(station_id: String, present: bool) -> void:
	set_keeper_working(station_id, present)


func set_elaia_task(kind: String, target: String, working: bool) -> void:
	_elaia_task = {"kind": kind, "target": target, "working": working}
	if working and target != "":
		_hero_claims["elaia"] = target
	if kind == "forge":
		_elaia_station = target if working else ""
		_elaia_working = working
	elif working:
		_elaia_station = ""
		_elaia_working = false


func note_elaia_idle() -> void:
	_elaia_working = false
	_elaia_station = ""
	_elaia_task = {"kind": "none", "target": "", "working": false}
	_hero_claims.erase("elaia")


func set_elaia_working(station_id: String, working: bool) -> void:
	if working and station_id != "":
		set_elaia_task("forge", station_id, true)
		return
	if station_id == "" or station_id == _elaia_station:
		if str(_elaia_task.get("kind", "")) == "forge":
			note_elaia_idle()
		else:
			_elaia_working = false
			_elaia_station = ""


func elaia_task() -> Dictionary:
	return _elaia_task.duplicate(true)


func _tick_absent_elaia(delta: float) -> void:
	## Her body only simulates in the area she is standing in. The job keeps going in the other view.
	if delta <= 0.0 or not bool(_elaia_task.get("working", false)):
		return
	if not has_node("/root/GameState"):
		return
	if GameState.is_world_frozen() or GameState.fruit_committed:
		return
	if _elaia_body_simulating():
		return
	var kind: String = str(_elaia_task.get("kind", ""))
	var target: String = str(_elaia_task.get("target", ""))
	if kind == "harvest":
		var rid: StringName = _harvest_resource(target)
		if rid != &"":
			GameState.accumulate_keeper_harvest(rid, delta, GameState.actor_work_rate("elaia"))
	elif kind == "water":
		GameState.tick_hero_water("elaia", delta)


func _elaia_body_simulating() -> bool:
	return _hero_body_simulating("elaia")


func _tick_absent_keeper(delta: float) -> void:
	## His body only simulates in the area he is standing in. Water and harvest keep paying in the other view.
	if delta <= 0.0 or not bool(_keeper_task.get("working", false)):
		return
	if not has_node("/root/GameState"):
		return
	if GameState.is_world_frozen() or GameState.fruit_committed:
		return
	if _keeper_body_simulating():
		return
	var kind: String = str(_keeper_task.get("kind", ""))
	var target: String = str(_keeper_task.get("target", ""))
	if kind == "harvest":
		var rid: StringName = _harvest_resource(target)
		if rid != &"":
			GameState.accumulate_keeper_harvest(rid, delta, GameState.actor_work_rate("keeper"))
	elif kind == "water":
		GameState.tick_hero_water("keeper", delta)


func _keeper_body_simulating() -> bool:
	return _hero_body_simulating("keeper")


func _hero_body_simulating(group_name: String) -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var node: Node = tree.get_first_node_in_group(group_name)
	return node != null and node.visible and node.is_physics_processing()


func claim_hero_target(actor: String, key: String) -> void:
	if actor == "" or key == "":
		return
	_hero_claims[actor] = key


func release_hero_claim(actor: String) -> void:
	_hero_claims.erase(actor)


func hero_claim(actor: String) -> String:
	return str(_hero_claims.get(actor, ""))


func hero_block_name(asker: String, key: String) -> String:
	## Empty when the target is free. Wisps never block a hero.
	if key == "":
		return ""
	for other: String in ["keeper", "elaia"]:
		if other == asker:
			continue
		if str(_hero_claims.get(other, "")) == key:
			return _hero_name(other)
		var task: Dictionary = _keeper_task if other == "keeper" else _elaia_task
		if bool(task.get("working", false)) and str(task.get("target", "")) == key:
			return _hero_name(other)
	return ""


func _hero_name(actor: String) -> String:
	if has_node("/root/GameState"):
		return GameState.hero_display_name(actor)
	if actor == "keeper":
		return "The Keeper"
	return "Elaia"


func set_companion_working(station_id: String, companion_id: String, working: bool) -> void:
	## Hook only. No companion UI, and player copy never says companion.
	if working and companion_id != "":
		_companions[station_id] = companion_id
	else:
		_companions.erase(station_id)


func keeper_task() -> Dictionary:
	return _keeper_task.duplicate(true)


func try_begin_job(station_id: String, recipe_id: String) -> String:
	if not is_forge_station(station_id):
		return "invalid"
	if _jobs.has(station_id):
		_play(&"sfx_wisp_deny")
		return "busy"
	var recipe: Dictionary = _recipe(recipe_id)
	if recipe.is_empty() or str(recipe.get("station", "")) != station_id:
		return "invalid"
	var output: String = str(recipe.get("output", ""))
	if bool(recipe.get("output_gear", false)) and has_node("/root/Equipment"):
		if Equipment.is_unique_item(output) and Equipment.owns_anywhere(output):
			return "owned"
	if not _can_pay(recipe):
		return "cant_afford"
	_pay(recipe)
	_jobs[station_id] = {
		"recipe_id": recipe_id,
		"progress": 0.0,
		"duration": _duration(recipe),
	}
	if in_forge_scene():
		_play(&"sfx_forge_craft_start")
		if station_id == "press":
			_play(&"sfx_press_squeeze")
	return "ok"


func has_job(station_id: String) -> bool:
	return _jobs.has(station_id)


func job_progress(station_id: String) -> float:
	if not _jobs.has(station_id):
		return 0.0
	return float((_jobs[station_id] as Dictionary).get("progress", 0.0))


func job_recipe(station_id: String) -> String:
	if not _jobs.has(station_id):
		return ""
	return str((_jobs[station_id] as Dictionary).get("recipe_id", ""))


func job_state(station_id: String) -> Dictionary:
	## One snapshot for the world bar, the station panel, and the selection HUD.
	if not _jobs.has(station_id):
		return {}
	var job: Dictionary = _jobs[station_id]
	var duration: float = maxf(float(job.get("duration", 1.0)), 0.05)
	var progress: float = clampf(float(job.get("progress", 0.0)), 0.0, duration)
	var speed: float = station_speed_mult(station_id)
	var remain_work: float = maxf(duration - progress, 0.0)
	var remain: float = remain_work / speed if speed > 0.0 else remain_work
	var recipe_id: String = str(job.get("recipe_id", ""))
	return {
		"recipe_id": recipe_id,
		"name": _item_label(recipe_output_id(recipe_id)),
		"progress": progress,
		"duration": duration,
		"fraction": clampf(progress / duration, 0.0, 1.0),
		"speed": speed,
		"remaining_sec": remain,
		"remaining_text": format_clock(remain),
		"working": speed > 0.0,
	}


func job_line(station_id: String) -> String:
	var state: Dictionary = job_state(station_id)
	if state.is_empty():
		return ""
	var pct: int = int(round(clampf(float(state.get("fraction", 0.0)), 0.0, 1.0) * 100.0))
	return "%s  %d%%  %s" % [str(state.get("name", "")), pct, str(state.get("remaining_text", ""))]


func format_clock(seconds: float) -> String:
	var total: int = maxi(0, int(ceil(maxf(seconds, 0.0) - 0.0001)))
	return "%d:%02d" % [int(total / 60.0), total % 60]


func station_speed_mult(station_id: String) -> float:
	## Additive. Keeper and a companion each count 1. Each Wisp counts 0.1, capped at 4.
	## Displayed job time stays the recipe base. Actual time is base / this sum.
	if has_node("/root/GameState") and GameState.fruit_committed:
		return 0.0
	var speed: float = 0.0
	if _keeper_working and _keeper_station == station_id:
		speed += float(_tuning.get("keeper_speed", 1.0))
	if _elaia_working and _elaia_station == station_id:
		var elaia_rate: float = 0.8
		if has_node("/root/GameState"):
			elaia_rate = GameState.actor_work_rate("elaia", station_id)
		speed += elaia_rate
	if str(_companions.get(station_id, "")) != "":
		speed += float(_tuning.get("companion_speed", 1.0))
	var wisps: int = mini(_wisps_on(station_id), wisp_cap())
	speed += float(_tuning.get("wisp_speed", 0.1)) * float(wisps)
	return speed


func station_speed_text(mult: float) -> String:
	if absf(mult - roundf(mult)) < 0.001:
		return "%dx" % int(roundf(mult))
	return "%.1fx" % mult


func station_is_busy(station_id: String) -> bool:
	return has_job(station_id) and station_speed_mult(station_id) > 0.0


func station_badge(station_id: String) -> String:
	var state: Dictionary = job_state(station_id)
	if state.is_empty():
		return ""
	var speed: float = float(state.get("speed", 0.0))
	if speed <= 0.0:
		return copy_text("station_paused")
	var pct: int = int(clampf(float(state.get("fraction", 0.0)), 0.0, 1.0) * 100.0)
	return "%s %d%%  %s" % [copy_text("station_busy"), pct, station_speed_text(speed)]


func advance_seconds(seconds: float) -> void:
	if seconds <= 0.0:
		return
	if has_node("/root/GameState") and GameState.is_world_frozen():
		return
	for station_id: String in STATION_IDS:
		if not _jobs.has(station_id):
			continue
		var mult: float = station_speed_mult(station_id)
		if mult <= 0.0:
			continue
		var job: Dictionary = _jobs[station_id]
		job["progress"] = float(job.get("progress", 0.0)) + seconds * mult
		var guard: int = 0
		while _jobs.has(station_id) and float((_jobs[station_id] as Dictionary).get("progress", 0.0)) >= float((_jobs[station_id] as Dictionary).get("duration", 1.0)):
			guard += 1
			if guard > MAX_COMPLETIONS:
				break
			if not _complete_job(station_id):
				break


func offline_effective_seconds(closed_sec: float) -> float:
	if has_node("/root/GameState"):
		return GameState.offline_effective_seconds(closed_sec)
	return 0.0


func apply_offline_seconds(closed_sec: float) -> Dictionary:
	## Fresh-curve closure. Tests and callers that pass a wall-clock gap from zero use this.
	if closed_sec <= 0.0 or _offline_blocked():
		return _empty_offline()
	return _grant_offline(offline_effective_seconds(closed_sec))


func apply_saved_offline_gap(gap_sec: float) -> Dictionary:
	## Load path. Continues the curve unless this session already played offline_reset_active_sec.
	if gap_sec <= 0.0 or not has_node("/root/GameState"):
		return _empty_offline()
	var eff: float = GameState.commit_offline_gap(gap_sec)
	if eff <= 0.0:
		return _empty_offline()
	return _grant_offline(eff)


func _offline_blocked() -> bool:
	if not has_node("/root/GameState"):
		return false
	return GameState.fruit_committed or GameState.stage_id == &"ancient"


func _empty_offline() -> Dictionary:
	return {
		"effective_sec": 0.0,
		"shards": 0,
		"essence": 0,
		"harvest": 0,
		"forge_completed": 0,
	}


func _grant_offline(eff: float) -> Dictionary:
	var result: Dictionary = _empty_offline()
	if eff <= 0.0 or _offline_blocked():
		return result
	result["effective_sec"] = eff
	var was_silent: bool = _silent
	_silent = true
	var keeper_was: bool = _keeper_working
	var keeper_station_was: String = _keeper_station
	if bool(_keeper_task.get("working", false)):
		var kind: String = _keeper_task_kind()
		if kind == "water":
			var water: Dictionary = _offline_water(eff)
			result["shards"] = int(water.get("shards", 0))
			result["essence"] = int(water.get("essence", 0))
		elif kind == "harvest":
			result["harvest"] = _offline_harvest(eff, str(_keeper_task.get("target", "")))
		elif kind == "forge":
			var station: String = str(_keeper_task.get("target", ""))
			if is_forge_station(station):
				_keeper_station = station
				_keeper_working = true
	if bool(_elaia_task.get("working", false)):
		var elaia_kind: String = str(_elaia_task.get("kind", ""))
		var elaia_rate: float = 0.8
		if has_node("/root/GameState"):
			elaia_rate = GameState.actor_work_rate("elaia", str(_elaia_task.get("target", "")) if elaia_kind == "forge" else "")
		if elaia_kind == "water":
			var elaia_water: Dictionary = _offline_water(eff, GameState.actor_water_mult("elaia") if has_node("/root/GameState") else elaia_rate)
			result["shards"] = int(result.get("shards", 0)) + int(elaia_water.get("shards", 0))
			result["essence"] = int(result.get("essence", 0)) + int(elaia_water.get("essence", 0))
		elif elaia_kind == "harvest":
			result["harvest"] = int(result.get("harvest", 0)) + _offline_harvest(eff, str(_elaia_task.get("target", "")), elaia_rate)
		elif elaia_kind == "forge":
			var elaia_station: String = str(_elaia_task.get("target", ""))
			if is_forge_station(elaia_station):
				_elaia_station = elaia_station
				_elaia_working = true
	result["forge_completed"] = _count_after_advance(eff)
	_offline_wisp_grants(eff, result)
	_silent = was_silent
	_keeper_working = false
	_keeper_station = ""
	_keeper_task["working"] = false
	_elaia_working = false
	_elaia_station = ""
	_elaia_task["working"] = false
	_hero_claims.clear()
	if keeper_was and keeper_station_was != "" and _keeper_task_kind() == "forge":
		pass
	_queue_offline_toast(result)
	return result


func ascend_warning() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if GameState.get_upgrade_rank("keep_forge_intermediates") <= 0:
		parts.append(copy_text("ascend_warning_materials"))
	if GameState.get_upgrade_rank("keep_forge_jobs") <= 0:
		parts.append(copy_text("ascend_warning_jobs"))
	return " ".join(parts)


func prepare_ascend() -> Dictionary:
	var snap: Dictionary = {}
	for mat: String in _forge_materials():
		if has_node("/root/Backpack"):
			snap[mat] = Backpack.get_count(mat)
	if GameState.get_upgrade_rank("keep_forge_jobs") <= 0:
		_jobs.clear()
	_companions.clear()
	note_keeper_idle()
	note_elaia_idle()
	_materials_snapshot = snap
	return snap


func finish_ascend(snap: Dictionary) -> void:
	if GameState.get_upgrade_rank("keep_forge_intermediates") <= 0:
		return
	if not has_node("/root/Backpack"):
		return
	for key: Variant in snap.keys():
		Backpack.set_count(str(key), int(snap[key]))


func capture_save_fields() -> Dictionary:
	return {
		"forge_jobs": _jobs.duplicate(true),
		"forge_workers": _workers_blob(),
		"keeper_task": _keeper_task.duplicate(true),
		"elaia_task": _elaia_task.duplicate(true),
		"idle_timestamp": Time.get_unix_time_from_system(),
		"item_categories": item_categories(),
		"station_repeat": _repeat_override.duplicate(true),
	}


func apply_save_fields(data: Dictionary) -> void:
	var jobs_v: Variant = data.get("forge_jobs", {})
	_jobs = (jobs_v as Dictionary).duplicate(true) if typeof(jobs_v) == TYPE_DICTIONARY else {}
	var workers_v: Variant = data.get("forge_workers", {})
	_apply_workers(workers_v if typeof(workers_v) == TYPE_DICTIONARY else {})
	var task_v: Variant = data.get("keeper_task", {})
	if typeof(task_v) == TYPE_DICTIONARY:
		var task: Dictionary = task_v
		_keeper_task = {
			"kind": str(task.get("kind", "none")),
			"target": str(task.get("target", "")),
			"working": bool(task.get("working", false)),
		}
	else:
		note_keeper_idle()
	if bool(_keeper_task.get("working", false)) and _keeper_task_kind() == "forge":
		_keeper_station = str(_keeper_task.get("target", ""))
		_keeper_working = true
	else:
		_keeper_working = false
		if _keeper_task_kind() != "forge":
			_keeper_station = ""
	var elaia_v: Variant = data.get("elaia_task", {})
	if typeof(elaia_v) == TYPE_DICTIONARY:
		var elaia_task: Dictionary = elaia_v
		_elaia_task = {
			"kind": str(elaia_task.get("kind", "none")),
			"target": str(elaia_task.get("target", "")),
			"working": bool(elaia_task.get("working", false)),
		}
	else:
		note_elaia_idle()
	if bool(_elaia_task.get("working", false)) and str(_elaia_task.get("kind", "")) == "forge":
		_elaia_station = str(_elaia_task.get("target", ""))
		_elaia_working = true
	else:
		_elaia_working = false
		if str(_elaia_task.get("kind", "")) != "forge":
			_elaia_station = ""
	_hero_claims.clear()
	if bool(_keeper_task.get("working", false)):
		_hero_claims["keeper"] = str(_keeper_task.get("target", ""))
	if bool(_elaia_task.get("working", false)):
		_hero_claims["elaia"] = str(_elaia_task.get("target", ""))
	var repeat_v: Variant = data.get("station_repeat", {})
	_repeat_override = (repeat_v as Dictionary).duplicate(true) if typeof(repeat_v) == TYPE_DICTIONARY else {}


func reset_for_new_game() -> void:
	_jobs.clear()
	_companions.clear()
	note_keeper_idle()
	note_elaia_idle()
	_pending_toast = ""
	_return_to_clearing = false
	_materials_snapshot.clear()
	_repeat_override.clear()


func take_offline_toast() -> String:
	var text: String = _pending_toast
	_pending_toast = ""
	return text


func _complete_job(station_id: String) -> bool:
	if not _jobs.has(station_id):
		return false
	var job: Dictionary = _jobs[station_id]
	var recipe: Dictionary = _recipe(str(job.get("recipe_id", "")))
	var duration: float = maxf(float(job.get("duration", 1.0)), 0.05)
	_grant_output(recipe)
	_play_completion(station_id, recipe)
	var repeat: bool = station_repeat_enabled(station_id)
	var still: bool = _someone_working(station_id)
	if repeat and still and _can_pay(recipe):
		_pay(recipe)
		job["progress"] = float(job.get("progress", 0.0)) - duration
		return true
	_jobs.erase(station_id)
	return false


func _grant_output(recipe: Dictionary) -> void:
	var output: String = str(recipe.get("output", ""))
	if output == "":
		return
	if bool(recipe.get("output_gear", false)):
		var granted: bool = false
		if has_node("/root/Equipment"):
			granted = Equipment.add_gear(output, 1)
		if granted and str(recipe.get("category", "")) == "relic" and has_node("/root/GameState"):
			GameState.note_first_relic_crafted()
		return
	if has_node("/root/Backpack"):
		Backpack.add_item(output, 1)
	if not _silent and has_node("/root/GameState"):
		GameState.status_message.emit(copy_text("job_done", {"item": output.capitalize().replace("_", " ")}))


func _play_completion(station_id: String, _recipe: Dictionary) -> void:
	if _silent:
		return
	if station_id == "anvil" or station_id == "reliquary":
		_play_big_done()
		return
	if not in_forge_scene():
		return
	if has_node("/root/GameAudio"):
		GameAudio.play_quiet(&"sfx_forge_craft_done", float(_tuning.get("upcycle_tick_db", -8.0)))


func _play_big_done() -> void:
	var now: int = Time.get_ticks_msec()
	var gap: int = int(float(_tuning.get("big_done_min_interval_sec", 3.0)) * 1000.0)
	if now - _last_big_done_msec < gap:
		return
	_last_big_done_msec = now
	_play(&"sfx_forge_big_done")


func _play(cue: StringName) -> void:
	if _silent or not has_node("/root/GameAudio"):
		return
	GameAudio.play(cue)


func _someone_working(station_id: String) -> bool:
	if _keeper_working and _keeper_station == station_id:
		return true
	if _elaia_working and _elaia_station == station_id:
		return true
	if str(_companions.get(station_id, "")) != "":
		return true
	return _wisps_on(station_id) > 0


func _wisps_on(station_id: String) -> int:
	if not has_node("/root/GameState"):
		return 0
	return GameState.count_wisps_on_node(station_id)


func _can_pay(recipe: Dictionary) -> bool:
	var inputs: Dictionary = _inputs(recipe)
	for key: Variant in inputs.keys():
		var need: int = int(inputs[key])
		if need <= 0:
			continue
		if _have(str(key)) < need:
			return false
	return true


func _pay(recipe: Dictionary) -> void:
	var inputs: Dictionary = _inputs(recipe)
	for key: Variant in inputs.keys():
		var need: int = int(inputs[key])
		if need > 0:
			_spend(str(key), need)


func _have(item_id: String) -> int:
	if RESOURCE_IDS.has(item_id) and has_node("/root/GameState"):
		return GameState.get_resource(StringName(item_id))
	if has_node("/root/Backpack") and Backpack.is_known_item(item_id):
		return Backpack.get_count(item_id)
	return 0


func _spend(item_id: String, amount: int) -> void:
	if RESOURCE_IDS.has(item_id) and has_node("/root/GameState"):
		GameState.add_resource(StringName(item_id), -amount)
		return
	if has_node("/root/Backpack"):
		Backpack.try_spend(item_id, amount)


func _inputs(recipe: Dictionary) -> Dictionary:
	var raw: Variant = recipe.get("inputs", {})
	return (raw as Dictionary) if typeof(raw) == TYPE_DICTIONARY else {}


func _duration(recipe: Dictionary) -> float:
	return maxf(float(recipe.get("duration_sec", 1.0)), 0.05)


func _recipe(recipe_id: String) -> Dictionary:
	var all: Dictionary = _recipes()
	var found: Variant = all.get(recipe_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func _recipes() -> Dictionary:
	var raw: Variant = _tuning.get("recipes", {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


func _station_def(station_id: String) -> Dictionary:
	var all: Variant = _tuning.get("stations", {})
	if typeof(all) != TYPE_DICTIONARY:
		return {}
	var found: Variant = (all as Dictionary).get(station_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func _forge_materials() -> PackedStringArray:
	var raw: Variant = _tuning.get("forge_materials", [])
	var out: PackedStringArray = PackedStringArray()
	if typeof(raw) == TYPE_ARRAY:
		for entry: Variant in raw:
			out.append(str(entry))
	return out


func _keeper_task_kind() -> String:
	return str(_keeper_task.get("kind", "none"))


func _offline_water(eff: float, reward_mult: float = 1.0) -> Dictionary:
	## Same pulse as online watering. No extra offline multiplier and no stage multiplier.
	var pulse: float = maxf(GameState.get_channel_pulse_sec(), 0.05)
	var pulses: int = int(floor(eff / pulse))
	if pulses <= 0:
		return {"shards": 0, "essence": 0}
	var shard_min: int = GameState.param_int("WATER_SHARD_MIN", 1)
	var shard_max: int = GameState.param_int("WATER_SHARD_MAX", 3)
	var mid: float = (float(shard_min) + float(shard_max)) * 0.5
	var roll: float = (mid + GameState.get_effect_total("water_shard_bonus")) * float(GameState.get_water_shard_roll_mult())
	var shard_units: float = roll * float(pulses) * reward_mult
	var shards: int = GameState.accumulate_harvest(&"manashards", shard_units)
	var essence: int = 0
	if is_equal_approx(reward_mult, 1.0):
		essence = int(floor(float(GameState.get_water_essence_amount()) * float(pulses)))
	else:
		var ess_units: float = float(GameState.get_water_essence_amount()) * float(pulses) * reward_mult
		GameState.elaia_water_essence_frac += ess_units
		essence = int(floor(GameState.elaia_water_essence_frac))
		GameState.elaia_water_essence_frac -= float(essence)
	if shards > 0:
		GameState.lifetime_shards_from_water += shards
	if essence > 0:
		GameState.add_resource(&"essence", essence)
		GameState.lifetime_essence_from_water += essence
	GameState.lifetime_waters += pulses
	return {"shards": shards, "essence": essence}


func _offline_harvest(eff: float, target: String, rate: float = 1.0) -> int:
	var rid: StringName = _harvest_resource(target)
	if rid == &"":
		return 0
	return GameState.apply_offline_keeper_harvest(eff, rid, rate)


func _harvest_resource(target: String) -> StringName:
	if target in ["wood", "stone", "food"]:
		return StringName(target)
	var mapped: StringName = GameState.resource_for_node_id(target)
	if mapped in GameState.HARVEST_IDS:
		return mapped
	return &""


func _offline_wisp_grants(eff: float, result: Dictionary) -> void:
	if not has_node("/root/GameState") or eff <= 0.0:
		return
	for i: int in range(GameState.wisp_count):
		var nid: String = GameState.get_wisp_assignment(i)
		if nid == "" or is_forge_station(nid):
			continue
		var rid: StringName = GameState.resource_for_node_id(nid)
		if rid == &"":
			continue
		var amount: int = GameState.apply_offline_wisp_harvest(eff, rid)
		if rid == &"manashards":
			result["shards"] = int(result.get("shards", 0)) + amount


func _count_after_advance(eff: float) -> int:
	var before: Dictionary = {}
	for mat: String in _forge_materials():
		before[mat] = Backpack.get_count(mat) if has_node("/root/Backpack") else 0
	var gear_before: int = _gear_count()
	advance_seconds(eff)
	var gained: int = 0
	for mat: String in _forge_materials():
		var now: int = Backpack.get_count(mat) if has_node("/root/Backpack") else 0
		gained += maxi(0, now - int(before.get(mat, 0)))
	gained += maxi(0, _gear_count() - gear_before)
	return gained


func _gear_count() -> int:
	if not has_node("/root/Equipment"):
		return 0
	var n: int = 0
	for recipe_key: Variant in _recipes().keys():
		var recipe: Dictionary = _recipe(str(recipe_key))
		if not bool(recipe.get("output_gear", false)):
			continue
		n += Equipment.gear_count_anywhere(str(recipe.get("output", "")))
	return n


func _queue_offline_toast(result: Dictionary) -> void:
	var bits: PackedStringArray = PackedStringArray()
	if int(result.get("shards", 0)) > 0:
		bits.append("+%d Manashards" % int(result.get("shards", 0)))
	if int(result.get("essence", 0)) > 0:
		bits.append("+%d Essence" % int(result.get("essence", 0)))
	if int(result.get("harvest", 0)) > 0:
		bits.append("+%d gathered" % int(result.get("harvest", 0)))
	if int(result.get("forge_completed", 0)) > 0:
		bits.append("%d Forge goods" % int(result.get("forge_completed", 0)))
	if bits.is_empty():
		return
	var text: String = copy_text("jobs_finished_away", {"summary": ", ".join(bits)})
	_pending_toast = text
	if get_tree() != null and get_tree().get_first_node_in_group("game_hud") != null:
		GameState.status_message.emit(text)
		_pending_toast = ""


func _workers_blob() -> Dictionary:
	var out: Dictionary = {}
	for station_id: String in STATION_IDS:
		var wisps: Array = []
		if has_node("/root/GameState"):
			for i: int in range(GameState.wisp_count):
				if GameState.get_wisp_assignment(i) == station_id:
					wisps.append(i)
		var keeper_here: bool = _keeper_working and _keeper_station == station_id
		var companion: String = str(_companions.get(station_id, ""))
		if not keeper_here and companion == "" and wisps.is_empty():
			continue
		out[station_id] = {
			"keeper": keeper_here,
			"companion": companion,
			"wisps": wisps,
		}
	return out


func _apply_workers(workers: Dictionary) -> void:
	_companions.clear()
	_keeper_working = false
	_keeper_station = ""
	for key: Variant in workers.keys():
		var station_id: String = str(key)
		var row_v: Variant = workers[key]
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_v
		var companion: String = str(row.get("companion", ""))
		if companion != "":
			_companions[station_id] = companion
		if bool(row.get("keeper", false)):
			_keeper_station = station_id
			_keeper_working = true
