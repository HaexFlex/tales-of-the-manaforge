extends SceneTree
## Hover labels, one fading toast, Forge popup, Options help, and distinct shots.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/polish_smoke.gd

const OUT: String = "/opt/cursor/artifacts"

var _fails: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var save_service: Node = root.get_node("SaveService")
	var gs: Node = root.get_node("GameState")
	save_service.set("boot_intent", "new")
	save_service.set("boot_slot", 0)
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var live: Node = packed.instantiate()
	root.add_child(live)
	for _i: int in range(6):
		await process_frame
	var hud: Node = live.get_node("HUD")
	if hud.has_method("_on_welcome_dismiss"):
		hud.call("_on_welcome_dismiss")
	await create_timer(3.8).timeout
	_aim(live, Vector2(1520, 1640))
	await process_frame
	await process_frame

	_check(not _label_visible(live, "World/HarvestTree"), "harvest label hidden at rest")
	_check(not _label_visible(live, "World/HarvestStone"), "stone label hidden at rest")
	_check(not _label_visible(live, "World/HarvestBerry"), "berry label hidden at rest")
	_check(not _label_visible(live, "World/Keeper"), "keeper label hidden at rest")
	var mana_label: Node = live.get_node_or_null("World/Manatree/Label")
	_check(mana_label != null and not mana_label.visible, "manatree stage label hidden at rest")
	_check(str(mana_label.get("text")).find("Sapling") >= 0, "manatree hover text carries the stage")
	var nearby: int = 0
	for wisp: Node in get_nodes_in_group("wisp"):
		var lbl: Node = wisp.get_node_or_null("Label")
		if lbl and lbl.visible and str(lbl.get("text")) == "Nearby":
			nearby += 1
	_check(nearby == 0, "no permanent Nearby labels (got %d)" % nearby)
	var controls: Node = hud.get_node("Panel/ControlsHint")
	var stage: Node = hud.get_node("Panel/StageLabel")
	var selection: Node = hud.get_node("Panel/SelectionHint")
	_check(not controls.visible and str(controls.get("text")).find("Left-click: select") >= 0, "controls hint kept but hidden")
	_check(not stage.visible, "stage line hidden")
	_check(not selection.visible, "selection hint hidden")
	var help: Node = hud.get_node_or_null("Panel/HelpButton")
	_check(help != null and str(help.get("tooltip_text")).find("Right-click: command") >= 0, "help button tooltip")
	var status: Node = hud.get_node("Panel/StatusLabel")
	_check(not status.visible, "toast faded before the hub shot")
	var decor: int = get_nodes_in_group("forest_decor").size()
	_check(decor >= 280, "decor scatter is present (got %d)" % decor)

	await _shot(live, "pt_newgame_fresh.png")
	var fill_n: int = get_nodes_in_group("forest_fill").size()
	_check(fill_n >= 80, "outer forest fill (got %d)" % fill_n)

	_aim(live, Vector2(-4000, -4000))
	await _shot(live, "pt_corner_nw.png")
	_aim(live, Vector2(9000, -4000))
	await _shot(live, "pt_corner_ne.png")
	_aim(live, Vector2(-4000, 9000))
	await _shot(live, "pt_corner_sw.png")
	_aim(live, Vector2(9000, 9000))
	await _shot(live, "pt_corner_se.png")
	_check_corner_forest("1280")

	gs.call("_set_stage", &"mature")
	gs.call("set_resource", &"wood", 40)
	gs.call("set_resource", &"stone", 28)
	gs.call("set_resource", &"food", 16)
	gs.call("set_resource", &"manashards", 80)
	_aim(live, Vector2(1680, 1500))
	await _shot(live, "pt_midgame.png")

	var tree: Node = live.get_node("World/HarvestTree")
	var shape: Node2D = tree.get_node("CollisionShape2D") as Node2D
	await _hover_world(live, shape.global_position)
	_check(_label_visible(live, "World/HarvestTree"), "harvest label shows on hover")
	_check(not _label_visible(live, "World/HarvestStone"), "stone label stays hidden while hovering the tree")
	await _shot(live, "pt_hover_label.png")
	await _hover_world(live, Vector2(8, 8))
	_check(not _label_visible(live, "World/HarvestTree"), "harvest label hides when the pointer leaves")

	gs.emit_signal("status_message", "Gathered a bundle of wood.")
	await process_frame
	_check(status.visible, "toast visible")
	_check(str(status.get("text")).find("\n") < 0, "toast is a single line")
	_check(str(status.get("text")).find("Gathered") >= 0, "toast text")
	await create_timer(3.8).timeout
	_check(not status.visible, "toast faded out")

	var pause: Node = live.get_node("PauseMenu")
	pause.call("open_options_standalone")
	await process_frame
	var opt: Node = pause.get_node("OptionsPanel/OptionsControls")
	var opt_panel: CanvasItem = pause.get_node("OptionsPanel") as CanvasItem
	_check(opt_panel.is_visible_in_tree() and str(opt.get("text")).find("Left-click: select") >= 0, "options shows the controls")
	_check(str(opt.get("text")).find("pan camera") >= 0, "options shows camera help")
	pause.call("close_standalone")
	await process_frame

	gs.call("_set_stage", &"elder")
	gs.set("forge_key", true)
	hud.call("show_care_menu")
	await process_frame
	var care: Node = hud.get_node("CarePanel")
	_check(care.visible, "care open before the forge popup")
	var msg: String = str(hud.call("open_forge_entry"))
	_check(msg.find("Congratulations") >= 0, "forge congratulations")
	_check(not care.visible, "care hidden while the forge popup is open")
	_check(bool(hud.call("is_forge_popup_open")), "forge popup open")
	var popup: Control = hud.get_node("ForgePopup") as Control
	var close: Control = popup.get_node("Close") as Control
	var pc: float = popup.get_global_rect().get_center().x
	var cc: float = close.get_global_rect().get_center().x
	_check(abs(pc - cc) < 8.0, "forge close button centered (popup %.1f close %.1f)" % [pc, cc])
	hud.call("hide_forge_popup")
	await process_frame
	_check(care.visible, "care returns when the forge popup closes")
	_check(not bool(hud.call("is_forge_popup_open")), "forge popup closed")
	hud.call("hide_care_menu")

	var win: Window = root as Window
	win.size = Vector2i(960, 540)
	for _r: int in range(6):
		await process_frame
	var view_960: Vector2 = live.get_viewport().get_visible_rect().size
	print("VIEW960_WINDOW ", view_960)
	if live.has_method("_clamp_camera"):
		live.call("_clamp_camera")
	_aim(live, Vector2(1520, 1640))
	await _shot(live, "pt_hud_960.png")
	# A real 960×540 viewport (stretch off) sees a different slice at the same world inset.
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	win.size = Vector2i(960, 540)
	for _s: int in range(6):
		await process_frame
	var view_raw: Vector2 = live.get_viewport().get_visible_rect().size
	print("VIEW960_RAW ", view_raw)
	if live.has_method("_clamp_camera"):
		live.call("_clamp_camera")
	_aim(live, Vector2(-4000, -4000))
	await _edge_forest(live, "top", "960 nw top")
	await _edge_forest(live, "left", "960 nw left")
	_aim(live, Vector2(9000, -4000))
	await _edge_forest(live, "top", "960 ne top")
	await _edge_forest(live, "right", "960 ne right")
	_aim(live, Vector2(-4000, 9000))
	await _edge_forest(live, "bottom", "960 sw bottom")
	await _edge_forest(live, "left", "960 sw left")
	_aim(live, Vector2(9000, 9000))
	await _edge_forest(live, "bottom", "960 se bottom")
	await _edge_forest(live, "right", "960 se right")

	var names: PackedStringArray = PackedStringArray([
		"pt_newgame_fresh.png",
		"pt_corner_nw.png",
		"pt_corner_ne.png",
		"pt_corner_sw.png",
		"pt_corner_se.png",
		"pt_midgame.png",
		"pt_hover_label.png",
		"pt_hud_960.png",
	])
	var seen: Dictionary = {}
	for file_name: String in names:
		var md5: String = FileAccess.get_md5(OUT + "/" + file_name)
		_check(md5 != "" and not seen.has(md5), "distinct " + file_name)
		seen[md5] = file_name

	print("DECOR %d" % decor)
	if _fails == 0:
		print("POLISH_OK")
		quit(0)
	else:
		print("POLISH_FAIL %d" % _fails)
		quit(1)


func _label_visible(live: Node, path: String) -> bool:
	var node: Node = live.get_node_or_null(path + "/Label")
	return node != null and bool(node.get("visible"))


func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		_fails += 1
		print("FAIL ", message)


func _aim(live: Node, pos: Vector2) -> void:
	var cam: Camera2D = live.get_node("Camera2D") as Camera2D
	if live.has_method("_clamped_camera_pos"):
		cam.position = live.call("_clamped_camera_pos", pos)
	else:
		cam.position = pos


func _hover_world(live: Node, world_pos: Vector2) -> void:
	var cam: Camera2D = live.get_node("Camera2D") as Camera2D
	var screen: Vector2 = cam.get_canvas_transform() * world_pos
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	motion.relative = Vector2(2, 1)
	root.warp_mouse(screen)
	Input.parse_input_event(motion)
	for _i: int in range(4):
		await process_frame
		await physics_frame


func _check_corner_forest(tag: String) -> void:
	_check(_file_edge_forest(OUT + "/pt_corner_nw.png", "top") > 0.01, "%s nw top is forest" % tag)
	_check(_file_edge_forest(OUT + "/pt_corner_nw.png", "left") > 0.01, "%s nw left is forest" % tag)
	_check(_file_edge_forest(OUT + "/pt_corner_ne.png", "top") > 0.01, "%s ne top is forest" % tag)
	_check(_file_edge_forest(OUT + "/pt_corner_ne.png", "right") > 0.01, "%s ne right is forest" % tag)
	_check(_file_edge_forest(OUT + "/pt_corner_sw.png", "bottom") > 0.01, "%s sw bottom is forest" % tag)
	_check(_file_edge_forest(OUT + "/pt_corner_sw.png", "left") > 0.01, "%s sw left is forest" % tag)
	_check(_file_edge_forest(OUT + "/pt_corner_se.png", "bottom") > 0.01, "%s se bottom is forest" % tag)
	_check(_file_edge_forest(OUT + "/pt_corner_se.png", "right") > 0.01, "%s se right is forest" % tag)


func _file_edge_forest(path: String, edge: String) -> float:
	var img := Image.load_from_file(path)
	if img == null:
		return 0.0
	return _edge_gvar(img, edge)


func _edge_forest(live: Node, edge: String, message: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = live.get_viewport().get_texture().get_image()
	var gvar: float = 0.0
	if img != null:
		gvar = _edge_gvar(img, edge)
	# Color channels are 0–1, so variance is tiny. Flat grass sat near 0.002.
	_check(gvar > 0.01, "%s (gvar %.4f)" % [message, gvar])


func _edge_gvar(img: Image, edge: String) -> float:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var x0: int = 8
	var y0: int = 8
	var x1: int = w - 8
	var y1: int = h - 8
	var band: int = maxi(24, int(float(mini(w, h)) * 0.16))
	match edge:
		"top":
			y1 = mini(h, band)
		"bottom":
			y0 = maxi(0, h - band)
		"left":
			x1 = mini(w, band)
		"right":
			x0 = maxi(0, w - band)
	var sum: float = 0.0
	var sum2: float = 0.0
	var n: int = 0
	var y: int = y0
	while y < y1:
		var x: int = x0
		while x < x1:
			var g: float = img.get_pixel(x, y).g
			sum += g
			sum2 += g * g
			n += 1
			x += 8
		y += 4
	if n < 4:
		return 0.0
	var mean: float = sum / float(n)
	return sum2 / float(n) - mean * mean


func _shot(live: Node, file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = live.get_viewport().get_texture().get_image()
	if img == null:
		_check(false, "capture " + file_name)
		return
	var copy: Image = img.duplicate()
	var err: int = copy.save_png(OUT + "/" + file_name)
	_check(err == OK, "saved " + file_name)
