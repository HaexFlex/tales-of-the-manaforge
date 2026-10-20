extends Control
## Title screen (540p kit). Hub BGM is already playing from GameAudio and is not restarted.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const KIT_DIALOG: PackedScene = preload("res://scenes/ui/kit_dialog.tscn")
## The title touch check swaps this for the binary export of the same scene.
var dialog_scene: PackedScene = KIT_DIALOG
const LOGO_POS: Vector2 = Vector2(52, 24)
const MENU_POS: Vector2 = Vector2(136, 146)
const VERSION_POS: Vector2 = Vector2(904, 503)
const WIDE_BG_SIZE: Vector2 = Vector2(1440, 960)
## Frame padding around the menu column: left, top, right, bottom.
const MENU_FRAME_PAD: Vector4 = Vector4(28, 20, 28, 22)
const WOOD_FILL: Color = Color8(104, 66, 38)
const WOOD_SEAM: Color = Color8(80, 48, 27)
const WOOD_BOARD_H: float = 26.0
const SAVE_CHIP_H: float = 24.0

@onready var fade: ColorRect = $Fade
@onready var menu: VBoxContainer = $Menu
@onready var logo: TextureRect = $Logo
@onready var btn_continue: Button = $Menu/BtnContinue
@onready var save_info: Label = $Menu/SaveInfo
@onready var btn_new: Button = $Menu/BtnNewGame
@onready var btn_load: Button = $Menu/BtnLoad
@onready var btn_options: Button = $Menu/BtnOptions
@onready var btn_quit: Button = $Menu/BtnQuit
@onready var pause_menu: PauseMenu = $PauseMenu

var _items: Array[Button] = []
var _index: int = 0
var _fade: float = 1.0
var _confirm_action: String = ""
var _active_dialog: KitDialog
var _menu_frame: Panel
var _version_label: Label
var _armed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameState.reset_play_speed()
	GameTheme.apply_app_theme()
	GameAudio.play_hub_music()
	for btn: Button in [btn_continue, btn_new, btn_load, btn_options, btn_quit]:
		btn.add_to_group("title_hero_button")
		GameTheme.style_title_hero_button(btn)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_continue.text = ContentStrings.get_text("title_continue")
	btn_new.text = ContentStrings.get_text("title_new_game")
	btn_load.text = ContentStrings.get_text("title_load")
	btn_options.text = ContentStrings.get_text("title_options")
	btn_quit.text = ContentStrings.get_text("title_quit")
	btn_continue.visible = SaveService.has_save()
	Ui540.hide_on_phone(btn_quit)
	_refresh_save_info()
	btn_continue.pressed.connect(_on_continue)
	btn_new.pressed.connect(_on_new_game)
	btn_load.pressed.connect(_on_load)
	btn_options.pressed.connect(_on_options)
	btn_quit.pressed.connect(_on_quit)
	for child: Node in menu.get_children():
		if child is Button:
			(child as Button).focus_entered.connect(_on_menu_focus.bind(child))
	pause_menu.suppress_pause_hotkey = true
	pause_menu.standalone_load_requested.connect(_on_slot_chosen)
	pause_menu.close_standalone()
	_layout_title540()
	if not get_viewport().size_changed.is_connected(_layout_title540):
		get_viewport().size_changed.connect(_layout_title540)
	_rebuild_items()
	_set_menu_enabled(false)
	call_deferred("_arm_menu_when_idle")


## Wide painting is 1440×960, drawn 1:1 and centred. Logo, menu, and version stay on the
## 960×540 frame: design point plus ((vw-960)/2, (vh-540)/2).
func _layout_title540() -> void:
	var vs: Vector2 = Ui540.viewport_size()
	var shift: Vector2 = Ui540.center_shift()
	var bg: TextureRect = get_node_or_null("Background") as TextureRect
	if bg:
		bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
		bg.offset_left = 0.0
		bg.offset_top = 0.0
		bg.offset_right = 0.0
		bg.offset_bottom = 0.0
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP
		var tex_size: Vector2 = WIDE_BG_SIZE
		if bg.texture:
			tex_size = bg.texture.get_size()
		bg.size = tex_size
		bg.position = ((vs - tex_size) * 0.5)
	if logo:
		logo.set_anchors_preset(Control.PRESET_TOP_LEFT)
		logo.position = LOGO_POS + shift
		logo.size = logo.texture.get_size() if logo.texture else logo.size
	_ensure_menu_frame()
	menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu.size = Vector2.ZERO
	var menu_size: Vector2 = menu.get_combined_minimum_size()
	menu.position = MENU_POS + shift
	menu.size = menu_size
	_menu_frame.position = menu.position - Vector2(MENU_FRAME_PAD.x, MENU_FRAME_PAD.y)
	_menu_frame.size = menu_size + Vector2(MENU_FRAME_PAD.x + MENU_FRAME_PAD.z, MENU_FRAME_PAD.y + MENU_FRAME_PAD.w)
	var ver_w: float = 78.0
	var font: Font = _version_label.get_theme_font(&"font")
	if font != null:
		ver_w = font.get_string_size(_version_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _version_label.get_theme_font_size(&"font_size")).x
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_version_label.size = Vector2(maxf(1.0, ver_w), 24.0)
	var ver_pos: Vector2 = VERSION_POS + shift
	## Keep the whole string on the viewport. On a 960-wide view the 78 px line starts left of 904.
	ver_pos.x = minf(ver_pos.x, maxf(0.0, vs.x - _version_label.size.x))
	ver_pos.y = minf(ver_pos.y, maxf(0.0, vs.y - _version_label.size.y))
	_version_label.position = ver_pos


func _ensure_menu_frame() -> void:
	if _menu_frame != null:
		return
	_menu_frame = Panel.new()
	_menu_frame.name = "MenuFrame"
	_menu_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border: StyleBoxTexture = Ui540.kit_stylebox_9s(
		"res://assets/ui/theme/frame_9s_96.png", Vector4i(24, 24, 24, 24), Vector4.ZERO, true
	)
	border.draw_center = false
	var rim := Panel.new()
	rim.name = "Rim"
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rim.set_anchors_preset(Control.PRESET_FULL_RECT)
	rim.add_theme_stylebox_override("panel", border)
	_menu_frame.add_child(rim)
	var fill := Control.new()
	fill.name = "WoodFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.offset_left = 19.0
	fill.offset_top = 19.0
	fill.offset_right = -19.0
	fill.offset_bottom = -19.0
	fill.draw.connect(_draw_wood_fill.bind(fill))
	_menu_frame.add_child(fill)
	_menu_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_menu_frame)
	move_child(_menu_frame, menu.get_index())
	var vines: VineFrame = Ui540.attach_vine_frame(_menu_frame, "title")
	_menu_frame.move_child(vines, _menu_frame.get_child_count() - 1)
	fill.resized.connect(fill.queue_redraw)

	_version_label = Label.new()
	_version_label.name = "Version"
	_version_label.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", ""))
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_version_label.add_theme_font_override("font", GameTheme.body_font())
	_version_label.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
	_version_label.add_theme_color_override("font_color", GameTheme.CREAM_BTN)
	_version_label.add_theme_color_override("font_outline_color", GameTheme.OUTLINE)
	_version_label.add_theme_constant_override("outline_size", 4)
	add_child(_version_label)
	move_child(_version_label, menu.get_index() + 1)


## Dark plank boards behind the menu buttons (the mockup's wood panel; the kit has no such piece).
func _draw_wood_fill(fill: Control) -> void:
	var sz: Vector2 = fill.size
	fill.draw_rect(Rect2(Vector2.ZERO, sz), WOOD_FILL)
	var y: float = WOOD_BOARD_H
	while y < sz.y:
		fill.draw_rect(Rect2(0.0, y, sz.x, 2.0), WOOD_SEAM)
		y += WOOD_BOARD_H


func _process(delta: float) -> void:
	if _fade > 0.0:
		_fade = maxf(0.0, _fade - delta * 1.4)
		fade.color = Color(0, 0, 0, _fade)
		fade.mouse_filter = Control.MOUSE_FILTER_STOP if _fade > 0.05 else Control.MOUSE_FILTER_IGNORE


func _refresh_save_info() -> void:
	if save_info == null:
		return
	save_info.theme_type_variation = &""
	save_info.add_theme_font_override("font", GameTheme.body_font())
	save_info.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
	save_info.add_theme_color_override("font_color", GameTheme.MUTED)
	save_info.add_theme_stylebox_override("normal", Ui540.kit_stylebox_9s(
		"res://assets/ui/theme/field_9s_normal_24x24.png", Vector4i(6, 6, 6, 6), Vector4(8, 1, 8, 1)
	))
	save_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	save_info.autowrap_mode = TextServer.AUTOWRAP_OFF
	save_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	save_info.custom_minimum_size = Vector2(0, SAVE_CHIP_H)
	if not SaveService.has_save():
		save_info.visible = false
		save_info.text = ""
		return
	save_info.visible = true
	var rec: Dictionary = SaveService.get_most_recent_record()
	if rec.is_empty():
		save_info.text = ContentStrings.get_text("title_continue_hint")
		return
	var kind: String = str(rec.get("kind", "manual"))
	var slot: int = int(rec.get("slot", 0))
	var slot_label: String = "Slot %d" % slot if kind == "manual" else ContentStrings.get_text("load_autosave_slot", {"n": slot})
	var ts: float = float(rec.get("timestamp", 0.0))
	var ago: String = _format_time_ago(ts)
	save_info.text = "%s · %s" % [slot_label, ago]
	save_info.tooltip_text = "Last save: %s" % save_info.text


func _format_time_ago(ts: float) -> String:
	if ts <= 0.0:
		return "—"
	var sec: float = maxf(0.0, Time.get_unix_time_from_system() - ts)
	if sec < 90.0:
		return "just now"
	var mins: int = int(sec / 60.0)
	if mins < 90:
		return "%d min ago" % mins
	var hours: int = int(mins / 60.0)
	if hours < 48:
		return "%d hr ago" % hours
	return "%d days ago" % int(hours / 24.0)


## Arming gates input only: the buttons keep their enabled face from the first frame.
func _set_menu_enabled(enabled: bool) -> void:
	_armed = enabled
	for btn: Button in [btn_continue, btn_new, btn_load, btn_options, btn_quit]:
		btn.disabled = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
		btn.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _input_held() -> bool:
	return (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		or Input.is_action_pressed("ui_accept")
		or Input.is_key_pressed(KEY_ENTER)
		or Input.is_key_pressed(KEY_KP_ENTER)
		or Input.is_key_pressed(KEY_SPACE)
	)


func _arm_menu_when_idle() -> void:
	while is_inside_tree() and (_fade > 0.05 or _input_held()):
		await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_set_menu_enabled(true)
	_rebuild_items()
	_focus_index(0)


func _rebuild_items() -> void:
	_items.clear()
	for child: Node in menu.get_children():
		if child is Button and (child as Button).visible:
			_items.append(child as Button)


func _focus_index(index: int) -> void:
	if _items.is_empty():
		return
	_index = posmod(index, _items.size())
	_items[_index].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if pause_menu.visible and pause_menu.standalone:
		return
	if _active_dialog != null and is_instance_valid(_active_dialog):
		return
	if not _armed:
		return
	if event.is_action_pressed("ui_down"):
		_focus_index(_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_focus_index(_index - 1)
		get_viewport().set_input_as_handled()


func _on_menu_focus(btn: Button) -> void:
	var found: int = _items.find(btn)
	if found >= 0:
		_index = found


func _on_continue() -> void:
	if not SaveService.has_save():
		return
	SaveService.boot_intent = "continue"
	SaveService.boot_slot = 0
	GameAudio.play_ui_confirm()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_new_game() -> void:
	if SaveService.has_save():
		_show_confirm(
			"new",
			ContentStrings.get_text("title_new_game_confirm"),
			ContentStrings.get_text("title_new_game_confirm_yes"),
			ContentStrings.get_text("title_new_game_confirm_no"),
		)
		return
	_start_new_game()


func _start_new_game() -> void:
	SaveService.boot_intent = "new"
	SaveService.boot_slot = 0
	GameAudio.play_ui_confirm()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_load() -> void:
	pause_menu.open_load_standalone()


func _on_options() -> void:
	pause_menu.open_options_standalone()


func _on_quit() -> void:
	_show_confirm(
		"quit",
		ContentStrings.get_text("title_quit_confirm"),
		ContentStrings.get_text("title_quit_confirm_yes"),
		ContentStrings.get_text("title_quit_confirm_no"),
	)


func _on_slot_chosen(slot: int, kind: String) -> void:
	SaveService.boot_intent = "load"
	SaveService.boot_slot = slot
	SaveService.boot_slot_kind = kind
	GameAudio.play_ui_confirm()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _show_confirm(action: String, body: String, yes: String, no: String) -> void:
	_confirm_action = action
	var dialog: KitDialog = dialog_scene.instantiate() as KitDialog
	_active_dialog = dialog
	var popup_layer: CanvasLayer = get_node_or_null("PopupLayer") as CanvasLayer
	if popup_layer == null:
		popup_layer = CanvasLayer.new()
		popup_layer.name = "PopupLayer"
		popup_layer.layer = 110
		add_child(popup_layer)
	popup_layer.add_child(dialog)
	dialog.setup("", body, "", no, yes, "title_%s" % action)
	dialog.confirmed.connect(_on_confirm_yes)
	dialog.cancelled.connect(_on_confirm_no)
	GameAudio.play_ui_open()


func _on_confirm_no() -> void:
	_confirm_action = ""
	_active_dialog = null
	GameAudio.play_ui_cancel()


func _on_confirm_yes() -> void:
	var action: String = _confirm_action
	_confirm_action = ""
	_active_dialog = null
	match action:
		"new":
			_start_new_game()
		"quit":
			SaveService.save_on_quit()
			get_tree().quit()
