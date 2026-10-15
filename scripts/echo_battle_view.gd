@tool
extends CanvasLayer
class_name EchoBattleView
## Separate battle surface. Keeper stands on idle v4 east frame 0; Elaia front right.
## Flavour text box sits between the portraits and above the battle log.

const PORTRAIT: Vector2 = Vector2(EchoTheme.SPRITE, EchoTheme.SPRITE)
const KEEPER_PORTRAIT_POS: Vector2 = Vector2(EchoTheme.KEEPER_CX - EchoTheme.SPRITE * 0.5, EchoTheme.SPRITE_Y)
const ECHO_PORTRAIT_POS: Vector2 = Vector2(EchoTheme.ECHO_CX - EchoTheme.SPRITE * 0.5, EchoTheme.SPRITE_Y)
const COMMAND_SIZE: Vector2 = Vector2(540, 90)
const LOG_SIZE: Vector2 = Vector2(780, 75)
const LOG_BG_POS: Vector2 = Vector2(90, 375)
const SPEECH_POS: Vector2 = Vector2(342, 192)
const SPEECH_SIZE: Vector2 = Vector2(276, 75)
const CHAMBER_CROP: Rect2 = EchoTheme.CROP_16
const KEEPER_IDLE: String = "res://assets/art/echo/battle_keeper_idle_e.png"
const ELAIA_IDLE: String = "res://assets/art/echo/battle_elaia_idle_w.png"
const ELAIA_KEY: String = "res://assets/art/echo/battle_elaia_key_w.png"
const ELAIA_FRONT: String = ELAIA_IDLE
## Opaque 1280×720 plate (centre-cropped to 960×540). Background + Ground stay underneath until this file exists.
const CHAMBER_BG: String = EchoTheme.PLATE

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
var _phase: String = "chamber"
var _chamber_panel: Panel = null
var _leave_btn: Button = null
var _face_btn: Button = null
var _close_btn: Button = null
var _title_plate: Panel = null
var _echo_ghost: TextureRect = null
var _mercy_shown: bool = false
var _waiting_return: bool = false
var _pending_outcome: String = ""
var _pending_toast: String = ""
var _pulse: float = 0.0
var _name_tag_root: Node = null


func _exit_tree() -> void:
	_restore_fled_names()


func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		_name_tag_root = tree.root
	_apply_chamber_plate()
	_apply_540_layout()
	_apply_portraits()
	_raise_names()
	_build_chamber_chrome()
	_hide_legacy_frames()
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


func _is_bramble() -> bool:
	return EchoChamber.battle_context == "echo2"


func _echo_line(suffix: String) -> String:
	var prefix: String = "echo_02_" if _is_bramble() else "echo_01_"
	return ContentStrings.get_text(prefix + suffix)


func _apply_elaia_portrait() -> void:
	if _echo_portrait == null:
		return
	if _is_bramble() and _battle != null and _battle.foe_art_path != "":
		var foe_tex: Texture2D = load(_battle.foe_art_path) as Texture2D
		if foe_tex:
			_echo_portrait.texture = foe_tex
		_echo_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_echo_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_echo_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_place_echo_ghost()
		return
	var path: String = ELAIA_KEY if _elaia_holds_key() else ELAIA_IDLE
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		_echo_portrait.texture = tex
	_echo_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_echo_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_echo_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place_echo_ghost()


func _raise_names() -> void:
	var ox: float = EchoTheme.shift()
	var keeper_name: Label = get_node_or_null("KeeperName") as Label
	var echo_name: Label = get_node_or_null("EchoName") as Label
	if keeper_name:
		keeper_name.position = Vector2(ox + EchoTheme.KEEPER_CX - 80.0, 90)
		keeper_name.size = Vector2(160, 22)
		keeper_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		EchoTheme.style_body(keeper_name, false)
	if echo_name:
		echo_name.position = Vector2(ox + EchoTheme.ECHO_CX - 90.0, 90)
		echo_name.size = Vector2(180, 22)
		echo_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		EchoTheme.style_title(echo_name, false)


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


func _apply_540_layout() -> void:
	var ox: float = EchoTheme.shift()
	if _keeper_portrait:
		_keeper_portrait.position = KEEPER_PORTRAIT_POS + Vector2(ox, 0)
		_keeper_portrait.size = PORTRAIT
	if _echo_portrait:
		_echo_portrait.position = ECHO_PORTRAIT_POS + Vector2(ox, 0)
		_echo_portrait.size = PORTRAIT
	_place_echo_ghost()
	_place_ripples()
	if _speech_bg:
		_speech_bg.position = SPEECH_POS + Vector2(ox, 0)
		_speech_bg.size = SPEECH_SIZE
	if _speech:
		_speech.position = SPEECH_POS + Vector2(ox + 8, 4)
		_speech.size = SPEECH_SIZE - Vector2(16, 8)
	if _command_band:
		var band_x: float = ox + (960.0 - COMMAND_SIZE.x) * 0.5
		_command_band.position = Vector2(band_x, 450.0)
		_command_band.size = COMMAND_SIZE
	var log_bg: ColorRect = get_node_or_null("LogBg") as ColorRect
	if log_bg:
		log_bg.position = LOG_BG_POS + Vector2(ox, 0)
		log_bg.size = LOG_SIZE
	if _log:
		_log.position = LOG_BG_POS + Vector2(ox + 12, 20)
		_log.size = LOG_SIZE - Vector2(24, 28)


func _hide_legacy_frames() -> void:
	for node_name: String in ["KeeperPortraitFrame", "EchoPortraitFrame", "Title"]:
		var node: CanvasItem = get_node_or_null(node_name) as CanvasItem
		if node:
			node.visible = false


func _place_echo_ghost() -> void:
	if _echo_portrait == null:
		return
	if _echo_ghost == null:
		_echo_ghost = TextureRect.new()
		_echo_ghost.name = "EchoGhost"
		_echo_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_echo_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_echo_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_echo_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_echo_ghost.modulate = Color(1, 1, 1, 0.25)
		_echo_ghost.z_index = -1
		add_child(_echo_ghost)
	_echo_ghost.texture = _echo_portrait.texture
	_echo_ghost.position = _echo_portrait.position + Vector2(4, -2)
	_echo_ghost.size = _echo_portrait.size


func _place_ripples() -> void:
	var ox: float = EchoTheme.shift()
	for who: String in ["Keeper", "Echo"]:
		var cx: float = EchoTheme.KEEPER_CX if who == "Keeper" else EchoTheme.ECHO_CX
		var node_name: String = who + "Ripple"
		var ripple: TextureRect = get_node_or_null(node_name) as TextureRect
		if ripple == null:
			ripple = TextureRect.new()
			ripple.name = node_name
			ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ripple.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ripple.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ripple.texture = load(EchoTheme.ART + "fx_ripple_0_220x44.png")
			add_child(ripple)
			move_child(ripple, _chamber_art.get_index() + 1 if _chamber_art else 0)
		ripple.position = Vector2(ox + cx - 110.0, EchoTheme.FEET_Y - 22.0)
		ripple.size = Vector2(220, 44)


func _build_chamber_chrome() -> void:
	var ox: float = EchoTheme.shift()
	var title_font: Font = EchoTheme.jersey_font(EchoTheme.TITLE_SIZE)
	var title_text: String = "Echo Chamber"
	var text_w: float = title_font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, EchoTheme.TITLE_SIZE).x
	var plate_w: float = EchoTheme.snap_panel(text_w + 56.0)
	var plate_h: float = EchoTheme.snap_panel(50.0)
	_title_plate = Panel.new()
	_title_plate.name = "EchoTitlePlate"
	_title_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_plate.position = Vector2(ox + (EchoTheme.DESIGN_W - plate_w) * 0.5, 26)
	_title_plate.size = Vector2(plate_w, plate_h)
	EchoTheme.paint_panel(_title_plate, true)
	add_child(_title_plate)
	var title := Label.new()
	title.name = "EchoTitle"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2.ZERO
	title.size = _title_plate.size
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_title(title, true)
	_title_plate.add_child(title)
	_close_btn = Button.new()
	_close_btn.name = "EchoClose"
	_close_btn.focus_mode = Control.FOCUS_ALL
	var close_box: Rect2 = EchoTheme.at(EchoTheme.CLOSE_BTN)
	_close_btn.position = close_box.position
	_close_btn.size = close_box.size
	_close_btn.custom_minimum_size = close_box.size
	EchoTheme.paint_button(_close_btn, true)
	var x_icon := TextureRect.new()
	x_icon.texture = load(EchoTheme.ART + "icon_close_x_24.png")
	x_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	x_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	x_icon.position = Vector2(10, 10)
	x_icon.size = Vector2(24, 24)
	_close_btn.add_child(x_icon)
	_close_btn.pressed.connect(_on_chamber_leave)
	add_child(_close_btn)
	var panel_box: Rect2 = EchoTheme.at(EchoTheme.CHAMBER_PANEL)
	_chamber_panel = Panel.new()
	_chamber_panel.name = "ChamberPanel"
	_chamber_panel.position = panel_box.position
	_chamber_panel.size = panel_box.size
	EchoTheme.paint_panel(_chamber_panel, false)
	add_child(_chamber_panel)
	var fee := Label.new()
	fee.name = "ChamberFee"
	fee.text = "Fee paid · saving is off inside"
	fee.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fee.position = Vector2(16, 8)
	fee.size = Vector2(panel_box.size.x - 32.0, 22)
	fee.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(fee, true)
	_chamber_panel.add_child(fee)
	var leave_box: Rect2 = EchoTheme.at(EchoTheme.LEAVE_BTN)
	_leave_btn = Button.new()
	_leave_btn.name = "LeaveButton"
	_leave_btn.text = "Leave"
	_leave_btn.position = leave_box.position
	_leave_btn.size = leave_box.size
	_leave_btn.custom_minimum_size = leave_box.size
	EchoTheme.paint_button(_leave_btn, false)
	_leave_btn.pressed.connect(_on_chamber_leave)
	add_child(_leave_btn)
	var face_box: Rect2 = EchoTheme.at(EchoTheme.FACE_BTN)
	_face_btn = Button.new()
	_face_btn.name = "FaceButton"
	_face_btn.text = "Face the Echo"
	_face_btn.position = face_box.position
	_face_btn.size = face_box.size
	_face_btn.custom_minimum_size = face_box.size
	EchoTheme.paint_button(_face_btn, true)
	_face_btn.pressed.connect(begin_face_off)
	add_child(_face_btn)


func is_chamber_shown() -> bool:
	return _phase == "chamber" and _chamber_panel != null and _chamber_panel.visible


func begin_face_off() -> void:
	_phase = "fight"
	_show_fight_chrome()
	_refresh_actions()


func _on_chamber_leave() -> void:
	## Leave confirm arrives with the later commit. Never flee from the title ×.
	_phase = "leave"


func _show_chamber_chrome() -> void:
	if _chamber_panel:
		_chamber_panel.visible = true
	if _leave_btn:
		_leave_btn.visible = true
	if _face_btn:
		_face_btn.visible = true
	if _close_btn:
		_close_btn.visible = true


func _hide_chamber_chrome() -> void:
	if _chamber_panel:
		_chamber_panel.visible = false
	if _leave_btn:
		_leave_btn.visible = false
	if _face_btn:
		_face_btn.visible = false


func _show_fight_chrome() -> void:
	_hide_chamber_chrome()
	if _command_band:
		_command_band.visible = true


func _hide_fight_chrome() -> void:
	if _strike:
		_strike.visible = false
	if _flee:
		_flee.visible = false
	if _spare:
		_spare.visible = false
	if _arrow:
		_arrow.visible = false
	if _return_btn:
		_return_btn.visible = false
	if _command_band:
		_command_band.visible = false


func _apply_chamber_plate() -> void:
	if _chamber_art == null:
		return
	var plate: Texture2D = null
	if FileAccess.file_exists(CHAMBER_BG):
		var full: Texture2D = load(CHAMBER_BG) as Texture2D
		if full != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = full
			var wide: bool = Ui540.viewport_size().x >= 1100.0
			atlas.region = EchoTheme.CROP_20 if wide else EchoTheme.CROP_16
			plate = atlas
	_chamber_art.texture = plate
	_chamber_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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


func echo_uses_bramble_texture() -> bool:
	return _echo_portrait != null and _echo_portrait.texture != null \
		and str(_echo_portrait.texture.resource_path).find("battle_bramble_idle") >= 0


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
	if _speech_bg == null or _speech == null or _log == null or _keeper_portrait == null or _echo_portrait == null:
		return false
	var gap_left: float = _keeper_portrait.position.x + _keeper_portrait.size.x
	var gap_right: float = _echo_portrait.position.x
	var box_left: float = _speech_bg.position.x
	var box_right: float = box_left + _speech_bg.size.x
	var box_top: float = _speech_bg.position.y
	var box_bottom: float = box_top + _speech_bg.size.y
	var portrait_top: float = _keeper_portrait.position.y
	var portrait_bottom: float = portrait_top + _keeper_portrait.size.y
	var in_gap: bool = box_left >= gap_left - 0.5 and box_right <= gap_right + 0.5
	var in_band: bool = box_top >= portrait_top - 0.5 and box_bottom <= portrait_bottom + 0.5
	var above_log: bool = _speech.position.y < _log.position.y and box_bottom <= _log.position.y + 0.5
	return in_gap and in_band and above_log


func log_top() -> float:
	return _log.position.y if _log else -1.0


func _enemy_name() -> String:
	if _is_bramble():
		var labeled: String = ContentStrings.get_text("bramble_name")
		if labeled != "" and labeled != "bramble_name":
			return labeled
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
		_phase = "fight"
		_show_mercy()
		_show_fight_chrome()
		_refresh_actions()
		return
	_phase = "chamber"
	_show_opening()
	_show_chamber_chrome()
	_refresh_actions()


func _show_opening() -> void:
	if _is_bramble():
		_show_bramble_opening()
		return
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


func _show_bramble_opening() -> void:
	if EchoChamber.reentry:
		if GameState.echo_02_outcome == "flee":
			_speech.text = ContentStrings.get_text("echo_02_return_flee")
		elif GameState.echo_02_outcome == "ko":
			_speech.text = ContentStrings.get_text("echo_02_return_lost")
		else:
			_speech.text = ContentStrings.get_text("echo_02_return")
	elif GameState.echo_02_outcome == "ko":
		_speech.text = ContentStrings.get_text("echo_02_return_lost")
	elif not GameState.echo_02_narrator_heard:
		_speech.text = "%s\n%s" % [
			ContentStrings.get_text("echo_02_narrator"),
			ContentStrings.get_text("echo_02_intro"),
		]
		GameState.echo_02_narrator_heard = true
	else:
		_speech.text = ContentStrings.get_text("echo_02_intro")
	_set_mercy_visible(false)


func _show_mercy() -> void:
	_mercy_shown = true
	_speech.text = _echo_line("mercy")
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
	if _log:
		_log.text = _pending_toast
	## Only the flee result is the You Fled window. Spare and defeat keep the command-band return.
	if outcome == "flee":
		_return_btn.visible = false
		_show_fled_window()
		return
	_return_btn.visible = true


func _flavour_for_outcome(outcome: String) -> String:
	match outcome:
		"flee":
			return _echo_line("flee")
		"spare":
			return _echo_line("spare")
		"defeat":
			return _echo_line("defeat")
	return ""


func _outcome_toast(outcome: String) -> String:
	var enemy: String = _enemy_name()
	var parts: PackedStringArray = PackedStringArray()
	if _is_bramble():
		match outcome:
			"flee":
				parts.append(ContentStrings.get_text("battle_flee_ok"))
			"spare":
				parts.append(ContentStrings.get_text("adventure_echo2_toast_spare"))
			"defeat":
				parts.append(ContentStrings.get_text("adventure_echo2_toast_defeat"))
		return "\n".join(parts)
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


## Echo You Fled (extras v8c). Position only: 520×420 at y 92, 24 px inside the parchment.
## The chamber, portraits, and the spare/defeat return stay as they are.
const ECHO_FLED_H: float = 420.0
const ECHO_FLED_ART: String = "res://assets/ui/extras/fled_art_120x72.png"
const ECHO_FLED_WARN: String = "res://assets/ui/extras/icon_warn_amber_kit_18x16.png"


func _show_fled_window() -> void:
	_clear_fled_window()
	var dim := ColorRect.new()
	dim.name = "EchoFledDim"
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := Panel.new()
	panel.name = "EchoFledWindow"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.position = Vector2(Ui540.fled_window_x(), Ui540.FLED_WINDOW_Y)
	panel.size = Vector2(Ui540.FLED_WINDOW_W, ECHO_FLED_H)
	panel.custom_minimum_size = panel.size
	Ui540.apply_kit_frame_panel(panel, "fled_window")
	add_child(panel)
	var title := Label.new()
	title.name = "EchoFledTitle"
	title.text = ContentStrings.get_text("adv_end_flee_title")
	panel.add_child(title)
	Ui540.place_title_plank(title, Ui540.FLED_WINDOW_W)
	title.position.y = -Ui540.FLED_PLANK_OVERHANG
	var inset: float = Ui540.FLED_INSET
	var content_w: float = Ui540.FLED_WINDOW_W - inset * 2.0
	var close := Button.new()
	close.name = "EchoFledClose"
	Ui540.configure_kit_close_button(close)
	close.position = Vector2(Ui540.FLED_WINDOW_W - inset - Ui540.TAP_MIN_PX, inset)
	close.size = Vector2(Ui540.TAP_MIN_PX, Ui540.TAP_MIN_PX)
	close.pressed.connect(_on_return)
	panel.add_child(close)
	var art := TextureRect.new()
	art.name = "EchoFledArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = load(ECHO_FLED_ART) as Texture2D
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2((Ui540.FLED_WINDOW_W - 120.0) * 0.5, inset + 8.0)
	art.size = Vector2(120, 72)
	panel.add_child(art)
	var body := Label.new()
	body.name = "EchoFledBody"
	body.text = _echo_line("flee")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(inset, inset + 100.0 - 14.0)
	body.size = Vector2(content_w, 28)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_fled_label(body, false)
	panel.add_child(body)
	var rows: Array = [
		["echo_fled_fee", "Essence fee", "echo_fled_fee_value", "still paid · re-entry free", false],
		["echo_fled_rewards", "Rewards", "echo_fled_rewards_value", "none this attempt", true],
		["echo_fled_keeper", "Keeper", "echo_fled_keeper_value", "back at the trailhead", false],
	]
	for i: int in rows.size():
		var spec: Array = rows[i]
		_add_fled_row(panel, i, str(spec[0]), str(spec[1]), str(spec[2]), str(spec[3]), bool(spec[4]), inset, content_w)
	var back := Button.new()
	back.name = "EchoFledReturn"
	back.text = ContentStrings.get_text("battle_return")
	back.custom_minimum_size = Vector2(300, 44)
	back.size = Vector2(300, 44)
	back.position = Vector2((Ui540.FLED_WINDOW_W - 300.0) * 0.5, ECHO_FLED_H - inset - 44.0)
	var theme: Node = get_node_or_null("/root/GameTheme")
	if theme != null:
		theme.call("style_primary_button", back)
	back.pressed.connect(_on_return)
	panel.add_child(back)
	back.call_deferred("grab_focus")
	Ui540.hide_name_tags_under(panel)


func _add_fled_row(panel: Control, index: int, label_key: String, label_fallback: String, value_key: String, value_fallback: String, amber: bool, inset: float, content_w: float) -> void:
	var row := Panel.new()
	row.name = "EchoFledRow%d" % index
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.position = Vector2(inset, inset + 128.0 + float(index) * 34.0)
	row.size = Vector2(content_w, 28)
	row.add_theme_stylebox_override(
		"panel",
		Ui540.kit_stylebox_9s("res://assets/ui/theme/play_bevel_9s_6x6.png", Vector4i(2, 2, 2, 2)),
	)
	panel.add_child(row)
	var left := Label.new()
	left.text = _fled_text(label_key, label_fallback)
	left.position = Vector2(12, 0)
	left.size = Vector2(content_w * 0.45, 28)
	left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_fled_label(left, true)
	row.add_child(left)
	var value := _fled_text(value_key, value_fallback)
	var right := Label.new()
	right.name = "Value"
	right.text = value
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.position = Vector2(content_w * 0.4, 0)
	right.size = Vector2(content_w * 0.6 - 12.0, 28)
	_style_fled_label(right, false)
	if amber:
		right.add_theme_color_override("font_color", Ui540.WARNING_AMBER)
		var icon := TextureRect.new()
		icon.texture = load(ECHO_FLED_WARN) as Texture2D
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.size = Vector2(18, 16)
		var font: Font = right.get_theme_font("font")
		var text_w: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, right.get_theme_font_size("font_size")).x if font else 120.0
		icon.position = Vector2(right.position.x + right.size.x - text_w - 24.0, 6)
		row.add_child(icon)
	row.add_child(right)


func _fled_text(key: String, fallback: String) -> String:
	var text: String = ContentStrings.get_text(key)
	if text == "" or text == key:
		return fallback
	return text


func _style_fled_label(lbl: Label, muted: bool) -> void:
	var theme: Node = get_node_or_null("/root/GameTheme")
	if theme != null:
		theme.call("style_ink_label", lbl, muted)


func _clear_fled_window() -> void:
	_restore_fled_names()
	for node_name: String in ["EchoFledDim", "EchoFledWindow"]:
		var node: Node = get_node_or_null(node_name)
		if node != null:
			node.queue_free()


func _restore_fled_names() -> void:
	var root: Node = _name_tag_root
	var tree: SceneTree = get_tree()
	if tree != null:
		root = tree.root
	Ui540.restore_name_tags(root)


func _on_return() -> void:
	if _pending_outcome == "":
		return
	var outcome: String = _pending_outcome
	_pending_outcome = ""
	_restore_fled_names()
	GameAudio.play_ui_confirm()
	EchoChamber.finish_battle(outcome)


func _refresh_actions() -> void:
	if _battle == null:
		return
	if _phase == "chamber":
		_hide_fight_chrome()
		_show_chamber_chrome()
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


