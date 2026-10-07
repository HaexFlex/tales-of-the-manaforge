extends Node
## Manual reach fight. Strike, Brace, Salve, and Bile. No turn timer.


var _layer: CanvasLayer
var _title: Label
var _keeper_hp: Label
var _foes: VBoxContainer
var _telegraph: Label
var _log: Label
var _target: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 48
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.05, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	var panel := Panel.new()
	panel.name = "FightPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -420.0
	panel.offset_top = -250.0
	panel.offset_right = 420.0
	panel.offset_bottom = 250.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.08, 0.98)
	sb.border_color = Color(0.55, 0.42, 0.32, 1)
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(panel)
	_title = _label(panel, "Title", Vector2(24, 16), Vector2(520, 32), 22, Color(0.93, 0.9, 0.8))
	_keeper_hp = _label(panel, "KeeperHP", Vector2(24, 56), Vector2(360, 28), 16, Color(0.78, 0.9, 0.72))
	_telegraph = _label(panel, "Telegraph", Vector2(24, 92), Vector2(760, 32), 16, Color(0.95, 0.78, 0.45))
	_foes = VBoxContainer.new()
	_foes.name = "Foes"
	_foes.position = Vector2(24, 136)
	_foes.size = Vector2(520, 220)
	panel.add_child(_foes)
	_log = _label(panel, "Log", Vector2(24, 360), Vector2(500, 28), 14, Color(0.75, 0.78, 0.72))
	_button(panel, "Strike", Vector2(24, 408), _act.bind("strike"))
	_button(panel, "Brace", Vector2(176, 408), _act.bind("brace"))
	_button(panel, "Salve", Vector2(328, 408), _act.bind("salve"))
	_button(panel, "Bile", Vector2(480, 408), _act.bind("bile"))
	_button(panel, "Retreat", Vector2(632, 408), _act.bind("retreat"))
	var keeper_art := load("res://assets/art/echo/battle_keeper_idle_e.png") as Texture2D
	if keeper_art:
		var rect := TextureRect.new()
		rect.texture = keeper_art
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.position = Vector2(560, 40)
		rect.size = Vector2(220, 280)
		panel.add_child(rect)
	refresh()


func _process(_delta: float) -> void:
	if has_node("/root/Reach") and Reach.fight_active():
		refresh()


func refresh() -> void:
	if not has_node("/root/Reach"):
		return
	var snap: Dictionary = Reach.fight_snapshot()
	if snap.is_empty():
		return
	_title.text = "Depth %d    %s" % [int(snap.get("depth", 1)), Reach.boss_line()]
	_keeper_hp.text = "Keeper  %d / %d" % [int(snap.get("keeper_hp", 0)), int(snap.get("keeper_max", 1))]
	var note := str(snap.get("telegraph", ""))
	_telegraph.text = note if note != "" else " "
	_log.text = str(snap.get("log", ""))
	for child: Node in _foes.get_children():
		child.queue_free()
	var rows: Array = snap.get("enemies", []) as Array
	for i: int in range(rows.size()):
		var row: Dictionary = rows[i]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var art_path := str(row.get("art", ""))
		if art_path != "" and ResourceLoader.exists(art_path):
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(48, 48)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.texture = load(art_path) as Texture2D
			line.add_child(icon)
		var lbl := Label.new()
		var mark := ">" if i == _target and bool(row.get("alive", false)) else " "
		lbl.text = "%s %s  %d / %d  %s" % [mark, str(row.get("name", "")), int(row.get("hp", 0)), int(row.get("max_hp", 1)), str(row.get("telegraph", ""))]
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
		line.add_child(lbl)
		var pick := Button.new()
		pick.text = "Target"
		pick.disabled = not bool(row.get("alive", false))
		pick.pressed.connect(_pick.bind(i))
		line.add_child(pick)
		_foes.add_child(line)


func _pick(index: int) -> void:
	_target = index
	refresh()


func _act(action: String) -> void:
	if has_node("/root/Reach"):
		Reach.fight_choose(action, _target)


func _button(parent: Control, text: String, pos: Vector2, on_press: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(140, 40)
	btn.pressed.connect(on_press)
	parent.add_child(btn)


func _label(parent: Control, node_name: String, pos: Vector2, sz: Vector2, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl
