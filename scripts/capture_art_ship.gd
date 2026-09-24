extends SceneTree
## Screenshots for the art / title / forest ship.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_art_ship.gd

const OUT: String = "/opt/cursor/artifacts"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var save_service: Node = root.get_node_or_null("SaveService")
	var gs: Node = root.get_node_or_null("GameState")
	var pack: Node = root.get_node_or_null("Backpack")
	if save_service and save_service.has_method("delete_save"):
		save_service.call("delete_save")
	if gs:
		gs.set("welcome_shown", true)
		gs.call("set_resource", &"wood", 48)
		gs.call("set_resource", &"stone", 36)
		gs.call("set_resource", &"food", 22)
		gs.call("set_resource", &"manashards", 120)
		gs.call("set_resource", &"essence", 40)
	if save_service and save_service.has_method("save_game"):
		save_service.call("save_game", 1)

	var title_packed: PackedScene = load("res://scenes/title_screen.tscn") as PackedScene
	var title: Node = title_packed.instantiate()
	root.add_child(title)
	for _i: int in range(100):
		await process_frame
	_shot("title_screen.png")
	title.queue_free()
	await process_frame

	if save_service:
		save_service.set("boot_intent", "new")
		save_service.set("boot_slot", 0)
	var main_packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var live: Node = main_packed.instantiate()
	root.add_child(live)
	for _j: int in range(8):
		await process_frame
	if gs:
		gs.set("welcome_shown", true)
		gs.call("set_resource", &"wood", 48)
		gs.call("set_resource", &"stone", 36)
		gs.call("set_resource", &"food", 22)
		gs.call("set_resource", &"manashards", 120)
		gs.call("set_resource", &"essence", 40)
	var hud: Node = live.get_node_or_null("HUD")
	if hud:
		var welcome: Node = hud.get_node_or_null("WelcomePanel")
		if welcome:
			welcome.set("visible", false)
	await process_frame
	_shot("hub_hud.png")

	_set_stage(gs, &"sapling")
	_aim(live, Vector2(1600, 1560))
	await process_frame
	_shot("manatree_sapling.png")

	_set_stage(gs, &"young")
	await process_frame
	_shot("manatree_young.png")

	_aim(live, Vector2(1210, 1740))
	await process_frame
	_shot("harvest_nodes.png")

	_aim(live, Vector2(1900, 1620))
	await process_frame
	_shot("runestones.png")

	if pack:
		pack.call("add_item", "wooden_planks", 12)
		pack.call("add_item", "stone_fragments", 8)
		pack.call("add_item", "wooden_tool_rod", 3)
		pack.call("add_item", "axe_head", 2)
		pack.call("add_item", "pickaxe_head", 1)
		pack.call("add_item", "stone_axe", 1)
		pack.call("add_item", "fertilizer", 6)
		pack.call("add_item", "wooden_basket", 1)
	if hud and hud.has_method("open_backpack"):
		hud.call("open_backpack")
	await process_frame
	await process_frame
	_shot("backpack.png")
	if hud and hud.has_method("close_backpack"):
		hud.call("close_backpack")

	_aim(live, Vector2(1600, 1560))
	await process_frame
	_shot("forest_overview.png")

	_aim(live, Vector2(900, 720))
	await process_frame
	_shot("forest_corner_decor.png")

	_set_stage(gs, &"elder")
	if gs:
		gs.set("forge_key", true)
	_aim(live, Vector2(1600, 1560))
	for _k: int in range(6):
		await process_frame
	if hud and hud.has_method("open_forge_entry"):
		hud.call("open_forge_entry")
	await process_frame
	_shot("forge_popup_key.png")

	_set_stage(gs, &"ancient")
	await process_frame
	if hud:
		var popup: Node = hud.get_node_or_null("ForgePopup")
		if popup:
			popup.set("visible", false)
	_shot("manatree_ancient.png")

	print("CAPTURE_OK")
	quit(0)


func _set_stage(gs: Node, stage: StringName) -> void:
	if gs and gs.has_method("_set_stage"):
		gs.call("_set_stage", stage)


func _aim(live: Node, pos: Vector2) -> void:
	var cam: Camera2D = live.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	if live.has_method("_clamped_camera_pos"):
		cam.position = live.call("_clamped_camera_pos", pos)
	else:
		cam.position = pos


func _shot(filename: String) -> void:
	var path: String = "%s/%s" % [OUT, filename]
	var vp: Viewport = root.get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img == null:
		push_error("no image for %s" % path)
		return
	img.save_png(path)
	print("saved %s %dx%d" % [path, img.get_width(), img.get_height()])
