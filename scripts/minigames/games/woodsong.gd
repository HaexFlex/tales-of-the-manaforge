class_name Woodsong
extends Minigame
## 48 BPM chops. A click inside ±180 ms pays. Every 8th beat pays double, tuned
## so a perfect minute is still +120s. The alt96 loop is 96 BPM music under
## that same chop grid, and the game clock follows the loop while it plays.

const TUNE_PATH: String = "res://assets/audio/mus_woodsong_alt96.ogg"
const TUNE_RECT := Rect2(12, 264, 140, 44)

var _window: float = 0.18
var _interval: float = 1.25
var _heavy_every: int = 8
var _loop_sec: float = 20.0
var _next_t: float = 0.8
var _elapsed: float = 0.0
var _index: int = 0
var _open: Array[Dictionary] = []
var _rail: Sprite2D
var _notch_x: float = 110.0
var _tune_on: bool = true
var _tune_btn: TextureButton
var _player: AudioStreamPlayer
var _loops: int = 0
var _last_pos: float = 0.0
var _heard: bool = false
var _await_audio: bool = false


func game_id() -> String:
	return "woodsong"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("woodsong")
	_window = float(row.get("window_ms", 180)) / 1000.0
	var bpm: float = maxf(1.0, float(row.get("bpm", 48)))
	_interval = 60.0 / bpm
	_heavy_every = maxi(1, int(row.get("heavy_every", 8)))
	_loop_sec = maxf(1.0, float(row.get("tune_loop_sec", 20.0)))
	_next_t = _interval
	MinigameArt.add_sprite(self, "bg_grass.png", Vector2(320, 160))
	var tree: Sprite2D = MinigameArt.add_sprite(self, "node_tree.png", Vector2(250, 150))
	tree.scale = Vector2(0.55, 0.55)
	MinigameArt.add_sprite(self, "keeper_axe_e.png", Vector2(430, 230), 9)
	_rail = MinigameArt.add_sprite(self, "beat_rail.png", Vector2(320, 286))
	_rail.z_index = 2
	var notch: Sprite2D = MinigameArt.add_sprite(self, "beat_notch.png", Vector2(_notch_x, 270))
	notch.z_index = 3
	_tune_btn = TextureButton.new()
	_tune_btn.name = "Tune"
	_tune_btn.position = TUNE_RECT.position
	_tune_btn.size = TUNE_RECT.size
	_tune_btn.ignore_texture_size = true
	_tune_btn.stretch_mode = TextureButton.STRETCH_KEEP
	_tune_btn.focus_mode = Control.FOCUS_NONE
	_tune_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_tune_btn.z_index = 5
	_tune_btn.pressed.connect(_toggle_tune)
	add_child(_tune_btn)
	_paint_tune()
	_player = AudioStreamPlayer.new()
	_player.name = "Alt96"
	_player.bus = "Music"
	add_child(_player)
	_load_tune()


func begin() -> void:
	super.begin()
	if _tune_on:
		_start_tune()


func shutdown() -> void:
	super.shutdown()
	_stop_tune()


func _exit_tree() -> void:
	_stop_tune()


func _process(delta: float) -> void:
	if not playing:
		return
	var heard: float = _heard_clock()
	if heard >= 0.0:
		_elapsed = heard
	else:
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
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not TUNE_RECT.has_point(mb.position):
		_strike()


func on_key(event: InputEvent) -> void:
	if not playing or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_M:
		_toggle_tune()
		return
	if key.keycode == KEY_SPACE or key.keycode == KEY_ENTER:
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


func _toggle_tune() -> void:
	_tune_on = not _tune_on
	_paint_tune()
	if not playing:
		return
	if _tune_on:
		_start_tune()
	else:
		_stop_tune()


func _paint_tune() -> void:
	if _tune_btn == null:
		return
	var file: String = "tune_alt96.png" if _tune_on else "tune_off.png"
	var tex: Texture2D = MinigameArt.texture(file)
	_tune_btn.texture_normal = tex
	_tune_btn.texture_hover = tex
	_tune_btn.texture_pressed = tex
	_tune_btn.tooltip_text = "Music on" if _tune_on else "Music off"


func _load_tune() -> void:
	if not ResourceLoader.exists(TUNE_PATH):
		return
	var loaded: AudioStream = load(TUNE_PATH) as AudioStream
	if loaded == null:
		return
	var stream: AudioStream = loaded.duplicate() as AudioStream
	if stream == null:
		stream = loaded
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_player.stream = stream


func _start_tune() -> void:
	if _player == null or _player.stream == null:
		return
	_loops = int(floor(_elapsed / _loop_sec))
	var offset: float = _elapsed - float(_loops) * _loop_sec
	_last_pos = offset
	_heard = false
	_await_audio = true
	if has_node("/root/GameAudio"):
		GameAudio.hold_bed_for_tune()
	_player.play(offset)


func _stop_tune() -> void:
	_await_audio = false
	_heard = false
	if _player != null and is_instance_valid(_player) and _player.playing:
		_player.stop()
	if has_node("/root/GameAudio"):
		GameAudio.release_bed_for_tune()


func _heard_clock() -> float:
	if not _tune_on or _player == null or not _player.playing:
		return -1.0
	var pos: float = _player.get_playback_position()
	if _await_audio:
		var want: float = _elapsed - float(_loops) * _loop_sec
		var gap: float = absf(pos - want)
		if gap < 0.35 or gap > _loop_sec - 0.35:
			_await_audio = false
			_last_pos = pos
			_heard = true
		else:
			return -1.0
	if _heard and pos + 0.25 < _last_pos:
		_loops += 1
	_last_pos = pos
	_heard = true
	return float(_loops) * _loop_sec + pos
