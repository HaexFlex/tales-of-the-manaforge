extends CanvasLayer
class_name EchoBattleView
## Separate battle surface. ColorRects stand in for missing portraits.
## Silence underneath: the hub bed is already stopped. No battle sting.

var _battle: EchoBattle
var _bg: ColorRect
var _ground: ColorRect
var _keeper_portrait: ColorRect
var _echo_portrait: ColorRect
var _keeper_hp_fill: ColorRect
var _echo_hp_fill: ColorRect
var _keeper_hp_label: Label
var _echo_hp_label: Label
var _speech: Label
var _log: Label
var _strike: Button
var _flee: Button
var _spare: Button
var _return_btn: Button
var _mercy_shown: bool = false
var _waiting_return: bool = false
var _pending_outcome: String = ""
var _pulse: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build()
	_bind()


func _process(delta: float) -> void:
	_pulse += delta
	if _echo_portrait:
		var echo_breath: float = 0.9 + 0.1 * sin(_pulse * 1.35)
		_echo_portrait.modulate = Color(echo_breath, echo_breath, echo_breath, 1.0)
	if _keeper_portrait:
		var keeper_breath: float = 0.92 + 0.08 * sin(_pulse * 1.05 + 0.8)
		_keeper_portrait.modulate = Color(keeper_breath, keeper_breath, keeper_breath, 1.0)
	if _ground:
		var ground_shift: float = 0.96 + 0.04 * sin(_pulse * 0.7)
		_ground.modulate = Color(ground_shift, ground_shift, ground_shift, 1.0)


func is_flee_shown() -> bool:
	return _flee != null and _flee.visible


func is_spare_shown() -> bool:
	return _spare != null and _spare.visible


func is_strike_shown() -> bool:
	return _strike != null and _strike.visible


func speech_text() -> String:
	return _speech.text if _speech else ""


func _bind() -> void:
	_battle = EchoChamber.battle
	if _battle == null:
		return
	var keeper_name: Label = get_node_or_null("KeeperName") as Label
	var echo_name: Label = get_node_or_null("EchoName") as Label
	if keeper_name:
		keeper_name.text = ContentStrings.get_text("echo_battle_keeper")
	if echo_name:
		echo_name.text = _battle.echo_name
	_refresh_bars(false)
	_refresh_log()
	if _battle.spare_window and _battle.outcome == "":
		_speech.text = ContentStrings.get_text("echo_01_mercy")
		_mercy_shown = true
		_refresh_actions()
		return
	_show_opening()
	_refresh_actions()


func _show_opening() -> void:
	var parts: PackedStringArray = PackedStringArray()
	if EchoChamber.reentry:
		parts.append(ContentStrings.get_text("echo_01_return"))
	else:
		if not GameState.echo_01_narrator_heard:
			parts.append(ContentStrings.get_text("echo_01_narrator"))
			GameState.echo_01_narrator_heard = true
		parts.append(ContentStrings.get_text("echo_01_intro"))
	_speech.text = "\n\n".join(parts)


func _on_strike() -> void:
	_choose("strike")


func _on_flee() -> void:
	_choose("flee")


func _on_spare() -> void:
	_choose("spare")


func _choose(action: String) -> void:
	if _battle == null or _waiting_return:
		return
	GameAudio.play_ui_confirm()
	_battle.choose(action)
	var outcome: String = _battle.outcome
	if outcome == "ko":
		EchoChamber.finish_battle("ko")
		return
	_refresh_bars(true)
	_refresh_log()
	if _battle.spare_window and outcome == "":
		if not _mercy_shown:
			_speech.text = ContentStrings.get_text("echo_01_mercy")
			_mercy_shown = true
		_refresh_actions()
		return
	if outcome == "flee" or outcome == "spare" or outcome == "defeat":
		_offer_return(outcome)
		return
	_refresh_actions()


func _offer_return(outcome: String) -> void:
	_waiting_return = true
	_pending_outcome = outcome
	_speech.text = ContentStrings.get_text("echo_01_%s" % outcome)
	_strike.visible = false
	_flee.visible = false
	_spare.visible = false
	_return_btn.visible = true


func _on_return() -> void:
	if _pending_outcome == "":
		return
	var outcome: String = _pending_outcome
	_pending_outcome = ""
	GameAudio.play_ui_confirm()
	EchoChamber.finish_battle(outcome)


func _refresh_actions() -> void:
	if _battle == null:
		return
	var actions: PackedStringArray = _battle.available_actions()
	_strike.visible = actions.has("strike")
	_flee.visible = actions.has("flee")
	_spare.visible = actions.has("spare")
	_return_btn.visible = false


func _refresh_bars(flash: bool) -> void:
	if _battle == null:
		return
	var keeper_ratio: float = float(_battle.keeper_hp) / float(maxi(1, _battle.keeper_max_hp))
	var echo_ratio: float = float(_battle.echo_hp) / float(maxi(1, _battle.echo_max_hp))
	_keeper_hp_fill.size = Vector2(220.0 * clampf(keeper_ratio, 0.0, 1.0), 16.0)
	_echo_hp_fill.size = Vector2(220.0 * clampf(echo_ratio, 0.0, 1.0), 16.0)
	_keeper_hp_label.text = ContentStrings.get_text("echo_hp_label", {
		"current": _battle.keeper_hp,
		"max": _battle.keeper_max_hp,
	})
	_echo_hp_label.text = ContentStrings.get_text("echo_hp_label", {
		"current": _battle.echo_hp,
		"max": _battle.echo_max_hp,
	})
	if flash and _echo_portrait:
		_echo_portrait.modulate = Color(1.15, 1.15, 1.15, 1.0)


func _refresh_log() -> void:
	if _battle == null or _log == null:
		return
	var lines: PackedStringArray = _battle.log
	var start: int = maxi(0, lines.size() - 4)
	var shown: PackedStringArray = PackedStringArray()
	for i: int in range(start, lines.size()):
		shown.append(lines[i])
	_log.text = "\n".join(shown)


func _build() -> void:
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.07, 0.12, 0.11, 1)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)
	_ground = ColorRect.new()
	_ground.name = "Ground"
	_ground.anchor_right = 1.0
	_ground.anchor_bottom = 1.0
	_ground.offset_top = 520.0
	_ground.color = Color(0.14, 0.24, 0.18, 1)
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ground)
	_keeper_portrait = _portrait("KeeperPortrait", Vector2(96, 120), Color(0.62, 0.46, 0.26, 1))
	_echo_portrait = _portrait("EchoPortrait", Vector2(1004, 120), Color(0.22, 0.42, 0.44, 1))
	_add_name("KeeperName", Vector2(96, 78), ContentStrings.get_text("echo_battle_keeper"))
	_add_name("EchoName", Vector2(1004, 78), EchoChamber.echo_display_name())
	_keeper_hp_fill = _hp_bar("KeeperHp", Vector2(96, 360), Color(0.52, 0.62, 0.28, 1))
	_echo_hp_fill = _hp_bar("EchoHp", Vector2(1004, 360), Color(0.32, 0.58, 0.56, 1))
	_keeper_hp_label = _add_name("KeeperHpText", Vector2(96, 384), "")
	_echo_hp_label = _add_name("EchoHpText", Vector2(1004, 384), "")
	var speech_bg := ColorRect.new()
	speech_bg.name = "SpeechBg"
	speech_bg.position = Vector2(300, 140)
	speech_bg.size = Vector2(680, 250)
	speech_bg.color = Color(0.09, 0.15, 0.13, 0.94)
	speech_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speech_bg)
	_speech = Label.new()
	_speech.name = "Speech"
	_speech.position = Vector2(320, 156)
	_speech.size = Vector2(640, 220)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.add_theme_font_size_override("font_size", 18)
	_speech.add_theme_color_override("font_color", Color(0.86, 0.91, 0.84, 1))
	add_child(_speech)
	_log = Label.new()
	_log.name = "Log"
	_log.position = Vector2(320, 400)
	_log.size = Vector2(640, 88)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.add_theme_font_size_override("font_size", 14)
	_log.add_theme_color_override("font_color", Color(0.7, 0.78, 0.7, 1))
	add_child(_log)
	_strike = _button("StrikeButton", Vector2(300, 620), "echo_battle_strike")
	_flee = _button("FleeButton", Vector2(520, 620), "echo_battle_flee")
	_spare = _button("SpareButton", Vector2(740, 620), "echo_battle_spare")
	_return_btn = _button("ReturnButton", Vector2(480, 620), "echo_battle_return")
	_return_btn.visible = false
	_strike.pressed.connect(_on_strike)
	_flee.pressed.connect(_on_flee)
	_spare.pressed.connect(_on_spare)
	_return_btn.pressed.connect(_on_return)


func _portrait(node_name: String, pos: Vector2, color: Color) -> ColorRect:
	var frame := ColorRect.new()
	frame.name = node_name + "Frame"
	frame.position = pos - Vector2(8, 8)
	frame.size = Vector2(196, 236)
	frame.color = Color(0.04, 0.07, 0.06, 1)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = pos
	rect.size = Vector2(180, 220)
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


func _hp_bar(node_name: String, pos: Vector2, fill_color: Color) -> ColorRect:
	var back := ColorRect.new()
	back.name = node_name + "Back"
	back.position = pos
	back.size = Vector2(220, 16)
	back.color = Color(0.04, 0.06, 0.05, 1)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var fill := ColorRect.new()
	fill.name = node_name + "Fill"
	fill.position = pos
	fill.size = Vector2(220, 16)
	fill.color = fill_color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	return fill


func _add_name(node_name: String, pos: Vector2, text: String) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = Vector2(220, 28)
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.86, 1))
	add_child(lbl)
	return lbl


func _button(node_name: String, pos: Vector2, key: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(200, 48)
	btn.text = ContentStrings.get_text(key)
	add_child(btn)
	return btn
