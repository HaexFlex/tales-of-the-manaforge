extends Node2D
class_name GladeWeatherFx
## Forest-ring weather particles (R6). Rain/mist use clearing_emit_map ring; snow/blossom use view-following boxes.

const EMIT_MAP: String = "res://assets/art/fx/weather/clearing_emit_map_160x90.png"
const RAIN_TEX: String = "res://assets/art/fx/weather/rain_streak_strip_2x6x4.png"
const MIST_TEX: String = "res://assets/art/fx/weather/mist_puff_strip_8x6x4.png"
const SNOW_SMALL_TEX: String = "res://assets/art/fx/weather/snow_flake_small_strip_4x4x4.png"
const SNOW_LARGE_TEX: String = "res://assets/art/fx/weather/snow_flake_large_strip_6x6x4.png"
const BLOSSOM_TEX: String = "res://assets/art/fx/weather/blossom_petal_strip_4x4x4.png"
const SPARKLE_TEX: String = "res://assets/art/fx/weather/puddle_sparkle_strip_12x8x4.png"
const WET_TEX: String = "res://assets/art/fx/weather/wet_ground_tint_64.png"

const EMIT_RGB: Vector3i = Vector3i(50, 40, 200)
const EMIT_COUNT_MIN: int = 600
const EMIT_COUNT_MAX: int = 680
const CENTER_NORM_MAX: float = 0.42

const RAIN_AMOUNT: int = 50
const MIST_AMOUNT: int = 12
const BLOSSOM_AMOUNT: int = 10

## PLACEHOLDER — Design light_snow visibility fix (2026-10-27); see SNOW_FIX_VALUES.md
const SNOW_VIEW_BOX_WIDTH_PX: float = 1408.0
const SNOW_VIEW_BOX_HEIGHT_PX: float = 16.0
const SNOW_VIEW_BOX_ABOVE_VIEW_PX: float = 48.0
const SNOW_AMOUNT_TOTAL: int = 80
const SNOW_AMOUNT_TOTAL_MOBILE: int = 48
const SNOW_AMOUNT_SMALL: int = 48
const SNOW_AMOUNT_LARGE: int = 32
const SNOW_AMOUNT_SMALL_MOBILE: int = 29
const SNOW_AMOUNT_LARGE_MOBILE: int = 19
const SNOW_LIFETIME_SEC: float = 9.0
const SNOW_LIFETIME_RANDOMNESS: float = 0.2
const SNOW_FALL_SPEED_MIN_PX_S: float = 70.0
const SNOW_FALL_SPEED_MAX_PX_S: float = 100.0
const SNOW_SWAY_PX: float = 10.0
const SNOW_SWAY_PERIOD_MIN_SEC: float = 3.0
const SNOW_SWAY_PERIOD_MAX_SEC: float = 5.0
const SNOW_SPREAD_DEG: float = 15.0
const SNOW_PREPROCESS_SEC: float = 9.0
const SNOW_FADE_IN_LIFE_FRAC: float = 0.10
const SNOW_FADE_OUT_LIFE_FRAC: float = 0.15
const SNOW_TRANSITION_RAMP_SEC: float = 6.0

const BLOSSOM_VIEW_AMOUNT: int = 40
const BLOSSOM_LIFETIME_SEC: float = 11.0
const BLOSSOM_FALL_SPEED_MIN_PX_S: float = 45.0
const BLOSSOM_FALL_SPEED_MAX_PX_S: float = 70.0
const BLOSSOM_SWAY_PX: float = 18.0
const BLOSSOM_SPREAD_DEG: float = 15.0
const BLOSSOM_PREPROCESS_SEC: float = 9.0
const BLOSSOM_FADE_IN_LIFE_FRAC: float = 0.10
const BLOSSOM_FADE_OUT_LIFE_FRAC: float = 0.15
const BLOSSOM_TRANSITION_RAMP_SEC: float = 6.0

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
var _snow_small: CPUParticles2D
var _snow_large: CPUParticles2D
var _blossom: CPUParticles2D
var _sparkle: CPUParticles2D
var _wet_overlay: Sprite2D
var _state: StringName = &"clear"
var _snow_amount_ratio: float = 0.0
var _blossom_amount_ratio: float = 0.0
var _sway_phase: float = 0.0


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


func _life_fade_ramp(fade_in_frac: float, fade_out_frac: float) -> Gradient:
	var grad := Gradient.new()
	grad.set_color(0.0, Color(1.0, 1.0, 1.0, 0.0))
	grad.set_color(fade_in_frac, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1.0 - fade_out_frac, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1.0, Color(1.0, 1.0, 1.0, 0.0))
	return grad


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


func _configure_view_fall_emitter(
	motes: CPUParticles2D,
	tex_path: String,
	amount: int,
	lifetime_sec: float,
	lifetime_randomness: float,
	fall_min_px_s: float,
	fall_max_px_s: float,
	sway_px: float,
	spread_deg: float,
	preprocess_sec: float,
	fade_in_frac: float,
	fade_out_frac: float,
	tint: Color
) -> void:
	motes.texture = load(tex_path) as Texture2D
	motes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motes.material = _strip_material()
	motes.local_coords = false
	motes.amount = amount
	motes.lifetime = lifetime_sec
	motes.preprocess = preprocess_sec
	motes.explosiveness = 0.0
	motes.randomness = lifetime_randomness
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(SNOW_VIEW_BOX_WIDTH_PX * 0.5, SNOW_VIEW_BOX_HEIGHT_PX * 0.5)
	motes.direction = Vector2(0, 1)
	motes.spread = spread_deg
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = fall_min_px_s
	motes.initial_velocity_max = fall_max_px_s
	motes.orbit_velocity_min = -sway_px
	motes.orbit_velocity_max = sway_px
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 1.0
	motes.anim_speed_min = 0.8
	motes.anim_speed_max = 1.2
	motes.color = tint
	motes.color_ramp = _life_fade_ramp(fade_in_frac, fade_out_frac)
	motes.emitting = false
	motes.z_index = PARTICLE_Z
	motes.y_sort_enabled = false


func _snow_split_amounts() -> Vector2i:
	if OS.has_feature("mobile"):
		return Vector2i(SNOW_AMOUNT_SMALL_MOBILE, SNOW_AMOUNT_LARGE_MOBILE)
	return Vector2i(SNOW_AMOUNT_SMALL, SNOW_AMOUNT_LARGE)


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
	var snow_amt: Vector2i = _snow_split_amounts()
	_snow_small = CPUParticles2D.new()
	_snow_small.name = "SnowSmall"
	_configure_view_fall_emitter(
		_snow_small,
		SNOW_SMALL_TEX,
		snow_amt.x,
		SNOW_LIFETIME_SEC,
		SNOW_LIFETIME_RANDOMNESS,
		SNOW_FALL_SPEED_MIN_PX_S,
		SNOW_FALL_SPEED_MAX_PX_S,
		SNOW_SWAY_PX,
		SNOW_SPREAD_DEG,
		SNOW_PREPROCESS_SEC,
		SNOW_FADE_IN_LIFE_FRAC,
		SNOW_FADE_OUT_LIFE_FRAC,
		Color(1.0, 1.0, 1.0, 1.0)
	)
	add_child(_snow_small)
	_snow_large = CPUParticles2D.new()
	_snow_large.name = "SnowLarge"
	_configure_view_fall_emitter(
		_snow_large,
		SNOW_LARGE_TEX,
		snow_amt.y,
		SNOW_LIFETIME_SEC,
		SNOW_LIFETIME_RANDOMNESS,
		SNOW_FALL_SPEED_MIN_PX_S,
		SNOW_FALL_SPEED_MAX_PX_S,
		SNOW_SWAY_PX,
		SNOW_SPREAD_DEG,
		SNOW_PREPROCESS_SEC,
		SNOW_FADE_IN_LIFE_FRAC,
		SNOW_FADE_OUT_LIFE_FRAC,
		Color(1.0, 1.0, 1.0, 1.0)
	)
	add_child(_snow_large)
	_blossom = CPUParticles2D.new()
	_blossom.name = "Blossom"
	_configure_view_fall_emitter(
		_blossom,
		BLOSSOM_TEX,
		BLOSSOM_VIEW_AMOUNT,
		BLOSSOM_LIFETIME_SEC,
		SNOW_LIFETIME_RANDOMNESS,
		BLOSSOM_FALL_SPEED_MIN_PX_S,
		BLOSSOM_FALL_SPEED_MAX_PX_S,
		BLOSSOM_SWAY_PX,
		BLOSSOM_SPREAD_DEG,
		BLOSSOM_PREPROCESS_SEC,
		BLOSSOM_FADE_IN_LIFE_FRAC,
		BLOSSOM_FADE_OUT_LIFE_FRAC,
		Color(1.0, 0.75, 0.82, 1.0)
	)
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
	var snow_on: bool = _state == &"light_snow"
	_snow_small.emitting = snow_on
	_snow_large.emitting = snow_on
	var blossom_on: bool = _state == &"blossom_fall"
	_blossom.emitting = blossom_on
	_sparkle.emitting = _state == &"soft_rain"
	var wet_a: float = WET_GROUND_ALPHA if _state == &"soft_rain" else 0.0
	_wet_overlay.modulate = Color(WET_RGB.x, WET_RGB.y, WET_RGB.z, wet_a)
	if snow_on:
		_snow_small.restart()
		_snow_large.restart()
	if blossom_on:
		_blossom.restart()


func _get_camera() -> Camera2D:
	var scene: Node = get_tree().get_current_scene()
	if scene == null:
		return null
	return scene.get_node_or_null("%Camera2D") as Camera2D


func _view_emitter_world_center(cam: Camera2D) -> Vector2:
	var vp_size: Vector2 = cam.get_viewport().get_visible_rect().size
	var half_h: float = vp_size.y * 0.5 / cam.zoom.y
	var y_top: float = cam.global_position.y - half_h - SNOW_VIEW_BOX_ABOVE_VIEW_PX
	var y_center: float = y_top + SNOW_VIEW_BOX_HEIGHT_PX * 0.5
	return Vector2(cam.global_position.x, y_center)


func _sync_view_emitter_node(motes: CPUParticles2D, world_center: Vector2, amount_ratio: float) -> void:
	motes.global_position = world_center
	if "amount_ratio" in motes:
		motes.set("amount_ratio", amount_ratio)


func _ramp_ratio(current: float, target: float, delta: float, ramp_sec: float) -> float:
	if ramp_sec <= 0.0:
		return target
	var step: float = delta / ramp_sec
	if current < target:
		return minf(current + step, target)
	if current > target:
		return maxf(current - step, target)
	return current


func _process(delta: float) -> void:
	if _wet_overlay != null and _state == &"soft_rain":
		var pulse: float = 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.004)
		_wet_overlay.modulate = Color(WET_RGB.x, WET_RGB.y, WET_RGB.z, WET_GROUND_ALPHA * pulse)
	var cam: Camera2D = _get_camera()
	if cam == null or _snow_small == null:
		return
	var snow_target: float = 1.0 if _state == &"light_snow" else 0.0
	var blossom_target: float = 1.0 if _state == &"blossom_fall" else 0.0
	_snow_amount_ratio = _ramp_ratio(_snow_amount_ratio, snow_target, delta, SNOW_TRANSITION_RAMP_SEC)
	_blossom_amount_ratio = _ramp_ratio(_blossom_amount_ratio, blossom_target, delta, BLOSSOM_TRANSITION_RAMP_SEC)
	_sway_phase += delta
	var sway_period: float = (SNOW_SWAY_PERIOD_MIN_SEC + SNOW_SWAY_PERIOD_MAX_SEC) * 0.5
	var sway_x: float = sin(TAU * _sway_phase / sway_period) * SNOW_SWAY_PX * 0.1
	var center: Vector2 = _view_emitter_world_center(cam)
	center.x += sway_x
	_sync_view_emitter_node(_snow_small, center, _snow_amount_ratio)
	_sync_view_emitter_node(_snow_large, center, _snow_amount_ratio)
	_sync_view_emitter_node(_blossom, center, _blossom_amount_ratio)
