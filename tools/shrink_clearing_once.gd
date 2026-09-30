extends SceneTree
## One-shot: shrink the 98ec4c3 clearing by 10% and close forest-ring gaps.
## Starts from the current scene. Does not restore an older layout and does not bake.
## Refuses to run again once play_width is already the tighter clearing.
##   godot --headless --path . --script res://tools/shrink_clearing_once.gd

const SCALE: float = 0.9
const PLAY: Vector2 = Vector2(4320, 3780)
const CLEAR_CENTER: Vector2 = Vector2(2160, 2025)
const CLEAR_RX: float = 1620.0
const CLEAR_RY: float = 1323.0
const PAIR_GAP: float = 64.0
const RUNE_TREE_GAP: float = 160.0
const TREE_MARGIN: float = 96.0

const SKIP: Array[String] = [
	"Manatree", "Keeper", "HarvestTree", "HarvestStone", "HarvestBerry", "Runestones", "EchoPortal",
]

const LANDMARKS: Dictionary = {
	"Manatree": Vector2(2160, 2106),
	"Keeper": Vector2(2080, 2460),
	"HarvestTree": Vector2(1200, 2100),
	"HarvestStone": Vector2(3300, 1900),
	"HarvestBerry": Vector2(2480, 2780),
	"EchoPortal": Vector2(2900, 1280),
}

const RUNESTONES: Dictionary = {
	"Runestone_might": Vector2(2000, 1000),
	"Runestone_arcana": Vector2(3200, 1600),
	"Runestone_resilience": Vector2(3300, 2500),
	"Runestone_ward": Vector2(2700, 2950),
	"Runestone_vitality": Vector2(1800, 2950),
	"Runestone_swiftness": Vector2(900, 2400),
	"Runestone_fate": Vector2(1100, 1500),
}

const BOWS: Dictionary = {
	"ToHarvestTree": 56.0,
	"ToHarvestStone": -56.0,
	"ToHarvestBerry": 48.0,
	"ToEchoPortal": -40.0,
	"ToMight": 52.0,
	"ToArcana": -48.0,
	"ToResilience": 44.0,
	"ToWard": -52.0,
	"ToVitality": 40.0,
	"ToSwiftness": -44.0,
	"ToFate": 36.0,
}


func _initialize() -> void:
	print("SHRINK_INIT")
	call_deferred("_shrink")


func _shrink() -> void:
	print("SHRINK_START")
	if OS.get_environment("MANAFORGE_BAKE") == "1":
		push_error("shrink: unset MANAFORGE_BAKE")
		quit(1)
		return
	var map_text: String = FileAccess.get_file_as_string("res://data/hub_map.json")
	var map_parsed: Variant = JSON.parse_string(map_text)
	if typeof(map_parsed) != TYPE_DICTIONARY:
		push_error("shrink: hub_map unreadable")
		quit(1)
		return
	var hub: Dictionary = map_parsed
	if float(hub.get("play_width", 0)) < 4500.0:
		push_error("shrink: play is already tighter than 4800; refusing to scale again")
		quit(1)
		return
	root.get_node("SaveService").set("boot_intent", "new")
	var game: Node = root.get_node("GameState")
	game.call("reset_for_new_game")
	game.set("welcome_shown", true)
	var packed_main: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var src: Node = packed_main.instantiate()
	root.add_child(src)
	await process_frame
	await process_frame
	var main: Node2D = src as Node2D
	var world: Node2D = main.get_node("World") as Node2D
	var scaled: int = 0
	for child: Node in world.get_children():
		if SKIP.has(child.name):
			continue
		var body: Node2D = child as Node2D
		if body == null:
			continue
		body.position *= SCALE
		scaled += 1
	for mark_name: String in LANDMARKS.keys():
		var mark: Node2D = world.get_node(mark_name) as Node2D
		mark.position = LANDMARKS[mark_name]
	var stones: Node2D = world.get_node("Runestones") as Node2D
	stones.position = Vector2.ZERO
	for stone_name: String in RUNESTONES.keys():
		(stones.get_node(stone_name) as Node2D).position = RUNESTONES[stone_name]
	_apply_clearing_fields(main)
	var pushed: int = _push_forest_off_landmarks(world)
	var added: int = _fill_ring(world)
	var ground: TileMap = main.get_node("Ground") as TileMap
	ground.clear()
	main.call("_build_grass")
	var camera: Camera2D = main.get_node("Camera2D") as Camera2D
	camera.limit_left = 180
	camera.limit_top = 180
	camera.limit_right = int(PLAY.x) - 180
	camera.limit_bottom = int(PLAY.y) - 180
	camera.position = (world.get_node("Manatree") as Node2D).position
	var click: ColorRect = main.get_node("ClickLayer") as ColorRect
	click.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click.position = Vector2.ZERO
	click.size = PLAY
	click.offset_left = 0.0
	click.offset_top = 0.0
	click.offset_right = PLAY.x
	click.offset_bottom = PLAY.y
	_reroute_paths(main)
	_nudge_decor(main)
	var open_gaps: int = _open_angles(world)
	var gap_ok: bool = _validate_spacing(world)
	if open_gaps > 0 or not gap_ok:
		push_error("shrink: layout failed gaps=%d spacing=%s" % [open_gaps, gap_ok])
		quit(1)
		return
	for wisp: Node in main.get_tree().get_nodes_in_group("wisp"):
		wisp.free()
	_claim(main, main)
	var packed := PackedScene.new()
	var err: Error = packed.pack(main)
	if err != OK:
		push_error("shrink: pack failed %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/main.tscn")
	if err != OK:
		push_error("shrink: save failed %s" % err)
		quit(1)
		return
	_write_hub_map(hub)
	print("SHRINK_OK scaled=%d pushed=%d added=%d play=%s limits=%d,%d,%d,%d" % [
		scaled, pushed, added, PLAY,
		camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom,
	])
	quit(0)


func _apply_clearing_fields(main: Node) -> void:
	main.set("play_size", PLAY)
	main.set("clearing_center", CLEAR_CENTER)
	main.set("clearing_rx", CLEAR_RX)
	main.set("clearing_ry", CLEAR_RY)
	main.set("_cols", int(ceili(PLAY.x / 64.0)))
	main.set("_rows", int(ceili(PLAY.y / 64.0)))
	var points: Array[Vector2] = [
		LANDMARKS["Manatree"],
		LANDMARKS["HarvestTree"],
		LANDMARKS["HarvestStone"],
		LANDMARKS["HarvestBerry"],
		LANDMARKS["Keeper"],
		LANDMARKS["EchoPortal"],
	]
	var radii: Array[float] = [400.0, 420.0, 160.0, 170.0, 120.0, 160.0]
	for stone_name: String in RUNESTONES.keys():
		points.append(RUNESTONES[stone_name])
		radii.append(110.0)
	main.set("clear_points", points)
	main.set("clear_radii", radii)


func _push_forest_off_landmarks(world: Node2D) -> int:
	var blocked: Array[Rect2] = _landmark_rects(world)
	var moved: int = 0
	for child: Node in world.get_children():
		if SKIP.has(child.name):
			continue
		if str(child.get("prop_kind")) == "decor":
			continue
		var body: Node2D = child as Node2D
		if body == null:
			continue
		var rect: Rect2 = _prop_rect(body)
		if not _hits_any(rect, blocked, 24.0):
			continue
		var dir: Vector2 = body.position - CLEAR_CENTER
		if dir.length() < 1.0:
			dir = Vector2.RIGHT
		dir = dir.normalized()
		for step: int in range(1, 48):
			var trial: Vector2 = body.position + dir * (18.0 * float(step))
			body.position = trial
			if not _hits_any(_prop_rect(body), blocked, 24.0):
				moved += 1
				break
	return moved


func _fill_ring(world: Node2D) -> int:
	var pools: Dictionary = _texture_pools(world)
	var tree_pool: Array = pools["tree"]
	var bush_pool: Array = pools["bush"]
	var solid: PackedScene = load("res://scenes/hub/forest_solid.tscn") as PackedScene
	var added: int = 0
	var tree_i: int = 0
	var bush_i: int = 0
	var rings: Array[Dictionary] = [
		{"norm": 1.06, "kind": "bush", "step": 72.0, "stagger": 0.0},
		{"norm": 1.22, "kind": "tree", "step": 96.0, "stagger": 0.5},
	]
	for ring: Dictionary in rings:
		var norm: float = float(ring["norm"])
		var kind: String = str(ring["kind"])
		var pool: Array = bush_pool if kind == "bush" else tree_pool
		var radius: float = _ring_radius(norm)
		var count: int = maxi(24, int(ceil(TAU * radius / float(ring["step"]))))
		var stagger: float = float(ring["stagger"]) * TAU / float(count)
		for i: int in range(count):
			var ang: float = TAU * float(i) / float(count) + stagger
			var sample: Vector2 = _on_ellipse(ang, norm)
			if _point_in_forest(world, sample, 8.0):
				continue
			var spec: Dictionary = pool[(bush_i if kind == "bush" else tree_i) % pool.size()]
			if kind == "bush":
				bush_i += 1
			else:
				tree_i += 1
			var vis: Vector2 = spec["vis"]
			var base: Vector2 = sample + Vector2(0, vis.y * 0.42)
			base.x = clampf(base.x, 24.0, PLAY.x - 24.0)
			base.y = clampf(base.y, 24.0, PLAY.y - 24.0)
			var preview := Rect2(base + Vector2(-vis.x * 0.5, -vis.y), vis)
			if _hits_any(preview, _landmark_rects(world), 36.0):
				continue
			if _point_in_forest(world, base, 18.0) and _point_in_forest(world, sample, 0.0):
				continue
			var prop: Node2D = solid.instantiate() as Node2D
			added += 1
			prop.name = "Ring%s_%04d" % [kind.capitalize(), added]
			prop.y_sort_enabled = true
			prop.position = base
			prop.set("texture_path", spec["path"])
			prop.set("prop_kind", kind)
			prop.set("sprite_scale", spec["scale"])
			prop.set("collider_size", spec["collider"])
			world.add_child(prop)
	return added


func _texture_pools(world: Node2D) -> Dictionary:
	var best: Dictionary = {}
	for child: Node in world.get_children():
		var path: String = str(child.get("texture_path"))
		var kind: String = str(child.get("prop_kind"))
		if path == "" or (kind != "tree" and kind != "bush"):
			continue
		var scale: float = float(child.get("sprite_scale"))
		if scale <= 0.0:
			scale = 1.0
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			continue
		var vis := Vector2(float(tex.get_width()), float(tex.get_height())) * scale
		var area: float = vis.x * vis.y
		if best.has(path) and float(best[path]["area"]) >= area:
			continue
		best[path] = {
			"path": path,
			"kind": kind,
			"scale": scale,
			"vis": vis,
			"area": area,
			"collider": child.get("collider_size"),
		}
	var trees: Array = []
	var bushes: Array = []
	for spec: Dictionary in best.values():
		if str(spec["kind"]) == "tree":
			trees.append(spec)
		else:
			bushes.append(spec)
	trees.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["area"]) > float(b["area"]))
	bushes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["area"]) > float(b["area"]))
	if trees.size() > 8:
		trees = trees.slice(0, 8)
	if bushes.size() > 8:
		bushes = bushes.slice(0, 8)
	return {"tree": trees, "bush": bushes}


func _reroute_paths(main: Node) -> void:
	var paths: Node2D = main.get_node("Paths") as Node2D
	var origin: Vector2 = LANDMARKS["Manatree"]
	var targets: Dictionary = {
		"ToHarvestTree": LANDMARKS["HarvestTree"],
		"ToHarvestStone": LANDMARKS["HarvestStone"],
		"ToHarvestBerry": LANDMARKS["HarvestBerry"],
		"ToEchoPortal": LANDMARKS["EchoPortal"],
		"ToMight": RUNESTONES["Runestone_might"],
		"ToArcana": RUNESTONES["Runestone_arcana"],
		"ToResilience": RUNESTONES["Runestone_resilience"],
		"ToWard": RUNESTONES["Runestone_ward"],
		"ToVitality": RUNESTONES["Runestone_vitality"],
		"ToSwiftness": RUNESTONES["Runestone_swiftness"],
		"ToFate": RUNESTONES["Runestone_fate"],
	}
	for line_name: String in targets.keys():
		var line: Line2D = paths.get_node(line_name) as Line2D
		var dest: Vector2 = targets[line_name]
		var delta: Vector2 = dest - origin
		var perp: Vector2 = Vector2(-delta.y, delta.x).normalized()
		var mid: Vector2 = (origin + dest) * 0.5 + perp * float(BOWS[line_name])
		line.points = PackedVector2Array([origin, mid, dest])
		var bend_name: String = "PatchBend" + line_name.trim_prefix("To")
		var bend: Node2D = paths.get_node_or_null(bend_name) as Node2D
		if bend:
			bend.position = mid
	var bases: Dictionary = {
		"PatchBaseManatree": origin,
		"PatchBaseHarvestTree": LANDMARKS["HarvestTree"],
		"PatchBaseHarvestStone": LANDMARKS["HarvestStone"],
		"PatchBaseHarvestBerry": LANDMARKS["HarvestBerry"],
		"PatchBasePortal": LANDMARKS["EchoPortal"],
		"PatchBaseMight": RUNESTONES["Runestone_might"],
		"PatchBaseArcana": RUNESTONES["Runestone_arcana"],
		"PatchBaseResilience": RUNESTONES["Runestone_resilience"],
		"PatchBaseWard": RUNESTONES["Runestone_ward"],
		"PatchBaseVitality": RUNESTONES["Runestone_vitality"],
		"PatchBaseSwiftness": RUNESTONES["Runestone_swiftness"],
		"PatchBaseFate": RUNESTONES["Runestone_fate"],
	}
	for patch_name: String in bases.keys():
		var patch: Node2D = paths.get_node(patch_name) as Node2D
		patch.position = bases[patch_name]
	if paths.has_method("_apply"):
		paths.call("_apply")


func _nudge_decor(main: Node) -> void:
	var moved: int = 0
	for node: Node in main.get_tree().get_nodes_in_group("forest_decor"):
		var body: Node2D = node as Node2D
		if body == null or bool(main.call("decor_spot_allowed", body.position)):
			continue
		var placed: bool = false
		for ring: int in range(1, 40):
			for step: int in range(16):
				var ang: float = TAU * float(step) / 16.0
				var trial: Vector2 = body.position + Vector2(cos(ang), sin(ang)) * (16.0 * float(ring))
				if trial.x < 16.0 or trial.y < 16.0 or trial.x > PLAY.x - 16.0 or trial.y > PLAY.y - 16.0:
					continue
				if bool(main.call("decor_spot_allowed", trial)):
					body.position = trial
					placed = true
					moved += 1
					break
			if placed:
				break
	print("SHRINK_DECOR_NUDGED %d" % moved)


func _validate_spacing(world: Node2D) -> bool:
	var named: Dictionary = {}
	for mark_name: String in ["HarvestTree", "HarvestStone", "HarvestBerry", "EchoPortal", "Keeper"]:
		named[mark_name] = _node_sprite_rect(world.get_node(mark_name))
	var stones: Node2D = world.get_node("Runestones") as Node2D
	for stone_name: String in RUNESTONES.keys():
		named[stone_name] = _node_sprite_rect(stones.get_node(stone_name))
	var keys: Array = named.keys()
	var min_gap: float = 1.0e9
	for i: int in range(keys.size()):
		for j: int in range(i + 1, keys.size()):
			var gap: float = _rect_gap(named[keys[i]], named[keys[j]])
			if gap < min_gap:
				min_gap = gap
	var tree_rect: Rect2 = named["HarvestTree"]
	var rune_gap: float = 1.0e9
	for stone_name: String in RUNESTONES.keys():
		rune_gap = minf(rune_gap, _rect_gap(tree_rect, named[stone_name]))
	var exclusion: Rect2 = _manatree_exclusion(LANDMARKS["Manatree"])
	var hidden: int = 0
	for mark_name: String in ["HarvestTree", "HarvestStone", "HarvestBerry", "EchoPortal"]:
		if named[mark_name].intersects(exclusion):
			hidden += 1
			print("SHRINK_HIDDEN %s" % mark_name)
	for stone_name: String in RUNESTONES.keys():
		if named[stone_name].intersects(exclusion):
			hidden += 1
			print("SHRINK_HIDDEN %s" % stone_name)
	print("MIN_PAIR_GAP %.2f" % min_gap)
	print("RUNE_TREE_GAP %.2f" % rune_gap)
	print("MANATREE_EXCLUSION %.1f %.1f %.1f %.1f" % [
		exclusion.position.x, exclusion.position.y, exclusion.size.x, exclusion.size.y,
	])
	return min_gap + 0.01 >= PAIR_GAP and rune_gap + 0.01 >= RUNE_TREE_GAP and hidden == 0


func _open_angles(world: Node2D) -> int:
	var open_n: int = 0
	var count: int = 180
	for i: int in range(count):
		var ang: float = TAU * float(i) / float(count)
		var covered: bool = false
		for norm: float in [1.02, 1.10, 1.18, 1.28]:
			if _point_in_forest(world, _on_ellipse(ang, norm), 6.0):
				covered = true
				break
		if not covered:
			open_n += 1
	print("FOREST_OPEN_ANGLES %d" % open_n)
	return open_n


func _point_in_forest(world: Node2D, point: Vector2, pad: float) -> bool:
	for child: Node in world.get_children():
		if SKIP.has(child.name):
			continue
		var kind: String = str(child.get("prop_kind"))
		if kind != "tree" and kind != "bush":
			continue
		var body: Node2D = child as Node2D
		if body == null:
			continue
		if _prop_rect(body).grow(pad).has_point(point):
			return true
	return false


func _landmark_rects(world: Node2D) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for mark_name: String in ["Manatree", "Keeper", "HarvestTree", "HarvestStone", "HarvestBerry", "EchoPortal"]:
		rects.append(_node_sprite_rect(world.get_node(mark_name)))
	var stones: Node2D = world.get_node("Runestones") as Node2D
	for stone_name: String in RUNESTONES.keys():
		rects.append(_node_sprite_rect(stones.get_node(stone_name)))
	## Ancient canopy, not the sapling that is on screen at boot.
	rects.append(_manatree_exclusion(LANDMARKS["Manatree"]).grow(-TREE_MARGIN))
	return rects


func _manatree_exclusion(origin: Vector2) -> Rect2:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/manatree/native/manatree_meta.json"))
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
	return union.grow(TREE_MARGIN)


func _prop_rect(body: Node2D) -> Rect2:
	var spr: Sprite2D = body.get_node_or_null("Sprite") as Sprite2D
	if spr == null or spr.texture == null:
		return Rect2(body.position, Vector2.ONE)
	return _aabb_of(spr)


func _node_sprite_rect(node: Node) -> Rect2:
	var spr: Node = node.get_node_or_null("Sprite")
	if spr == null:
		spr = node.get_node_or_null("Visual/Marker")
	if spr == null:
		spr = node.get_node_or_null("Stone")
	if spr is Sprite2D and (spr as Sprite2D).texture != null:
		return _aabb_of(spr as Sprite2D)
	if spr is AnimatedSprite2D:
		var anim: AnimatedSprite2D = spr as AnimatedSprite2D
		var tex: Texture2D = anim.sprite_frames.get_frame_texture(anim.animation, 0) if anim.sprite_frames else null
		if tex == null:
			return Rect2(anim.global_position, Vector2(128, 128))
		var local := Rect2(anim.offset, Vector2(float(tex.get_width()), float(tex.get_height())))
		return _transformed_rect(anim.global_transform, local)
	return Rect2((node as Node2D).global_position, Vector2(64, 64))


func _aabb_of(spr: Sprite2D) -> Rect2:
	var fw: float = float(spr.texture.get_width())
	var fh: float = float(spr.texture.get_height())
	if spr.hframes > 1:
		fw /= float(spr.hframes)
	if spr.vframes > 1:
		fh /= float(spr.vframes)
	return _transformed_rect(spr.global_transform, Rect2(spr.offset, Vector2(fw, fh)))


func _transformed_rect(xf: Transform2D, local: Rect2) -> Rect2:
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


func _rect_gap(a: Rect2, b: Rect2) -> float:
	var dx: float = maxf(a.position.x - b.end.x, b.position.x - a.end.x)
	var dy: float = maxf(a.position.y - b.end.y, b.position.y - a.end.y)
	if dx < 0.0 and dy < 0.0:
		return maxf(dx, dy)
	if dx < 0.0:
		return dy
	if dy < 0.0:
		return dx
	return sqrt(dx * dx + dy * dy)


func _hits_any(rect: Rect2, blocked: Array[Rect2], pad: float) -> bool:
	var grown: Rect2 = rect.grow(pad)
	for other: Rect2 in blocked:
		if grown.intersects(other):
			return true
	return false


func _on_ellipse(ang: float, norm: float) -> Vector2:
	return CLEAR_CENTER + Vector2(cos(ang) * CLEAR_RX * norm, sin(ang) * CLEAR_RY * norm)


func _ring_radius(norm: float) -> float:
	return sqrt((CLEAR_RX * CLEAR_RX + CLEAR_RY * CLEAR_RY) * 0.5) * norm


func _write_hub_map(hub: Dictionary) -> void:
	hub["version"] = "v0.1.16-tighter-clearing"
	hub["notes"] = [
		"Play area is 4320×3780, about 10% under the 4800×4200 clearing. The forest ring moved in with it, then gap sprites were added.",
		"scenes/main.tscn is the layout you edit. Do not run tools/bake_hub_layout.gd; it rebuilds the forest and wipes editor moves.",
		"These landmark coordinates match the scene so decor clearance stays off the nodes.",
		"World positions are not stored in the save, so older slots still load.",
	]
	hub["play_width"] = 4320
	hub["play_height"] = 3780
	hub["map_width_mult"] = 3.375
	hub["map_height_mult"] = 5.25
	var glade_v: Array = hub.get("glade", [])
	if glade_v.size() >= 4:
		hub["glade"] = [
			int(round(float(glade_v[0]) * SCALE)),
			int(round(float(glade_v[1]) * SCALE)),
			int(round(float(glade_v[2]) * SCALE)),
			int(round(float(glade_v[3]) * SCALE)),
		]
	hub["clearing"] = {"center": [2160, 2025], "rx": 1620, "ry": 1323}
	hub["landmarks"] = {
		"manatree": [2160, 2106],
		"keeper": [2080, 2460],
		"echo_portal": [2900, 1280],
		"harvest_tree": [1200, 2100],
		"harvest_stone": [3300, 1900],
		"harvest_berry": [2480, 2780],
	}
	var stone_rows: Array = []
	for stone_name: String in RUNESTONES.keys():
		var pos: Vector2 = RUNESTONES[stone_name]
		stone_rows.append({
			"stat": stone_name.trim_prefix("Runestone_"),
			"pos": [int(pos.x), int(pos.y)],
		})
	hub["runestones"] = stone_rows
	hub["clear_radii"] = [400, 420, 160, 170, 120]
	hub["extra_clear"] = [{"pos": [2900, 1280], "radius": 160}]
	var scatter_v: Variant = hub.get("scatter", [])
	if typeof(scatter_v) == TYPE_ARRAY:
		for entry_v: Variant in scatter_v:
			if typeof(entry_v) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_v
			var rect_v: Variant = entry.get("rect", [])
			if typeof(rect_v) == TYPE_ARRAY and (rect_v as Array).size() >= 4:
				var rect: Array = rect_v
				entry["rect"] = [
					int(round(float(rect[0]) * SCALE)),
					int(round(float(rect[1]) * SCALE)),
					int(round(float(rect[2]) * SCALE)),
					int(round(float(rect[3]) * SCALE)),
				]
	var file := FileAccess.open("res://data/hub_map.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(hub, "\t"))
	file.close()


func _claim(node: Node, scene_root: Node) -> void:
	if node != scene_root:
		node.owner = scene_root
	for child: Node in node.get_children():
		if child.scene_file_path != "":
			child.owner = scene_root
		else:
			_claim(child, scene_root)
