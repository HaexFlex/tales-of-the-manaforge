extends Node
## Audio cue router. Buses: Music / SFX_UI / SFX_World / SFX_Progress.
## Every play sets volume_db and pitch_scale on its own voice. Progress ducks the hub bed only.

signal cue_played(cue_id: StringName)
signal cue_missing(cue_id: StringName)
signal volumes_changed(music_linear: float, sfx_linear: float)

const MANIFEST_PATH: String = "res://data/audio_cues.json"
const SETTINGS_PATH: String = "user://manaforge_settings.cfg"
const SETTINGS_SECTION: String = "audio"
const HUB_BED_BUS: String = "Music_HubBed"
const HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ: float = HubTimePhase.HUB_AMBIENCE_DAY_CUTOFF_HZ
const HUB_AMBIENCE_FILTER_NIGHT_CUTOFF_HZ: float = HubTimePhase.HUB_AMBIENCE_NIGHT_CUTOFF_HZ
const HUB_AMBIENCE_FILTER_RESONANCE: float = 0.5
const HUB_AMBIENCE_FILTER_DISCONTINUITY_SEC: float = 2.0
## Fade floor for a weather bed that is fully out. Crossfade and clear fade times live in data.
const WEATHER_BED_SILENCE_DB: float = -80.0
## Matches HubDayNightCycle.CYCLE_SEC (phase jump detection).
const HUB_DAY_NIGHT_CYCLE_SEC: float = 1200.0
const MUSIC_BUS_DEFAULT_DB: float = -9.0
const SFX_BUS_DEFAULT_DB: float = 0.0
## PLACEHOLDER — bench idle sit bed swell (see CUE_NOTES_BENCH_REST.md).
const BENCH_REST_BED_LIFT_DB: float = 2.0
const BENCH_REST_BED_TWEEN_SEC: float = 1.5
const BENCH_REST_RETRIGGER_SEC: float = 10.0
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
## Woodsong pauses the hub bed while its own loop is audible, then lets it resume.
var _bed_held_for_tune: bool = false
## A minigame mutes world music and every SFX bus. The Music bus stays up for Woodsong.
var _minigame_hold: bool = false
var _minigame_took_hub: bool = false
var _fruit_ready_played_cycle: bool = false
var _fruit_ready_after_stage: bool = false
var _fruit_delay_token: int = 0
var _played_log: PackedStringArray = PackedStringArray()
var music_volume_linear: float = 1.0
var sfx_volume_linear: float = 1.0
## Multiplies Music and SFX together. Missing from old settings files, so it stays 1.
var master_volume_linear: float = 1.0
var fullscreen_on: bool = false
## True fills the window. False keeps a pixel-perfect integer scale with bars.
var fill_screen: bool = true
## Hub camera step. 2 / 1 / 0.5, and 0.25 when the forest fills that view.
var camera_zoom: float = 1.0
var use_speedup_button: bool = false
## Hub day / dusk / night tint. World only; HUD stays neutral.
var day_night_enabled: bool = true
## First touch session showed the long-press tip. Settings file only, not the save.
var touch_hold_hint_seen: bool = false
var _forge_mix_on: bool = false
var _forge_music_offset_db: float = 0.0
var _forge_lowpass: AudioEffectLowPassFilter
var _forge_reverb: AudioEffectReverb
var _hub_bed_lowpass: AudioEffectLowPassFilter
var _hub_bed_cutoff_hz: float = HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ
var _hub_filter_prev_phase: float = -1.0
var _hub_filter_cutoff_tween: Tween
var _hub_filter_discontinuity_pending: bool = false
## < 0 = pause-menu low-pass cap off. When set, effective cutoff = min(phase, this).
var _pause_hub_bed_lowpass_cutoff_hz: float = -1.0
var last_cue_volume_db: float = 0.0
var last_cue_bus: String = ""
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
var _bench_rest_last_play_msec: int = -100000000
var _bench_rest_bed_lift_db: float = 0.0
var _bench_rest_bed_tween: Tween
var _hub_life_script: GDScript
var _weather_lowpass: AudioEffectLowPassFilter
var _weather_gain: AudioEffectAmplify
var _weather_reverb: AudioEffectReverb
var _weather_ready: bool = false
var _weather_state: String = ""
var _weather_fx: Dictionary = {}
var _weather_from: Dictionary = {}
var _weather_to: Dictionary = {}
var _weather_left: float = 0.0
var _weather_span: float = 0.0
var _bed_players: Dictionary = {}
var _bed_vol: Dictionary = {}
var _bed_from: Dictionary = {}
var _bed_to: Dictionary = {}
var _bed_left: float = 0.0
var _bed_span: float = 0.0
var _beds_held: bool = false
var _chore_cue_at: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_load_manifest()
	_music_player = _make_player("MusicPlayer", HUB_BED_BUS)
	set_process(true)
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
	if DisplayServer.get_name() != "headless":
		var win: Window = get_window()
		if win != null and not win.size_changed.is_connected(_on_window_resized):
			win.size_changed.connect(_on_window_resized)
		Ui540.apply_integer_viewport(win)
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
	_add_bus_if_missing(HUB_BED_BUS)
	_add_bus_if_missing("SFX_UI")
	_add_bus_if_missing("SFX_World")
	_add_bus_if_missing("SFX_Progress")
	var hub_bed_idx: int = AudioServer.get_bus_index(HUB_BED_BUS)
	if hub_bed_idx >= 0:
		AudioServer.set_bus_send(hub_bed_idx, "Music")
		if _hub_bed_lowpass == null:
			_hub_bed_lowpass = AudioEffectLowPassFilter.new()
			_hub_bed_lowpass.db = AudioEffectFilter.FILTER_12DB
			_hub_bed_lowpass.cutoff_hz = HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ
			_hub_bed_lowpass.resonance = HUB_AMBIENCE_FILTER_RESONANCE
			_hub_bed_cutoff_hz = HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ
			AudioServer.add_bus_effect(hub_bed_idx, _hub_bed_lowpass)
		_ensure_weather_bus_effects(hub_bed_idx)
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


func gather_offset_db() -> float:
	return _gather_offset_db


func music_bed_volume_db() -> float:
	if _music_player == null:
		return 0.0
	return _music_player.volume_db


func bench_rest_bed_lift_db() -> float:
	return _bench_rest_bed_lift_db


func reset_bench_rest_bed_lift() -> void:
	if _bench_rest_bed_tween != null and _bench_rest_bed_tween.is_valid():
		_bench_rest_bed_tween.kill()
	_apply_bench_rest_bed_lift(0.0)


func on_keeper_bench_sat() -> void:
	if DisplayServer.get_name() == "headless":
		_apply_bench_rest_bed_lift(BENCH_REST_BED_LIFT_DB)
	var now: int = Time.get_ticks_msec()
	if now - _bench_rest_last_play_msec >= int(BENCH_REST_RETRIGGER_SEC * 1000.0):
		play(&"sfx_bench_rest", 0.0, 1.0)
		_bench_rest_last_play_msec = now
	if DisplayServer.get_name() == "headless":
		return
	_tween_bench_rest_bed(BENCH_REST_BED_LIFT_DB)


func on_keeper_bench_stood() -> void:
	if DisplayServer.get_name() == "headless":
		reset_bench_rest_bed_lift()
	else:
		_tween_bench_rest_bed(0.0)


func _tween_bench_rest_bed(target_lift_db: float) -> void:
	if _bench_rest_bed_tween != null and _bench_rest_bed_tween.is_valid():
		_bench_rest_bed_tween.kill()
	if DisplayServer.get_name() == "headless":
		_apply_bench_rest_bed_lift(target_lift_db)
		return
	var span: float = maxf(BENCH_REST_BED_TWEEN_SEC, 0.0)
	if span <= 0.0001 or is_equal_approx(_bench_rest_bed_lift_db, target_lift_db):
		_apply_bench_rest_bed_lift(target_lift_db)
		return
	_bench_rest_bed_tween = create_tween()
	_bench_rest_bed_tween.tween_method(_apply_bench_rest_bed_lift, _bench_rest_bed_lift_db, target_lift_db, span)


func _apply_bench_rest_bed_lift(value: float) -> void:
	_bench_rest_bed_lift_db = value
	_sync_music_player_volume()


func _sync_music_player_volume() -> void:
	if _music_player:
		_music_player.volume_db = _duck_db + _bench_rest_bed_lift_db


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


func hold_bed_for_tune() -> void:
	if _music_player == null or not _music_player.playing or _music_player.stream_paused:
		return
	_music_player.stream_paused = true
	_bed_held_for_tune = true


func release_bed_for_tune() -> void:
	if not _bed_held_for_tune:
		return
	_bed_held_for_tune = false
	if _hub_suspended:
		return
	if _music_player and _music_player.stream_paused:
		_music_player.stream_paused = false


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


func hold_world_for_minigame() -> void:
	if _minigame_hold:
		return
	_minigame_hold = true
	_minigame_took_hub = not _hub_suspended
	if _minigame_took_hub:
		suspend_hub_for_battle()
	for voice: AudioStreamPlayer in _sfx_pool:
		if voice.playing:
			voice.stop()
	for voice: AudioStreamPlayer in _progress_pool:
		if voice.playing:
			voice.stop()
	_mute_minigame_sfx()


func release_world_after_minigame() -> void:
	if not _minigame_hold:
		return
	_minigame_hold = false
	apply_volumes()
	if _minigame_took_hub:
		_minigame_took_hub = false
		resume_hub_after_battle()


func minigame_audio_held() -> bool:
	return _minigame_hold


func _mute_minigame_sfx() -> void:
	for bus_name: String in SFX_BUS_NAMES:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			AudioServer.set_bus_mute(idx, true)


func play(cue_id: StringName, offset_db: float = 0.0, pitch: float = 1.0) -> void:
	if _minigame_hold:
		return
	var key: String = String(cue_id)
	var bus: String = _cue_bus(key)
	var base_db: float = 0.0
	if _cues.has(key) and typeof(_cues[key]) == TYPE_DICTIONARY:
		base_db = float((_cues[key] as Dictionary).get("volume_db", 0.0))
	var effective_db: float = base_db + offset_db
	if _hub_suspended and bus == "Music" and key != "mus_battle_forest":
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
			var bed_bus: String = bus
			if key == "mus_hub_forest":
				hub_stream = _resolve_hub_stream(path)
				bed_bus = HUB_BED_BUS
			elif path != "" and ResourceLoader.exists(path):
				hub_stream = load(path) as AudioStream
			if hub_stream == null:
				cue_missing.emit(cue_id)
				cue_played.emit(cue_id)
				return
			_play_hub_stream(hub_stream, bed_bus)
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
		last_cue_bus = bus
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
	_sync_music_player_volume()


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
		player.bus = bus
		_sync_music_player_volume()
		return
	_force_stream_loop(stream)
	_ensure_music_bus_audible()
	player.stream = stream
	player.bus = bus
	_sync_music_player_volume()
	player.pitch_scale = 1.0
	player.play()
	_hub_playing = true


func hub_ambience_filter_cutoff_hz() -> float:
	return _hub_bed_cutoff_hz


## Optional pause-menu low-pass cap on the hub bed (one filter on Music_HubBed). hz < 0 clears.
func set_pause_hub_bed_lowpass_cutoff_hz(hz: float) -> void:
	var prev: float = _pause_hub_bed_lowpass_cutoff_hz
	_pause_hub_bed_lowpass_cutoff_hz = hz
	if not is_equal_approx(prev, hz):
		_request_hub_filter_discontinuity_tween()


func pause_hub_bed_lowpass_cutoff_hz() -> float:
	return _pause_hub_bed_lowpass_cutoff_hz


func _process(delta: float) -> void:
	_refresh_hub_ambience_lowpass(delta)
	advance_weather_audio(delta)


func _phase_hub_bed_cutoff_hz() -> float:
	if not day_night_enabled:
		return HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ
	return HubTimePhase.hub_ambience_filter_cutoff_hz(HubTimePhase.sample_phase01())


func _pause_hub_bed_lowpass_cap_hz() -> float:
	if _pause_hub_bed_lowpass_cutoff_hz < 0.0:
		return HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ
	return _pause_hub_bed_lowpass_cutoff_hz


func _effective_hub_bed_cutoff_hz(phase_hz: float) -> float:
	return minf(phase_hz, _pause_hub_bed_lowpass_cap_hz())


func _apply_hub_bed_cutoff_hz(cutoff_hz: float) -> void:
	_hub_bed_cutoff_hz = cutoff_hz
	if _hub_bed_lowpass != null:
		_hub_bed_lowpass.cutoff_hz = cutoff_hz


func _request_hub_filter_discontinuity_tween() -> void:
	_hub_filter_discontinuity_pending = true


func _hub_filter_phase_discontinuity(phase: float, delta: float) -> bool:
	if _hub_filter_prev_phase < 0.0:
		return false
	var delta_phase: float = absf(phase - _hub_filter_prev_phase)
	if delta_phase > 0.5:
		delta_phase = 1.0 - delta_phase
	var max_step: float = delta / HUB_DAY_NIGHT_CYCLE_SEC
	return delta_phase > max_step * 3.0 + 0.012


func _tween_hub_bed_cutoff_to(target_hz: float, seconds: float) -> void:
	if _hub_filter_cutoff_tween != null and _hub_filter_cutoff_tween.is_valid():
		_hub_filter_cutoff_tween.kill()
	var from_hz: float = _hub_bed_cutoff_hz
	var from_log: float = log(from_hz)
	var to_log: float = log(target_hz)
	var span: float = maxf(seconds, HUB_AMBIENCE_FILTER_DISCONTINUITY_SEC)
	if span <= 0.0001 or is_equal_approx(from_hz, target_hz):
		_apply_hub_bed_cutoff_hz(target_hz)
		return
	_hub_filter_cutoff_tween = create_tween()
	_hub_filter_cutoff_tween.tween_method(_apply_hub_bed_cutoff_log, from_log, to_log, span)


func _apply_hub_bed_cutoff_log(log_hz: float) -> void:
	_apply_hub_bed_cutoff_hz(exp(log_hz))


func _refresh_hub_ambience_lowpass(delta: float) -> void:
	if _hub_bed_lowpass == null:
		return
	var phase: float = HubTimePhase.sample_phase01()
	var target_hz: float = _effective_hub_bed_cutoff_hz(_phase_hub_bed_cutoff_hz())
	var tweening: bool = _hub_filter_cutoff_tween != null and _hub_filter_cutoff_tween.is_valid()
	if _hub_filter_discontinuity_pending and not tweening:
		_hub_filter_discontinuity_pending = false
		_tween_hub_bed_cutoff_to(target_hz, HUB_AMBIENCE_FILTER_DISCONTINUITY_SEC)
		_hub_filter_prev_phase = phase
		return
	if not tweening and _hub_filter_phase_discontinuity(phase, delta):
		_tween_hub_bed_cutoff_to(target_hz, HUB_AMBIENCE_FILTER_DISCONTINUITY_SEC)
		_hub_filter_prev_phase = phase
		return
	if tweening:
		_hub_filter_prev_phase = phase
		return
	_apply_hub_bed_cutoff_hz(target_hz)
	_hub_filter_prev_phase = phase


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
	var chime: StringName = _mana_chime_cue_for_stage()
	if chime != &"":
		play(chime, 0.0, 1.0)


func _mana_chime_cue_for_stage() -> StringName:
	if not has_node("/root/GameState"):
		return &""
	var stage_num: int = GameState.get_stage_index() + 1
	match stage_num:
		1:
			return &"sfx_mana_chime_1"
		2:
			return &"sfx_mana_chime_2"
		3:
			return &"sfx_mana_chime_3"
		_:
			return &"sfx_mana_chime_4"


func _on_keeper_harvested(resource_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	play_gather(resource_id)


func play_tree_water_ok() -> void:
	play(&"sfx_tree_water")


func play_water_pulse() -> void:
	## Cue id stays sfx_water_pulse. The file is the soft splash. Offset is -18 (about half as loud as -12).
	play_quiet(&"sfx_water_pulse", -18.0)


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
	play(&"sfx_ascend_breath")
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
	## Wisps bank harvest silently; assign/deny/unassign cues stay.
	pass


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


func busy_voices(bus: String) -> int:
	var count: int = 0
	for voice: AudioStreamPlayer in _sfx_pool:
		if voice.playing and voice.bus == bus:
			count += 1
	return count


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


func set_master_volume_linear(value: float) -> void:
	master_volume_linear = clampf(value, 0.0, 1.0)
	apply_volumes()
	volumes_changed.emit(music_volume_linear, sfx_volume_linear)


func set_fullscreen(on: bool) -> void:
	fullscreen_on = on
	apply_display()
	save_settings()


func set_fill_screen(fill: bool) -> void:
	fill_screen = fill
	apply_display()
	save_settings()


func reset_volumes_to_defaults() -> void:
	music_volume_linear = 1.0
	sfx_volume_linear = 1.0
	master_volume_linear = 1.0
	apply_volumes()
	save_settings()
	volumes_changed.emit(music_volume_linear, sfx_volume_linear)


func apply_volumes() -> void:
	var music_lin: float = clampf(music_volume_linear * master_volume_linear, 0.0, 1.0)
	var sfx_lin: float = clampf(sfx_volume_linear * master_volume_linear, 0.0, 1.0)
	_apply_bus_volume("Music", music_lin, MUSIC_BUS_DEFAULT_DB)
	for bus_name: String in SFX_BUS_NAMES:
		_apply_bus_volume(bus_name, sfx_lin, SFX_BUS_DEFAULT_DB)
	if _minigame_hold:
		_mute_minigame_sfx()


func _on_window_resized() -> void:
	Ui540.apply_integer_viewport(get_window())


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	var win: Window = get_window() if is_inside_tree() else null
	if win == null:
		return
	## Black bars are gone. Integer scale, logical size = window / scale, on every screen.
	Ui540.apply_integer_viewport(win)


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
		master_volume_linear = 1.0
		return
	music_volume_linear = clampf(float(cfg.get_value(SETTINGS_SECTION, "music_volume", 1.0)), 0.0, 1.0)
	sfx_volume_linear = clampf(float(cfg.get_value(SETTINGS_SECTION, "sfx_volume", 1.0)), 0.0, 1.0)
	master_volume_linear = clampf(float(cfg.get_value(SETTINGS_SECTION, "master_volume", 1.0)), 0.0, 1.0)
	use_speedup_button = bool(cfg.get_value(SETTINGS_SECTION, "use_speedup_button", false))
	fullscreen_on = bool(cfg.get_value("display", "fullscreen", false))
	fill_screen = bool(cfg.get_value("display", "fill_screen", true))
	camera_zoom = float(cfg.get_value("display", "camera_zoom", 1.0))
	touch_hold_hint_seen = bool(cfg.get_value("touch", "hold_hint_seen", false))
	day_night_enabled = bool(cfg.get_value("display", "day_night", true))
	_request_hub_filter_discontinuity_tween()
	apply_display()
	if MUSIC_VOLUME_ZERO_MEANS_DEFAULT and music_volume_linear <= 0.001:
		music_volume_linear = 1.0
		save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SETTINGS_SECTION, "music_volume", music_volume_linear)
	cfg.set_value(SETTINGS_SECTION, "sfx_volume", sfx_volume_linear)
	cfg.set_value(SETTINGS_SECTION, "master_volume", master_volume_linear)
	cfg.set_value(SETTINGS_SECTION, "use_speedup_button", use_speedup_button)
	cfg.set_value("display", "fullscreen", fullscreen_on)
	cfg.set_value("display", "fill_screen", fill_screen)
	cfg.set_value("display", "camera_zoom", camera_zoom)
	cfg.set_value("display", "day_night", day_night_enabled)
	cfg.set_value("touch", "hold_hint_seen", touch_hold_hint_seen)
	cfg.save(SETTINGS_PATH)


func mark_touch_hold_hint_seen() -> void:
	touch_hold_hint_seen = true
	save_settings()


func get_camera_zoom() -> float:
	return camera_zoom


func set_camera_zoom(z: float) -> void:
	camera_zoom = z
	save_settings()


func set_use_speedup_button(enabled: bool) -> void:
	use_speedup_button = enabled
	if not enabled:
		Engine.time_scale = 1.0
	save_settings()


func set_day_night_enabled(enabled: bool) -> void:
	day_night_enabled = enabled
	_request_hub_filter_discontinuity_tween()
	save_settings()


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


func _hub_life() -> GDScript:
	if _hub_life_script == null:
		var script_name := "hub_life.gd"
		_hub_life_script = load("res://scripts/%s" % script_name) as GDScript
	return _hub_life_script


func _ensure_weather_bus_effects(bus_idx: int) -> void:
	if _weather_lowpass != null:
		return
	_weather_lowpass = AudioEffectLowPassFilter.new()
	_weather_lowpass.cutoff_hz = HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ
	_weather_gain = AudioEffectAmplify.new()
	_weather_gain.volume_db = 0.0
	_weather_reverb = AudioEffectReverb.new()
	_weather_reverb.dry = 1.0
	_weather_reverb.wet = 0.0
	_weather_reverb.room_size = 0.0
	_weather_reverb.damping = 0.0
	AudioServer.add_bus_effect(bus_idx, _weather_lowpass)
	AudioServer.add_bus_effect(bus_idx, _weather_gain)
	AudioServer.add_bus_effect(bus_idx, _weather_reverb)
	_set_weather_effect_enabled(_weather_lowpass, false)
	_set_weather_effect_enabled(_weather_gain, false)
	_set_weather_effect_enabled(_weather_reverb, false)


func _set_weather_effect_enabled(effect: AudioEffect, enabled: bool) -> void:
	var bus_idx: int = AudioServer.get_bus_index(HUB_BED_BUS)
	if bus_idx < 0 or effect == null:
		return
	for i: int in range(AudioServer.get_bus_effect_count(bus_idx)):
		if AudioServer.get_bus_effect(bus_idx, i) == effect:
			AudioServer.set_bus_effect_enabled(bus_idx, i, enabled)
			return


func _weather_effect_enabled(effect: AudioEffect) -> bool:
	var bus_idx: int = AudioServer.get_bus_index(HUB_BED_BUS)
	if bus_idx < 0 or effect == null:
		return false
	for i: int in range(AudioServer.get_bus_effect_count(bus_idx)):
		if AudioServer.get_bus_effect(bus_idx, i) == effect:
			return AudioServer.is_bus_effect_enabled(bus_idx, i)
	return false


func weather_hub_bus_params() -> Dictionary:
	var gain_on: bool = _weather_effect_enabled(_weather_gain)
	var low_on: bool = _weather_effect_enabled(_weather_lowpass)
	var rev_on: bool = _weather_effect_enabled(_weather_reverb)
	return {
		"lowpass_enabled": low_on,
		"lowpass_hz": _weather_lowpass.cutoff_hz if _weather_lowpass != null and low_on else 0.0,
		"gain_enabled": gain_on,
		"gain_db": _weather_gain.volume_db if _weather_gain != null and gain_on else 0.0,
		"reverb_enabled": rev_on,
		"reverb_room": _weather_reverb.room_size if _weather_reverb != null and rev_on else 0.0,
		"reverb_wet": _weather_reverb.wet if _weather_reverb != null and rev_on else 0.0,
		"reverb_damp": _weather_reverb.damping if _weather_reverb != null and rev_on else 0.0,
	}


func weather_bed_volume_db(cue_id: String) -> float:
	var player: AudioStreamPlayer = _bed_players.get(cue_id, null)
	if player == null or not player.playing:
		return WEATHER_BED_SILENCE_DB
	return player.volume_db


func weather_bed_playing(cue_id: String) -> bool:
	return weather_bed_volume_db(cue_id) > WEATHER_BED_SILENCE_DB + 0.5


func weather_bed_bus(cue_id: String) -> String:
	var player: AudioStreamPlayer = _bed_players.get(cue_id, null)
	if player == null:
		return ""
	return player.bus


func weather_bed_silence_db() -> float:
	return WEATHER_BED_SILENCE_DB


func advance_weather_audio(seconds: float) -> void:
	var state: String = _live_weather_state()
	var held: bool = _weather_beds_held()
	if not _weather_ready:
		_weather_ready = true
		_weather_state = state
		_beds_held = held
		_snap_weather(state, held)
		return
	if state != _weather_state or held != _beds_held:
		var from_state: String = _weather_state
		_weather_state = state
		_beds_held = held
		_begin_weather_fade(from_state, state, held)
	_step_weather_fade(maxf(seconds, 0.0))


func play_chore_payout(companion_id: String, node_id: String) -> bool:
	companion_id = CompanionRoster.canonical_id(companion_id)
	var script: GDScript = _hub_life()
	if script == null:
		return false
	var spec_v: Variant = script.call("chore_payout_audio", node_id)
	var spec: Dictionary = spec_v if typeof(spec_v) == TYPE_DICTIONARY else {}
	var cue: String = str(spec.get("cue", ""))
	if cue == "":
		return false
	if _minigame_hold or _held_while_fruit_committed(cue, str(spec.get("bus", "SFX_World"))):
		return false
	var gap_ms: int = int(round(float(spec.get("gap_sec", 2.0)) * 1000.0))
	var now: int = Time.get_ticks_msec()
	var last: int = int(_chore_cue_at.get(companion_id, -100000000))
	if now - last < gap_ms:
		return false
	_chore_cue_at[companion_id] = now
	play(StringName(cue), float(spec.get("offset_db", -6.0)), 1.0)
	return true


func age_chore_cue(companion_id: String, msec: int) -> void:
	_chore_cue_at[CompanionRoster.canonical_id(companion_id)] = Time.get_ticks_msec() - msec


func clear_chore_cues() -> void:
	_chore_cue_at.clear()


func _live_weather_state() -> String:
	var script: GDScript = _hub_life()
	if script == null:
		return "clear"
	return str(script.call("weather_state_name"))


func _weather_audio_block() -> Dictionary:
	var script: GDScript = _hub_life()
	if script == null:
		return {}
	var raw: Variant = script.call("weather_audio")
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


func _weather_fade_sec() -> float:
	return maxf(float(_weather_audio_block().get("crossfade_sec", 2.0)), 0.0)


func _bed_fade_in_sec() -> float:
	return maxf(float(_weather_audio_block().get("bed_fade_in_sec", 3.0)), 0.0)


func _bed_fade_out_sec() -> float:
	return maxf(float(_weather_audio_block().get("bed_fade_out_sec", 4.0)), 0.0)


func _bed_fade_sec(from_state: String, to_state: String, held: bool) -> float:
	if held:
		return _weather_fade_sec()
	var from_active: bool = _bed_cue_for(from_state) != ""
	var to_active: bool = _bed_cue_for(to_state) != "" if not held else false
	if not from_active and to_active:
		return _bed_fade_in_sec()
	if from_active and not to_active:
		return _bed_fade_out_sec()
	return _weather_fade_sec()


func _weather_beds_held() -> bool:
	if _minigame_hold:
		return true
	if has_node("/root/GameState") and GameState.fruit_committed:
		return true
	return false


func _fx_row(state: String) -> Dictionary:
	var table_v: Variant = _weather_audio_block().get("hub_bed", {})
	var table: Dictionary = table_v if typeof(table_v) == TYPE_DICTIONARY else {}
	var row_v: Variant = table.get(state, {})
	var row: Dictionary = row_v if typeof(row_v) == TYPE_DICTIONARY else {}
	var low: float = float(row.get("lowpass_hz", 0.0))
	var gain: float = float(row.get("gain_db", 0.0))
	var room: float = float(row.get("reverb_room", 0.0))
	var wet: float = float(row.get("reverb_wet", 0.0))
	var damp: float = float(row.get("reverb_damp", 0.0))
	var use_low: bool = low > 0.0
	var use_gain: bool = not is_equal_approx(gain, 0.0)
	var use_rev: bool = wet > 0.0 or room > 0.0 or damp > 0.0
	return {
		"lowpass_hz": low if use_low else HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ,
		"gain_db": gain,
		"reverb_room": room,
		"reverb_wet": wet,
		"reverb_damp": damp,
		"use_lowpass": use_low,
		"use_gain": use_gain,
		"use_reverb": use_rev,
	}


func _neutral_fx() -> Dictionary:
	return _fx_row("clear")


func _bed_level_db(cue_id: String) -> float:
	if _cues.has(cue_id) and typeof(_cues[cue_id]) == TYPE_DICTIONARY:
		return float((_cues[cue_id] as Dictionary).get("volume_db", 0.0))
	return 0.0


func _bed_ids() -> PackedStringArray:
	var beds_v: Variant = _weather_audio_block().get("beds", {})
	var beds: Dictionary = beds_v if typeof(beds_v) == TYPE_DICTIONARY else {}
	var out := PackedStringArray()
	for key_v: Variant in beds.values():
		var cue_id: String = str(key_v)
		if cue_id != "" and not out.has(cue_id):
			out.append(cue_id)
	return out


func _bed_cue_for(state: String) -> String:
	var beds_v: Variant = _weather_audio_block().get("beds", {})
	var beds: Dictionary = beds_v if typeof(beds_v) == TYPE_DICTIONARY else {}
	return str(beds.get(state, ""))


func _target_bed_volumes(state: String, held: bool) -> Dictionary:
	var active: String = "" if held else _bed_cue_for(state)
	var out: Dictionary = {}
	for cue_id: String in _bed_ids():
		out[cue_id] = _bed_level_db(cue_id) if cue_id == active else WEATHER_BED_SILENCE_DB
	return out


func _snap_weather(state: String, held: bool) -> void:
	_weather_fx = _fx_row(state)
	_weather_from = _weather_fx.duplicate()
	_weather_to = _weather_fx.duplicate()
	_weather_left = 0.0
	_weather_span = 0.0
	_apply_fx(_weather_fx)
	_bed_vol = _target_bed_volumes(state, held)
	_bed_from = _bed_vol.duplicate()
	_bed_to = _bed_vol.duplicate()
	_bed_left = 0.0
	_bed_span = 0.0
	_apply_bed_volumes(_bed_vol)


func _begin_weather_fade(from_state: String, to_state: String, held: bool) -> void:
	if _weather_fx.is_empty():
		_weather_fx = _neutral_fx()
	_weather_from = _weather_fx.duplicate()
	_weather_to = _fx_row(to_state)
	_weather_span = _weather_fade_sec()
	_weather_left = _weather_span
	if _bed_vol.is_empty():
		for cue_id: String in _bed_ids():
			_bed_vol[cue_id] = WEATHER_BED_SILENCE_DB
	_bed_from = _bed_vol.duplicate()
	_bed_to = _target_bed_volumes(to_state, held)
	_bed_span = _bed_fade_sec(from_state, to_state, held)
	_bed_left = _bed_span


func _step_weather_fade(seconds: float) -> void:
	if _weather_span <= 0.0001:
		_weather_fx = _weather_to.duplicate() if not _weather_to.is_empty() else _neutral_fx()
		_apply_fx(_weather_fx)
	else:
		_weather_left = maxf(0.0, _weather_left - seconds)
		var t: float = 1.0 if _weather_span <= 0.0 else clampf(1.0 - (_weather_left / _weather_span), 0.0, 1.0)
		_weather_fx = _lerp_fx(_weather_from, _weather_to, t)
		_apply_fx(_weather_fx)
	if _bed_span <= 0.0001:
		_bed_vol = _bed_to.duplicate()
	else:
		_bed_left = maxf(0.0, _bed_left - seconds)
		var bed_t: float = clampf(1.0 - (_bed_left / _bed_span), 0.0, 1.0)
		_bed_vol = _lerp_beds(_bed_from, _bed_to, bed_t)
	_apply_bed_volumes(_bed_vol)


func _lerp_fx(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var done: bool = t >= 0.999
	return {
		"lowpass_hz": lerpf(float(a.get("lowpass_hz", HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ)), float(b.get("lowpass_hz", HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ)), t),
		"gain_db": lerpf(float(a.get("gain_db", 0.0)), float(b.get("gain_db", 0.0)), t),
		"reverb_room": lerpf(float(a.get("reverb_room", 0.0)), float(b.get("reverb_room", 0.0)), t),
		"reverb_wet": lerpf(float(a.get("reverb_wet", 0.0)), float(b.get("reverb_wet", 0.0)), t),
		"reverb_damp": lerpf(float(a.get("reverb_damp", 0.0)), float(b.get("reverb_damp", 0.0)), t),
		"use_lowpass": bool(b.get("use_lowpass", false)) if done else (bool(a.get("use_lowpass", false)) or bool(b.get("use_lowpass", false))),
		"use_gain": bool(b.get("use_gain", false)) if done else (bool(a.get("use_gain", false)) or bool(b.get("use_gain", false))),
		"use_reverb": bool(b.get("use_reverb", false)) if done else (bool(a.get("use_reverb", false)) or bool(b.get("use_reverb", false))),
	}


func _lerp_beds(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out: Dictionary = {}
	var keys: Dictionary = {}
	for key_v: Variant in a.keys():
		keys[str(key_v)] = true
	for key_v2: Variant in b.keys():
		keys[str(key_v2)] = true
	for key_v3: Variant in keys.keys():
		var cue_id: String = str(key_v3)
		out[cue_id] = lerpf(float(a.get(cue_id, WEATHER_BED_SILENCE_DB)), float(b.get(cue_id, WEATHER_BED_SILENCE_DB)), t)
	return out


func _apply_fx(fx: Dictionary) -> void:
	if _weather_lowpass == null:
		return
	_weather_lowpass.cutoff_hz = float(fx.get("lowpass_hz", HUB_AMBIENCE_FILTER_DAY_CUTOFF_HZ))
	_weather_gain.volume_db = float(fx.get("gain_db", 0.0))
	_weather_reverb.room_size = float(fx.get("reverb_room", 0.0))
	_weather_reverb.wet = float(fx.get("reverb_wet", 0.0))
	_weather_reverb.damping = float(fx.get("reverb_damp", 0.0))
	_weather_reverb.dry = 1.0
	_set_weather_effect_enabled(_weather_lowpass, bool(fx.get("use_lowpass", false)))
	_set_weather_effect_enabled(_weather_gain, bool(fx.get("use_gain", false)))
	_set_weather_effect_enabled(_weather_reverb, bool(fx.get("use_reverb", false)))


func _apply_bed_volumes(volumes: Dictionary) -> void:
	for key_v: Variant in volumes.keys():
		var cue_id: String = str(key_v)
		var db: float = float(volumes[cue_id])
		if db <= WEATHER_BED_SILENCE_DB + 0.05:
			_stop_bed(cue_id)
		else:
			_play_bed(cue_id, db)


func _play_bed(cue_id: String, db: float) -> void:
	var player: AudioStreamPlayer = _ensure_bed_player(cue_id)
	if player == null:
		return
	player.volume_db = db
	if not player.playing:
		player.play()


func _stop_bed(cue_id: String) -> void:
	var player: AudioStreamPlayer = _bed_players.get(cue_id, null)
	if player == null:
		return
	player.volume_db = WEATHER_BED_SILENCE_DB
	if player.playing:
		player.stop()


func _ensure_bed_player(cue_id: String) -> AudioStreamPlayer:
	var existing: AudioStreamPlayer = _bed_players.get(cue_id, null)
	if existing != null:
		return existing
	if not _cues.has(cue_id) or typeof(_cues[cue_id]) != TYPE_DICTIONARY:
		return null
	var meta: Dictionary = _cues[cue_id]
	var path: String = str(meta.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		cue_missing.emit(StringName(cue_id))
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		cue_missing.emit(StringName(cue_id))
		return null
	_force_stream_loop(stream)
	var player := AudioStreamPlayer.new()
	player.name = "WeatherBed_%s" % cue_id
	player.bus = str(meta.get("bus", "SFX_World"))
	player.stream = stream
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	_bed_players[cue_id] = player
	return player
