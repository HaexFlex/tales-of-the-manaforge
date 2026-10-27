extends CanvasLayer
class_name PauseMenu
## Mid-game pause: ESC / HUD Pause. PROCESS_MODE_ALWAYS so ESC works while paused.
## Options → Audio: Music / SFX volume sliders (persist via GameAudio settings).

const Binds := preload("res://scripts/ui/input_binds.gd")

signal status_toast(text: String)
signal new_game_started
signal game_loaded
signal standalone_load_requested(slot: int, kind: String)

enum SlotMode { NONE, SAVE, LOAD }

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/Title
@onready var btn_resume: Button = $Panel/BtnResume
@onready var btn_new_game: Button = $Panel/BtnNewGame
@onready var btn_save: Button = $Panel/BtnSave
@onready var btn_load: Button = $Panel/BtnLoad
@onready var btn_options: Button = $Panel/BtnOptions
@onready var btn_exit: Button = $Panel/BtnExit
var btn_quit_game: Button
@onready var slots_panel: Control = $SlotsPanel
@onready var slots_title: Label = $SlotsPanel/SlotsTitle
@onready var slot_scroll: ScrollContainer = $SlotsPanel/SlotScroll
@onready var slot_buttons: VBoxContainer = $SlotsPanel/SlotScroll/SlotButtons
@onready var slots_back: Button = $SlotsPanel/SlotsBack
@onready var confirm_panel: Control = $ConfirmPanel
@onready var confirm_label: Label = $ConfirmPanel/ConfirmLabel
@onready var confirm_yes: Button = $ConfirmPanel/ConfirmYes
@onready var confirm_no: Button = $ConfirmPanel/ConfirmNo
@onready var options_panel: Control = $OptionsPanel
@onready var options_title: Label = $OptionsPanel/OptionsTitle
@onready var options_hint: Label = $OptionsPanel/OptionsHint
@onready var options_controls: Label = $OptionsPanel/OptionsControls
@onready var music_label: Label = $OptionsPanel/MusicLabel
@onready var music_slider: HSlider = $OptionsPanel/MusicSlider
@onready var sfx_label: Label = $OptionsPanel/SfxLabel
@onready var sfx_slider: HSlider = $OptionsPanel/SfxSlider
@onready var options_reset: Button = $OptionsPanel/OptionsReset
@onready var options_close: Button = $OptionsPanel/OptionsClose

var _open: bool = false
var standalone: bool = false
## Title screen owns ESC. Do not open the in-game pause from that scene.
var suppress_pause_hotkey: bool = false
var _slot_mode: int = SlotMode.NONE
var _confirm_action: StringName = &""
var _pending_slot: int = 0
var _slot_btns: Array[Button] = []
var _audio_sliders_ready: bool = false
var _options_tab: String = "audio"
var _rebind_listen: String = ""
var _rebind_pending_key: int = 0
var _rebind_pending_other: String = ""
var _return_to_options: bool = false
var _return_to_slots: bool = false
var _slot_tab: String = "manual"
var _pending_kind: String = ""
var _master_slider: HSlider

const PAUSE_BTN_W: float = 200.0
const PAUSE_BTN_H: float = 44.0
const PAUSE_BTN_GAP: float = 8.0
const PAUSE_PAD_X: float = 36.0
const PAUSE_PAD_TOP: float = 28.0
const OPTIONS_W: float = 560.0
const SLOTS_W: float = 640.0
const SLOTS_H: float = 368.0
const CONFIRM_TITLES: Dictionary = {
	&"new_game": "pause_new_game_confirm_title",
	&"exit": "pause_exit_confirm_title",
	&"quit": "pause_quit_game_confirm_title",
	&"overwrite": "pause_slot_overwrite_title",
	&"load_slot": "pause_slot_load_title",
	&"rebind_swap": "options_rebind_conflict_title",
	&"delete_slot": "pause_slot_delete_title",
}
const OPTIONS_ROW_H: float = 44.0
const OPTIONS_LABEL_W: float = 96.0
const OPTIONS_PCT_W: float = 52.0
const OPTIONS_CONTENT_TOP: float = 72.0 + 44.0 + 8.0 + 14.0


func _touch_help_keys() -> PackedStringArray:
	return PackedStringArray([
		"options_touch_pause",
		"help_touch_tap",
		"help_touch_double_tap",
		"help_touch_long_press",
		"help_touch_drag",
		"help_touch_pinch",
		"help_touch_box",
	])


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	visible = false
	backdrop.visible = false
	panel.visible = false
	slots_panel.visible = false
	confirm_panel.visible = false
	options_panel.visible = false
	backdrop.color = Color(0, 0, 0, 0.5)
	_apply_pause_kit_chrome()
	_layout_pause_menu()
	if not get_viewport().size_changed.is_connected(_layout_pause_menu):
		get_viewport().size_changed.connect(_layout_pause_menu)
	_apply_strings()
	btn_resume.pressed.connect(resume_game)
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	slots_back.pressed.connect(_on_slots_back)
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_no.pressed.connect(_on_confirm_no)
	options_close.pressed.connect(_on_options_close)
	options_reset.pressed.connect(_on_options_reset)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_slider.drag_ended.connect(_on_volume_drag_ended)
	sfx_slider.drag_ended.connect(_on_volume_drag_ended)
	_audio_sliders_ready = true
	_sync_audio_sliders_from_game()
	_build_slot_buttons()
	_ensure_speedup_toggle()
	_ensure_photo_mode_button()
	_ensure_options_chrome()


func _apply_pause_kit_chrome() -> void:
	for kit_panel: Dictionary in [
		{"root": panel, "id": "pause", "frame": panel.get_node_or_null("Frame") as Panel},
		{"root": slots_panel, "id": "save_load", "frame": slots_panel.get_node_or_null("Frame") as Panel},
		{"root": confirm_panel, "id": "confirm", "frame": confirm_panel.get_node_or_null("Frame") as Panel},
		{"root": options_panel, "id": "options", "frame": options_panel.get_node_or_null("Frame") as Panel},
	]:
		var frame: Panel = kit_panel.frame as Panel
		if frame:
			Ui540.apply_kit_frame_panel(frame, str(kit_panel.id))
			frame.mouse_filter = Control.MOUSE_FILTER_STOP
	for lbl: Label in [title_label, slots_title, options_title]:
		if lbl:
			GameTheme.style_plank_label(lbl)
	for btn: Button in [btn_resume, btn_new_game, btn_save, btn_load, btn_options, btn_exit, options_reset, options_close]:
		GameTheme.style_menu_button(btn)
	GameTheme.style_menu_button(slots_back)
	GameTheme.style_ink_label(options_hint, true)
	GameTheme.style_ink_label(options_controls, true)
	for lbl: Label in [music_label, sfx_label]:
		GameTheme.style_ink_label(lbl)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for lbl: Label in [options_hint, options_controls]:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for slider: HSlider in [music_slider, sfx_slider]:
		slider.custom_minimum_size = Vector2.ZERO
		slider.value_changed.connect(_refresh_volume_pct.unbind(1))


## A kit window here is a Control root plus a Frame panel; both take the content size.
func _fit_window(root: Control, sz: Vector2) -> void:
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.custom_minimum_size = Vector2.ZERO
	root.size = sz
	var frame: Panel = root.get_node_or_null("Frame") as Panel
	if frame:
		frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
		frame.position = Vector2.ZERO
		frame.size = sz
	Ui540.center_kit_panel(root)


func _ensure_quit_game_button() -> void:
	if btn_quit_game != null and is_instance_valid(btn_quit_game):
		Ui540.hide_on_phone(btn_quit_game)
		return
	btn_quit_game = Button.new()
	btn_quit_game.name = "BtnQuitGame"
	btn_quit_game.text = "Quit Game"
	GameTheme.style_menu_button(btn_quit_game)
	btn_quit_game.pressed.connect(_on_quit_game_pressed)
	panel.add_child(btn_quit_game)
	Ui540.hide_on_phone(btn_quit_game)


func _on_quit_game_pressed() -> void:
	if _echo_pause_holds():
		return
	_show_confirm(
		&"quit",
		ContentStrings.get_text("pause_quit_game_confirm"),
		ContentStrings.get_text("pause_quit_game_confirm_yes"),
		ContentStrings.get_text("pause_quit_game_confirm_no"),
	)


func _notify_pause_button() -> void:
	var hud: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() != null else null
	if hud != null and hud.has_method("hold_pause_button_over_dim"):
		hud.call("hold_pause_button_over_dim", _open)


func _layout_pause_menu() -> void:
	_ensure_photo_mode_button()
	_ensure_quit_game_button()
	btn_new_game.visible = false
	var photo_btn: Button = panel.get_node_or_null("BtnPhotoMode") as Button
	var btns: Array[Button] = [btn_resume, btn_save, btn_load, btn_options]
	if photo_btn != null:
		btns.append(photo_btn)
	btns.append(btn_exit)
	if btn_quit_game != null and btn_quit_game.visible:
		btns.append(btn_quit_game)
	var n: int = btns.size()
	var btn_w: float = PAUSE_BTN_W
	for btn: Button in btns:
		btn_w = maxf(btn_w, ceilf(Ui540._button_text_w(btn)) + 40.0)
	var ww: float = btn_w + PAUSE_PAD_X * 2.0
	_fit_window(panel, Vector2(ww, PAUSE_PAD_TOP + n * PAUSE_BTN_H + float(n - 1) * PAUSE_BTN_GAP + 24.0))
	var y: float = PAUSE_PAD_TOP
	for btn: Button in btns:
		Ui540.anchor_rect_safe(btn, PAUSE_PAD_X, y, btn_w, PAUSE_BTN_H)
		Ui540.fit_button_font(btn, btn_w)
		y += PAUSE_BTN_H + PAUSE_BTN_GAP
	Ui540.place_title_plank(title_label, ww)
	_layout_options()
	_layout_slots()


func _slot_bevel() -> Panel:
	var bevel: Panel = slots_panel.get_node_or_null("SlotBevel") as Panel
	if bevel == null:
		bevel = Panel.new()
		bevel.name = "SlotBevel"
		bevel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bevel.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s("res://assets/ui/theme/play_bevel_9s_6x6.png", Vector4i(2, 2, 2, 2)))
		slots_panel.add_child(bevel)
		slots_panel.move_child(bevel, slot_scroll.get_index())
	return bevel


## Manual | Autosaves. The list is 44 px rows. Close is the kit ×, not a text Back.
func _layout_slots() -> void:
	var sz := Vector2(SLOTS_W, minf(SLOTS_H, Ui540.max_window_h()))
	_fit_window(slots_panel, sz)
	Ui540.place_title_plank(slots_title, sz.x)
	_ensure_slot_tabs()
	var tab_y: float = 72.0
	var tab_h: float = 36.0
	var tab_w: float = 160.0
	for i: int in 2:
		var node_name: String = "TabManual" if i == 0 else "TabAutosave"
		var tab: Button = slots_panel.get_node_or_null(node_name) as Button
		if tab == null:
			continue
		var x: float = 36.0 + float(i) * (tab_w + 8.0)
		Ui540.anchor_rect_safe(tab, x, tab_y, tab_w, tab_h)
		var selected: bool = (i == 0 and _slot_tab == "manual") or (i == 1 and _slot_tab == "autosave")
		tab.set_pressed_no_signal(selected)
		_paint_slot_tab(tab, selected)
	var rule: ColorRect = slots_panel.get_node_or_null("SlotTabRule") as ColorRect
	if rule:
		var rule_x: float = 36.0 if _slot_tab == "manual" else 36.0 + tab_w + 8.0
		rule.color = Color8(232, 176, 48)
		Ui540.anchor_rect_safe(rule, rule_x, tab_y + tab_h - 2.0, tab_w, 6.0)
	var list_y: float = tab_y + tab_h + 12.0
	var list_h: float = sz.y - list_y - 24.0
	Ui540.anchor_rect_safe(_slot_bevel(), 36, list_y, sz.x - 72.0, list_h)
	Ui540.anchor_rect_safe(slot_scroll, 38, list_y + 2.0, sz.x - 76.0, list_h - 4.0)
	slots_back.visible = false
	var closer: Button = slots_panel.get_node_or_null("SlotsClose") as Button
	if closer:
		Ui540.configure_kit_close_button(closer)
		Ui540.place_close_button(closer, sz.x)


## options540: Audio & Display / Gameplay / Controls. The × sits in the title row.
## Reset stays in the scene for older callers and is not shown.
func _layout_options() -> void:
	if options_panel == null:
		return
	_ensure_options_chrome()
	var w: float = OPTIONS_W
	var inner: float = w - PAUSE_PAD_X * 2.0
	Ui540.configure_kit_close_button(options_close)
	Ui540.place_close_button(options_close, w)
	options_reset.visible = false
	if options_controls:
		options_controls.visible = false
	var tab_y: float = 72.0
	var tab_h: float = 44.0
	_layout_option_tabs(tab_y, tab_h, inner)
	var y: float = tab_y + tab_h + 8.0
	var rule: ColorRect = options_panel.get_node_or_null("TabRule") as ColorRect
	if rule:
		Ui540.anchor_rect_safe(rule, PAUSE_PAD_X, y, inner, 2.0)
	y += 14.0
	var show_audio: bool = _options_tab == "audio"
	var show_play: bool = _options_tab == "gameplay"
	var show_keys: bool = _options_tab == "controls"
	var phone: bool = Ui540.is_phone_export()
	y = _layout_audio_page(y, inner, w, show_audio, phone)
	y = _layout_gameplay_page(y, inner, show_play)
	y = _layout_controls_page(y, inner, show_keys, phone or GameInput.touch_mode())
	var want: Vector2 = Vector2(w, y + 24.0)
	if phone or GameInput.touch_mode():
		## fit_kit_window assigns position. Centre anchors turn that into a 0-size window.
		options_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var fitted: Vector2 = Ui540.fit_kit_window(options_panel, want)
		var frame: Panel = options_panel.get_node_or_null("Frame") as Panel
		if frame:
			frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
			frame.position = Vector2.ZERO
			frame.size = fitted
	else:
		_fit_window(options_panel, want)
	Ui540.place_title_plank(options_title, w)


func _ensure_options_chrome() -> void:
	if options_panel == null or options_panel.get_node_or_null("TabAudio") != null:
		return
	var group := ButtonGroup.new()
	for spec: Array in [
		["TabAudio", "options_tab_audio", "audio"],
		["TabGameplay", "options_tab_gameplay", "gameplay"],
		["TabControls", "options_tab_controls", "controls"],
	]:
		var tab := Button.new()
		tab.name = str(spec[0])
		tab.text = ContentStrings.get_text(str(spec[1]))
		tab.toggle_mode = true
		tab.button_group = group
		tab.button_pressed = str(spec[2]) == _options_tab
		GameTheme.style_big_tab_button(tab)
		tab.pressed.connect(_on_options_tab.bind(str(spec[2])))
		options_panel.add_child(tab)
	var rule := ColorRect.new()
	rule.name = "TabRule"
	rule.color = Color(0.82, 0.64, 0.28, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_panel.add_child(rule)
	_master_slider = HSlider.new()
	_master_slider.name = "MasterSlider"
	_master_slider.min_value = 0.0
	_master_slider.max_value = 1.0
	_master_slider.step = 0.01
	_master_slider.value = GameAudio.master_volume_linear
	_master_slider.value_changed.connect(_on_master_slider_changed)
	_master_slider.drag_ended.connect(_on_volume_drag_ended)
	options_panel.add_child(_master_slider)
	var master_lbl := Label.new()
	master_lbl.name = "MasterLabel"
	master_lbl.text = ContentStrings.get_text("options_master_volume")
	GameTheme.style_ink_label(master_lbl)
	master_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	options_panel.add_child(master_lbl)
	var display := Control.new()
	display.name = "DisplayBlock"
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_panel.add_child(display)
	var full := CheckButton.new()
	full.name = "FullscreenToggle"
	full.text = ContentStrings.get_text("options_fullscreen")
	full.button_pressed = GameAudio.fullscreen_on
	full.toggled.connect(_on_fullscreen_toggled)
	_ink_check(full)
	display.add_child(full)
	var screen_lbl := Label.new()
	screen_lbl.name = "ScreenLabel"
	screen_lbl.text = ContentStrings.get_text("options_screen")
	GameTheme.style_ink_label(screen_lbl)
	screen_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display.add_child(screen_lbl)
	var screen_group := ButtonGroup.new()
	for spec2: Array in [["ScreenPixel", "options_screen_pixel", false], ["ScreenFill", "options_screen_fill", true]]:
		var chip := Button.new()
		chip.name = str(spec2[0])
		chip.text = ContentStrings.get_text(str(spec2[1]))
		chip.toggle_mode = true
		chip.button_group = screen_group
		chip.button_pressed = GameAudio.fill_screen == bool(spec2[2])
		GameTheme.style_tab_button(chip)
		chip.pressed.connect(_on_screen_mode.bind(bool(spec2[2])))
		display.add_child(chip)
	Ui540.hide_on_phone(display)
	for action: String in ["pause", "character", "inventory"]:
		var row := Button.new()
		row.name = "Rebind_%s" % action
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		GameTheme.style_ink_button(row)
		row.add_theme_font_override("font", GameTheme.body_font())
		row.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
		var empty_face := StyleBoxEmpty.new()
		for face_state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
			row.add_theme_stylebox_override(face_state, empty_face)
		for ink_state: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
		]:
			row.add_theme_color_override(ink_state, GameTheme.INK)
		row.set_meta("bind_action", action)
		row.pressed.connect(_on_rebind_pressed.bind(action))
		var key_lbl := Label.new()
		key_lbl.name = "Key"
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		GameTheme.style_ink_label(key_lbl, false)
		row.add_child(key_lbl)
		options_panel.add_child(row)
	_ensure_touch_help_scroll()
	_sync_touch_help_rows()
	_refresh_rebind_rows()


func _on_options_tab(tab_id: String) -> void:
	_options_tab = tab_id
	_rebind_listen = ""
	_layout_options()


func _layout_option_tabs(tab_y: float, tab_h: float, inner: float) -> void:
	var ids: PackedStringArray = PackedStringArray(["TabAudio", "TabGameplay", "TabControls"])
	var font: Font = load("res://assets/fonts/font_primary_silver38_bold.tres") as Font
	var widths: Array[float] = []
	var sum: float = 0.0
	for node_name: String in ids:
		var tab: Button = options_panel.get_node_or_null(node_name) as Button
		if tab == null:
			widths.append(0.0)
			continue
		tab.button_pressed = (
			(node_name == "TabAudio" and _options_tab == "audio")
			or (node_name == "TabGameplay" and _options_tab == "gameplay")
			or (node_name == "TabControls" and _options_tab == "controls")
		)
		var text_w: float = 120.0
		if font:
			text_w = ceilf(font.get_string_size(tab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x) + 28.0
		widths.append(text_w)
		sum += text_w
	var gap: float = 8.0
	var gaps: float = gap * float(ids.size() - 1)
	if sum + gaps > inner and sum > 0.0:
		var scale: float = (inner - gaps) / sum
		for i: int in widths.size():
			widths[i] = floorf(widths[i] * scale)
	var x: float = PAUSE_PAD_X
	for i: int in ids.size():
		var tab: Button = options_panel.get_node_or_null(ids[i]) as Button
		if tab == null:
			continue
		Ui540.anchor_rect_safe(tab, x, tab_y, widths[i], tab_h)
		if widths[i] < 80.0:
			Ui540.fit_button_font(tab, widths[i])
		x += widths[i] + gap


func _layout_audio_page(y: float, inner: float, w: float, show: bool, phone: bool) -> float:
	var body_font: Font = GameTheme.body_font()
	var line_h: float = body_font.get_height(GameTheme.BODY_SIZE)
	options_hint.visible = show
	if show:
		Ui540.anchor_rect_safe(options_hint, PAUSE_PAD_X, y, inner, line_h)
		y += line_h + 8.0
	var rows: Array = [
		[options_panel.get_node_or_null("MasterLabel"), _master_slider, "MasterPct"],
		[music_label, music_slider, "MusicPct"],
		[sfx_label, sfx_slider, "SfxPct"],
	]
	for pair: Array in rows:
		var lbl: Label = pair[0]
		var slider: HSlider = pair[1]
		if lbl == null or slider == null:
			continue
		lbl.visible = show
		slider.visible = show
		var pct: Label = _volume_pct_label(str(pair[2]))
		pct.visible = show
		if show:
			Ui540.anchor_rect_safe(lbl, PAUSE_PAD_X, y, OPTIONS_LABEL_W, OPTIONS_ROW_H)
			Ui540.anchor_rect_safe(slider, PAUSE_PAD_X + OPTIONS_LABEL_W, y + (OPTIONS_ROW_H - 24.0) * 0.5, inner - OPTIONS_LABEL_W - OPTIONS_PCT_W - 12.0, 24)
			Ui540.anchor_rect_safe(pct, w - PAUSE_PAD_X - OPTIONS_PCT_W, y, OPTIONS_PCT_W, OPTIONS_ROW_H)
			y += OPTIONS_ROW_H
	if show:
		_refresh_volume_pct()
	var display: Control = options_panel.get_node_or_null("DisplayBlock") as Control
	if display:
		var display_on: bool = show and not phone
		display.visible = display_on
		if display_on:
			var full: CheckButton = display.get_node_or_null("FullscreenToggle") as CheckButton
			var screen_lbl: Label = display.get_node_or_null("ScreenLabel") as Label
			if full:
				full.position = Vector2(PAUSE_PAD_X, y)
				full.size = Vector2(inner, OPTIONS_ROW_H)
				y += OPTIONS_ROW_H
			if screen_lbl:
				screen_lbl.position = Vector2(PAUSE_PAD_X, y)
				screen_lbl.size = Vector2(OPTIONS_LABEL_W, OPTIONS_ROW_H)
			var chip_x: float = PAUSE_PAD_X + OPTIONS_LABEL_W
			var chip_w: float = (inner - OPTIONS_LABEL_W - 8.0) * 0.5
			for node_name: String in ["ScreenPixel", "ScreenFill"]:
				var chip: Button = display.get_node_or_null(node_name) as Button
				if chip == null:
					continue
				chip.position = Vector2(chip_x, y)
				chip.size = Vector2(chip_w, OPTIONS_ROW_H)
				chip_x += chip_w + 8.0
			y += OPTIONS_ROW_H
	return y


func _layout_gameplay_page(y: float, inner: float, show: bool) -> float:
	var body_font: Font = GameTheme.body_font()
	var line_h: float = body_font.get_height(GameTheme.BODY_SIZE)
	var speed: CheckButton = options_panel.get_node_or_null("SpeedupToggle") as CheckButton
	if speed:
		speed.visible = show
		if show:
			Ui540.anchor_rect_safe(speed, PAUSE_PAD_X, y, inner, OPTIONS_ROW_H)
			y += OPTIONS_ROW_H
	var hint: Label = options_panel.get_node_or_null("SpeedupHint") as Label
	if hint:
		hint.visible = show
		if show:
			var lines: int = Ui540.text_line_count(hint.text, body_font, GameTheme.BODY_SIZE, inner)
			Ui540.anchor_rect_safe(hint, PAUSE_PAD_X, y, inner, line_h * float(lines))
			y += line_h * float(lines) + 8.0
	var debug_box: CheckButton = options_panel.get_node_or_null("DebugToolsToggle") as CheckButton
	if debug_box:
		debug_box.visible = show
		if show:
			Ui540.anchor_rect_safe(debug_box, PAUSE_PAD_X, y, inner, OPTIONS_ROW_H)
			y += OPTIONS_ROW_H
	var photo_btn: Button = options_panel.get_node_or_null("PhotoModeButton") as Button
	if photo_btn:
		photo_btn.visible = show
		if show:
			Ui540.anchor_rect_safe(photo_btn, PAUSE_PAD_X, y, inner, OPTIONS_ROW_H)
			y += OPTIONS_ROW_H
	var photo_hint: Label = options_panel.get_node_or_null("PhotoModeHint") as Label
	if photo_hint:
		photo_hint.visible = show
		if show:
			var photo_lines: int = Ui540.text_line_count(photo_hint.text, body_font, GameTheme.BODY_SIZE, inner)
			Ui540.anchor_rect_safe(photo_hint, PAUSE_PAD_X, y, inner, line_h * float(photo_lines))
			y += line_h * float(photo_lines) + 8.0
	return y


func _ensure_touch_help_scroll() -> void:
	if options_panel == null:
		return
	var scroll: ScrollContainer = options_panel.get_node_or_null("TouchHelpScroll") as ScrollContainer
	if scroll == null:
		scroll = ScrollContainer.new()
		scroll.name = "TouchHelpScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		scroll.visible = false
		options_panel.add_child(scroll)
		if has_node("/root/GameInput"):
			GameInput.configure_scroll_container(scroll)
	var touch: VBoxContainer = scroll.get_node_or_null("TouchHelp") as VBoxContainer
	if touch == null:
		touch = options_panel.get_node_or_null("TouchHelp") as VBoxContainer
		if touch != null and touch.get_parent() == options_panel:
			options_panel.remove_child(touch)
		if touch == null:
			touch = VBoxContainer.new()
			touch.name = "TouchHelp"
			touch.add_theme_constant_override("separation", 6)
		scroll.add_child(touch)


func _sync_touch_help_rows() -> void:
	var scroll: ScrollContainer = options_panel.get_node_or_null("TouchHelpScroll") as ScrollContainer if options_panel != null else null
	var touch: VBoxContainer = scroll.get_node_or_null("TouchHelp") as VBoxContainer if scroll != null else null
	if touch == null:
		return
	var keys: PackedStringArray = _touch_help_keys()
	if touch.get_child_count() == keys.size():
		var ok: bool = true
		for i: int in keys.size():
			var line: Node = touch.get_child(i)
			if str(line.get_meta(&"string_key", "")) != keys[i]:
				ok = false
				break
		if ok:
			for i: int in keys.size():
				var lbl: Label = touch.get_child(i) as Label
				if lbl != null:
					lbl.text = ContentStrings.get_text(keys[i])
			return
	for child: Node in touch.get_children():
		child.free()
	for key: String in keys:
		var line := Label.new()
		line.set_meta(&"string_key", key)
		line.text = ContentStrings.get_text(key)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		GameTheme.style_ink_label(line)
		touch.add_child(line)


func _layout_controls_page(y: float, inner: float, show: bool, phone: bool) -> float:
	_ensure_touch_help_scroll()
	_sync_touch_help_rows()
	for action: String in ["pause", "character", "inventory"]:
		var row: Button = options_panel.get_node_or_null("Rebind_%s" % action) as Button
		if row == null:
			continue
		var on: bool = show and not phone
		row.visible = on
		if on:
			Ui540.anchor_rect_safe(row, PAUSE_PAD_X, y, inner, OPTIONS_ROW_H)
			var key_lbl: Label = row.get_node_or_null("Key") as Label
			if key_lbl:
				key_lbl.position = Vector2(inner - 180.0, 0)
				key_lbl.size = Vector2(168.0, OPTIONS_ROW_H)
			y += OPTIONS_ROW_H + 4.0
	var touch_scroll: ScrollContainer = options_panel.get_node_or_null("TouchHelpScroll") as ScrollContainer
	var touch: VBoxContainer = touch_scroll.get_node_or_null("TouchHelp") as VBoxContainer if touch_scroll != null else null
	if touch_scroll != null and touch != null:
		var on_touch: bool = show and phone
		touch_scroll.visible = on_touch
		if on_touch:
			touch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for child: Node in touch.get_children():
				if child is Control:
					var row: Control = child as Control
					row.custom_minimum_size.x = inner
					row.size.x = inner
			touch.position = Vector2.ZERO
			touch.size = Vector2(inner, 0)
			touch_scroll.position = Vector2(PAUSE_PAD_X, y)
			var sep: float = float(touch.get_theme_constant(&"separation", &"VBoxContainer"))
			var natural_h: float = 0.0
			for i: int in touch.get_child_count():
				var row: Control = touch.get_child(i) as Control
				if row == null:
					continue
				if i > 0:
					natural_h += sep
				natural_h += row.get_minimum_size().y
			touch.custom_minimum_size = Vector2(inner, natural_h)
			var max_scroll_h: float = maxf(48.0, Ui540.max_window_h() - y - 24.0)
			var scroll_h: float = minf(natural_h, max_scroll_h)
			touch_scroll.size = Vector2(inner, scroll_h)
			y += scroll_h
	return y


func _refresh_rebind_rows() -> void:
	if options_panel == null:
		return
	for action: String in ["pause", "character", "inventory"]:
		var row: Button = options_panel.get_node_or_null("Rebind_%s" % action) as Button
		if row == null:
			continue
		row.text = ContentStrings.get_text("options_rebind_%s" % action)
		var key_lbl: Label = row.get_node_or_null("Key") as Label
		if key_lbl == null:
			continue
		if _rebind_listen == action:
			key_lbl.text = ContentStrings.get_text("options_rebind_listen")
		else:
			key_lbl.text = Binds.display(Binds.keycode(action))


func _on_rebind_pressed(action: String) -> void:
	_rebind_listen = action
	_refresh_rebind_rows()


func _offer_rebind(code: Key) -> void:
	if _rebind_listen == "" or int(code) <= 0:
		return
	var other: String = Binds.conflict(_rebind_listen, code)
	if other == "":
		Binds.set_keycode(_rebind_listen, code)
		_rebind_listen = ""
		_refresh_rebind_rows()
		return
	_rebind_pending_key = int(code)
	_rebind_pending_other = other
	_return_to_options = true
	var other_name: String = ContentStrings.get_text("options_rebind_%s" % other)
	_show_confirm(
		&"rebind_swap",
		ContentStrings.get_text("options_rebind_conflict", {"action": other_name}),
		ContentStrings.get_text("options_rebind_swap"),
		ContentStrings.get_text("options_rebind_cancel"),
	)


func _on_master_slider_changed(value: float) -> void:
	GameAudio.set_master_volume_linear(value)
	_refresh_volume_pct()


func _on_fullscreen_toggled(on: bool) -> void:
	GameAudio.set_fullscreen(on)


func _on_screen_mode(fill: bool) -> void:
	GameAudio.set_fill_screen(fill)


func _volume_pct_label(node_name: String) -> Label:
	var pct: Label = options_panel.get_node_or_null(node_name) as Label
	if pct == null:
		pct = Label.new()
		pct.name = node_name
		GameTheme.style_ink_label(pct)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		options_panel.add_child(pct)
	return pct


func _refresh_volume_pct() -> void:
	if options_panel == null:
		return
	for pair: Array in [["MasterPct", _master_slider], ["MusicPct", music_slider], ["SfxPct", sfx_slider]]:
		var pct: Label = options_panel.get_node_or_null(str(pair[0])) as Label
		var slider: HSlider = pair[1]
		if pct and slider:
			pct.text = "%d%%" % roundi(100.0 * (slider.value - slider.min_value) / maxf(0.001, slider.max_value - slider.min_value))


func _apply_strings() -> void:
	title_label.text = ContentStrings.get_text("pause_title")
	btn_resume.text = ContentStrings.get_text("pause_resume")
	btn_new_game.text = ContentStrings.get_text("pause_new_game")
	btn_save.text = ContentStrings.get_text("pause_save")
	btn_load.text = ContentStrings.get_text("pause_load")
	btn_options.text = ContentStrings.get_text("pause_options")
	var photo_pause: Button = panel.get_node_or_null("BtnPhotoMode") as Button
	if photo_pause:
		photo_pause.text = ContentStrings.get_text("pause_photo_mode_button")
	var photo_opt: Button = options_panel.get_node_or_null("PhotoModeButton") as Button if options_panel else null
	if photo_opt:
		photo_opt.text = ContentStrings.get_text("options_photo_mode_button")
	var photo_hint: Label = options_panel.get_node_or_null("PhotoModeHint") as Label if options_panel else null
	if photo_hint:
		photo_hint.text = ContentStrings.get_text("options_photo_mode_hint")
	btn_exit.text = ContentStrings.get_text("pause_exit")
	if btn_quit_game:
		btn_quit_game.text = ContentStrings.get_text("pause_quit_game")
	slots_back.text = ContentStrings.get_text("options_back")
	options_title.text = ContentStrings.get_text("options_title")
	options_hint.text = ContentStrings.get_text("options_audio_hint")
	var master_lbl: Label = options_panel.get_node_or_null("MasterLabel") as Label if options_panel else null
	if master_lbl:
		master_lbl.text = ContentStrings.get_text("options_master_volume")
	_refresh_rebind_rows()
	if options_controls:
		options_controls.text = "%s   ·   %s\n%s   ·   %s" % [
			ContentStrings.get_text("controls_lmb_select"),
			ContentStrings.get_text("controls_rmb_command"),
			ContentStrings.get_text("controls_lmb_deselect"),
			ContentStrings.get_text("controls_camera_pan"),
		]
	music_label.text = ContentStrings.get_text("options_music_volume")
	sfx_label.text = ContentStrings.get_text("options_sfx_volume")
	options_reset.text = ContentStrings.get_text("options_audio_reset")
	options_reset.visible = false
	if options_close:
		Ui540.configure_kit_close_button(options_close)


func _build_slot_buttons() -> void:
	_rebuild_slot_rows(false)


func _on_photo_mode_pressed() -> void:
	if PhotoMode.try_enter():
		resume_game()


func _ensure_photo_mode_button() -> void:
	if panel.get_node_or_null("BtnPhotoMode") != null:
		return
	var btn := Button.new()
	btn.name = "BtnPhotoMode"
	# Content & Lore: pause_photo_mode_button
	btn.text = ContentStrings.get_text("pause_photo_mode_button")
	GameTheme.style_menu_button(btn)
	btn.pressed.connect(_on_photo_mode_pressed)
	panel.add_child(btn)
	var opt_btn: Button = options_panel.get_node_or_null("PhotoModeButton") as Button
	if opt_btn == null and options_panel != null:
		opt_btn = Button.new()
		opt_btn.name = "PhotoModeButton"
		# Content & Lore: options_photo_mode_button
		opt_btn.text = ContentStrings.get_text("options_photo_mode_button")
		GameTheme.style_ink_button(opt_btn)
		opt_btn.pressed.connect(_on_photo_mode_pressed)
		options_panel.add_child(opt_btn)
		var hint := Label.new()
		hint.name = "PhotoModeHint"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		GameTheme.style_ink_label(hint, true)
		# Content & Lore: options_photo_mode_hint
		hint.text = ContentStrings.get_text("options_photo_mode_hint")
		options_panel.add_child(hint)


func _ensure_speedup_toggle() -> void:
	if options_panel == null or options_panel.get_node_or_null("SpeedupToggle") != null:
		return
	var box := CheckButton.new()
	box.name = "SpeedupToggle"
	box.text = ContentStrings.get_text("options_speedup_toggle")
	box.button_pressed = GameAudio.use_speedup_button
	box.toggled.connect(_on_speedup_toggled)
	options_panel.add_child(box)
	var hint := Label.new()
	hint.name = "SpeedupHint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameTheme.style_ink_label(hint, true)
	hint.text = ContentStrings.get_text("options_speedup_toggle_hint")
	options_panel.add_child(hint)
	if _debug_tools_available():
		var debug_box := CheckButton.new()
		debug_box.name = "DebugToolsToggle"
		debug_box.text = ContentStrings.get_text("options_debug_tools_toggle")
		debug_box.tooltip_text = "Ctrl+F8"
		debug_box.button_pressed = AnimPreviewHotkey.debug_panel_open()
		debug_box.toggled.connect(_on_debug_tools_toggled)
		options_panel.add_child(debug_box)
	for toggle: CheckButton in [box, options_panel.get_node_or_null("DebugToolsToggle") as CheckButton]:
		_ink_check(toggle)
	_layout_options()


func _ink_check(box: CheckButton) -> void:
	if box == null:
		return
	box.add_theme_font_override("font", GameTheme.body_font())
	box.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
	for ink_state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		box.add_theme_color_override(ink_state, GameTheme.INK)


func _debug_tools_available() -> bool:
	return AnimPreviewHotkey.debug_panel_available()


func _on_speedup_toggled(on: bool) -> void:
	GameAudio.set_use_speedup_button(on)


func _on_debug_tools_toggled(on: bool) -> void:
	AnimPreviewHotkey.set_debug_panel(on)


func sync_debug_toggle(open: bool) -> void:
	if options_panel == null:
		return
	var box: CheckButton = options_panel.get_node_or_null("DebugToolsToggle") as CheckButton
	if box:
		box.set_pressed_no_signal(open)


func open_load_standalone() -> void:
	standalone = true
	visible = true
	backdrop.visible = true
	panel.visible = false
	_hide_confirm()
	_hide_options()
	_slot_mode = SlotMode.LOAD
	_show_slots(ContentStrings.get_text("pause_load"))


func open_options_standalone() -> void:
	standalone = true
	visible = true
	backdrop.visible = true
	panel.visible = false
	_hide_slots()
	_hide_confirm()
	_apply_strings()
	_sync_audio_sliders_from_game()
	options_panel.visible = true
	GameAudio.play_ui_open()


func close_standalone() -> void:
	standalone = false
	_slot_mode = SlotMode.NONE
	_hide_slots()
	_hide_confirm()
	_hide_options()
	panel.visible = false
	backdrop.visible = false
	visible = false


func _expedition_board_open() -> bool:
	for node: Node in get_tree().get_nodes_in_group("expedition_board"):
		if node.has_method("shell_open") and bool(node.call("shell_open")):
			return true
	return false


func _close_expedition_board() -> void:
	for node: Node in get_tree().get_nodes_in_group("expedition_board"):
		if node.has_method("close_shell"):
			node.call("close_shell")
			return


## Android back and a synthesized ui_cancel. Escape still owns the keyboard path.
func dismiss_for_back() -> bool:
	if confirm_panel != null and confirm_panel.visible:
		_hide_confirm()
		return true
	if standalone:
		if (options_panel != null and options_panel.visible) or (slots_panel != null and slots_panel.visible):
			close_standalone()
			return true
		return false
	if options_panel != null and options_panel.visible:
		_hide_options()
		return true
	if slots_panel != null and slots_panel.visible:
		_hide_slots()
		return true
	if _open:
		resume_game()
		return true
	if _expedition_board_open():
		_close_expedition_board()
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if _rebind_listen != "" and event is InputEventKey and event.pressed and not event.echo:
		var listen: InputEventKey = event as InputEventKey
		if listen.keycode == KEY_ESCAPE:
			_rebind_listen = ""
			_refresh_rebind_rows()
		else:
			_offer_rebind(listen.keycode)
		get_viewport().set_input_as_handled()
		return
	## Keyboard Escape stays on the key path below, including opening pause.
	## A non-key ui_cancel (Android back) only closes a window that is already open.
	if event.is_action_pressed("ui_cancel") and not (event is InputEventKey):
		if dismiss_for_back():
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event
		var pause_key: bool = key.keycode == KEY_ESCAPE or Binds.event_matches(key, "pause")
		if pause_key:
			if suppress_pause_hotkey and not standalone:
				return
			if standalone:
				if confirm_panel.visible:
					_hide_confirm()
				elif options_panel.visible or slots_panel.visible:
					close_standalone()
					GameAudio.play_ui_cancel()
				get_viewport().set_input_as_handled()
				return
			if confirm_panel.visible:
				_hide_confirm()
			elif options_panel.visible:
				_hide_options()
			elif slots_panel.visible:
				_hide_slots()
			elif _open:
				resume_game()
			else:
				var hud: Node = get_tree().get_first_node_in_group("game_hud")
				if hud != null and hud.has_method("is_character_open") and bool(hud.call("is_character_open")):
					hud.call("close_character_sheet")
				elif hud != null and hud.has_method("is_bench_open") and bool(hud.call("is_bench_open")):
					hud.call("close_bench")
				elif hud != null and hud.has_method("is_backpack_open") and bool(hud.call("is_backpack_open")):
					hud.call("close_backpack")
				elif hud != null and hud.has_method("offline_summary_open") and bool(hud.call("offline_summary_open")):
					hud.call("dismiss_offline_summary")
				elif _expedition_board_open():
					_close_expedition_board()
				else:
					open_pause()
			get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _open


func open_pause() -> void:
	if _open:
		return
	_open = true
	_apply_strings()
	_hide_slots()
	_hide_confirm()
	_hide_options()
	_layout_pause_menu()
	visible = true
	backdrop.visible = true
	panel.visible = true
	_apply_echo_pause_locks()
	btn_resume.grab_focus.call_deferred()
	_notify_pause_button()
	if EchoChamber.in_battle:
		status_toast.emit(ContentStrings.get_text("battle_paused_hint"))
	get_tree().paused = true
	GameAudio.play_ui_open()


func resume_game() -> void:
	if not _open:
		get_tree().paused = GameState.fruit_committed or EchoChamber.in_battle
		return
	_open = false
	_slot_mode = SlotMode.NONE
	_hide_slots()
	_hide_confirm()
	_hide_options()
	panel.visible = false
	backdrop.visible = false
	visible = false
	# Fruit commit holds the world paused until Ascend. An open Echo stays paused too.
	get_tree().paused = GameState.fruit_committed or EchoChamber.in_battle
	_notify_pause_button()
	# Hub bed must still be playing after pause resume, except during an Echo.
	if not EchoChamber.in_battle and not GameAudio.is_hub_music_playing():
		GameAudio.play_hub_music()
	GameAudio.play_ui_close()


func _echo_pause_holds() -> bool:
	## Pause may open over an Echo. It must not spend the fee, discard a result,
	## or leave the fight. Resume is the way back. x / Esc still open Leave.
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return true
	return EchoPortal.is_fee_confirm_open()


func _apply_echo_pause_locks() -> void:
	var hold: bool = _echo_pause_holds()
	btn_save.disabled = hold
	btn_new_game.disabled = hold
	btn_load.disabled = hold
	btn_exit.disabled = hold
	if btn_quit_game != null:
		btn_quit_game.disabled = hold


func _on_new_game_pressed() -> void:
	if _echo_pause_holds():
		return
	_show_confirm(
		&"new_game",
		ContentStrings.get_text("pause_new_game_confirm"),
		ContentStrings.get_text("pause_new_game_confirm_yes"),
		ContentStrings.get_text("pause_new_game_confirm_no"),
	)


func _on_save_pressed() -> void:
	if EchoChamber.in_battle:
		status_toast.emit(ContentStrings.get_text("battle_save_disabled"))
		GameAudio.play_ui_cancel()
		return
	if _echo_pause_holds():
		return
	_slot_mode = SlotMode.SAVE
	_show_slots(ContentStrings.get_text("pause_save"))


func _on_load_pressed() -> void:
	if _echo_pause_holds():
		return
	_slot_mode = SlotMode.LOAD
	_show_slots(ContentStrings.get_text("pause_load"))


func _on_options_pressed() -> void:
	_apply_strings()
	_sync_audio_sliders_from_game()
	panel.visible = false
	_layout_options()
	options_panel.visible = true
	GameAudio.play_ui_open()


func _sync_audio_sliders_from_game() -> void:
	if not _audio_sliders_ready:
		return
	music_slider.set_value_no_signal(GameAudio.music_volume_linear)
	sfx_slider.set_value_no_signal(GameAudio.sfx_volume_linear)
	if _master_slider:
		_master_slider.set_value_no_signal(GameAudio.master_volume_linear)


func _on_music_slider_changed(value: float) -> void:
	GameAudio.set_music_volume_linear(value)


func _on_sfx_slider_changed(value: float) -> void:
	GameAudio.set_sfx_volume_linear(value)


func _on_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		GameAudio.save_settings()


func _on_options_reset() -> void:
	GameAudio.reset_volumes_to_defaults()
	_sync_audio_sliders_from_game()
	GameAudio.play_ui_confirm()


func _on_exit_pressed() -> void:
	if _echo_pause_holds():
		return
	_show_confirm(
		&"exit",
		ContentStrings.get_text("pause_exit_confirm"),
		ContentStrings.get_text("pause_exit_confirm_yes"),
		ContentStrings.get_text("pause_exit_confirm_no"),
	)


func _show_slots(title: String) -> void:
	slots_title.text = title
	if _slot_mode == SlotMode.SAVE:
		_slot_tab = "manual"
	_rebuild_slot_rows(_slot_tab == "autosave")
	_refresh_slot_labels()
	panel.visible = false
	_layout_slots()
	_sync_save_tabs()
	slots_panel.visible = true
	GameAudio.play_ui_open()


func _on_slots_back() -> void:
	GameAudio.play_ui_cancel()
	if standalone:
		close_standalone()
		return
	_hide_slots()


func _hide_slots() -> void:
	slots_panel.visible = false
	_slot_mode = SlotMode.NONE
	if _open and not standalone and not confirm_panel.visible:
		panel.visible = true


func _paint_slot_tab(tab: Button, selected: bool) -> void:
	var theme: Theme = load("res://assets/ui/manaforge_theme.tres") as Theme
	if theme == null or tab == null:
		return
	var box: StyleBox = theme.get_stylebox(&"pressed" if selected else &"normal", &"ToggleButton" if selected else &"Button")
	if box == null:
		return
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus"]:
		tab.add_theme_stylebox_override(state, box)


func _ensure_slot_tabs() -> void:
	if slots_panel == null or slots_panel.get_node_or_null("TabManual") != null:
		return
	var group := ButtonGroup.new()
	for spec: Array in [["TabManual", "slots_tab_manual", "manual"], ["TabAutosave", "slots_tab_autosave", "autosave"]]:
		var tab := Button.new()
		tab.name = str(spec[0])
		tab.text = ContentStrings.get_text(str(spec[1]))
		tab.toggle_mode = true
		tab.button_group = group
		GameTheme.style_tab_button(tab)
		tab.pressed.connect(_on_slot_tab.bind(str(spec[2])))
		slots_panel.add_child(tab)
	var rule := ColorRect.new()
	rule.name = "SlotTabRule"
	rule.color = Color(0.82, 0.64, 0.28, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_panel.add_child(rule)
	var closer := Button.new()
	closer.name = "SlotsClose"
	closer.pressed.connect(_on_slots_back)
	slots_panel.add_child(closer)
	Ui540.configure_kit_close_button(closer)


func _sync_save_tabs() -> void:
	var autosave_tab: Button = slots_panel.get_node_or_null("TabAutosave") as Button if slots_panel != null else null
	var manual_tab: Button = slots_panel.get_node_or_null("TabManual") as Button if slots_panel != null else null
	var saving: bool = _slot_mode == SlotMode.SAVE
	if autosave_tab != null:
		autosave_tab.disabled = saving
		if saving:
			autosave_tab.button_pressed = false
	if saving and manual_tab != null:
		manual_tab.button_pressed = true


func _on_slot_tab(tab_id: String) -> void:
	if _slot_mode == SlotMode.SAVE and tab_id == "autosave":
		_slot_tab = "manual"
		_sync_save_tabs()
		GameAudio.play_ui_cancel()
		return
	_slot_tab = tab_id
	_rebuild_slot_rows(_slot_tab == "autosave")
	_refresh_slot_labels()
	_layout_slots()


func _rebuild_slot_rows(include_autosave: bool) -> void:
	for child: Node in slot_buttons.get_children():
		child.queue_free()
	_slot_btns.clear()
	if _slot_mode == SlotMode.SAVE:
		include_autosave = false
	if include_autosave:
		for slot: int in range(1, SaveService.AUTOSAVE_SLOT_COUNT + 1):
			_add_slot_button("autosave", slot)
	else:
		for slot: int in range(1, SaveService.SAVE_SLOT_COUNT + 1):
			_add_slot_button("manual", slot)


func _add_slot_header(node_name: String, text: String) -> void:
	var header := Label.new()
	header.name = node_name
	header.text = text
	GameTheme.style_ink_label(header, true)
	header.custom_minimum_size = Vector2(0, 28)
	header.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	slot_buttons.add_child(header)


func _add_slot_button(kind: String, slot: int) -> void:
	var btn := Button.new()
	btn.name = "%s%d" % [kind.capitalize(), slot]
	btn.custom_minimum_size = Vector2(0, 44)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	GameTheme.style_ink_button(btn)
	btn.add_theme_font_override("font", GameTheme.body_font())
	btn.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
	for ink_state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		btn.add_theme_color_override(ink_state, GameTheme.INK)
	btn.add_theme_stylebox_override("normal", Ui540.list_row_style())
	btn.add_theme_stylebox_override("hover", Ui540.kit_stylebox_9s("res://assets/ui/theme/pick_row_9s_hover_24x24.png", Vector4i(6, 6, 6, 6), Vector4(8, 4, 12, 4)))
	btn.add_theme_stylebox_override("pressed", Ui540.list_row_style(true))
	btn.add_theme_stylebox_override("focus", Ui540.list_row_style(true))
	btn.set_meta("slot_kind", kind)
	btn.set_meta("slot_index", slot)
	btn.pressed.connect(_on_slot_pressed.bind(kind, slot))
	if kind == "manual":
		var edit := LineEdit.new()
		edit.name = "NameEdit"
		edit.visible = false
		edit.flat = true
		edit.max_length = 28
		edit.mouse_filter = Control.MOUSE_FILTER_STOP
		edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
		edit.position = Vector2(12, 6)
		edit.size = Vector2(240, 32)
		edit.add_theme_font_override("font", GameTheme.body_font())
		edit.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
		edit.add_theme_color_override("font_color", GameTheme.INK)
		edit.add_theme_color_override("font_placeholder_color", GameTheme.MUTED)
		var empty := StyleBoxEmpty.new()
		edit.add_theme_stylebox_override("normal", empty)
		edit.add_theme_stylebox_override("focus", empty)
		edit.text_submitted.connect(_commit_slot_name.bind(edit, slot))
		edit.focus_exited.connect(_commit_slot_name.bind(edit, slot))
		btn.add_child(edit)
	var del := Button.new()
	del.name = "Delete"
	del.flat = true
	del.focus_mode = Control.FOCUS_NONE
	del.tooltip_text = ContentStrings.get_text("pause_slot_delete")
	del.text = ContentStrings.get_text("pause_slot_delete")
	GameTheme.style_wood_button(del)
	del.add_theme_font_size_override("font_size", 14)
	del.visible = false
	del.pressed.connect(_on_delete_slot.bind(kind, slot))
	btn.add_child(del)
	del.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	del.offset_left = -96.0
	del.offset_right = -8.0
	del.offset_top = -18.0
	del.offset_bottom = 18.0
	slot_buttons.add_child(btn)
	_slot_btns.append(btn)


func _on_delete_slot(kind: String, slot: int) -> void:
	_pending_slot = slot
	_pending_kind = kind
	_return_to_slots = true
	_show_confirm(
		&"delete_slot",
		ContentStrings.get_text("pause_slot_delete_confirm"),
		ContentStrings.get_text("pause_slot_delete_yes"),
		ContentStrings.get_text("pause_slot_delete_no"),
	)


func _refresh_slot_labels() -> void:
	for btn: Button in _slot_btns:
		var kind: String = str(btn.get_meta("slot_kind", "manual"))
		var slot: int = int(btn.get_meta("slot_index", 0))
		var info: Dictionary = SaveService.get_autosave_info(slot) if kind == "autosave" else SaveService.get_slot_info(slot)
		var line: String
		var sub: Label = btn.get_node_or_null("Sub") as Label
		if sub == null:
			sub = Label.new()
			sub.name = "Sub"
			sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			GameTheme.style_ink_label(sub, true)
			sub.add_theme_font_size_override("font_size", 14)
			btn.add_child(sub)
			sub.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			sub.offset_left = -280.0
			sub.offset_right = -104.0
			sub.offset_top = -16.0
			sub.offset_bottom = 16.0
		var del: Button = btn.get_node_or_null("Delete") as Button
		var edit: LineEdit = btn.get_node_or_null("NameEdit") as LineEdit
		if bool(info.get("filled", false)):
			line = SaveService.record_title(info)
			if line == "":
				line = "Slot %d" % slot
			sub.text = _slot_subline(info)
			sub.visible = true
			if del:
				del.visible = true
			if edit != null and kind == "manual":
				edit.visible = true
				if not edit.has_focus():
					edit.text = line
				btn.text = ""
			else:
				btn.text = line
				if edit:
					edit.visible = false
		else:
			line = "Slot %d — %s" % [slot, ContentStrings.get_text("pause_slot_empty")]
			if kind == "autosave":
				line = "%s — %s" % [
					ContentStrings.get_text("load_autosave_slot", {"n": slot}),
					ContentStrings.get_text("pause_slot_empty"),
				]
			sub.visible = false
			if del:
				del.visible = false
			if edit:
				edit.visible = false
			btn.text = line


func _commit_slot_name(edit: LineEdit, slot: int) -> void:
	if edit == null or not edit.visible:
		return
	var info: Dictionary = SaveService.get_slot_info(slot)
	if not bool(info.get("filled", false)):
		return
	var next: String = edit.text.strip_edges()
	var shown: String = SaveService.record_title(info)
	## Leaving the field on the name already shown must not freeze the stage label.
	if next != shown:
		SaveService.rename_manual_slot(slot, next)
		info = SaveService.get_slot_info(slot)
	if not edit.has_focus():
		edit.text = SaveService.record_title(info)


func _slot_subline(info: Dictionary) -> String:
	var depth: int = int(info.get("depth", 1))
	var when: int = int(float(info.get("timestamp", 0.0)))
	var clock: String = ""
	var day: String = ""
	if when > 0:
		var stamp: Dictionary = Time.get_datetime_dict_from_unix_time(when)
		clock = "%02d:%02d" % [int(stamp.get("hour", 0)), int(stamp.get("minute", 0))]
		day = "%d/%d" % [int(stamp.get("month", 1)), int(stamp.get("day", 1))]
	if clock == "":
		return "Depth %d" % depth
	return "Depth %d · %s · %s" % [depth, clock, day]


func _on_slot_pressed(kind: String, slot: int) -> void:
	if kind == "autosave" and _slot_mode == SlotMode.SAVE:
		return
	if _slot_mode == SlotMode.SAVE:
		var info: Dictionary = SaveService.get_slot_info(slot)
		if bool(info.get("filled", false)):
			_pending_slot = slot
			_show_confirm(
				&"overwrite",
				ContentStrings.get_text("pause_slot_overwrite_confirm"),
				ContentStrings.get_text("pause_slot_overwrite_yes"),
				ContentStrings.get_text("pause_slot_overwrite_no"),
			)
		else:
			_do_save_slot(slot)
	elif _slot_mode == SlotMode.LOAD:
		var filled: bool = SaveService.has_autosave(slot) if kind == "autosave" else SaveService.has_slot(slot)
		if not filled:
			_do_load_slot(kind, slot)
			return
		_pending_slot = slot
		_pending_kind = kind
		_return_to_slots = true
		_show_confirm(
			&"load_slot",
			ContentStrings.get_text("pause_slot_load_confirm"),
			ContentStrings.get_text("pause_slot_load_yes"),
			ContentStrings.get_text("pause_slot_load_no"),
		)


func _do_save_slot(slot: int) -> void:
	if _echo_pause_holds():
		return
	var ok: bool = SaveService.save_game(slot)
	if ok:
		GameAudio.play_ui_confirm()
		status_toast.emit(ContentStrings.get_text("pause_save_ok"))
		_hide_slots()
		_refresh_slot_labels()
	else:
		status_toast.emit(ContentStrings.get_text("pause_save_fail"))


func _do_load_slot(kind: String, slot: int) -> void:
	if not standalone and _echo_pause_holds():
		return
	var filled: bool = SaveService.has_autosave(slot) if kind == "autosave" else SaveService.has_slot(slot)
	if standalone:
		if not filled:
			status_toast.emit(ContentStrings.get_text("pause_load_empty"))
			return
		close_standalone()
		standalone_load_requested.emit(slot, kind)
		return
	if not filled:
		status_toast.emit(ContentStrings.get_text("pause_load_empty"))
		return
	var was_echo: bool = EchoChamber.in_battle
	var ok: bool = SaveService.load_autosave(slot) if kind == "autosave" else SaveService.load_game(slot)
	if ok:
		if was_echo:
			EchoChamber.dismiss_battle_without_reward()
		GameAudio.play_ui_confirm()
		status_toast.emit(ContentStrings.get_text("pause_load_ok"))
		_hide_slots()
		resume_game()
		game_loaded.emit()
	else:
		var why: String = str(SaveService.last_load_error)
		status_toast.emit(why if why != "" else ContentStrings.get_text("pause_load_fail"))


func _show_confirm(action: StringName, body: String, yes: String, no: String) -> void:
	_confirm_action = action
	confirm_label.text = body
	confirm_yes.text = yes
	confirm_no.text = no
	panel.visible = false
	slots_panel.visible = false
	options_panel.visible = false
	confirm_panel.visible = true
	confirm_panel.z_index = 10
	confirm_panel.move_to_front()
	var title: Label = confirm_panel.get_node_or_null("ConfirmTitle") as Label
	if title:
		title.text = ContentStrings.get_text(str(CONFIRM_TITLES.get(action, "pause_title")))
	Ui540.layout_confirm(confirm_panel, title, confirm_label, confirm_yes, confirm_no)
	var frame: Panel = confirm_panel.get_node_or_null("Frame") as Panel
	if frame:
		frame.position = Vector2.ZERO
		frame.size = confirm_panel.size
	confirm_no.grab_focus.call_deferred()


func _on_confirm_no() -> void:
	GameAudio.play_ui_cancel()
	_hide_confirm()


func _hide_confirm() -> void:
	confirm_panel.visible = false
	_confirm_action = &""
	_pending_slot = 0
	if _return_to_options:
		_return_to_options = false
		options_panel.visible = true
		panel.visible = false
		return
	if _return_to_slots:
		_return_to_slots = false
		slots_panel.visible = true
		panel.visible = false
		return
	if _open and not standalone:
		panel.visible = true


func _on_options_close() -> void:
	GameAudio.save_settings()
	GameAudio.play_ui_cancel()
	_hide_options()
	if standalone:
		close_standalone()


func _hide_options() -> void:
	options_panel.visible = false
	if _open and not standalone:
		panel.visible = true


func _on_confirm_yes() -> void:
	var action: StringName = _confirm_action
	var slot: int = _pending_slot
	var kind_now: String = _pending_kind
	_hide_confirm()
	if _echo_pause_holds() and (action == &"new_game" or action == &"quit" or action == &"exit"):
		return
	match action:
		&"new_game":
			_do_new_game()
		&"quit":
			if not EchoChamber.in_battle:
				SaveService.save_on_quit()
			get_tree().paused = false
			get_tree().quit()
		&"exit":
			if not EchoChamber.in_battle:
				SaveService.save_on_quit()
			SaveService.note_session_ended()
			get_tree().paused = false
			if EchoChamber.in_battle:
				EchoChamber.dismiss_battle_without_reward()
			else:
				GameAudio.play_hub_music()
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		&"overwrite":
			if slot >= 1:
				_do_save_slot(slot)
		&"load_slot":
			if slot >= 1 and kind_now != "":
				_do_load_slot(kind_now, slot)
				_pending_kind = ""
		&"rebind_swap":
			if _rebind_listen != "" and _rebind_pending_other != "":
				var old_key: Key = Binds.keycode(_rebind_listen)
				Binds.set_keycode(_rebind_listen, _rebind_pending_key as Key)
				Binds.set_keycode(_rebind_pending_other, old_key)
			_rebind_listen = ""
			_rebind_pending_other = ""
			_refresh_rebind_rows()
		&"delete_slot":
			if kind_now == "autosave":
				SaveService.delete_autosave(slot)
			else:
				SaveService.delete_slot(slot)
			_pending_kind = ""
			_rebuild_slot_rows(_slot_tab == "autosave")
			_refresh_slot_labels()
			slots_panel.visible = true
			panel.visible = false


func _do_new_game() -> void:
	var was_echo: bool = EchoChamber.in_battle
	GameState.reset_for_new_game()
	if was_echo:
		EchoChamber.dismiss_battle_without_reward()
	# Emit HUD refresh signals after reset.
	GameState.resources_changed.emit(&"wood", GameState.wood)
	GameState.resources_changed.emit(&"stone", GameState.stone)
	GameState.resources_changed.emit(&"food", GameState.food)
	GameState.resources_changed.emit(&"manashards", GameState.manashards)
	GameState.resources_changed.emit(&"essence", GameState.essence)
	GameState.stage_changed.emit(GameState.stage_id)
	GameState.fruit_ready_changed.emit(GameState.fruit_ready)
	GameState.needs_changed.emit()
	GameState.upgrades_changed.emit()
	GameAudio.reset_cycle_flags()
	resume_game()
	new_game_started.emit()
	GameAudio.play_ui_confirm()
