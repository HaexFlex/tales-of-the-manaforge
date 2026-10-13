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


static func kit_stylebox_9s(
	texture_path: String,
	margins: Vector4i,
	content: Vector4 = Vector4.ZERO,
	tile: bool = false,
) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(texture_path) as Texture2D
	box.texture_margin_left = margins.x
	box.texture_margin_top = margins.y
	box.texture_margin_right = margins.z
	box.texture_margin_bottom = margins.w
	if content != Vector4.ZERO:
		box.content_margin_left = content.x
		box.content_margin_top = content.y
		box.content_margin_right = content.z
		box.content_margin_bottom = content.w
	if tile:
		box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return box


static func attach_vine_frame(host: Control, window_id: String) -> VineFrame:
	var existing: VineFrame = host.get_node_or_null("VineFrame") as VineFrame
	if existing:
		existing.window_id = window_id
		return existing
	var vines := VineFrame.new()
	vines.name = "VineFrame"
	vines.window_id = window_id
	vines.set_anchors_preset(Control.PRESET_FULL_RECT)
	vines.anchor_right = 1.0
	vines.anchor_bottom = 1.0
	vines.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vines.grow_vertical = Control.GROW_DIRECTION_BOTH
	vines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(vines)
	host.move_child(vines, 0)
	return vines


static func apply_kit_frame_panel(panel: Panel, window_id: String) -> VineFrame:
	panel.add_theme_stylebox_override(
		"panel",
		kit_stylebox_9s("res://assets/ui/theme/frame_9s_96.png", Vector4i(24, 24, 24, 24), Vector4(28, 28, 28, 28), true),
	)
	return attach_vine_frame(panel, window_id)


static func style_wood_icon_button(btn: BaseButton) -> void:
	if btn == null:
		return
	configure_icon_button(btn, btn.tooltip_text)
	var theme_res: Theme = load("res://assets/ui/manaforge_theme.tres") as Theme
	if theme_res == null:
		return
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		var sb: StyleBox = theme_res.get_stylebox(state, &"Button")
		if sb:
			btn.add_theme_stylebox_override(state, sb)
	btn.flat = false
