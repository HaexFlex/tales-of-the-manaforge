extends CanvasModulate
class_name HubDayNightCycle
## Gentle hub tint cycle (day → dusk → night → dawn). Real-time ~20 min per loop.
## Spawned at runtime so scenes stay free of CanvasModulate (compat scan).

const CYCLE_SEC: float = 1200.0

const _KEY_COLORS: Array[Color] = [
	Color(1.0, 1.0, 0.98, 1.0),
	Color(1.0, 0.92, 0.78, 1.0),
	Color(0.88, 0.90, 1.0, 1.0),
	Color(1.0, 0.95, 0.85, 1.0),
]

signal dusk_ground_changed(use_dusk: bool)

var _start_msec: int = 0
var _dusk_ground_active: bool = false


func _init() -> void:
	name = "HubDayNightModulate"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	color = Color.WHITE
	set_process(true)


func _process(_delta: float) -> void:
	var use_dusk: bool = false
	if not GameAudio.day_night_enabled:
		color = Color.WHITE
	else:
		var elapsed_sec: float = float(Time.get_ticks_msec() - _start_msec) * 0.001
		var phase: float = fmod(elapsed_sec / CYCLE_SEC, 1.0)
		color = _sample_phase(phase)
		use_dusk = HubGroundDusk.wants_dusk_textures(phase)
	_set_dusk_ground_active(use_dusk)


func _set_dusk_ground_active(use_dusk: bool) -> void:
	if use_dusk == _dusk_ground_active:
		return
	_dusk_ground_active = use_dusk
	dusk_ground_changed.emit(use_dusk)


func _sample_phase(phase: float) -> Color:
	var count: int = _KEY_COLORS.size()
	var seg: float = phase * float(count)
	var index: int = int(floor(seg)) % count
	var t: float = smoothstep(0.0, 1.0, seg - floor(seg))
	var from: Color = _KEY_COLORS[index]
	var to: Color = _KEY_COLORS[(index + 1) % count]
	return from.lerp(to, t)
