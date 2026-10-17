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
## Strike gap 1.0s, then the hurt hold. Poses stay on this view.
const PARTY_DIR: String = "res://assets/art/battle/party/"
const GAP_STRIKE_SEC: float = 1.0
const HURT_HOLD_SEC: float = 0.75
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
var _speech_box: Control = null
var _speech_art: TextureRect = null
var _status_chip: Panel = null
var _status_label: Label = null
var _strike_focused: bool = false
var _page_label: Label = null
var _page_btn: Button = null
var _skip_btn: Button = null
var _speech_source: String = ""
var _pages: PackedStringArray = PackedStringArray()
var _page_i: int = 0
var _ability_btn: Button = null
var _brace_btn: Button = null
var _salve_btn: Button = null
var _title_plate: Panel = null
var _echo_ghost: TextureRect = null
var _mercy_shown: bool = false
var _waiting_return: bool = false
var _pending_outcome: String = ""
var _end_layer: Control = null
var _end_action: String = ""
var _phase_before_end: String = ""
var _pending_toast: String = ""
var _pulse: float = 0.0
var _name_tag_root: Node = null
var _instant_turns: bool = false
var _turn_busy: bool = false
var _pose_queue: Array[Dictionary] = []
var _pose_left: float = 0.0
var _pose_action: String = ""
var _pose_echo_hp: int = 0


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
	_instant_turns = DisplayServer.get_name() == "headless" or OS.has_feature("headless")
	_apply_button_copy()
	_bind()


func _apply_portraits() -> void:
	var keeper_tex: Texture2D = load(KEEPER_IDLE) as Texture2D
	if _keeper_portrait and keeper_tex:
		_keeper_portrait.texture = keeper_tex
		_keeper_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_keeper_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_keeper_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_mirror_portrait(_keeper_portrait, false)
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
		_mirror_portrait(_echo_portrait, false)
		_place_echo_ghost()
		return
	var path: String = ELAIA_KEY if _elaia_holds_key() else ELAIA_IDLE
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		_echo_portrait.texture = tex
	_echo_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_echo_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_echo_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mirror_portrait(_echo_portrait, false)
	_place_echo_ghost()


func _raise_names() -> void:
	var ox: float = EchoTheme.shift()
	var keeper_name: Label = get_node_or_null("KeeperName") as Label
	var echo_name: Label = get_node_or_null("EchoName") as Label
	if keeper_name:
		keeper_name.position = Vector2(ox + EchoTheme.KEEPER_CX - 80.0, 90.0 + Ui540.center_shift_y())
		keeper_name.size = Vector2(160, 22)
		keeper_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		EchoTheme.style_body(keeper_name, false)
	if echo_name:
		echo_name.position = Vector2(ox + EchoTheme.ECHO_CX - 90.0, 90.0 + Ui540.center_shift_y())
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
		_keeper_portrait.position = KEEPER_PORTRAIT_POS + Vector2(ox, Ui540.center_shift_y())
		_keeper_portrait.size = PORTRAIT
	if _echo_portrait:
		_echo_portrait.position = ECHO_PORTRAIT_POS + Vector2(ox, Ui540.center_shift_y())
		_echo_portrait.size = PORTRAIT
	_place_echo_ghost()
	_place_ripples()
	_layout_speech_box(ox)
	if _speech_bg:
		_speech_bg.visible = false
	if _command_band:
		var band_x: float = ox + (960.0 - COMMAND_SIZE.x) * 0.5
		_command_band.position = Vector2(band_x, 450.0 + Ui540.center_shift_y())
		_command_band.size = COMMAND_SIZE
	var log_bg: ColorRect = get_node_or_null("LogBg") as ColorRect
	if log_bg:
		log_bg.position = LOG_BG_POS + Vector2(ox, Ui540.center_shift_y())
		log_bg.size = LOG_SIZE
	if _log:
		_log.position = LOG_BG_POS + Vector2(ox + 12, 20.0 + Ui540.center_shift_y())
		_log.size = LOG_SIZE - Vector2(24, 28)


func _hide_legacy_frames() -> void:
	for node_name: String in [
		"KeeperPortraitFrame", "EchoPortraitFrame", "Title",
		"LogBg", "LogTitle", "Log", "CommandBand",
		"KeeperHpBack", "KeeperHpFill", "EchoHpBack", "EchoHpFill",
		"KeeperHpText", "EchoHpText",
	]:
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
		ripple.position = Vector2(ox + cx - 110.0, EchoTheme.FEET_Y - 22.0 + Ui540.center_shift_y())
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
	_title_plate.position = Vector2(ox + (EchoTheme.DESIGN_W - plate_w) * 0.5, 26.0 + Ui540.center_shift_y())
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


func _layout_speech_box(ox: float) -> void:
	var box_rect: Rect2 = EchoTheme.SPEECH_BOX
	if _speech_box == null:
		_speech_box = Control.new()
		_speech_box.name = "SpeechBox"
		_speech_box.clip_contents = true
		_speech_box.mouse_filter = Control.MOUSE_FILTER_STOP
		_speech_box.gui_input.connect(_on_speech_input)
		add_child(_speech_box)
		_speech_art = TextureRect.new()
		_speech_art.name = "SpeechArt"
		_speech_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_speech_art.texture = load(EchoTheme.SPEECH_TEX)
		_speech_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_speech_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_speech_art.stretch_mode = TextureRect.STRETCH_SCALE
		_speech_art.position = Vector2.ZERO
		_speech_art.size = box_rect.size
		_speech_box.add_child(_speech_art)
		if _speech:
			_speech.reparent(_speech_box)
		_page_label = Label.new()
		_page_label.name = "PageCount"
		_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_page_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		EchoTheme.style_body(_page_label, true)
		_speech_box.add_child(_page_label)
		_page_btn = Button.new()
		_page_btn.name = "PageNext"
		_page_btn.focus_mode = Control.FOCUS_ALL
		_page_btn.custom_minimum_size = Vector2(44, 44)
		EchoTheme.paint_button(_page_btn, true)
		var arrow := TextureRect.new()
		arrow.texture = load(EchoTheme.ART + "arrow_page_down_16x10.png")
		arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.position = Vector2(14, 17)
		arrow.size = Vector2(16, 10)
		_page_btn.add_child(arrow)
		_page_btn.pressed.connect(advance_speech)
		_speech_box.add_child(_page_btn)
		_skip_btn = Button.new()
		_skip_btn.name = "SkipSpeech"
		_skip_btn.text = "Skip"
		_skip_btn.custom_minimum_size = Vector2(104, 44)
		EchoTheme.paint_button(_skip_btn, false)
		var skip_icon := TextureRect.new()
		skip_icon.texture = load(EchoTheme.ART + "arrow_skip_18x12.png")
		skip_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		skip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skip_icon.position = Vector2(62, 16)
		skip_icon.size = Vector2(18, 12)
		_skip_btn.add_child(skip_icon)
		_skip_btn.pressed.connect(_skip_speech)
		_speech_box.add_child(_skip_btn)
	_speech_box.position = box_rect.position + Vector2(ox, Ui540.center_shift_y())
	_speech_box.size = box_rect.size
	_fit_speech_height()
	if _speech:
		_speech.position = Vector2(12, 10)
		_speech.size = Vector2(EchoTheme.SPEECH_TEXT_W, 60)
		_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_speech.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		EchoTheme.style_body(_speech, false)
	if _page_label:
		_page_label.position = Vector2(300, 104)
		_page_label.size = Vector2(72, 20)
	if _page_btn:
		_page_btn.position = Vector2(382, 82)
		_page_btn.size = Vector2(44, 44)
	if _skip_btn:
		_skip_btn.position = Vector2(8, 82)
		_skip_btn.size = Vector2(104, 44)


func _set_speech(text: String) -> void:
	_speech_source = text
	_pages = EchoTheme.paginate(text)
	if _pages.is_empty():
		_pages.append(text)
	_page_i = 0
	_show_page()


func _show_page() -> void:
	if _speech == null:
		return
	var shown: String = page_text() if not _pages.is_empty() else _speech_source
	_speech.text = shown
	var many: bool = _pages.size() > 1 or _phase == "speech"
	if _page_label:
		_page_label.visible = many and _phase != "fight"
		_page_label.text = "%d/%d" % [_page_i + 1, maxi(1, _pages.size())]
	if _page_btn:
		_page_btn.visible = _phase == "speech" or (_phase == "chamber" and _pages.size() > 1)
	if _skip_btn:
		var paging: bool = _phase == "speech" or _phase == "chamber"
		_skip_btn.visible = paging and EchoChamber.reentry
	_fit_speech_height()
	_refresh_status_chip()


func _fit_speech_height() -> void:
	if _speech_box == null:
		return
	var height: float = EchoTheme.SPEECH_BOX.size.y
	if _phase == "fight" and _speech != null:
		var font: Font = load(EchoTheme.BODY_FONT) as Font
		var lines: int = maxi(1, EchoTheme.line_count(_speech.text, font))
		if lines <= 1:
			height = 48.0
		elif lines == 2:
			height = 72.0
	_speech_box.size.y = height


func _skip_speech() -> void:
	if _pages.is_empty():
		return
	_page_i = _pages.size() - 1
	_show_page()


func _on_speech_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and _phase == "speech":
			advance_speech()


func begin_face_off() -> void:
	_phase = "speech"
	_show_fight_chrome()
	_show_page()
	_refresh_actions()


func finish_speech() -> void:
	if not _pages.is_empty():
		_page_i = _pages.size() - 1
	_phase = "fight"
	_show_page()
	_refresh_actions()


func advance_speech() -> void:
	if _phase != "speech":
		return
	if _page_i + 1 < _pages.size():
		_page_i += 1
		_show_page()
		return
	finish_speech()


var _leave_layer: Control = null
var _phase_before_leave: String = ""


func _on_chamber_leave() -> void:
	_open_leave_confirm()


func _open_leave_confirm() -> void:
	if _waiting_return or _leave_layer != null:
		return
	_phase_before_leave = _phase
	_phase = "leave"
	var ox: float = EchoTheme.shift()
	var dim := ColorRect.new()
	dim.name = "LeaveDim"
	dim.color = EchoTheme.DIM
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := Panel.new()
	panel.name = "LeaveConfirm"
	panel.position = Vector2(ox + 220.0, 126.0 + Ui540.center_shift_y())
	## 288 keeps Flee and Stay inside the frame. 248 let them straddle the border.
	panel.size = Vector2(520, 288)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	EchoTheme.paint_panel(panel, false)
	add_child(panel)
	_leave_layer = panel
	var title := Label.new()
	title.name = "LeaveTitle"
	title.text = "Leave the Chamber?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(32, 34)
	title.size = Vector2(456, 40)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_title(title, true)
	panel.add_child(title)
	var body := Label.new()
	body.name = "LeaveBody"
	body.text = ContentStrings.get_text("echo_leave_body")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(32, 68)
	body.size = Vector2(456, 48)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(body, false)
	panel.add_child(body)
	var warn := Label.new()
	warn.name = "LeaveWarn"
	warn.text = ContentStrings.get_text("echo_leave_warn")
	warn.position = Vector2(56, 120)
	warn.size = Vector2(432, 22)
	warn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(warn, false)
	warn.add_theme_color_override("font_color", EchoTheme.AMBER)
	panel.add_child(warn)
	var mark := TextureRect.new()
	mark.texture = load(EchoTheme.ART + "icon_warn_amber_18x16.png")
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = Vector2(32, 123)
	mark.size = Vector2(18, 16)
	panel.add_child(mark)
	var flee := Button.new()
	flee.name = "LeaveFlee"
	flee.text = "Flee"
	flee.position = Vector2(32, 212)
	flee.size = Vector2(168, 44)
	flee.custom_minimum_size = flee.size
	EchoTheme.paint_button(flee, false)
	flee.pressed.connect(_confirm_flee)
	panel.add_child(flee)
	var stay := Button.new()
	stay.name = "LeaveStay"
	stay.text = "Stay"
	stay.position = Vector2(232, 200)
	stay.size = Vector2(236, 56)
	stay.custom_minimum_size = Vector2(236, 44)
	EchoTheme.paint_button(stay, true)
	stay.pressed.connect(_confirm_stay)
	panel.add_child(stay)
	var cap := TextureRect.new()
	cap.name = "EscKeycap"
	cap.texture = load("res://assets/ui/theme/keycap_esc.png")
	cap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if cap.texture:
		cap.size = cap.texture.get_size()
	else:
		cap.size = Vector2(28, 15)
	cap.position = Vector2(stay.size.x - cap.size.x - 8.0, -cap.size.y - 2.0)
	cap.visible = not Ui540.is_phone_export()
	stay.add_child(cap)
	if _close_btn:
		_close_btn.visible = false
	stay.call_deferred("grab_focus")


func _confirm_stay() -> void:
	_close_leave_confirm()
	_phase = _phase_before_leave if _phase_before_leave != "" else "chamber"
	if _phase == "chamber":
		_show_chamber_chrome()
	elif _phase == "speech":
		_refresh_actions()
	else:
		_phase = "fight"
		_refresh_actions()
	_show_page()


func _confirm_flee() -> void:
	_close_leave_confirm()
	_phase = "fight"
	_choose("flee")


func _close_leave_confirm() -> void:
	for node_name: String in ["LeaveDim", "LeaveConfirm"]:
		var node: Node = get_node_or_null(node_name)
		if node:
			node.queue_free()
	_leave_layer = null
	if _close_btn and _phase != "fight":
		_close_btn.visible = true


func leave_confirm_open() -> bool:
	return _leave_layer != null and is_instance_valid(_leave_layer)


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
	_ensure_echo_menu()
	if _command_band:
		_command_band.visible = false


func _ensure_echo_menu() -> void:
	if get_node_or_null("EchoActionMenu") != null:
		return
	for node_name: String in ["StrikeButton", "FleeButton", "SpareButton", "ArrowToggle"]:
		var legacy: Node = get_node_or_null(node_name)
		if legacy:
			legacy.name = "Legacy" + node_name
			if legacy is CanvasItem:
				(legacy as CanvasItem).visible = false
	for node_name: String in ["LogBg", "LogTitle", "KeeperHpBack", "KeeperHpFill", "EchoHpBack", "EchoHpFill", "KeeperHpText", "EchoHpText"]:
		var old: CanvasItem = get_node_or_null(node_name) as CanvasItem
		if old:
			old.visible = false
	var hybrid: bool = _battle != null and _battle.strike_kind == "hybrid"
	var built: Dictionary = BattleView.build_echo_menu(self, hybrid)
	_strike = built["strike"] as Button
	_flee = built["flee"] as Button
	_spare = built["spare"] as Button
	_arrow = built["chip"] as Button
	_log = built["log"] as Label
	_ability_btn = built["ability"] as Button
	_brace_btn = built["brace"] as Button
	_salve_btn = built["items"] as Button
	if _strike and not _strike.pressed.is_connected(_on_strike):
		_strike.pressed.connect(_on_strike)
	if _flee and not _flee.pressed.is_connected(_on_flee):
		_flee.pressed.connect(_on_flee)
	if _spare and not _spare.pressed.is_connected(_on_spare):
		_spare.pressed.connect(_on_spare)
	if _arrow and not _arrow.pressed.is_connected(_on_arrow):
		_arrow.pressed.connect(_on_arrow)
	if _brace_btn and not _brace_btn.pressed.is_connected(_on_brace):
		_brace_btn.pressed.connect(_on_brace)
	if _salve_btn and not _salve_btn.pressed.is_connected(_on_salve):
		_salve_btn.pressed.connect(_on_salve)
	_build_hp_bars()
	_refresh_bars(false)
	_ensure_log_header()
	_refresh_log()
	_ensure_status_chip()


func _ensure_log_header() -> void:
	var panel: Control = get_node_or_null("EchoActionMenu/EchoLog") as Control
	if panel == null or panel.get_node_or_null("LogHeader") != null:
		return
	var header := Label.new()
	header.name = "LogHeader"
	header.text = ContentStrings.get_text("battle_log_title")
	header.position = Vector2(8, 4)
	header.size = Vector2(396, 20)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(header, false)
	header.add_theme_color_override("font_color", EchoTheme.AMBER)
	panel.add_child(header)
	if _log:
		_log.position = Vector2(8, 24)
		_log.size = Vector2(396, 68)


func _ensure_status_chip() -> void:
	if _status_chip != null:
		return
	var box: Rect2 = EchoTheme.at(EchoTheme.ATTEMPT_CHIP)
	_status_chip = Panel.new()
	_status_chip.name = "EchoStatusChip"
	_status_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_chip.position = box.position
	_status_chip.size = box.size
	var art := TextureRect.new()
	art.texture = load(EchoTheme.ART + "chip_attempt_132x44.png")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = Vector2.ZERO
	art.size = box.size
	_status_chip.add_child(art)
	_status_label = Label.new()
	_status_label.name = "Label"
	_status_label.position = Vector2.ZERO
	_status_label.size = box.size
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(_status_label, false)
	_status_chip.add_child(_status_label)
	_status_chip.visible = false
	add_child(_status_chip)


func _refresh_status_chip() -> void:
	_ensure_status_chip()
	if _status_chip == null:
		return
	## The card is narrower than the chip. Leave the chip hidden until the card closes.
	if get_node_or_null("EchoRewards") != null:
		_status_chip.visible = false
		return
	## reentry is the only attempt flag. A third visit still reads Attempt 2.
	if EchoChamber.reentry and (_phase == "speech" or _phase == "fight"):
		_status_chip.visible = true
		_status_label.text = "Attempt 2"
		return
	if _phase == "fight" and _battle != null:
		_status_chip.visible = true
		_status_label.text = "Round %d" % (_battle.round + 1)
		return
	_status_chip.visible = false


func _build_hp_bars() -> void:
	if get_node_or_null("KeeperHpBar") != null:
		return
	_keeper_hp_fill = _make_hp_bar("Keeper", EchoTheme.KEEPER_CX, false)
	_echo_hp_fill = _make_hp_bar("Echo", EchoTheme.ECHO_CX, true)


func _make_hp_bar(who: String, cx: float, foe: bool) -> ColorRect:
	var ox: float = EchoTheme.shift()
	var frame := NinePatchRect.new()
	frame.name = who + "HpBar"
	frame.texture = load(EchoTheme.ART + "ink_hp_frame_9s_16x14.png")
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.patch_margin_left = 2
	frame.patch_margin_top = 2
	frame.patch_margin_right = 2
	frame.patch_margin_bottom = 2
	frame.position = Vector2(ox + cx - 90.0, 344.0 + Ui540.center_shift_y())
	frame.size = Vector2(180, 14)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var fill := ColorRect.new()
	fill.name = who + "HpFill"
	fill.position = Vector2(2, 2)
	fill.size = Vector2(176, 10)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.color = EchoTheme.KOI if foe else EchoTheme.CYAN
	frame.add_child(fill)
	var lbl := Label.new()
	lbl.name = who + "HpText"
	lbl.position = Vector2(ox + cx - 90.0, 366.0 + Ui540.center_shift_y())
	lbl.size = Vector2(180, 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(lbl, false)
	add_child(lbl)
	if who == "Keeper":
		_keeper_hp_label = lbl
	else:
		_echo_hp_label = lbl
	return fill


func _on_brace() -> void:
	if _turn_busy or end_confirm_open():
		return
	_choose("brace")


func _on_salve() -> void:
	if _turn_busy or end_confirm_open():
		return
	_choose("salve")


func _pause_is_open() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var menu: Node = tree.get_first_node_in_group("pause_menu")
	return menu != null and menu.has_method("is_open") and bool(menu.call("is_open"))


func _unhandled_input(event: InputEvent) -> void:
	if _battle == null:
		return
	## Pause only freezes. Esc while it is open resumes it, and does not flee.
	if _pause_is_open():
		return
	if end_confirm_open():
		if event is InputEventKey:
			var end_key: InputEventKey = event as InputEventKey
			if end_key.pressed and not end_key.echo and end_key.keycode == KEY_ESCAPE:
				_dismiss_end()
				get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if _waiting_return:
		if key.keycode == KEY_ESCAPE and get_node_or_null("EchoRewards") != null:
			_on_return()
			get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_ESCAPE:
		if _phase == "leave":
			_confirm_stay()
		else:
			_open_leave_confirm()
		get_viewport().set_input_as_handled()
		return
	if _phase == "speech" and (key.keycode == KEY_SPACE or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		advance_speech()
		get_viewport().set_input_as_handled()
		return
	if _phase != "fight":
		return
	if key.keycode >= KEY_1 and key.keycode <= KEY_6:
		var row: Array[Button] = [_strike, _ability_btn, _salve_btn, _brace_btn, _flee, _spare]
		var slot: int = int(key.keycode - KEY_1)
		var btn: Button = row[slot]
		if _offered(btn):
			btn.pressed.emit()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_TAB or key.keycode == KEY_Q:
		_on_arrow()
		get_viewport().set_input_as_handled()


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
	if not _turn_busy:
		return
	if _instant_turns:
		_finish_pose_queue()
		return
	_pose_left -= delta
	if _pose_left <= 0.0:
		_advance_pose()


func is_flee_shown() -> bool:
	return _offered(_flee)


func is_spare_shown() -> bool:
	return _offered(_spare)


func is_strike_shown() -> bool:
	return _offered(_strike)


func _offered(btn: Button) -> bool:
	return btn != null and btn.visible and not btn.disabled


func is_arrow_toggle_shown() -> bool:
	return _arrow != null and _arrow.visible


func arrow_toggle_text() -> String:
	return _arrow.text if _arrow else ""


func speech_text() -> String:
	if _speech_source != "":
		return _speech_source
	return _speech.text if _speech else ""


func page_count() -> int:
	return _pages.size()


func page_text() -> String:
	if _page_i < 0 or _page_i >= _pages.size():
		return ""
	return _pages[_page_i]


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
	var bar: Control = get_node_or_null("EchoActionMenu/EchoBottomBar") as Control
	if bar != null:
		return bar.size
	return COMMAND_SIZE if _command_band == null else _command_band.size


func log_band_size() -> Vector2:
	var log_panel: Control = get_node_or_null("EchoActionMenu/EchoLog") as Control
	if log_panel != null:
		return log_panel.size
	return LOG_SIZE


func speech_band_size() -> Vector2:
	if _speech_box:
		return _speech_box.size
	if _speech_bg:
		return _speech_bg.size
	return EchoTheme.SPEECH_BOX.size


func speech_top() -> float:
	if _speech == null:
		return -1.0
	return _speech.get_global_rect().position.y


func speech_between_portraits() -> bool:
	var box: Control = _speech_box if _speech_box != null else _speech_bg
	if box == null or _speech == null or _log == null or _keeper_portrait == null:
		return false
	var ox: float = EchoTheme.shift()
	var box_left: float = box.position.x
	var box_right: float = box_left + box.size.x
	var box_top: float = box.position.y
	var box_bottom: float = box_top + box.size.y
	var portrait_top: float = _keeper_portrait.position.y
	var portrait_bottom: float = portrait_top + _keeper_portrait.size.y
	## Opaque keeper art ends at x 230; Elaia's key sprite starts at x 704.
	var in_gap: bool = box_left >= ox + 230.0 - 0.5 and box_right <= ox + 704.0 + 0.5
	var in_band: bool = box_top >= portrait_top - 0.5 and box_bottom <= portrait_bottom + 0.5
	var log_y: float = _log.get_global_rect().position.y
	var speech_y: float = _speech.get_global_rect().position.y
	var above_log: bool = speech_y < log_y and box_bottom <= log_y + 0.5
	return in_gap and in_band and above_log


func log_top() -> float:
	if _log == null:
		return -1.0
	return _log.get_global_rect().position.y


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
	## The fee-paid card is gone. Entry opens on the fight dialogue.
	_show_opening()
	begin_face_off()


func _show_opening() -> void:
	if _is_bramble():
		_show_bramble_opening()
		return
	if EchoChamber.reentry:
		_set_speech(ContentStrings.get_text("echo_01_return"))
	elif not GameState.echo_01_narrator_heard:
		_set_speech("%s\n%s" % [
			ContentStrings.get_text("echo_01_narrator"),
			ContentStrings.get_text("echo_01_intro"),
		])
		GameState.echo_01_narrator_heard = true
	else:
		_set_speech(ContentStrings.get_text("echo_01_intro"))
	_set_mercy_visible(false)


func _show_bramble_opening() -> void:
	if EchoChamber.reentry:
		if GameState.echo_02_outcome == "flee":
			_set_speech(ContentStrings.get_text("echo_02_return_flee"))
		elif GameState.echo_02_outcome == "ko":
			_set_speech(ContentStrings.get_text("echo_02_return_lost"))
		else:
			_set_speech(ContentStrings.get_text("echo_02_return"))
	elif GameState.echo_02_outcome == "ko":
		_set_speech(ContentStrings.get_text("echo_02_return_lost"))
	elif not GameState.echo_02_narrator_heard:
		_set_speech("%s\n%s" % [
			ContentStrings.get_text("echo_02_narrator"),
			ContentStrings.get_text("echo_02_intro"),
		])
		GameState.echo_02_narrator_heard = true
	else:
		_set_speech(ContentStrings.get_text("echo_02_intro"))
	_set_mercy_visible(false)


func _show_mercy() -> void:
	_mercy_shown = true
	_set_speech(_echo_line("mercy"))
	_set_mercy_visible(true)


func _set_mercy_visible(show: bool) -> void:
	if _mercy_banner:
		_mercy_banner.visible = show
	if _mercy_label:
		_mercy_label.visible = show
		if show:
			_mercy_label.text = ContentStrings.get_text("battle_mercy_hint", {"enemy": _enemy_name()})


func _on_strike() -> void:
	if _turn_busy or end_confirm_open():
		return
	if _ending_choice("strike"):
		_open_end_confirm("strike")
		return
	_choose("strike")


func _on_flee() -> void:
	if _turn_busy or end_confirm_open():
		return
	_choose("flee")


func _on_spare() -> void:
	if _turn_busy or end_confirm_open():
		return
	if _ending_choice("spare"):
		_open_end_confirm("spare")
		return
	_choose("spare")


## Spare and the last Strike finish the fight. Brace and Salve do not.
func _ending_choice(action: String) -> bool:
	return (
		_battle != null
		and not _waiting_return
		and _phase == "fight"
		and _battle.outcome == ""
		and _battle.spare_window
		and (action == "strike" or action == "spare")
	)


func end_confirm_open() -> bool:
	return _end_layer != null and is_instance_valid(_end_layer)


func end_confirm_text() -> String:
	if not end_confirm_open():
		return ""
	var body: Label = _end_layer.get_node_or_null("EndBody") as Label
	return body.text if body != null else ""


func _open_end_confirm(action: String) -> void:
	if _waiting_return or _battle == null or end_confirm_open():
		return
	_phase_before_end = _phase
	_phase = "end"
	_end_action = action
	var ox: float = EchoTheme.shift()
	var dim := ColorRect.new()
	dim.name = "EndDim"
	dim.color = EchoTheme.DIM
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := Panel.new()
	panel.name = "EndConfirm"
	panel.position = Vector2(ox + 220.0, 150.0 + Ui540.center_shift_y())
	panel.size = Vector2(520, 220)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	EchoTheme.paint_panel(panel, false)
	add_child(panel)
	_end_layer = panel
	var title := Label.new()
	title.name = "EndTitle"
	title.text = ContentStrings.get_text("echo_end_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(32, 28)
	title.size = Vector2(456, 36)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_title(title, true)
	panel.add_child(title)
	var body := Label.new()
	body.name = "EndBody"
	var line_key: String = "echo_end_spare" if action == "spare" else "echo_end_strike"
	body.text = ContentStrings.get_text(line_key, {"enemy": _enemy_name()})
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.position = Vector2(32, 76)
	body.size = Vector2(456, 52)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(body, false)
	panel.add_child(body)
	var no := Button.new()
	no.name = "EndNo"
	no.text = ContentStrings.get_text("portal_confirm_no")
	no.position = Vector2(32, 144)
	no.size = Vector2(200, 44)
	no.custom_minimum_size = no.size
	EchoTheme.paint_button(no, true)
	no.pressed.connect(_dismiss_end)
	panel.add_child(no)
	var yes := Button.new()
	yes.name = "EndYes"
	yes.text = ContentStrings.get_text("echo_end_yes")
	yes.position = Vector2(288, 144)
	yes.size = Vector2(200, 44)
	yes.custom_minimum_size = yes.size
	EchoTheme.paint_button(yes, false)
	yes.pressed.connect(_confirm_end)
	panel.add_child(yes)
	no.call_deferred("grab_focus")


func _confirm_end() -> void:
	var action: String = _end_action
	_close_end_confirm()
	_phase = "fight"
	if action == "strike" or action == "spare":
		_choose(action)


func _dismiss_end() -> void:
	_close_end_confirm()
	_phase = _phase_before_end if _phase_before_end == "fight" else "fight"
	_end_action = ""
	_refresh_actions()


func _close_end_confirm() -> void:
	for node_name: String in ["EndDim", "EndConfirm"]:
		var node: Node = get_node_or_null(node_name)
		if node:
			node.queue_free()
	_end_layer = null


func _on_arrow() -> void:
	if _turn_busy or _battle == null or _waiting_return or _battle.strike_kind != "hybrid":
		return
	GameAudio.play_ui_confirm()
	var mode: String = _battle.toggle_arrow_mode()
	GameState.arrow_mode = mode
	_refresh_actions()
	_refresh_log()


func set_instant_turns(on: bool) -> void:
	_instant_turns = on


func turn_busy() -> bool:
	return _turn_busy


func portrait_texture_path(who: String) -> String:
	var rect: TextureRect = _portrait_for(who)
	if rect == null or rect.texture == null:
		return ""
	return str(rect.texture.resource_path)


func portrait_flipped(who: String) -> bool:
	var rect: TextureRect = _portrait_for(who)
	return rect != null and rect.scale.x < 0.0


func portrait_pivot_x(who: String) -> float:
	var rect: TextureRect = _portrait_for(who)
	if rect == null:
		return -1.0
	return rect.pivot_offset.x


func _choose(action: String) -> void:
	if _battle == null or _waiting_return or _turn_busy:
		return
	if _battle.pending_half() != "":
		return
	GameAudio.play_ui_confirm()
	var before_echo: int = _battle.echo_hp
	var log_before: int = _battle.turn_log.size()
	_battle.present_halves = true
	_battle.instant_present = _instant_turns
	var result: String = _battle.choose(action)
	if result == "invalid" or result == "locked" or result == "no_flee" or result == "resolved":
		return
	_pose_action = action
	_pose_echo_hp = before_echo
	var acted: bool = result != "no_salve"
	if acted:
		_enqueue_half(action, log_before, true, result)
	if result == "presenting":
		_turn_busy = true
		_refresh_bars(true)
		_refresh_log()
		_begin_pose()
		return
	if _instant_turns:
		_drain_poses()
		_settle_turn()
		return
	if _pose_queue.is_empty():
		_settle_turn()
		return
	_turn_busy = true
	_refresh_bars(true)
	_refresh_log()
	_begin_pose()


func _enqueue_half(action: String, log_before: int, first_half: bool, result: String) -> void:
	if _battle == null:
		return
	if first_half and action == "brace" and result != "no_salve":
		_queue_pose("keeper", "brace", GAP_STRIKE_SEC)
		_queue_pose("keeper", "idle", 0.0)
	elif first_half and action == "salve" and result != "no_salve":
		_queue_pose("keeper", "idle", GAP_STRIKE_SEC)
	var i: int = log_before
	while i < _battle.turn_log.size():
		_enqueue_turn(_battle.turn_log[i])
		i += 1
	if first_half and action == "strike" and log_before == _battle.turn_log.size() and result == "defeat":
		_queue_pose("keeper", "attack", GAP_STRIKE_SEC)
		if _battle.last_keeper_damage > 0:
			_queue_pose("echo", "ko", HURT_HOLD_SEC)
			_queue_pose("echo", "idle", 0.0)
		_queue_pose("keeper", "idle", 0.0)


func _enqueue_turn(entry: Dictionary) -> void:
	var actor: String = str(entry.get("actor", ""))
	if actor != "keeper" and actor != "echo":
		return
	var damage: int = 0 if bool(entry.get("rootbind", false)) else int(entry.get("damage", 0))
	var target: String = "echo" if actor == "keeper" else "keeper"
	_queue_pose(actor, "attack", GAP_STRIKE_SEC)
	if damage > 0:
		var hurt: String = "hurt"
		if target == "echo" and _battle.echo_hp <= 0:
			hurt = "ko"
		elif target == "keeper" and _battle.keeper_hp <= 0:
			hurt = "ko"
		_queue_pose(target, hurt, HURT_HOLD_SEC)
		_queue_pose(target, "idle", 0.0)
	_queue_pose(actor, "idle", 0.0)


func _queue_pose(who: String, pose: String, hold: float) -> void:
	_pose_queue.append({"who": who, "pose": pose, "hold": hold})


func _begin_pose() -> void:
	_advance_pose()


func _advance_pose() -> void:
	if _pose_queue.is_empty():
		_on_half_shown()
		return
	var step: Dictionary = _pose_queue.pop_front()
	_apply_combat_pose(str(step.get("who", "")), str(step.get("pose", "idle")))
	_pose_left = float(step.get("hold", 0.0))
	if _pose_left <= 0.0:
		_advance_pose()


func _on_half_shown() -> void:
	if _battle != null and _battle.pending_half() != "":
		var log_before: int = _battle.turn_log.size()
		var result: String = _battle.finish_presented_half()
		_refresh_bars(true)
		_refresh_log()
		_enqueue_half("", log_before, false, result)
		if not _pose_queue.is_empty():
			_advance_pose()
			return
	_settle_turn()


func _drain_poses() -> void:
	while not _pose_queue.is_empty():
		var step: Dictionary = _pose_queue.pop_front()
		_apply_combat_pose(str(step.get("who", "")), str(step.get("pose", "idle")))
	_pose_left = 0.0


func _finish_pose_queue() -> void:
	if not _turn_busy:
		return
	_turn_busy = false
	_drain_poses()
	while _battle != null and _battle.pending_half() != "":
		var log_before: int = _battle.turn_log.size()
		var result: String = _battle.finish_presented_half()
		_refresh_bars(true)
		_refresh_log()
		_enqueue_half("", log_before, false, result)
		_drain_poses()
	_settle_turn()


func _settle_turn() -> void:
	_turn_busy = false
	_pose_queue.clear()
	_pose_left = 0.0
	if _battle == null:
		return
	var action: String = _pose_action
	var before_echo: int = _pose_echo_hp
	var outcome: String = _battle.outcome
	if action == "strike" and _battle.last_keeper_damage == 0 and before_echo == _battle.echo_hp and outcome == "":
		_set_speech(ContentStrings.get_text("battle_log_fists"))
	if outcome == "ko":
		_apply_combat_pose("keeper", "ko")
		EchoChamber.finish_battle("ko")
		return
	_refresh_bars(true)
	_refresh_log()
	_apply_combat_pose("keeper", "idle")
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
	_set_speech(ContentStrings.get_text("battle_your_turn"))
	_refresh_actions()


func _portrait_for(who: String) -> TextureRect:
	return _keeper_portrait if who == "keeper" else _echo_portrait


func _apply_combat_pose(who: String, pose: String) -> void:
	var rect: TextureRect = _portrait_for(who)
	if rect == null:
		return
	if pose == "idle":
		if who == "echo":
			var idle_path: String = _echo_idle_path()
			var idle_tex: Texture2D = load(idle_path) as Texture2D
			if idle_tex:
				rect.texture = idle_tex
			_mirror_portrait(rect, false)
			return
		var keeper_idle: Texture2D = load(KEEPER_IDLE) as Texture2D
		if keeper_idle:
			rect.texture = keeper_idle
		_mirror_portrait(rect, false)
		return
	var path: String = _party_pose_path(who, pose)
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		rect.texture = tex
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	## East sheets face right. The Echo stands on the right, so flip about the
	## midline (source x=64 on a 128px sheet drawn in the 256px portrait).
	_mirror_portrait(rect, who == "echo")


func _echo_idle_path() -> String:
	if _is_bramble():
		if _battle != null and _battle.foe_art_path != "":
			return _battle.foe_art_path
		return PARTY_DIR + "battle_bramble_idle_e.png"
	return ELAIA_IDLE


func _party_pose_path(who: String, pose: String) -> String:
	var sheet: String = pose
	if sheet != "attack" and sheet != "brace" and sheet != "hurt" and sheet != "ko":
		sheet = "attack"
	if who == "keeper":
		return PARTY_DIR + "battle_keeper_%s.png" % sheet
	if _is_bramble():
		return PARTY_DIR + "battle_bramble_%s.png" % sheet
	return PARTY_DIR + "battle_elaia_%s.png" % sheet


func _mirror_portrait(rect: TextureRect, flip: bool) -> void:
	if rect == null:
		return
	var span: Vector2 = rect.size
	if span.x < 1.0:
		span = PORTRAIT
	rect.pivot_offset = span * 0.5
	rect.scale = Vector2(-1.0, 1.0) if flip else Vector2.ONE


func _offer_return(outcome: String) -> void:
	_waiting_return = true
	_pending_outcome = outcome
	_set_mercy_visible(false)
	_pending_toast = _outcome_toast(outcome)
	_set_speech(_flavour_for_outcome(outcome))
	_strike.visible = false
	_flee.visible = false
	_spare.visible = false
	if _arrow:
		_arrow.visible = false
	if _ability_btn:
		_ability_btn.visible = false
	if _brace_btn:
		_brace_btn.visible = false
	if _salve_btn:
		_salve_btn.visible = false
	if _log:
		_log.text = _pending_toast
	## Flee uses the hub You Fled window. Spare and defeat use the ink rewards window.
	_return_btn.visible = false
	if outcome == "flee":
		_show_fled_window()
		return
	_show_rewards(outcome)


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
				parts.append(ContentStrings.get_text("battle_shards_gain", {"amount": EchoChamber.snapshot_payout("spare")}))
			"defeat":
				parts.append(ContentStrings.get_text("adventure_echo2_toast_defeat"))
				parts.append(ContentStrings.get_text("battle_shards_gain", {"amount": EchoChamber.snapshot_payout("defeat")}))
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
func _show_rewards(outcome: String) -> void:
	_clear_rewards()
	if _speech_box:
		_speech_box.visible = false
	var menu: CanvasItem = get_node_or_null("EchoActionMenu") as CanvasItem
	if menu:
		menu.visible = false
	if _close_btn:
		_close_btn.visible = false
	var dim := ColorRect.new()
	dim.name = "EchoRewardsDim"
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var ox: float = EchoTheme.shift()
	var panel := Panel.new()
	panel.name = "EchoRewards"
	## Mockup card x200..760, y40..498. 458 is off the 40+8n tile; 464 is the next fit.
	panel.position = Vector2(ox + 200.0, 40.0 + Ui540.center_shift_y())
	panel.size = Vector2(560, 464)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	EchoTheme.paint_panel(panel, false)
	## The ink fill is opaque. The dim behind it is the dark backdrop.
	panel.self_modulate.a = 1.0
	add_child(panel)
	dim.move_to_front()
	panel.move_to_front()
	## The title plank starts at y26, above this card. Hide it so the dim is what shows.
	if _title_plate:
		_title_plate.visible = false
	_refresh_status_chip()
	var title := Label.new()
	title.name = "RewardsTitle"
	title.text = "Echo Spared" if outcome == "spare" else "Echo Defeated"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	## Screen centre y75 is local y35. Keep the label clear of the × at local x493.
	title.position = Vector2(80, 15)
	title.size = Vector2(400, 40)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_title(title, true)
	panel.add_child(title)
	var close := Button.new()
	close.name = "RewardsClose"
	## Screen 693..735, y55..97.
	close.position = Vector2(493, 15)
	close.size = Vector2(42, 42)
	close.custom_minimum_size = close.size
	EchoTheme.paint_button(close, true)
	var x_icon := TextureRect.new()
	x_icon.name = "CloseGlyph"
	x_icon.texture = load(EchoTheme.ART + "icon_close_x_24.png")
	x_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	x_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	x_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	x_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	x_icon.position = Vector2(13, 13)
	x_icon.size = Vector2(16, 16)
	close.add_child(x_icon)
	close.pressed.connect(_on_return)
	panel.add_child(close)
	var flavour := Label.new()
	flavour.name = "RewardsFlavour"
	flavour.text = _flavour_for_outcome(outcome)
	flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	## Screen y118. Rows start at local y150, so the line stays above them.
	flavour.position = Vector2(48, 78)
	var flavour_w: float = panel.size.x - 96.0
	var flavour_font: Font = load(EchoTheme.BODY_FONT) as Font
	var flavour_lines: int = 1
	if flavour_font != null and flavour.text != "":
		var measured: Vector2 = flavour_font.get_multiline_string_size(flavour.text, HORIZONTAL_ALIGNMENT_LEFT, flavour_w, EchoTheme.BODY_SIZE)
		flavour_lines = maxi(1, int(ceil(measured.y / flavour_font.get_height(EchoTheme.BODY_SIZE))))
	flavour.size = Vector2(flavour_w, minf(22.0 * flavour_lines, 64.0))
	flavour.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(flavour, true)
	panel.add_child(flavour)
	var rows: Array = _reward_rows(outcome)
	## Screen x228..732 (local 28, width 504), y190+50i, 44 tall.
	var row_w: float = 504.0
	for row_i: int in rows.size():
		var spec: Array = rows[row_i]
		var row := Panel.new()
		row.name = "RewardRow%d" % row_i
		row.position = Vector2(28, 150.0 + row_i * 50.0)
		row.size = Vector2(row_w, 44)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		EchoTheme.paint_panel(row, true)
		row.self_modulate.a = 1.0
		panel.add_child(row)
		var left := Label.new()
		left.name = "Label"
		left.text = str(spec[0])
		left.position = Vector2(16, 10)
		left.size = Vector2(270, 24)
		left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		EchoTheme.style_body(left, false)
		row.add_child(left)
		var right := Label.new()
		right.name = "Value"
		right.text = str(spec[1])
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		right.position = Vector2(290, 10)
		right.size = Vector2(row_w - 306.0, 24)
		right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		EchoTheme.style_body(right, false)
		right.add_theme_color_override("font_color", _reward_value_color(str(spec[2]) if spec.size() > 2 else "pearl"))
		row.add_child(right)
	var footer := Label.new()
	footer.name = "RewardsFooter"
	footer.text = ContentStrings.get_text("echo_rewards_footer")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	## Screen y401 on a four-row card. Local 150 + n*50 + 11.
	footer.position = Vector2(48, 150.0 + rows.size() * 50.0 + 11.0)
	footer.size = Vector2(panel.size.x - 96.0, 22)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EchoTheme.style_body(footer, true)
	panel.add_child(footer)
	var back := Button.new()
	back.name = "RewardsReturn"
	back.text = ContentStrings.get_text("battle_return")
	## Screen x328..632, y422..478.
	back.position = Vector2(128, 382)
	back.size = Vector2(304, 56)
	back.custom_minimum_size = Vector2(304, 56)
	EchoTheme.paint_button(back, true)
	back.pressed.connect(_on_return)
	panel.add_child(back)
	back.call_deferred("grab_focus")
	Ui540.hide_name_tags_under(panel)


func _reward_value_color(tone: String) -> Color:
	## Gold stays on focus, the page arrow, and the mercy banner.
	if tone == "cyan":
		return EchoTheme.CYAN
	if tone == "amber":
		return EchoTheme.AMBER
	return EchoTheme.PEARL


func _reward_rows(outcome: String) -> Array:
	if _is_bramble():
		var bramble_shards: int = EchoChamber.snapshot_payout(outcome)
		## The reward row already names Manashards. The story line must not say it again.
		var story: String = _pending_toast
		var shards_line: String = ContentStrings.get_text("battle_shards_gain", {"amount": bramble_shards})
		story = story.replace("\n" + shards_line, "").replace(shards_line, "").strip_edges()
		return [
			[ContentStrings.get_text("hud_manashards"), "+%d" % bramble_shards, "cyan"],
			[story, "", "pearl"],
		]
	var shards: int = EchoChamber.snapshot_payout(outcome)
	var rows: Array = [
		[ContentStrings.get_text("hud_manashards"), "+%d" % shards, "cyan"],
		[
			"Forge Key (relic)",
			"+1 %s  +1 %s" % [ContentStrings.get_text("stat_swiftness"), ContentStrings.get_text("stat_fate")],
			"amber",
		],
		["Relic niche", "unlocked", "pearl"],
	]
	if outcome == "spare":
		rows.append([_enemy_name(), "redeemed", "pearl"])
	return rows


func _clear_rewards() -> void:
	for node_name: String in ["EchoRewardsDim", "EchoRewards"]:
		var node: Node = get_node_or_null(node_name)
		if node:
			node.free()
	if _title_plate:
		_title_plate.visible = true
	_refresh_status_chip()


const ECHO_FLED_H: float = 380.0
const ECHO_FLED_ART: String = "res://assets/ui/extras/fled_art_120x72.png"
const ECHO_FLED_WARN: String = "res://assets/ui/extras/icon_warn_amber_kit_18x16.png"


func _show_fled_window() -> void:
	_clear_fled_window()
	## The chamber × and the ink log band sit outside this hub window.
	if _close_btn:
		_close_btn.visible = false
	var menu: CanvasItem = get_node_or_null("EchoActionMenu") as CanvasItem
	if menu:
		menu.visible = false
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
		_strike_focused = false
		_hide_fight_chrome()
		_show_chamber_chrome()
		_refresh_status_chip()
		return
	if _phase == "speech":
		_strike_focused = false
		_ensure_echo_menu()
		_lock_menu()
		_refresh_log()
		_refresh_status_chip()
		return
	_ensure_echo_menu()
	var actions: PackedStringArray = _battle.available_actions()
	_offer_slot(_strike, actions.has("strike"), ContentStrings.get_text("battle_strike"))
	_offer_slot(_flee, actions.has("flee"), ContentStrings.get_text("battle_flee"))
	_offer_slot(_spare, actions.has("spare"), ContentStrings.get_text("battle_spare"))
	_offer_slot(_brace_btn, actions.has("brace"), "Brace")
	if _ability_btn:
		_ability_btn.visible = true
		_ability_btn.disabled = not BattleView.keeper_abilities_exist()
		_paint_slot_dim(_ability_btn, _ability_btn.disabled)
		_ability_btn.text = "Ability"
	if _salve_btn:
		var left: int = _battle.salves_left()
		_salve_btn.visible = true
		_salve_btn.disabled = left <= 0 or not actions.has("salve") or _waiting_return
		_paint_slot_dim(_salve_btn, _salve_btn.disabled)
		_salve_btn.text = "Salve %d" % left
	_return_btn.visible = false
	if _arrow:
		var hybrid: bool = _battle.strike_kind == "hybrid" and _battle.outcome == "" and _phase == "fight"
		_arrow.visible = hybrid
		_arrow.disabled = not hybrid or _waiting_return
		_paint_slot_dim(_arrow, _arrow.disabled)
		if hybrid:
			var magical: bool = _battle.arrow_mode == "magical"
			_arrow.text = ContentStrings.get_text("battle_toggle_mag" if magical else "battle_toggle_phys")
			_arrow.tooltip_text = ContentStrings.get_text("battle_mode_hint")
	_refresh_log()
	_refresh_status_chip()
	if not _strike_focused and _offered(_strike):
		_strike_focused = true
		_strike.grab_focus.call_deferred()


func _lock_menu() -> void:
	var hybrid: bool = _battle != null and _battle.strike_kind == "hybrid"
	for btn: Button in [_strike, _ability_btn, _salve_btn, _brace_btn, _flee, _spare, _arrow]:
		if btn == null:
			continue
		## A physical Strike is the full slot. The Phy chip would cover its label.
		btn.visible = btn != _arrow or hybrid
		btn.disabled = true
		_paint_slot_dim(btn, true)


func _offer_slot(btn: Button, on: bool, label: String) -> void:
	if btn == null:
		return
	btn.visible = _phase == "fight"
	btn.disabled = not on or _waiting_return
	_paint_slot_dim(btn, btn.disabled)
	if label != "":
		btn.text = label


func _paint_slot_dim(btn: Button, dim: bool) -> void:
	if btn == null:
		return
	btn.modulate = Color(0.45, 0.55, 0.55, 1) if dim else Color.WHITE
	## The badge art is brighter than the disabled face, so it needs its own dim.
	var badge := Color(0.38, 0.42, 0.42, 1) if dim else Color.WHITE
	for node_name: String in ["Keycap", "KeycapPlate"]:
		var node: CanvasItem = btn.get_node_or_null(node_name) as CanvasItem
		if node:
			node.modulate = badge


func _refresh_bars(flash: bool) -> void:
	if _battle == null:
		return
	var keeper_ratio: float = float(_battle.keeper_hp) / float(maxi(1, _battle.keeper_max_hp))
	var echo_ratio: float = float(_battle.echo_hp) / float(maxi(1, _battle.echo_max_hp))
	var keeper_w: float = 176.0 if _keeper_hp_fill != null and _keeper_hp_fill.get_parent() is NinePatchRect else PORTRAIT.x
	var echo_w: float = 176.0 if _echo_hp_fill != null and _echo_hp_fill.get_parent() is NinePatchRect else PORTRAIT.x
	if _keeper_hp_fill:
		_keeper_hp_fill.size = Vector2(keeper_w * clampf(keeper_ratio, 0.0, 1.0), 10.0 if keeper_w == 176.0 else 14.0)
		if keeper_w == 176.0:
			_keeper_hp_fill.color = EchoTheme.AMBER if keeper_ratio < 0.35 else EchoTheme.CYAN
	if _echo_hp_fill:
		_echo_hp_fill.size = Vector2(echo_w * clampf(echo_ratio, 0.0, 1.0), 10.0 if echo_w == 176.0 else 14.0)
		if echo_w == 176.0:
			_echo_hp_fill.color = EchoTheme.KOI
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
	var header: CanvasItem = get_node_or_null("EchoActionMenu/EchoLog/LogHeader") as CanvasItem
	var in_menu: bool = _log.get_parent() != null and _log.get_parent().name == "EchoLog"
	if _phase == "speech":
		if header:
			header.visible = false
		if in_menu:
			_log.position = Vector2(8, 8)
			_log.size = Vector2(396, 84)
		var page_no: int = _page_i + 1
		var page_total: int = maxi(1, _pages.size())
		_log.text = "%s\n%s" % [
			ContentStrings.get_text("echo_speech_hint"),
			ContentStrings.get_text("echo_speech_page", {
				"page": page_no,
				"pages": page_total,
				"chars": page_text().length(),
			}),
		]
		return
	if header:
		header.visible = true
	if in_menu:
		_log.position = Vector2(8, 24)
		_log.size = Vector2(396, 68)
	if _phase != "fight":
		return
	var lines: PackedStringArray = _battle.log
	var start: int = maxi(0, lines.size() - 3)
	var shown: PackedStringArray = PackedStringArray()
	for i: int in range(start, lines.size()):
		shown.append(lines[i])
	if shown.is_empty():
		shown.append(ContentStrings.get_text("battle_your_turn"))
	_log.text = "\n".join(shown)


