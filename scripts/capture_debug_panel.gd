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
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("CAPTURE_FAIL no viewport image")
		quit(1)
		return
	var dest := "/opt/cursor/artifacts/debug_panel.png"
	var err: Error = image.save_png(dest)
	if err != OK:
		print("CAPTURE_FAIL save %s" % err)
		quit(1)
		return
	print("CAPTURE_OK %s" % dest)
	quit(0)
