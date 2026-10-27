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
		for view_name: String in VIEW_NAMES:
			cam.position = _camera_pos_for(hub, view_name)
			for _pf: int in 3:
				await process_frame
			if weather == &"light_snow" and view_name == "center":
				await _ensure_clear_center_reference(hub, hub_weather, cam)
			if _is_view_fall_weather(weather):
				await _prepare_view_fall_capture(hub, weather)
			elif weather != &"clear":
				_preprocess_weather_particles(hub, weather)
			var warmup: int = CAPTURE_WARMUP_FRAMES if _is_view_fall_weather(weather) else 10
			for _f: int in warmup:
				await process_frame
			var cam_pos: Vector2 = cam.position
			print("CAM %s_%s %s" % [String(weather), view_name, cam_pos])
			cam_lines.append("%s_%s %s" % [String(weather), view_name, cam_pos])
			var fname: String = "%s_%s.png" % [String(weather), view_name]
			if _is_view_fall_weather(weather):
				_append_view_fall_debug(hub, hub_weather, cam, fname, snow_debug_lines)
			for dir: String in OUT_DIRS:
				var path: String = "%s/%s" % [dir, fname]
				if not _save_viewport_png(hub, path):
					print("CAPTURE_FAIL %s" % path)
					quit(1)
					return
				if weather == &"light_snow":
					var clear_path: String = "%s/clear_center.png" % dir
					var flake_px: int = _count_flake_diff_pixels(path, clear_path)
					snow_debug_lines.append(
						"readback %s bright_px=%d diff_vs_clear_px=%d flake_diff_px=%d viewport=%s"
						% [fname, _count_bright_pixels(path), _diff_vs_clear_pixels(path), flake_px, _capture_viewport_path(hub)]
					)
			print("CAPTURE_OK %s" % fname)
			if weather == &"light_snow" and view_name == "center":
				_write_snow_flake_crop_4x_from_diff(
					"%s/light_snow_center.png" % OUT_DIRS[0],
					"%s/clear_center.png" % OUT_DIRS[0]
				)
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


func _is_flake_diff_pixel(snow_c: Color, clear_c: Color) -> bool:
	var d: float = absf(snow_c.r - clear_c.r) + absf(snow_c.g - clear_c.g) + absf(snow_c.b - clear_c.b)
	if d < 0.05:
		return false
	var snow_luma: float = snow_c.r + snow_c.g + snow_c.b
	var clear_luma: float = clear_c.r + clear_c.g + clear_c.b
	if snow_luma < clear_luma + 0.12:
		return false
	if snow_c.r > 0.90 and snow_c.g > 0.90 and snow_c.b > 0.90:
		return true
	if (
		snow_c.r > 0.30 and snow_c.r < 0.45
		and snow_c.g > 0.38 and snow_c.g < 0.52
		and snow_c.b > 0.48 and snow_c.b < 0.62
	):
		return true
	return false


func _count_flake_diff_pixels(snow_path: String, clear_path: String) -> int:
	var snow: Image = Image.load_from_file(snow_path)
	var clear: Image = Image.load_from_file(clear_path)
	if snow == null or clear == null:
		return -1
	var n: int = 0
	var y0: int = int(snow.get_height() * 0.08)
	var y1: int = int(snow.get_height() * 0.78)
	var x0: int = int(snow.get_width() * 0.06)
	var x1: int = int(snow.get_width() * 0.94)
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			if _is_flake_diff_pixel(snow.get_pixel(x, y), clear.get_pixel(x, y)):
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


func _append_view_fall_debug(hub: Node, hub_weather: Node, cam: Camera2D, capture_label: String, lines: PackedStringArray) -> void:
	lines.append("--- %s ---" % capture_label)
	lines.append("hub_weather.current_state=%s" % str(hub_weather.call("current_state")))
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	if fx == null:
		lines.append("GladeWeatherFx=missing")
		return
	if fx.has_method("sync_view_emitters_for_camera"):
		fx.call("sync_view_emitters_for_camera", cam)
	if fx.has_method("count_particles_in_view"):
		lines.append("particles_in_view_at_grab=%d" % int(fx.call("count_particles_in_view", cam)))
	lines.append(
		"fx_snow_amount_ratio_at_grab=%s fx_blossom_amount_ratio_at_grab=%s"
		% [str(fx.get("_snow_amount_ratio")), str(fx.get("_blossom_amount_ratio"))]
	)
	_log_particles_under(fx, hub, cam, lines)


func _log_particles_under(node: Node, hub: Node, cam: Camera2D, lines: PackedStringArray) -> void:
	if node is CPUParticles2D:
		_log_one_particle(node as CPUParticles2D, hub, cam, lines)
	for child: Node in node.get_children():
		_log_particles_under(child, hub, cam, lines)


func _log_one_particle(motes: CPUParticles2D, hub: Node, cam: Camera2D, lines: PackedStringArray) -> void:
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
	lines.append("global_position=%s" % motes.global_position)
	lines.append("emitting=%s visible=%s is_visible_in_tree=%s" % [motes.emitting, motes.visible, motes.is_visible_in_tree()])
	lines.append("amount_at_grab=%d configured_base=%s" % [motes.amount, configured_base])
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
	if cam != null:
		lines.append("camera_global_position=%s" % cam.global_position)


func _prepare_view_fall_capture(hub: Node, weather: StringName) -> void:
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	var cam: Camera2D = hub.get_node_or_null("%Camera2D") as Camera2D
	if fx == null or cam == null:
		return
	_force_view_fall_amount_ratio(hub, weather, 1.0)
	if fx.has_method("sync_view_emitters_for_camera"):
		fx.call("sync_view_emitters_for_camera", cam)
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
	for _f: int in CAPTURE_WARMUP_FRAMES:
		await process_frame
	await create_timer(VIEW_FALL_REALTIME_WARMUP_SEC).timeout
	_force_view_fall_amount_ratio(hub, weather, 1.0)
	if fx.has_method("sync_view_emitters_for_camera"):
		fx.call("sync_view_emitters_for_camera", cam)
	for _f2: int in 10:
		await process_frame


func _force_view_fall_amount_ratio(hub: Node, weather: StringName, ratio: float) -> void:
	var fx: Node = hub.get_node_or_null("World/GladeWeatherFx")
	if fx == null:
		return
	if weather == &"light_snow":
		fx.set("_snow_amount_ratio", ratio)
	elif weather == &"blossom_fall":
		fx.set("_blossom_amount_ratio", ratio)
	var cam: Camera2D = hub.get_node_or_null("%Camera2D") as Camera2D
	if fx.has_method("sync_view_emitters_for_camera") and cam != null:
		fx.call("sync_view_emitters_for_camera", cam)


func _ensure_clear_center_reference(hub: Node, hub_weather: Node, cam: Camera2D) -> void:
	var clear_path: String = "%s/clear_center.png" % OUT_DIRS[0]
	var saved_weather: StringName = hub_weather.call("current_state")
	hub_weather.call("force_state_for_debug", &"clear")
	await process_frame
	await process_frame
	cam.position = _camera_pos_for(hub, "center")
	for _f: int in 15:
		await process_frame
	if not _save_viewport_png(hub, clear_path):
		print("CAPTURE_FAIL %s" % clear_path)
		quit(1)
		return
	print("CAPTURE_OK clear_center.png (reference)")
	hub_weather.call("force_state_for_debug", saved_weather)
	await process_frame
	await process_frame


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


func _write_snow_flake_crop_4x_from_diff(snow_path: String, clear_path: String) -> void:
	var snow: Image = Image.load_from_file(snow_path)
	var clear: Image = Image.load_from_file(clear_path)
	if snow == null or clear == null:
		print("CAPTURE_FAIL snow_flake_crop missing snow or clear")
		return
	const CROP: int = 32
	var y0: int = int(snow.get_height() * 0.08)
	var y1: int = int(snow.get_height() * 0.78)
	var x0: int = int(snow.get_width() * 0.06)
	var x1: int = int(snow.get_width() * 0.94)
	var flake_pts: PackedVector2Array = PackedVector2Array()
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			if _is_flake_diff_pixel(snow.get_pixel(x, y), clear.get_pixel(x, y)):
				flake_pts.append(Vector2(x, y))
	if flake_pts.is_empty():
		print("CAPTURE_FAIL snow_flake_crop_4x no flake diff pixels in scene grab")
		for dir: String in OUT_DIRS:
			var note_path: String = "%s/snow_flake_crop_4x.txt" % dir
			var nf := FileAccess.open(note_path, FileAccess.WRITE)
			if nf != null:
				nf.store_line("no_flake_diff_pixels_in_light_snow_center")
				nf.close()
		return
	var cluster_center: Vector2 = _best_flake_cluster_center(flake_pts, 10.0)
	if cluster_center.x < 0.0:
		print("CAPTURE_FAIL snow_flake_crop_4x no compact flake clusters in scene grab")
		return
	var origin: Vector2i = Vector2i(
		clampi(int(round(cluster_center.x)) - CROP / 2, x0, x1 - CROP),
		clampi(int(round(cluster_center.y)) - CROP / 2, y0, y1 - CROP)
	)
	var region: Image = snow.get_region(Rect2i(origin.x, origin.y, CROP, CROP))
	region.resize(CROP * 4, CROP * 4, Image.INTERPOLATE_NEAREST)
	for dir: String in OUT_DIRS:
		var out_path: String = "%s/snow_flake_crop_4x.png" % dir
		if region.save_png(out_path) != OK:
			print("CAPTURE_FAIL %s" % out_path)
		else:
			print(
				"CAPTURE_OK %s flake_diff_px=%d origin=%s cluster_center=%s"
				% [out_path, flake_pts.size(), origin, cluster_center]
			)


func _best_flake_cluster_center(pts: PackedVector2Array, radius: float) -> Vector2:
	var best_count: int = 0
	var best_center: Vector2 = Vector2(-1.0, -1.0)
	var r2: float = radius * radius
	for p: Vector2 in pts:
		var count: int = 0
		for q: Vector2 in pts:
			if p.distance_squared_to(q) <= r2:
				count += 1
		if count > best_count:
			best_count = count
			best_center = p
	if best_count < 3:
		return Vector2(-1.0, -1.0)
	return best_center


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
