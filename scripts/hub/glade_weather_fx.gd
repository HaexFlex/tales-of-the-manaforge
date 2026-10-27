extends Node2D
class_name GladeWeatherFx
## Forest-ring weather particles (R6). Emits only on the ring band per clearing_emit_map.

const EMIT_MAP: String = "res://assets/art/fx/weather/clearing_emit_map_160x90.png"
const RAIN_TEX: String = "res://assets/art/fx/weather/rain_streak_strip_2x6x4.png"
const MIST_TEX: String = "res://assets/art/fx/weather/mist_puff_strip_8x6x4.png"
const SNOW_TEX: String = "res://assets/art/fx/weather/snow_flake_strip_3x3x4.png"
const BLOSSOM_TEX: String = "res://assets/art/fx/weather/blossom_petal_strip_4x4x4.png"
const SPARKLE_TEX: String = "res://assets/art/fx/weather/puddle_sparkle_strip_12x8x4.png"
const WET_TEX: String = "res://assets/art/fx/weather/wet_ground_tint_64.png"

const EMIT_RGB: Vector3i = Vector3i(50, 40, 200)
const EMIT_COUNT_MIN: int = 600
const EMIT_COUNT_MAX: int = 680
const CENTER_NORM_MAX: float = 0.42

const RAIN_AMOUNT: int = 50
const MIST_AMOUNT: int = 12
const SNOW_AMOUNT: int = 20
const BLOSSOM_AMOUNT: int = 10

## Above hub TileMap (root sibling), below y-sorted canopy trunks in World.
const WEATHER_Z: int = 0
const PARTICLE_Z: int = 1

const WET_GROUND_ALPHA: float = 0.35
const WET_RGB: Vector3 = Vector3(0.72, 0.75, 0.82)

var _play_size: Vector2 = Vector2(4320, 3780)
var _clearing_center: Vector2 = Vector2(2160, 2025)
var _clearing_rx: float = 1620.0
var _clearing_ry: float = 1323.0
var _emit_points: PackedVector2Array = PackedVector2Array()
var _rain: CPUParticles2D
var _mist: CPUParticles2D
var _snow: CPUParticles2D
var _blossom: CPUParticles2D
var _sparkle: CPUParticles2D
var _wet_overlay: Sprite2D
var _state: StringName = &"clear"


func setup(play_size: Vector2, clearing_center: Vector2 = Vector2(2160, 2025), clearing_rx: float = 1620.0, clearing_ry: float = 1323.0) -> void:
	_play_size = play_size
	_clearing_center = clearing_center
	_clearing_rx = maxf(clearing_rx, 1.0)
	_clearing_ry = maxf(clearing_ry, 1.0)
	z_index = WEATHER_Z
	y_sort_enabled = true
	_build_emit_points()
	_ensure_nodes()
	var hub_weather: Node = get_node_or_null("/root/HubWeather")
	if hub_weather != null:
		if not hub_weather.state_changed.is_connected(_on_weather_state):
			hub_weather.state_changed.connect(_on_weather_state)
		_on_weather_state(hub_weather.call("current_state"))
	set_process(true)


static func emit_map_stats(
	play_size: Vector2,
	clearing_center: Vector2 = Vector2(2160, 2025),
	clearing_rx: float = 1620.0,
	clearing_ry: float = 1323.0
) -> Dictionary:
	var pts: PackedVector2Array = _build_emit_points_static(play_size, clearing_center, clearing_rx, clearing_ry)
	return {
		"count": pts.size(),
		"center_count": _count_center_emit_points(pts, clearing_center, clearing_rx, clearing_ry),
	}


static func _build_emit_points_static(
	play_size: Vector2,
	clearing_center: Vector2,
	clearing_rx: float,
	clearing_ry: float
) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var img: Image = _load_emit_image()
	if img == null:
		return out
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in h:
		for x: int in w:
			if not _pixel_is_emit_band(img.get_pixel(x, y)):
				continue
			var wx: float = (float(x) + 0.5) / float(w) * play_size.x
			var wy: float = (float(y) + 0.5) / float(h) * play_size.y
			out.append(Vector2(wx, wy))
	return out


static func _count_center_emit_points(
	pts: PackedVector2Array,
	clearing_center: Vector2,
	clearing_rx: float,
	clearing_ry: float
) -> int:
	var n: int = 0
	for p: Vector2 in pts:
		var nx: float = (p.x - clearing_center.x) / clearing_rx
		var ny: float = (p.y - clearing_center.y) / clearing_ry
		if nx * nx + ny * ny <= CENTER_NORM_MAX * CENTER_NORM_MAX:
			n += 1
	return n


static func _load_emit_image() -> Image:
	var tex: Texture2D = load(EMIT_MAP) as Texture2D
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return null
	img.decompress()
	return img


static func _pixel_is_emit_band(c: Color) -> bool:
	var r8: int = int(round(c.r * 255.0))
	var g8: int = int(round(c.g * 255.0))
	var b8: int = int(round(c.b * 255.0))
	return r8 == EMIT_RGB.x and g8 == EMIT_RGB.y and b8 == EMIT_RGB.z


func _strip_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_h_frames = 4
	mat.particles_anim_v_frames = 1
	mat.particles_anim_loop = true
	return mat


func _configure_strip(motes: CPUParticles2D, tex_path: String, amount: int, tint: Color) -> void:
	motes.texture = load(tex_path) as Texture2D
	motes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motes.material = _strip_material()
	motes.local_coords = false
	motes.amount = amount
	motes.lifetime = 4.5
	motes.explosiveness = 0.0
	motes.randomness = 0.35
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	motes.emission_points = _emit_points
	motes.direction = Vector2(0, 1)
	motes.spread = 12.0
	motes.gravity = Vector2(0, 28)
	motes.initial_velocity_min = 18.0
	motes.initial_velocity_max = 42.0
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 1.0
	motes.anim_speed_min = 0.8
	motes.anim_speed_max = 1.2
	motes.color = tint
	motes.emitting = false
	motes.z_index = PARTICLE_Z
	motes.y_sort_enabled = true


func _ensure_nodes() -> void:
	if _rain != null:
		return
	_wet_overlay = Sprite2D.new()
	_wet_overlay.name = "WetGround"
	_wet_overlay.texture = load(WET_TEX) as Texture2D
	_wet_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wet_overlay.centered = false
	_wet_overlay.position = Vector2.ZERO
	_wet_overlay.scale = Vector2(_play_size.x / 64.0, _play_size.y / 64.0)
	_wet_overlay.modulate = Color(WET_RGB.x, WET_RGB.y, WET_RGB.z, 0.0)
	_wet_overlay.z_index = -1
	_wet_overlay.y_sort_enabled = false
	add_child(_wet_overlay)
	_rain = CPUParticles2D.new()
	_rain.name = "Rain"
	_configure_strip(_rain, RAIN_TEX, RAIN_AMOUNT, Color(0.75, 0.82, 1.0, 1.0))
	_rain.gravity = Vector2(8, 120)
	_rain.direction = Vector2(0.15, 1)
	add_child(_rain)
	_mist = CPUParticles2D.new()
	_mist.name = "Mist"
	_configure_strip(_mist, MIST_TEX, MIST_AMOUNT, Color(0.9, 0.92, 0.95, 1.0))
	_mist.gravity = Vector2(0, -4)
	_mist.initial_velocity_min = 2.0
	_mist.initial_velocity_max = 8.0
	_mist.lifetime = 7.0
	add_child(_mist)
	_snow = CPUParticles2D.new()
	_snow.name = "Snow"
	_configure_strip(_snow, SNOW_TEX, SNOW_AMOUNT, Color(1.0, 1.0, 1.0, 1.0))
	_snow.gravity = Vector2(-6, 18)
	_snow.initial_velocity_min = 6.0
	_snow.initial_velocity_max = 16.0
	add_child(_snow)
	_blossom = CPUParticles2D.new()
	_blossom.name = "Blossom"
	_configure_strip(_blossom, BLOSSOM_TEX, BLOSSOM_AMOUNT, Color(1.0, 0.75, 0.82, 1.0))
	_blossom.gravity = Vector2(10, 22)
	add_child(_blossom)
	_sparkle = CPUParticles2D.new()
	_sparkle.name = "PuddleSparkle"
	_configure_strip(_sparkle, SPARKLE_TEX, 24, Color(0.85, 0.95, 1.0, 1.0))
	_sparkle.gravity = Vector2(0, 0)
	_sparkle.initial_velocity_min = 0.0
	_sparkle.initial_velocity_max = 2.0
	_sparkle.lifetime = 2.2
	_sparkle.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(_sparkle)


func _build_emit_points() -> void:
	_emit_points = _build_emit_points_static(_play_size, _clearing_center, _clearing_rx, _clearing_ry)
	if _emit_points.is_empty():
		_emit_points.append(Vector2(_play_size.x * 0.5, _play_size.y * 0.25))


func _on_weather_state(state_id: StringName) -> void:
	_state = state_id
	_apply_visuals()


func _apply_visuals() -> void:
	if _rain == null:
		return
	_rain.emitting = _state == &"soft_rain"
	_mist.emitting = _state == &"mist"
	_snow.emitting = _state == &"light_snow"
	_blossom.emitting = _state == &"blossom_fall"
	_sparkle.emitting = _state == &"soft_rain"
	var wet_a: float = WET_GROUND_ALPHA if _state == &"soft_rain" else 0.0
	_wet_overlay.modulate = Color(WET_RGB.x, WET_RGB.y, WET_RGB.z, wet_a)


func _process(_delta: float) -> void:
	if _wet_overlay == null:
		return
	if _state != &"soft_rain":
		return
	var pulse: float = 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.004)
	_wet_overlay.modulate = Color(WET_RGB.x, WET_RGB.y, WET_RGB.z, WET_GROUND_ALPHA * pulse)
