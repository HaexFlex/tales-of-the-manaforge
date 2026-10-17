## Theme test / preview. Run: godot --path <project> res://tools/theme_test.tscn  (writes previews, then quits)
## Shows kit_window, kit_dialog and one sample of every themed control.
extends Control

const OUT_DIR := "res://tools/_preview/"
var mode := "sampler"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="): mode = a.substr(7)
	if mode == "dialog": _dialog_only()
	else: _sampler()
	for i in 8: await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + "theme_test_%s_1x.png" % mode))
	print("saved ", mode)
	get_tree().quit()

func _bg(path: String) -> void:
	if not ResourceLoader.exists(path):   # backgrounds are scratch captures, not part of the package
		var c := ColorRect.new(); c.color = Color8(54, 96, 44); c.size = Vector2(1280, 720); add_child(c); return
	var t := TextureRect.new(); t.texture = load(path); add_child(t)

func _btn(text: String, variation := "", disabled := false, toggle := false, min := Vector2(0, 32)) -> Button:
	var b := Button.new(); b.text = text; b.theme_type_variation = variation; b.disabled = disabled
	b.toggle_mode = toggle; b.button_pressed = toggle; b.custom_minimum_size = min
	return b

func _label(t: String, variation := "") -> Label:
	var l := Label.new(); l.text = t; l.theme_type_variation = variation; return l

func _sampler() -> void:
	_bg("res://tools/hub_clean.png")
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.45); dim.size = Vector2(1280, 720); add_child(dim)
	var win: KitWindow = load("res://scenes/ui/kit_window.tscn").instantiate()
	win.position = Vector2(24, 44); win.size = Vector2(700, 650); win.title = "Options"; win.close_on_cancel = false
	add_child(win)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); win.content.add_child(v)
	var tabs := TabBar.new(); tabs.add_tab("Sound & game"); tabs.add_tab("Controls"); tabs.add_tab("Disabled"); tabs.set_tab_disabled(2, true); v.add_child(tabs)
	var g := GridContainer.new(); g.columns = 2; g.add_theme_constant_override("h_separation", 16); g.add_theme_constant_override("v_separation", 10); v.add_child(g)
	g.add_child(_label("HSlider")); var s := HSlider.new(); s.value = 70; s.custom_minimum_size = Vector2(300, 24); g.add_child(s)
	g.add_child(_label("CheckButton")); var hb := HBoxContainer.new(); var c1 := CheckButton.new(); c1.text = "On"; c1.button_pressed = true; hb.add_child(c1); var c2 := CheckButton.new(); c2.text = "Off"; hb.add_child(c2); g.add_child(hb)
	g.add_child(_label("LineEdit")); var le := LineEdit.new(); le.text = "Keeper"; le.custom_minimum_size = Vector2(200, 30); g.add_child(le)
	g.add_child(_label("SpinBox")); var sb := SpinBox.new(); sb.value = 12; sb.max_value = 100; g.add_child(sb)
	g.add_child(_label("ProgressBar")); var pb := ProgressBar.new(); pb.value = 62; pb.custom_minimum_size = Vector2(300, 22); g.add_child(pb)
	g.add_child(_label("Muted note", "MutedLabel")); g.add_child(_label("Body text: Silver 19 on parchment, ink #3E2A18."))
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8); v.add_child(row)
	row.add_child(_btn("Normal", "", false, false, Vector2(110, 32)))
	var focused := _btn("Focus", "", false, false, Vector2(110, 32)); row.add_child(focused)
	row.add_child(_btn("Selected", "ToggleButton", false, true, Vector2(110, 32)))
	row.add_child(_btn("Disabled", "", true, false, Vector2(110, 32)))
	var row2 := HBoxContainer.new(); row2.add_theme_constant_override("separation", 8); v.add_child(row2)
	row2.add_child(_btn("Continue", "PrimaryButton", false, false, Vector2(232, 44)))
	row2.add_child(_btn("Disabled", "PrimaryButton", true, false, Vector2(200, 44)))
	var sc := ScrollContainer.new(); sc.custom_minimum_size = Vector2(0, 150); sc.theme_type_variation = ""; v.add_child(sc)
	var pc := PanelContainer.new(); pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(pc)
	var list := VBoxContainer.new(); pc.add_child(list)
	for i in 10: list.add_child(_label("Row %d   Cycle %d · Sapling · played %d h" % [i + 1, i, i * 3]))
	pc.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	focused.grab_focus.call_deferred()
	# tooltip look (TooltipPanel scroll 9-slice + TooltipLabel) and a popup menu
	var tip := PanelContainer.new(); tip.theme_type_variation = "TooltipPanel"; tip.position = Vector2(760, 60); add_child(tip)
	var tl := Label.new(); tl.theme_type_variation = "TooltipLabel"; tl.text = "Essence 46\nGrows with every careful watering."; tip.add_child(tl)
	var pm := PopupMenu.new(); pm.add_item("Load"); pm.add_item("Save"); pm.add_separator(); pm.add_item("Delete"); pm.set_item_disabled(3, true); add_child(pm)
	pm.popup(Rect2i(760, 150, 160, 0))
	# kit dialog on the right
	var d: KitDialog = load("res://scenes/ui/kit_dialog.tscn").instantiate()
	d.free_on_answer = false; add_child(d)
	d.get_node("Dim").visible = false
	d.get_node("Window").position = Vector2(740, 330)
	d.setup("Begin again?", "Begin again as a new Keeper? Your saves stay safe: nothing is overwritten. Progress since your last save stays behind.", "Last save: Slot 1 · 4 min ago", "Stay", "Begin again")

func _dialog_only() -> void:
	_bg("res://tools/title_clean.png")
	var d: KitDialog = load("res://scenes/ui/kit_dialog.tscn").instantiate()
	add_child(d)
	d.setup("Begin again?", "Begin again as a new Keeper? Your saves stay safe: nothing is overwritten. Progress since your last save stays behind.", "Last save: Slot 1 · 4 min ago", "Stay", "Begin again")
