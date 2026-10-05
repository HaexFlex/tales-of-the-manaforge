extends Area2D
## Hub brewing stand. Unlocks when Corvane joins. Placeholder art until Art ships the prop.
## ID: res://assets/art/props/brewing_stand.png

const STAND_SIZE: Vector2 = Vector2(64, 80)


func _ready() -> void:
	add_to_group("brewing_stand")
	add_to_group("interactable")
	z_index = 0
	y_sort_enabled = true
	position = Adventure.BREWING_STAND_POS
	input_pickable = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_build_visual()
	_build_pick()
	input_event.connect(_on_input_event)
	if not Adventure.adventure_changed.is_connected(refresh):
		Adventure.adventure_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var show_it: bool = Adventure.brewing_unlocked
	visible = show_it
	input_pickable = show_it
	monitorable = show_it


func _build_visual() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex: Texture2D = null
	if ResourceLoader.exists(Adventure.ART_BREWING_STAND):
		tex = load(Adventure.ART_BREWING_STAND) as Texture2D
	if tex != null:
		sprite.texture = tex
		sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	else:
		sprite.offset = Vector2(-STAND_SIZE.x * 0.5, -STAND_SIZE.y)
	add_child(sprite)
	if tex == null:
		var swatch := Polygon2D.new()
		swatch.name = "Placeholder"
		swatch.color = Color(0.45, 0.32, 0.18, 1)
		swatch.polygon = PackedVector2Array([
			Vector2(-STAND_SIZE.x * 0.5, -STAND_SIZE.y),
			Vector2(STAND_SIZE.x * 0.5, -STAND_SIZE.y),
			Vector2(STAND_SIZE.x * 0.5, 0),
			Vector2(-STAND_SIZE.x * 0.5, 0),
		])
		add_child(swatch)
	var label := Label.new()
	label.name = "Label"
	label.position = Vector2(-48, -STAND_SIZE.y - 22)
	label.size = Vector2(96, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = ContentStrings.get_text("brewing_stand_label")
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	add_child(label)


func _build_pick() -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(72, 64)
	shape_node.shape = rect
	shape_node.position = Vector2(0, -32)
	add_child(shape_node)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not visible or not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	get_viewport().set_input_as_handled()
	Adventure.open_panel()
