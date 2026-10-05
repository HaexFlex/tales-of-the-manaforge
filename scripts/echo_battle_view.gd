@tool
extends CanvasLayer
class_name EchoBattleView
## Separate battle surface. Keeper stands on idle v4 east frame 0; Elaia front right.
## Flavour text box sits between the portraits and above the battle log.

const PORTRAIT: Vector2 = Vector2(384, 384)
const KEEPER_PORTRAIT_POS: Vector2 = Vector2(56, 114)
const ECHO_PORTRAIT_POS: Vector2 = Vector2(840, 114)
const COMMAND_SIZE: Vector2 = Vector2(720, 120)
const LOG_SIZE: Vector2 = Vector2(1040, 100)
const LOG_BG_POS: Vector2 = Vector2(120, 500)
const SPEECH_POS: Vector2 = Vector2(456, 256)
const SPEECH_SIZE: Vector2 = Vector2(368, 100)
const KEEPER_IDLE: String = "res://assets/art/echo/battle_keeper_idle_e.png"
const ELAIA_IDLE: String = "res://assets/art/echo/battle_elaia_idle_w.png"
const ELAIA_KEY: String = "res://assets/art/echo/battle_elaia_key_w.png"
const ELAIA_FRONT: String = ELAIA_IDLE
## Opaque 1280×720 plate. Background + Ground stay underneath until this file exists.
const CHAMBER_BG: String = "res://assets/art/echo/echo_chamber_bg.png"

var _battle: EchoBattle
@onready var _bg: ColorRect = $Background
@onready var _ground: ColorRect = $Ground
@onready var _chamber_art: TextureRect = $ChamberArt
@onready var _command_band: ColorRect = $CommandBand
@onready var _mercy_banner: ColorRect = $MercyBanner
@onready var _mercy_label: Label = $MercyLabel
@onready var _keeper_portrait: TextureRect = $KeeperPortrait
@onready var _echo_portrait: TextureRect = $EchoPortrait
@onready var _keeper_hp_fill: ColorRect = $KeeperHpFill
@onready var _echo_hp_fill: ColorRect = $EchoHpFill
@onready var _keeper_hp_label: Label = $KeeperHpText
@onready var _echo_hp_label: Label = $EchoHpText
@onready var _title: Label = $Title
@onready var _speech_bg: ColorRect = $SpeechBg
@onready var _speech: Label = $Speech
@onready var _log: Label = $Log
@onready var _strike: Button = $StrikeButton
@onready var _flee: Button = $FleeButton
@onready var _spare: Button = $SpareButton
@onready var _return_btn: Button = $ReturnButton
@onready var _arrow: Button = $ArrowToggle
var _mercy_shown: bool = false
var _waiting_return: bool = false
var _pending_outcome: String = ""
var _pending_toast: String = ""
var _pulse: float = 0.0


func _ready() -> void:
	_apply_chamber_plate()
	_apply_portraits()
	_raise_names()
	_lighten_panels()
	if Engine.is_editor_hint():
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_apply_button_copy()
	_bind()


func _apply_portraits() -> void:
	var keeper_tex: Texture2D = load(KEEPER_IDLE) as Texture2D
	if _keeper_portrait and keeper_tex:
		_keeper_portrait.texture = keeper_tex
		_keeper_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_keeper_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_keeper_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_apply_elaia_portrait()


func _elaia_holds_key() -> bool:
	if _battle == null:
		return false
	if _battle.outcome == "spare":
		return true
	if _battle.spare_window and _battle.outcome == "":
		return true
	return false


func _apply_elaia_portrait() -> void:
	if _echo_portrait == null:
		return
	var path: String = ELAIA_KEY if _elaia_holds_key() else ELAIA_IDLE
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		_echo_portrait.texture = tex
	_echo_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_echo_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_echo_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _raise_names() -> void:
	for node_name: String in ["KeeperName", "EchoName"]:
		var lbl: Label = get_node_or_null(node_name) as Label
		if lbl == null:
			continue
		lbl.offset_top = 70.0
		lbl.offset_bottom = 90.0


func _lighten_panels() -> void:
	var panels: Dictionary = {
		"SpeechBg": Color(0.16, 0.24, 0.20, 0.50),
		"LogBg": Color(0.16, 0.22, 0.18, 0.50),
		"CommandBand": Color(0.14, 0.22, 0.18, 0.52),
		"KeeperPortraitFrame": Color(0.10, 0.16, 0.14, 0.48),
		"EchoPortraitFrame": Color(0.10, 0.16, 0.14, 0.48),
	}
	for node_name: String in panels.keys():
		var rect: ColorRect = get_node_or_null(node_name) as ColorRect
		if rect:
			rect.color = panels[node_name]


func _apply_chamber_plate() -> void:
	if _chamber_art == null:
		return
	var plate: Texture2D = null
	if FileAccess.file_exists(CHAMBER_BG):
		plate = load(CHAMBER_BG) as Texture2D
	_chamber_art.texture = plate
	_chamber_art.visible = plate != null
	if _bg:
		_bg.visible = true
	if _ground:
		_ground.visible = true


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_pulse += delta
	if _echo_portrait:
		var echo_breath: float = 0.9 + 0.1 * sin(_pulse * 1.35)
		_echo_portrait.modulate = Color(echo_breath, echo_breath, echo_breath, 1.0)
	if _keeper_portrait:
		var keeper_breath: float = 0.92 + 0.08 * sin(_pulse * 1.05 + 0.8)
		_keeper_portrait.modulate = Color(keeper_breath, keeper_breath, keeper_breath, 1.0)
	if _ground and (_chamber_art == null or not _chamber_art.visible):
		var ground_shift: float = 0.96 + 0.04 * sin(_pulse * 0.7)
		_ground.modulate = Color(ground_shift, ground_shift, ground_shift, 1.0)


func is_flee_shown() -> bool:
	return _flee != null and _flee.visible


func is_spare_shown() -> bool:
	return _spare != null and _spare.visible


func is_strike_shown() -> bool:
	return _strike != null and _strike.visible


func is_arrow_toggle_shown() -> bool:
	return _arrow != null and _arrow.visible


func arrow_toggle_text() -> String:
	return _arrow.text if _arrow else ""


func speech_text() -> String:
	return _speech.text if _speech else ""


func log_text() -> String:
	return _log.text if _log else ""


func portrait_size() -> Vector2:
	return PORTRAIT


func keeper_uses_idle_texture() -> bool:
	return _keeper_portrait != null and _keeper_portrait.texture != null \
		and str(_keeper_portrait.texture.resource_path).find("battle_keeper_idle_e") >= 0


func echo_uses_elaia_texture() -> bool:
	if _echo_portrait == null or _echo_portrait.texture == null:
		return false
	var path: String = str(_echo_portrait.texture.resource_path)
	return path.find("battle_elaia_idle_w") >= 0 or path.find("battle_elaia_key_w") >= 0


func echo_uses_key_texture() -> bool:
	return _echo_portrait != null and _echo_portrait.texture != null \
		and str(_echo_portrait.texture.resource_path).find("battle_elaia_key_w") >= 0


func command_band_size() -> Vector2:
	return COMMAND_SIZE if _command_band == null else _command_band.size


func log_band_size() -> Vector2:
	return LOG_SIZE


func speech_band_size() -> Vector2:
	if _speech_bg:
		return _speech_bg.size
	return SPEECH_SIZE


func speech_top() -> float:
	return _speech.position.y if _speech else -1.0


func speech_between_portraits() -> bool:
	if _speech_bg == null or _speech == null or _log == null:
		return false
	var gap_left: float = KEEPER_PORTRAIT_POS.x + PORTRAIT.x
	var gap_right: float = ECHO_PORTRAIT_POS.x
	var box_left: float = _speech_bg.position.x
	var box_right: float = box_left + _speech_bg.size.x
	var box_top: float = _speech_bg.position.y
	var box_bottom: float = box_top + _speech_bg.size.y
	var portrait_top: float = KEEPER_PORTRAIT_POS.y
	var portrait_bottom: float = portrait_top + PORTRAIT.y
	var in_gap: bool = box_left >= gap_left - 0.5 and box_right <= gap_right + 0.5
	var in_band: bool = box_top >= portrait_top - 0.5 and box_bottom <= portrait_bottom + 0.5
	var above_log: bool = _speech.position.y < _log.position.y and box_bottom <= _log.position.y + 0.5
	return in_gap and in_band and above_log


func log_top() -> float:
	return _log.position.y if _log else -1.0


func _enemy_name() -> String:
	return EchoChamber.echo_display_name()


func _apply_button_copy() -> void:
	_strike.text = ContentStrings.get_text("battle_strike")
	_flee.text = ContentStrings.get_text("battle_flee")
	_spare.text = ContentStrings.get_text("battle_spare")
	_return_btn.text = ContentStrings.get_text("battle_return")
	_arrow.text = ContentStrings.get_text("battle_toggle_phys")
	var log_title: Label = get_node_or_null("LogTitle") as Label
	if log_title:
		log_title.text = ContentStrings.get_text("battle_log_title")
	_title.text = ContentStrings.get_text("battle_title")


func _bind() -> void:
	_battle = EchoChamber.battle
	if _battle == null:
		return
	_title.text = ContentStrings.get_text("battle_title")
	var echo_name: Label = get_node_or_null("EchoName") as Label
	var keeper_name: Label = get_node_or_null("KeeperName") as Label
	if keeper_name:
		keeper_name.text = ContentStrings.get_text("char_sheet_title")
	if echo_name:
		echo_name.text = _enemy_name()
	_refresh_bars(false)
	_refresh_log()
	_apply_elaia_portrait()
	if _battle.spare_window and _battle.outcome == "":
		_show_mercy()
		_refresh_actions()
		return
	_show_opening()
	_refresh_actions()


func _show_opening() -> void:
	if EchoChamber.reentry:
		_speech.text = ContentStrings.get_text("echo_01_return")
	elif not GameState.echo_01_narrator_heard:
		_speech.text = "%s\n%s" % [
			ContentStrings.get_text("echo_01_narrator"),
			ContentStrings.get_text("echo_01_intro"),
		]
		GameState.echo_01_narrator_heard = true
	else:
		_speech.text = ContentStrings.get_text("echo_01_intro")
	_set_mercy_visible(false)


func _show_mercy() -> void:
	_mercy_shown = true
	_speech.text = ContentStrings.get_text("echo_01_mercy")
	_set_mercy_visible(true)


func _set_mercy_visible(show: bool) -> void:
	if _mercy_banner:
		_mercy_banner.visible = show
	if _mercy_label:
		_mercy_label.visible = show
		if show:
			_mercy_label.text = ContentStrings.get_text("battle_mercy_hint", {"enemy": _enemy_name()})


func _on_strike() -> void:
	_choose("strike")


func _on_flee() -> void:
	_choose("flee")


func _on_spare() -> void:
	_choose("spare")


func _on_arrow() -> void:
	if _battle == null or _waiting_return or _battle.strike_kind != "hybrid":
		return
	GameAudio.play_ui_confirm()
	var mode: String = _battle.toggle_arrow_mode()
	GameState.arrow_mode = mode
	_refresh_actions()
	_refresh_log()


func _choose(action: String) -> void:
	if _battle == null or _waiting_return:
		return
	GameAudio.play_ui_confirm()
	var before_echo: int = _battle.echo_hp
	_battle.choose(action)
	var outcome: String = _battle.outcome
	if action == "strike" and _battle.last_keeper_damage == 0 and before_echo == _battle.echo_hp and outcome == "":
		_speech.text = ContentStrings.get_text("battle_log_fists")
	if outcome == "ko":
		EchoChamber.finish_battle("ko")
		return
	_refresh_bars(true)
	_refresh_log()
	_apply_elaia_portrait()
	if _battle.spare_window and outcome == "":
		if not _mercy_shown:
			_show_mercy()
		_refresh_actions()
		return
	if outcome == "flee" or outcome == "spare" or outcome == "defeat":
		_apply_elaia_portrait()
		_offer_return(outcome)
		return
	_speech.text = ContentStrings.get_text("battle_your_turn")
	_refresh_actions()


func _offer_return(outcome: String) -> void:
	_waiting_return = true
	_pending_outcome = outcome
	_set_mercy_visible(false)
	_pending_toast = _outcome_toast(outcome)
	_speech.text = _flavour_for_outcome(outcome)
	_strike.visible = false
	_flee.visible = false
	_spare.visible = false
	if _arrow:
		_arrow.visible = false
	_return_btn.visible = true
	if _log:
		_log.text = _pending_toast


func _flavour_for_outcome(outcome: String) -> String:
	match outcome:
		"flee":
			return ContentStrings.get_text("echo_01_flee")
		"spare":
			return ContentStrings.get_text("echo_01_spare")
		"defeat":
			return ContentStrings.get_text("echo_01_defeat")
	return ""


func _outcome_toast(outcome: String) -> String:
	var enemy: String = _enemy_name()
	var parts: PackedStringArray = PackedStringArray()
	match outcome:
		"flee":
			parts.append(ContentStrings.get_text("battle_flee_ok"))
		"spare":
			parts.append(ContentStrings.get_text("battle_spare_ok", {"enemy": enemy}))
			var shards: int = EchoChamber.snapshot_payout("spare")
			parts.append(ContentStrings.get_text("battle_shards_gain", {"amount": shards}))
			parts.append(ContentStrings.get_text("forge_key_relic_grant"))
			parts.append(ContentStrings.get_text("battle_companion_flag"))
			parts.append(ContentStrings.get_text("relic_slot_unlocked"))
		"defeat":
			parts.append(ContentStrings.get_text("battle_defeat_ok", {"enemy": enemy}))
			var shards_d: int = EchoChamber.snapshot_payout("defeat")
			parts.append(ContentStrings.get_text("battle_shards_gain", {"amount": shards_d}))
			parts.append(ContentStrings.get_text("forge_key_relic_grant"))
			parts.append(ContentStrings.get_text("relic_slot_unlocked"))
	return "\n".join(parts)


func _on_return() -> void:
	if _pending_outcome == "":
		return
	var outcome: String = _pending_outcome
	_pending_outcome = ""
	GameAudio.play_ui_confirm()
	EchoChamber.finish_battle(outcome)


func _refresh_actions() -> void:
	if _battle == null:
		return
	var actions: PackedStringArray = _battle.available_actions()
	_strike.visible = actions.has("strike")
	_flee.visible = actions.has("flee")
	_spare.visible = actions.has("spare")
	_return_btn.visible = false
	if _strike:
		_strike.text = ContentStrings.get_text("battle_strike")
	if _arrow:
		var hybrid: bool = _battle.strike_kind == "hybrid" and _battle.outcome == ""
		_arrow.visible = hybrid
		if hybrid:
			var magical: bool = _battle.arrow_mode == "magical"
			_arrow.text = ContentStrings.get_text("battle_toggle_mag" if magical else "battle_toggle_phys")
			_arrow.tooltip_text = ContentStrings.get_text("battle_mode_hint")


func _refresh_bars(flash: bool) -> void:
	if _battle == null:
		return
	var keeper_ratio: float = float(_battle.keeper_hp) / float(maxi(1, _battle.keeper_max_hp))
	var echo_ratio: float = float(_battle.echo_hp) / float(maxi(1, _battle.echo_max_hp))
	_keeper_hp_fill.size = Vector2(PORTRAIT.x * clampf(keeper_ratio, 0.0, 1.0), 14.0)
	_echo_hp_fill.size = Vector2(PORTRAIT.x * clampf(echo_ratio, 0.0, 1.0), 14.0)
	_keeper_hp_label.text = ContentStrings.get_text("battle_hp", {
		"current": _battle.keeper_hp,
		"max": _battle.keeper_max_hp,
	})
	_echo_hp_label.text = ContentStrings.get_text("battle_hp", {
		"current": _battle.echo_hp,
		"max": _battle.echo_max_hp,
	})
	if flash and _echo_portrait:
		_echo_portrait.modulate = Color(1.15, 1.15, 1.15, 1.0)


func _refresh_log() -> void:
	if _battle == null or _log == null:
		return
	var lines: PackedStringArray = _battle.log
	var start: int = maxi(0, lines.size() - 4)
	var shown: PackedStringArray = PackedStringArray()
	for i: int in range(start, lines.size()):
		shown.append(lines[i])
	_log.text = "\n".join(shown)


