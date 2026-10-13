class_name Ui540
extends RefCounted
## Shared 540p layout helpers (safe margins, phone export, 20:9 window shift).

const SAFE_MARGIN_PX: float = 24.0
const TOOLTIP_GAP_PX: float = 6.0
const TOOLTIP_MIN_H: float = 30.0
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


## Hover tip: parchment panel, 6 px under the control, kept inside the 24 px safe area.
static func place_tooltip(popup: Window, anchor: Control) -> void:
	if popup == null:
		return
	var sz: Vector2 = popup.size
	if sz.y < TOOLTIP_MIN_H:
		sz.y = TOOLTIP_MIN_H
		popup.size = sz
	var vs: Vector2 = viewport_size()
	var pos := Vector2(SAFE_MARGIN_PX, SAFE_MARGIN_PX)
	if anchor != null and is_instance_valid(anchor):
		var rect: Rect2 = anchor.get_global_rect()
		pos = Vector2(rect.position.x, rect.end.y + TOOLTIP_GAP_PX)
	var max_x: float = maxf(SAFE_MARGIN_PX, vs.x - SAFE_MARGIN_PX - sz.x)
	var max_y: float = maxf(SAFE_MARGIN_PX, vs.y - SAFE_MARGIN_PX - sz.y)
	popup.position = Vector2(clampf(pos.x, SAFE_MARGIN_PX, max_x), clampf(pos.y, SAFE_MARGIN_PX, max_y))


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


## Parchment list row (bag, bench, shop): 44 px tall rows on a 48 px pitch inside the bevel.
static func list_row_style(selected: bool = false) -> StyleBoxTexture:
	var file: String = "pick_row_9s_current_24x24.png" if selected else "list_row_9s_even_24x24.png"
	return kit_stylebox_9s("res://assets/ui/theme/" + file, Vector4i(6, 6, 6, 6), Vector4(8, 4, 12, 4))


const _INK: Color = Color8(62, 42, 24)
const _CUE_CREAM: Color = Color8(243, 230, 200)
const _CUE_OUTLINE: Color = Color8(26, 15, 8)
const CONFIRM_W: float = 520.0
const CONFIRM_BTN_H: float = 44.0
const CONFIRM_BTN_GAP: float = 16.0
const CONFIRM_MAX_W: float = 640.0


## kit_dialog look for confirms built in place (HUD, pause, runestone): kit frame, plank title,
## centred Silver 19 ink body, optional amber note, action = wood button LEFT, safe = primary
## RIGHT, no ×. Height follows the body so there is no empty band.
static func layout_confirm(
	panel: Control,
	title: Label,
	body: Label,
	action: Button,
	safe: Button,
	note: Label = null,
	width: float = CONFIRM_W,
) -> void:
	if panel is Panel and panel.get_node_or_null("VineFrame") == null:
		apply_kit_frame_panel(panel as Panel, str(panel.name).to_snake_case())
	var body_font: Font = load("res://assets/fonts/font_body_silver19.tres") as Font
	var action_w: float = 0.0
	var safe_w: float = 0.0
	if action:
		action.theme_type_variation = &"BigButton"
		action.remove_theme_font_override("font")
		action.remove_theme_font_size_override("font_size")
		action_w = maxf(160.0, _button_text_w(action) + 30.0)
	if safe:
		safe.theme_type_variation = &"PrimaryButton"
		safe.remove_theme_font_override("font")
		safe.remove_theme_font_size_override("font_size")
		safe_w = maxf(200.0, _button_text_w(safe) + 40.0)
	width = clampf(action_w + CONFIRM_BTN_GAP + safe_w + 72.0, width, minf(CONFIRM_MAX_W, max_window_w()))
	var inner: float = width - 72.0
	var y: float = 36.0
	if title:
		title.theme_type_variation = &"TitlePlank"
		title.remove_theme_font_override("font")
		title.remove_theme_font_size_override("font_size")
		title.remove_theme_color_override("font_color")
		place_title_plank(title, width)
	for lbl: Label in [body, note]:
		if lbl == null:
			continue
		lbl.add_theme_font_override("font", body_font)
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.add_theme_color_override("font_color", WARNING_AMBER if lbl == note else _INK)
		lbl.remove_theme_color_override("font_shadow_color")
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		# The cached minimum keeps the unwrapped width until refreshed, and `size` clamps to it.
		lbl.update_minimum_size()
		lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		lbl.position = Vector2(36, y)
		lbl.size = Vector2(inner, 20)
		var lines: int = text_line_count(lbl.text, body_font, 19, inner)
		lbl.visible = lines > 0
		var spacing: float = float(lbl.get_theme_constant("line_spacing"))
		lbl.size = Vector2(inner, maxf(20.0, (body_font.get_height(19) + spacing) * lines))
		if lines > 0:
			y += lbl.size.y + 12.0
	y += 8.0
	var sw: float = floorf(maxf(200.0, minf(safe_w, (inner - CONFIRM_BTN_GAP) * 0.5))) if action else inner
	var aw: float = inner - CONFIRM_BTN_GAP - sw if safe else inner
	if action:
		action.set_anchors_preset(Control.PRESET_TOP_LEFT)
		action.position = Vector2(36, y)
		action.custom_minimum_size = Vector2(0, CONFIRM_BTN_H)
		_clear_button_overrides(action)
		fit_button_font(action, aw + 10.0)
		action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		action.size = Vector2(aw, CONFIRM_BTN_H)
	if safe:
		safe.set_anchors_preset(Control.PRESET_TOP_LEFT)
		safe.position = Vector2(width - 36.0 - sw, y)
		safe.custom_minimum_size = Vector2(0, CONFIRM_BTN_H)
		_clear_button_overrides(safe)
		fit_button_font(safe, sw + 10.0)
		safe.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		safe.size = Vector2(sw, CONFIRM_BTN_H)
	var h: float = y + CONFIRM_BTN_H + 28.0
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.custom_minimum_size = Vector2(width, h)
	panel.size = Vector2(width, h)
	center_kit_panel(panel)


## Wrapped line count for `text` at `width` (word-smart, like the labels use).
static func text_line_count(text: String, font: Font, font_size: int, width: float) -> int:
	if text == "" or font == null:
		return 0
	var lines: int = 0
	for para: String in text.split("\n"):
		if para == "":
			lines += 1
			continue
		var sz: Vector2 = font.get_multiline_string_size(para, HORIZONTAL_ALIGNMENT_LEFT, width, font_size)
		lines += maxi(1, int(roundf(sz.y / font.get_height(font_size))))
	return lines


static func _button_text_w(btn: Button) -> float:
	var font: Font = btn.get_theme_font("font")
	if font == null:
		return 0.0
	return font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, btn.get_theme_font_size("font_size")).x


static func _clear_button_overrides(btn: Button) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		btn.remove_theme_stylebox_override(state)
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		btn.remove_theme_color_override(state)
	btn.flat = false


## Big (Silver 38) caps drop to the body size when the label would not fit the face.
static func fit_button_font(btn: Button, face_w: float = -1.0) -> void:
	if btn == null:
		return
	if face_w < 0.0:
		face_w = btn.size.x
	btn.remove_theme_font_override("font")
	btn.remove_theme_font_size_override("font_size")
	var font: Font = btn.get_theme_font("font")
	var fs: int = btn.get_theme_font_size("font_size")
	if font == null:
		return
	var tw: float = font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if tw > face_w - 40.0:
		btn.add_theme_font_override("font", load("res://assets/fonts/font_body_silver19.tres") as Font)
		btn.add_theme_font_size_override("font_size", 19)


## Cream ↻ cue at the right of a cycling tab (bag, bench Parts, char Weapon).
## One readable 18 px mark, inset 12 px, on every tab. The label is padded so a
## Silver 38 "Weapon" on the narrow gear tab still ends before the arc.
static func add_cycle_cue(btn: Button) -> void:
	if btn == null:
		return
	_pad_cycle_label(btn)
	var cue := btn.get_node_or_null("CycleCue") as Control
	if cue == null:
		cue = Control.new()
		cue.name = "CycleCue"
		cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cue.draw.connect(_draw_cycle_cue.bind(cue))
		btn.add_child(cue)
	## Re-applied on every call so a later restyle cannot leave the bag tab
	## with a different mark than Parts and Weapon.
	cue.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	cue.offset_left = -30.0
	cue.offset_right = -12.0
	cue.offset_top = -11.0
	cue.offset_bottom = 7.0
	cue.scale = Vector2.ONE
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER


static func _draw_cycle_cue(cue: Control) -> void:
	var c := Vector2(9, 9)
	for pass_i: int in range(2):
		var col: Color = _CUE_OUTLINE if pass_i == 0 else _CUE_CREAM
		var wdt: float = 4.0 if pass_i == 0 else 2.0
		cue.draw_arc(c, 6.0, deg_to_rad(200.0), deg_to_rad(470.0), 16, col, wdt)
		var tri := PackedVector2Array([Vector2(11, 1), Vector2(17, 5), Vector2(10, 7)])
		if pass_i == 0:
			tri = PackedVector2Array([Vector2(10, 0), Vector2(18, 5), Vector2(9, 8)])
		cue.draw_colored_polygon(tri, col)


## Extra right inset so the centred label ends before the cue.
static func _pad_cycle_label(btn: Button) -> void:
	for state_name: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		var box: StyleBox = btn.get_theme_stylebox(state_name)
		if box == null:
			continue
		if box.content_margin_right >= 36.0:
			continue
		var copy: StyleBox = box.duplicate()
		copy.content_margin_right = 36.0
		btn.add_theme_stylebox_override(state_name, copy)


static func style_wood_icon_button(btn: BaseButton) -> void:
	if btn == null:
		return
	if btn is Button and (btn as Button).text != "":
		btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, TAP_MIN_PX)
	else:
		configure_icon_button(btn, btn.tooltip_text)
	var theme_res: Theme = load("res://assets/ui/manaforge_theme.tres") as Theme
	if theme_res == null:
		return
	var icon_only: bool = not (btn is Button and (btn as Button).text != "")
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		var sb: StyleBox = theme_res.get_stylebox(state, &"Button")
		if sb:
			if icon_only:
				# The theme's 12 px text margins would make a 24 px glyph 48 wide.
				sb = sb.duplicate() as StyleBox
				sb.content_margin_left = 10.0
				sb.content_margin_right = 10.0
			btn.add_theme_stylebox_override(state, sb)
	btn.flat = false


const _CLOSE_ICON: Texture2D = preload("res://assets_extra/shared/close_x_24.png")


static func configure_kit_close_button(btn: BaseButton) -> void:
	if btn == null:
		return
	if btn is Button:
		(btn as Button).text = ""
	style_wood_icon_button(btn)
	configure_icon_button(btn, "Close")
	if btn is Button:
		var b: Button = btn as Button
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
