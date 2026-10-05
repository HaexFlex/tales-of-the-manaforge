extends SceneTree
## One-shot screenshot of the testing debug panel over the hub.
##   godot --path . --script res://scripts/capture_debug_panel.gd
## Not shipped. Both export presets exclude this script.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_service: Node = root.get_node("SaveService")
	var game_state: Node = root.get_node("GameState")
	save_service.set("boot_intent", "new")
	game_state.call("reset_for_new_game")
	game_state.set("welcome_shown", true)
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		print("CAPTURE_FAIL main scene missing")
		quit(1)
		return
	var live: Node = packed.instantiate()
	root.add_child(live)
	current_scene = live
	for _i: int in 4:
		await process_frame
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	var hotkey: Node = root.get_node_or_null("AnimPreviewHotkey")
	if hotkey != null and hotkey.has_method("set_debug_panel"):
		hotkey.call("set_debug_panel", true)
	for _j: int in 3:
		await process_frame
	if not await _save_shot("/opt/cursor/artifacts/debug_panel.png"):
		quit(1)
		return
	if hotkey != null and hotkey.has_method("set_debug_panel"):
		hotkey.call("set_debug_panel", false)
	var tree: Node2D = live.get_node_or_null("World/Manatree") as Node2D
	var keeper: Node2D = live.get_node_or_null("World/Keeper") as Node2D
	var camera: Camera2D = live.get_node_or_null("Camera2D") as Camera2D
	if tree != null and keeper != null:
		game_state.set("stage_id", &"sapling")
		game_state.emit_signal("stage_changed", &"sapling")
		await process_frame
		var keeper_cls = load("res://scripts/keeper.gd")
		var footprint: Rect2 = tree.call("work_footprint")
		var solved: Dictionary = keeper_cls.solve_work_spot(footprint, tree.global_position, "manatree", Callable(), "", "keeper")
		var feet: Vector2 = solved.get("position", tree.global_position + Vector2(-102, 35))
		keeper.global_position = feet
		if camera:
			camera.position = feet + Vector2(40, -20)
		await process_frame
		await process_frame
		if not await _save_shot("/opt/cursor/artifacts/manatree_watering.png"):
			quit(1)
			return
	game_state.set("wisp_count", 2)
	game_state.call("try_assign_wisp", 0, "manatree")
	game_state.call("try_assign_wisp", 1, "manatree")
	for _w: int in 8:
		await process_frame
	for wisp: Node in live.get_tree().get_nodes_in_group("wisp"):
		if wisp.has_method("place_on_shared_orbit"):
			wisp.call("place_on_shared_orbit")
	if camera and tree:
		camera.position = tree.global_position + Vector2(0, -80)
	await process_frame
	if not await _save_shot("/opt/cursor/artifacts/wisps_hover.png"):
		quit(1)
		return
	var forge_packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
	if forge_packed == null:
		print("CAPTURE_FAIL forge room")
		quit(1)
		return
	var room: Node = forge_packed.instantiate()
	root.add_child(room)
	current_scene = room
	live.queue_free()
	var arch_keeper: Node2D = room.get_node_or_null("Keeper") as Node2D
	var arch_cam: Camera2D = room.get_node_or_null("Camera2D") as Camera2D
	if arch_keeper:
		arch_keeper.global_position = Vector2(800, 1100)
	if arch_cam:
		arch_cam.position = Vector2(800, 1040)
	for _a: int in 3:
		await process_frame
	if not await _save_shot("/opt/cursor/artifacts/forge_arch.png"):
		quit(1)
		return
	print("CAPTURE_OK")
	quit(0)


func _save_shot(dest: String) -> bool:
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("CAPTURE_FAIL no viewport image")
		return false
	var err: Error = image.save_png(dest)
	if err != OK:
		print("CAPTURE_FAIL save %s %s" % [dest, err])
		return false
	print("CAPTURE_OK %s" % dest)
	return true
