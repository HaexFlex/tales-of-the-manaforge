class_name Ui540
extends RefCounted
## Shared 540p layout helpers (safe margins, phone export, 20:9 window shift).

const SAFE_MARGIN_PX: float = 24.0
const HUD_RESOURCE_BAND_H: float = 48.0
const TAP_MIN_PX: float = 44.0
const WIDE_ASPECT_SHIFT_PX: float = 120.0
const BASE_W: float = 960.0
const BASE_H: float = 540.0
const WARNING_AMBER: Color = Color8(176, 112, 20)


static func is_phone_export() -> bool:
	return OS.has_feature("mobile")


## Logical (stretched) size. `root.size` is the window in physical pixels, which is 2× or more
## on a scaled window and would push every 540p layout off screen.
static func viewport_size() -> Vector2:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return Vector2(BASE_W, BASE_H)
	return tree.root.get_visible_rect().size


static func is_wide_aspect() -> bool:
	var vs: Vector2 = viewport_size()
	if vs.y <= 0.0:
		return false
	return vs.x / vs.y > (20.0 / 9.0) - 0.02


## Offset of the 960-wide design canvas inside a wider logical viewport (120 on 20:9).
## Only for elements the mockups pin to the 960 canvas (title logo and menu).
## Centred windows and edge-anchored HUD chrome must not add it.
static func center_shift_x() -> float:
	return maxf(0.0, (viewport_size().x - BASE_W) * 0.5)


static func kit_top_inset() -> float:
	return SAFE_MARGIN_PX + HUD_RESOURCE_BAND_H + SAFE_MARGIN_PX


static func kit_content_size() -> Vector2:
	var vs: Vector2 = viewport_size()
	return Vector2(vs.x, maxf(0.0, vs.y - kit_top_inset() - SAFE_MARGIN_PX))


static func center_control(ctrl: Control) -> void:
	if ctrl == null:
		return
	var vs: Vector2 = viewport_size()
	var sz: Vector2 = ctrl.size
	if sz.x <= 0.0 or sz.y <= 0.0:
		sz = ctrl.get_combined_minimum_size()
	ctrl.position = ((vs - sz) * 0.5).round()


## Kit windows overlap the HUD band (the mockups dim it), so they centre on the whole
## viewport. A title plank sits 22 px above the frame, so plank windows drop by half that.
static func center_kit_panel(ctrl: Control, has_plank: bool = true) -> void:
	if ctrl == null:
		return
	var vs: Vector2 = viewport_size()
	var sz: Vector2 = ctrl.size
	if sz.x <= 0.0 or sz.y <= 0.0:
		sz = ctrl.get_combined_minimum_size()
	var top_room: float = PLANK_RISE if has_plank else 0.0
	var y: float = (vs.y - sz.y + top_room) * 0.5
	y = clampf(y, SAFE_MARGIN_PX + top_room, maxf(SAFE_MARGIN_PX + top_room, vs.y - SAFE_MARGIN_PX - sz.y))
	ctrl.position = Vector2(roundf((vs.x - sz.x) * 0.5), roundf(y))


const PLANK_RISE: float = 22.0
const PLANK_H: float = 40.0


## Tallest window that fits 540 inside the safe margins (with room for a plank).
static func max_window_h(has_plank: bool = true) -> float:
	return viewport_size().y - SAFE_MARGIN_PX * 2.0 - (PLANK_RISE if has_plank else 0.0)


static func max_window_w() -> float:
	return viewport_size().x - SAFE_MARGIN_PX * 2.0


## Sizes a kit window to `want`, clamped to the safe area, then centres it.
## Callers lay out their content against the returned size, so nothing runs past 540.
static func fit_kit_window(ctrl: Control, want: Vector2, has_plank: bool = true) -> Vector2:
	var sz := Vector2(minf(want.x, max_window_w()), minf(want.y, max_window_h(has_plank)))
	ctrl.custom_minimum_size = Vector2.ZERO
	ctrl.size = sz
	ctrl.custom_minimum_size = sz
	center_kit_panel(ctrl, has_plank)
	return sz


## Title plank on the window header: sized to the text and centred on the top frame edge.
static func place_title_plank(lbl: Label, window_w: float) -> void:
	if lbl == null:
		return
	lbl.theme_type_variation = &"TitlePlank"
	lbl.remove_theme_font_override(&"font")
	lbl.remove_theme_font_size_override(&"font_size")
	lbl.remove_theme_color_override(&"font_color")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var font: Font = lbl.get_theme_font(&"font")
	var fsize: int = lbl.get_theme_font_size(&"font_size")
	var text_w: float = font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x if font else 120.0
	var w: float = clampf(ceilf(text_w) + 56.0, 120.0, window_w - 120.0)
	lbl.custom_minimum_size = Vector2.ZERO
	lbl.size = Vector2(w, PLANK_H)
	lbl.position = Vector2(roundf((window_w - w) * 0.5), -PLANK_RISE)
	lbl.z_index = 1


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


const _CLOSE_ICON: Texture2D = preload("res://assets_extra/shared/close_x_24.png")


static func configure_kit_close_button(btn: BaseButton) -> void:
	if btn == null:
		return
	style_wood_icon_button(btn)
	configure_icon_button(btn, "Close")
	if btn is Button:
		var b: Button = btn as Button
		b.text = ""
		b.icon = _CLOSE_ICON
		b.expand_icon = false
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_focus_color", &"icon_hover_pressed_color"]:
			b.remove_theme_color_override(state)


## The 44×44 × sits in the header row, inset from the frame's top-right corner.
static func place_close_button(btn: Control, window_w: float) -> void:
	if btn == null:
		return
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.size = Vector2(TAP_MIN_PX, TAP_MIN_PX)
	btn.position = Vector2(window_w - 24.0 - TAP_MIN_PX, 20.0)
	btn.z_index = 1


static func apply_kit_panel(
	panel: Panel,
	window_id: String,
	title_label: Label = null,
	close_button: BaseButton = null,
) -> VineFrame:
	var vines: VineFrame = apply_kit_frame_panel(panel, window_id)
	if title_label:
		title_label.theme_type_variation = &"TitlePlank"
	if close_button:
		configure_kit_close_button(close_button)
	return vines


static func layout_popup_panel(panel: Control, size: Vector2) -> void:
	if panel == null:
		return
	panel.custom_minimum_size = size
	panel.size = size
	center_control(panel)
