class_name Woodsong
extends Minigame
## 48 BPM. A click inside ±180 ms pays. Every 8th beat pays double, tuned so a
## perfect minute is still +120s.

var _window: float = 0.18
var _interval: float = 1.25
var _heavy_every: int = 8
var _next_t: float = 0.8
var _elapsed: float = 0.0
var _index: int = 0
var _open: Array[Dictionary] = []
var _rail: Sprite2D
var _notch_x: float = 110.0


func game_id() -> String:
	return "woodsong"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("woodsong")
	_window = float(row.get("window_ms", 180)) / 1000.0
	var bpm: float = maxf(1.0, float(row.get("bpm", 48)))
	_interval = 60.0 / bpm
	_heavy_every = maxi(1, int(row.get("heavy_every", 8)))
	_next_t = _interval
	MinigameArt.add_sprite(self, "bg_grass.png", Vector2(320, 160))
	var tree: Sprite2D = MinigameArt.add_sprite(self, "node_tree.png", Vector2(250, 150))
	tree.scale = Vector2(0.55, 0.55)
	MinigameArt.add_sprite(self, "keeper_axe_e.png", Vector2(430, 230), 9)
	_rail = MinigameArt.add_sprite(self, "beat_rail.png", Vector2(320, 286))
	_rail.z_index = 2
	var notch: Sprite2D = MinigameArt.add_sprite(self, "beat_notch.png", Vector2(_notch_x, 270))
	notch.z_index = 3


func _process(delta: float) -> void:
	if not playing:
		return
	_elapsed += delta
	while _elapsed + 2.4 >= _next_t:
		_open.append({"t": _next_t, "i": _index, "done": false, "sprite": _make_marker(_index)})
		_index += 1
		_next_t += _interval
	var kept: Array[Dictionary] = []
	for beat_v: Dictionary in _open:
		var beat: Dictionary = beat_v
		var when: float = float(beat.get("t", 0.0))
		var spr: Sprite2D = beat.get("sprite") as Sprite2D
		if spr != null and is_instance_valid(spr):
			var ahead: float = when - _elapsed
			spr.position = Vector2(_notch_x + ahead * 200.0, 270)
			spr.visible = spr.position.x > 40.0 and spr.position.x < 620.0
		if bool(beat.get("done", false)):
			if spr != null and is_instance_valid(spr) and when + 0.4 < _elapsed:
				spr.queue_free()
			else:
				kept.append(beat)
			continue
		if _elapsed > when + _window:
			beat["done"] = true
			if spr != null and is_instance_valid(spr):
				spr.modulate = Color(1, 1, 1, 0.35)
		kept.append(beat)
	_open = kept


func _gui_input(event: InputEvent) -> void:
	if not playing or not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_strike()


func on_key(event: InputEvent) -> void:
	if not playing or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if key.pressed and not key.echo and (key.keycode == KEY_SPACE or key.keycode == KEY_ENTER):
		_strike()


func _strike() -> void:
	var best: int = -1
	var best_d: float = _window + 0.001
	for i: int in _open.size():
		var beat: Dictionary = _open[i]
		if bool(beat.get("done", false)):
			continue
		var d: float = absf(float(beat.get("t", 0.0)) - _elapsed)
		if d <= _window and d < best_d:
			best_d = d
			best = i
	if best < 0:
		return
	var hit: Dictionary = _open[best]
	hit["done"] = true
	_open[best] = hit
	var heavy: bool = int(hit.get("i", 0)) % _heavy_every == _heavy_every - 1
	succeed(MinigameCatalog.woodsong_k(heavy))
	var spr: Sprite2D = hit.get("sprite") as Sprite2D
	if spr != null and is_instance_valid(spr):
		spr.modulate = Color(1.15, 1.1, 0.85)


func _make_marker(index: int) -> Sprite2D:
	var heavy: bool = index % _heavy_every == _heavy_every - 1
	var spr: Sprite2D = MinigameArt.add_sprite(self, "beat_heavy.png" if heavy else "beat.png", Vector2(700, 270))
	spr.z_index = 4
	return spr
