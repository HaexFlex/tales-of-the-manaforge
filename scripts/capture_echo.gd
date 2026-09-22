extends SceneTree
## Echo Chamber screenshots.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_echo.gd


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
		push_error("capture_echo: main.tscn missing")
		quit(1)
		return
	var live: Node = packed.instantiate()
	root.add_child(live)
	for _i: int in range(4):
		await process_frame
	var hud: Node = live.get_node_or_null("HUD")
	if hud and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	if hud and hud.has_method("show_care_menu"):
		hud.call("show_care_menu")
	await process_frame
	_shot("/opt/cursor/artifacts/echo_forge_gray.png")
	if gs:
		gs.set("forge_key", true)
		gs.emit_signal("echo_flags_changed")
	if hud and hud.has_method("open_forge_entry"):
		hud.call("open_forge_entry")
	await process_frame
	_shot("/opt/cursor/artifacts/echo_forge_key.png")
	if hud and hud.has_method("hide_forge_popup"):
		hud.call("hide_forge_popup")
	if hud and hud.has_method("hide_care_menu"):
		hud.call("hide_care_menu")
	if gs:
		gs.set("forge_key", false)
		gs.set("portal_unlocked", true)
		gs.set("echo_01_resolved", false)
		gs.emit_signal("echo_flags_changed")
	var camera: Camera2D = live.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.position = Vector2(1560, 820)
	for _j: int in range(3):
		await process_frame
	_shot("/opt/cursor/artifacts/echo_portal.png")
	var portal: Node = live.get_node_or_null("World/EchoPortal")
	if portal and gs:
		gs.call("set_resource", &"essence", 30)
		portal.call("begin_entry")
		portal.call("confirm_fee")
	for _k: int in range(3):
		await process_frame
	_shot("/opt/cursor/artifacts/echo_battle.png")
	print("CAPTURE_OK")
	quit(0)


func _shot(path: String) -> void:
	var vp: Viewport = root.get_viewport()
	var tex: ViewportTexture = vp.get_texture()
	var img: Image = tex.get_image()
	if img == null:
		push_error("capture_echo: no image for %s" % path)
		return
	img.save_png(path)
	print("saved %s %dx%d" % [path, img.get_width(), img.get_height()])
