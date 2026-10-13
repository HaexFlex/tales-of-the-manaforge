class_name Ui540
extends RefCounted
## Shared 540p layout helpers (safe margins, phone export, 20:9 window shift).

const SAFE_MARGIN_PX: float = 24.0
const TAP_MIN_PX: float = 44.0
const WIDE_ASPECT_SHIFT_PX: float = 120.0
const BASE_W: float = 960.0
const BASE_H: float = 540.0
const WARNING_AMBER: Color = Color8(176, 112, 20)


static func is_phone_export() -> bool:
	return OS.has_feature("mobile")


static func viewport_size() -> Vector2:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return Vector2(BASE_W, BASE_H)
	return tree.root.size


static func is_wide_aspect() -> bool:
	var vs: Vector2 = viewport_size()
	if vs.y <= 0.0:
		return false
	return vs.x / vs.y > (20.0 / 9.0) - 0.02


static func center_shift_x() -> float:
	return WIDE_ASPECT_SHIFT_PX if is_wide_aspect() else 0.0


static func center_control(ctrl: Control) -> void:
	if ctrl == null:
		return
	var vs: Vector2 = viewport_size()
	var sz: Vector2 = ctrl.size
	if sz.x <= 0.0 or sz.y <= 0.0:
		sz = ctrl.get_combined_minimum_size()
	ctrl.position = Vector2(
		(vs.x - sz.x) * 0.5 + center_shift_x(),
		(vs.y - sz.y) * 0.5,
	)


static func anchor_rect_safe(ctrl: Control, x: float, y: float, w: float, h: float) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = Vector2(x, y)
	ctrl.size = Vector2(w, h)


static func configure_icon_button(btn: BaseButton, tooltip: String) -> void:
	btn.custom_minimum_size = Vector2(TAP_MIN_PX, TAP_MIN_PX)
	btn.text = ""
	if not is_phone_export():
		btn.tooltip_text = tooltip


static func should_show_pc_tooltips() -> bool:
	return not is_phone_export() and DisplayServer.get_name() != "headless"


static func hide_on_phone(ctrl: CanvasItem) -> void:
	if ctrl == null:
		return
	ctrl.visible = not is_phone_export()
