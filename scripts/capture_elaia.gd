extends SceneTree
## Headless shots for Elaia's join, work poses, and the character sheet.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_elaia.gd

const OUT := "/opt/cursor/artifacts"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs: Node = root.get_node_or_null("GameState")
	var save_service: Node = root.get_node_or_null("SaveService")
	if save_service and save_service.has_method("delete_save"):
		save_service.call("delete_save")
	if gs:
		gs.call("reset_for_new_game")
		gs.set("welcome_shown", true)
	var main_packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if main_packed == null:
		push_error("capture_elaia: main missing")
		quit(1)
		return
	var main: Node = main_packed.instantiate()
	root.add_child(main)
	current_scene = main
	for _i: int in range(4):
		await process_frame
	var hud: Node = main.get_node_or_null("HUD")
	var camera: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
	var keeper: Node = main.get_node_or_null("World/Keeper")
	var elaia: Node = main.get_node_or_null("World/Elaia")
	var tree: Node = main.get_node_or_null("World/Manatree")
	if hud == null or camera == null or keeper == null or elaia == null or tree == null:
		push_error("capture_elaia: hub nodes missing")
		quit(1)
		return
	_frame_camera(camera, (keeper as Node2D).global_position + Vector2(32, -20), 1.4)
	if hud.has_method("_refresh_party_bar"):
		hud.call("_refresh_party_bar")
	await process_frame
	_shot("%s/elaia_prejoin_no_portrait.png" % OUT)

	gs.set("echo_01_redeemed", true)
	gs.set("first_relic_crafted", true)
	gs.set("elaia_join_seen", false)
	if elaia.has_method("_apply_presence"):
		elaia.call("_apply_presence")
	if hud.has_method("_refresh_party_bar"):
		hud.call("_refresh_party_bar")
	if hud.has_method("maybe_show_elaia_join"):
		hud.call("maybe_show_elaia_join")
	await process_frame
	_frame_camera(camera, (keeper as Node2D).global_position + Vector2(40, -10), 1.15)
	_shot("%s/elaia_join_dialogue.png" % OUT)
	gs.set("elaia_join_seen", true)
	var band: CanvasItem = hud.get_node_or_null("ElaiaJoinBand") as CanvasItem
	if band:
		band.visible = false

	_frame_camera(camera, (keeper as Node2D).global_position + Vector2(36, -24), 1.6)
	await process_frame
	_shot("%s/elaia_idle_beside_keeper.png" % OUT)

	_solo(keeper, elaia)
	await _pose_shot(keeper, camera, main.get_node("World/HarvestTree"), "wood", 3, "%s/keeper_wood_right_facing_left.png" % OUT)
	_solo(elaia, keeper)
	await _pose_shot(elaia, camera, main.get_node("World/HarvestTree"), "wood", 3, "%s/elaia_wood_right_facing_left.png" % OUT)
	await _pose_shot(elaia, camera, main.get_node("World/HarvestStone"), "stone", 7, "%s/elaia_mining.png" % OUT)
	await _pose_shot(elaia, camera, main.get_node("World/HarvestBerry"), "food", 4, "%s/elaia_berries.png" % OUT)
	_solo(keeper, elaia)
	await _water_stage(gs, tree, keeper, camera, &"sapling", "%s/keeper_water_sapling.png" % OUT)
	await _water_stage(gs, tree, keeper, camera, &"elder", "%s/keeper_water_elder.png" % OUT)
	_solo(elaia, keeper)
	await _water_stage(gs, tree, elaia, camera, &"young", "%s/elaia_water_young.png" % OUT)
	await _water_stage(gs, tree, elaia, camera, &"ancient", "%s/elaia_water_ancient.png" % OUT)
	(keeper as CanvasItem).visible = true
	(elaia as CanvasItem).visible = true

	var win: Window = root
	win.size = Vector2i(1280, 720)
	await process_frame
	if hud.has_method("open_character_sheet"):
		hud.call("open_character_sheet")
	var sheet: Node = hud.get_node_or_null("CharacterSheet")
	if sheet and sheet.has_method("show_actor"):
		sheet.call("show_actor", "keeper")
	await process_frame
	await process_frame
	_shot("%s/sheet_keeper_both_portraits.png" % OUT)
	if sheet and sheet.has_method("show_actor"):
		sheet.call("show_actor", "elaia")
	await process_frame
	_shot("%s/sheet_elaia_both_portraits.png" % OUT)
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	win.size = Vector2i(960, 540)
	for _s: int in range(4):
		await process_frame
	if sheet and sheet.has_method("_fit_sheet"):
		sheet.call("_fit_sheet")
	await process_frame
	_shot("%s/sheet_elaia_960.png" % OUT)
	win.size = Vector2i(1920, 1080)
	for _b: int in range(4):
		await process_frame
	if sheet and sheet.has_method("_fit_sheet"):
		sheet.call("_fit_sheet")
	await process_frame
	_shot("%s/sheet_elaia_1920.png" % OUT)

	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.size = Vector2i(1280, 720)
	await process_frame
	main.queue_free()
	await process_frame
	var forge_packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
	if forge_packed == null:
		push_error("capture_elaia: forge missing")
		quit(1)
		return
	var forge: Node = forge_packed.instantiate()
	root.add_child(forge)
	current_scene = forge
	for _j: int in range(3):
		await process_frame
	var forge_hud: Node = forge.get_node_or_null("HUD")
	if forge_hud:
		forge_hud.set("visible", false)
	var forge_elaia: Node = forge.get_node_or_null("Elaia")
	var forge_cam: Camera2D = forge.get_node_or_null("Camera2D") as Camera2D
	gs.set("elaia_area", "forge")
	gs.set("elaia_has_pos", true)
	if forge_elaia and forge_elaia.has_method("_apply_presence"):
		forge_elaia.call("_apply_presence")
	await _pose_shot(forge_elaia, forge_cam, forge.get_node("Reliquary"), "station", 4, "%s/elaia_reliquary.png" % OUT, "reliquary")
	print("CAPTURE_ELAIA_OK")
	quit(0)


func _water_stage(gs: Node, tree: Node, body: Node, camera: Camera2D, stage: StringName, path: String) -> void:
	gs.set("stage_id", stage)
	gs.emit_signal("stage_changed", stage)
	if tree.has_method("_refresh_visual"):
		tree.call("_refresh_visual")
	await process_frame
	await _pose_shot(body, camera, tree, "manatree", 5, path)


func _pose_shot(body: Node, camera: Camera2D, target: Node, type_id: String, frame_idx: int, path: String, station_id: String = "") -> void:
	if body == null or target == null or not (target is Node2D) or camera == null:
		push_error("capture_elaia: missing pose %s" % type_id)
		return
	var mark: Node2D = target as Node2D
	(body as Node2D).global_position = mark.global_position + Vector2(-280, 24)
	if body.has_method("set_physics_process"):
		body.call("set_physics_process", true)
	var plan: Dictionary = body.call("plan_work", mark, type_id, station_id)
	var feet: Vector2 = plan.get("position", mark.global_position)
	var contact: Vector2 = plan.get("contact", feet)
	(body as Node2D).global_position = feet
	var keeper_cls = load("res://scripts/keeper.gd")
	var anim := StringName(str(keeper_cls.work_anim_for(str(plan.get("tool", "")), str(plan.get("facing", "south")))))
	body.call("hold_contact_pose", anim, frame_idx)
	_frame_camera(camera, feet.lerp(contact, 0.45) + Vector2(0, -36), 2.6)
	for _k: int in range(2):
		await process_frame
	_shot(path)
	print("pose %s %s side %s facing %s feet %s contact %s" % [
		body.name, type_id, str(plan.get("side", "")), str(plan.get("facing", "")), str(feet), str(contact),
	])


func _solo(show_body: Node, hide_body: Node) -> void:
	(show_body as CanvasItem).visible = true
	(hide_body as CanvasItem).visible = false


func _frame_camera(camera: Camera2D, pos: Vector2, zoom: float) -> void:
	camera.make_current()
	camera.zoom = Vector2(zoom, zoom)
	camera.offset = Vector2.ZERO
	camera.position = pos


func _shot(path: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("capture_elaia: no image %s" % path)
		return
	img.save_png(path)
	print("saved %s %dx%d" % [path, img.get_width(), img.get_height()])
