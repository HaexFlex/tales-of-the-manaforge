extends Node
## Audio cue router. Buses: Music / SFX_UI / SFX_World / SFX_Progress.
## Every play sets volume_db and pitch_scale on its own voice. Progress ducks the hub bed only.

signal cue_played(cue_id: StringName)
signal cue_missing(cue_id: StringName)
signal volumes_changed(music_linear: float, sfx_linear: float)

const MANIFEST_PATH: String = "res://data/audio_cues.json"
const SETTINGS_PATH: String = "user://manaforge_settings.cfg"
const SETTINGS_SECTION: String = "audio"
const MUSIC_BUS_DEFAULT_DB: float = -9.0
const SFX_BUS_DEFAULT_DB: float = 0.0
const SFX_BUS_NAMES: PackedStringArray = ["SFX_UI", "SFX_World", "SFX_Progress"]
const SFX_POOL_SIZE: int = 4
const PROGRESS_POOL_SIZE: int = 2
## JSON path first, then this shipped MP3. Legacy beds live under assets/library/legacy/.
const HUB_STREAM_CANDIDATES: PackedStringArray = [
	"res://assets/audio/mus_hub_forest_haex.mp3",
]
const FORGE_JOB_CUES: PackedStringArray = [
	"sfx_forge_craft_start",
	"sfx_forge_craft_done",
	"sfx_press_squeeze",
	"sfx_forge_big_done",
]
const MUSIC_VOLUME_ZERO_MEANS_DEFAULT: bool = true

var _cues: Dictionary = {}
var _music_player: AudioStreamPlayer
var _sting_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _progress_pool: Array[AudioStreamPlayer] = []
var _hub_playing: bool = false
var _hub_suspended: bool = false
var _fruit_ready_played_cycle: bool = false
var _fruit_ready_after_stage: bool = false
var _fruit_delay_token: int = 0
var _played_log: PackedStringArray = PackedStringArray()
var music_volume_linear: float = 1.0
var sfx_volume_linear: float = 1.0
var _forge_mix_on: bool = false
var _forge_music_offset_db: float = 0.0
var _forge_lowpass: AudioEffectLowPassFilter
var _forge_reverb: AudioEffectReverb
var last_cue_volume_db: float = 0.0
var _duck_amount_db: float = -5.0
var _duck_attack_sec: float = 0.05
var _duck_release_sec: float = 0.6
var _duck_hold: String = "while_playing"
var _duck_db: float = 0.0
var _duck_tween: Tween
var _progress_holds: int = 0
var _gather_offset_db: float = -12.0
var _gather_pitch_min: float = 0.96
var _gather_pitch_max: float = 1.04
var _gather_gap_sec: float = 0.9
var _fruit_ready_delay_sec: float = 0.7
var _last_gather_msec: int = -100000000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_load_manifest()
	_music_player = _make_player("MusicPlayer", "Music")
	_sting_player = _make_player("StingPlayer", "Music")
	for i: int in SFX_POOL_SIZE:
		var sfx: AudioStreamPlayer = _make_player("SfxVoice%d" % i, "SFX_World")
		_sfx_pool.append(sfx)
	for i: int in PROGRESS_POOL_SIZE:
		var progress: AudioStreamPlayer = _make_player("ProgressVoice%d" % i, "SFX_Progress")
		progress.finished.connect(_on_progress_finished.bind(progress))
		_progress_pool.append(progress)
	_sting_player.finished.connect(_on_sting_finished)
	load_settings()
	apply_volumes()
	call_deferred("play_hub_music")
	call_deferred("_connect_game_signals")
	if not cue_played.is_connected(_on_cue_logged):
		cue_played.connect(_on_cue_logged)


func _make_player(node_name: String, bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	p.bus = bus_name
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


func _ensure_buses() -> void:
	_add_bus_if_missing("Music")
	_add_bus_if_missing("SFX_UI")
	_add_bus_if_missing("SFX_World")
	_add_bus_if_missing("SFX_Progress")
	## Duck is a bed-player envelope. A sidechain compressor would also duck the stings.
	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx < 0:
		return
	for i: int in range(AudioServer.get_bus_effect_count(music_idx) - 1, -1, -1):
		if AudioServer.get_bus_effect(music_idx, i) is AudioEffectCompressor:
			AudioServer.remove_bus_effect(music_idx, i)


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
	var duck_v: Variant = root.get("duck", {})
	if typeof(duck_v) == TYPE_DICTIONARY:
		var duck: Dictionary = duck_v
		_duck_amount_db = float(duck.get("amount_db", -5.0))
		_duck_attack_sec = float(duck.get("attack_sec", 0.05))
		_duck_release_sec = float(duck.get("release_sec", 0.6))
		_duck_hold = str(duck.get("hold", "while_playing"))
	var gather_v: Variant = root.get("gather_tick", {})
	if typeof(gather_v) == TYPE_DICTIONARY:
		var gather: Dictionary = gather_v
		_gather_offset_db = float(gather.get("offset_db", -12.0))
		_gather_pitch_min = float(gather.get("pitch_min", 0.96))
		_gather_pitch_max = float(gather.get("pitch_max", 1.04))
		_gather_gap_sec = float(gather.get("gap_sec", 0.9))
	_fruit_ready_delay_sec = float(root.get("fruit_ready_delay_sec", 0.7))


func duck_amount_db() -> float:
	return _duck_amount_db


func duck_attack_sec() -> float:
	return _duck_attack_sec


func duck_release_sec() -> float:
	return _duck_release_sec


func duck_hold() -> String:
	return _duck_hold


func music_bed_volume_db() -> float:
	if _music_player == null:
		return 0.0
	return _music_player.volume_db


func _connect_game_signals() -> void:
	if not has_node("/root/GameState"):
		return
	GameState.stage_changed.connect(_on_stage_changed)
	GameState.fruit_ready_changed.connect(_on_fruit_ready)
	if GameState.has_signal("keeper_harvested") and not GameState.keeper_harvested.is_connected(_on_keeper_harvested):
		GameState.keeper_harvested.connect(_on_keeper_harvested)
	if GameState.has_signal("wisp_assigned"):
		GameState.wisp_assigned.connect(_on_wisp_assigned)
	if GameState.has_signal("wisp_assign_failed"):
		GameState.wisp_assign_failed.connect(_on_wisp_assign_failed)
	if GameState.has_signal("wisp_unassigned"):
		GameState.wisp_unassigned.connect(_on_wisp_unassigned)
	if GameState.has_signal("wisp_pulsed"):
		GameState.wisp_pulsed.connect(_on_wisp_pulsed)


func play_hub_music() -> void:
	if _hub_suspended:
		return
	play(&"mus_hub_forest")
	_hub_playing = true


func suspend_hub_for_battle() -> void:
	_hub_suspended = true
	_hub_playing = false
	if _music_player and _music_player.playing and not _music_player.stream_paused:
		_music_player.stream_paused = true
	if _sting_player and _sting_player.playing:
		_sting_player.stop()


func resume_hub_after_battle() -> void:
	_hub_suspended = false
	if _music_player and _music_player.stream_paused:
		_music_player.stream_paused = false
		_hub_playing = _music_player.playing
		if _hub_playing:
			_ensure_music_bus_audible()
			return
	play_hub_music()


func is_hub_bed_paused() -> bool:
	return _music_player != null and _music_player.stream_paused


func is_hub_suspended() -> bool:
	return _hub_suspended


func is_hub_music_playing() -> bool:
	return _music_player != null and _music_player.playing and _hub_playing


func get_hub_stream() -> AudioStream:
	if _music_player == null:
		return null
	return _music_player.stream


func forge_mix_on() -> bool:
	return _forge_mix_on


func forge_lowpass_hz() -> float:
	if _forge_lowpass == null:
		return 0.0
	return _forge_lowpass.cutoff_hz


func forge_music_offset_db() -> float:
	return _forge_music_offset_db


func cue_bus(cue_id: String) -> String:
	return _cue_bus(cue_id)


func set_forge_room_mix(enabled: bool, lowpass_hz: float = 1500.0, room_size: float = 0.35, gain_db: float = -3.0) -> void:
	var idx: int = AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	if enabled == _forge_mix_on:
		return
	if enabled:
		_forge_lowpass = AudioEffectLowPassFilter.new()
		_forge_lowpass.cutoff_hz = lowpass_hz
		_forge_reverb = AudioEffectReverb.new()
		_forge_reverb.room_size = room_size
		AudioServer.add_bus_effect(idx, _forge_lowpass)
		AudioServer.add_bus_effect(idx, _forge_reverb)
		_forge_music_offset_db = gain_db
		_forge_mix_on = true
	else:
		_remove_bus_effect("Music", _forge_lowpass)
		_remove_bus_effect("Music", _forge_reverb)
		_forge_lowpass = null
		_forge_reverb = null
		_forge_music_offset_db = 0.0
		_forge_mix_on = false
	apply_volumes()


func _remove_bus_effect(bus_name: String, effect: AudioEffect) -> void:
	if effect == null:
		return
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	for i: int in range(AudioServer.get_bus_effect_count(idx) - 1, -1, -1):
		if AudioServer.get_bus_effect(idx, i) == effect:
			AudioServer.remove_bus_effect(idx, i)


func play(cue_id: StringName, offset_db: float = 0.0, pitch: float = 1.0) -> void:
	var key: String = String(cue_id)
	var bus: String = _cue_bus(key)
	var base_db: float = 0.0
	if _cues.has(key) and typeof(_cues[key]) == TYPE_DICTIONARY:
		base_db = float((_cues[key] as Dictionary).get("volume_db", 0.0))
	var effective_db: float = base_db + offset_db
	if _hub_suspended and bus == "Music":
		return
	if _held_while_fruit_committed(key, bus):
		return
	if not _cues.has(key):
		cue_missing.emit(cue_id)
		cue_played.emit(cue_id)
		return
	var meta: Dictionary = _cues[key]
	var path: String = str(meta.get("path", ""))
	bus = str(meta.get("bus", "Master"))
	var looping: bool = bool(meta.get("loop", false))
	if bus == "Music":
		if looping or key == "mus_hub_forest":
			var hub_stream: AudioStream = null
			if key == "mus_hub_forest":
				hub_stream = _resolve_hub_stream(path)
			elif path != "" and ResourceLoader.exists(path):
				hub_stream = load(path) as AudioStream
			if hub_stream == null:
				cue_missing.emit(cue_id)
				cue_played.emit(cue_id)
				return
			_play_hub_stream(hub_stream, bus)
			cue_played.emit(cue_id)
			return
		if path == "" or not ResourceLoader.exists(path):
			cue_missing.emit(cue_id)
			cue_played.emit(cue_id)
			return
		var sting: AudioStream = load(path) as AudioStream
		if sting == null:
			cue_missing.emit(cue_id)
			return
		_sting_player.volume_db = effective_db
		_sting_player.pitch_scale = pitch
		_play_sting_stream(sting, bus)
		cue_played.emit(cue_id)
		return
	if path == "" or not ResourceLoader.exists(path):
		cue_missing.emit(cue_id)
		cue_played.emit(cue_id)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		cue_missing.emit(cue_id)
		return
	var progress: bool = bus == "SFX_Progress"
	var player: AudioStreamPlayer = _claim_voice(_progress_pool if progress else _sfx_pool, progress)
	player.stream = stream
	player.bus = bus
	player.volume_db = effective_db
	player.pitch_scale = pitch
	if bus != "Music":
		last_cue_volume_db = effective_db
	player.play()
	if progress:
		_note_progress_started()
	cue_played.emit(cue_id)


func _held_while_fruit_committed(key: String, bus: String) -> bool:
	if not has_node("/root/GameState") or not GameState.fruit_committed:
		return false
	if key in FORGE_JOB_CUES:
		return true
	return bus == "SFX_World"


func _claim_voice(pool: Array[AudioStreamPlayer], is_progress: bool) -> AudioStreamPlayer:
	var idle: AudioStreamPlayer = null
	var oldest: AudioStreamPlayer = pool[0]
	var oldest_msec: int = 2147483647
	for voice: AudioStreamPlayer in pool:
		if not voice.playing:
			idle = voice
			break
		var started: int = int(voice.get_meta("started_msec", 0))
		if started < oldest_msec:
			oldest_msec = started
			oldest = voice
	var chosen: AudioStreamPlayer = idle if idle != null else oldest
	if chosen.playing and bool(chosen.get_meta("is_progress", false)):
		chosen.set_meta("is_progress", false)
		_note_progress_ended()
	chosen.set_meta("is_progress", is_progress)
	chosen.set_meta("started_msec", Time.get_ticks_msec())
	return chosen


func _note_progress_started() -> void:
	_progress_holds += 1
	_tween_duck(_duck_amount_db, _duck_attack_sec)


func _note_progress_ended() -> void:
	_progress_holds = maxi(0, _progress_holds - 1)
	if _progress_holds == 0:
		_tween_duck(0.0, _duck_release_sec)


func _on_progress_finished(voice: AudioStreamPlayer) -> void:
	if not bool(voice.get_meta("is_progress", false)):
		return
	voice.set_meta("is_progress", false)
	_note_progress_ended()


func _tween_duck(target_db: float, seconds: float) -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	var span: float = maxf(seconds, 0.0)
	if span <= 0.0001 or is_equal_approx(_duck_db, target_db):
		_apply_duck_db(target_db)
		return
	_duck_tween = create_tween()
	_duck_tween.tween_method(_apply_duck_db, _duck_db, target_db, span)


func _apply_duck_db(value: float) -> void:
	_duck_db = value
	if _music_player:
		_music_player.volume_db = _duck_db


func _resolve_hub_stream(primary_path: String) -> AudioStream:
	var tried: Dictionary = {}
	var ordered: PackedStringArray = PackedStringArray()
	if primary_path != "":
		ordered.append(primary_path)
	for candidate: String in HUB_STREAM_CANDIDATES:
		if candidate not in ordered:
			ordered.append(candidate)
	for path: String in ordered:
		if tried.has(path):
			continue
		tried[path] = true
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path) as AudioStream
		if stream != null:
			return stream
	return null


func _force_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _ensure_music_bus_audible() -> void:
	var idx: int = AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, false)
	if music_volume_linear <= 0.001:
		music_volume_linear = 1.0
	_apply_bus_volume("Music", music_volume_linear, MUSIC_BUS_DEFAULT_DB)


func _play_hub_stream(stream: AudioStream, bus: String) -> void:
	var player: AudioStreamPlayer = _music_player
	if player.playing and player.stream == stream:
		_hub_playing = true
		_ensure_music_bus_audible()
		player.volume_db = _duck_db
		return
	_force_stream_loop(stream)
	_ensure_music_bus_audible()
	player.stream = stream
	player.bus = bus
	player.volume_db = _duck_db
	player.pitch_scale = 1.0
	player.play()
	_hub_playing = true


func _play_sting_stream(stream: AudioStream, bus: String) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = false
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_sting_player.stream = stream
	_sting_player.bus = bus
	_sting_player.play()
	if _hub_suspended:
		return
	if not _music_player.playing:
		play_hub_music()


func _on_sting_finished() -> void:
	if _hub_suspended:
		return
	if not _music_player.playing:
		play_hub_music()
	else:
		_hub_playing = true


func play_quiet(cue_id: StringName, volume_db: float = -8.0) -> void:
	play(cue_id, volume_db, 1.0)


func play_gather(resource_id: StringName) -> void:
	if has_node("/root/ForgeJobs") and ForgeJobs.in_forge_scene():
		return
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return
	var tree: SceneTree = get_tree()
	if tree != null and tree.paused:
		return
	if has_node("/root/GameState") and GameState.fruit_committed:
		return
	var cue: StringName = &""
	match resource_id:
		&"wood":
			cue = &"sfx_gather_wood"
		&"stone":
			cue = &"sfx_gather_stone"
		&"food":
			cue = &"sfx_gather_food"
		_:
			return
	var now: int = Time.get_ticks_msec()
	if now - _last_gather_msec < int(_gather_gap_sec * 1000.0):
		return
	_last_gather_msec = now
	var pitch: float = randf_range(_gather_pitch_min, _gather_pitch_max)
	play(cue, _gather_offset_db, pitch)


func _on_keeper_harvested(resource_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	play_gather(resource_id)


func play_tree_water_ok() -> void:
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
	play(&"sfx_fruit_harvest")
	play(&"mus_fruit_sting")


func play_ascend() -> void:
	play(&"sfx_ascend")
	play(&"mus_ascend_sting")


func play_upgrade_buy() -> void:
	play(&"sfx_upgrade_buy")


func play_ui_confirm() -> void:
	play(&"sfx_ui_confirm")


func play_ui_cancel() -> void:
	play(&"sfx_ui_cancel")


func play_ui_deny() -> void:
	play(&"sfx_ui_deny")


func play_ui_open() -> void:
	play(&"sfx_ui_open")


func play_ui_close() -> void:
	play(&"sfx_ui_close")


func play_wisp_assign() -> void:
	play(&"sfx_wisp_assign")


func play_wisp_deny() -> void:
	play(&"sfx_wisp_deny")


func play_wisp_unassign() -> void:
	play(&"sfx_wisp_unassign")


func play_wisp_pulse() -> void:
	play_quiet(&"sfx_wisp_pulse", -8.0)


func _on_wisp_assigned(_wisp_id: int, _node_id: String, result: String) -> void:
	if result == "ok" or result == "reassign" or result == "join":
		play_wisp_assign()


func _on_wisp_assign_failed(reason: String, _node_id: String) -> void:
	if reason == "busy":
		play_wisp_deny()


func _on_wisp_unassigned(_wisp_id: int) -> void:
	play_wisp_unassign()


func _on_wisp_pulsed(_resource_id: StringName) -> void:
	play_wisp_pulse()


func _on_stage_changed(stage_id: StringName) -> void:
	if has_node("/root/GameState") and GameState.applying_save:
		_fruit_ready_played_cycle = GameState.fruit_ready or GameState.fruit_committed
		_fruit_ready_after_stage = false
		return
	if stage_id != &"sapling":
		play_stage_up()
	if stage_id == &"ancient":
		_fruit_ready_played_cycle = false
		_fruit_ready_after_stage = true


func _on_fruit_ready(ready: bool) -> void:
	if has_node("/root/GameState") and GameState.applying_save:
		_fruit_ready_played_cycle = GameState.fruit_ready or GameState.fruit_committed
		_fruit_ready_after_stage = false
		return
	if not ready:
		return
	if _fruit_ready_after_stage:
		_fruit_ready_after_stage = false
		_fruit_ready_played_cycle = true
		_fruit_delay_token += 1
		_play_fruit_ready_later(_fruit_delay_token)
		return
	if not _fruit_ready_played_cycle:
		_fruit_ready_played_cycle = true
		play(&"sfx_fruit_ready")


func _play_fruit_ready_later(token: int) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	await tree.create_timer(_fruit_ready_delay_sec, true).timeout
	if token != _fruit_delay_token or not is_inside_tree():
		return
	if not has_node("/root/GameState"):
		return
	if GameState.fruit_ready and not GameState.fruit_committed and GameState.stage_id == &"ancient":
		play(&"sfx_fruit_ready")


func reset_cycle_flags() -> void:
	_fruit_ready_played_cycle = false
	_fruit_ready_after_stage = false
	_fruit_delay_token += 1


func ensure_hub_playing() -> void:
	if _hub_suspended:
		return
	if is_hub_music_playing():
		return
	play_hub_music()


func is_hub_player_always() -> bool:
	return _music_player != null and _music_player.process_mode == Node.PROCESS_MODE_ALWAYS


func is_hub_stream_playing() -> bool:
	if _music_player == null or _music_player.stream_paused:
		return false
	return _music_player.playing


func _cue_bus(key: String) -> String:
	if not _cues.has(key):
		return ""
	var meta: Variant = _cues[key]
	if typeof(meta) != TYPE_DICTIONARY:
		return ""
	return str((meta as Dictionary).get("bus", ""))


func clear_played_log() -> void:
	_played_log.clear()


func did_play(cue_id: StringName) -> bool:
	return _played_log.has(String(cue_id))


func _on_cue_logged(cue_id: StringName) -> void:
	_played_log.append(String(cue_id))


func list_cue_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for k: Variant in _cues.keys():
		out.append(str(k))
	return out


func set_music_volume_linear(value: float) -> void:
	music_volume_linear = clampf(value, 0.0, 1.0)
	apply_volumes()
	volumes_changed.emit(music_volume_linear, sfx_volume_linear)


func set_sfx_volume_linear(value: float) -> void:
	sfx_volume_linear = clampf(value, 0.0, 1.0)
	apply_volumes()
	volumes_changed.emit(music_volume_linear, sfx_volume_linear)


func reset_volumes_to_defaults() -> void:
	music_volume_linear = 1.0
	sfx_volume_linear = 1.0
	apply_volumes()
	save_settings()
	volumes_changed.emit(music_volume_linear, sfx_volume_linear)


func apply_volumes() -> void:
	_apply_bus_volume("Music", music_volume_linear, MUSIC_BUS_DEFAULT_DB)
	for bus_name: String in SFX_BUS_NAMES:
		_apply_bus_volume(bus_name, sfx_volume_linear, SFX_BUS_DEFAULT_DB)


func _apply_bus_volume(bus_name: String, linear: float, base_db: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.001:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, base_db)
		return
	AudioServer.set_bus_mute(idx, false)
	var extra: float = _forge_music_offset_db if bus_name == "Music" else 0.0
	AudioServer.set_bus_volume_db(idx, base_db + linear_to_db(linear) + extra)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(SETTINGS_PATH)
	if err != OK:
		music_volume_linear = 1.0
		sfx_volume_linear = 1.0
		return
	music_volume_linear = clampf(float(cfg.get_value(SETTINGS_SECTION, "music_volume", 1.0)), 0.0, 1.0)
	sfx_volume_linear = clampf(float(cfg.get_value(SETTINGS_SECTION, "sfx_volume", 1.0)), 0.0, 1.0)
	if MUSIC_VOLUME_ZERO_MEANS_DEFAULT and music_volume_linear <= 0.001:
		music_volume_linear = 1.0
		save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SETTINGS_SECTION, "music_volume", music_volume_linear)
	cfg.set_value(SETTINGS_SECTION, "sfx_volume", sfx_volume_linear)
	cfg.save(SETTINGS_PATH)


func get_music_bus_volume_db() -> float:
	var idx: int = AudioServer.get_bus_index("Music")
	if idx < 0:
		return MUSIC_BUS_DEFAULT_DB
	return AudioServer.get_bus_volume_db(idx)


func get_cue_path(cue_id: StringName) -> String:
	var key: String = String(cue_id)
	if not _cues.has(key):
		return ""
	var meta: Dictionary = _cues[key]
	return str(meta.get("path", ""))
