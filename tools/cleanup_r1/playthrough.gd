extends SceneTree
## Cleanup R1 play-through. Report only: prints PLAY lines and writes 1280x720 captures.
## godot --path . --rendering-method gl_compatibility -s res://tools/cleanup_r1/playthrough.gd

const OUT_DIR: String = "res://tools/cleanup_r1/captures"
const CAP_W: int = 1280
const CAP_H: int = 720


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_setup_window()
	_logic_checks()
	await _capture_title()
	await _capture_hub()
	_art_probe()
	print("PLAYTHROUGH_DONE")
	quit(0)


func _setup_window() -> void:
	root.size = Vector2i(CAP_W, CAP_H)
	DisplayServer.window_set_size(Vector2i(CAP_W, CAP_H))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	root.content_scale_size = Vector2i(CAP_W, CAP_H)
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST


func _logic_checks() -> void:
	var gs: Node = root.get_node("GameState")
	var save_service: Node = root.get_node("SaveService")
	var audio: Node = root.get_node("GameAudio")
	var strings: Node = root.get_node("ContentStrings")
	print("PLAY SAVE_VERSION %d" % int(save_service.get("SAVE_VERSION")))
	var v15: Dictionary = {
		"stage_id": "elder",
		"elaia_joined": true,
		"moss_tortoise_joined": true,
		"keeper_stats": {"might": 2},
	}
	var migrated: Dictionary = save_service.call("migrate_state", 15, v15)
	var comps_v: Variant = migrated.get("companions", {})
	var comps: Dictionary = comps_v if typeof(comps_v) == TYPE_DICTIONARY else {}
	var stats_v: Variant = migrated.get("keeper_stats", {})
	var ranks_v: Variant = (stats_v as Dictionary).get("ranks_by_actor", {}) if typeof(stats_v) == TYPE_DICTIONARY else {}
	print("PLAY V15_MIGRATE companions %s ranks %s" % [str(comps.keys()), str(ranks_v)])
	print("PLAY V15_HAS puff %s mossback %s elaia %s" % [comps.has("puff"), comps.has("mossback"), comps.has("elaia")])
	var gaps: Array[float] = [60.0, 119.0, 600.0, 1800.0, 7200.0, 28800.0, 86400.0, 172800.0]
	var expect: Array[float] = [60.0, 119.0, 300.0, 600.0, 1200.0, 2400.0, 3600.0, 4200.0]
	for i: int in gaps.size():
		var got: float = float(gs.call("offline_effective_seconds", gaps[i]))
		print("PLAY OFFLINE closed %.0f eff %.2f expect %.0f match %s" % [gaps[i], got, expect[i], str(is_equal_approx(got, expect[i]))])
	print("PLAY PANEL_MIN %s" % str(gs.get("OFFLINE_PANEL_MIN_SEC")))
	gs.call("reset_for_new_game")
	gs.call("_set_stage", &"sapling")
	print("PLAY JOIN sapling puff %s" % str(gs.call("companion_joined", "puff")))
	gs.call("_set_stage", &"elder")
	print("PLAY JOIN elder puff %s mossback %s" % [str(gs.call("companion_joined", "puff")), str(gs.call("companion_joined", "mossback"))])
	var reach: Node = root.get_node("Reach")
	reach.call("debug_set_reaches_cleared", 1)
	print("PLAY JOIN briarwood1 mossback %s" % str(gs.call("companion_joined", "mossback")))
	print("PLAY PUFF_PARTY_FLAG %s" % str(gs.call("puff_in_party_active")))
	var speeds: PackedStringArray = PackedStringArray()
	for _s: int in 4:
		var step: int = int(gs.call("cycle_play_speed"))
		speeds.append("%d:%.2f" % [step, float(gs.call("play_speed_scale"))])
	print("PLAY SPEEDS %s" % " ".join(speeds))
	var depart_idle: String = str(reach.call("depart", 1, 1.0, "", "idle"))
	print("PLAY IDLE_DEPART %s phase %s" % [depart_idle, str(reach.get("phase"))])
	if depart_idle == "ok":
		reach.call("debug_force_outcomes", ["overwhelmed"])
		var catch: Dictionary = reach.call("catch_up", 720.0, "play")
		print("PLAY IDLE_FAIL catch %s phase %s room_left %.0f" % [str(catch), str(reach.get("phase")), float(reach.get("room_left"))])
		reach.call("debug_finish_run", "finished")
	var depart_manual: String = str(reach.call("depart", 1, 1.0, "", "manual"))
	print("PLAY MANUAL_DEPART %s fight %s" % [depart_manual, str(reach.call("fight_active"))])
	if bool(reach.call("fight_active")):
		reach.call("on_manual_outcome", "win")
		print("PLAY MANUAL_AFTER_WIN phase %s" % str(reach.get("phase")))
		reach.call("debug_finish_run", "finished")
	_audio_scan(audio)
	_string_scan(strings)
	_data_flags()


func _audio_scan(audio: Node) -> void:
	var file: FileAccess = FileAccess.open("res://data/audio_cues.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text() if file != null else "")
	if file != null:
		file.close()
	var cues: Dictionary = {}
	if typeof(parsed) == TYPE_DICTIONARY:
		var raw: Variant = (parsed as Dictionary).get("cues", {})
		if typeof(raw) == TYPE_DICTIONARY:
			cues = raw
	var watched: PackedStringArray = PackedStringArray([
		"sfx_gather_water_soft", "sfx_water_pulse", "mus_title", "sfx_ui_hover",
		"sfx_gather_manashards", "sfx_gather_cooldown", "sfx_footstep", "sfx_interact_arrive",
	])
	var sources: PackedStringArray = _gd_sources("res://scripts")
	sources.append_array(_gd_sources("res://tools"))
	var blob: String = "\n".join(sources)
	for id: String in watched:
		var in_table: bool = cues.has(id)
		var path: String = ""
		if in_table and typeof(cues[id]) == TYPE_DICTIONARY:
			path = str((cues[id] as Dictionary).get("path", ""))
		var file_ok: bool = path != "" and FileAccess.file_exists(path)
		var refs: int = blob.count("\"%s\"" % id) + blob.count("&\"%s\"" % id)
		print("PLAY CUE %s table %s file %s gd_refs %d path %s" % [id, str(in_table), str(file_ok), refs, path])
	var missing_files: int = 0
	var cue_ids: PackedStringArray = audio.call("list_cue_ids")
	for id_v: String in cue_ids:
		var row_v: Variant = cues.get(id_v, {})
		if typeof(row_v) != TYPE_DICTIONARY:
			missing_files += 1
			print("PLAY CUE_NO_ROW %s" % id_v)
			continue
		var cue_path: String = str((row_v as Dictionary).get("path", ""))
		if cue_path == "" or not FileAccess.file_exists(cue_path):
			missing_files += 1
			print("PLAY CUE_FILE_MISSING %s %s" % [id_v, cue_path])
	print("PLAY CUE_COUNT %d missing_files %d" % [cue_ids.size(), missing_files])
	print("PLAY TITLE_MUS_CALL %s" % str(blob.find("mus_title") >= 0))
	print("PLAY HUB_MUSIC_CALL %s" % str(blob.find("mus_hub_forest") >= 0))
	print("PLAY WATER_PULSE_CALL %s" % str(blob.find("sfx_water_pulse") >= 0))
	print("PLAY GATHER_WATER_SOFT_CALL %s" % str(blob.find("sfx_gather_water_soft") >= 0))


func _gd_sources(root_path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	_walk_gd(root_path, out)
	return out


func _walk_gd(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if name != "." and name != ".." and not name.ends_with(".uid"):
			var full: String = dir_path.path_join(name)
			if dir.current_is_dir():
				_walk_gd(full, out)
			elif name.ends_with(".gd"):
				var f: FileAccess = FileAccess.open(full, FileAccess.READ)
				if f != null:
					out.append(f.get_as_text())
					f.close()
		name = dir.get_next()
	dir.list_dir_end()


func _string_scan(strings: Node) -> void:
	for key: String in ["board_who_stands", "sim_forecast_note", "touch_box_select_button"]:
		var shown: String = str(strings.call("get_text", key))
		print("PLAY STRING %s => %s raw_id %s" % [key, shown, str(shown == key)])
	var touch_was: bool = false
	if root.get_node_or_null("GameInput") != null and root.get_node("GameInput").has_method("set_touch_mode"):
		touch_was = bool(root.get_node("GameInput").call("touch_mode"))
		root.get_node("GameInput").call("set_touch_mode", true)
		print("PLAY STRING_TOUCH touch_box_select_button => %s" % str(strings.call("get_text", "touch_box_select_button")))
		root.get_node("GameInput").call("set_touch_mode", touch_was)


func _data_flags() -> void:
	var forge: Dictionary = _json("res://data/forge_tuning.json")
	var fruit: Dictionary = _json("res://data/fruit_upgrades.json")
	var forge_hit: bool = JSON.stringify(forge).find("keep_forge_jobs") >= 0
	var fruit_hit: bool = JSON.stringify(fruit).find("keep_forge_jobs") >= 0
	print("PLAY KEEP_FORGE_JOBS forge_tuning %s fruit_upgrades %s" % [str(forge_hit), str(fruit_hit)])
	var spawns: Dictionary = _json("res://data/spawn_tables.json")
	var loot_v: Variant = spawns.get("loot", {})
	var status: String = ""
	if typeof(loot_v) == TYPE_DICTIONARY:
		status = str((loot_v as Dictionary).get("status", ""))
	print("PLAY LOOT_STATUS %s" % status)
	var comps: Dictionary = _json("res://data/companions.json")
	var puff: Dictionary = comps.get("puff", {}) as Dictionary
	var moss: Dictionary = comps.get("mossback", {}) as Dictionary
	print("PLAY COMPANION_JOIN puff %s mossback %s cap %s" % [str(puff.get("join", {})), str(moss.get("join", {})), str(comps.get("party_cap", -1))])
	var clips: Dictionary = ((puff.get("anim", {}) as Dictionary).get("clips", {}) as Dictionary)
	print("PLAY PUFF_CLIPS %s" % str(clips.keys()))


func _json(path: String) -> Dictionary:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _capture_title() -> void:
	var packed: PackedScene = load("res://scenes/title_screen.tscn") as PackedScene
	if packed == null:
		print("PLAY CAPTURE_FAIL title")
		return
	var title: Node = packed.instantiate()
	root.add_child(title)
	current_scene = title
	for _i: int in 8:
		await process_frame
	await _shot(title, "01_title.png")
	var save_service: Node = root.get_node("SaveService")
	var made_slot: bool = false
	if not bool(save_service.call("has_save")):
		save_service.call("note_session_started")
		made_slot = bool(save_service.call("save_game", 7))
		save_service.call("save_autosave", true)
		if title.has_method("_refresh_save_info"):
			title.call("_refresh_save_info")
		var cont_live: Button = title.get_node_or_null("Menu/BtnContinue") as Button
		if cont_live != null:
			cont_live.visible = bool(save_service.call("has_save"))
		for _sv: int in 2:
			await process_frame
		await _shot(title, "01b_title_with_save.png")
	var cont: Button = title.get_node_or_null("Menu/BtnContinue") as Button
	print("PLAY TITLE_CONTINUE visible %s disabled %s text %s has_save %s wrote %s" % [
		str(cont.visible if cont != null else false),
		str(cont.disabled if cont != null else true),
		cont.text if cont != null else "",
		str(save_service.call("has_save")),
		str(made_slot),
	])
	var info: Label = title.get_node_or_null("Menu/SaveInfo") as Label
	print("PLAY TITLE_SAVE_INFO visible %s text %s" % [str(info.visible if info != null else false), info.text if info != null else ""])
	if title.has_method("_on_load"):
		title.call("_on_load")
		for _i2: int in 6:
			await process_frame
		await _shot(title, "02_title_load.png")
	if made_slot:
		save_service.call("delete_slot", 7)
		save_service.call("delete_autosave", 1)
		save_service.call("delete_autosave", 2)
		save_service.call("delete_autosave", 3)
		save_service.call("note_session_ended")
	title.queue_free()
	for _i3: int in 2:
		await process_frame


func _capture_hub() -> void:
	var gs: Node = root.get_node("GameState")
	gs.set("welcome_shown", true)
	gs.set("welcome_presented", true)
	gs.call("reset_for_new_game")
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		print("PLAY CAPTURE_FAIL hub")
		return
	var hub: Node = packed.instantiate()
	root.add_child(hub)
	current_scene = hub
	for _i: int in 10:
		await process_frame
	var hud: Node = hub.get_node_or_null("%HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	var pause: CanvasItem = hub.get_node_or_null("%PauseMenu") as CanvasItem
	if pause:
		pause.visible = false
	_setup_window()
	await _shot(hub, "03_hub.png")
	await _look_at(hub, "World/Manatree", "04_manatree.png")
	gs.call("_set_stage", &"elder")
	var tree: Node = hub.get_node_or_null("World/Manatree")
	if tree != null and tree.has_method("_refresh_visual"):
		tree.call("_refresh_visual")
	for _j: int in 4:
		await process_frame
	await _look_at(hub, "World/Manatree", "05_manatree_elder.png")
	gs.call("_set_stage", &"ancient")
	if tree != null and tree.has_method("_refresh_visual"):
		tree.call("_refresh_visual")
	for _k: int in 4:
		await process_frame
	await _look_at(hub, "World/Manatree", "06_manatree_ancient.png")
	if hud != null and hud.has_method("open_fruit_confirm"):
		hud.call("open_fruit_confirm")
		for _f: int in 4:
			await process_frame
		await _shot(hub, "07_ascension_confirm.png")
		if hud.has_method("close_fruit_confirm"):
			hud.call("close_fruit_confirm")
	var audio: Node = root.get_node("GameAudio")
	audio.call("set_use_speedup_button", true)
	if hud != null and hud.has_method("_refresh_play_speed_button"):
		hud.call("_refresh_play_speed_button")
	var speed_btn: CanvasItem = hud.get_node_or_null("Panel/PlaySpeedButton") if hud != null else null
	if speed_btn == null and hud != null:
		speed_btn = hud.get_node_or_null("PlaySpeedButton") as CanvasItem
	print("PLAY SPEED_BUTTON %s" % str(speed_btn != null and speed_btn.visible))
	if speed_btn != null and hud != null and hud.has_method("_on_play_speed_pressed"):
		hud.call("_on_play_speed_pressed")
		print("PLAY SPEED_AFTER_PRESS %s" % str(gs.call("play_speed_scale")))
	await _shot(hub, "08_speed_button.png")
	var board: Node = _find_named(hub, "ExpeditionBoard")
	if board != null and board.has_method("open_shell"):
		board.call("open_shell")
		for _b: int in 6:
			await process_frame
		await _shot(hub, "09_adventure_board.png")
		var strings: Node = root.get_node("ContentStrings")
		var who: String = str(strings.call("get_text", "board_who_stands"))
		var note: String = str(strings.call("get_text", "sim_forecast_note"))
		print("PLAY BOARD_STRINGS who %s note %s" % [who, note])
		if board.has_method("close_shell"):
			board.call("close_shell")
	await _look_at(hub, "World/EchoPortal", "10_echo_portal.png")
	if hud != null and hud.has_method("open_character_sheet"):
		hud.call("open_character_sheet")
		for _c: int in 4:
			await process_frame
		await _shot(hub, "11_character_sheet.png")
	var box: Button = hud.get_node_or_null("TouchBoxSelect") if hud != null else null
	if box == null and hud != null:
		box = _find_named(hud, "TouchBoxSelect") as Button
	print("PLAY BOX_BUTTON text %s" % (box.text if box != null else "missing"))
	if hud != null:
		hud.call("_ensure_offline_summary")
		var summary: Node = hud.get_node_or_null("OfflineSummary")
		if summary != null and summary.has_method("present"):
			summary.call("present", {
				"show": true,
				"raw_sec": 86400.0,
				"effective_sec": 3600.0,
				"shard_mult": 1.0,
				"gathered": {"wood": 12},
				"expedition": {},
			})
			for _o: int in 4:
				await process_frame
			await _shot(hub, "12_offline_panel.png")
			print("PLAY OFFLINE_PANEL open %s" % str(hud.call("offline_summary_open")))
			if summary.has_method("dismiss"):
				summary.call("dismiss")
	var weather: Node = root.get_node_or_null("HubWeather")
	if weather != null and weather.has_method("force_state_for_debug"):
		for state: String in ["clear", "soft_rain", "light_snow", "blossom_fall"]:
			weather.call("force_state_for_debug", StringName(state))
			for _w: int in 6:
				await process_frame
			await _look_at(hub, "World/Manatree", "13_weather_%s.png" % state)
	var cycle: Node = _find_named(hub, "HubDayNightModulate")
	if cycle != null:
		cycle.set_process(false)
		var phase_script: GDScript = load("res://scripts/hub/hub_time_phase.gd") as GDScript
		phase_script.call("set_driven_phase01", 0.65)
		(cycle as CanvasModulate).color = Color(0.55, 0.62, 0.95, 1.0)
		for _n: int in 3:
			await process_frame
		await _look_at(hub, "World/Manatree", "14_night.png")
	var puff: Node = _find_named(hub, "Puff")
	if puff != null:
		await _look_at_node(hub, puff, "15_puff_hub.png")
	else:
		print("PLAY PUFF_BODY missing")
	if ResourceLoader.exists("res://scenes/forge_room.tscn"):
		var forge_packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
		if forge_packed != null:
			var forge: Node = forge_packed.instantiate()
			root.add_child(forge)
			for _g: int in 8:
				await process_frame
			await _shot(forge, "16_forge.png")
			forge.queue_free()
	var battle_open: bool = false
	var reach_hub: Node = root.get_node("Reach")
	var departed: String = str(reach_hub.call("depart", 1, 1.0, "", "manual"))
	print("PLAY BATTLE_DEPART %s" % departed)
	if departed == "ok":
		for _bf: int in 8:
			await process_frame
		battle_open = true
		await _shot(hub, "17_manual_fight.png")
		reach_hub.call("debug_finish_run", "finished")
	print("PLAY BATTLE_CAPTURED %s" % str(battle_open))
	hub.queue_free()


func _look_at(hub: Node, path: String, file_name: String) -> void:
	var node: Node2D = hub.get_node_or_null(path) as Node2D
	if node == null:
		print("PLAY LOOK_MISS %s" % path)
		await _shot(hub, file_name)
		return
	await _look_at_node(hub, node, file_name)


func _look_at_node(hub: Node, node: Node, file_name: String) -> void:
	var cam: Camera2D = hub.get_node_or_null("%Camera2D") as Camera2D
	if cam != null and node is Node2D:
		cam.position = (node as Node2D).global_position
	for _i: int in 3:
		await process_frame
	await _shot(hub, file_name)


func _find_named(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child: Node in node.get_children():
		var found: Node = _find_named(child, wanted)
		if found != null:
			return found
	return null


func _shot(host: Node, file_name: String) -> void:
	var vp: Viewport = host.get_viewport()
	if vp == null:
		vp = root
	var image: Image = vp.get_texture().get_image() if vp.get_texture() != null else null
	var path: String = OUT_DIR.path_join(file_name)
	if image == null:
		print("PLAY SHOT_FAIL %s null" % file_name)
		return
	var used: Image = image
	if image.get_width() != CAP_W or image.get_height() != CAP_H:
		used = image.duplicate()
		used.resize(CAP_W, CAP_H, Image.INTERPOLATE_NEAREST)
	var abs_path: String = ProjectSettings.globalize_path(path)
	var err: Error = used.save_png(abs_path)
	var opaque: int = 0
	for y: int in range(0, used.get_height(), 8):
		for x: int in range(0, used.get_width(), 8):
			if used.get_pixel(x, y).a > 0.1 and (used.get_pixel(x, y).r + used.get_pixel(x, y).g + used.get_pixel(x, y).b) > 0.05:
				opaque += 1
	print("PLAY SHOT %s %dx%d err %d sample_opaque %d" % [file_name, used.get_width(), used.get_height(), err, opaque])


func _art_probe() -> void:
	for rel: String in [
		"res://assets/art/companions/puff/portrait_160.png",
		"res://assets/art/companions/puff/portrait_52.png",
		"res://assets/art/companions/puff/idle_s.png",
	]:
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(rel))
		if image == null:
			print("PLAY ART_MISS %s" % rel)
			continue
		var holes: int = _interior_holes(image)
		print("PLAY ART %s %dx%d interior_holes %d" % [rel.get_file(), image.get_width(), image.get_height(), holes])
		var copy: Image = image.duplicate()
		if copy.get_width() != CAP_W or copy.get_height() != CAP_H:
			var sheet: Image = Image.create(CAP_W, CAP_H, false, Image.FORMAT_RGBA8)
			sheet.fill(Color(0.12, 0.14, 0.12, 1))
			var scale: int = maxi(1, mini(CAP_W / image.get_width(), CAP_H / image.get_height()) - 1)
			var dest: Image = image.duplicate()
			dest.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
			var at: Vector2i = Vector2i((CAP_W - dest.get_width()) / 2, (CAP_H - dest.get_height()) / 2)
			sheet.blend_rect(dest, Rect2i(0, 0, dest.get_width(), dest.get_height()), at)
			copy = sheet
		var out_name: String = "18_%s" % rel.get_file()
		copy.save_png(ProjectSettings.globalize_path(OUT_DIR.path_join(out_name)))
		print("PLAY ART_SHEET %s" % out_name)
	var idle: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/companions/puff/idle_s.png"))
	if idle != null:
		var mid: int = idle.get_width() / 2
		var left_y: int = _lowest_opaque(idle, 0, mid)
		var right_y: int = _lowest_opaque(idle, mid, idle.get_width())
		print("PLAY PUFF_IDLE_FEET left_lowest_y %d right_lowest_y %d delta %d" % [left_y, right_y, absi(left_y - right_y)])
	var gather: bool = DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://assets/art/companions/puff/work_gather"))
	var brew: bool = DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://assets/art/companions/puff/work_brew"))
	print("PLAY PUFF_GATHER_DIR %s BREW_DIR %s" % [str(gather), str(brew)])


func _lowest_opaque(image: Image, x0: int, x1: int) -> int:
	var best: int = -1
	for y: int in image.get_height():
		for x: int in range(x0, x1):
			if image.get_pixel(x, y).a > 0.5:
				best = y
	return best


func _interior_holes(image: Image) -> int:
	var w: int = image.get_width()
	var h: int = image.get_height()
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x: int in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y: int in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var idx: int = p.y * w + p.x
		if seen[idx] != 0:
			continue
		if image.get_pixel(p.x, p.y).a > 0.2:
			continue
		seen[idx] = 1
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	var holes: int = 0
	for y2: int in h:
		for x2: int in w:
			if image.get_pixel(x2, y2).a <= 0.2 and seen[y2 * w + x2] == 0:
				holes += 1
	return holes
