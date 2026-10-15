class_name JustEnough
extends Minigame
## Hold to fill, release inside the drifting green band. One try every 1.8 seconds.

const GAUGE_POS := Vector2(78, 40)
const GAUGE_SIZE := Vector2(62, 240)

var _k: float = 3.6
var _cycle: float = 1.8
var _fill_sec: float = 1.0
var _pour_sec: float = 0.4
var _band_width: float = 0.1
var _band_center: float = 0.66
var _drift_amp: float = 0.12
var _drift_period: float = 6.0
var _clock: float = 0.0
var _t: float = 0.0
var _fill: float = 0.0
var _holding: bool = false
var _resolved: bool = false
var _pour: float = 0.0
var _fill_rect: ColorRect
var _band_rect: ColorRect


func game_id() -> String:
	return "just_enough"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("just_enough")
	_k = MinigameCatalog.k_for("just_enough")
	_cycle = float(row.get("cycle_sec", 1.8))
	_fill_sec = maxf(0.05, float(row.get("fill_sec", 1.0)))
	_pour_sec = maxf(0.0, float(row.get("pour_sec", 0.4)))
	_band_width = float(row.get("band_width", 0.1))
	_band_center = float(row.get("band_center", 0.66))
	_drift_amp = float(row.get("drift_amp", 0.12))
	_drift_period = maxf(0.1, float(row.get("drift_period", 6.0)))
	MinigameArt.add_sprite(self, "bg_grass.png", Vector2(320, 160))
	var sapling: Sprite2D = MinigameArt.add_sprite(self, "node_sapling.png", Vector2(430, 150))
	sapling.scale = Vector2(0.55, 0.55)
	MinigameArt.add_sprite(self, "keeper_water_e.png", Vector2(250, 240), 4)
	var gauge: Sprite2D = MinigameArt.add_sprite(self, "gauge_just.png", GAUGE_POS + GAUGE_SIZE * 0.5)
	gauge.z_index = 2
	_band_rect = ColorRect.new()
	_band_rect.color = Color(0.45, 0.62, 0.32, 0.55)
	_band_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band_rect.z_index = 3
	add_child(_band_rect)
	_fill_rect = ColorRect.new()
	_fill_rect.color = Color8(86, 122, 92)
	_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect.z_index = 3
	add_child(_fill_rect)
	_layout_gauge()


func _process(delta: float) -> void:
	if not playing:
		return
	_clock += delta
	_t += delta
	if _t >= _cycle:
		if not _resolved:
			_resolved = true
			miss()
		_t = 0.0
		_fill = 0.0
		_resolved = false
		_pour = 0.0
		_holding = false
	if _holding and not _resolved:
		_fill = minf(1.0, _fill + delta / _fill_sec)
		if _fill >= 1.0:
			_resolved = true
			miss()
	if _resolved and _pour > 0.0:
		_pour = maxf(0.0, _pour - delta)
	_layout_gauge()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_holding = true
	else:
		_holding = false
		_release()


func on_pointer_up() -> void:
	if not _holding:
		return
	_holding = false
	_release()


func on_key(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if key.keycode != KEY_SPACE or key.echo:
		return
	if key.pressed:
		_holding = true
	else:
		_holding = false
		_release()


func _release() -> void:
	if not playing or _resolved:
		return
	_resolved = true
	if _fill >= _band_lo() and _fill <= _band_hi():
		succeed(_k)
		_pour = _pour_sec
	else:
		_pour = 0.0
		miss()


func _layout_gauge() -> void:
	var inner := Rect2(GAUGE_POS + Vector2(14, 16), Vector2(34, 208))
	var band_h: float = inner.size.y * _band_width
	var band_y: float = inner.position.y + inner.size.y * (1.0 - _band_hi())
	_band_rect.position = Vector2(inner.position.x, band_y)
	_band_rect.size = Vector2(inner.size.x, band_h)
	var fill_h: float = inner.size.y * clampf(_fill, 0.0, 1.0)
	_fill_rect.position = Vector2(inner.position.x + 6.0, inner.end.y - fill_h)
	_fill_rect.size = Vector2(inner.size.x - 12.0, fill_h)


func _band_mid() -> float:
	return _band_center + _drift_amp * sin(TAU * _clock / _drift_period)


func _band_lo() -> float:
	return _band_mid() - _band_width * 0.5


func _band_hi() -> float:
	return _band_mid() + _band_width * 0.5
