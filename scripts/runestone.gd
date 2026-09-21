extends Area2D
class_name Runestone
## One hub stone per combat stat. Click to spend Manashards for +1 rank.
## Placeholder polygon — Haex replaces the art later.

@export var stat_id: StringName = &"might"

@onready var stone: Polygon2D = $Stone
@onready var label: Label = $Label


func _ready() -> void:
	add_to_group("runestone")
	add_to_group("interactable")
	y_sort_enabled = true
	input_pickable = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_event.connect(_on_input_event)
	if not KeeperStats.ranks_changed.is_connected(_on_ranks):
		KeeperStats.ranks_changed.connect(_on_ranks)
	if not GameState.resources_changed.is_connected(_on_resources):
		GameState.resources_changed.connect(_on_resources)
	_refresh()


func _on_ranks(_stat_id: StringName) -> void:
	_refresh()


func _on_resources(resource_id: StringName, _amount: int) -> void:
	if resource_id == &"manashards":
		_refresh()


func _refresh() -> void:
	var sid: String = String(stat_id)
	var tint: Color = KeeperStats.stat_color(sid)
	var cost: int = KeeperStats.get_next_cost(sid)
	if cost >= 0 and GameState.manashards < cost:
		tint = tint.darkened(0.35)
	if stone:
		stone.color = tint
	if label == null:
		return
	var stat_name: String = KeeperStats.stat_display_name(sid)
	if cost < 0:
		label.text = "%s\n%s" % [stat_name, ContentStrings.get_text("runestone_maxed")]
	else:
		label.text = "%s\n%s" % [stat_name, ContentStrings.get_text("runestone_cost", {"cost": cost})]


func _world_blocked() -> bool:
	var mains: Array[Node] = get_tree().get_nodes_in_group("main_root")
	if mains.is_empty():
		return GameState.fruit_committed
	var main: Node = mains[0]
	if main.has_method("world_input_blocked"):
		return bool(main.call("world_input_blocked"))
	return false


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if _world_blocked():
		return
	var result: String = KeeperStats.try_buy(String(stat_id))
	var stat_name: String = KeeperStats.stat_display_name(String(stat_id))
	var cost: int = KeeperStats.get_next_cost(String(stat_id))
	match result:
		"ok":
			GameAudio.play_upgrade_buy()
			GameState.status_message.emit(ContentStrings.get_text("runestone_buy_ok", {
				"stat": stat_name,
				"rank": KeeperStats.get_rank(String(stat_id)),
			}))
			SaveService.save_game()
		"cant_afford":
			GameAudio.play_tree_deny()
			GameState.status_message.emit(ContentStrings.get_text("runestone_cant_afford", {
				"stat": stat_name,
				"cost": maxi(cost, 0),
			}))
		"pending_ascend":
			GameAudio.play_tree_deny()
			GameState.status_message.emit(ContentStrings.get_text("runestone_pending"))
		"maxed":
			GameAudio.play_tree_deny()
			GameState.status_message.emit(ContentStrings.get_text("runestone_maxed"))
		_:
			GameAudio.play_tree_deny()
	_refresh()
