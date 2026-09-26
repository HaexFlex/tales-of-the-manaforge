extends Control
## SNES-style front door. Hub BGM is already playing from GameAudio and is not restarted.

const MAIN_SCENE: String = "res://scenes/main.tscn"

@onready var fade: ColorRect = $Fade
@onready var menu: VBoxContainer = $Menu
@onready var cursor: TextureRect = $Cursor
@onready var btn_continue: Button = $Menu/BtnContinue
@onready var btn_new: Button = $Menu/BtnNewGame
@onready var btn_load: Button = $Menu/BtnLoad
@onready var btn_options: Button = $Menu/BtnOptions
@onready var btn_quit: Button = $Menu/BtnQuit
@onready var confirm_panel: ColorRect = $ConfirmPanel
@onready var confirm_label: Label = $ConfirmPanel/ConfirmLabel
@onready var confirm_yes: Button = $ConfirmPanel/ConfirmYes
@onready var confirm_no: Button = $ConfirmPanel/ConfirmNo
@onready var pause_menu: PauseMenu = $PauseMenu

var _items: Array[Button] = []
var _index: int = 0
var _fade: float = 1.0
var _blink: float = 0.0
var _confirm_action: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	GameAudio.play_hub_music()
	_style_button(btn_continue)
	_style_button(btn_new)
	_style_button(btn_load)
	_style_button(btn_options)
	_style_button(btn_quit)
	btn_continue.text = ContentStrings.get_text("title_continue")
	btn_new.text = ContentStrings.get_text("title_new_game")
	btn_load.text = ContentStrings.get_text("title_load")
	btn_options.text = ContentStrings.get_text("title_options")
	btn_quit.text = ContentStrings.get_text("title_quit")
	btn_continue.visible = SaveService.has_save()
	btn_continue.pressed.connect(_on_continue)
	btn_new.pressed.connect(_on_new_game)
	btn_load.pressed.connect(_on_load)
	btn_options.pressed.connect(_on_options)
	btn_quit.pressed.connect(_on_quit)
	for child: Node in menu.get_children():
		if child is Button:
			(child as Button).focus_entered.connect(_on_menu_focus.bind(child))
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_no.pressed.connect(_on_confirm_no)
	confirm_panel.visible = false
	pause_menu.suppress_pause_hotkey = true
	pause_menu.standalone_load_requested.connect(_on_slot_chosen)
	pause_menu.close_standalone()
	var cursor_tex: Texture2D = load("res://assets/art/ui/icon_manashards.png") as Texture2D
	cursor.texture = cursor_tex
	cursor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rebuild_items()
	_set_menu_enabled(false)
	call_deferred("_arm_menu_when_idle")


func _process(delta: float) -> void:
	if _fade > 0.0:
		_fade = maxf(0.0, _fade - delta * 1.4)
		fade.color = Color(0, 0, 0, _fade)
		fade.mouse_filter = Control.MOUSE_FILTER_STOP if _fade > 0.05 else Control.MOUSE_FILTER_IGNORE
	_blink += delta
	var pulse: float = 0.55 + 0.45 * abs(sin(_blink * 3.2))
	cursor.modulate = Color(1, 1, 1, pulse)
	_place_cursor()


func _set_menu_enabled(enabled: bool) -> void:
	btn_continue.disabled = not enabled
	btn_new.disabled = not enabled
	btn_load.disabled = not enabled
	btn_options.disabled = not enabled
	btn_quit.disabled = not enabled


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
	## The editor Play click / accept must not activate Continue or New Game.
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
	_place_cursor()


func _place_cursor() -> void:
	if _items.is_empty() or cursor == null:
		return
	var btn: Button = _items[_index]
	var origin: Vector2 = btn.global_position
	cursor.global_position = origin + Vector2(-36, btn.size.y * 0.5 - 16)


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.08, 0.55)
	normal.border_color = Color(0.72, 0.58, 0.28, 0.0)
	normal.set_border_width_all(0)
	normal.set_content_margin_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.10, 0.12, 0.08, 0.72)
	hover.border_color = Color(0.86, 0.72, 0.34, 1)
	hover.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(0.93, 0.86, 0.62, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.75, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 0.95, 0.75, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 0.86, 1))
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_ALL


func _unhandled_input(event: InputEvent) -> void:
	if pause_menu.visible and pause_menu.standalone:
		return
	if confirm_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_on_confirm_no()
			get_viewport().set_input_as_handled()
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
		_place_cursor()


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


func _on_slot_chosen(slot: int) -> void:
	SaveService.boot_intent = "load"
	SaveService.boot_slot = slot
	GameAudio.play_ui_confirm()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _show_confirm(action: String, body: String, yes: String, no: String) -> void:
	_confirm_action = action
	confirm_label.text = body
	confirm_yes.text = yes
	confirm_no.text = no
	confirm_panel.visible = true
	GameAudio.play_ui_open()


func _on_confirm_no() -> void:
	confirm_panel.visible = false
	_confirm_action = ""
	GameAudio.play_ui_cancel()


func _on_confirm_yes() -> void:
	var action: String = _confirm_action
	confirm_panel.visible = false
	_confirm_action = ""
	match action:
		"new":
			_start_new_game()
		"quit":
			get_tree().quit()
