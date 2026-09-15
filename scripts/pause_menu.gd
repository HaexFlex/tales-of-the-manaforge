extends CanvasLayer
class_name PauseMenu
## Mid-game pause: ESC / HUD Pause. PROCESS_MODE_ALWAYS so ESC works while paused.
## Options → Audio: Music / SFX volume sliders (persist via GameAudio settings).

signal status_toast(text: String)
signal new_game_started
signal game_loaded

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
@onready var music_label: Label = $OptionsPanel/MusicLabel
@onready var music_slider: HSlider = $OptionsPanel/MusicSlider
@onready var sfx_label: Label = $OptionsPanel/SfxLabel
@onready var sfx_slider: HSlider = $OptionsPanel/SfxSlider
@onready var options_reset: Button = $OptionsPanel/OptionsReset
@onready var options_close: Button = $OptionsPanel/OptionsClose

var _open: bool = false
var _slot_mode: int = SlotMode.NONE
var _confirm_action: StringName = &""
var _pending_slot: int = 0
var _slot_btns: Array[Button] = []
var _audio_sliders_ready: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	music_label.text = ContentStrings.get_text("options_music_volume")
	sfx_label.text = ContentStrings.get_text("options_sfx_volume")
	options_reset.text = ContentStrings.get_text("options_audio_reset")
	options_close.text = ContentStrings.get_text("options_audio_back")


func _build_slot_buttons() -> void:
	for child: Node in slot_buttons.get_children():
		child.queue_free()
	_slot_btns.clear()
	for slot: int in range(1, SaveService.SAVE_SLOT_COUNT + 1):
		var btn := Button.new()
		btn.name = "Slot%d" % slot
		btn.custom_minimum_size = Vector2(400, 36)
		btn.pressed.connect(_on_slot_pressed.bind(slot))
		slot_buttons.add_child(btn)
		_slot_btns.append(btn)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event
		if key.keycode == KEY_ESCAPE:
			if confirm_panel.visible:
				_hide_confirm()
			elif options_panel.visible:
				_hide_options()
			elif slots_panel.visible:
				_hide_slots()
			elif _open:
				resume_game()
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
	get_tree().paused = true
	GameAudio.play_ui_open()


func resume_game() -> void:
	if not _open:
		get_tree().paused = false
		return
	_open = false
	_slot_mode = SlotMode.NONE
	_hide_slots()
	_hide_confirm()
	_hide_options()
	panel.visible = false
	backdrop.visible = false
	visible = false
	get_tree().paused = false
	# Hub bed must still be playing after pause resume (volume-only options).
	if not GameAudio.is_hub_music_playing():
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
	_refresh_slot_labels()
	slots_panel.visible = true
	GameAudio.play_ui_open()


func _on_slots_back() -> void:
	GameAudio.play_ui_cancel()
	_hide_slots()


func _hide_slots() -> void:
	slots_panel.visible = false
	_slot_mode = SlotMode.NONE


func _refresh_slot_labels() -> void:
	for i: int in range(_slot_btns.size()):
		var slot: int = i + 1
		var btn: Button = _slot_btns[i]
		var info: Dictionary = SaveService.get_slot_info(slot)
		var line: String
		if bool(info.get("filled", false)):
			line = "Slot %d — %s" % [
				slot,
				ContentStrings.get_text("pause_slot_filled", {
					"ascensions": int(info.get("ascensions", 0)),
					"stage_display": str(info.get("stage_display", "")),
				}),
			]
			var essence: int = int(info.get("essence", 0))
			if essence > 0:
				line += " · %s %d" % [ContentStrings.get_text("hud_essence"), essence]
		else:
			line = "Slot %d — %s" % [slot, ContentStrings.get_text("pause_slot_empty")]
		btn.text = line


func _on_slot_pressed(slot: int) -> void:
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
		_do_load_slot(slot)


func _do_save_slot(slot: int) -> void:
	var ok: bool = SaveService.save_game(slot)
	if ok:
		GameAudio.play_ui_confirm()
		status_toast.emit(ContentStrings.get_text("pause_save_ok"))
		_hide_slots()
		_refresh_slot_labels()
	else:
		status_toast.emit(ContentStrings.get_text("pause_save_fail"))


func _do_load_slot(slot: int) -> void:
	if not SaveService.has_slot(slot):
		status_toast.emit(ContentStrings.get_text("pause_load_empty"))
		return
	var ok: bool = SaveService.load_game(slot)
	if ok:
		GameAudio.play_ui_confirm()
		status_toast.emit(ContentStrings.get_text("pause_load_ok"))
		_hide_slots()
		resume_game()
		game_loaded.emit()
	else:
		status_toast.emit(ContentStrings.get_text("pause_load_fail"))


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
			get_tree().paused = false
			get_tree().quit()
		&"overwrite":
			if slot >= 1:
				_do_save_slot(slot)


func _do_new_game() -> void:
	GameState.reset_for_new_game()
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
