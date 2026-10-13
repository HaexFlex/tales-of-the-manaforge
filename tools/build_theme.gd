## Rebuilds assets/ui/manaforge_theme.tres + the font variations from the kit textures.
## Run: godot --headless --path <project> -s res://tools/build_theme.gd
extends SceneTree

const T := "res://assets/ui/theme/"
const INK := Color8(62, 42, 24)
const CREAM := Color8(243, 230, 200)
const OUTLINE := Color8(26, 15, 8)
const MUTED := Color8(90, 62, 40)
const DIS := Color8(66, 52, 40)
# measured cap heights (px ink, top of "H" to baseline) - see MOCKUPS.md v8c
const CAP := {"silver19": 9, "silver38": 18, "jersey30": 16}

var _missing: PackedStringArray = []

## A headless run before `--import` loads every texture as null and silently writes a
## Theme with no art (flat buttons, no slider track, engine font). Refuse to save then.
func tex(n: String) -> Texture2D:
	var t: Texture2D = load(T + n) as Texture2D
	if t == null:
		_missing.append(n)
	return t

func sbt(n: String, m: Array, cm: Array = [], tile := false, expand: Array = []) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex(n)
	s.texture_margin_left = m[0]; s.texture_margin_top = m[1]; s.texture_margin_right = m[2]; s.texture_margin_bottom = m[3]
	if cm.size() == 4:
		s.content_margin_left = cm[0]; s.content_margin_top = cm[1]; s.content_margin_right = cm[2]; s.content_margin_bottom = cm[3]
	if tile:
		s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	if expand.size() == 4:
		s.expand_margin_left = expand[0]; s.expand_margin_top = expand[1]; s.expand_margin_right = expand[2]; s.expand_margin_bottom = expand[3]
	return s

func centred_variation(base: FontFile, size: int, cap: int, embolden := 0.0) -> FontVariation:
	# Godot centres the line box (ascent+descent+spacing). Shift it so the CAP ink is centred:
	# spacing_top - spacing_bottom = descent - ascent + cap
	var v := FontVariation.new()
	v.base_font = base
	var asc := base.get_ascent(size); var desc := base.get_descent(size)
	var d := int(round(desc - asc + cap))
	if d > 0: v.spacing_bottom = -d
	elif d < 0: v.spacing_top = d
	v.variation_embolden = embolden
	print("font ", base.resource_path.get_file(), " ", size, ": ascent ", asc, " descent ", desc, " cap ", cap, " -> spacing_top ", v.spacing_top, " spacing_bottom ", v.spacing_bottom)
	return v

func _init() -> void:
	var silver: FontFile = load("res://assets/fonts/Silver.ttf")
	var jersey: FontFile = load("res://assets/fonts/Jersey10-Regular.ttf")
	var body := centred_variation(silver, 19, CAP.silver19)
	var primary := centred_variation(silver, 38, CAP.silver38, 0.6)
	var title := centred_variation(jersey, 30, CAP.jersey30)
	ResourceSaver.save(body, "res://assets/fonts/font_body_silver19.tres")
	ResourceSaver.save(primary, "res://assets/fonts/font_primary_silver38_bold.tres")
	ResourceSaver.save(title, "res://assets/fonts/font_title_jersey30.tres")
	body = load("res://assets/fonts/font_body_silver19.tres")
	primary = load("res://assets/fonts/font_primary_silver38_bold.tres")
	title = load("res://assets/fonts/font_title_jersey30.tres")

	var th := Theme.new()
	th.default_font = body
	th.default_font_size = 19

	# ---- panels / windows: kit frame (9s 24, centre tiled)
	var frame := sbt("frame_9s_96.png", [24, 24, 24, 24], [28, 28, 28, 28], true)
	for t in ["Panel", "PanelContainer"]: th.set_stylebox("panel", t, frame)
	th.set_stylebox("embedded_border", "Window", frame)
	th.set_stylebox("embedded_unfocused_border", "Window", frame)
	th.set_stylebox("panel", "AcceptDialog", frame)
	th.set_color("title_color", "Window", CREAM)
	th.set_font("title_font", "Window", title)
	th.set_font_size("title_font_size", "Window", 30)
	th.set_constant("title_height", "Window", 40)

	# ---- Label
	th.set_color("font_color", "Label", INK)
	th.set_constant("line_spacing", "Label", 3)
	# muted note label
	th.set_type_variation("MutedLabel", "Label")
	th.set_color("font_color", "MutedLabel", MUTED)
	# title plank label (3s plank, ends 16; face inset top 1 / bottom 8)
	th.set_type_variation("TitlePlank", "Label")
	th.set_stylebox("normal", "TitlePlank", sbt("title_plank_3s_48x40.png", [16, 0, 16, 0], [24, 1, 24, 8]))
	th.set_font("font", "TitlePlank", title); th.set_font_size("font_size", "TitlePlank", 30)
	th.set_color("font_color", "TitlePlank", CREAM)
	th.set_color("font_shadow_color", "TitlePlank", OUTLINE)
	th.set_constant("shadow_offset_x", "TitlePlank", 1); th.set_constant("shadow_offset_y", "TitlePlank", 1)
	th.set_type_variation("TitlePlate", "Label")
	th.set_stylebox("normal", "TitlePlate", sbt("title_plate_312x46.png", [40, 0, 40, 0], [40, 4, 40, 11]))
	th.set_font("font", "TitlePlate", title); th.set_font_size("font_size", "TitlePlate", 30)
	th.set_color("font_color", "TitlePlate", CREAM); th.set_color("font_shadow_color", "TitlePlate", OUTLINE)
	th.set_constant("shadow_offset_x", "TitlePlate", 1); th.set_constant("shadow_offset_y", "TitlePlate", 1)

	# ---- Button (wood 9s 6; content margins = face insets so caps centre on the face)
	var focus := sbt("focus_ring_9s_16x16.png", [5, 5, 5, 5], [], false, [3, 3, 3, 3])
	th.set_stylebox("normal", "Button", sbt("wood_button_9s_normal_32x28.png", [6, 6, 6, 6], [12, 1, 12, 5]))
	th.set_stylebox("hover", "Button", sbt("wood_button_9s_hover_32x28.png", [6, 6, 6, 6], [12, 1, 12, 5]))
	th.set_stylebox("pressed", "Button", sbt("wood_button_9s_pressed_32x28.png", [6, 6, 6, 6], [12, 4, 12, 4]))
	th.set_stylebox("hover_pressed", "Button", sbt("wood_button_9s_selected_32x28.png", [6, 6, 6, 6], [12, 4, 12, 4]))
	th.set_stylebox("disabled", "Button", sbt("wood_button_9s_disabled_32x28.png", [6, 6, 6, 6], [12, 1, 12, 5]))
	th.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]: th.set_color(c, "Button", CREAM)
	th.set_color("font_disabled_color", "Button", DIS)
	th.set_color("font_outline_color", "Button", OUTLINE)
	th.set_constant("h_separation", "Button", 8)
	th.set_constant("icon_max_width", "Button", 32)
	# toggle-style selected (tabs / mode) = board wood_button_selected for pressed
	th.set_type_variation("ToggleButton", "Button")
	th.set_stylebox("pressed", "ToggleButton", sbt("wood_button_9s_selected_32x28.png", [6, 6, 6, 6], [12, 4, 12, 4]))

	# ---- Title menu (wood face, cream hero caps)
	th.set_type_variation("TitleMenuButton", "Button")
	for k in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		th.set_stylebox(k, "TitleMenuButton", th.get_stylebox(k, "Button"))
	th.set_stylebox("focus", "TitleMenuButton", focus)
	th.set_font("font", "TitleMenuButton", primary)
	th.set_font_size("font_size", "TitleMenuButton", 38)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		th.set_color(c, "TitleMenuButton", CREAM)
	th.set_color("font_disabled_color", "TitleMenuButton", DIS)
	th.set_color("font_outline_color", "TitleMenuButton", OUTLINE)
	th.set_constant("outline_size", "TitleMenuButton", 2)

	# ---- Menu button (BigButton: wood face, Silver 38 faux-bold caps: pause, options, confirm, care rows)
	th.set_type_variation("BigButton", "Button")
	th.set_font("font", "BigButton", primary)
	th.set_font_size("font_size", "BigButton", 38)

	# ---- Flat text button on parchment: no face, so the label must be ink, never cream
	th.set_type_variation("InkButton", "Button")
	for k in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		th.set_stylebox(k, "InkButton", StyleBoxEmpty.new())
	for c in ["font_color", "font_pressed_color", "font_focus_color"]: th.set_color(c, "InkButton", INK)
	th.set_color("font_hover_color", "InkButton", Color8(122, 78, 44))
	th.set_color("font_hover_pressed_color", "InkButton", Color8(122, 78, 44))
	th.set_color("font_disabled_color", "InkButton", MUTED)

	# ---- Primary button (battle action button, 9s 8)
	th.set_type_variation("PrimaryButton", "Button")
	th.set_stylebox("normal", "PrimaryButton", sbt("action_button_normal_160x44.png", [8, 8, 8, 8], [20, 1, 20, 5]))
	th.set_stylebox("hover", "PrimaryButton", sbt("action_button_hover_160x44.png", [8, 8, 8, 8], [20, 1, 20, 5]))
	th.set_stylebox("pressed", "PrimaryButton", sbt("action_button_pressed_160x44.png", [8, 8, 8, 8], [20, 4, 20, 4]))
	th.set_stylebox("disabled", "PrimaryButton", sbt("action_button_disabled_160x44.png", [8, 8, 8, 8], [20, 1, 20, 5]))
	th.set_font("font", "PrimaryButton", primary); th.set_font_size("font_size", "PrimaryButton", 38)
	# fallback faux bold if embolden rasterises soft: uncomment (1 px outline in the font colour)
	# th.set_constant("outline_size", "PrimaryButton", 1); th.set_color("font_outline_color", "PrimaryButton", CREAM)

	# ---- Close button (kit stop button 104x28)
	th.set_type_variation("CloseButton", "Button")
	th.set_stylebox("normal", "CloseButton", sbt("stop_button_normal_104x28.png", [8, 8, 8, 8], [10, 1, 8, 5]))
	th.set_stylebox("hover", "CloseButton", sbt("stop_button_hover_104x28.png", [8, 8, 8, 8], [10, 1, 8, 5]))
	th.set_stylebox("pressed", "CloseButton", sbt("stop_button_pressed_104x28.png", [8, 8, 8, 8], [10, 4, 8, 4]))
	th.set_stylebox("disabled", "CloseButton", sbt("stop_button_disabled_104x28.png", [8, 8, 8, 8], [10, 1, 8, 5]))

	# ---- TabBar / TabContainer
	th.set_stylebox("tab_unselected", "TabBar", sbt("wood_button_9s_normal_32x28.png", [6, 6, 6, 6], [12, 1, 12, 5]))
	th.set_stylebox("tab_hovered", "TabBar", sbt("wood_button_9s_hover_32x28.png", [6, 6, 6, 6], [12, 1, 12, 5]))
	th.set_stylebox("tab_selected", "TabBar", sbt("wood_button_9s_selected_32x28.png", [6, 6, 6, 6], [12, 4, 12, 4]))
	th.set_stylebox("tab_disabled", "TabBar", sbt("wood_button_9s_disabled_32x28.png", [6, 6, 6, 6], [12, 1, 12, 5]))
	th.set_stylebox("tab_focus", "TabBar", focus)
	for c in ["font_selected_color", "font_unselected_color", "font_hovered_color"]: th.set_color(c, "TabBar", CREAM)
	th.set_color("font_disabled_color", "TabBar", DIS)
	th.set_constant("h_separation", "TabBar", 6)
	for k in ["tab_unselected", "tab_hovered", "tab_selected", "tab_disabled", "tab_focus"]: th.set_stylebox(k, "TabContainer", th.get_stylebox(k, "TabBar"))
	for c in ["font_selected_color", "font_unselected_color", "font_hovered_color"]: th.set_color(c, "TabContainer", CREAM)
	th.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	th.set_constant("side_margin", "TabContainer", 0)

	# ---- HSlider (new pieces)
	th.set_stylebox("slider", "HSlider", sbt("slider_track_9s_24x14.png", [6, 5, 6, 5], [0, 7, 0, 7]))
	var fill := sbt("slider_fill_9s_16x14.png", [4, 4, 4, 4], [0, 7, 0, 7])
	th.set_stylebox("grabber_area", "HSlider", fill)
	th.set_stylebox("grabber_area_highlight", "HSlider", fill)
	th.set_icon("grabber", "HSlider", tex("slider_grabber_normal_14x24.png"))
	th.set_icon("grabber_highlight", "HSlider", tex("slider_grabber_hover_14x24.png"))
	th.set_icon("grabber_disabled", "HSlider", tex("slider_grabber_normal_14x24.png"))
	th.set_stylebox("focus", "HSlider", focus)
	th.set_icon("tick", "HSlider", PlaceholderTexture2D.new())

	# ---- CheckButton = kit switch (new pieces)
	th.set_icon("checked", "CheckButton", tex("toggle_on_normal_44x20.png"))
	th.set_icon("unchecked", "CheckButton", tex("toggle_off_normal_44x20.png"))
	th.set_icon("checked_disabled", "CheckButton", tex("toggle_on_normal_44x20.png"))
	th.set_icon("unchecked_disabled", "CheckButton", tex("toggle_off_normal_44x20.png"))
	for k in ["normal", "hover", "pressed", "hover_pressed", "disabled"]: th.set_stylebox(k, "CheckButton", StyleBoxEmpty.new())
	th.set_stylebox("focus", "CheckButton", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]: th.set_color(c, "CheckButton", INK)
	th.set_constant("h_separation", "CheckButton", 8)

	# ---- LineEdit / SpinBox (board field 9s 6)
	th.set_stylebox("normal", "LineEdit", sbt("field_9s_normal_24x24.png", [6, 6, 6, 6], [8, 4, 8, 4]))
	th.set_stylebox("focus", "LineEdit", sbt("field_9s_focus_24x24.png", [6, 6, 6, 6], [8, 4, 8, 4]))
	th.set_stylebox("read_only", "LineEdit", sbt("field_9s_disabled_24x24.png", [6, 6, 6, 6], [8, 4, 8, 4]))
	th.set_color("font_color", "LineEdit", INK)
	th.set_color("font_placeholder_color", "LineEdit", MUTED)
	th.set_color("caret_color", "LineEdit", INK)
	th.set_color("selection_color", "LineEdit", Color8(220, 192, 122))

	# SpinBox: no kit arrow piece yet, and the engine's white arrows float on parchment.
	# Fields stay editable by typing, wheel and arrow keys; screens that need steppers draw − / +.
	var no_icon := PlaceholderTexture2D.new()
	no_icon.size = Vector2(1, 1)
	for k in ["updown", "up", "up_hover", "up_pressed", "up_disabled", "down", "down_hover", "down_pressed", "down_disabled"]:
		th.set_icon(k, "SpinBox", no_icon)
	for k in ["up_background", "up_background_hovered", "up_background_pressed", "up_background_disabled", "down_background", "down_background_hovered", "down_background_pressed", "down_background_disabled", "field_and_buttons_separator", "up_down_buttons_separator"]:
		th.set_stylebox(k, "SpinBox", StyleBoxEmpty.new())
	th.set_constant("buttons_width", "SpinBox", 0)
	th.set_constant("field_and_buttons_separation", "SpinBox", 0)
	th.set_constant("set_min_buttons_width_from_icons", "SpinBox", 0)

	# ---- ScrollContainer / VScrollBar (board scroll pieces)
	th.set_stylebox("scroll", "VScrollBar", sbt("scroll_track_9s_12x24.png", [4, 4, 4, 4], [6, 2, 6, 2]))
	th.set_stylebox("grabber", "VScrollBar", sbt("scroll_thumb_9s_normal_12x16.png", [5, 5, 5, 5], [6, 8, 6, 8]))
	th.set_stylebox("grabber_highlight", "VScrollBar", sbt("scroll_thumb_9s_hover_12x16.png", [5, 5, 5, 5], [6, 8, 6, 8]))
	th.set_stylebox("grabber_pressed", "VScrollBar", sbt("scroll_thumb_9s_drag_12x16.png", [5, 5, 5, 5], [6, 8, 6, 8]))
	th.set_stylebox("panel", "ScrollContainer", sbt("play_bevel_9s_6x6.png", [2, 2, 2, 2], [4, 4, 4, 4]))

	# ---- ProgressBar (field track + pace green fill)
	th.set_stylebox("background", "ProgressBar", sbt("field_9s_normal_24x24.png", [6, 6, 6, 6], [4, 4, 4, 4]))
	th.set_stylebox("fill", "ProgressBar", sbt("slider_fill_9s_16x14.png", [4, 4, 4, 4]))
	th.set_color("font_color", "ProgressBar", INK)
	th.set_color("font_outline_color", "ProgressBar", CREAM)

	# ---- Tooltip / Popup
	th.set_stylebox("panel", "TooltipPanel", sbt("toast_9s_40x30.png", [12, 8, 12, 8], [12, 6, 12, 6]))
	th.set_color("font_color", "TooltipLabel", INK)
	th.set_font("font", "TooltipLabel", body); th.set_font_size("font_size", "TooltipLabel", 19)
	th.set_stylebox("panel", "PopupMenu", sbt("popup_9s_32x32.png", [8, 8, 8, 8], [8, 8, 8, 8]))
	th.set_stylebox("hover", "PopupMenu", sbt("pick_row_9s_hover_24x24.png", [6, 6, 6, 6]))
	th.set_stylebox("panel", "PopupPanel", sbt("popup_9s_32x32.png", [8, 8, 8, 8], [8, 8, 8, 8]))
	for c in ["font_color", "font_hover_color", "font_accelerator_color"]: th.set_color(c, "PopupMenu", INK)
	th.set_color("font_disabled_color", "PopupMenu", DIS)
	th.set_constant("v_separation", "PopupMenu", 6)

	if body == null or primary == null or title == null:
		_missing.append("font variations")
	if not _missing.is_empty():
		push_error("build_theme: missing %s; run --headless --import first" % ", ".join(_missing))
		quit(1)
		return
	var err := ResourceSaver.save(th, "res://assets/ui/manaforge_theme.tres")
	print("theme saved: ", error_string(err))
	quit(0 if err == OK else 1)
