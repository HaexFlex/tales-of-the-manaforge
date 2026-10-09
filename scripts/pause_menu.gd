extends CanvasLayer
class_name PauseMenu
## Mid-game pause: ESC / HUD Pause. PROCESS_MODE_ALWAYS so ESC works while paused.
## Options → Audio: Music / SFX volume sliders (persist via GameAudio settings).

signal status_toast(text: String)
signal new_game_started
signal game_loaded
signal standalone_load_requested(slot: int, kind: String)

enum SlotMode { NONE, SAVE, LOAD }

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: ColorRect = $Panel
@onready var title_label: Label = $Panel/Title
@onready var btn_resume: Button = $Panel/BtnResume
@onready var btn_new_game: Button = $Panel/BtnNewGame
@onready var btn_save: Button = $Panel/BtnSave
@onready var btn_load: Button = $Panel/BtnLoad
@onready var btn_options: Button = $Panel/BtnOptions
@onready var btn_exit: Button = $Panel/BtnExit
@onready var slots_panel: ColorRect = $SlotsPanel
@onready var slots_title: Label = $SlotsPanel/SlotsTitle
@onready var slot_buttons: VBoxContainer = $SlotsPanel/SlotButtons
@onready var slots_back: Button = $SlotsPanel/SlotsBack
@onready var confirm_panel: ColorRect = $ConfirmPanel
@onready var confirm_label: Label = $ConfirmPanel/ConfirmLabel
@onready var confirm_yes: Button = $ConfirmPanel/ConfirmYes
@onready var confirm_no: Button = $ConfirmPanel/ConfirmNo
@onready var options_panel: ColorRect = $OptionsPanel
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	visible = false
	backdrop.visible = false
	panel.visible = false
	slots_panel.visible = false
	confirm_panel.visible = false
	options_panel.visible = false
	backdrop.color = Color(0.02, 0.04, 0.03, 0.72)
	panel.color = Color(0.09, 0.12, 0.11, 0.97)
	slots_panel.color = Color(0.09, 0.12, 0.11, 0.97)
	confirm_panel.color = Color(0.12, 0.1, 0.08, 0.98)
	options_panel.color = Color(0.09, 0.12, 0.11, 0.97)
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


func _apply_strings() -> void:
	title_label.text = ContentStrings.get_text("pause_title")
	btn_resume.text = ContentStrings.get_text("pause_resume")
	btn_new_game.text = ContentStrings.get_text("pause_new_game")
	btn_save.text = ContentStrings.get_text("pause_save")
	btn_load.text = ContentStrings.get_text("pause_load")
	btn_options.text = ContentStrings.get_text("pause_options")
	btn_exit.text = ContentStrings.get_text("pause_exit")
	slots_back.text = ContentStrings.get_text("btn_close")
	options_title.text = ContentStrings.get_text("options_audio_title")
	options_hint.text = ContentStrings.get_text("options_audio_hint")
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
	options_close.text = ContentStrings.get_text("options_audio_back")


func _build_slot_buttons() -> void:
	_rebuild_slot_rows(false)


func _ensure_speedup_toggle() -> void:
	if options_panel == null or options_panel.get_node_or_null("SpeedupToggle") != null:
		return
	var box := CheckButton.new()
	box.name = "SpeedupToggle"
	box.position = Vector2(28, 248)
	box.size = Vector2(464, 32)
	box.text = ContentStrings.get_text("options_speedup_toggle")
	box.button_pressed = GameAudio.use_speedup_button
	box.toggled.connect(_on_speedup_toggled)
	options_panel.add_child(box)
	var hint := Label.new()
	hint.name = "SpeedupHint"
	hint.position = Vector2(36, 282)
	hint.size = Vector2(448, 72)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.78, 0.86, 0.74, 1))
	hint.text = ContentStrings.get_text("options_speedup_toggle_hint")
	options_panel.add_child(hint)
	var next_y: float = 360.0
	if _debug_tools_available():
		var debug_box := CheckButton.new()
		debug_box.name = "DebugToolsToggle"
		debug_box.position = Vector2(28, next_y)
		debug_box.size = Vector2(464, 32)
		debug_box.text = ContentStrings.get_text("options_debug_tools_toggle")
		debug_box.tooltip_text = "Ctrl+F8"
		debug_box.button_pressed = AnimPreviewHotkey.debug_panel_open()
		debug_box.toggled.connect(_on_debug_tools_toggled)
		options_panel.add_child(debug_box)
		next_y += 40.0
	if options_controls:
		options_controls.position = Vector2(options_controls.position.x, next_y)
		next_y += 84.0
	options_reset.position = Vector2(options_reset.position.x, next_y)
	options_close.position = Vector2(options_close.position.x, next_y)
	options_panel.offset_bottom = -240.0 + next_y + 56.0


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event
		if key.keycode == KEY_ESCAPE:
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
	visible = true
	backdrop.visible = true
	panel.visible = true
	btn_save.disabled = EchoChamber.in_battle
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
	# Hub bed must still be playing after pause resume, except during an Echo.
	if not EchoChamber.in_battle and not GameAudio.is_hub_music_playing():
		GameAudio.play_hub_music()
	GameAudio.play_ui_close()


func _on_new_game_pressed() -> void:
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
	_slot_mode = SlotMode.SAVE
	_show_slots(ContentStrings.get_text("pause_save"))


func _on_load_pressed() -> void:
	_slot_mode = SlotMode.LOAD
	_show_slots(ContentStrings.get_text("pause_load"))


func _on_options_pressed() -> void:
	_apply_strings()
	_sync_audio_sliders_from_game()
	options_panel.visible = true
	GameAudio.play_ui_open()


func _sync_audio_sliders_from_game() -> void:
	if not _audio_sliders_ready:
		return
	music_slider.set_value_no_signal(GameAudio.music_volume_linear)
	sfx_slider.set_value_no_signal(GameAudio.sfx_volume_linear)


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
	_show_confirm(
		&"exit",
		ContentStrings.get_text("pause_exit_confirm"),
		ContentStrings.get_text("pause_exit_confirm_yes"),
		ContentStrings.get_text("pause_exit_confirm_no"),
	)


func _show_slots(title: String) -> void:
	slots_title.text = title
	_rebuild_slot_rows(_slot_mode == SlotMode.LOAD)
	_refresh_slot_labels()
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


func _rebuild_slot_rows(include_autosave: bool) -> void:
	for child: Node in slot_buttons.get_children():
		child.queue_free()
	_slot_btns.clear()
	if include_autosave:
		_add_slot_header("AutosaveHeader", ContentStrings.get_text("load_autosave_header"))
		for slot: int in range(1, SaveService.AUTOSAVE_SLOT_COUNT + 1):
			_add_slot_button("autosave", slot)
		_add_slot_header("ManualHeader", ContentStrings.get_text("load_manual_header"))
	for slot: int in range(1, SaveService.SAVE_SLOT_COUNT + 1):
		_add_slot_button("manual", slot)


func _add_slot_header(node_name: String, text: String) -> void:
	var header := Label.new()
	header.name = node_name
	header.text = text
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.93, 0.86, 0.62, 1))
	slot_buttons.add_child(header)


func _add_slot_button(kind: String, slot: int) -> void:
	var btn := Button.new()
	btn.name = "%s%d" % [kind.capitalize(), slot]
	btn.custom_minimum_size = Vector2(400, 28 if _slot_mode == SlotMode.LOAD else 36)
	btn.set_meta("slot_kind", kind)
	btn.set_meta("slot_index", slot)
	btn.pressed.connect(_on_slot_pressed.bind(kind, slot))
	slot_buttons.add_child(btn)
	_slot_btns.append(btn)


func _refresh_slot_labels() -> void:
	for btn: Button in _slot_btns:
		var kind: String = str(btn.get_meta("slot_kind", "manual"))
		var slot: int = int(btn.get_meta("slot_index", 0))
		var info: Dictionary = SaveService.get_autosave_info(slot) if kind == "autosave" else SaveService.get_slot_info(slot)
		var line: String
		if bool(info.get("filled", false)):
			var filled: String = ContentStrings.get_text("pause_slot_filled", {
				"ascensions": int(info.get("ascensions", 0)),
				"stage_display": str(info.get("stage_display", "")),
			})
			if kind == "autosave":
				line = "%s — %s" % [ContentStrings.get_text("load_autosave_slot", {"n": slot}), filled]
			else:
				line = "Slot %d — %s" % [slot, filled]
			var essence: int = int(info.get("essence", 0))
			if essence > 0:
				line += " · %s %d" % [ContentStrings.get_text("hud_essence"), essence]
		elif kind == "autosave":
			line = "%s — %s" % [
				ContentStrings.get_text("load_autosave_slot", {"n": slot}),
				ContentStrings.get_text("pause_slot_empty"),
			]
		else:
			line = "Slot %d — %s" % [slot, ContentStrings.get_text("pause_slot_empty")]
		btn.text = line


func _on_slot_pressed(kind: String, slot: int) -> void:
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
		_do_load_slot(kind, slot)


func _do_save_slot(slot: int) -> void:
	var ok: bool = SaveService.save_game(slot)
	if ok:
		GameAudio.play_ui_confirm()
		status_toast.emit(ContentStrings.get_text("pause_save_ok"))
		_hide_slots()
		_refresh_slot_labels()
	else:
		status_toast.emit(ContentStrings.get_text("pause_save_fail"))


func _do_load_slot(kind: String, slot: int) -> void:
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
	confirm_panel.visible = true


func _on_confirm_no() -> void:
	GameAudio.play_ui_cancel()
	_hide_confirm()


func _hide_confirm() -> void:
	confirm_panel.visible = false
	_confirm_action = &""
	_pending_slot = 0


func _on_options_close() -> void:
	GameAudio.save_settings()
	GameAudio.play_ui_cancel()
	_hide_options()
	if standalone:
		close_standalone()


func _hide_options() -> void:
	options_panel.visible = false


func _on_confirm_yes() -> void:
	var action: StringName = _confirm_action
	var slot: int = _pending_slot
	_hide_confirm()
	match action:
		&"new_game":
			_do_new_game()
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
