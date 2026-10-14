extends SceneTree
## Headless forge arch capture for docs/captures/r3_forge_arch.png
## godot --headless --path . -s res://tools/capture_r3_forge_arch.gd


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
	if packed == null:
		print("CAPTURE_FAIL forge scene")
		quit(1)
		return
	var room: Node = packed.instantiate()
	root.add_child(room)
	current_scene = room
	var cam: Camera2D = room.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.position = Vector2(800, 1040)
		cam.zoom = Vector2(1.0, 1.0)
	var keeper: Node2D = room.get_node_or_null("Keeper") as Node2D
	if keeper:
		keeper.visible = false
	var elaia: Node2D = room.get_node_or_null("Elaia") as Node2D
	if elaia:
		elaia.visible = false
	var hud: CanvasItem = room.get_node_or_null("HUD") as CanvasItem
	if hud:
		hud.visible = false
	var pause: CanvasItem = room.get_node_or_null("PauseMenu") as CanvasItem
	if pause:
		pause.visible = false
	DisplayServer.window_set_size(Vector2i(960, 540))
	for _i: int in 6:
		await process_frame
	var dest: String = "res://docs/captures/r3_forge_arch.png"
	var vp: Viewport = root
	var image: Image = vp.get_texture().get_image()
	if image == null:
		print("CAPTURE_FAIL no image")
		quit(1)
		return
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	var err: Error = image.save_png(dest)
	if err != OK:
		print("CAPTURE_FAIL save %s" % err)
		quit(1)
		return
	print("CAPTURE_OK %s" % dest)
	quit(0)
