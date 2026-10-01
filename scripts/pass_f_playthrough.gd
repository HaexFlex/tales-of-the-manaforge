extends SceneTree
## Pre-merge playthrough for Pass F. Logic plus screenshots.
##   xvfb-run -a godot --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/pass_f_playthrough.gd

const OUT: String = "/opt/cursor/artifacts"
const SAVE_FILE: String = "/opt/cursor/artifacts/save_v8_from_main.json"
const HUB_W: int = 2160

var _fails: int = 0
var _area_fails: Dictionary = {}
var GS: Node
var SS: Node
var BP: Node
var EC: Node
var CS: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for area: String in ["title", "hub", "gather", "manatree", "echo", "save", "controls"]:
		_area_fails[area] = 0
	await process_frame
	await process_frame
	GS = root.get_node("GameState")
	SS = root.get_node("SaveService")
	BP = root.get_node("Backpack")
	EC = root.get_node("EchoChamber")
	CS = root.get_node("ContentStrings")
	SS.call("delete_save")
	await _title_and_new_game()
	var main: Node = current_scene
	if main == null or main.name != "Main":
		_fail("hub", "hub scene missing after New Game")
		_finish()
		return
	await _hub(main)
	await _gather(main)
	await _manatree(main)
	await _echo(main)
	await _controls(main)
	await _save_from_main()
	_finish()


func _finish() -> void:
	for area: String in ["title", "hub", "gather", "manatree", "echo", "save", "controls"]:
		var n: int = int(_area_fails[area])
		print("AREA %s %s" % [area, "PASS" if n == 0 else "FAIL"])
	print("PLAYTHROUGH_DONE fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(area: String, name: String, ok: bool, detail: String = "") -> void:
	var line: String = "%s  [%s] %s%s" % ["PASS" if ok else "FAIL", area, name, (" — " + detail) if detail != "" else ""]
	print(line)
	if not ok:
		_fails += 1
		_area_fails[area] = int(_area_fails[area]) + 1


func _fail(area: String, name: String) -> void:
	_check(area, name, false)


func _shot_view(filename: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("no viewport image %s" % filename)
		return
	img.save_png("%s/%s" % [OUT, filename])
	print("saved %s %dx%d" % [filename, img.get_width(), img.get_height()])


func _click(btn: Button) -> void:
	if btn == null:
		return
	btn.pressed.emit()
	await process_frame
	await process_frame


func _title_and_new_game() -> void:
	print("-- title --")
	change_scene_to_file("res://scenes/title_screen.tscn")
	for _i: int in range(8):
		await process_frame
	var title: Node = current_scene
	_check("title", "title scene", title != null and title.name == "TitleScreen")
	if title == null:
		return
	var cont: Button = title.get_node_or_null("Menu/BtnContinue") as Button
	var new_b: Button = title.get_node_or_null("Menu/BtnNewGame") as Button
	_check("title", "Continue hidden on a fresh profile", cont != null and not cont.visible)
	_check("title", "New Game visible", new_b != null and new_b.visible)
	await _shot_view("title.png")
	await _click(new_b)
	for _k: int in range(10):
		await process_frame
	var main: Node = current_scene
	_check("title", "New Game enters the hub at sapling", main != null and main.name == "Main" and str(GS.get("stage_id")) == "sapling" and int(GS.get("wood")) == 0)
	if main == null:
		return
	var welcome: CanvasItem = main.get_node_or_null("HUD/WelcomePanel") as CanvasItem
	var dismiss: Button = main.get_node_or_null("HUD/WelcomePanel/WelcomeDismiss") as Button
	if welcome and welcome.visible and dismiss:
		await _click(dismiss)
	_check("title", "welcome dismissed", welcome == null or not welcome.visible)


func _hub(main: Node) -> void:
	print("-- hub --")
	var keeper: CharacterBody2D = main.get_node("World/Keeper") as CharacterBody2D
	var start: Vector2 = keeper.global_position
	GS.call("select_keeper")
	var dest: Vector2 = start + Vector2(160, -40)
	keeper.call("move_to", dest, null)
	var arrived: bool = await _wait_near(keeper, dest, 14.0, 8.0)
	_check("hub", "Keeper walks to a point", arrived, "at %s want %s" % [str(keeper.global_position), str(dest)])
	var cam: Camera2D = main.get_node("Camera2D") as Camera2D
	_check("hub", "camera limits", cam.limit_left == 180 and cam.limit_top == 180 and cam.limit_right == 4140 and cam.limit_bottom == 3600)
	main.call("pan_camera", Vector2(-100000, -100000))
	var lo: Vector2 = main.call("camera_min")
	_check("hub", "camera clamps to the near corner", cam.position.distance_to(lo) < 1.5, str(cam.position))
	main.call("pan_camera", Vector2(100000, 100000))
	var hi: Vector2 = main.call("camera_max")
	_check("hub", "camera clamps to the far corner", cam.position.distance_to(hi) < 1.5, str(cam.position))
	main.call("focus_manatree")
	_check("hub", "trample paths", _paths_ok(main))
	var frame: Rect2 = _frame_rect(main)
	var zoom: float = float(HUB_W) / frame.size.x
	var out_h: int = maxi(2, int(round(frame.size.y * zoom)))
	var shot: SubViewport = _make_view(main, frame, zoom, out_h, HUB_W)
	for _i: int in range(3):
		await process_frame
	var img: Image = shot.get_texture().get_image()
	if img == null:
		_fail("hub", "hub render")
	else:
		img.save_png("%s/hub.png" % OUT)
		print("saved hub.png %dx%d" % [img.get_width(), img.get_height()])
		var open_n: int = _ring_open_count(img, frame, zoom)
		print("FOREST_OPEN_RAYS %d" % open_n)
		_check("hub", "forest ring has no open gap to the edge", open_n <= 12, "open rays %d" % open_n)
	shot.queue_free()


func _paths_ok(main: Node) -> bool:
	var paths: Node = main.get_node_or_null("Paths")
	if paths == null:
		return false
	var berry: Node2D = main.get_node("World/HarvestBerry") as Node2D
	var line: Line2D = paths.get_node_or_null("ToHarvestBerry") as Line2D
	if line == null or line.get_point_count() < 2:
		return false
	if line.get_point_position(line.get_point_count() - 1).distance_to(berry.position) > 1.5:
		return false
	if absf(line.width - 48.0) > 0.5:
		return false
	if line.texture == null or line.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		return false
	if line.texture_repeat != CanvasItem.TEXTURE_REPEAT_ENABLED:
		return false
	var needed: Array[String] = ["ToHarvestTree", "ToHarvestStone", "ToHarvestBerry", "ToEchoPortal"]
	for name: String in needed:
		var other: Line2D = paths.get_node_or_null(name) as Line2D
		if other == null or other.get_point_count() < 2 or other.texture == null:
			return false
	return true


func _gather(main: Node) -> void:
	print("-- gather --")
	var keeper: CharacterBody2D = main.get_node("World/Keeper") as CharacterBody2D
	GS.call("select_keeper")
	var berry: Node = main.get_node("World/HarvestBerry")
	var sprite: Sprite2D = berry.get_node("Sprite") as Sprite2D
	var vis: Vector2 = sprite.texture.get_size() * sprite.scale
	var shape_node: CollisionShape2D = berry.get_node("CollisionShape2D") as CollisionShape2D
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	_check("gather", "berry display is twice the 64 box", absf(vis.y - 128.0) < 1.0 and vis.x > 80.0 and vis.x <= 128.5, str(vis))
	_check("gather", "berry click matches the sprite", rect != null and rect.size.distance_to(vis) < 1.5, str(rect.size) if rect else "nil")
	_check("gather", "berry click sits on the sprite", shape_node.position.distance_to(Vector2(0, -vis.y * 0.5)) < 1.5)
	await physics_frame
	var space: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	var inside: Vector2 = (berry as Node2D).global_position + Vector2(30, -100)
	var outside: Vector2 = (berry as Node2D).global_position + Vector2(vis.x * 0.5 + 24.0, -vis.y * 0.5)
	_check("gather", "doubled bush catches a click the old box missed", _hits_node(space, inside, berry))
	_check("gather", "click outside the doubled bush misses it", not _hits_node(space, outside, berry))
	var berry_frame := Rect2((berry as Node2D).global_position + Vector2(-vis.x * 0.5, -vis.y) - Vector2(160, 80), vis + Vector2(320, 200))
	var berry_zoom: float = 720.0 / berry_frame.size.x
	var berry_h: int = maxi(2, int(round(berry_frame.size.y * berry_zoom)))
	var berry_view: SubViewport = _make_view(main, berry_frame, berry_zoom, berry_h, 720)
	for _i: int in range(3):
		await process_frame
	var berry_img: Image = berry_view.get_texture().get_image()
	if berry_img:
		berry_img.save_png("%s/berry_bush.png" % OUT)
		print("saved berry_bush.png %dx%d" % [berry_img.get_width(), berry_img.get_height()])
	berry_view.queue_free()
	var wood0: int = int(GS.call("get_resource", &"wood"))
	var stone0: int = int(GS.call("get_resource", &"stone"))
	var food0: int = int(GS.call("get_resource", &"food"))
	_check("gather", "harvest wood", await _harvest(keeper, main.get_node("World/HarvestTree"), &"wood", wood0))
	_check("gather", "harvest stone", await _harvest(keeper, main.get_node("World/HarvestStone"), &"stone", stone0))
	_check("gather", "harvest food", await _harvest(keeper, berry, &"food", food0))
	keeper.call("cancel_channel")


func _hits_node(space: PhysicsDirectSpaceState2D, point: Vector2, node: Node) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit: Dictionary in space.intersect_point(query, 8):
		if hit.get("collider") == node:
			return true
	return false


func _harvest(keeper: CharacterBody2D, node: Node, resource_id: StringName, before: int) -> bool:
	GS.call("select_keeper")
	var dest: Vector2 = node.call("approach_point")
	keeper.call("move_to", dest, node)
	var arrived: bool = await _wait_near(keeper, dest, 16.0, 20.0)
	if not arrived:
		print("harvest miss %s at %s want %s" % [resource_id, str(keeper.global_position), str(dest)])
		return false
	var t: float = 0.0
	while t < 2.5:
		await physics_frame
		t += root.get_physics_process_delta_time()
		if int(GS.call("get_resource", resource_id)) > before:
			return true
	print("harvest no yield %s count %s" % [resource_id, str(GS.call("get_resource", resource_id))])
	return false


func _manatree(main: Node) -> void:
	print("-- manatree --")
	var keeper: CharacterBody2D = main.get_node("World/Keeper") as CharacterBody2D
	var tree: Node2D = main.get_node("World/Manatree") as Node2D
	var hud: Node = main.get_node("HUD")
	GS.call("select_keeper")
	var water_at: Vector2 = tree.global_position + Vector2(0, 40)
	keeper.call("move_to", water_at, null)
	var at_tree: bool = await _wait_near(keeper, water_at, 16.0, 20.0)
	_check("manatree", "Keeper reaches the door sill", at_tree, str(keeper.global_position))
	var ess0: int = int(GS.get("essence"))
	var shards0: int = int(GS.get("manashards"))
	keeper.call("start_water_channel", tree)
	var watered: bool = await _wait_water(ess0, shards0)
	keeper.call("cancel_channel")
	_check("manatree", "watering pays shards and essence", watered, "essence %d shards %d" % [int(GS.get("essence")), int(GS.get("manashards"))])
	GS.call("set_resource", &"essence", 500)
	BP.call("add_item", "fertilizer", 50)
	var order: Array[String] = ["sapling", "young", "mature", "elder", "ancient"]
	for sid: String in order:
		_check("manatree", "stage %s" % sid, str(GS.get("stage_id")) == sid, "got %s" % str(GS.get("stage_id")))
		var anchor: Vector2 = tree.call("door_anchor_offset")
		_check("manatree", "%s door sill is the anchor" % sid, anchor.length() < 1.5, str(anchor))
		if sid == "ancient":
			break
		hud.call("show_care_menu")
		await process_frame
		var grow: Button = hud.get_node_or_null("CarePanel/ActionBand/PayButton") as Button
		_check("manatree", "Grow enabled at %s" % sid, grow != null and not grow.disabled)
		await _click(grow)
		await process_frame
	_check("manatree", "grew to Ancient", str(GS.get("stage_id")) == "ancient")
	var ess1: int = int(GS.get("essence"))
	keeper.call("start_water_channel", tree)
	var ancient_water: bool = await _wait_water(ess1, int(GS.get("manashards")))
	keeper.call("cancel_channel")
	_check("manatree", "watering still works at Ancient", ancient_water)
	var hidden: int = _hidden_by_tree(main)
	_check("manatree", "nothing hidden behind the grown tree", hidden == 0, "overlaps %d" % hidden)
	var ancient_frame := Rect2(tree.global_position + Vector2(-780, -1100), Vector2(1560, 1500))
	var ancient_zoom: float = 1400.0 / ancient_frame.size.x
	var ancient_h: int = maxi(2, int(round(ancient_frame.size.y * ancient_zoom)))
	var ancient_view: SubViewport = _make_view(main, ancient_frame, ancient_zoom, ancient_h, 1400)
	for _i: int in range(4):
		await process_frame
	var ancient_img: Image = ancient_view.get_texture().get_image()
	if ancient_img:
		ancient_img.save_png("%s/ancient_manatree.png" % OUT)
		print("saved ancient_manatree.png %dx%d" % [ancient_img.get_width(), ancient_img.get_height()])
	ancient_view.queue_free()
	_check("manatree", "grows granted wisps", int(GS.get("wisp_count")) >= 4, "count %d" % int(GS.get("wisp_count")))
	var targets: Array[String] = ["harvest_tree", "harvest_stone", "harvest_berry", "manatree"]
	var nodes: Array[Node] = [
		main.get_node("World/HarvestTree"),
		main.get_node("World/HarvestStone"),
		main.get_node("World/HarvestBerry"),
		tree,
	]
	for i: int in range(targets.size()):
		GS.call("select_wisp", i)
		nodes[i].call("apply_player_command")
		_check("gather", "wisp %d assigned to %s" % [i, targets[i]], str(GS.call("get_wisp_assignment", i)) == targets[i])


func _wait_water(ess_before: int, shards_before: int) -> bool:
	var t: float = 0.0
	while t < 2.5:
		await physics_frame
		t += root.get_physics_process_delta_time()
		if int(GS.get("essence")) > ess_before or int(GS.get("manashards")) > shards_before:
			return true
	return false


func _hidden_by_tree(main: Node) -> int:
	var origin: Vector2 = (main.get_node("World/Manatree") as Node2D).position
	var exclusion: Rect2 = _manatree_exclusion(origin)
	var hidden: int = 0
	var world: Node2D = main.get_node("World") as Node2D
	for mark_name: String in ["HarvestTree", "HarvestStone", "HarvestBerry", "EchoPortal"]:
		if _sprite_rect(world.get_node(mark_name)).intersects(exclusion):
			hidden += 1
			print("hidden %s" % mark_name)
	var stones: Node = world.get_node("Runestones")
	for stone: Node in stones.get_children():
		if _sprite_rect(stone).intersects(exclusion):
			hidden += 1
			print("hidden %s" % stone.name)
	return hidden


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
	return union.grow(96.0)


func _sprite_rect(node: Node) -> Rect2:
	var spr: Sprite2D = node.get_node_or_null("Sprite") as Sprite2D
	if spr == null:
		spr = node.get_node_or_null("Visual/Marker") as Sprite2D
	if spr == null:
		spr = node.get_node_or_null("Stone") as Sprite2D
	if spr == null or spr.texture == null:
		return Rect2((node as Node2D).global_position, Vector2.ONE)
	var fw: float = float(spr.texture.get_width())
	var fh: float = float(spr.texture.get_height())
	if spr.hframes > 1:
		fw /= float(spr.hframes)
	var sc: Vector2 = spr.global_scale
	var origin: Vector2 = spr.global_position + Vector2(spr.offset.x * sc.x, spr.offset.y * sc.y)
	return Rect2(origin, Vector2(fw * absf(sc.x), fh * absf(sc.y)))


func _echo(main: Node) -> void:
	print("-- echo --")
	GS.set("portal_unlocked", true)
	GS.set("portal_fee_paid", false)
	GS.set("echo_01_resolved", false)
	GS.set("echo_01_redeemed", false)
	GS.call("set_resource", &"essence", 40)
	var portal: Node = main.get_node("World/EchoPortal")
	portal.call("refresh_visibility")
	await process_frame
	_check("echo", "portal opens once unlocked", bool(portal.get("visible")))
	var paid: String = str(EC.call("try_pay_fee"))
	_check("echo", "fee paid", paid == "paid", paid)
	EC.call("open_battle", true)
	for _i: int in range(6):
		await process_frame
	var view: Node = root.get_node_or_null("EchoBattle")
	_check("echo", "battle view opens", view != null and bool(EC.get("in_battle")))
	var art: TextureRect = null
	if view:
		art = view.get_node_or_null("ChamberArt") as TextureRect
	var plate_ok: bool = art != null and art.visible and art.texture != null and art.texture.get_width() == 1280 and art.texture.get_height() == 720
	_check("echo", "ChamberArt plate", plate_ok)
	await _shot_view("echo_chamber.png")
	var guard: int = 0
	while view != null and guard < 40:
		guard += 1
		var ret: Button = view.get_node_or_null("ReturnButton") as Button
		if ret and ret.visible:
			await _click(ret)
			break
		var strike: Button = view.get_node_or_null("StrikeButton") as Button
		if strike and strike.visible:
			await _click(strike)
			continue
		var spare: Button = view.get_node_or_null("SpareButton") as Button
		if spare and spare.visible:
			await _click(spare)
			continue
		break
	for _j: int in range(4):
		await process_frame
	_check("echo", "battle ends", not bool(EC.get("in_battle")))
	var keeper: Node2D = main.get_node("World/Keeper") as Node2D
	var tree: Node2D = main.get_node("World/Manatree") as Node2D
	_check("echo", "return lands at the hub tree", current_scene == main and keeper.global_position.distance_to(tree.global_position + Vector2(0, 48)) < 8.0, str(keeper.global_position))


func _controls(main: Node) -> void:
	print("-- controls --")
	var hud: Node = main.get_node("HUD")
	var btn: Button = hud.get_node("Panel/HelpButton") as Button
	var icon: TextureRect = hud.get_node("Panel/HelpButton/HelpIcon") as TextureRect
	var expected: String = str(hud.call("_controls_line"))
	_check("controls", "tooltip text is the controls line", str(btn.tooltip_text) == expected and expected.find("Right-click: command") >= 0, str(btn.tooltip_text))
	var help_cell: AtlasTexture = HudIcons.cell(HudIcons.HELP)
	_check("controls", "icon is the help sheet cell", icon.texture == help_cell and icon.texture != null)
	var rect: Rect2 = btn.get_global_rect()
	var view_w: float = root.get_viewport().get_visible_rect().size.x
	_check("controls", "icon sits on the right", rect.position.x > view_w * 0.7, "x %.0f of %.0f" % [rect.position.x, view_w])
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", 0.05)
	var center: Vector2 = rect.get_center()
	for _n: int in range(8):
		var motion := InputEventMouseMotion.new()
		motion.position = center
		motion.global_position = center
		motion.relative = Vector2(0.5, 0.2)
		root.push_input(motion)
		Input.parse_input_event(motion)
		await process_frame
	var elapsed: float = 0.0
	var popup: PopupPanel = null
	while elapsed < 1.5:
		await process_frame
		elapsed += root.get_process_delta_time()
		popup = _find_tooltip()
		if popup:
			break
	var tip_text: String = _popup_text(popup)
	_check("controls", "hover shows the tooltip", popup != null and tip_text.find("Right-click: command") >= 0 and tip_text.find("Left-click: select") >= 0, tip_text)
	if popup:
		var tip_size := Vector2(popup.size)
		var on_right: bool = popup.position.x > view_w * 0.45 or (popup.position.x + tip_size.x) > rect.position.x
		var on_screen: bool = popup.position.x >= -2.0 and popup.position.y >= -2.0 and popup.position.x + tip_size.x <= view_w + 4.0
		_check("controls", "tooltip stays on screen to the right", on_right and on_screen, "pos %s size %s" % [str(popup.position), str(tip_size)])
	await _shot_view("controls_tooltip.png")


func _find_tooltip() -> PopupPanel:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node == null or not is_instance_valid(node):
			continue
		if node is PopupPanel and (node as Window).visible:
			return node as PopupPanel
		for child: Node in node.get_children():
			stack.append(child)
	return null


func _popup_text(popup: Node) -> String:
	if popup == null:
		return ""
	var stack: Array[Node] = [popup]
	var parts: PackedStringArray = PackedStringArray()
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Label:
			parts.append((node as Label).text)
		for child: Node in node.get_children():
			stack.append(child)
	return " ".join(parts)


func _save_from_main() -> void:
	print("-- save --")
	if not FileAccess.file_exists(SAVE_FILE):
		_fail("save", "v8 save from main is missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("save", "v8 save is not an object")
		return
	var root_d: Dictionary = parsed
	_check("save", "save version 8", int(root_d.get("save_version", 0)) == 8)
	var original: Variant = root_d.get("state", {})
	if typeof(original) != TYPE_DICTIONARY:
		_fail("save", "state missing")
		return
	SS.call("delete_save")
	var slot_path: String = str(SS.call("slot_path", 1))
	var out := FileAccess.open(slot_path, FileAccess.WRITE)
	if out == null:
		_fail("save", "could not write slot")
		return
	out.store_string(JSON.stringify(root_d, "\t"))
	out.close()
	GS.call("reset_for_new_game")
	var loaded: bool = bool(SS.call("load_game", 1))
	_check("save", "load_game accepts the main save", loaded)
	if not loaded:
		return
	var now: Dictionary = GS.call("to_save_dict")
	var missing: PackedStringArray = _missing(original, now, "state")
	_check("save", "no data loss against the main payload", missing.is_empty(), "\n".join(missing))
	_check("save", "missing arrow mode defaults to physical", str(now.get("arrow_mode", "")) == "physical")
	SS.set("boot_intent", "load")
	SS.set("boot_slot", 1)
	change_scene_to_file("res://scenes/main.tscn")
	for _i: int in range(8):
		await process_frame
	var main: Node = current_scene
	var stage_ok: bool = main != null and main.name == "Main" and str(GS.get("stage_id")) == str((original as Dictionary).get("stage_id", ""))
	_check("save", "loaded game boots that stage", stage_ok, str(GS.get("stage_id")))
	_check("save", "loaded wood", int(GS.get("wood")) == int((original as Dictionary).get("wood", -1)))
	_check("save", "loaded essence", int(GS.get("essence")) == int((original as Dictionary).get("essence", -1)))
	_check("save", "loaded wisps", int(GS.get("wisp_count")) == int((original as Dictionary).get("wisp_count", -1)))
	_check("save", "loaded forge key", bool(GS.get("forge_key")) == bool((original as Dictionary).get("forge_key", false)))


func _missing(original: Variant, loaded: Variant, path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if typeof(original) == TYPE_DICTIONARY and typeof(loaded) == TYPE_DICTIONARY:
		var src: Dictionary = original
		var dst: Dictionary = loaded
		for key: Variant in src.keys():
			var child: String = "%s.%s" % [path, str(key)]
			if not dst.has(key):
				out.append("missing %s" % child)
			else:
				out.append_array(_missing(src[key], dst[key], child))
		return out
	if typeof(original) == TYPE_ARRAY and typeof(loaded) == TYPE_ARRAY:
		var a: Array = original
		var b: Array = loaded
		if a.size() != b.size():
			out.append("size %s %d!=%d" % [path, a.size(), b.size()])
			return out
		for i: int in range(a.size()):
			out.append_array(_missing(a[i], b[i], "%s[%d]" % [path, i]))
		return out
	if not _same_value(original, loaded):
		out.append("%s %s != %s" % [path, str(original), str(loaded)])
	return out


func _same_value(a: Variant, b: Variant) -> bool:
	if (typeof(a) == TYPE_FLOAT or typeof(a) == TYPE_INT) and (typeof(b) == TYPE_FLOAT or typeof(b) == TYPE_INT):
		return absf(float(a) - float(b)) < 0.001
	if typeof(a) == TYPE_BOOL or typeof(b) == TYPE_BOOL:
		return bool(a) == bool(b)
	if typeof(a) == TYPE_STRING or typeof(b) == TYPE_STRING:
		return str(a) == str(b)
	return a == b


func _wait_near(body: Node2D, dest: Vector2, dist: float, timeout: float) -> bool:
	var t: float = 0.0
	while t < timeout:
		await physics_frame
		t += root.get_physics_process_delta_time()
		if body.global_position.distance_to(dest) <= dist:
			return true
	return false


func _make_view(live: Node, frame: Rect2, zoom: float, out_h: int, out_w: int) -> SubViewport:
	var shot := SubViewport.new()
	shot.size = Vector2i(out_w, out_h)
	shot.transparent_bg = false
	shot.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	shot.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	shot.world_2d = live.get_world_2d()
	root.add_child(shot)
	var cam := Camera2D.new()
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
		bounds = bounds.merge(_raw_sprite_aabb(spr))
	return bounds.grow(24.0)


func _raw_sprite_aabb(spr: Sprite2D) -> Rect2:
	var fw: float = float(spr.texture.get_width())
	var fh: float = float(spr.texture.get_height())
	if spr.hframes > 1:
		fw /= float(spr.hframes)
	var sc: Vector2 = spr.scale
	var origin: Vector2 = spr.global_position + Vector2(spr.offset.x * sc.x, spr.offset.y * sc.y)
	return Rect2(origin, Vector2(fw * absf(sc.x), fh * absf(sc.y)))


func _ring_open_count(img: Image, frame: Rect2, zoom: float) -> int:
	var center := Vector2(2160, 2025)
	var rx: float = 1620.0
	var ry: float = 1323.0
	var palette: Array[Color] = []
	var play := Rect2(Vector2.ZERO, Vector2(4320, 3780))
	for gy: int in range(8):
		for gx: int in range(8):
			var p := Vector2(center.x + (float(gx) - 3.5) * 140.0, center.y + (float(gy) - 3.5) * 110.0)
			if p.distance_to(Vector2(2160, 2106)) < 280.0:
				continue
			if not play.has_point(p):
				continue
			var c: Color = _sample(img, frame, zoom, p)
			if c.a < 0.5:
				continue
			palette.append(c)
	var open_n: int = 0
	for deg: int in range(360):
		var rad: float = float(deg) * PI / 180.0
		var samples: int = 0
		var all_grass: bool = true
		for t: float in [1.04, 1.12, 1.20, 1.28, 1.36]:
			var p := Vector2(center.x + cos(rad) * rx * t, center.y + sin(rad) * ry * t)
			if not play.has_point(p):
				continue
			samples += 1
			if not _near_palette(_sample(img, frame, zoom, p), palette):
				all_grass = false
				break
		if samples >= 3 and all_grass:
			open_n += 1
	return open_n


func _sample(img: Image, frame: Rect2, zoom: float, world: Vector2) -> Color:
	var x: int = clampi(int((world.x - frame.position.x) * zoom), 0, img.get_width() - 1)
	var y: int = clampi(int((world.y - frame.position.y) * zoom), 0, img.get_height() - 1)
	return img.get_pixel(x, y)


func _near_palette(c: Color, palette: Array[Color]) -> bool:
	for swatch: Color in palette:
		var d: float = absf(c.r - swatch.r) + absf(c.g - swatch.g) + absf(c.b - swatch.b)
		if d < 0.18:
			return true
	return false
