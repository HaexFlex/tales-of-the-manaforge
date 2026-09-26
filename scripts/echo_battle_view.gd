extends CanvasLayer
class_name EchoBattleView
## Separate battle surface. Big Keeper idle (same sheet frame) left; Elaia front right.
## Flavour lines at the top; battle log sits lower under the portraits.

const PORTRAIT: Vector2 = Vector2(384, 384)
const COMMAND_SIZE: Vector2 = Vector2(720, 120)
const LOG_SIZE: Vector2 = Vector2(1040, 100)
const SPEECH_SIZE: Vector2 = Vector2(1040, 80)
const KEEPER_IDLE: String = "res://assets/art/keeper/keeper_idle_south.png"
const ELAIA_FRONT: String = "res://assets/art/echo/elaia_front.png"

var _battle: EchoBattle
var _bg: ColorRect
var _ground: ColorRect
var _command_band: ColorRect
var _mercy_banner: ColorRect
var _mercy_label: Label
var _keeper_portrait: TextureRect
var _echo_portrait: TextureRect
var _keeper_hp_fill: ColorRect
var _echo_hp_fill: ColorRect
var _keeper_hp_label: Label
var _echo_hp_label: Label
var _title: Label
var _speech: Label
var _log: Label
var _strike: Button
var _flee: Button
var _spare: Button
var _return_btn: Button
var _mercy_shown: bool = false
var _waiting_return: bool = false
var _pending_outcome: String = ""
var _pending_toast: String = ""
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


func log_text() -> String:
	return _log.text if _log else ""


func portrait_size() -> Vector2:
	return PORTRAIT


func keeper_uses_idle_texture() -> bool:
	return _keeper_portrait != null and _keeper_portrait.texture != null \
		and str(_keeper_portrait.texture.resource_path).find("keeper_idle_south") >= 0


func echo_uses_elaia_texture() -> bool:
	return _echo_portrait != null and _echo_portrait.texture != null \
		and str(_echo_portrait.texture.resource_path).find("elaia_front") >= 0


func command_band_size() -> Vector2:
	return COMMAND_SIZE if _command_band == null else _command_band.size


func log_band_size() -> Vector2:
	return LOG_SIZE


func speech_band_size() -> Vector2:
	return SPEECH_SIZE


func speech_top() -> float:
	return _speech.position.y if _speech else -1.0


func log_top() -> float:
	return _log.position.y if _log else -1.0


func _enemy_name() -> String:
	return EchoChamber.echo_display_name()


func _bind() -> void:
	_battle = EchoChamber.battle
	if _battle == null:
		return
	_title.text = ContentStrings.get_text("battle_title")
	var echo_name: Label = get_node_or_null("EchoName") as Label
	var keeper_name: Label = get_node_or_null("KeeperName") as Label
	if keeper_name:
		keeper_name.text = ContentStrings.get_text("char_sheet_title")
	if echo_name:
		echo_name.text = _enemy_name()
	_refresh_bars(false)
	_refresh_log()
	if _battle.spare_window and _battle.outcome == "":
		_show_mercy()
		_refresh_actions()
		return
	_show_opening()
	_refresh_actions()


func _show_opening() -> void:
	if EchoChamber.reentry:
		_speech.text = ContentStrings.get_text("echo_01_return")
	else:
		_speech.text = "%s\n\n%s" % [
			ContentStrings.get_text("echo_01_intro"),
			ContentStrings.get_text("echo_01_intro_2"),
		]
	_set_mercy_visible(false)


func _show_mercy() -> void:
	_mercy_shown = true
	_speech.text = ContentStrings.get_text("echo_01_mercy")
	_set_mercy_visible(true)


func _set_mercy_visible(show: bool) -> void:
	if _mercy_banner:
		_mercy_banner.visible = show
	if _mercy_label:
		_mercy_label.visible = show
		if show:
			_mercy_label.text = ContentStrings.get_text("battle_mercy_hint", {"enemy": _enemy_name()})


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
	var before_echo: int = _battle.echo_hp
	_battle.choose(action)
	var outcome: String = _battle.outcome
	if action == "strike" and _battle.last_keeper_damage == 0 and before_echo == _battle.echo_hp and outcome == "":
		_speech.text = ContentStrings.get_text("battle_log_fists")
	if outcome == "ko":
		EchoChamber.finish_battle("ko")
		return
	_refresh_bars(true)
	_refresh_log()
	if _battle.spare_window and outcome == "":
		if not _mercy_shown:
			_show_mercy()
		_refresh_actions()
		return
	if outcome == "flee" or outcome == "spare" or outcome == "defeat":
		_offer_return(outcome)
		return
	_speech.text = ContentStrings.get_text("battle_your_turn")
	_refresh_actions()


func _offer_return(outcome: String) -> void:
	_waiting_return = true
	_pending_outcome = outcome
	_set_mercy_visible(false)
	_pending_toast = _outcome_toast(outcome)
	_speech.text = _flavour_for_outcome(outcome)
	_strike.visible = false
	_flee.visible = false
	_spare.visible = false
	_return_btn.visible = true
	if _log:
		_log.text = _pending_toast


func _flavour_for_outcome(outcome: String) -> String:
	match outcome:
		"flee":
			return ContentStrings.get_text("echo_01_flee")
		"spare":
			return ContentStrings.get_text("echo_01_spare")
		"defeat":
			return ContentStrings.get_text("echo_01_defeat")
	return ""


func _outcome_toast(outcome: String) -> String:
	var enemy: String = _enemy_name()
	var parts: PackedStringArray = PackedStringArray()
	match outcome:
		"flee":
			parts.append(ContentStrings.get_text("battle_flee_ok"))
		"spare":
			parts.append(ContentStrings.get_text("battle_spare_ok", {"enemy": enemy}))
			var shards: int = EchoChamber.snapshot_payout("spare")
			parts.append(ContentStrings.get_text("battle_shards_gain", {"amount": shards}))
			parts.append(ContentStrings.get_text("forge_key_relic_grant"))
			parts.append(ContentStrings.get_text("battle_companion_flag"))
			parts.append(ContentStrings.get_text("relic_slot_unlocked"))
		"defeat":
			parts.append(ContentStrings.get_text("battle_defeat_ok", {"enemy": enemy}))
			var shards_d: int = EchoChamber.snapshot_payout("defeat")
			parts.append(ContentStrings.get_text("battle_shards_gain", {"amount": shards_d}))
			parts.append(ContentStrings.get_text("forge_key_relic_grant"))
			parts.append(ContentStrings.get_text("relic_slot_unlocked"))
	return "\n".join(parts)


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
	_keeper_hp_fill.size = Vector2(PORTRAIT.x * clampf(keeper_ratio, 0.0, 1.0), 14.0)
	_echo_hp_fill.size = Vector2(PORTRAIT.x * clampf(echo_ratio, 0.0, 1.0), 14.0)
	_keeper_hp_label.text = ContentStrings.get_text("battle_hp", {
		"current": _battle.keeper_hp,
		"max": _battle.keeper_max_hp,
	})
	_echo_hp_label.text = ContentStrings.get_text("battle_hp", {
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
	_ground.offset_top = 500.0
	_ground.color = Color(0.14, 0.24, 0.18, 1)
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ground)
	_mercy_banner = ColorRect.new()
	_mercy_banner.name = "MercyBanner"
	_mercy_banner.position = Vector2(200, 2)
	_mercy_banner.size = Vector2(880, 20)
	_mercy_banner.color = Color(0.12, 0.22, 0.2, 0.94)
	_mercy_banner.visible = false
	_mercy_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mercy_banner)
	_mercy_label = Label.new()
	_mercy_label.name = "MercyLabel"
	_mercy_label.position = Vector2(216, 2)
	_mercy_label.size = Vector2(848, 18)
	_mercy_label.visible = false
	_mercy_label.add_theme_font_size_override("font_size", 12)
	_mercy_label.add_theme_color_override("font_color", Color(0.86, 0.92, 0.84, 1))
	add_child(_mercy_label)
	_title = _add_label("Title", Vector2(520, 2), Vector2(240, 14), ContentStrings.get_text("battle_title"), 15)
	var speech_bg := ColorRect.new()
	speech_bg.name = "SpeechBg"
	speech_bg.position = Vector2(120, 16)
	speech_bg.size = SPEECH_SIZE
	speech_bg.color = Color(0.09, 0.15, 0.13, 0.94)
	speech_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speech_bg)
	_speech = Label.new()
	_speech.name = "Speech"
	_speech.position = Vector2(136, 20)
	_speech.size = Vector2(1008, 72)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.add_theme_font_size_override("font_size", 14)
	_speech.add_theme_color_override("font_color", Color(0.86, 0.91, 0.84, 1))
	add_child(_speech)
	_add_label("KeeperName", Vector2(56, 98), Vector2(384, 16), ContentStrings.get_text("char_sheet_title"), 15)
	_add_label("EchoName", Vector2(840, 98), Vector2(384, 16), EchoChamber.echo_display_name(), 15)
	_keeper_portrait = _keeper_texture(Vector2(56, 114))
	_echo_portrait = _echo_texture(Vector2(840, 114))
	var log_bg := ColorRect.new()
	log_bg.name = "LogBg"
	# Portraits end at y=498; log under them (lock: 100–140 above commands).
	log_bg.position = Vector2(120, 500)
	log_bg.size = LOG_SIZE
	log_bg.color = Color(0.08, 0.13, 0.11, 0.9)
	log_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(log_bg)
	_add_label("LogTitle", Vector2(560, 506), Vector2(160, 18), ContentStrings.get_text("battle_log_title"), 12)
	_log = Label.new()
	_log.name = "Log"
	_log.position = Vector2(136, 526)
	_log.size = Vector2(1008, 68)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.add_theme_font_size_override("font_size", 12)
	_log.add_theme_color_override("font_color", Color(0.7, 0.78, 0.7, 1))
	add_child(_log)
	# HP under each portrait; paint after log so bars stay readable.
	_keeper_hp_fill = _hp_bar("KeeperHp", Vector2(56, 500), Color(0.52, 0.62, 0.28, 1))
	_echo_hp_fill = _hp_bar("EchoHp", Vector2(840, 500), Color(0.32, 0.58, 0.56, 1))
	_keeper_hp_label = _add_label("KeeperHpText", Vector2(56, 516), Vector2(384, 16), "", 12)
	_echo_hp_label = _add_label("EchoHpText", Vector2(840, 516), Vector2(384, 16), "", 12)
	_command_band = ColorRect.new()
	_command_band.name = "CommandBand"
	_command_band.position = Vector2(280, 600)
	_command_band.size = COMMAND_SIZE
	_command_band.color = Color(0.08, 0.14, 0.12, 0.96)
	_command_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_command_band)
	_strike = _button("StrikeButton", Vector2(308, 636), "battle_strike")
	_flee = _button("FleeButton", Vector2(540, 636), "battle_flee")
	_spare = _button("SpareButton", Vector2(772, 636), "battle_spare")
	_return_btn = _button("ReturnButton", Vector2(540, 636), "battle_return")
	_return_btn.visible = false
	_strike.pressed.connect(_on_strike)
	_flee.pressed.connect(_on_flee)
	_spare.pressed.connect(_on_spare)
	_return_btn.pressed.connect(_on_return)


func _keeper_texture(pos: Vector2) -> TextureRect:
	var frame := ColorRect.new()
	frame.name = "KeeperPortraitFrame"
	frame.position = pos - Vector2(6, 6)
	frame.size = PORTRAIT + Vector2(12, 12)
	frame.color = Color(0.04, 0.07, 0.06, 1)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var tex_rect := TextureRect.new()
	tex_rect.name = "KeeperPortrait"
	tex_rect.position = pos
	tex_rect.size = PORTRAIT
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(KEEPER_IDLE) as Texture2D
	tex_rect.texture = tex
	add_child(tex_rect)
	return tex_rect


func _echo_texture(pos: Vector2) -> TextureRect:
	var frame := ColorRect.new()
	frame.name = "EchoPortraitFrame"
	frame.position = pos - Vector2(6, 6)
	frame.size = PORTRAIT + Vector2(12, 12)
	frame.color = Color(0.04, 0.07, 0.06, 1)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var tex_rect := TextureRect.new()
	tex_rect.name = "EchoPortrait"
	tex_rect.position = pos
	tex_rect.size = PORTRAIT
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(ELAIA_FRONT) as Texture2D
	tex_rect.texture = tex
	add_child(tex_rect)
	return tex_rect


func _hp_bar(node_name: String, pos: Vector2, fill_color: Color) -> ColorRect:
	var back := ColorRect.new()
	back.name = node_name + "Back"
	back.position = pos
	back.size = Vector2(PORTRAIT.x, 14)
	back.color = Color(0.04, 0.06, 0.05, 1)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var fill := ColorRect.new()
	fill.name = node_name + "Fill"
	fill.position = pos
	fill.size = Vector2(PORTRAIT.x, 14)
	fill.color = fill_color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	return fill


func _add_label(node_name: String, pos: Vector2, sz: Vector2, text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.86, 1))
	add_child(lbl)
	return lbl


func _button(node_name: String, pos: Vector2, key: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(200, 40)
	btn.text = ContentStrings.get_text(key)
	add_child(btn)
	return btn
