extends SceneTree
## Close shots of the Keeper at each work spot.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_keeper_anims.gd

const OUT := "/opt/cursor/artifacts"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_service: Node = root.get_node_or_null("SaveService")
	var gs: Node = root.get_node_or_null("GameState")
	if save_service and save_service.has_method("delete_save"):
		save_service.call("delete_save")
	if gs:
		gs.call("reset_for_new_game")
		gs.set("welcome_shown", true)
	var main_packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if main_packed == null:
		push_error("capture_keeper_anims: main.tscn missing")
		quit(1)
		return
	var main: Node = main_packed.instantiate()
	root.add_child(main)
	for _i: int in range(3):
		await process_frame
	_hide_ui(main)
	var keeper: Node = main.get_node_or_null("World/Keeper")
	var camera: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
	if keeper == null or camera == null:
		push_error("capture_keeper_anims: hub keeper or camera missing")
		quit(1)
		return
	await _pose_shot(keeper, camera, main.get_node("World/Manatree"), "manatree", 5, "%s/keeper_water_manatree.png" % OUT)
	await _pose_shot(keeper, camera, main.get_node("World/HarvestTree"), "wood", 3, "%s/keeper_axe_tree.png" % OUT)
	await _pose_shot(keeper, camera, main.get_node("World/HarvestStone"), "stone", 7, "%s/keeper_pickaxe_stone.png" % OUT)
	await _pose_shot(keeper, camera, main.get_node("World/Runestones/Runestone_might"), "runestone", 7, "%s/keeper_pickaxe_runestone.png" % OUT)
	await _pose_shot(keeper, camera, main.get_node("World/HarvestBerry"), "food", 4, "%s/keeper_berries.png" % OUT)
	main.queue_free()
	await process_frame
	var forge_packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
	if forge_packed == null:
		push_error("capture_keeper_anims: forge_room.tscn missing")
		quit(1)
		return
	var forge: Node = forge_packed.instantiate()
	root.add_child(forge)
	for _j: int in range(3):
		await process_frame
	_hide_ui(forge)
	var forge_keeper: Node = forge.get_node_or_null("Keeper")
	var forge_cam: Camera2D = forge.get_node_or_null("Camera2D") as Camera2D
	if forge_keeper == null or forge_cam == null:
		push_error("capture_keeper_anims: forge keeper or camera missing")
		quit(1)
		return
	await _pose_shot(forge_keeper, forge_cam, forge.get_node("Anvil"), "station", 4, "%s/keeper_station_anvil.png" % OUT, "anvil")
	await _pose_shot(forge_keeper, forge_cam, forge.get_node("Press"), "station", 4, "%s/keeper_station_press.png" % OUT, "press")
	print("CAPTURE_OK")
	quit(0)


func _pose_shot(keeper: Node, camera: Camera2D, target: Node, type_id: String, frame_idx: int, path: String, station_id: String = "") -> void:
	if target == null or not (target is Node2D):
		push_error("capture_keeper_anims: missing %s" % type_id)
		return
	var body: Node2D = target as Node2D
	var approach: Vector2 = body.global_position + Vector2(-420, 8)
	if type_id == "station":
		approach = body.global_position + Vector2(0, 220)
	(keeper as Node2D).global_position = approach
	var plan: Dictionary = keeper.call("plan_work", body, type_id, station_id)
	var feet: Vector2 = plan.get("position", body.global_position)
	var contact: Vector2 = plan.get("contact", feet)
	(keeper as Node2D).global_position = feet
	var keeper_cls = load("res://scripts/keeper.gd")
	var anim := StringName(str(keeper_cls.work_anim_for(str(plan.get("tool", "")), str(plan.get("facing", "south")))))
	keeper.call("hold_contact_pose", anim, frame_idx)
	camera.make_current()
	camera.zoom = Vector2(3.4, 3.4)
	camera.offset = Vector2.ZERO
	camera.position = feet.lerp(contact, 0.35) + Vector2(0, -28)
	for _k: int in range(2):
		await process_frame
	_shot(path)
	print("pose %s anim %s side %s facing %s feet %s contact %s fallback %s" % [
		type_id,
		str(anim),
		str(plan.get("side", "")),
		str(plan.get("facing", "")),
		str(feet),
		str(contact),
		str(bool(plan.get("fallback", false))),
	])


func _hide_ui(scene: Node) -> void:
	var hud: Node = scene.get_node_or_null("HUD")
	if hud:
		hud.set("visible", false)
	var welcome: Node = scene.get_node_or_null("HUD/WelcomePanel")
	if welcome:
		welcome.set("visible", false)
	var pause_menu: Node = scene.get_node_or_null("PauseMenu")
	if pause_menu and pause_menu is CanvasItem:
		(pause_menu as CanvasItem).visible = false


func _shot(path: String) -> void:
	var vp: Viewport = root.get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img == null:
		push_error("capture_keeper_anims: no image for %s" % path)
		return
	img.save_png(path)
	print("saved %s %dx%d" % [path, img.get_width(), img.get_height()])
