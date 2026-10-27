extends SceneTree
## Headless weather ring captures for Art review.
## godot --headless --path . -s res://tools/capture_r6_weather_views.gd

const OUT_DIR: String = "/opt/cursor/artifacts/weather_r6"
const WEATHER_STATES: Array[StringName] = [&"soft_rain", &"mist", &"light_snow"]
const VIEW_NAMES: Array[String] = [
	"clearing_center",
	"corner_nw",
	"corner_ne",
	"corner_sw",
	"corner_se",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
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
	var hud: CanvasItem = hub.get_node_or_null("%HUD") as CanvasItem
	if hud:
		hud.visible = false
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
	for weather: StringName in WEATHER_STATES:
		hub_weather.call("force_state_for_debug", weather)
		for view_name: String in VIEW_NAMES:
			cam.position = _camera_pos_for(hub, view_name)
			for _f: int in 8:
				await process_frame
			var fname: String = "%s_%s.png" % [String(weather), view_name]
			var path: String = "%s/%s" % [OUT_DIR, fname]
			if not _save_viewport_png(path):
				print("CAPTURE_FAIL %s" % path)
				quit(1)
				return
			print("CAPTURE_OK %s" % path)
	print("CAPTURE_ALL_OK")
	quit(0)


func _camera_pos_for(hub: Node, view_name: String) -> Vector2:
	if hub.has_method("get_play_size"):
		pass
	var center: Vector2 = hub.clearing_center if "clearing_center" in hub else Vector2(2160, 2025)
	if view_name == "clearing_center":
		return center
	var lo: Vector2 = hub.call("camera_min") if hub.has_method("camera_min") else Vector2(600, 400)
	var hi: Vector2 = hub.call("camera_max") if hub.has_method("camera_max") else Vector2(3600, 3200)
	match view_name:
		"corner_nw":
			return Vector2(lo.x, lo.y)
		"corner_ne":
			return Vector2(hi.x, lo.y)
		"corner_sw":
			return Vector2(lo.x, hi.y)
		"corner_se":
			return Vector2(hi.x, hi.y)
		_:
			return center


func _save_viewport_png(path: String) -> bool:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return false
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	return image.save_png(path) == OK
