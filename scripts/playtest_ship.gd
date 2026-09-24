extends SceneTree
## Thorough playtest for the art / title / forest ship.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/playtest_ship.gd

const OUT: String = "/opt/cursor/artifacts"
const FORGE_KEY_TEXT: String = "Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned."

var _fails: int = 0
var _log: PackedStringArray = PackedStringArray()
var SS
var GS
var AU
var BP
var KS
var EC
var CS


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await process_frame
	await process_frame
	SS = root.get_node("SaveService")
	GS = root.get_node("GameState")
	AU = root.get_node("GameAudio")
	BP = root.get_node("Backpack")
	KS = root.get_node("KeeperStats")
	EC = root.get_node("EchoChamber")
	CS = root.get_node("ContentStrings")
	SS.delete_save()
	_reset_audio_file()
	await _title_flows()
	await _save_compat()
	await _core_loop()
	await _forest_and_camera()
	await _hud_sizes()
	_write_log()
	print("PLAYTEST_DONE fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(name: String, ok: bool, detail: String = "") -> void:
	var line: String = "%s  %s%s" % ["PASS" if ok else "FAIL", name, (" — " + detail) if detail != "" else ""]
	_log.append(line)
	if not ok:
		_fails += 1
	print(line)


func _shot(filename: String) -> void:
	var path: String = "%s/%s" % [OUT, filename]
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("no image %s" % filename)
		return
	img.save_png(path)
	print("saved %s %dx%d" % [filename, img.get_width(), img.get_height()])


func _goto(path: String) -> Node:
	change_scene_to_file(path)
	for _i: int in range(6):
		await process_frame
	return current_scene


func _click(btn: Button) -> void:
	if btn == null:
		return
	btn.pressed.emit()
	await process_frame
	await process_frame


func _music() -> AudioStreamPlayer:
	return AU.get_node_or_null("MusicPlayer") as AudioStreamPlayer


func _reset_audio_file() -> void:
	AU.music_volume_linear = 1.0
	AU.sfx_volume_linear = 1.0
	AU.save_settings()
	AU.apply_volumes()


func _title_flows() -> void:
	print("-- title flows --")
	var title: Node = await _goto("res://scenes/title_screen.tscn")
	for _i: int in range(70):
		await process_frame
	var cont: Button = title.get_node("Menu/BtnContinue") as Button
	var new_b: Button = title.get_node("Menu/BtnNewGame") as Button
	_check("1 fresh Continue hidden", cont != null and not cont.visible)
	_check("1 fresh New Game visible", new_b != null and new_b.visible)
	_shot("pt_title_fresh.png")
	var player: AudioStreamPlayer = _music()
	var stream_before: int = player.stream.get_instance_id() if player and player.stream else 0
	var pos_before: float = player.get_playback_position() if player else -1.0
	var playing_before: bool = player.playing if player else false
	for _j: int in range(40):
		await process_frame
	var pos_mid: float = player.get_playback_position() if player else -1.0
	_check("1 hub BGM playing on title", playing_before and player.playing, "pos %.3f -> %.3f" % [pos_before, pos_mid])

	await _click(new_b)
	for _k: int in range(8):
		await process_frame
	var main: Node = current_scene
	_check("1 New Game enters hub", main != null and main.name == "Main" and str(GS.stage_id) == "sapling" and GS.wood == 0)
	var welcome: Button = main.get_node_or_null("HUD/WelcomePanel/WelcomeDismiss") as Button
	if welcome and welcome.visible:
		_shot("pt_welcome.png")
		await _click(welcome)
	_shot("pt_title_new_game_hub.png")
	var pos_hub: float = player.get_playback_position() if player else -1.0
	var stream_hub: int = player.stream.get_instance_id() if player and player.stream else 0
	var music_nodes: int = 0
	for child: Node in AU.get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).playing and str((child as AudioStreamPlayer).bus) == "Music":
			music_nodes += 1
	_check(
		"1 BGM continuous title into hub",
		player.playing and stream_hub == stream_before and pos_hub + 0.05 >= pos_mid and music_nodes == 1,
		"pos %.3f -> %.3f streams %d players %d" % [pos_mid, pos_hub, stream_hub, music_nodes]
	)

	GS.select_keeper()
	var keeper: Node2D = main.get_node("World/Keeper") as Node2D
	keeper.call("move_to", keeper.global_position + Vector2(80, 40), null)
	for _w: int in range(40):
		await physics_frame
	GS.set_resource(&"wood", 17)
	GS.set_resource(&"essence", 9)
	var pause: Node = main.get_node("PauseMenu")
	pause.call("open_pause")
	await process_frame
	var save_btn: Button = pause.get_node("Panel/BtnSave") as Button
	await _click(save_btn)
	var slot1: Button = pause.get_node_or_null("SlotsPanel/SlotButtons/Slot1") as Button
	await _click(slot1)
	var overwrite: CanvasItem = pause.get_node_or_null("ConfirmPanel") as CanvasItem
	if overwrite != null and overwrite.visible:
		await _click(pause.get_node("ConfirmPanel/ConfirmYes") as Button)
	_check("1 save written from pause", SS.has_slot(1) and int(SS.get_slot_info(1).get("wood", -1)) == 17, "wood %s" % str(SS.get_slot_info(1).get("wood", -1)))
	pause.call("resume_game")
	await process_frame
	pause.call("open_pause")
	await process_frame
	_shot("pt_pause_menu.png")
	var exit_btn: Button = pause.get_node("Panel/BtnExit") as Button
	_check("1 pause Exit reads Return to Title", exit_btn.text == CS.get_text("pause_exit"))
	await _click(exit_btn)
	_shot("pt_pause_return_confirm.png")
	var yes: Button = pause.get_node("ConfirmPanel/ConfirmYes") as Button
	await _click(yes)
	for _t: int in range(8):
		await process_frame
	title = current_scene
	_check("1 Return to Title", title != null and title.name == "TitleScreen")
	var pos_back: float = player.get_playback_position() if player else -1.0
	_check(
		"1 BGM still continuous after Return to Title",
		player.playing and player.stream.get_instance_id() == stream_before and pos_back + 0.05 >= pos_hub,
		"pos %.3f -> %.3f" % [pos_hub, pos_back]
	)
	cont = title.get_node("Menu/BtnContinue") as Button
	_check("1 Continue visible with a save", cont.visible)
	_shot("pt_title_with_save.png")
	await _click(cont)
	for _c: int in range(8):
		await process_frame
	main = current_scene
	_check(
		"1 Continue loads the save",
		main != null and main.name == "Main" and GS.wood == 17 and GS.essence == 9 and str(GS.stage_id) == "sapling",
		"wood %d essence %d stage %s" % [GS.wood, GS.essence, str(GS.stage_id)]
	)
	_shot("pt_title_continue_loaded.png")
	var pos_cont: float = player.get_playback_position() if player else -1.0
	_check(
		"1 BGM continuous into Continue",
		player.playing and player.stream.get_instance_id() == stream_before and pos_cont + 0.05 >= pos_back,
		"pos %.3f -> %.3f" % [pos_back, pos_cont]
	)

	pause = main.get_node("PauseMenu")
	pause.call("open_pause")
	await _click(pause.get_node("Panel/BtnExit") as Button)
	await _click(pause.get_node("ConfirmPanel/ConfirmYes") as Button)
	for _r: int in range(8):
		await process_frame
	title = current_scene
	new_b = title.get_node("Menu/BtnNewGame") as Button
	await _click(new_b)
	var confirm: CanvasItem = title.get_node("ConfirmPanel") as CanvasItem
	_check("1 New Game with save asks confirmation", confirm.visible)
	_shot("pt_title_new_confirm.png")
	await _click(title.get_node("ConfirmPanel/ConfirmNo") as Button)
	_check("1 New Game confirm cancel stays on title", current_scene == title and (title.get_node("Menu/BtnContinue") as Button).visible)

	await _click(title.get_node("Menu/BtnLoad") as Button)
	var slots: CanvasItem = title.get_node("PauseMenu/SlotsPanel") as CanvasItem
	_check("1 Load opens slot list", slots.visible)
	_shot("pt_title_load.png")
	var load_slot: Button = title.get_node("PauseMenu/SlotsPanel/SlotButtons/Slot1") as Button
	await _click(load_slot)
	for _l: int in range(8):
		await process_frame
	main = current_scene
	_check("1 Load slot returns to saved wood", main.name == "Main" and GS.wood == 17, "wood %d" % GS.wood)

	pause = main.get_node("PauseMenu")
	pause.call("open_pause")
	await _click(pause.get_node("Panel/BtnExit") as Button)
	await _click(pause.get_node("ConfirmPanel/ConfirmYes") as Button)
	for _q: int in range(6):
		await process_frame
	title = current_scene
	await _click(title.get_node("Menu/BtnOptions") as Button)
	var music_slider: HSlider = title.get_node("PauseMenu/OptionsPanel/MusicSlider") as HSlider
	var sfx_slider: HSlider = title.get_node("PauseMenu/OptionsPanel/SfxSlider") as HSlider
	_check("1 Options sliders visible", music_slider.visible and sfx_slider.visible)
	music_slider.value = 0.42
	sfx_slider.value = 0.63
	music_slider.drag_ended.emit(true)
	sfx_slider.drag_ended.emit(true)
	_shot("pt_title_options.png")
	await _click(title.get_node("PauseMenu/OptionsPanel/OptionsClose") as Button)
	AU.music_volume_linear = 1.0
	AU.sfx_volume_linear = 1.0
	AU.load_settings()
	_check(
		"1 Options volumes persist to disk",
		absf(AU.music_volume_linear - 0.42) < 0.02 and absf(AU.sfx_volume_linear - 0.63) < 0.02,
		"music %.2f sfx %.2f" % [AU.music_volume_linear, AU.sfx_volume_linear]
	)
	await _click(title.get_node("Menu/BtnOptions") as Button)
	music_slider = title.get_node("PauseMenu/OptionsPanel/MusicSlider") as HSlider
	sfx_slider = title.get_node("PauseMenu/OptionsPanel/SfxSlider") as HSlider
	_check(
		"1 Options sliders restore persisted values",
		absf(music_slider.value - 0.42) < 0.02 and absf(sfx_slider.value - 0.63) < 0.02,
		"music %.2f sfx %.2f" % [music_slider.value, sfx_slider.value]
	)
	await _click(title.get_node("PauseMenu/OptionsPanel/OptionsClose") as Button)
	_reset_audio_file()

	await _click(title.get_node("Menu/BtnQuit") as Button)
	var quit_panel: CanvasItem = title.get_node("ConfirmPanel") as CanvasItem
	_check("1 Quit asks confirmation", quit_panel.visible and (title.get_node("ConfirmPanel/ConfirmLabel") as Label).text == CS.get_text("title_quit_confirm"))
	_shot("pt_title_quit_confirm.png")
	await _click(title.get_node("ConfirmPanel/ConfirmNo") as Button)
	_check("1 Quit cancel stays on title", current_scene == title and not (title.get_node("ConfirmPanel") as CanvasItem).visible)


func _write_main_save() -> void:
	var state: Dictionary = {
		"wood": 40,
		"stone": 22,
		"food": 11,
		"manashards": 850,
		"essence": 55,
		"stage_id": "elder",
		"fruit_ready": false,
		"fruit_committed": false,
		"fruit_harvested_pending_ascend": false,
		"welcome_shown": true,
		"run_time_sec": 640.0,
		"ascensions": 0,
		"lifetime_waters": 4,
		"lifetime_shards_from_water": 12,
		"lifetime_essence_from_water": 4,
		"lifetime_fruit_harvested": 0,
		"lifetime_harvested": {"wood": 40, "stone": 22, "food": 11},
		"upgrades": {},
		"wisp_count": 3,
		"wisp_assignments": {"0": "harvest_tree", "1": "manatree"},
		"backpack": {"fertilizer": 2},
		"owns_stone_axe": false,
		"owns_stone_pickaxe": false,
		"owns_wooden_basket": false,
		"owns_stone_watering_can": false,
		"keeper_stats": {
			"might": 3, "arcana": 1, "resilience": 0, "ward": 2,
			"vitality": 0, "swiftness": 0, "fate": 1,
		},
		"equipment_unlocked": {
			"weapon": true, "relic": true, "head": false, "body": false,
			"hands": false, "pants": false, "feet": false, "cape": false,
			"ring1": false, "ring2": false,
		},
		"equipment_equipped": {
			"weapon": null, "relic": "forge_key_relic", "head": null, "body": null,
			"hands": null, "pants": null, "feet": null, "cape": null,
			"ring1": null, "ring2": null,
		},
		"gear_inventory": {"forge_key_relic": 1},
		"portal_unlocked": false,
		"portal_fee_paid": false,
		"echo_01_resolved": false,
		"echo_01_redeemed": false,
		"forge_key": true,
		"echo_01_narrator_heard": false,
	}
	var payload: Dictionary = {
		"save_version": 8,
		"timestamp": 1700000000,
		"slot": 1,
		"state": state,
	}
	var path: String = SS.slot_path(1)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	var copy := FileAccess.open(OUT + "/save8_main_schema.json", FileAccess.WRITE)
	copy.store_string(JSON.stringify(payload, "\t"))
	copy.close()


func _save_compat() -> void:
	print("-- save compatibility --")
	SS.delete_save()
	_write_main_save()
	var title: Node = await _goto("res://scenes/title_screen.tscn")
	for _i: int in range(20):
		await process_frame
	await _click(title.get_node("Menu/BtnContinue") as Button)
	for _j: int in range(8):
		await process_frame
	var main: Node = current_scene
	_check("2 SAVE 8 loads", main != null and main.name == "Main" and str(GS.stage_id) == "elder" and GS.forge_key)
	_check("2 runestone ranks restored", int(KS.get_rank("might")) == 3 and int(KS.get_rank("ward")) == 2, "might %s" % str(KS.get_rank("might")))
	_check("2 wisp assignment restored", str(GS.get_wisp_assignment(0)) == "harvest_tree" and str(GS.get_wisp_assignment(1)) == "manatree")
	var play: Vector2 = main.call("get_play_size")
	var names: Array[String] = ["World/Keeper", "World/Manatree", "World/HarvestTree", "World/HarvestStone", "World/HarvestBerry"]
	var oob: PackedStringArray = PackedStringArray()
	for path: String in names:
		var n: Node2D = main.get_node_or_null(path) as Node2D
		if n == null:
			oob.append(path + " missing")
			continue
		var p: Vector2 = n.global_position
		var norm: float = float(main.call("_ellipse_norm", p))
		if p.x < 8.0 or p.y < 8.0 or p.x > play.x - 8.0 or p.y > play.y - 8.0 or norm > 0.92:
			oob.append("%s pos %s norm %.2f" % [path, str(p), norm])
	var runes: Array = main.get_tree().get_nodes_in_group("runestone")
	_check("2 seven runestones spawned", runes.size() == 7, "count %d" % runes.size())
	for stone: Node in runes:
		if stone is Node2D:
			var sp: Vector2 = (stone as Node2D).global_position
			var sn: float = float(main.call("_ellipse_norm", sp))
			if sp.x < 8.0 or sp.y < 8.0 or sp.x > play.x - 8.0 or sp.y > play.y - 8.0 or sn > 0.92:
				oob.append("runestone %s norm %.2f" % [str(sp), sn])
	var portal: Node2D = main.get_node_or_null("World/EchoPortal") as Node2D
	if portal:
		var pn: float = float(main.call("_ellipse_norm", portal.global_position))
		if pn > 0.92:
			oob.append("portal norm %.2f" % pn)
	for wisp: Node in main.get_tree().get_nodes_in_group("wisp"):
		if wisp is Node2D:
			var wp: Vector2 = (wisp as Node2D).global_position
			if wp.x < 0.0 or wp.y < 0.0 or wp.x > play.x or wp.y > play.y:
				oob.append("wisp %s" % str(wp))
	_check("2 no out-of-bounds entities", oob.is_empty(), " ".join(oob))
	var tree: Node2D = main.get_node("World/Manatree") as Node2D
	main.call("focus_manatree")
	await process_frame
	_shot("pt_save8_loaded_elder.png")
	var sprite: Sprite2D = tree.get_node("Sprite") as Sprite2D
	_check("2 loaded elder uses animated strip", sprite.hframes == 8 and absf(sprite.scale.x - 4.0) < 0.01 and sprite.texture != null and sprite.texture.get_width() == 256 * 8)


func _core_loop() -> void:
	print("-- core loop --")
	SS.delete_save()
	GS.reset_for_new_game()
	var title: Node = await _goto("res://scenes/title_screen.tscn")
	for _i: int in range(15):
		await process_frame
	await _click(title.get_node("Menu/BtnNewGame") as Button)
	for _j: int in range(8):
		await process_frame
	var main: Node = current_scene
	var welcome: Button = main.get_node_or_null("HUD/WelcomePanel/WelcomeDismiss") as Button
	if welcome and (main.get_node("HUD/WelcomePanel") as CanvasItem).visible:
		await _click(welcome)
	var hud: Node = main.get_node("HUD")
	var keeper: CharacterBody2D = main.get_node("World/Keeper") as CharacterBody2D
	GS.select_keeper()
	_check("3 Keeper selected", GS.keeper_selected)
	var start: Vector2 = keeper.global_position
	var dest: Vector2 = start + Vector2(120, -30)
	keeper.call("move_to", dest, null)
	var arrived: bool = await _wait_arrive(keeper, dest, 90)
	_check("3 Keeper moves", arrived, "at %s want %s" % [str(keeper.global_position), str(dest)])
	main.call("focus_manatree")
	await process_frame
	_shot("pt_keeper_moved.png")

	var wood0: int = GS.wood
	var stone0: int = GS.stone
	var food0: int = GS.food
	await _harvest(main, keeper, "World/HarvestTree", "pt_harvest_wood.png")
	await _harvest(main, keeper, "World/HarvestStone", "pt_harvest_stone.png")
	await _harvest(main, keeper, "World/HarvestBerry", "pt_harvest_food.png")
	_check("3 harvest wood", GS.wood > wood0, "wood %d" % GS.wood)
	_check("3 harvest stone", GS.stone > stone0, "stone %d" % GS.stone)
	_check("3 harvest food", GS.food > food0, "food %d" % GS.food)

	GS.set_resource(&"wood", 80)
	GS.set_resource(&"stone", 80)
	GS.set_resource(&"food", 80)
	GS.set_resource(&"essence", 400)
	GS.set_resource(&"manashards", 2500)
	hud.call("open_backpack")
	await process_frame
	var crafted: bool = false
	var craft_list: Node = hud.get_node("BackpackPanel/CraftScroll/CraftList")
	var crafted_row: bool = false
	for child: Node in craft_list.get_children():
		if not is_instance_valid(child):
			continue
		var name_lbl: Label = _first_label(child)
		if name_lbl == null or name_lbl.text.find("Fertilizer") < 0:
			continue
		for sub: Node in child.get_children():
			if sub is Button and not (sub as Button).disabled:
				await _click(sub as Button)
				crafted = BP.get_count("fertilizer") > 0
				crafted_row = true
				break
		if crafted_row:
			break
	if not crafted:
		for child2: Node in craft_list.get_children():
			if not is_instance_valid(child2):
				continue
			var lbl2: Label = _first_label(child2)
			if lbl2 == null or lbl2.text.find("Plank") < 0:
				continue
			var hit: bool = false
			for sub2: Node in child2.get_children():
				if sub2 is Button and not (sub2 as Button).disabled:
					await _click(sub2 as Button)
					crafted = BP.get_count("wooden_planks") > 0
					hit = true
					break
			if hit:
				break
	_shot("pt_backpack_craft.png")
	_check("3 craft from backpack", crafted or BP.get_count("fertilizer") > 0 or BP.get_count("wooden_planks") > 0, "fert %d planks %d" % [BP.get_count("fertilizer"), BP.get_count("wooden_planks")])
	hud.call("close_backpack")

	BP.add_item("fertilizer", 50)
	var stages: Array[StringName] = [&"sapling", &"young", &"mature", &"elder", &"ancient"]
	var scales: Array[float] = [2.0, 3.0, 4.0, 4.0, 4.0]
	var frames_w: Array[int] = [64, 96, 184, 256, 256]
	for idx: int in range(stages.size()):
		var sid: StringName = stages[idx]
		_check("3 stage is %s" % sid, GS.stage_id == sid, "got %s" % str(GS.stage_id))
		var spr: Sprite2D = (main.get_node("World/Manatree") as Node2D).get_node("Sprite") as Sprite2D
		var tex_ok: bool = spr.texture != null and spr.hframes == 8 and spr.texture.get_width() == frames_w[idx] * 8
		var scale_ok: bool = absf(spr.scale.x - scales[idx]) < 0.01 and spr.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
		_check("3 %s anim scale" % sid, tex_ok and scale_ok, "hframes %d scale %.2f tex %s" % [spr.hframes, spr.scale.x, str(spr.texture.get_width()) if spr.texture else "nil"])
		hud.call("hide_care_menu")
		main.call("focus_manatree")
		await process_frame
		_shot("pt_stage_%s.png" % sid)
		if sid == &"elder":
			await _forge_checks(main, hud, false)
		if sid != &"ancient":
			hud.call("show_care_menu")
			await process_frame
			var grow: Button = hud.get_node("CarePanel/ActionBand/PayButton") as Button
			_check("3 Grow enabled at %s" % sid, grow != null and not grow.disabled, grow.text if grow else "missing")
			await _click(grow)
			await process_frame
	_check("3 grew to ancient", GS.stage_id == &"ancient")
	var wisps: int = int(GS.wisp_count)
	_check("3 wisps from grows", wisps >= 1, "count %d" % wisps)
	GS.select_wisp(0)
	var berry: Node = main.get_node("World/HarvestBerry")
	berry.call("apply_player_command")
	_check("3 wisp assign to food node", str(GS.get_wisp_assignment(0)) == "harvest_berry")
	GS.select_wisp(0)
	(main.get_node("World/Manatree") as Node).call("apply_player_command")
	_check("3 wisp assign to manatree", str(GS.get_wisp_assignment(0)) == "manatree")
	main.call("focus_manatree")
	await process_frame
	await process_frame
	_shot("pt_wisp_assigned.png")

	var ess_before: int = GS.essence
	hud.call("show_care_menu")
	await _click(hud.get_node("CarePanel/ActionBand/WaterButton") as Button)
	for _p: int in range(8):
		await physics_frame
	_check("3 watering pulse", GS.essence > ess_before or GS.manashards > 0, "essence %d -> %d" % [ess_before, GS.essence])
	keeper.call("cancel_channel")
	_shot("pt_watering.png")

	hud.call("open_backpack")
	await process_frame
	_check("3 backpack opens", bool(hud.call("is_backpack_open")))
	_shot("pt_backpack.png")
	hud.call("close_backpack")
	_check("3 backpack closes", not bool(hud.call("is_backpack_open")))

	var key_ev := InputEventKey.new()
	key_ev.keycode = KEY_C
	key_ev.physical_keycode = KEY_C
	key_ev.pressed = true
	Input.parse_input_event(key_ev)
	await process_frame
	await process_frame
	if not bool(hud.call("is_character_open")):
		await _click(hud.get_node("Panel/CharacterButton") as Button)
		_check("3 character sheet opens with C", false, "C did not open; button fallback used")
	else:
		_check("3 character sheet opens with C", true)
	_shot("pt_character_sheet.png")
	var key_up := InputEventKey.new()
	key_up.keycode = KEY_C
	key_up.physical_keycode = KEY_C
	key_up.pressed = true
	Input.parse_input_event(key_up)
	await process_frame
	if bool(hud.call("is_character_open")):
		hud.call("close_character_sheet")
	_check("3 character sheet closes", not bool(hud.call("is_character_open")))

	GS.select_keeper()
	var rune: Node2D = main.get_node("World/Runestones/Runestone_might") as Node2D
	var rank0: int = int(KS.get_rank("might"))
	keeper.call("move_to", rune.global_position, rune)
	await _wait_arrive(keeper, rune.global_position, 360)
	await process_frame
	await process_frame
	var yes_btn: Button = root.get_node_or_null("RunestoneConfirm/Panel/Yes") as Button
	_check("3 runestone confirm opens", yes_btn != null and yes_btn.visible)
	_shot("pt_runestone_confirm.png")
	if yes_btn:
		await _click(yes_btn)
	_check("3 runestone raise", int(KS.get_rank("might")) == rank0 + 1, "%d -> %d" % [rank0, int(KS.get_rank("might"))])
	_shot("pt_runestone_raised.png")

	await _forge_checks(main, hud, true)

	hud.call("show_care_menu")
	var fruit_btn: Button = hud.get_node("CarePanel/ActionBand/HarvestFruitButton") as Button
	_check("3 fruit harvest available", fruit_btn.visible and not fruit_btn.disabled)
	await _click(fruit_btn)
	await process_frame
	_shot("pt_fruit_confirm.png")
	var fruit_yes: Button = hud.get_node("FruitConfirmPanel/ConfirmYes") as Button
	await _click(fruit_yes)
	await _click(fruit_yes)
	await process_frame
	_check("3 ascension shop opens", bool(hud.call("is_ascension_shop_open")))
	_shot("pt_ascension_shop.png")
	var ascend: Button = hud.get_node("AscensionPanel/Footer/AscendButton") as Button
	await _click(ascend)
	await _click(ascend)
	await process_frame
	_check("3 Ascend returns to sapling", str(GS.stage_id) == "sapling" and GS.ascensions >= 1, "stage %s asc %d" % [str(GS.stage_id), GS.ascensions])
	_shot("pt_after_ascend.png")

	var portal: Node = main.get_node("World/EchoPortal")
	_check("3 echo portal visible after ascend", portal.visible)
	GS.set_resource(&"essence", 80)
	GS.select_keeper()
	var battle_pos: float = _music().get_playback_position() if _music() else 0.0
	keeper.call("move_to", (portal as Node2D).global_position, portal)
	await _wait_arrive(keeper, (portal as Node2D).global_position, 240)
	await process_frame
	var fee_yes: Button = root.get_node_or_null("EchoPortalConfirm/Panel/Yes") as Button
	if fee_yes == null or not fee_yes.visible:
		portal.call("begin_entry")
		await process_frame
		fee_yes = root.get_node_or_null("EchoPortalConfirm/Panel/Yes") as Button
	_check("3 echo fee confirm", fee_yes != null)
	if fee_yes:
		await _click(fee_yes)
	await process_frame
	await process_frame
	_check("3 echo battle entered and hub BGM suspended", EC.in_battle and bool(AU.call("is_hub_bed_paused")), "battle %s paused %s" % [str(EC.in_battle), str(AU.call("is_hub_bed_paused"))])
	_shot("pt_echo_battle.png")
	var flee: Button = _find_button_named("FleeButton")
	if flee:
		await _click(flee)
	await process_frame
	var ret: Button = _find_button_named("ReturnButton")
	if ret and ret.visible:
		await _click(ret)
	await process_frame
	var pos_after: float = _music().get_playback_position() if _music() else 0.0
	_check(
		"3 echo exit resumes hub BGM",
		not EC.in_battle and _music().playing and not bool(AU.call("is_hub_suspended")) and pos_after + 0.05 >= battle_pos,
		"pos %.3f -> %.3f playing %s" % [battle_pos, pos_after, str(_music().playing)]
	)
	_shot("pt_echo_exit.png")


func _forge_checks(main: Node, hud: Node, with_key: bool) -> void:
	GS.forge_key = with_key
	hud.call("show_care_menu")
	await process_frame
	var forge: Button = hud.get_node_or_null("CarePanel/ForgeButton") as Button
	_check("3 forge button at %s" % str(GS.stage_id), forge != null and forge.visible)
	if forge:
		await _click(forge)
	await process_frame
	var body: Label = hud.get_node_or_null("ForgePopup/Body") as Label
	var popup: Control = hud.get_node_or_null("ForgePopup") as Control
	if with_key:
		var fits: bool = false
		if body != null and body.text == FORGE_KEY_TEXT:
			var font: Font = body.get_theme_font("font")
			var line_h: float = font.get_height(body.get_theme_font_size("font_size")) if font else 18.0
			fits = float(body.get_line_count()) * line_h <= body.size.y + 2.0
		_check("3 forge popup with key fits", fits, body.text if body else "no body")
		_shot("pt_forge_with_key.png")
	else:
		_check("3 forge without key", body != null and body.text == CS.get_text("forge_no_key"), body.text if body else "")
		_shot("pt_forge_no_key.png")
	if popup:
		popup.visible = false
	hud.call("hide_care_menu")


func _harvest(main: Node, keeper: CharacterBody2D, path: String, shot_name: String) -> void:
	var node: Node2D = main.get_node(path) as Node2D
	GS.select_keeper()
	keeper.call("move_to", node.global_position, node)
	await _wait_arrive(keeper, node.global_position, 200)
	for _i: int in range(6):
		await physics_frame
	var cam: Camera2D = main.get_node("Camera2D") as Camera2D
	cam.position = main.call("_clamped_camera_pos", node.global_position)
	await process_frame
	_shot(shot_name)
	keeper.call("cancel_channel")


func _wait_arrive(keeper: CharacterBody2D, dest: Vector2, frames: int) -> bool:
	for _i: int in range(frames):
		if not bool(keeper.get("_moving")):
			return keeper.global_position.distance_to(dest) < 36.0
		await physics_frame
	return keeper.global_position.distance_to(dest) < 36.0


func _first_label(n: Node) -> Label:
	if n == null or not is_instance_valid(n):
		return null
	if n is Label:
		return n as Label
	for c: Node in n.get_children():
		var found: Label = _first_label(c)
		if found:
			return found
	return null


func _find_button_named(node_name: String) -> Button:
	var found: Node = root.find_child(node_name, true, false)
	return found as Button


func _forest_and_camera() -> void:
	print("-- forest --")
	var main: Node = current_scene
	if main == null or main.name != "Main":
		main = await _goto("res://scenes/main.tscn")
	var hud: Node = main.get_node("HUD")
	hud.call("hide_care_menu")
	hud.call("close_backpack")
	hud.call("close_character_sheet")
	if hud.has_method("hide_forge_popup"):
		hud.call("hide_forge_popup")
	if hud.has_method("hide_ascension_shop"):
		hud.call("hide_ascension_shop")
	var welcome: CanvasItem = hud.get_node("WelcomePanel") as CanvasItem
	welcome.visible = false
	paused = false
	var keeper: CharacterBody2D = main.get_node("World/Keeper") as CharacterBody2D
	keeper.call("halt")
	GS.select_keeper()

	var gaps: int = 0
	var gap_angles: PackedStringArray = PackedStringArray()
	var steps: int = 48
	for i: int in range(steps):
		var ang: float = TAU * float(i) / float(steps)
		var inside: Vector2 = _point_at_norm(main, ang, 0.72)
		var outside: Vector2 = _point_at_norm(main, ang, 1.28)
		keeper.global_position = inside
		keeper.velocity = Vector2.ZERO
		PhysicsServer2D.body_set_state(keeper.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, keeper.global_transform)
		var blocked: bool = false
		var pos: Vector2 = inside
		var dir: Vector2 = (outside - inside).normalized()
		for _s: int in range(80):
			var motion := PhysicsTestMotionParameters2D.new()
			motion.from = keeper.global_transform
			motion.motion = dir * 10.0
			var result := PhysicsTestMotionResult2D.new()
			var hit: bool = PhysicsServer2D.body_test_motion(keeper.get_rid(), motion, result)
			if hit:
				blocked = true
				break
			keeper.global_position += dir * 10.0
			PhysicsServer2D.body_set_state(keeper.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, keeper.global_transform)
			pos = keeper.global_position
			if float(main.call("_ellipse_norm", pos)) > 1.05:
				break
		if not blocked and float(main.call("_ellipse_norm", pos)) > 1.02:
			gaps += 1
			if gap_angles.size() < 8:
				gap_angles.append("%.0fdeg" % rad_to_deg(ang))
	_check("4 no gaps through the tree line", gaps == 0, "gaps %d/%d at %s" % [gaps, steps, " ".join(gap_angles)])

	var stuck: int = 0
	var walk_n: int = 16
	var prev: Vector2 = _point_at_norm(main, 0.0, 0.7)
	keeper.global_position = prev
	for i2: int in range(1, walk_n + 1):
		var ang2: float = TAU * float(i2) / float(walk_n)
		var wp: Vector2 = _point_at_norm(main, ang2, 0.7)
		keeper.call("move_to", wp, null)
		var ok: bool = await _wait_arrive(keeper, wp, 160)
		if not ok:
			stuck += 1
			keeper.global_position = wp
			keeper.call("halt")
		prev = wp
	_check("4 walk the clearing edge without stuck spots", stuck == 0, "stuck %d/%d" % [stuck, walk_n])
	main.call("focus_manatree")
	var cam: Camera2D = main.get_node("Camera2D") as Camera2D
	cam.position = main.call("_clamped_camera_pos", keeper.global_position)
	await process_frame
	_shot("pt_forest_edge.png")

	var decor_blocks: int = 0
	var decor_clicked: int = 0
	var decor_bodies: int = 0
	var decor_nodes: Array = main.get_tree().get_nodes_in_group("forest_decor")
	_check("4 decoration spawned", decor_nodes.size() > 20, "count %d" % decor_nodes.size())
	var space: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	for d: Node in decor_nodes:
		if d.find_child("StaticBody2D", true, false) != null or d.get_node_or_null("StaticBody2D") != null:
			decor_bodies += 1
		if d is Node2D and space != null:
			var q := PhysicsPointQueryParameters2D.new()
			q.position = (d as Node2D).global_position
			q.collide_with_areas = true
			q.collide_with_bodies = true
			q.collision_mask = 0xFFFFFFFF
			var hits: Array[Dictionary] = space.intersect_point(q, 8)
			for hit: Dictionary in hits:
				var col: Variant = hit.get("collider")
				if col is Node and ((col as Node) == d or (col as Node).get_parent() == d):
					decor_blocks += 1
				if col is Node and (col as Node).is_in_group("interactable") and (col as Node).get_parent() == d:
					decor_clicked += 1
	_check("4 decoration has no collision", decor_bodies == 0 and decor_blocks == 0, "bodies %d hits %d" % [decor_bodies, decor_blocks])
	_check("4 decoration is not clickable", decor_clicked == 0)

	var world: Node2D = main.get_node("World") as Node2D
	var tree_ok: bool = false
	var props: Array = main.get_tree().get_nodes_in_group("forest_prop")
	if not props.is_empty() and props[0] is CanvasItem:
		tree_ok = (props[0] as CanvasItem).y_sort_enabled
	_check("4 Y-sort enabled on world, keeper, props", world.y_sort_enabled and keeper.y_sort_enabled and tree_ok)
	var sample_tree: Node2D = null
	for pnode: Node in props:
		if pnode is Node2D and str(pnode.get_meta("prop_kind", "")) == "tree":
			sample_tree = pnode as Node2D
			break
	if sample_tree:
		keeper.global_position = sample_tree.global_position + Vector2(0, 36)
		cam.position = main.call("_clamped_camera_pos", keeper.global_position)
		await process_frame
		_shot("pt_ysort_keeper_south.png")
		keeper.global_position = sample_tree.global_position + Vector2(0, -20)
		cam.position = main.call("_clamped_camera_pos", sample_tree.global_position + Vector2(0, -80))
		await process_frame
		_shot("pt_ysort_keeper_north.png")

	var lo: Vector2 = main.call("camera_min")
	var hi: Vector2 = main.call("camera_max")
	main.call("pan_camera", Vector2(-20000, -20000))
	var got_lo: Vector2 = main.call("get_camera_position_clamped")
	main.call("pan_camera", Vector2(20000, 20000))
	var got_hi: Vector2 = main.call("get_camera_position_clamped")
	_check("4 camera clamp min", got_lo.distance_to(lo) < 1.5, str(got_lo))
	_check("4 camera clamp max", got_hi.distance_to(hi) < 1.5, str(got_hi))
	var corners: Array[Vector2] = [lo, Vector2(hi.x, lo.y), Vector2(lo.x, hi.y), hi]
	var corner_names: Array[String] = ["pt_corner_nw.png", "pt_corner_ne.png", "pt_corner_sw.png", "pt_corner_se.png"]
	for ci: int in range(4):
		cam.position = corners[ci]
		await process_frame
		var clamped: Vector2 = cam.position
		_check("4 corner camera %s" % corner_names[ci], clamped.distance_to(corners[ci]) < 1.5)
		_shot(corner_names[ci])


func _point_at_norm(main: Node, ang: float, target: float) -> Vector2:
	var center: Vector2 = main.get("clearing_center")
	var lo: float = 0.0
	var hi: float = 2200.0
	var pos: Vector2 = center
	for _i: int in range(20):
		var mid: float = (lo + hi) * 0.5
		pos = center + Vector2(cos(ang), sin(ang)) * mid
		var n: float = float(main.call("_ellipse_norm", pos))
		if n < target:
			lo = mid
		else:
			hi = mid
	return pos


func _hud_sizes() -> void:
	print("-- hud --")
	var main: Node = current_scene
	var win: Window = root as Window
	win.size = Vector2i(1280, 720)
	for _i: int in range(4):
		await process_frame
	_hud_audit("5 HUD 1280x720")
	_shot("pt_hud_1280.png")
	await _tooltip_check("5 tooltip at 1280")
	win.size = Vector2i(960, 540)
	for _j: int in range(6):
		await process_frame
	_hud_audit("5 HUD 960x540")
	_shot("pt_hud_960.png")
	await _tooltip_check("5 tooltip at 960")
	win.size = Vector2i(1280, 720)


func _hud_audit(label: String) -> void:
	var main: Node = current_scene
	var hud: Node = main.get_node("HUD")
	var names: Array[String] = [
		"Panel/IconRow/WoodChip",
		"Panel/IconRow/StoneChip",
		"Panel/IconRow/FoodChip",
		"Panel/IconRow/ShardChip",
		"Panel/IconRow/EssenceChip",
		"Panel/CharacterButton",
		"Panel/BackpackButton",
		"Panel/PauseButton",
		"Panel/StageLabel",
		"Panel/ControlsHint",
		"Panel/StatusLabel",
		"Panel/SelectionHint",
	]
	var rects: Array[Rect2] = []
	var nearest_bad: int = 0
	for path: String in names:
		var c: Control = hud.get_node_or_null(path) as Control
		if c == null or not c.visible:
			continue
		rects.append(c.get_global_rect())
		if c is TextureRect and (c as TextureRect).texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			nearest_bad += 1
	var icons: Array[String] = [
		"Panel/IconRow/WoodChip/IconWood",
		"Panel/IconRow/StoneChip/IconStone",
		"Panel/IconRow/FoodChip/IconFood",
		"Panel/IconRow/ShardChip/IconShards",
		"Panel/IconRow/EssenceChip/IconEssence",
		"Panel/BackpackButton/BackpackIcon",
		"Panel/PauseButton/Icon",
	]
	for ip: String in icons:
		var tex: CanvasItem = hud.get_node_or_null(ip) as CanvasItem
		if tex and tex.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			nearest_bad += 1
	var overlaps: int = 0
	for a: int in range(rects.size()):
		for b: int in range(a + 1, rects.size()):
			var inter: Rect2 = rects[a].intersection(rects[b])
			if inter.get_area() > 2.0:
				overlaps += 1
	var vp: Rect2 = root.get_viewport().get_visible_rect()
	var clipped: int = 0
	for r: Rect2 in rects:
		if not vp.encloses(r.grow(-1.0)):
			clipped += 1
	_check(label + " no overlap", overlaps == 0, "overlaps %d" % overlaps)
	_check(label + " on screen", clipped == 0, "clipped %d vp %s" % [clipped, str(vp.size)])
	_check(label + " nearest icons", nearest_bad == 0, "bad %d" % nearest_bad)


func _tooltip_check(label: String) -> void:
	var hud: Node = current_scene.get_node("HUD")
	var btn: Button = hud.get_node("Panel/CharacterButton") as Button
	var tip: String = btn.tooltip_text
	var center: Vector2 = btn.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	root.push_input(motion)
	for _i: int in range(50):
		await process_frame
	var shown: bool = _tree_has_text(root, tip)
	_check(label, tip != "" and shown, "tip '%s' shown %s" % [tip, str(shown)])
	if shown:
		_shot("pt_tooltip.png")


func _tree_has_text(n: Node, text: String) -> bool:
	if n is Label and (n as Label).text.find(text) >= 0 and (n as CanvasItem).visible:
		return true
	if n is Button and (n as Button).text.find(text) >= 0:
		return true
	for c: Node in n.get_children():
		if _tree_has_text(c, text):
			return true
	return false


func _write_log() -> void:
	var file := FileAccess.open(OUT + "/playtest_checklist.txt", FileAccess.WRITE)
	if file == null:
		return
	for line: String in _log:
		file.store_line(line)
	file.store_line("FAILS %d" % _fails)
	file.close()
