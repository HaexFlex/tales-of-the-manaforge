extends SceneTree
## One-shot: run the deterministic hub scatter and save it into main.tscn.
##   MANAFORGE_BAKE=1 godot --headless --path . --script res://tools/bake_hub_layout.gd


func _initialize() -> void:
	print("BAKE_INIT")
	call_deferred("_bake")


func _bake() -> void:
	print("BAKE_START")
	var packed_main: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed_main == null:
		push_error("bake: main.tscn missing")
		quit(1)
		return
	var src: Node = packed_main.instantiate()
	print("BAKE_ADD")
	root.add_child(src)
	print("BAKE_ADDED")
	if OS.get_environment("MANAFORGE_BAKE") != "1":
		push_error("bake: set MANAFORGE_BAKE=1 so main builds the layout once")
		quit(1)
		return
	var main := src as Node2D
	if main == null or not main.has_method("get_play_size"):
		push_error("bake: main did not come up")
		quit(1)
		return
	var play: Vector2 = main.call("get_play_size")
	var camera: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
	if camera:
		var inset: int = 120
		camera.limit_left = inset
		camera.limit_top = inset
		camera.limit_right = int(play.x) - inset
		camera.limit_bottom = int(play.y) - inset
		camera.position_smoothing_enabled = false
	var portal: Node2D = main.get_node_or_null("World/EchoPortal") as Node2D
	if portal:
		portal.visible = true
		portal.set("input_pickable", true)
	# Drop anything that is not static layout (wisps, confirm layers).
	var wisps: Array[Node] = []
	for wisp: Node in main.get_tree().get_nodes_in_group("wisp"):
		wisps.append(wisp)
	for wisp: Node in wisps:
		wisp.free()
	var dst := Node2D.new()
	dst.name = "Main"
	dst.set_script(load("res://scripts/main.gd"))
	for child_name: String in ["Ground", "Camera2D", "ClickLayer", "World"]:
		var node: Node = main.get_node(child_name)
		main.remove_child(node)
		dst.add_child(node)
	var hud: Node = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	hud.name = "HUD"
	hud.unique_name_in_owner = true
	dst.add_child(hud)
	var pause: Node = (load("res://scenes/pause_menu.tscn") as PackedScene).instantiate()
	pause.name = "PauseMenu"
	pause.unique_name_in_owner = true
	dst.add_child(pause)
	_claim(dst, dst)
	var packed := PackedScene.new()
	var err: Error = packed.pack(dst)
	if err != OK:
		push_error("bake: pack failed %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/main.tscn")
	if err != OK:
		push_error("bake: save failed %s" % err)
		quit(1)
		return
	var props: int = 0
	for child: Node in dst.get_node("World").get_children():
		if child.is_in_group("forest_prop") or str(child.scene_file_path).find("forest_") >= 0:
			props += 1
	print("BAKE_OK props_seen=%d play=%s" % [props, play])
	quit(0)


func _claim(node: Node, scene_root: Node) -> void:
	if node != scene_root:
		node.owner = scene_root
	for child: Node in node.get_children():
		if child.scene_file_path != "":
			child.owner = scene_root
		else:
			_claim(child, scene_root)
