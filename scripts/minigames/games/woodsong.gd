class_name Woodsong
extends Minigame
## 48 BPM chops. A click inside ±180 ms pays. Every 8th beat pays double, tuned
## so a perfect minute is still +120s. The alt96 loop is 96 BPM music under
## that same chop grid, and the game clock follows the loop while it plays.

const TUNE_PATH: String = "res://assets/audio/mus_woodsong_alt96.ogg"
const TUNE_RECT := Rect2(12, 264, 140, 44)
## r6 puts the beat rail on the top of the play field, clear of the tune button.
const RAIL_POS := Vector2(320, 32)
const NOTCH_X: float = 100.0
## Volume plate sits beside the tune button. The value survives Play again.
const VOL_RECT := Rect2(160, 264, 196, 44)
## Track width is the plate minus the 20 px side margins the prototype leaves.
const VOL_TRACK_W: float = 156.0
static var _saved_volume: float = 0.8

var _window: float = 0.18
var _interval: float = 1.25
var _heavy_every: int = 8
var _loop_sec: float = 20.0
var _next_t: float = 0.8
var _elapsed: float = 0.0
var _index: int = 0
var _open: Array[Dictionary] = []
var _rail: Sprite2D
var _notch: Sprite2D
var _tune_on: bool = true
var _tune_btn: TextureButton
var _vol_fill: TextureRect
var _vol_grab: TextureRect
var _player: AudioStreamPlayer
var _loops: int = 0
var _last_pos: float = 0.0
var _heard: bool = false
var _await_audio: bool = false
var _keeper: Sprite2D
var _swing_at: float = -10.0
## Keeper on the left, tree just right of centre, so swing frame 2 meets the trunk.
const KEEPER_POS := Vector2(278, 248)
const TREE_POS := Vector2(408, 156)
const AXE_TIP := Vector2(63, -19)


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
	var tree: Sprite2D = MinigameArt.add_sprite(self, "node_tree.png", TREE_POS)
	tree.scale = Vector2.ONE
	_keeper = MinigameArt.add_sprite(self, "keeper_axe_e.png", KEEPER_POS, 9)
	_keeper.z_index = 2
	## The rail art is dark brown. A cream plate keeps it readable on the tree.
	var plate := ColorRect.new()
	plate.name = "RailPlate"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.color = Color8(250, 242, 220)
	plate.position = Vector2(RAIL_POS.x - 308.0, RAIL_POS.y - 28.0)
	plate.size = Vector2(616, 56)
	plate.z_index = 5
	add_child(plate)
	_rail = MinigameArt.add_sprite(self, "beat_rail.png", RAIL_POS)
	_rail.z_index = 6
	_notch = MinigameArt.add_sprite(self, "beat_notch.png", Vector2(NOTCH_X, RAIL_POS.y - 2.0))
	_notch.z_index = 8
	## The stretched window plate can peek through the bottom clip as a cream seam.
	var foot := ColorRect.new()
	foot.name = "PlayFoot"
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.color = Color8(106, 170, 46)
	foot.position = Vector2(0, 316)
	foot.size = Vector2(640, 6)
	foot.z_index = 12
	add_child(foot)
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
	_build_volume()
	_seat_chrome()
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
	_reclaim_chrome()
	super.shutdown()
	_stop_tune()


## Music On and the volume plate sit in the header strip, not on the play field.
func _seat_chrome() -> void:
	var play := get_parent() as Control
	if play == null or str(play.name) != "Play":
		return
	var window := play.get_parent() as Control
	if window == null:
		return
	var strip_y: float = play.position.y
	var next_y: float = strip_y + 48.0
	var content_bottom: float = play.position.y + play.size.y * play.scale.y
	var budget: float = content_bottom - next_y
	var fitted_y: float = clampf(budget / maxf(size.y, 1.0), 0.5, play.scale.y)
	play.position.y = next_y
	play.scale = Vector2(play.scale.x, fitted_y)
	_park_chrome(_tune_btn, window, Vector2(play.position.x, strip_y))
	var volume := get_node_or_null("Volume") as Control
	_park_chrome(volume, window, Vector2(play.position.x + TUNE_RECT.size.x + 8.0, strip_y))


func _park_chrome(node: Control, window: Control, at: Vector2) -> void:
	if node == null:
		return
	var parent := node.get_parent()
	if parent != null and parent != window:
		parent.remove_child(node)
		window.add_child(node)
	node.position = at
	node.z_index = 8


func _reclaim_chrome() -> void:
	for node_name: String in ["Tune", "Volume"]:
		var node := get_node_or_null(node_name) as Control
		if node == null:
			var window := get_parent().get_parent() if get_parent() != null else null
			if window != null:
				node = window.get_node_or_null(node_name) as Control
		if node == null or node.get_parent() == self:
			continue
		var parent := node.get_parent()
		parent.remove_child(node)
		add_child(node)


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
			spr.position = Vector2(NOTCH_X + ahead * 200.0, RAIL_POS.y)
			## Stay on the rail. The left cap is the notch, and markers must not cover it.
			spr.visible = spr.position.x > NOTCH_X + 18.0 and spr.position.x < 612.0
		if bool(beat.get("done", false)):
			if spr != null and is_instance_valid(spr) and when + 0.4 < _elapsed:
				spr.queue_free()
			else:
				kept.append(beat)
			continue
		if _elapsed > when + _window:
			beat["done"] = true
			miss()
			if spr != null and is_instance_valid(spr):
				spr.modulate = Color(1, 1, 1, 0.35)
		kept.append(beat)
	_open = kept
	_paint_keeper()


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
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_M:
		_toggle_tune()
		return
	if key.keycode == KEY_BRACKETLEFT or key.keycode == KEY_BRACKETRIGHT:
		var step: float = 0.1 if key.keycode == KEY_BRACKETRIGHT else -0.1
		_saved_volume = clampf(_saved_volume + step, 0.0, 1.0)
		_paint_volume()
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
	_swing_at = _elapsed
	succeed(MinigameCatalog.woodsong_k(heavy), 2.0 if heavy else 1.0, Vector2(NOTCH_X, RAIL_POS.y))
	_paint_keeper()
	var spr: Sprite2D = hit.get("sprite") as Sprite2D
	if spr != null and is_instance_valid(spr):
		spr.modulate = Color(1.15, 1.1, 0.85)


func _paint_keeper() -> void:
	if _keeper == null:
		return
	var age: float = _elapsed - _swing_at
	if age >= 0.0 and age < 0.45:
		_keeper.frame = mini(8, int(floor(age / 0.05)))
	else:
		_keeper.frame = 0


func _make_marker(index: int) -> Sprite2D:
	var heavy: bool = index % _heavy_every == _heavy_every - 1
	var spr: Sprite2D = MinigameArt.add_sprite(self, "beat_heavy.png" if heavy else "beat.png", Vector2(700, RAIL_POS.y))
	spr.z_index = 7
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


func _build_volume() -> void:
	var plate := Control.new()
	plate.name = "Volume"
	plate.position = VOL_RECT.position
	plate.size = VOL_RECT.size
	plate.mouse_filter = Control.MOUSE_FILTER_STOP
	plate.z_index = 5
	plate.gui_input.connect(_on_volume_input)
	add_child(plate)
	var back := TextureRect.new()
	back.name = "Plate"
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.texture = MinigameArt.texture("vol_plate.png")
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_SCALE
	back.size = VOL_RECT.size
	plate.add_child(back)
	_vol_fill = TextureRect.new()
	_vol_fill.name = "Fill"
	_vol_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vol_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vol_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_vol_fill.position = Vector2(20, 15)
	plate.add_child(_vol_fill)
	_vol_grab = TextureRect.new()
	_vol_grab.name = "Grab"
	_vol_grab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vol_grab.texture = MinigameArt.texture("vol_grab.png")
	_vol_grab.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vol_grab.stretch_mode = TextureRect.STRETCH_KEEP
	_vol_grab.size = Vector2(24, 24)
	plate.add_child(_vol_grab)
	_paint_volume()


func _paint_volume() -> void:
	var v: float = clampf(_saved_volume, 0.0, 1.0)
	var fw: float = maxf(8.0, roundf((VOL_TRACK_W - 4.0) * v))
	if _vol_fill != null:
		var src: Texture2D = MinigameArt.texture("vol_fill.png")
		var atlas := AtlasTexture.new()
		atlas.atlas = src
		atlas.region = Rect2(0, 0, fw, 14)
		_vol_fill.texture = atlas
		_vol_fill.size = Vector2(fw, 14)
	if _vol_grab != null:
		_vol_grab.position = Vector2(20.0 + roundf((VOL_TRACK_W - 24.0) * v), 10.0)
	_apply_volume()


func _apply_volume() -> void:
	if _player == null:
		return
	var v: float = clampf(_saved_volume, 0.0, 1.0)
	_player.volume_db = -80.0 if v <= 0.001 else linear_to_db(v)


func _on_volume_input(event: InputEvent) -> void:
	var local_x: float = -1.0
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
			return
		local_x = mb.position.x
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
			return
		local_x = mm.position.x
	else:
		return
	## Grab center sits 32 px in from the plate, then travels the 132 px track.
	_saved_volume = clampf((local_x - 32.0) / (VOL_TRACK_W - 24.0), 0.0, 1.0)
	_paint_volume()


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
	_apply_volume()
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
