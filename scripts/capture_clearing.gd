extends SceneTree
## Top-down shot of the whole 4320×3780 clearing.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_clearing.gd

const OUT_PATH: String = "/opt/cursor/artifacts/clearing_topdown.png"
const PLAY: Vector2 = Vector2(4320, 3780)


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
	var window: Window = root.get_window()
	window.size = Vector2i(2160, 1890)
	var camera: Camera2D = live.get_node("Camera2D") as Camera2D
	camera.limit_left = -100000
	camera.limit_top = -100000
	camera.limit_right = 100000
	camera.limit_bottom = 100000
	camera.position = PLAY * 0.5
	camera.zoom = Vector2(0.5, 0.5)
	camera.enabled = true
	camera.make_current()
	var hud: CanvasItem = live.get_node_or_null("HUD") as CanvasItem
	if hud:
		hud.visible = false
	var pause: CanvasItem = live.get_node_or_null("PauseMenu") as CanvasItem
	if pause:
		pause.visible = false
	for _i: int in range(4):
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	var rendered: bool = img != null and img.get_width() > 64 and not _is_blank(img)
	if rendered:
		img.save_png(OUT_PATH)
		print("CAPTURE_RENDER %dx%d" % [img.get_width(), img.get_height()])
	else:
		_schematic(live).save_png(OUT_PATH)
		print("CAPTURE_SCHEMATIC")
	print("CAPTURE_OK")
	quit(0)


func _is_blank(img: Image) -> bool:
	var sample: Color = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	var corners: Array[Color] = [
		img.get_pixel(8, 8),
		img.get_pixel(img.get_width() - 8, 8),
		img.get_pixel(8, img.get_height() - 8),
	]
	for corner: Color in corners:
		if absf(corner.r - sample.r) + absf(corner.g - sample.g) + absf(corner.b - sample.b) > 0.04:
			return false
	return true


func _schematic(live: Node) -> Image:
	var scale: float = 0.25
	var img := Image.create(int(PLAY.x * scale), int(PLAY.y * scale), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.16, 0.28, 0.14, 1))
	var world: Node2D = live.get_node("World") as Node2D
	for child: Node in world.get_children():
		var kind: String = str(child.get("prop_kind"))
		if kind != "tree" and kind != "bush":
			continue
		var spr: Sprite2D = child.get_node_or_null("Sprite") as Sprite2D
		if spr == null or spr.texture == null:
			continue
		var rect: Rect2 = _aabb(spr)
		var col: Color = Color(0.05, 0.22, 0.08, 1) if kind == "tree" else Color(0.12, 0.38, 0.16, 1)
		_fill_rect(img, rect, scale, col)
	var paths: Node2D = live.get_node("Paths") as Node2D
	for child: Node in paths.get_children():
		if child is Line2D:
			var line: Line2D = child as Line2D
			for i: int in range(line.points.size() - 1):
				_line(img, line.points[i], line.points[i + 1], scale, Color(0.72, 0.62, 0.38, 1))
	var marks: Array[String] = ["HarvestTree", "HarvestStone", "HarvestBerry", "EchoPortal", "Keeper"]
	for mark_name: String in marks:
		var node: Node = world.get_node(mark_name)
		var spr: Node = node.get_node_or_null("Sprite")
		if spr == null:
			spr = node.get_node_or_null("Visual/Marker")
		if spr is Sprite2D and (spr as Sprite2D).texture != null:
			_stroke(img, _aabb(spr as Sprite2D), scale, Color(0.95, 0.85, 0.2, 1))
	var stones: Node2D = world.get_node("Runestones") as Node2D
	for stone: Node in stones.get_children():
		var spr: Sprite2D = stone.get_node_or_null("Stone") as Sprite2D
		if spr and spr.texture:
			_stroke(img, _aabb(spr), scale, Color(0.45, 0.75, 1.0, 1))
	var origin: Vector2 = (world.get_node("Manatree") as Node2D).position
	_stroke(img, _manatree_exclusion(origin), scale, Color(0.85, 0.25, 0.85, 1))
	_stroke(img, Rect2(Vector2.ZERO, PLAY), scale, Color(1, 1, 1, 1))
	return img


func _manatree_exclusion(origin: Vector2) -> Rect2:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/manatree/manatree_meta.json"))
	var union := Rect2()
	var first: bool = true
	for entry: Variant in (parsed as Dictionary).get("stages", []):
		var stage: Dictionary = entry
		var size_v: Array = stage.get("size", [0, 0])
		var door_v: Array = stage.get("door_floor", [0, 0])
		var sc: float = float(stage.get("display_scale", 1.0))
		var sz := Vector2(float(size_v[0]), float(size_v[1])) * sc
		var door := Vector2(float(door_v[0]), float(door_v[1])) * sc
		var rect := Rect2(origin + Vector2(-door.x, -door.y), sz)
		union = rect if first else union.merge(rect)
		first = false
	return union.grow(96.0)


func _aabb(spr: Sprite2D) -> Rect2:
	var fw: float = float(spr.texture.get_width())
	var fh: float = float(spr.texture.get_height())
	if spr.hframes > 1:
		fw /= float(spr.hframes)
	if spr.vframes > 1:
		fh /= float(spr.vframes)
	var xf: Transform2D = spr.global_transform
	var local := Rect2(spr.offset, Vector2(fw, fh))
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


func _fill_rect(img: Image, rect: Rect2, scale: float, col: Color) -> void:
	var x0: int = clampi(int(rect.position.x * scale), 0, img.get_width() - 1)
	var y0: int = clampi(int(rect.position.y * scale), 0, img.get_height() - 1)
	var x1: int = clampi(int(rect.end.x * scale), 0, img.get_width() - 1)
	var y1: int = clampi(int(rect.end.y * scale), 0, img.get_height() - 1)
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			img.set_pixel(x, y, col)


func _stroke(img: Image, rect: Rect2, scale: float, col: Color) -> void:
	var x0: int = clampi(int(rect.position.x * scale), 0, img.get_width() - 1)
	var y0: int = clampi(int(rect.position.y * scale), 0, img.get_height() - 1)
	var x1: int = clampi(int(rect.end.x * scale), 0, img.get_width() - 1)
	var y1: int = clampi(int(rect.end.y * scale), 0, img.get_height() - 1)
	for x: int in range(x0, x1 + 1):
		img.set_pixel(x, y0, col)
		img.set_pixel(x, y1, col)
	for y: int in range(y0, y1 + 1):
		img.set_pixel(x0, y, col)
		img.set_pixel(x1, y, col)


func _line(img: Image, a: Vector2, b: Vector2, scale: float, col: Color) -> void:
	var steps: int = int(a.distance_to(b) * scale)
	steps = maxi(steps, 1)
	for i: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps)) * scale
		var x: int = clampi(int(p.x), 0, img.get_width() - 1)
		var y: int = clampi(int(p.y), 0, img.get_height() - 1)
		img.set_pixel(x, y, col)
		if x + 1 < img.get_width():
			img.set_pixel(x + 1, y, col)
