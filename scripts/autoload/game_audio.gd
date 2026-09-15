extends Node
## Audio cue router per AUDIO_RESTART_V01.
## Buses: Music / SFX_UI / SFX_World / SFX_Progress. Music ducks under Progress.
## Missing assets → silent TODO hooks (scaffold never blocks on files).

signal cue_played(cue_id: StringName)
signal cue_missing(cue_id: StringName)

const MANIFEST_PATH: String = "res://data/audio_cues.json"

var _cues: Dictionary = {}
var _players: Dictionary = {}
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _progress_player: AudioStreamPlayer
var _hub_playing: bool = false
var _fruit_ready_played_cycle: bool = false


func _ready() -> void:
	_ensure_buses()
	_load_manifest()
	_music_player = _make_player("MusicPlayer", "Music")
	_sfx_player = _make_player("SfxPlayer", "SFX_World")
	_progress_player = _make_player("ProgressPlayer", "SFX_Progress")
	# Hub bed stays on through gather/walk/tend (no combat crossfade).
	call_deferred("play_hub_music")
	if Engine.has_singleton("GameState") or true:
		# Connect after GameState exists (autoload order: ContentStrings, GameAudio, GameState...).
		pass
	call_deferred("_connect_game_signals")


func _make_player(node_name: String, bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	p.bus = bus_name
	add_child(p)
	return p


func _ensure_buses() -> void:
	# Master is always index 0. Add named buses if missing.
	_add_bus_if_missing("Music")
	_add_bus_if_missing("SFX_UI")
	_add_bus_if_missing("SFX_World")
	_add_bus_if_missing("SFX_Progress")
	var music_idx: int = AudioServer.get_bus_index("Music")
	var progress_idx: int = AudioServer.get_bus_index("SFX_Progress")
	if music_idx < 0 or progress_idx < 0:
		return
	# Light music duck when Progress SFX fire (~4–6 dB).
	# Clear existing sends then add compressor-sidechain style via send.
	# Godot: use AudioEffectCompressor with sidechain on Music listening to Progress.
	var has_comp: bool = false
	for i: int in range(AudioServer.get_bus_effect_count(music_idx)):
		if AudioServer.get_bus_effect(music_idx, i) is AudioEffectCompressor:
			has_comp = true
			break
	if not has_comp:
		var comp := AudioEffectCompressor.new()
		comp.threshold = -12.0
		comp.ratio = 4.0
		comp.attack_us = 150000.0
		comp.release_ms = 1200.0
		comp.sidechain = "SFX_Progress"
		AudioServer.add_bus_effect(music_idx, comp)


func _add_bus_if_missing(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _load_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("GameAudio: missing audio_cues.json — cue IDs still accepted as no-ops")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	var cues: Variant = root.get("cues", {})
	if typeof(cues) == TYPE_DICTIONARY:
		_cues = cues


func _connect_game_signals() -> void:
	if not has_node("/root/GameState"):
		return
	GameState.stage_changed.connect(_on_stage_changed)
	GameState.fruit_ready_changed.connect(_on_fruit_ready)


func play_hub_music() -> void:
	play(&"mus_hub_forest")
	_hub_playing = true


func play(cue_id: StringName) -> void:
	var key: String = String(cue_id)
	if not _cues.has(key):
		# Still emit for wiring tests even if unknown.
		cue_missing.emit(cue_id)
		cue_played.emit(cue_id)
		return
	var meta: Dictionary = _cues[key]
	var path: String = str(meta.get("path", ""))
	var bus: String = str(meta.get("bus", "Master"))
	if path == "" or not ResourceLoader.exists(path):
		# TODO: drop .ogg under assets/audio/ and set path in audio_cues.json
		cue_missing.emit(cue_id)
		cue_played.emit(cue_id)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		cue_missing.emit(cue_id)
		return
	var player: AudioStreamPlayer = _sfx_player
	if bus == "Music":
		player = _music_player
	elif bus == "SFX_Progress":
		player = _progress_player
	elif bus == "SFX_UI":
		player = _sfx_player
		player.bus = "SFX_UI"
	else:
		player.bus = bus
	if bus == "Music" and bool(meta.get("loop", false)):
		# Keep hub bed through gather/walk; stings may briefly steal Music bus.
		if player.playing and player.stream == stream:
			cue_played.emit(cue_id)
			return
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream = stream
	player.bus = bus
	player.play()
	cue_played.emit(cue_id)



func play_quiet(cue_id: StringName, volume_db: float = -8.0) -> void:
	## Soft SFX under mus_hub_forest (channel 1Hz ticks stay cozy).
	var key: String = String(cue_id)
	if not _cues.has(key):
		cue_missing.emit(cue_id)
		cue_played.emit(cue_id)
		return
	var meta: Dictionary = _cues[key]
	var path: String = str(meta.get("path", ""))
	var bus: String = str(meta.get("bus", "Master"))
	if path == "" or not ResourceLoader.exists(path):
		cue_missing.emit(cue_id)
		cue_played.emit(cue_id)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		cue_missing.emit(cue_id)
		return
	var player: AudioStreamPlayer = _sfx_player
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.play()
	# Reset so other SFX stay full level
	call_deferred("_reset_sfx_volume")
	cue_played.emit(cue_id)


func _reset_sfx_volume() -> void:
	if _sfx_player and not _sfx_player.playing:
		_sfx_player.volume_db = 0.0


func play_gather(resource_id: StringName) -> void:
	match resource_id:
		&"wood":
			play_quiet(&"sfx_gather_wood", -8.0)
		&"stone":
			play_quiet(&"sfx_gather_stone", -8.0)
		&"food":
			play_quiet(&"sfx_gather_food", -8.0)
		&"manashards":
			play_quiet(&"sfx_gather_manashards", -8.0)
		_:
			play_quiet(&"sfx_gather_wood", -8.0)


func play_tree_water_ok() -> void:
	## Legacy one-shot water; channel pulses use play_water_pulse.
	play(&"sfx_tree_water")


func play_water_pulse() -> void:
	play_quiet(&"sfx_water_pulse", -10.0)


func play_channel_start() -> void:
	play_quiet(&"sfx_channel_start", -6.0)


func play_tree_deny() -> void:
	play(&"sfx_tree_deny")


func play_tree_offer() -> void:
	play(&"sfx_tree_offer")


func play_stage_up() -> void:
	play(&"sfx_stage_up")


func play_fruit_harvest() -> void:
	play(&"mus_fruit_sting")
	play(&"sfx_fruit_harvest")


func play_ascend() -> void:
	play(&"mus_ascend_sting")
	play(&"sfx_ascend")


func play_upgrade_buy() -> void:
	play(&"sfx_upgrade_buy")


func play_ui_confirm() -> void:
	play(&"sfx_ui_confirm")


func play_ui_cancel() -> void:
	play(&"sfx_ui_cancel")


func play_ui_open() -> void:
	play(&"sfx_ui_open")


func play_ui_close() -> void:
	play(&"sfx_ui_close")


func _on_stage_changed(stage_id: StringName) -> void:
	if stage_id != &"sapling":
		# Prefer stage sting over water SFX on the same advance frame.
		play_stage_up()
	if stage_id == &"ancient":
		_fruit_ready_played_cycle = false


func _on_fruit_ready(ready: bool) -> void:
	if ready and not _fruit_ready_played_cycle:
		_fruit_ready_played_cycle = true
		play(&"sfx_fruit_ready")


func reset_cycle_flags() -> void:
	_fruit_ready_played_cycle = false


func list_cue_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for k: Variant in _cues.keys():
		out.append(str(k))
	return out
