extends CanvasLayer
class_name BattleView
## Empty fullscreen arena. Later jobs fill the rows. This shell does not pause the tree.
## Layer 75 sits above Echo (50) and the HUD (20), and below the pause menu (100).
## One instance, parented to the hub, so a scene change drops it. A load closes it
## because loading does not rebuild the hub. No autoload: the debug button and
## Echo call these statics.


const SCENE_PATH: String = "res://scenes/battle/battle_scene.tscn"
const ARENA_LAYER: int = 75
const ARENA_SIZE: Vector2 = Vector2(1280.0, 720.0)
const SLOT_SIZE: Vector2 = Vector2(84.0, 108.0)
const SLOT_GAP: float = 12.0
const ROW_GAP: float = 24.0
const SIDE_MARGIN: float = 72.0
const FRONT_Y: float = 392.0
const BACKDROP: Color = Color(0.05, 0.14, 0.08, 1.0)
const OUTLINE: Color = Color(0.75, 0.86, 0.7, 0.38)

static var _current: Node = null

@onready var _background: ColorRect = $Background
@onready var _placeholder: Label = $Arena/Placeholder
@onready var _close_button: Button = $Arena/CloseButton
@onready var _slots: Control = $Arena/Slots


static func is_open() -> bool:
	return _current != null and is_instance_valid(_current) and not _current.is_queued_for_deletion()


static func open_arena() -> bool:
	## The call the Experimental "Battle arena (test)" button makes.
	## A second call keeps the one overlay. Echo and a manual reach fight refuse it.
	if is_open():
		return true
	if _refuses_open():
		return false
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("BattleView: arena scene missing")
		return false
	var view: BattleView = packed.instantiate() as BattleView
	if view == null:
		return false
	var host: Node = _host()
	if host == null:
		view.free()
		return false
	host.add_child(view)
	return is_open()


static func close_arena() -> void:
	if not is_open():
		return
	if _current.has_method("close_overlay"):
		_current.call("close_overlay")


static func _refuses_open() -> bool:
	## Static calls cannot name autoloads. Read the live nodes instead.
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	var echo: Node = tree.root.get_node_or_null("EchoChamber")
	if echo != null and bool(echo.get("in_battle")):
		return true
	var reach: Node = tree.root.get_node_or_null("Reach")
	if reach != null and reach.has_method("fight_active") and bool(reach.call("fight_active")):
		return true
	return false


static func _host() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var hubs: Array[Node] = tree.get_nodes_in_group("main_root")
	if not hubs.is_empty():
		return hubs[0]
	if tree.current_scene != null:
		return tree.current_scene
	return tree.root


func _enter_tree() -> void:
	## Pausable, like the hub. Nothing here sets get_tree().paused.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	layer = ARENA_LAYER
	add_to_group("battle_overlay")
	_current = self


func _ready() -> void:
	if _background:
		_background.color = BACKDROP
		_background.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_copy()
	_build_slot_outlines()
	if _close_button and not _close_button.pressed.is_connected(close_overlay):
		_close_button.pressed.connect(close_overlay)
	_bind_load()


func _exit_tree() -> void:
	_unbind_load()
	if _current == self:
		_current = null


func close_overlay() -> void:
	_unbind_load()
	if is_in_group("battle_overlay"):
		remove_from_group("battle_overlay")
	if _current == self:
		_current = null
	if is_inside_tree() and not is_queued_for_deletion():
		queue_free()


func _saves() -> Node:
	## class_name scripts are parsed before autoload names exist.
	return get_node_or_null("/root/SaveService")


func _bind_load() -> void:
	var saves: Node = _saves()
	if saves == null:
		return
	if not saves.is_connected("load_completed", _on_load_completed):
		saves.connect("load_completed", _on_load_completed)


func _unbind_load() -> void:
	var saves: Node = _saves()
	if saves != null and saves.is_connected("load_completed", _on_load_completed):
		saves.disconnect("load_completed", _on_load_completed)


func _on_load_completed(ok: bool) -> void:
	## The overlay is not part of the save. A loaded game starts with it closed.
	if ok:
		close_overlay()


func _apply_copy() -> void:
	var strings: Node = get_node_or_null("/root/ContentStrings")
	if _placeholder:
		var line: String = "Forest arena: art coming"
		if strings != null:
			line = str(strings.call("get_text", "adv_arena_placeholder"))
			if line == "" or line == "adv_arena_placeholder":
				line = "Forest arena: art coming"
		_placeholder.text = line
	if _close_button:
		var close_label: String = "Close"
		if strings != null:
			close_label = str(strings.call("get_text", "btn_close"))
		_close_button.text = close_label


func _build_slot_outlines() -> void:
	## Party on the left, beasts on the right. Front row, then a back row of
	## three, shifted half a slot toward the center so the rows don't stack.
	if _slots == null:
		return
	_add_row("party", false)
	_add_row("party", true)
	_add_row("beast", false)
	_add_row("beast", true)


func _add_row(side: String, back: bool) -> void:
	var step: float = SLOT_SIZE.x + SLOT_GAP
	var row_w: float = step * 2.0 + SLOT_SIZE.x
	var x: float = SIDE_MARGIN
	var y: float = FRONT_Y
	if side == "beast":
		x = ARENA_SIZE.x - SIDE_MARGIN - row_w
	if back:
		y = FRONT_Y - SLOT_SIZE.y - ROW_GAP
		if side == "party":
			x += SLOT_SIZE.x * 0.5
		else:
			x -= SLOT_SIZE.x * 0.5
	for i: int in 3:
		var mark := ReferenceRect.new()
		mark.name = "SlotOutline"
		mark.editor_only = false
		mark.border_color = OUTLINE
		mark.border_width = 2.0
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.position = Vector2(x + step * float(i), y)
		mark.size = SLOT_SIZE
		mark.add_to_group("battle_slot_outline")
		_slots.add_child(mark)


func _input(event: InputEvent) -> void:
	## Swallow world clicks even when the full-rect control is not the hovered
	## GUI (headless has no pointer). Escape closes this overlay before the
	## pause menu's unhandled key sees it. Already-handled GUI clicks, including
	## Close, are not delivered here.
	if is_queued_for_deletion():
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	close_overlay()
	get_viewport().set_input_as_handled()
