extends Node2D
class_name GladeFireflies
## Soft glade motes at dusk/night. Non-interactive; stays in world space below the HUD.

const WARM_STRIP: String = "res://assets/art/fx/fireflies/firefly_warm_strip_8x8x4.png"
const CYAN_STRIP: String = "res://assets/art/fx/fireflies/firefly_cyan_strip_8x8x4.png"

const WARM_AMOUNT_MAX: int = 13
const CYAN_AMOUNT_MAX: int = 3
const TWINKLE_COOLDOWN_MSEC: int = 4000
const TWINKLE_CUE_IDS: PackedStringArray = [
	"sfx_firefly_twinkle_1",
	"sfx_firefly_twinkle_2",
	"sfx_firefly_twinkle_3",
]

static var _last_twinkle_msec: int = -100000000

var _motes_warm: CPUParticles2D
var _motes_cyan: CPUParticles2D
var _glade: Rect2 = Rect2()
var _strength: float = 0.0
var _twinkle_attempt_sec: float = 0.0


func setup(glade_rect: Rect2) -> void:
	_glade = glade_rect
	position = _glade.get_center()
	_ensure_motes()
	_apply_glade_bounds()
	set_process(true)
	_refresh_strength(true)


func _strip_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_h_frames = 4
	mat.particles_anim_v_frames = 1
	mat.particles_anim_loop = true
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _configure_motes(motes: CPUParticles2D, tex_path: String, tint: Color) -> void:
	motes.texture = load(tex_path) as Texture2D
	motes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motes.material = _strip_material()
	motes.local_coords = true
	motes.emitting = false
	motes.lifetime = 6.5
	motes.explosiveness = 0.0
	motes.randomness = 0.45
	motes.direction = Vector2(0, -1)
	motes.spread = 165.0
	motes.gravity = Vector2(0, -2)
	motes.initial_velocity_min = 3.0
	motes.initial_velocity_max = 11.0
	motes.angular_velocity_min = -18.0
	motes.angular_velocity_max = 18.0
	motes.orbit_velocity_min = 0.02
	motes.orbit_velocity_max = 0.08
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 1.0
	motes.anim_speed_min = 0.6
	motes.anim_speed_max = 1.0
	motes.anim_offset_max = 1.0
	motes.color = tint
	motes.hue_variation_min = -0.04
	motes.hue_variation_max = 0.06
	motes.z_index = 0


func _ensure_motes() -> void:
	if _motes_warm != null:
		return
	_motes_warm = CPUParticles2D.new()
	_motes_warm.name = "MotesWarm"
	_configure_motes(_motes_warm, WARM_STRIP, Color(1.0, 0.84, 0.45, 0.75))
	add_child(_motes_warm)
	_motes_cyan = CPUParticles2D.new()
	_motes_cyan.name = "MotesCyan"
	_configure_motes(_motes_cyan, CYAN_STRIP, Color(1.0, 1.0, 1.0, 0.75))
	add_child(_motes_cyan)


func _apply_glade_bounds() -> void:
	var inset: Vector2 = _glade.size * 0.08
	var inner: Vector2 = _glade.size - inset * 2.0
	var half: Vector2 = inner * 0.5
	if _motes_warm != null:
		_motes_warm.emission_rect_extents = half
	if _motes_cyan != null:
		_motes_cyan.emission_rect_extents = half


func _process(delta: float) -> void:
	_refresh_strength(false)
	_tick_twinkle_sfx(delta)


static func reset_twinkle_state() -> void:
	_last_twinkle_msec = -100000000


static func twinkle_cooldown_msec() -> int:
	return TWINKLE_COOLDOWN_MSEC


## Returns a twinkle cue id when allowed; empty when blocked. Updates the global cooldown on fire.
static func try_twinkle_sfx(phase01: float, strength: float, now_msec: int, variant_index: int) -> String:
	if strength <= 0.04:
		return ""
	if not HubTimePhase.firefly_twinkle_night(phase01):
		return ""
	if now_msec - _last_twinkle_msec < TWINKLE_COOLDOWN_MSEC:
		return ""
	var idx: int = clampi(variant_index, 1, TWINKLE_CUE_IDS.size())
	_last_twinkle_msec = now_msec
	return TWINKLE_CUE_IDS[idx - 1]


func _tick_twinkle_sfx(delta: float) -> void:
	if _strength <= 0.04:
		return
	var phase01: float = HubTimePhase.sample_phase01()
	if not HubTimePhase.firefly_twinkle_night(phase01):
		return
	_twinkle_attempt_sec -= delta
	if _twinkle_attempt_sec > 0.0:
		return
	_schedule_twinkle_attempt()
	var cue_id: String = try_twinkle_sfx(phase01, _strength, Time.get_ticks_msec(), randi_range(1, TWINKLE_CUE_IDS.size()))
	if cue_id.is_empty():
		return
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio != null:
		audio.call("play", StringName(cue_id), 0.0, 1.0)


func _schedule_twinkle_attempt() -> void:
	_twinkle_attempt_sec = randf_range(0.35, 1.25)


func _apply_emitter_strength(motes: CPUParticles2D, cap: int) -> void:
	if motes == null:
		return
	motes.modulate.a = _strength
	motes.emitting = _strength > 0.04
	var live_amount: int = int(round(lerpf(0.0, float(cap), _strength)))
	motes.amount = maxi(live_amount, 1 if _strength > 0.04 else 0)


func _refresh_strength(force: bool) -> void:
	var target: float = HubTimePhase.firefly_strength(HubTimePhase.sample_phase01())
	if not force and is_equal_approx(target, _strength):
		return
	_strength = target
	_apply_emitter_strength(_motes_warm, WARM_AMOUNT_MAX)
	_apply_emitter_strength(_motes_cyan, CYAN_AMOUNT_MAX)
