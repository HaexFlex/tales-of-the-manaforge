extends RefCounted
## Permanent payout and scene checks for the lend-a-hand games.
## Runs inside verify_headless and scene_sanity, where the autoloads exist.


func run_payout() -> int:
	var failed: int = 0
	failed += _math()
	failed += _apply()
	failed += _save_stays_put()
	if failed == 0:
		print("MINIGAME_PAYOUT_OK")
	return failed


func run_scenes() -> int:
	var failed: int = 0
	var ids: PackedStringArray = MinigameCatalog.playable_ids()
	failed += _check(ids.size() == 8, "eight minigame scenes, got %d" % ids.size())
	for id: String in ids:
		var path: String = MinigameCatalog.scene_path(id)
		var packed: PackedScene = load(path) as PackedScene
		failed += _check(packed != null, "scene loads %s" % id)
		if packed == null:
			continue
		var node: Node = packed.instantiate()
		failed += _check(node is Minigame, "%s is a Minigame" % id)
		failed += _check(node.has_method("game_id") and str(node.call("game_id")) == id, "%s game_id" % id)
		node.free()
	failed += _check(MinigameCatalog.game_for("crucible") == "hot_spots", "Hot Spots is offered at the Crucible")
	failed += _check(MinigameCatalog.game_for("anvil") == "hot_spots", "Hot Spots is offered at the Anvil")
	failed += _check(MinigameCatalog.game_for("reliquary") == "hot_spots", "Hot Spots is offered at the Reliquary")
	failed += _check(MinigameCatalog.hot_spot_points("anvil").size() == 7, "anvil has the seven blade points")
	failed += _check(MinigameCatalog.hot_spot_points("crucible").size() == 15, "crucible has the fifteen bubble points")
	failed += _check(MinigameCatalog.hot_spot_points("reliquary").size() == 9, "reliquary has the nine rune points")
	failed += _hot_spots_switch()
	failed += _woodsong_volume()
	failed += _grain_shapes()
	failed += _steeping_debug()
	failed += _grade_marks()
	failed += _just_enough_band()
	failed += _check(MinigameCatalog.game_for("brewing") == "steeping", "steeping stays mapped to brewing")
	failed += _check(not MinigameCatalog.is_reachable("steeping"), "steeping has no world station, so it stays unreachable")
	failed += _summary()
	failed += _world_hover()
	if failed == 0:
		print("MINIGAME_SCENES_OK")
	return failed


func _hot_spots_switch() -> int:
	var failed: int = 0
	var node: Node = (load("res://scenes/minigames/hot_spots.tscn") as PackedScene).instantiate()
	Engine.get_main_loop().root.add_child(node)
	for station_id: String in ["anvil", "crucible", "reliquary"]:
		failed += _check(node.get_node_or_null("Station_%s" % station_id) != null, "hot spots switcher has %s" % station_id)
	node.call("_switch_station", "reliquary")
	var plate: Sprite2D = node.get_node_or_null("Plate") as Sprite2D
	var plate_path: String = str(plate.texture.resource_path) if plate != null and plate.texture != null else ""
	failed += _check(plate_path.ends_with("close_reliquary.png"), "switcher shows the reliquary plate")
	node.call("_drop_miss", {"x": 40.0, "y": 40.0, "sprite": null})
	var miss: Sprite2D = node.get_node_or_null("MissPip") as Sprite2D
	var miss_path: String = str(miss.texture.resource_path) if miss != null and miss.texture != null else ""
	failed += _check(miss_path.ends_with("spot_miss.png"), "an expired spot leaves the crossed miss mark, not a success pip")
	node.free()
	return failed


func _woodsong_volume() -> int:
	var failed: int = 0
	var node: Node = (load("res://scenes/minigames/woodsong.tscn") as PackedScene).instantiate()
	Engine.get_main_loop().root.add_child(node)
	var vol: Control = node.get_node_or_null("Volume") as Control
	failed += _check(vol != null, "woodsong builds a volume plate")
	failed += _check(node.get_node_or_null("Volume/Fill") != null and node.get_node_or_null("Volume/Grab") != null, "woodsong volume has fill and grab")
	var rail: Sprite2D = node.get_node_or_null("beat_rail") as Sprite2D
	var rail_plate: ColorRect = node.get_node_or_null("RailPlate") as ColorRect
	failed += _check(rail != null and rail.position.y < 80.0, "woodsong beat rail stays at the top")
	failed += _check(rail_plate != null and rail_plate.color.r > 0.85, "the woodsong rail sits on a light plate")
	var before: float = Woodsong._saved_volume
	node.call("begin")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_BRACKETLEFT
	node.call("on_key", key)
	failed += _check(is_equal_approx(Woodsong._saved_volume, before - 0.1), "woodsong [ lowers the tune")
	Woodsong._saved_volume = before
	node.call("_paint_volume")
	node.free()
	var host: Node = Engine.get_main_loop().root.get_node_or_null("MinigameHost")
	failed += _check(host != null, "woodsong chrome check has the host")
	if host == null:
		return failed
	var frozen: bool = GameState.ancient_frozen
	GameState.ancient_frozen = false
	host.call("close_immediate")
	var opened: bool = bool(host.call("open_game", "woodsong", "keeper", "wood"))
	failed += _check(opened, "woodsong opens so the music controls can leave the play field")
	if opened:
		var window: Node = host.get_node_or_null("MinigameRoot/Window")
		var play: Control = window.get_node_or_null("Play") as Control if window != null else null
		var seated: Control = window.get_node_or_null("Volume") as Control if window != null else null
		var tune: Control = window.get_node_or_null("Tune") as Control if window != null else null
		failed += _check(seated != null and tune != null, "music and volume sit on the window, not the play field")
		failed += _check(play != null and seated != null and seated.position.y + seated.size.y <= play.position.y, "volume stays above the play field")
		failed += _check(play != null and tune != null and tune.position.y + tune.size.y <= play.position.y, "Music On stays above the play field")
		var window_ctl: Control = window as Control
		var host_fit_x: float = window_ctl.size.x / MinigameCatalog.WINDOW_SIZE.x if window_ctl != null else 1.0
		failed += _check(play != null and is_equal_approx(play.scale.x, host_fit_x), "woodsong keeps the play field full width")
		host.call("close_immediate")
	GameState.ancient_frozen = frozen
	return failed


func _grain_shapes() -> int:
	var failed: int = 0
	var node: Node = (load("res://scenes/minigames/with_the_grain.tscn") as PackedScene).instantiate()
	Engine.get_main_loop().root.add_child(node)
	var want: PackedStringArray = PackedStringArray([
		"rod", "head", "plank", "s_curve", "spiral", "wave", "loop", "heart", "leaf", "zigzag",
		"arch", "vee", "tick", "stairs", "diamond", "hook", "circle", "figure8", "crescent", "bell",
	])
	var panel := Rect2(148, 34, 424, 272)
	for i: int in want.size():
		node.set("_shape_i", i)
		var pts: PackedVector2Array = node.call("_path_for", want[i])
		var expect: int = 20 if i < 3 else 32
		failed += _check(pts.size() == expect, "%s has %d points, got %d" % [want[i], expect, pts.size()])
		var inside: bool = pts.size() > 1
		for p: Vector2 in pts:
			if not panel.grow(1.0).has_point(p):
				inside = false
		failed += _check(inside, "%s stays on the workpiece" % want[i])
	var grass: Sprite2D = node.get_node_or_null("bg_grass") as Sprite2D
	var grass_path: String = str(grass.texture.resource_path) if grass != null and grass.texture != null else ""
	failed += _check(grass_path.ends_with("bg_grass.png"), "grain uses the clearing, not the forge rug")
	failed += _check(node.get_node_or_null("bg_forge") == null, "the forge rug is not in the grain scene")
	failed += _check(node.clip_contents, "grain clips art that would stick out of the play window")
	var bench: Sprite2D = node.get_node_or_null("st_bench") as Sprite2D
	if bench == null:
		failed += _check(false, "grain keeps the workbench")
	else:
		var sx: float = bench.scale.x
		var sy: float = bench.scale.y
		var left: float = bench.position.x + (2.0 - 96.0) * sx
		var right: float = bench.position.x + (185.0 - 96.0) * sx
		var top: float = bench.position.y + (66.0 - 96.0) * sy
		var bottom: float = bench.position.y + (190.0 - 96.0) * sy
		var board := Rect2(148, 34, 424, 272)
		failed += _check(board.encloses(Rect2(left, top, right - left, bottom - top)), "the workbench stays inside the board (%.0f,%.0f)-(%.0f,%.0f)" % [left, top, right, bottom])
	node.set("_shape_i", 0)
	var rod: PackedVector2Array = node.call("_path_for", "rod")
	var origin := Vector2(148.0 + 0.277365 * 424.0, 34.0 + 0.422701 * 272.0)
	failed += _check(rod.size() > 0 and rod[0].distance_to(origin) < 0.05, "rod uses the prototype seed")
	node.free()
	return failed


func _steeping_debug() -> int:
	var failed: int = 0
	var host: Node = Engine.get_main_loop().root.get_node_or_null("MinigameHost")
	failed += _check(host != null, "steeping check has the minigame host")
	if host == null:
		return failed
	var frozen: bool = GameState.ancient_frozen
	GameState.ancient_frozen = false
	host.call("close_immediate")
	failed += _check(not bool(host.call("open_game", "steeping", "keeper", "brewing")), "the world cannot open steeping")
	failed += _check(bool(host.call("debug_open", "steeping")), "the debug panel can open steeping")
	var game: Node = null
	var play: Node = host.get_node_or_null("MinigameRoot/Window/Play")
	if play != null:
		for child: Node in play.get_children():
			if child is Steeping:
				game = child
	failed += _check(game != null, "steeping scene is open from the debug entry")
	if game != null:
		failed += _check(is_equal_approx(float(game.get("_k")), 21.2), "open steeping pays 21.2")
		failed += _check(is_equal_approx(float(game.get("_show_each")), 1.2), "steeping shows each herb for 1.2s")
		failed += _check(is_equal_approx(float(game.get("_hold")), 1.0), "steeping holds the order for 1s")
		failed += _check(is_equal_approx(float(game.get("_input_sec")), 10.0), "steeping gives 10s to pick")
		failed += _check(int(game.get("_replays_max")) == 1, "steeping allows one replay")
		failed += _check(is_equal_approx(float(game.get("_gap")), 0.8), "steeping waits 0.8s before the next order")
		failed += _check(game.get_node_or_null("TimerFill") == null and game.get_node_or_null("TimerTrack") == null, "steeping draws no timer line across the order")
		var replay: CanvasItem = game.get_node_or_null("Replay") as CanvasItem
		failed += _check(replay != null and not replay.visible, "the grey replay square stays hidden until a replay is offered")
	var panel_src: String = FileAccess.get_file_as_string("res://tools/debug/debug_panel.gd")
	failed += _check(panel_src.find("Open Steeping") >= 0, "debug panel lists Steeping")
	host.call("close_immediate")
	GameState.ancient_frozen = frozen
	return failed


func _grade_marks() -> int:
	var failed: int = 0
	var host: Node = Engine.get_main_loop().root.get_node_or_null("MinigameHost")
	failed += _check(host != null, "grade check has the minigame host")
	if host == null:
		return failed
	var frozen: bool = GameState.ancient_frozen
	var stage: StringName = GameState.stage_id
	var food: int = GameState.get_resource(&"food")
	var accum: Dictionary = (GameState.harvest_accum as Dictionary).duplicate()
	GameState.ancient_frozen = false
	GameState.stage_id = &"sapling"
	host.call("close_immediate")
	var opened: bool = bool(host.call("open_game", "ripe_catch", "keeper", "food"))
	failed += _check(opened, "grade check can open a game")
	if not opened:
		GameState.ancient_frozen = frozen
		GameState.stage_id = stage
		GameState.harvest_accum = accum
		GameState.set_resource(&"food", food)
		return failed
	var window: Node = host.get_node_or_null("MinigameRoot/Window")
	var plate: TextureRect = window.get_node_or_null("WinPlate") as TextureRect if window != null else null
	var plate_path: String = ""
	if plate != null and plate.texture is AtlasTexture:
		var atlas: AtlasTexture = plate.texture as AtlasTexture
		plate_path = str(atlas.atlas.resource_path) if atlas.atlas != null else ""
	failed += _check(plate_path.ends_with("win_ripe_catch_pc.png"), "the window uses the ripe catch win plate")
	var blot: Control = window.get_node_or_null("WinPlate/FeelTestCover") as Control
	failed += _check(blot != null, "the baked feel-test line stays covered")
	failed += _check(blot != null and blot.anchor_left < 0.1 and blot.anchor_right > 0.9, "the old instruction line is covered across the footer")
	failed += _check(blot != null and blot.anchor_top <= 408.0 / 472.0 and blot.anchor_bottom >= 440.0 / 472.0, "the baked flavour line is covered across the footer")
	var pace_lbl: Label = window.get_node_or_null("Pace") as Label
	var bar: Control = window.get_node_or_null("PaceBar") as Control
	var closer: Control = window.get_node_or_null("Close") as Control
	failed += _check(pace_lbl != null and int(pace_lbl.get_theme_font_size(&"font_size")) == 19, "the pace readout is 19px")
	failed += _check(window.get_node_or_null("Successes") != null and window.get_node_or_null("PaceWord") != null, "Successes and Pace are labeled")
	var pip0: Control = window.get_node_or_null("GradePip0") as Control
	failed += _check(pip0 != null and is_equal_approx(pip0.size.y, 19.0), "grade pips are 19px")
	var ticks: int = 0
	if bar != null:
		for child: Node in bar.get_children():
			if str(child.name).begins_with("Tick"):
				var tick: Control = child as Control
				ticks += 1
				failed += _check(tick != null and tick.size.y > bar.size.y, "pace ticks stick out of the bar")
	failed += _check(ticks == 3, "the pace bar has three ticks")
	failed += _check(bar != null and pace_lbl != null and bar.position.x + bar.size.x <= pace_lbl.position.x - 4.0, "the pace readout clears the bar")
	failed += _check(pace_lbl != null and closer != null and pace_lbl.position.x + pace_lbl.size.x <= closer.position.x - 4.0, "the pace readout clears the close button")
	var vs: Vector2 = Ui540.viewport_size()
	var shortcut_top: float = vs.y - Ui540.SAFE_MARGIN_PX - Ui540.TAP_MIN_PX
	var window_ctl: Control = window as Control
	var bottom: float = window_ctl.position.y + window_ctl.size.y if window_ctl != null else 9999.0
	failed += _check(bottom <= shortcut_top - 4.0, "the window stays above the HUD buttons (bottom %.0f)" % bottom)
	var play_field: Control = window.get_node_or_null("Play") as Control
	if play_field != null and window_ctl != null:
		var fit := Vector2(window_ctl.size.x / MinigameCatalog.WINDOW_SIZE.x, window_ctl.size.y / MinigameCatalog.WINDOW_SIZE.y)
		var visual := Rect2(play_field.position, play_field.size * play_field.scale)
		var content := Rect2(MinigameCatalog.PLAY_ORIGIN * fit, MinigameCatalog.PLAY_SIZE * fit)
		failed += _check(visual.position.distance_to(content.position) < 1.0 and visual.size.distance_to(content.size) < 1.0, "the play field fills the window content rect")
		var right_gap: float = window_ctl.size.x - visual.end.x
		failed += _check(right_gap < 40.0, "no empty strip on the right of the play field (%.0f px)" % right_gap)
	host.call("note_success", 3.0, 2.0)
	var pop: Control = window.get_node_or_null("PacePop") as Control
	var play: Control = window.get_node_or_null("Play") as Control
	failed += _check(pop != null and pop.get_node_or_null("Chip") != null, "the +k pop sits on a parchment chip")
	failed += _check(pop != null and play != null and pop.position.y + pop.size.y <= play.position.y + 1.0, "the +k pop stays above the play art")
	host.call("note_miss")
	host.call("note_success", 3.0, 1.0)
	failed += _check(_pip_file(window, "GradePip0") == "pip_perfect.png", "a heavy success is a perfect pip")
	failed += _check(_pip_file(window, "GradePip1") == "pip_miss.png", "a miss is a grey pip")
	failed += _check(_pip_file(window, "GradePip2") == "pip_good.png", "a normal success is a good pip")
	failed += _check(_pip_file(window, "GradePip3") == "pip_empty.png", "unused grades stay empty")
	var summary: Node = window.get_node_or_null("Summary") if window != null else null
	failed += _check(summary != null and summary.get_node_or_null("PlayAgain") != null, "Play again is already on the card")
	failed += _check(_pip_file(summary, "GradePip1") == "pip_miss.png", "the card shows the same grades")
	failed += _check(host.find_child("StreakGlow", true, false) == null, "there is no streak glow to add")
	host.call("close_immediate")
	failed += _check(bool(host.call("open_game", "hot_spots", "keeper", "anvil")), "hot spots still opens")
	var hot_plate: TextureRect = host.get_node_or_null("MinigameRoot/Window/WinPlate") as TextureRect
	var hot_path: String = ""
	if hot_plate != null and hot_plate.texture is AtlasTexture:
		var hot_atlas: AtlasTexture = hot_plate.texture as AtlasTexture
		hot_path = str(hot_atlas.atlas.resource_path) if hot_atlas.atlas != null else ""
	failed += _check(hot_path.ends_with("win_forge_glow_pc.png"), "Hot Spots uses the forge glow win plate")
	host.call("close_immediate")
	GameState.ancient_frozen = frozen
	GameState.stage_id = stage
	GameState.harvest_accum = accum
	GameState.set_resource(&"food", food)
	return failed


func _just_enough_band() -> int:
	var failed: int = 0
	var node: Node = (load("res://scenes/minigames/just_enough.tscn") as PackedScene).instantiate()
	Engine.get_main_loop().root.add_child(node)
	node.set("_clock", 0.0)
	failed += _check(is_equal_approx(float(node.call("_band_lo")), 0.61), "water band starts at 0.61")
	failed += _check(is_equal_approx(float(node.call("_band_hi")), 0.71), "water band starts at 0.71")
	node.set("_clock", 1.5)
	failed += _check(is_equal_approx(float(node.call("_band_mid")), 0.78), "water band drifts up to 0.78")
	node.call("_layout_gauge")
	var band: ColorRect = node.get_node_or_null("Band") as ColorRect
	var bracket: ColorRect = node.get_node_or_null("BandTop") as ColorRect
	failed += _check(band != null and band.color.a > 0.95 and band.color.g > 0.55, "the water band is a solid green")
	failed += _check(bracket != null and bracket.color.r > 0.9 and bracket.size.y >= 3.0, "gold brackets mark the water band")
	node.free()
	return failed


func _pip_file(parent: Node, node_name: String) -> String:
	if parent == null:
		return ""
	var pip: TextureRect = parent.get_node_or_null(node_name) as TextureRect
	if pip == null or pip.texture == null:
		return ""
	var path: String = str(pip.texture.resource_path)
	return path.get_file()


func _summary() -> int:
	var failed: int = 0
	var host: Node = Engine.get_main_loop().root.get_node_or_null("MinigameHost")
	failed += _check(host != null, "minigame host is loaded")
	if host == null:
		return failed
	var frozen: bool = GameState.ancient_frozen
	GameState.ancient_frozen = false
	host.call("close_immediate")
	var opened: bool = bool(host.call("open_game", "ripe_catch", "keeper", "food"))
	failed += _check(opened, "summary check can open a game")
	if not opened:
		host.call("close_immediate")
		GameState.ancient_frozen = frozen
		return failed
	var window: Node = host.get_node("MinigameRoot/Window")
	var play: Control = window.get_node("Play") as Control
	failed += _check(play.visible, "play layer shows while the game is running")
	host.call("note_success", 3.0, 1.0)
	host.call("note_success", 3.0, 1.0)
	host.call("note_miss")
	var closer: BaseButton = window.get_node("Close") as BaseButton
	closer.pressed.emit()
	var summaries: Array[Node] = []
	_collect_named(host, "Summary", summaries)
	failed += _check(summaries.size() == 1, "one summary node, got %d" % summaries.size())
	var summary: Control = summaries[0] as Control if summaries.size() == 1 else null
	failed += _check(summary != null and summary.visible, "the host summary is showing")
	failed += _check(not play.visible, "play layer hides under the summary")
	var game_visible: bool = false
	for child: Node in play.get_children():
		if child is Minigame and (child as CanvasItem).visible:
			game_visible = true
	failed += _check(not game_visible, "the game itself is hidden under the summary")
	failed += _check(not _tree_text_has(host, "Feel test"), "feel-test placeholder is gone")
	failed += _check(window.get_node_or_null("Successes") != null, "the header shows Successes")
	var footer: Label = window.get_node_or_null("Hint") as Label
	failed += _check(footer != null and not footer.visible, "the window hint hides once Results is up")
	failed += _check(MinigameCatalog.flavour("splitting_stone") == "Every stone has a way it wants to break. Follow the cracks.", "the splitting stone flavour is the full sentence")
	if summary != null:
		var body: Label = summary.get_node_or_null("SummaryBody") as Label
		var flavour: String = MinigameCatalog.flavour("ripe_catch")
		failed += _check(body != null and body.get_parent() == summary and body.text == flavour and flavour != "", "the flavour line sits inside Results")
		failed += _check(body != null and body.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "the flavour line is centred")
		failed += _check(body != null and not body.clip_text and body.autowrap_mode != TextServer.AUTOWRAP_OFF, "the flavour wraps instead of being cut off")
		failed += _check(body != null and body.position.y >= 40.0 and body.position.y < 70.0, "the flavour sits under the Results title")
		var successes: Label = summary.get_node_or_null("RowSuccesses") as Label
		failed += _check(body != null and successes != null and body.position.y + body.size.y <= successes.position.y, "the flavour stays above the totals")
		failed += _check(body != null and body.position.x >= 48.0, "summary text starts inside the frame (x %.0f)" % (body.position.x if body else -1.0))
		failed += _check(body != null and body.position.x + body.size.x <= 412.0, "summary text ends inside the frame")
		var expect: Dictionary = {
			"RowSuccesses": "Successes  2",
			"RowMisses": "Misses  1",
			"RowStreak": "Best streak  2",
			"RowPace": "Pace  ×",
		}
		for row_name: String in expect.keys():
			var row: Label = summary.get_node_or_null(row_name) as Label
			var want: String = str(expect[row_name])
			failed += _check(row != null and row.text.begins_with(want), "%s reads '%s', got '%s'" % [row_name, want, row.text if row != null else ""])
			failed += _check(row != null and row.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "%s is centred" % row_name)
			failed += _check(row != null and int(row.get_theme_font_size(&"font_size")) == 19, "%s is 19px" % row_name)
			failed += _check(row != null and row.position.x >= 48.0 and row.position.x + row.size.x <= 412.0, "%s stays inside the frame" % row_name)
		var bonus: Label = summary.get_node_or_null("RowBonus") as Label
		failed += _check(bonus != null and bonus.text.begins_with("Bonus"), "the bonus line stays on the card")
		var done: Control = summary.get_node_or_null("Done") as Control
		var again: Control = summary.get_node_or_null("PlayAgain") as Control
		failed += _check(done != null and again != null, "summary has Done and Play again")
		if done != null and again != null:
			failed += _check(done.size.is_equal_approx(again.size), "Done and Play again are the same size (%s vs %s)" % [done.size, again.size])
			failed += _check(done.size.y >= 44.0 and done.size.x > 0.0, "summary buttons meet the tap size")
	host.call("close_immediate")
	GameState.ancient_frozen = frozen
	return failed


func _world_hover() -> int:
	var failed: int = 0
	var host: Node = Engine.get_main_loop().root.get_node_or_null("MinigameHost")
	failed += _check(host != null, "hover check has the minigame host")
	if host == null:
		return failed
	var frozen: bool = GameState.ancient_frozen
	var prev: Dictionary = ForgeJobs.keeper_task()
	GameState.ancient_frozen = false
	ForgeJobs.set_keeper_task("gather", "stone", true)
	var node: Node = (load("res://scenes/gatherable.tscn") as PackedScene).instantiate()
	node.set("resource_id", &"stone")
	node.set("node_key", "stone")
	Engine.get_main_loop().root.add_child(node)
	node.call("_on_hover", true)
	var name_label: Label = node.get_node("Label") as Label
	failed += _check(name_label != null and not name_label.visible, "Harvest Stone label stays off the Lend a hand button")
	var prompt: Control = host.get_node("MinigameRoot/LendPrompt") as Control
	failed += _check(prompt != null and prompt.visible, "Lend a hand shows for the worked stone")
	var opened: bool = bool(host.call("open_game", "splitting_stone", "keeper", "stone"))
	failed += _check(opened, "hover check can open Splitting Stone")
	failed += _check(WorldHover.current_text() == "", "world tooltip hides when a minigame opens")
	WorldHover.present(node, "Harvest Stone")
	failed += _check(WorldHover.current_text() == "", "world tooltip stays hidden while a minigame is open")
	host.call("close_immediate")
	node.queue_free()
	WorldHover.shutdown()
	if bool(prev.get("working", false)):
		ForgeJobs.set_keeper_task(str(prev.get("kind", "")), str(prev.get("target", "")), true)
	else:
		ForgeJobs.note_keeper_idle()
	GameState.ancient_frozen = frozen
	return failed


func _collect_named(node: Node, wanted: String, into: Array[Node]) -> void:
	if str(node.name) == wanted:
		into.append(node)
	for child: Node in node.get_children():
		_collect_named(child, wanted, into)


func _tree_text_has(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.find(needle) >= 0:
		return true
	if node is Button and (node as Button).text.find(needle) >= 0:
		return true
	for child: Node in node.get_children():
		if _tree_text_has(child, needle):
			return true
	return false


func _math() -> int:
	var failed: int = 0
	failed += _check(is_equal_approx(MinigameMath.k_from_r(40.0), 3.0), "ripe k = 3")
	failed += _check(is_equal_approx(MinigameMath.k_from_r(30.0), 4.0), "stone k = 4")
	failed += _check(is_equal_approx(MinigameMath.k_from_r(20.0), 6.0), "k_from_r(20) is 6")
	failed += _check(is_equal_approx(MinigameMath.k_from_r(15.0), 8.0), "k_from_r(15) is 8")
	failed += _check(is_equal_approx(MinigameCatalog.k_for("ripe_catch"), 3.0), "catalog ripe k")
	failed += _check(is_equal_approx(MinigameCatalog.k_for("splitting_stone"), 4.0), "catalog stone k")
	failed += _check(is_equal_approx(MinigameCatalog.k_for("just_enough"), 3.6), "catalog water k is the prototype 3.6")
	failed += _check(is_equal_approx(float(MinigameCatalog.game("just_enough").get("cycle_sec", 0.0)), 1.8), "water cycle is the prototype 1.8s")
	failed += _check(is_equal_approx(60.0 / 1.8 * 3.6, 120.0), "a perfect water minute is still +120s")
	failed += _check(is_equal_approx(MinigameCatalog.k_for("steady_press"), 15.0), "catalog press k is the prototype 15")
	failed += _check(is_equal_approx(float(MinigameCatalog.game("steady_press").get("cycle_sec", 0.0)), 7.5), "press cycle is the prototype 7.5s")
	failed += _check(is_equal_approx(60.0 / 7.5 * 15.0, 120.0), "a perfect press minute is still +120s")
	failed += _check(is_equal_approx(MinigameCatalog.k_for("hot_spots"), 5.0), "hot spots k = 5")
	failed += _check(is_equal_approx(MinigameCatalog.r_of("hot_spots"), 24.0), "hot spots r = 24")
	failed += _check(is_equal_approx(MinigameMath.k_from_r(24.0), 5.0), "hot spots k matches r")
	failed += _check(is_equal_approx(float(MinigameCatalog.game("hot_spots").get("life_sec", 0.0)), 2.5), "hot spots live for one spawn")
	var normal: float = MinigameCatalog.woodsong_k(false)
	var heavy: float = MinigameCatalog.woodsong_k(true)
	failed += _check(is_equal_approx(heavy, normal * 2.0), "heavy beat is double")
	var minute: float = 42.0 * normal + 6.0 * heavy
	failed += _check(is_equal_approx(minute, 120.0), "woodsong perfect minute is +120s (got %.4f)" % minute)
	failed += _check(is_equal_approx(MinigameCatalog.k_for("steeping"), 21.2), "steeping k is the prototype 21.2")
	failed += _check(is_equal_approx(MinigameCatalog.steeping_cycle(), 10.6), "steeping nominal cycle is 10.6s")
	failed += _check(is_equal_approx(60.0 / 10.6 * 21.2, 120.0), "a perfect steeping minute is still +120s")
	var phone_k: float = MinigameCatalog.k_for("with_the_grain", true)
	var desk_k: float = MinigameCatalog.k_for("with_the_grain", false)
	var phone_avg: float = MinigameCatalog.grain_average_round(true)
	failed += _check(is_equal_approx(phone_k, MinigameMath.grain_k(phone_avg)), "grain k follows the average round")
	failed += _check(MinigameCatalog.grain_shapes().size() == 20, "grain has the twenty prototype shapes")
	var straight: int = 0
	for entry_v: Variant in MinigameCatalog.grain_shapes():
		if typeof(entry_v) == TYPE_DICTIONARY and not bool((entry_v as Dictionary).get("curvy", false)):
			straight += 1
	failed += _check(straight == 1, "only the rod stays a 4s phone round")
	failed += _check(is_equal_approx(phone_k, 11.8), "phone grain k is 11.8 with nineteen curvy rounds (got %.3f)" % phone_k)
	failed += _check(is_equal_approx(desk_k, 8.0), "desktop grain rounds are 4s so k = 8")
	failed += _check(is_equal_approx(MinigameCatalog.grain_round_seconds(1, true), 6.0), "curvy phone round is 6s")
	failed += _check(is_equal_approx(MinigameCatalog.grain_round_seconds(0, true), 4.0), "straight phone round stays 4s")
	failed += _check(is_equal_approx(MinigameCatalog.grain_round_seconds(1, false), 4.0), "curvy desktop round stays 4s")
	var perfect: float = MinigameMath.pace_multiplier(120.0, 60.0)
	failed += _check(is_equal_approx(perfect, 3.0), "perfect minute is 3x")
	var over: float = MinigameMath.pace_multiplier(500.0, 10.0)
	failed += _check(is_equal_approx(over, 3.0), "pace ceiling holds at 3x")
	failed += _check(is_equal_approx(MinigameMath.pace_multiplier(0.0, 30.0), 1.0), "a miss leaves the pace at 1x")
	var partial: float = MinigameMath.pace_multiplier(40.0 * 3.0 * 0.8, 60.0)
	failed += _check(is_equal_approx(partial, 2.6), "80 percent of ripe catch is 2.6x")
	return failed


func _apply() -> int:
	var failed: int = 0
	var frozen: bool = GameState.ancient_frozen
	var committed: bool = GameState.fruit_committed
	var stage: StringName = GameState.stage_id
	var food: int = GameState.get_resource(&"food")
	var essence: int = GameState.get_resource(&"essence")
	var shards: int = GameState.get_resource(&"manashards")
	var wood: int = GameState.get_resource(&"wood")
	var basket: int = Backpack.get_count("wooden_basket")
	var can: int = Backpack.get_count("stone_watering_can")
	var ranks: Dictionary = GameState.upgrade_ranks
	var knack: int = int(ranks.get("minigame_knack", 0))
	var forager: int = int(ranks.get("forager", 0))
	var roots: int = int(ranks.get("deep_roots", 0))
	var sight: int = int(ranks.get("shard_sight", 0))
	GameState.ancient_frozen = false
	GameState.fruit_committed = false
	GameState.stage_id = &"sapling"
	GameState.harvest_accum = {}
	Backpack.set_count("wooden_basket", 0)
	Backpack.set_count("stone_watering_can", 0)
	ranks["minigame_knack"] = 5
	ranks["forager"] = 0
	ranks["deep_roots"] = 0
	ranks["shard_sight"] = 0
	GameState.set_resource(&"food", 0)
	var bare: Dictionary = MinigamePayout.grant("keeper", "ripe_catch", "food", 3.0)
	failed += _check(bool(bare.get("ok", false)), "keeper gather grant")
	failed += _check(is_equal_approx(float(bare.get("units", -1.0)), 1.5), "3s bare gather is 1.5 berries (got %.3f)" % float(bare.get("units", -1.0)))
	failed += _check(int(ranks.get("minigame_knack", 0)) == 5, "knack rank stayed high for the ignore check")
	GameState.harvest_accum = {}
	GameState.set_resource(&"food", 0)
	Backpack.set_count("wooden_basket", 1)
	var tooled: Dictionary = MinigamePayout.grant("keeper", "ripe_catch", "food", 3.0)
	failed += _check(is_equal_approx(float(tooled.get("units", -1.0)), 3.0), "basket doubles gather seconds (got %.3f)" % float(tooled.get("units", -1.0)))
	GameState.stage_id = &"young"
	GameState.harvest_accum = {}
	Backpack.set_count("wooden_basket", 0)
	var staged: Dictionary = MinigamePayout.grant("elaia", "ripe_catch", "food", 3.0)
	var expect: float = (3.0 / 2.0) * 1.15 * 0.8
	failed += _check(is_equal_approx(float(staged.get("units", -1.0)), expect), "stage and companion rate scale the seconds (got %.3f want %.3f)" % [float(staged.get("units", -1.0)), expect])
	var food_now: int = GameState.get_resource(&"food")
	var accum_now: float = float((GameState.harvest_accum as Dictionary).get("food", 0.0))
	var wisp: Dictionary = MinigamePayout.grant("wisp", "ripe_catch", "food", 30.0)
	failed += _check(not bool(wisp.get("ok", true)), "wisp gather is refused")
	failed += _check(GameState.get_resource(&"food") == food_now, "wisp grant does not add food")
	failed += _check(is_equal_approx(float((GameState.harvest_accum as Dictionary).get("food", 0.0)), accum_now), "wisp grant does not touch the accumulator")
	GameState.stage_id = &"sapling"
	GameState.set_resource(&"essence", 0)
	GameState.set_resource(&"manashards", 0)
	GameState.elaia_water_essence_frac = 0.0
	var poured: Dictionary = MinigamePayout.grant("keeper", "just_enough", "manatree", 6.0)
	failed += _check(bool(poured.get("ok", false)), "water grant")
	failed += _check(int(poured.get("essence", -1)) == 6, "6s of watering is 6 essence (got %d)" % int(poured.get("essence", -1)))
	failed += _check(int(poured.get("shards", -1)) >= 6 and int(poured.get("shards", -1)) <= 18, "shard roll stays in the normal range")
	var frac_before: float = GameState.elaia_water_essence_frac
	var ess_before: int = GameState.get_resource(&"essence")
	MinigamePayout.grant("keeper", "just_enough", "manatree", 0.4)
	failed += _check(GameState.get_resource(&"essence") == ess_before, "a short pour does not mint a whole essence")
	failed += _check(GameState.elaia_water_essence_frac > frac_before + 0.2, "the leftover watering fraction is banked")
	if ForgeJobs.has_job("mill"):
		ForgeJobs.cancel_batch("mill")
	GameState.set_resource(&"wood", 80)
	var started: String = ForgeJobs.try_begin_batch("mill", "heartwood_bits", 3)
	failed += _check(started == "ok", "mill batch for the job test (%s)" % started)
	var before: Dictionary = ForgeJobs.job_state("mill")
	var wisp_job: Dictionary = MinigamePayout.grant("wisp", "steady_press", "mill", 90.0)
	var after_wisp: Dictionary = ForgeJobs.job_state("mill")
	failed += _check(not bool(wisp_job.get("ok", true)), "wisp job time is refused")
	failed += _check(int(after_wisp.get("done", -1)) == int(before.get("done", -2)), "wisp does not finish the current job")
	failed += _check(is_equal_approx(float(after_wisp.get("progress", -1.0)), float(before.get("progress", -2.0))), "wisp does not move the current job")
	var elaia_job: Dictionary = MinigamePayout.grant("elaia", "steady_press", "mill", 10.0)
	var after_elaia: Dictionary = ForgeJobs.job_state("mill")
	failed += _check(bool(elaia_job.get("ok", false)), "companion job grant")
	failed += _check(is_equal_approx(float(elaia_job.get("applied", -1.0)), 8.0), "companion rate scales job seconds")
	failed += _check(int(after_elaia.get("done", -1)) == 0, "10s at 0.8 does not finish a 60s item")
	failed += _check(is_equal_approx(float(after_elaia.get("progress", -1.0)), 8.0), "current item moved 8s")
	var burst: Dictionary = MinigamePayout.grant("keeper", "steady_press", "mill", 90.0)
	var after_burst: Dictionary = ForgeJobs.job_state("mill")
	failed += _check(int(burst.get("finished", -1)) == 1, "overflow finishes the current item only")
	failed += _check(float(burst.get("spilled", 0.0)) > 1.0, "spare seconds do not enter the queue")
	failed += _check(int(after_burst.get("done", -1)) == 1, "one of three items finished")
	failed += _check(int(after_burst.get("total", -1)) == 3, "the queue is still three")
	failed += _check(is_equal_approx(float(after_burst.get("progress", -1.0)), 0.0), "the next item has not started")
	ForgeJobs.cancel_batch("mill")
	GameState.ancient_frozen = frozen
	GameState.fruit_committed = committed
	GameState.stage_id = stage
	GameState.set_resource(&"food", food)
	GameState.set_resource(&"essence", essence)
	GameState.set_resource(&"manashards", shards)
	GameState.set_resource(&"wood", wood)
	Backpack.set_count("wooden_basket", basket)
	Backpack.set_count("stone_watering_can", can)
	ranks["minigame_knack"] = knack
	ranks["forager"] = forager
	ranks["deep_roots"] = roots
	ranks["shard_sight"] = sight
	return failed


func _save_stays_put() -> int:
	var failed: int = 0
	var blob: Dictionary = GameState.to_save_dict()
	for key_v: Variant in blob.keys():
		failed += _check(not str(key_v).begins_with("minigame_"), "save has no minigame session field %s" % str(key_v))
	var jobs: Dictionary = ForgeJobs.capture_save_fields()
	failed += _check(not jobs.has("minigame"), "forge save has no minigame field")
	var migrated: Dictionary = SaveService.migrate_state(14, {"wood": 4, "stage_id": "sapling"})
	failed += _check(not migrated.is_empty(), "a v14 save still migrates")
	failed += _check(int(migrated.get("wood", -1)) == 4, "migration keeps the wood")
	failed += _check(migrated.has("first_minigame_played"), "existing flag still defaults in")
	failed += _check(not migrated.has("minigame_session"), "migration does not invent a session")
	failed += _check(int(SaveService.get("SAVE_VERSION")) == 15, "save version stays 15")
	return failed


func _check(ok: bool, label: String) -> int:
	if ok:
		return 0
	printerr("ASSERT FAIL: %s" % label)
	return 1
