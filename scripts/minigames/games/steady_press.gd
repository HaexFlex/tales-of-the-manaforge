class_name SteadyPress
extends Minigame
## Circle the crank, release in the mark band. Stopping sags. Past the top, it vents.
## One cycle every 4 seconds. Spare time waits.

const DIAL := Vector2(230, 168)

var _k: float = 8.0
var _cycle: float = 4.0
var _band_start: float = 0.70
var _band: float = 0.15
var _t: float = 0.0
var _pressure: float = 0.0
var _angle: float = 0.0
var _holding: bool = false
var _turning: bool = false
var _resolved: bool = false
var _last_key: int = 0
var _needle: Sprite2D
var _crank: Sprite2D
var _vent: Sprite2D
var _rim: Sprite2D


func game_id() -> String:
	return "steady_press"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("steady_press")
	_k = MinigameCatalog.k_for("steady_press")
	_cycle = float(row.get("cycle_sec", 4.0))
	_band_start = float(row.get("band_start", 0.70))
	_band = float(row.get("band", 0.15))
	MinigameArt.add_sprite(self, "bg_forge.png", Vector2(320, 160))
	MinigameArt.add_sprite(self, "st_mill.png", Vector2(500, 170))
	_rim = MinigameArt.add_sprite(self, "rim_green.png", DIAL)
	_rim.z_index = 2
	MinigameArt.add_sprite(self, "press_dial.png", DIAL + Vector2(0, 8)).z_index = 2
	_crank = MinigameArt.add_sprite(self, "crank_8f.png", DIAL, 8)
	_crank.z_index = 3
	_needle = MinigameArt.add_sprite(self, "needle.png", DIAL + Vector2(0, -8))
	_needle.z_index = 4
	_vent = MinigameArt.add_sprite(self, "vent.png", DIAL + Vector2(78, -20))
	_vent.z_index = 4
	_vent.visible = false


func _process(delta: float) -> void:
	if not playing:
		return
	_t += delta
	if not _resolved and not _turning:
		_pressure = maxf(0.0, _pressure - 0.12 * delta)
	_turning = false
	if _t >= _cycle:
		_t = 0.0
		_pressure = 0.0
		_resolved = false
		_vent.visible = false
	_paint()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_holding = true
			_angle = (mb.position - DIAL).angle()
		else:
			_holding = false
			_release()
	elif event is InputEventMouseMotion and _holding:
		_crank_to((event as InputEventMouseMotion).position)


func on_pointer_up() -> void:
	if not _holding:
		return
	_holding = false
	_release()


func on_key(event: InputEvent) -> void:
	if not playing or _resolved or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	var code: int = int(key.keycode)
	if code != KEY_A and code != KEY_D and code != KEY_LEFT and code != KEY_RIGHT:
		return
	if _last_key != 0 and _last_key != code:
		_pressure += 0.14
		_turning = true
		if _pressure >= 1.0:
			_overcrank()
	_last_key = code


func _crank_to(pos: Vector2) -> void:
	if _resolved:
		return
	var ang: float = (pos - DIAL).angle()
	var delta: float = wrapf(ang - _angle, -PI, PI)
	_angle = ang
	if absf(delta) < 0.02:
		return
	_turning = true
	_pressure += absf(delta) / TAU * 0.9
	if _pressure >= 1.0:
		_overcrank()


func _release() -> void:
	if not playing or _resolved:
		return
	_resolved = true
	if _pressure >= _band_start and _pressure <= _band_start + _band:
		succeed(_k)


func _overcrank() -> void:
	_resolved = true
	_pressure = 0.45
	_vent.visible = true
	if _vent.texture != null:
		_vent.texture = MinigameArt.texture("vent_open.png")


func _paint() -> void:
	if _needle != null:
		_needle.rotation = lerpf(-2.4, 0.6, clampf(_pressure, 0.0, 1.0))
	if _crank != null:
		_crank.frame = posmod(int(floor(_angle / TAU * 8.0)), 8)
	if _rim != null:
		var tex: Texture2D = MinigameArt.texture("rim_green.png" if _in_band() else "rim_amber.png")
		if tex != null:
			_rim.texture = tex


func _in_band() -> bool:
	return _pressure >= _band_start and _pressure <= _band_start + _band
