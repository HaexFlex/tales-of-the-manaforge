extends Area2D
## R5 PLACEHOLDER brewing stand beside the bench. ColorRect until art lands.

@onready var _placeholder: ColorRect = $Placeholder


func _ready() -> void:
	add_to_group("brewing_stand")
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	input_pickable = true
	visible = GameState.brewing_unlocked
	if _placeholder:
		_placeholder.color = Color(0.35, 0.55, 0.38, 0.85)
	if not GameState.echo_flags_changed.is_connected(_on_flags):
		GameState.echo_flags_changed.connect(_on_flags)


func _on_flags() -> void:
	visible = GameState.brewing_unlocked


func world_hover_name() -> String:
	return ContentStrings.get_text("brewing_stand_title")
