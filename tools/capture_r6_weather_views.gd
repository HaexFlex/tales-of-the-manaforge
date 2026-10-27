extends SceneTree
## Headless weather ring captures for Art review.
## godot --headless --path . -s res://tools/capture_r6_weather_views.gd

const OUT_DIRS: Array[String] = ["/cursor/stores/self/caps"]
const WEATHER_STATES: Array[StringName] = [
	&"clear", &"soft_rain", &"mist", &"light_snow", &"blossom_fall",
]
const VIEW_NAMES: Array[String] = ["center", "ne", "nw", "se", "sw"]
const PARTICLE_PREPROCESS_SEC: float = 9.0
const CAPTURE_WARMUP_FRAMES: int = 30
const VIEW_FALL_REALTIME_WARMUP_SEC: float = 9.0
const VIEW_FALL_EMITTER_NAMES: Array[String] = ["SnowSmall", "SnowLarge", "Blossom"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dir: String in OUT_DIRS:
		DirAccess.make_dir_recursive_absolute(dir)
	var gs: Node = root.get_node_or_null("GameState")
	if gs != null:
		gs.set("welcome_shown", true)
		gs.set("welcome_presented", true)
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		print("CAPTURE_FAIL main scene")
		quit(1)
		return
	var hub: Node = packed.instantiate()
	root.add_child(hub)
	current_scene = hub
	if not hub.is_in_group("main_root"):
		hub.add_to_group("main_root")
	await process_frame
	var hud: Node = hub.get_node_or_null("%HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	var pause: CanvasItem = hub.get_node_or_null("%PauseMenu") as CanvasItem
	if pause:
		pause.visible = false
	var cam: Camera2D = hub.get_node_or_null("%Camera2D") as Camera2D
	if cam == null:
		print("CAPTURE_FAIL camera")
		quit(1)
		return
	cam.zoom = Vector2(1.0, 1.0)
	DisplayServer.window_set_size(Vector2i(960, 540))
	var hub_weather: Node = root.get_node_or_null("HubWeather")
	if hub_weather == null:
		print("CAPTURE_FAIL HubWeather")
		quit(1)
		return
	var cam_lines: PackedStringArray = PackedStringArray()
	var snow_debug_lines: PackedStringArray = PackedStringArray()
	var only_weather: String = OS.get_environment("MANAFORGE_CAPTURE_ONLY_WEATHER")
	var only_list: PackedStringArray = PackedStringArray()
	if only_weather != "":
		for part: String in only_weather.split(",", false):
			var trimmed: String = part.strip_edges()
			if trimmed != "":
				only_list.append(trimmed)
	for weather: StringName in WEATHER_STATES:
		if only_list.size() > 0 and not only_list.has(String(weather)):
			continue
		hub_weather.call("force_state_for_debug", weather)
		await process_frame
		await process_frame
		if _is_view_fall_weather(weather):
			await _warmup_view_fall_particles_once(hub, weather)
		for view_name: String in VIEW_NAMES:
			cam.position = _camera_pos_for(hub, view_name)
			if not _is_view_fall_weather(weather):
				_preprocess_weather_particles(hub, weather)
			var warmup: int = CAPTURE_WARMUP_FRAMES if _is_view_fall_weather(weather) else 10
			for _f: int in warmup:
				await process_frame
			if _is_view_fall_weather(weather):
				_force_view_fall_amount_ratio(hub, 1.0)
				for _f2: int in 3:
					await process_frame
			var cam_pos: Vector2 = cam.position
			print("CAM %s_%s %s" % [String(weather), view_name, cam_pos])
			cam_lines.append("%s_%s %s" % [String(weather), view_name, cam_pos])
			var fname: String = "%s_%s.png" % [String(weather), view_name]
			if _is_view_fall_weather(weather):
				_append_view_fall_debug(hub, hub_weather, fname, snow_debug_lines)
			for dir: String in OUT_DIRS:
				var path: String = "%s/%s" % [dir, fname]
				if not _save_viewport_png(hub, path):
					print("CAPTURE_FAIL %s" % path)
					quit(1)
					return
				if weather == &"light_snow":
					snow_debug_lines.append(
						"readback %s bright_px=%d diff_vs_clear_px=%d viewport=%s"
						% [fname, _count_bright_pixels(path), _diff_vs_clear_pixels(path), _capture_viewport_path(hub)]
					)
			print("CAPTURE_OK %s" % fname)
			if weather == &"light_snow" and view_name == "center":
				_write_snow_flake_crop_4x("%s/%s" % [OUT_DIRS[0], fname])
	_write_snow_debug(snow_debug_lines)
	if only_list.size() > 0:
		print("CAPTURE_ALL_OK")
		quit(0)
		return
	for dir: String in OUT_DIRS:
		var cams_path: String = "%s/cams.txt" % dir
		var cams_file := FileAccess.open(cams_path, FileAccess.WRITE)
		if cams_file == null:
			print("CAPTURE_FAIL %s" % cams_path)
			quit(1)
			return
		for line: String in cam_lines:
			cams_file.store_line(line)
		cams_file.close()
	print("CAPTURE_ALL_OK")
	quit(0)


func _is_view_fall_weather(weather: StringName) -> bool:
	return weather == &"light_snow" or weather == &"blossom_fall"


func _capture_viewport_path(hub: Node) -> String:
	var vp: Viewport = hub.get_viewport()
	if vp != null:
		return str(vp.get_path())
	return str(root.get_path())


func _save_viewport_png(hub: Node, path: String) -> bool:
	var vp: Viewport = hub.get_viewport()
	if vp == null:
		vp = root
	var tex: ViewportTexture = vp.get_texture()
	if tex == null:
		return false
	var image: Image = tex.get_image()
	if image == null:
		return false
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	return image.save_png(path) == OK


func _count_bright_pixels(path: String) -> int:
	var image: Image = Image.load_from_file(path)
	if image == null:
		return -1
	var n: int = 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			var c: Color = image.get_pixel(x, y)
			if c.r > 0.94 and c.g > 0.94 and c.b > 0.94:
				n += 1
	return n


func _diff_vs_clear_pixels(path: String) -> int:
	var a: Image = Image.load_from_file(path)
	var clear_name: String = path.replace("light_snow_", "clear_")
	var b: Image = Image.load_from_file(clear_name)
	if a == null or b == null:
		return -1
	var n: int = 0
	for y: int in a.get_height():
		for x: int in a.get_width():
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.06:
				n += 1
	return n


func _write_snow_debug(lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	lines.insert(0, "note=soft_rain_center diff_vs_clear_px reference ~472325 on same readback path (rain visible)")
	for dir: String in OUT_DIRS:
		var path: String = "%s/snow_debug.txt" % dir
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			print("CAPTURE_FAIL %s" % path)
			continue
		for line: String in lines:
			f.store_line(line)
		f.close()


func _append_view_fall_debug(hub: Node, hub_weather: Node, capture_label: String, lines: PackedStringArray) -> void:
	lines.append("--- %s ---" % capture_label)
	lines.append("hub_weather.current_state=%s" % str(hub_weather.call("current_state")))
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	if fx == null:
		lines.append("GladeWeatherFx=missing")
		return
	lines.append(
		"fx_snow_amount_ratio_at_grab=%s fx_blossom_amount_ratio_at_grab=%s"
		% [str(fx.get("_snow_amount_ratio")), str(fx.get("_blossom_amount_ratio"))]
	)
	_log_particles_under(fx, hub, lines)


func _log_particles_under(node: Node, hub: Node, lines: PackedStringArray) -> void:
	if node is CPUParticles2D:
		_log_one_particle(node as CPUParticles2D, hub, lines)
	for child: Node in node.get_children():
		_log_particles_under(child, hub, lines)


func _log_one_particle(motes: CPUParticles2D, hub: Node, lines: PackedStringArray) -> void:
	var n: String = str(motes.name)
	if n != "SnowSmall" and n != "SnowLarge" and n != "Blossom":
		return
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	var base_key: String = ""
	match n:
		"SnowSmall":
			base_key = "_snow_small_base_amount"
		"SnowLarge":
			base_key = "_snow_large_base_amount"
		"Blossom":
			base_key = "_blossom_base_amount"
	var configured_base: String = "n/a"
	if fx != null and base_key != "":
		configured_base = str(fx.get(base_key))
	var path: NodePath = hub.get_path_to(motes)
	var parent_mod: Color = Color.WHITE
	var p: Node = motes.get_parent()
	while p != null and p is CanvasItem:
		parent_mod *= (p as CanvasItem).modulate
		p = p.get_parent()
	var tex: Texture2D = motes.texture
	var tex_size: Vector2 = tex.get_size() if tex != null else Vector2.ZERO
	var tex_path: String = ""
	if tex != null:
		tex_path = tex.resource_path
	var live_count: String = "n/a"
	if motes.has_method("get_particle_count"):
		live_count = str(motes.call("get_particle_count"))
	var mat: Material = motes.material
	var anim_h: String = "n/a"
	var anim_v: String = "n/a"
	var particles_anim: String = "n/a"
	if mat is CanvasItemMaterial:
		var cim: CanvasItemMaterial = mat as CanvasItemMaterial
		particles_anim = str(cim.particles_animation)
		anim_h = str(cim.particles_anim_h_frames)
		anim_v = str(cim.particles_anim_v_frames)
	var scale_curve_pts: int = -1
	if motes.scale_amount_curve != null:
		scale_curve_pts = motes.scale_amount_curve.get_point_count()
	lines.append("path=%s" % path)
	lines.append("emitting=%s visible=%s is_visible_in_tree=%s" % [motes.emitting, motes.visible, motes.is_visible_in_tree()])
	lines.append(
		"amount_at_grab=%d configured_base=%s live_particle_count=%s"
		% [motes.amount, configured_base, live_count]
	)
	lines.append(
		"scale_amount_min=%s scale_amount_max=%s scale_amount_curve_points=%d"
		% [motes.scale_amount_min, motes.scale_amount_max, scale_curve_pts]
	)
	lines.append(
		"texture_filter=%d material_particles_animation=%s h_frames=%s v_frames=%s"
		% [motes.texture_filter, particles_anim, anim_h, anim_v]
	)
	lines.append("modulate=%s self_modulate=%s alpha=%.3f parent_modulate_chain=%s" % [
		motes.modulate, motes.self_modulate, motes.modulate.a * motes.self_modulate.a, parent_mod
	])
	lines.append("z_index=%d y_sort_enabled=%s" % [motes.z_index, motes.y_sort_enabled])
	lines.append("texture=%s size=%s" % [tex_path, tex_size])
	lines.append("emission_rect_extents=%s local_coords=%s preprocess=%s" % [
		motes.emission_rect_extents, motes.local_coords, motes.preprocess
	])


func _warmup_view_fall_particles_once(hub: Node, weather: StringName) -> void:
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	if fx == null:
		return
	var names: Array[String] = []
	if weather == &"light_snow":
		names = ["SnowSmall", "SnowLarge"]
	elif weather == &"blossom_fall":
		names = ["Blossom"]
	for child_name: String in names:
		var motes: CPUParticles2D = fx.get_node_or_null(child_name) as CPUParticles2D
		if motes == null:
			continue
		motes.preprocess = PARTICLE_PREPROCESS_SEC
		motes.restart()
	_force_view_fall_amount_ratio(hub, 1.0)
	for _f: int in CAPTURE_WARMUP_FRAMES:
		await process_frame
	await create_timer(VIEW_FALL_REALTIME_WARMUP_SEC).timeout
	for _f2: int in 10:
		await process_frame


func _force_view_fall_amount_ratio(hub: Node, ratio: float) -> void:
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	if fx == null:
		return
	fx.set("_snow_amount_ratio", ratio)
	fx.set("_blossom_amount_ratio", ratio)
	for child_name: String in VIEW_FALL_EMITTER_NAMES:
		var motes: CPUParticles2D = fx.get_node_or_null(child_name) as CPUParticles2D
		if motes == null or not motes.emitting:
			continue
		var base_amt: int = 1
		match child_name:
			"SnowSmall":
				base_amt = int(fx.get("_snow_small_base_amount"))
			"SnowLarge":
				base_amt = int(fx.get("_snow_large_base_amount"))
			"Blossom":
				base_amt = int(fx.get("_blossom_base_amount"))
		motes.amount = clampi(int(round(float(base_amt) * ratio)), 1, base_amt)


func _preprocess_weather_particles(hub: Node, weather: StringName) -> void:
	if _is_view_fall_weather(weather):
		return
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	if fx == null:
		return
	_preprocess_particles_under(fx)


func _preprocess_particles_under(node: Node) -> void:
	if node is CPUParticles2D:
		var motes: CPUParticles2D = node as CPUParticles2D
		if motes.emitting:
			motes.preprocess = PARTICLE_PREPROCESS_SEC
			motes.restart()
	for child: Node in node.get_children():
		_preprocess_particles_under(child)


func _write_snow_flake_crop_4x(center_png_path: String) -> void:
	var image: Image = Image.load_from_file(center_png_path)
	if image == null:
		print("CAPTURE_FAIL snow_flake_crop source %s" % center_png_path)
		return
	var best_score: int = -1
	var best_origin: Vector2i = Vector2i.ZERO
	const CROP: int = 24
	var y0: int = int(image.get_height() * 0.12)
	var y1: int = int(image.get_height() * 0.72)
	var x0: int = int(image.get_width() * 0.08)
	var x1: int = int(image.get_width() * 0.92)
	for y: int in range(y0, y1 - CROP, 2):
		for x: int in range(x0, x1 - CROP, 2):
			var score: int = 0
			for dy: int in CROP:
				for dx: int in CROP:
					var c: Color = image.get_pixel(x + dx, y + dy)
					if c.a < 0.5:
						continue
					if c.r > 0.85 and c.g > 0.85 and c.b > 0.85:
						score += 1
					if c.r > 0.32 and c.r < 0.42 and c.g > 0.4 and c.g < 0.48 and c.b > 0.5 and c.b < 0.6:
						score += 4
			if score > best_score:
				best_score = score
				best_origin = Vector2i(x, y)
	var region: Image = image.get_region(Rect2i(best_origin.x, best_origin.y, CROP, CROP))
	region.resize(CROP * 4, CROP * 4, Image.INTERPOLATE_NEAREST)
	for dir: String in OUT_DIRS:
		var out_path: String = "%s/snow_flake_crop_4x.png" % dir
		if region.save_png(out_path) != OK:
			print("CAPTURE_FAIL %s" % out_path)
		else:
			print("CAPTURE_OK %s score=%d origin=%s" % [out_path, best_score, best_origin])


func _camera_pos_for(hub: Node, view_name: String) -> Vector2:
	var center: Vector2 = hub.clearing_center if "clearing_center" in hub else Vector2(2160, 2025)
	if view_name == "center":
		return center
	var lo: Vector2 = hub.call("camera_min") if hub.has_method("camera_min") else Vector2(600, 400)
	var hi: Vector2 = hub.call("camera_max") if hub.has_method("camera_max") else Vector2(3600, 3200)
	match view_name:
		"nw":
			return Vector2(lo.x, lo.y)
		"ne":
			return Vector2(hi.x, lo.y)
		"sw":
			return Vector2(lo.x, hi.y)
		"se":
			return Vector2(hi.x, hi.y)
		_:
			return center
