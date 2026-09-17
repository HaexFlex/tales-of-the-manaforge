extends SceneTree
## One-shot hub screenshotter (art QA).
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_hub.gd


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
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("capture_hub: main.tscn missing")
		quit(1)
		return
	var live: Node = packed.instantiate()
	root.add_child(live)
	await process_frame
	await process_frame
	var hud: Node = live.get_node_or_null("HUD")
	if hud:
		hud.set("visible", false)
	var welcome: Node = live.get_node_or_null("HUD/WelcomePanel")
	if welcome:
		welcome.set("visible", false)
	await process_frame
	_shot("/opt/cursor/artifacts/hub_clearing_forest_ring.png")
	var keeper: Node = live.get_node_or_null("World/Keeper")
	if keeper and keeper.has_method("move_to"):
		var pos: Vector2 = keeper.get("global_position") as Vector2
		keeper.call("move_to", pos + Vector2(40, 180), null)
		for _j: int in range(16):
			await physics_frame
		_shot("/opt/cursor/artifacts/keeper_walking_south_in_glade.png")
	print("CAPTURE_OK")
	quit(0)


func _shot(path: String) -> void:
	var vp: Viewport = root.get_viewport()
	var tex: ViewportTexture = vp.get_texture()
	var img: Image = tex.get_image()
	if img == null:
		push_error("capture_hub: no image for %s" % path)
		return
	img.save_png(path)
	print("saved %s %dx%d" % [path, img.get_width(), img.get_height()])
