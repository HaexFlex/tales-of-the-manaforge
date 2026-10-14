@tool
class_name KitWindow
extends Control
## Base kit window: frame + seeded vines + title plank + 44×44 × Close + content slot.

signal closed

@export var title := "Window":
	set(v): title = v; _sync()
@export var window_id := "":
	set(v): window_id = v; _sync()
@export var use_title_plate := false:
	set(v): use_title_plate = v; _sync()
@export var show_close := true:
	set(v): show_close = v; _sync()
@export var close_on_cancel := true
@export var free_on_close := false
@export var reduce_motion := false:
	set(v): reduce_motion = v; _sync()
@export var center_on_viewport := false:
	set(v): center_on_viewport = v; _sync()

@onready var _plank: Label = $TitlePlank
@onready var _close: Button = $CloseButton
@onready var _vines: VineFrame = $VineFrame
@onready var content: MarginContainer = $Content

const _CLOSE_ICON: Texture2D = preload("res://assets/ui/theme/icon_close_24x24.png")


func _ready() -> void:
	_sync()
	if not Engine.is_editor_hint():
		_close.pressed.connect(close)
		get_viewport().size_changed.connect(_on_viewport_resized)
		call_deferred("_on_viewport_resized")


func _sync() -> void:
	if not is_node_ready():
		return
	_plank.text = title
	_plank.visible = title != ""
	_plank.theme_type_variation = &"TitlePlate" if use_title_plate else &"TitlePlank"
	_close.visible = show_close
	Ui540.configure_icon_button(_close, "Close")
	_close.icon = _CLOSE_ICON
	_close.expand_icon = true
	_vines.window_id = window_id if window_id != "" else title.to_snake_case()
	_vines.reduce_motion = reduce_motion


func close() -> void:
	closed.emit()
	if free_on_close:
		queue_free()
	else:
		hide()


func _on_viewport_resized() -> void:
	if not center_on_viewport or Engine.is_editor_hint():
		return
	Ui540.center_control(self)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree():
		return
	if close_on_cancel and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
