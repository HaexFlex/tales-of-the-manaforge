extends PanelContainer
## Shared Make / Max / Cancel panel for Forge stations and the workbench.
## The slider cannot pass what the player can afford.

var _spot_id: String = ""
var _recipe_id: String = ""
var _built: bool = false
var _slider_recipe: String = ""
var _confirming: bool = false

var _amount_label: Label
var _count_label: Label
var _slider: HSlider
var _make: Button
var _max: Button
var _cancel: Button
var _current_label: Label
var _current_bar: ProgressBar
var _total_label: Label
var _total_bar: ProgressBar
var _detail: Label
var _note: Label
var _status: Label
var _confirm: PanelContainer
var _confirm_title: Label
var _confirm_body: Label
var _confirm_yes: Button
var _confirm_no: Button


func setup(spot_id: String) -> void:
	_spot_id = spot_id
	_ensure_built()
	_refresh()


func bind_recipe(recipe_id: String) -> void:
	_recipe_id = recipe_id
	_ensure_built()
	_refresh()


func selected_recipe() -> String:
	return _recipe_id


func spot_id() -> String:
	return _spot_id


func _ready() -> void:
	_ensure_built()
	_refresh()


func _process(_delta: float) -> void:
	if _spot_id == "":
		return
	_refresh()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(340, 250)
	var box := VBoxContainer.new()
	box.name = "Body"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var amount_row := HBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 8)
	_amount_label = Label.new()
	_amount_label.name = "Amount"
	_count_label = Label.new()
	_count_label.name = "Count"
	amount_row.add_child(_amount_label)
	amount_row.add_child(_count_label)
	box.add_child(amount_row)
	_slider = HSlider.new()
	_slider.name = "Slider"
	_slider.min_value = 0
	_slider.max_value = 0
	_slider.step = 1
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.custom_minimum_size = Vector2(0, 22)
	_slider.value_changed.connect(_on_slider)
	box.add_child(_slider)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	_make = Button.new()
	_make.name = "Make"
	_make.pressed.connect(_on_make)
	_max = Button.new()
	_max.name = "Max"
	_max.pressed.connect(_on_max)
	_cancel = Button.new()
	_cancel.name = "Cancel"
	_cancel.pressed.connect(_on_cancel)
	buttons.add_child(_make)
	buttons.add_child(_max)
	buttons.add_child(_cancel)
	box.add_child(buttons)
	_current_label = Label.new()
	_current_label.name = "CurrentLabel"
	box.add_child(_current_label)
	_current_bar = _bar("CurrentBar")
	box.add_child(_current_bar)
	_total_label = Label.new()
	_total_label.name = "TotalLabel"
	box.add_child(_total_label)
	_total_bar = _bar("TotalBar")
	box.add_child(_total_bar)
	_detail = Label.new()
	_detail.name = "Detail"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail)
	_status = Label.new()
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	_note = Label.new()
	_note.name = "AwayNote"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_note)
	_build_confirm(box)
	_apply_copy()


func _bar(node_name: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = node_name
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.55, 0.78, 0.34, 1.0)
	bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.06, 0.04, 1.0)
	bar.add_theme_stylebox_override("background", back)
	return bar


func _build_confirm(box: VBoxContainer) -> void:
	_confirm = PanelContainer.new()
	_confirm.name = "CancelConfirm"
	_confirm.visible = false
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	_confirm_title = Label.new()
	_confirm_title.name = "ConfirmTitle"
	_confirm_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body = Label.new()
	_confirm_body.name = "ConfirmBody"
	_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_confirm_yes = Button.new()
	_confirm_yes.name = "ConfirmYes"
	_confirm_yes.pressed.connect(_on_confirm_yes)
	_confirm_no = Button.new()
	_confirm_no.name = "ConfirmNo"
	_confirm_no.pressed.connect(_on_confirm_no)
	row.add_child(_confirm_yes)
	row.add_child(_confirm_no)
	inner.add_child(_confirm_title)
	inner.add_child(_confirm_body)
	inner.add_child(row)
	_confirm.add_child(inner)
	box.add_child(_confirm)


func _apply_copy() -> void:
	if not has_node("/root/ContentStrings"):
		return
	_amount_label.text = ContentStrings.get_text("batch_amount")
	_make.text = ContentStrings.get_text("batch_make")
	_max.text = ContentStrings.get_text("batch_max")
	_cancel.text = ContentStrings.get_text("batch_cancel")
	_current_label.text = ContentStrings.get_text("batch_bar_current")
	_note.text = ContentStrings.get_text("batch_away_note")
	_confirm_title.text = ContentStrings.get_text("batch_cancel_confirm_title")
	_confirm_yes.text = ContentStrings.get_text("batch_cancel_confirm_yes")
	_confirm_no.text = ContentStrings.get_text("batch_cancel_confirm_no")


func _line(key: String, tokens: Dictionary = {}) -> String:
	if not has_node("/root/ContentStrings"):
		return key
	return ContentStrings.get_text(key, tokens)


func _on_slider(value: float) -> void:
	_count_label.text = str(int(value))


func _on_max() -> void:
	if _slider == null:
		return
	_slider.value = _slider.max_value


func _on_make() -> void:
	if not has_node("/root/ForgeJobs") or _spot_id == "" or _recipe_id == "":
		return
	if ForgeJobs.has_job(_spot_id):
		_status.text = _line("batch_busy")
		return
	var count: int = int(_slider.value)
	if count < 1:
		return
	var result: String = ForgeJobs.try_begin_batch(_spot_id, _recipe_id, count)
	if result == "ok":
		_status.text = ""
		_confirming = false
	elif result == "busy":
		_status.text = _line("batch_busy")
	elif result == "owned" and has_node("/root/ForgeJobs"):
		GameState.status_message.emit(ForgeJobs.copy_text("already_owned"))
	_refresh()


func _on_cancel() -> void:
	if not has_node("/root/ForgeJobs") or not ForgeJobs.has_job(_spot_id):
		return
	_confirming = true
	_confirm.visible = true
	_refresh()


func _on_confirm_yes() -> void:
	if has_node("/root/ForgeJobs"):
		ForgeJobs.cancel_batch(_spot_id)
	_confirming = false
	_refresh()


func _on_confirm_no() -> void:
	_confirming = false
	_refresh()


func _refresh() -> void:
	if not _built or _spot_id == "" or not has_node("/root/ForgeJobs"):
		return
	_apply_copy()
	var running: bool = ForgeJobs.has_job(_spot_id)
	var state: Dictionary = ForgeJobs.job_state(_spot_id) if running else {}
	var limit: int = 0
	if _recipe_id != "" and not running:
		limit = ForgeJobs.slider_limit(_recipe_id)
	_slider.max_value = float(limit)
	_slider.min_value = 0.0
	if _recipe_id != _slider_recipe:
		_slider_recipe = _recipe_id
		_slider.set_value_no_signal(float(limit if limit > 0 else 0))
	elif _slider.value > float(limit):
		_slider.set_value_no_signal(float(limit))
	var shown: int = int(_slider.value)
	_count_label.text = str(shown)
	var show_slider: bool = not running and limit > 0
	_slider.visible = show_slider
	_amount_label.visible = not running
	_count_label.visible = not running
	_make.visible = not running
	_max.visible = not running
	_make.disabled = running or limit < 1 or shown < 1
	_max.disabled = running or limit < 1
	_cancel.visible = running
	_cancel.disabled = not running
	_current_bar.visible = running
	_total_bar.visible = running
	_current_label.visible = running
	_total_label.visible = running
	if running:
		var fraction: float = clampf(float(state.get("fraction", 0.0)), 0.0, 1.0)
		var batch_fraction: float = clampf(float(state.get("batch_fraction", 0.0)), 0.0, 1.0)
		_current_bar.value = fraction
		_total_bar.value = batch_fraction
		_total_label.text = _line("batch_bar_total", {
			"done": int(state.get("done", 0)),
			"total": int(state.get("total", 0)),
		})
		var bits: PackedStringArray = PackedStringArray()
		bits.append(str(state.get("name", "")))
		bits.append(ForgeJobs.staff_line(_spot_id))
		_detail.text = "\n".join(bits)
		if float(state.get("speed", 0.0)) <= 0.0:
			_status.text = _line("batch_unstaffed")
		else:
			_status.text = _line("batch_busy")
	else:
		var info_name: String = ""
		if _recipe_id != "":
			info_name = ForgeJobs.recipe_display_name(_recipe_id)
		var idle_bits: PackedStringArray = PackedStringArray()
		if info_name != "":
			idle_bits.append(info_name)
		var staff: String = ForgeJobs.staff_line(_spot_id)
		if staff != "":
			idle_bits.append(staff)
		_detail.text = "\n".join(idle_bits)
		if _status.text == _line("batch_unstaffed") or _status.text == _line("batch_busy"):
			_status.text = ""
	_note.text = _line("batch_away_note")
	_confirm.visible = _confirming and running
	if _confirm.visible:
		_confirm_body.text = _line("batch_cancel_confirm_body", {"refund": ForgeJobs.refund_text(_spot_id)})
