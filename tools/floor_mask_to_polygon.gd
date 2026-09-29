extends SceneTree
## Manual only. Turns a floor-mask PNG into a wall CollisionPolygon2D for the Forge room.
## Not an autoload. Do not run from MANAFORGE_BAKE or bake_hub_layout.
##   godot --headless --path . -s res://tools/floor_mask_to_polygon.gd -- res://path/mask.png
## Prints a PackedVector2Array. Paste it onto scenes/forge_room.tscn Walls/CollisionPolygon2D.

const BINS: int = 36


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: floor_mask_to_polygon.gd -- mask.png")
		quit(1)
		return
	var path: String = args[0]
	var image := Image.new()
	var err: Error = image.load(path)
	if err != OK:
		push_error("floor mask failed to load %s (%s)" % [path, error_string(err)])
		quit(1)
		return
	var points: PackedVector2Array = _outline(image)
	var parts: PackedStringArray = PackedStringArray()
	for i: int in range(points.size()):
		parts.append("%.1f, %.1f" % [points[i].x, points[i].y])
	print("PackedVector2Array(%s)" % ", ".join(parts))
	quit(0)


func _outline(image: Image) -> PackedVector2Array:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var sum := Vector2.ZERO
	var count: int = 0
	var min_x: int = width
	var min_y: int = height
	var max_x: int = 0
	var max_y: int = 0
	for y: int in range(height):
		for x: int in range(width):
			if not _floor_pixel(image, x, y):
				continue
			sum += Vector2(x, y)
			count += 1
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if count == 0:
		return PackedVector2Array()
	var center: Vector2 = sum / float(count)
	var inner: PackedVector2Array = PackedVector2Array()
	for bin: int in range(BINS):
		var ang: float = TAU * float(bin) / float(BINS)
		var dir := Vector2(sin(ang), cos(ang))
		var best := center
		var best_d: float = 0.0
		var steps: int = int(maxf(width, height))
		for step: int in range(steps):
			var p: Vector2 = center + dir * float(step)
			var ix: int = int(p.x)
			var iy: int = int(p.y)
			if ix < 0 or iy < 0 or ix >= width or iy >= height:
				break
			if _floor_pixel(image, ix, iy) and float(step) >= best_d:
				best = Vector2(ix, iy)
				best_d = float(step)
		inner.append(best)
	var gap: float = 160.0
	if FileAccess.file_exists("res://data/forge_tuning.json"):
		var file := FileAccess.open("res://data/forge_tuning.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				gap = float((parsed as Dictionary).get("door_gap_px", gap))
	var thick: float = 64.0
	var south: float = float(max_y)
	var ring: PackedVector2Array = PackedVector2Array()
	for i: int in range(inner.size()):
		var p: Vector2 = inner[i]
		if p.y > south - gap * 0.35 and absf(p.x - center.x) < gap * 0.5:
			continue
		ring.append(p)
	var outer: PackedVector2Array = PackedVector2Array()
	for i: int in range(ring.size()):
		var p: Vector2 = ring[i]
		var n: Vector2 = (p - center).normalized()
		if n == Vector2.ZERO:
			n = Vector2.DOWN
		outer.append(p + n * thick)
	outer.reverse()
	ring.append_array(outer)
	return ring


func _floor_pixel(image: Image, x: int, y: int) -> bool:
	var c: Color = image.get_pixel(x, y)
	if c.a > 0.5:
		return true
	return (c.r + c.g + c.b) / 3.0 > 0.5 and c.a >= 0.99
