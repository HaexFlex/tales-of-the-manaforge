extends SceneTree
## Debug-only full-clearing shots. Does not save the scene or change gameplay.
## The root window stays 1280×720 (canvas_items stretch), so this renders a
## SubViewport whose camera fits the play rect plus every forest sprite.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_clearing.gd

const OUT_DIR: String = "/opt/cursor/artifacts"
const OUT_W: int = 2160


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_service: Node = root.get_node_or_null("SaveService")
	var gs: Node = root.get_node_or_null("GameState")
	if save_service:
		save_service.set("boot_intent", "new")
	if gs:
		gs.call("reset_for_new_game")
		gs.set("welcome_shown", true)
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var live: Node = packed.instantiate()
	root.add_child(live)
	await process_frame
	## Boot intent "new" clears welcome_shown inside _enter_tree. Hide UI after that.
	if gs:
		gs.set("welcome_shown", true)
	_hide_ui(live)
	await process_frame
	var frame: Rect2 = _frame_rect(live)
	var zoom: float = float(OUT_W) / frame.size.x
	var out_h: int = maxi(2, int(round(frame.size.y * zoom)))
	var shot: SubViewport = _make_view(live, frame, zoom, out_h)
	for _i: int in range(3):
		await process_frame
	var sapling: Image = shot.get_texture().get_image()
	if not _image_ok(sapling, out_h):
		push_error("capture_clearing: sapling render failed")
		quit(1)
		return
	var sapling_path: String = OUT_DIR + "/clearing_topdown.png"
	sapling.save_png(sapling_path)
	_report("sapling", sapling, frame, zoom, live)
	if gs and gs.has_method("_set_stage"):
		gs.call("_set_stage", &"ancient")
	_hide_ui(live)
	for _j: int in range(4):
		await process_frame
	var ancient: Image = shot.get_texture().get_image()
	if not _image_ok(ancient, out_h):
		push_error("capture_clearing: ancient render failed")
		quit(1)
		return
	var ancient_path: String = OUT_DIR + "/clearing_topdown_ancient.png"
	ancient.save_png(ancient_path)
	_report("ancient", ancient, frame, zoom, live)
	print("CAPTURE_OK")
	quit(0)


func _hide_ui(live: Node) -> void:
	for node_name: String in ["HUD", "PauseMenu"]:
		var layer: CanvasItem = live.get_node_or_null(node_name) as CanvasItem
		if layer:
			layer.visible = false
			layer.process_mode = Node.PROCESS_MODE_DISABLED
	var welcome: CanvasItem = live.get_node_or_null("HUD/WelcomePanel") as CanvasItem
	if welcome:
		welcome.visible = false
	var tree_label: CanvasItem = live.get_node_or_null("World/Manatree/Label") as CanvasItem
	if tree_label:
		tree_label.visible = false
	var fruit: CanvasItem = live.get_node_or_null("World/Manatree/FruitHint") as CanvasItem
	if fruit:
		fruit.visible = false


func _make_view(live: Node, frame: Rect2, zoom: float, out_h: int) -> SubViewport:
	var shot := SubViewport.new()
	shot.name = "ClearingShot"
	shot.size = Vector2i(OUT_W, out_h)
	shot.transparent_bg = false
	shot.handle_input_locally = false
	shot.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	shot.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	shot.world_2d = live.get_world_2d()
	root.add_child(shot)
	var cam := Camera2D.new()
	cam.name = "ShotCamera"
	cam.enabled = true
	cam.position_smoothing_enabled = false
	cam.position = frame.get_center()
	cam.zoom = Vector2(zoom, zoom)
	shot.add_child(cam)
	cam.make_current()
	return shot


func _frame_rect(live: Node) -> Rect2:
	var play: Vector2 = live.call("get_play_size")
	var bounds := Rect2(Vector2.ZERO, play)
	var world: Node2D = live.get_node("World") as Node2D
	for child: Node in world.get_children():
		var kind: String = str(child.get("prop_kind"))
		if kind != "tree" and kind != "bush" and kind != "tuft" and kind != "decor":
			continue
		var spr: Sprite2D = child.get_node_or_null("Sprite") as Sprite2D
		if spr == null or spr.texture == null:
			continue
		bounds = bounds.merge(_sprite_aabb(spr))
	return bounds.grow(24.0)


func _sprite_aabb(spr: Sprite2D) -> Rect2:
	var fw: float = float(spr.texture.get_width())
	var fh: float = float(spr.texture.get_height())
	if spr.hframes > 1:
		fw /= float(spr.hframes)
	if spr.vframes > 1:
		fh /= float(spr.vframes)
	var local := Rect2(spr.offset, Vector2(fw, fh))
	var xf: Transform2D = spr.global_transform
	var pts: Array[Vector2] = [
		xf * local.position,
		xf * (local.position + Vector2(local.size.x, 0)),
		xf * (local.position + local.size),
		xf * (local.position + Vector2(0, local.size.y)),
	]
	var lo: Vector2 = pts[0]
	var hi: Vector2 = pts[0]
	for p: Vector2 in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2(lo, hi - lo)


func _report(tag: String, img: Image, frame: Rect2, zoom: float, live: Node) -> void:
	var keeper: Node2D = live.get_node("World/Keeper") as Node2D
	var tree: Node2D = live.get_node("World/HarvestTree") as Node2D
	print("CAPTURE_%s %dx%d zoom=%.4f frame=(%.1f,%.1f,%.1f,%.1f) keeper_px=%.1f tree_px=%.1f" % [
		tag.to_upper(), img.get_width(), img.get_height(), zoom,
		frame.position.x, frame.position.y, frame.size.x, frame.size.y,
		128.0 * zoom, 384.0 * zoom,
	])
	print("CAPTURE_%s_ANCHORS keeper=%s tree=%s" % [
		tag.to_upper(), _px(keeper.position, frame, zoom), _px(tree.position, frame, zoom),
	])


func _px(world: Vector2, frame: Rect2, zoom: float) -> String:
	var p: Vector2 = (world - frame.position) * zoom
	return "(%.0f,%.0f)" % [p.x, p.y]


func _image_ok(img: Image, out_h: int) -> bool:
	if img == null or img.get_width() != OUT_W or img.get_height() != out_h:
		return false
	var mid: Color = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	var corner: Color = img.get_pixel(4, 4)
	return absf(mid.r - corner.r) + absf(mid.g - corner.g) + absf(mid.b - corner.b) > 0.05
