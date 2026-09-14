extends Node2D
## Main 1280×720 clearing: click-to-move, Manatree, 64px gatherables, HUD.

@onready var keeper: Keeper = $Keeper
@onready var manatree: Manatree = $Manatree
@onready var hud: GameHUD = $HUD
@onready var ground: ColorRect = $Ground


func _ready() -> void:
	ground.color = Color("243528")
	ground.mouse_filter = Control.MOUSE_FILTER_STOP
	ground.gui_input.connect(_on_ground_input)
	manatree.fruit_menu_requested.connect(_on_fruit_menu)
	if SaveService.has_save():
		SaveService.load_game()


func _on_ground_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var world: Vector2 = ground.global_position + mb.position
			keeper.move_to(world, null)


func _on_fruit_menu() -> void:
	hud.show_prestige_menu()
