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
const ART_DIR: String = "res://assets/art/battle/"
## Sole points (feet on the ground) in the 1280x720 arena view, from the approved arena
## art (battle_b1 arena_info.json). Each side has a front and a back column of three;
## the back column stands further from the centre and 30 px higher.
const SLOT_SOLES: Dictionary = {
	"party_front": [Vector2(448, 452), Vector2(448, 512), Vector2(448, 572)],
	"party_back": [Vector2(328, 422), Vector2(328, 482), Vector2(328, 542)],
	"beast_front": [Vector2(832, 452), Vector2(832, 512), Vector2(832, 572)],
	"beast_back": [Vector2(952, 422), Vector2(952, 482), Vector2(952, 542)],
}
const SLOT_ORDER: Array[String] = ["party_front", "party_back", "beast_front", "beast_back"]
const SLOT_MARK_SIZE: Vector2 = Vector2(56.0, 16.0)
## 128x128 fighter frames: soles on row 123, feet centred on x 63.5.
const FIGHTER_FRAME: Vector2 = Vector2(128.0, 128.0)
const FIGHTER_SOLE: Vector2 = Vector2(64.0, 123.0)
## Placeholder lineup until job 18's formation: Keeper front middle, Elaia back middle.
const PARTY_LINEUP: Dictionary = {"keeper": ["party_front", 1], "elaia": ["party_back", 1]}
## Battle poses (east-facing). Only idle is shown; the rest wait for jobs 18/21.
const PARTY_POSES: Dictionary = {
	"keeper": {
		"idle": "res://assets/art/echo/battle_keeper_idle_e.png",
		"attack": ART_DIR + "party/battle_keeper_attack.png",
		"brace": ART_DIR + "party/battle_keeper_brace.png",
		"hurt": ART_DIR + "party/battle_keeper_hurt.png",
		"ko": ART_DIR + "party/battle_keeper_ko.png",
	},
	"elaia": {
		"idle": ART_DIR + "party/battle_elaia_idle_e.png",
		"attack": ART_DIR + "party/battle_elaia_attack.png",
		"brace": ART_DIR + "party/battle_elaia_brace.png",
		"hurt": ART_DIR + "party/battle_elaia_hurt.png",
		"ko": ART_DIR + "party/battle_elaia_ko.png",
	},
}
## West-facing beast hurt frames, imported for playback (job 21). Not wired yet.
const BEAST_HURT: Dictionary = {
	"acorn_imp": ART_DIR + "beasts/battle_acorn_imp_hurt.png",
	"briar_hulk": ART_DIR + "beasts/battle_briar_hulk_hurt.png",
	"moss_brute": ART_DIR + "beasts/battle_moss_brute_hurt.png",
	"root_snapper": ART_DIR + "beasts/battle_root_snapper_hurt.png",
	"spore_moth": ART_DIR + "beasts/battle_spore_moth_hurt.png",
	"thorn_boar": ART_DIR + "beasts/battle_thorn_boar_hurt.png",
	"vine_serpent": ART_DIR + "beasts/battle_vine_serpent_hurt.png",
	"wilt_wisp": ART_DIR + "beasts/battle_wilt_wisp_hurt.png",
}
const SLOT_MARK_PATH: String = ART_DIR + "arena/slot_mark.png"
const SHADOW_M_PATH: String = ART_DIR + "arena/shadow_m.png"
const BACKDROP: Color = Color(0.05, 0.14, 0.08, 1.0)

static var _current: Node = null

@onready var _background: ColorRect = $Background
@onready var _placeholder: Label = $Arena/Placeholder
@onready var _close_button: Button = $Arena/CloseButton
@onready var _slots: Control = $Arena/Slots
@onready var _fighters: Control = $Arena/Fighters


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
	_place_party()
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
	## Twelve ground marks in the art's slots: party front 0-2, party back 3-5,
	## beast front 6-8, beast back 9-11. Each Control is the mark, centred on its sole point.
	if _slots == null:
		return
	var mark_tex: Texture2D = load(SLOT_MARK_PATH) as Texture2D
	for column: String in SLOT_ORDER:
		var soles: Array = SLOT_SOLES[column]
		for i: int in soles.size():
			var sole: Vector2 = soles[i]
			var slot := Control.new()
			slot.name = "%s_%d" % [column, i]
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.position = sole - SLOT_MARK_SIZE * 0.5
			slot.size = SLOT_MARK_SIZE
			slot.set_meta("sole", sole)
			slot.add_to_group("battle_slot_outline")
			var mark := TextureRect.new()
			mark.name = "Mark"
			mark.texture = mark_tex
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.size = SLOT_MARK_SIZE
			slot.add_child(mark)
			_slots.add_child(slot)


static func slot_sole(column: String, index: int) -> Vector2:
	var soles: Array = SLOT_SOLES.get(column, [])
	if index < 0 or index >= soles.size():
		return Vector2.ZERO
	return soles[index]


func _place_party() -> void:
	## Keeper and Elaia idle poses on their placeholder slots. Job 18 replaces this
	## with the real formation; set_fighter_pose swaps frames for later playback.
	if _fighters == null:
		return
	var shadow_tex: Texture2D = load(SHADOW_M_PATH) as Texture2D
	for member: String in ["elaia", "keeper"]:
		var spot: Array = PARTY_LINEUP[member]
		var sole: Vector2 = slot_sole(str(spot[0]), int(spot[1]))
		var root := Control.new()
		root.name = "Fighter_%s" % member
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.position = sole
		root.add_to_group("battle_fighter")
		if shadow_tex != null:
			var shadow := TextureRect.new()
			shadow.name = "Shadow"
			shadow.texture = shadow_tex
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shadow.size = shadow_tex.get_size()
			shadow.position = -shadow_tex.get_size() * 0.5
			root.add_child(shadow)
		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.size = FIGHTER_FRAME
		sprite.position = -FIGHTER_SOLE
		root.add_child(sprite)
		_fighters.add_child(root)
		set_fighter_pose(member, "idle")


func set_fighter_pose(member: String, pose: String) -> bool:
	var root: Node = _fighters.get_node_or_null("Fighter_%s" % member) if _fighters != null else null
	var poses: Dictionary = PARTY_POSES.get(member, {})
	if root == null or not poses.has(pose):
		return false
	var tex: Texture2D = load(str(poses[pose])) as Texture2D
	var sprite: TextureRect = root.get_node_or_null("Sprite") as TextureRect
	if tex == null or sprite == null:
		return false
	sprite.texture = tex
	root.set_meta("pose", pose)
	return true


func _input(event: InputEvent) -> void:
	## Swallow world clicks even when the full-rect control is not the hovered
	## GUI (headless has no pointer). Escape closes this overlay before the
	## pause menu's unhandled key sees it. _input runs BEFORE GUI input, so a
	## pointer event over the Close button is let through to reach the button.
	if is_queued_for_deletion():
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if _over_close(event as InputEventMouse):
			return
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	close_overlay()
	get_viewport().set_input_as_handled()


func _over_close(event: InputEventMouse) -> bool:
	if _close_button == null or not _close_button.is_visible_in_tree():
		return false
	return _close_button.get_global_rect().has_point(event.position)
