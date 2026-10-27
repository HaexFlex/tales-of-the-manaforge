extends Node2D
class_name GladeFireflies
## Soft glade motes at dusk/night. Non-interactive; stays in world space below the HUD.


var _motes: CPUParticles2D
var _glade: Rect2 = Rect2()
var _strength: float = 0.0
var _glow_tex: Texture2D


func _glow_texture() -> Texture2D:
	if _glow_tex != null:
		return _glow_tex
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	img.set_pixel(0, 0, Color(1.0, 0.78, 0.38, 0.95))
	img.set_pixel(1, 0, Color(1.0, 0.86, 0.48, 0.75))
	img.set_pixel(0, 1, Color(1.0, 0.82, 0.42, 0.8))
	img.set_pixel(1, 1, Color(1.0, 0.9, 0.55, 0.65))
	_glow_tex = ImageTexture.create_from_image(img)
	return _glow_tex


func setup(glade_rect: Rect2) -> void:
	_glade = glade_rect
	position = _glade.get_center()
	_ensure_motes()
	_apply_glade_bounds()
	set_process(true)
	_refresh_strength(true)


func _ensure_motes() -> void:
	if _motes != null:
		return
	_motes = CPUParticles2D.new()
	_motes.name = "Motes"
	_motes.texture = _glow_texture()
	_motes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_motes.local_coords = true
	_motes.emitting = false
	_motes.amount = 16
	_motes.lifetime = 6.5
	_motes.explosiveness = 0.0
	_motes.randomness = 0.45
	_motes.direction = Vector2(0, -1)
	_motes.spread = 165.0
	_motes.gravity = Vector2(0, -2)
	_motes.initial_velocity_min = 3.0
	_motes.initial_velocity_max = 11.0
	_motes.angular_velocity_min = -18.0
	_motes.angular_velocity_max = 18.0
	_motes.orbit_velocity_min = 0.02
	_motes.orbit_velocity_max = 0.08
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.scale_amount_min = 1.0
	_motes.scale_amount_max = 2.2
	_motes.color = Color(1.0, 0.84, 0.45, 0.75)
	_motes.hue_variation_min = -0.04
	_motes.hue_variation_max = 0.06
	_motes.z_index = 0
	add_child(_motes)


func _apply_glade_bounds() -> void:
	if _motes == null:
		return
	var inset: Vector2 = _glade.size * 0.08
	var inner: Vector2 = _glade.size - inset * 2.0
	_motes.emission_rect_extents = inner * 0.5


func _process(_delta: float) -> void:
	_refresh_strength(false)


func _refresh_strength(force: bool) -> void:
	var target: float = HubTimePhase.firefly_strength(HubTimePhase.sample_phase01())
	if not force and is_equal_approx(target, _strength):
		return
	_strength = target
	if _motes == null:
		return
	_motes.modulate.a = _strength
	_motes.emitting = _strength > 0.04
	var live_amount: int = int(round(lerpf(0.0, 16.0, _strength)))
	_motes.amount = maxi(live_amount, 1 if _strength > 0.04 else 0)
