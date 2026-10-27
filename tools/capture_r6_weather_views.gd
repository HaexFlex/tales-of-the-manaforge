extends SceneTree
## Headless weather ring captures for Art review.
## godot --headless --path . -s res://tools/capture_r6_weather_views.gd

const OUT_DIRS: Array[String] = ["/cursor/stores/self/caps"]
const WEATHER_STATES: Array[StringName] = [
	&"clear", &"soft_rain", &"mist", &"light_snow", &"blossom_fall",
]
const VIEW_NAMES: Array[String] = ["center", "ne", "nw", "se", "sw"]


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
	for weather: StringName in WEATHER_STATES:
		hub_weather.call("force_state_for_debug", weather)
		for view_name: String in VIEW_NAMES:
			cam.position = _camera_pos_for(hub, view_name)
			for _f: int in 10:
				await process_frame
			var cam_pos: Vector2 = cam.position
			print("CAM %s_%s %s" % [String(weather), view_name, cam_pos])
			cam_lines.append("%s_%s %s" % [String(weather), view_name, cam_pos])
			var fname: String = "%s_%s.png" % [String(weather), view_name]
			for dir: String in OUT_DIRS:
				var path: String = "%s/%s" % [dir, fname]
				if not _save_viewport_png(path):
					print("CAPTURE_FAIL %s" % path)
					quit(1)
					return
			print("CAPTURE_OK %s" % fname)
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


func _save_viewport_png(path: String) -> bool:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return false
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	return image.save_png(path) == OK
