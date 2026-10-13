class_name KitDialog
extends Control
## Shared confirm dialog: dim + kit window (no ×) + body + action left / safe primary right.

signal confirmed
signal cancelled

@export var free_on_answer := true

const DIALOG_W: float = 520.0
const DIALOG_W_MAX: float = 640.0
const DIALOG_H_MAX: float = 340.0
const BODY_LINE_PX: float = 18.0
const BODY_MAX_LINES: int = 8
const BTN_H: float = 44.0
const WARNING: Color = Ui540.WARNING_AMBER

@onready var _win: KitWindow = $Window
@onready var _body: Label = $Window/Content/VBox/Body
@onready var _body_scroll: ScrollContainer = $Window/Content/VBox/BodyScroll
@onready var _body_scroll_label: Label = $Window/Content/VBox/BodyScroll/BodyScrollLabel
@onready var _note: Label = $Window/Content/VBox/Note
@onready var _action: Button = $Window/Content/VBox/Buttons/Action
@onready var _safe: Button = $Window/Content/VBox/Buttons/Safe

var _body_text: String = ""
var _note_text: String = ""
var _action_text: String = ""
var _safe_text: String = ""


func _ready() -> void:
	_action.pressed.connect(_answer.bind(true))
	_safe.pressed.connect(_answer.bind(false))
	_safe.grab_focus.call_deferred()


func setup(title: String, body: String, note := "", safe_text := "Cancel", primary_text := "OK", id := "confirm") -> void:
	if not is_node_ready():
		await ready
	_win.title = title
	_win.window_id = id
	_win.show_close = false
	_body_text = body
	_note_text = note
	_action_text = primary_text
	_safe_text = safe_text
	_apply_copy()
	_layout_dialog()
	_safe.grab_focus.call_deferred()


func _apply_copy() -> void:
	_body.text = _body_text
	_body_scroll_label.text = _body_text
	_note.text = _note_text
	_note.visible = _note_text != ""
	if _note_text != "":
		_note.add_theme_color_override("font_color", WARNING)
	_action.text = _fit_button_label(_action, _action_text)
	_safe.text = _fit_button_label(_safe, _safe_text)
	_safe.add_theme_font_override("font", _action.get_theme_font(&"font"))
	_safe.add_theme_font_size_override("font_size", _action.get_theme_font_size(&"font_size"))
	if _action.text != _action_text and Ui540.should_show_pc_tooltips():
		_action.tooltip_text = _action_text
	if _safe.text != _safe_text and Ui540.should_show_pc_tooltips():
		_safe.tooltip_text = _safe_text


func _fit_button_label(btn: Button, full: String) -> String:
	btn.add_theme_font_size_override("font_size", 38)
	btn.add_theme_font_override("font", load("res://assets/fonts/font_primary_silver38_bold.tres"))
	if _text_fits(btn, full, 38):
		return full
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_font_override("font", load("res://assets/fonts/font_body_silver19.tres"))
	if _text_fits(btn, full, 19):
		return full
	btn.add_theme_font_size_override("font_size", 19)
	return _ellipsis(full, 28)


func _text_fits(btn: Button, text: String, size_px: int) -> bool:
	var font: Font = btn.get_theme_font(&"font")
	if font == null:
		return text.length() <= 24
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	return w <= btn.custom_minimum_size.x - 16.0


func _ellipsis(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max(1, max_chars - 1)) + "…"


func _layout_dialog() -> void:
	var inner_w: float = DIALOG_W - 80.0
	var use_scroll: bool = _body_line_count(_body_text) > BODY_MAX_LINES
	_body.visible = not use_scroll
	_body_scroll.visible = use_scroll
	var body_h: float = minf(BODY_MAX_LINES * BODY_LINE_PX, _body_line_count(_body_text) * BODY_LINE_PX)
	if use_scroll:
		_body_scroll.custom_minimum_size = Vector2(inner_w, body_h)
	else:
		_body.custom_minimum_size = Vector2(inner_w, 0)
	var btn_w: float = maxf(170.0, _button_width(_action_text))
	btn_w = maxf(btn_w, _button_width(_safe_text))
	var total_w: float = minf(DIALOG_W_MAX, maxf(DIALOG_W, btn_w * 2.0 + 48.0 + 80.0))
	_win.custom_minimum_size = Vector2(total_w, 0)
	_win.size = Vector2(total_w, minf(DIALOG_H_MAX, _estimate_height(total_w, body_h, use_scroll)))
	_action.custom_minimum_size = Vector2(btn_w, BTN_H)
	_safe.custom_minimum_size = Vector2(btn_w, BTN_H)
	_win.center_on_viewport = true
	Ui540.center_control(_win)


func _estimate_height(w: float, body_h: float, scroll: bool) -> float:
	var h: float = 34.0 + body_h + 12.0
	if _note_text != "":
		h += 22.0
	h += 12.0 + BTN_H + 26.0
	return minf(DIALOG_H_MAX, h)


func _body_line_count(text: String) -> int:
	if text.is_empty():
		return 1
	var inner_w: float = DIALOG_W - 80.0
	var font: Font = _body.get_theme_font(&"font")
	var size: int = _body.get_theme_font_size(&"font_size")
	if font == null:
		return int(ceil(float(text.length()) / 42.0))
	var lines: int = 0
	for line: String in text.split("\n"):
		var lw: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		lines += int(maxi(1, ceil(lw / inner_w)))
	return lines


func _button_width(label: String) -> float:
	var font: Font = load("res://assets/fonts/font_primary_silver38_bold.tres") as Font
	var w38: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x + 40.0
	if w38 <= 240.0:
		return w38
	var body_font: Font = load("res://assets/fonts/font_body_silver19.tres") as Font
	return body_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 32.0


func _answer(ok: bool) -> void:
	if ok:
		confirmed.emit()
	else:
		cancelled.emit()
	if free_on_answer:
		queue_free()
	else:
		hide()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)
