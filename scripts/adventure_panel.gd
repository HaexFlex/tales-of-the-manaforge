extends CanvasLayer
## Hub panel for Phase 0 reaches, crates, and the brewing stand.
## Hidden until the scar from Echo 2. Wisps are not part of this panel.

var _root: Control
var _panel: Panel
var _body: Label
var _open_btn: Button
var _idle_btn: Button
var _manual_btn: Button
var _cancel_btn: Button
var _fight_btn: Button
var _crate_btn: Button
var _salve_btn: Button
var _bile_btn: Button
var _keeper_btn: Button
var _elaia_btn: Button
var _glow_icon: TextureRect
var _root_icon: TextureRect
var _salve_icon: TextureRect
var _bile_icon: TextureRect
var _glow_count: Label
var _root_count: Label
var _salve_count: Label
var _bile_count: Label
var _sheet_bust: TextureRect
var _open: bool = false


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build()
	if not Adventure.adventure_changed.is_connected(sync):
		Adventure.adventure_changed.connect(sync)
	sync()


func toggle() -> void:
	if not Adventure.adventure_unlocked:
		return
	_open = not _open
	sync()


func open() -> void:
	if not Adventure.adventure_unlocked:
		return
	_open = true
	sync()


func sync() -> void:
	if _root == null:
		return
	var unlocked: bool = Adventure.adventure_unlocked
	_root.visible = unlocked
	_open_btn.visible = unlocked
	_panel.visible = unlocked and _open
	if not unlocked:
		return
	_open_btn.text = ContentStrings.get_text("adventure_title")
	_write_body()
	_idle_btn.disabled = Adventure.reach_active or Adventure.awaiting_manual
	_manual_btn.disabled = _idle_btn.disabled
	_cancel_btn.disabled = not Adventure.reach_active and not Adventure.awaiting_manual
	_fight_btn.visible = Adventure.awaiting_manual
	_crate_btn.disabled = Adventure.crate_count() <= 0
	_crate_btn.text = ContentStrings.get_text("adventure_open_crate", {"count": Adventure.crate_count()})
	var brew: bool = Adventure.brewing_unlocked
	_salve_btn.visible = brew
	_bile_btn.visible = brew
	_salve_btn.disabled = not brew
	_bile_btn.disabled = not brew
	_salve_btn.text = ContentStrings.get_text("heart_salve_name")
	_bile_btn.text = ContentStrings.get_text("bile_vial_name")
	_glow_count.text = str(Adventure.herb_count("glowcap"))
	_root_count.text = str(Adventure.herb_count("bitterroot"))
	_salve_count.text = str(Adventure.potion_count("heart_salve"))
	_bile_count.text = str(Adventure.potion_count("bile_vial"))
	_sheet_bust.visible = Adventure.puff_promised or Adventure.puff_joined
	_keeper_btn.text = _party_label("keeper", "adventure_party_keeper")
	_elaia_btn.text = _party_label("elaia", "adventure_party_elaia")
	_elaia_btn.disabled = not GameState.elaia_in_party() or Adventure.reach_active or Adventure.awaiting_manual
	_keeper_btn.disabled = Adventure.reach_active or Adventure.awaiting_manual


func _party_label(actor: String, key: String) -> String:
	var mark: String = "✓ " if Adventure.selected_party.has(actor) else ""
	return "%s%s" % [mark, ContentStrings.get_text(key)]


func _write_body() -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(ContentStrings.get_text("adventure_reaches", {"count": Adventure.cumulative_reaches}))
	if Adventure.reach_active:
		var left: float = maxf(0.0, Adventure.reach_duration_sec() - Adventure.reach_elapsed)
		var mins: int = int(left) / 60
		var secs: int = int(left) % 60
		var mode: String = ContentStrings.get_text("adventure_manual_mode" if Adventure.reach_mode == "manual" else "adventure_idle_mode")
		lines.append(ContentStrings.get_text("adventure_timer", {"mode": mode, "mins": mins, "secs": secs}))
	elif Adventure.awaiting_manual:
		lines.append(ContentStrings.get_text("adventure_manual_ready"))
	elif Adventure.ancient_blocks_adventure():
		lines.append(ContentStrings.get_text("adventure_locked_ancient"))
	if Adventure.cumulative_reaches >= 6 and not Adventure.brewing_unlocked:
		lines.append(ContentStrings.get_text("adventure_brew_preview"))
	if Adventure.puff_promised and not Adventure.puff_joined:
		lines.append(ContentStrings.get_text("adventure_promised"))
	lines.append(ContentStrings.get_text("adventure_herbs", {
		"glowcap": Adventure.herb_count("glowcap"),
		"bitterroot": Adventure.herb_count("bitterroot"),
	}))
	_body.text = "\n".join(lines)


func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_open_btn = Button.new()
	_open_btn.name = "OpenAdventure"
	_open_btn.position = Vector2(16, 640)
	_open_btn.size = Vector2(168, 36)
	_open_btn.focus_mode = Control.FOCUS_NONE
	_open_btn.pressed.connect(toggle)
	_root.add_child(_open_btn)
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.position = Vector2(16, 208)
	_panel.size = Vector2(420, 400)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.1, 0.96)
	sb.border_color = Color(0.45, 0.62, 0.48, 1)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(_panel)
	_body = _label(Vector2(16, 12), Vector2(340, 112))
	_sheet_bust = _art_icon(Adventure.ART_PUFF_SHEET, Adventure.SHEET_FRAME, Vector2(364, 12), Vector2(40, 40))
	_sheet_bust.tooltip_text = ContentStrings.get_text("puff_name")
	_glow_icon = _art_icon(Adventure.ART_GLOWCAP, Vector2i(32, 32), Vector2(16, 128), Vector2(32, 32))
	_glow_count = _count_label(Vector2(50, 132))
	_glow_icon.tooltip_text = ContentStrings.get_text("glowcap_name")
	_root_icon = _art_icon(Adventure.ART_BITTERROOT, Vector2i(32, 32), Vector2(112, 128), Vector2(32, 32))
	_root_count = _count_label(Vector2(146, 132))
	_root_icon.tooltip_text = ContentStrings.get_text("bitterroot_name")
	_salve_icon = _art_icon(Adventure.ART_HEART_SALVE, Vector2i(32, 32), Vector2(208, 128), Vector2(32, 32))
	_salve_count = _count_label(Vector2(242, 132))
	_salve_icon.tooltip_text = ContentStrings.get_text("heart_salve_name")
	_bile_icon = _art_icon(Adventure.ART_BILE_VIAL, Vector2i(32, 32), Vector2(304, 128), Vector2(32, 32))
	_bile_count = _count_label(Vector2(338, 132))
	_bile_icon.tooltip_text = ContentStrings.get_text("bile_vial_name")
	_keeper_btn = _button(Vector2(16, 172), Vector2(140, 32), _on_keeper)
	_elaia_btn = _button(Vector2(164, 172), Vector2(140, 32), _on_elaia)
	_idle_btn = _button(Vector2(16, 214), Vector2(188, 34), _on_idle)
	_manual_btn = _button(Vector2(214, 214), Vector2(188, 34), _on_manual)
	_idle_btn.text = ContentStrings.get_text("adventure_send_idle")
	_manual_btn.text = ContentStrings.get_text("adventure_send_manual")
	_cancel_btn = _button(Vector2(16, 256), Vector2(188, 34), _on_cancel)
	_fight_btn = _button(Vector2(214, 256), Vector2(188, 34), _on_fight)
	_cancel_btn.text = ContentStrings.get_text("adventure_cancel")
	_fight_btn.text = ContentStrings.get_text("adventure_manual_ready")
	_crate_btn = _button(Vector2(16, 300), Vector2(388, 32), _on_crate)
	_salve_btn = _button(Vector2(16, 342), Vector2(188, 32), _on_salve)
	_bile_btn = _button(Vector2(214, 342), Vector2(188, 32), _on_bile)


func _label(pos: Vector2, sz: Vector2) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = sz
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.78))
	_panel.add_child(lbl)
	return lbl


func _art_icon(path: String, frame: Vector2i, pos: Vector2, sz: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.position = pos
	icon.size = sz
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Adventure.frame_slice(path, frame)
	_panel.add_child(icon)
	return icon


func _count_label(pos: Vector2) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = Vector2(48, 24)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.78))
	_panel.add_child(lbl)
	return lbl


func _button(pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(cb)
	_panel.add_child(btn)
	return btn


func _on_keeper() -> void:
	Adventure.toggle_party_member("keeper")


func _on_elaia() -> void:
	Adventure.toggle_party_member("elaia")


func _on_idle() -> void:
	_toast_start(Adventure.try_start_reach("idle"))


func _on_manual() -> void:
	_toast_start(Adventure.try_start_reach("manual"))


func _on_cancel() -> void:
	Adventure.cancel_reach()


func _on_fight() -> void:
	Adventure.present_manual_battle()


func _on_crate() -> void:
	Adventure.open_crate(0)


func _on_salve() -> void:
	_toast_brew(Adventure.try_brew("heart_salve"))


func _on_bile() -> void:
	_toast_brew(Adventure.try_brew("bile_vial"))


func _toast_start(result: String) -> void:
	if result == "ok" or not has_node("/root/GameState"):
		return
	var key: String = "adventure_start_%s" % result
	var text: String = ContentStrings.get_text(key)
	if text == key:
		text = ContentStrings.get_text("adventure_start_locked")
	GameState.status_message.emit(text)


func _toast_brew(result: String) -> void:
	if result == "ok" or not has_node("/root/GameState"):
		return
	GameState.status_message.emit(ContentStrings.get_text("adventure_brew_%s" % result))
