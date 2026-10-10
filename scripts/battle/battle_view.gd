extends CanvasLayer
class_name BattleView
## Empty fullscreen arena. Later jobs fill the rows. This shell does not pause the tree.

signal strike_for_me_party_stepped(packet: Dictionary)
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
const TARGET_MARK_PATH: String = ART_DIR + "arena/slot_mark_target.png"
const TARGET_BUTTON_SIZE: Vector2 = Vector2(80.0, 110.0)
const LOG_PANEL_RECT: Rect2 = Rect2(960.0, 64.0, 304.0, 236.0)
const ACTION_MENU_POS: Vector2 = Vector2(16.0, 468.0)
const ACTION_MENU_GAP: float = 8.0
const SHADOW_M_PATH: String = ART_DIR + "arena/shadow_m.png"
const BACKDROP: Color = Color(0.05, 0.14, 0.08, 1.0)
const PARTY_BAR_TOP: float = 608.0
const PARTY_BAR_HEIGHT: float = 112.0
const BEAST_PLATE_SIZE: Vector2 = Vector2(96.0, 34.0)
const BEAST_PLATE_LIFT: float = 132.0
const INTENT_MARKER_SIZE: Vector2 = Vector2(16.0, 16.0)
const BEAST_PLACEHOLDER_SIZE: Vector2 = Vector2(40.0, 56.0)
const ACTIVE_OUTLINE_COLOR: Color = Color(1.0, 0.84, 0.3)
const ACTIVE_OUTLINE_WIDTH: float = 2.0
const VARIANT_MODULATE: Color = Color(0.62, 0.55, 0.7, 1.0)
const ECHO_BEAST_IDLE: String = "res://assets/art/echo/battle_%s_idle.png"

static var _current: Node = null

@onready var _background: ColorRect = $Background
@onready var _placeholder: Label = $Arena/Placeholder
@onready var _close_button: Button = $Arena/CloseButton
@onready var _arena: Control = $Arena
@onready var _slots: Control = $Arena/Slots
@onready var _fighters: Control = $Arena/Fighters

var _party_bar: PanelContainer = null
var _active_fighter_id: String = ""
var _fight: FightState = null
var _target_mode: String = ""
var _test_fight_bar: HBoxContainer = null
var _depth_spin: SpinBox = null
var _boss_check: CheckBox = null
var _elaia_check: CheckBox = null
var _start_fight_button: Button = null
var _action_menu: VBoxContainer = null
var _strike_button: Button = null
var _salve_button: Button = null
var _brace_button: Button = null
var _flee_button: Button = null
var _idle_button: Button = null
var _cancel_target_button: Button = null
var _ability_buttons: Array[Button] = []
var _ability_row: HBoxContainer = null
var _log_panel: VBoxContainer = null
var _log_labels: Array[Label] = []
var _result_label: Label = null
var _target_layer: Control = null
var _strike_for_me_toggle: Button = null


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
	if _close_button:
		_close_button.add_to_group("battle_ui")
	_build_test_fight_bar()
	_build_fight_hud()
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
		root.set_meta("fighter_id", member)
		root.set_meta("side", "party")
		root.set_meta("member", member)
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


func set_fighter_pose(fighter_id: String, pose: String) -> bool:
	var root: Node = _fighters.get_node_or_null("Fighter_%s" % fighter_id) if _fighters != null else null
	if root == null:
		return false
	var member: String = str(root.get_meta("member", fighter_id))
	var poses: Dictionary = PARTY_POSES.get(member, {})
	if not poses.has(pose):
		return false
	var tex: Texture2D = load(str(poses[pose])) as Texture2D
	var sprite: TextureRect = root.get_node_or_null("Sprite") as TextureRect
	if tex == null or sprite == null:
		return false
	sprite.texture = tex
	root.set_meta("pose", pose)
	return true


func show_fight(fight: FightState) -> void:
	if _fighters == null or _arena == null:
		return
	_clear_fight_ui()
	var snapshot: Dictionary = fight.to_dict()
	var rows: Array = snapshot.get("fighters", []) as Array
	var by_column: Dictionary = {}
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		var column: String = _column_key(str(row.get("side", "")), str(row.get("row", "front")))
		if not by_column.has(column):
			by_column[column] = []
		(by_column[column] as Array).append(row)
	for column: String in by_column.keys():
		var group: Array = by_column[column] as Array
		group.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("slot", 0)) < int(b.get("slot", 0))
		)
		var indices: Array[int] = _sole_indices(group.size())
		for i: int in group.size():
			var fighter_row: Dictionary = group[i] as Dictionary
			var sole: Vector2 = slot_sole(column, indices[i])
			_spawn_fighter_node(fighter_row, sole)
	var beast_suffixes: Dictionary = _beast_suffix_map(rows)
	_build_party_bar(rows)
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		if str(row.get("side", "")) != "beast":
			continue
		var fighter_id: String = str(row.get("id", ""))
		var sole: Vector2 = _fighter_sole(fighter_id)
		_build_beast_plate(row, sole, str(beast_suffixes.get(fighter_id, "")))
	set_active("")


func refresh_fight(fight: FightState) -> void:
	var snapshot: Dictionary = fight.to_dict()
	var rows: Array = snapshot.get("fighters", []) as Array
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		var fighter_id: String = str(row.get("id", ""))
		var side: String = str(row.get("side", ""))
		if side == "party":
			_refresh_party_plate(row)
		elif side == "beast":
			_refresh_beast_plate(row)
		_refresh_fighter_visual(row)


func set_active(fighter_id: String) -> void:
	_active_fighter_id = fighter_id
	for node: Node in get_tree().get_nodes_in_group("battle_plate_outline"):
		node.queue_free()
	if fighter_id == "" or _arena == null:
		return
	var plate: Control = _arena.get_node_or_null("BeastPlate_%s" % fighter_id) as Control
	if plate == null and _party_bar != null:
		plate = _party_bar.find_child("PartyPlate_%s" % fighter_id, true, false) as Control
	if plate == null:
		return
	var outline := ReferenceRect.new()
	outline.name = "ActiveOutline"
	outline.editor_only = false
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.border_color = ACTIVE_OUTLINE_COLOR
	outline.border_width = ACTIVE_OUTLINE_WIDTH
	outline.position = Vector2(-ACTIVE_OUTLINE_WIDTH, -ACTIVE_OUTLINE_WIDTH)
	outline.size = plate.size + Vector2(ACTIVE_OUTLINE_WIDTH * 2.0, ACTIVE_OUTLINE_WIDTH * 2.0)
	outline.add_to_group("battle_plate_outline")
	plate.add_child(outline)


func _clear_fight_ui() -> void:
	_exit_target_mode()
	if _result_label != null:
		_result_label.text = ""
	_hide_action_menu()
	if _fighters != null:
		for child: Node in _fighters.get_children():
			_fighters.remove_child(child)
			child.free()
	if _party_bar != null and is_instance_valid(_party_bar):
		_arena.remove_child(_party_bar)
		_party_bar.free()
		_party_bar = null
	if _arena == null:
		return
	for child: Node in _arena.get_children():
		if child.name.begins_with("BeastPlate_"):
			_arena.remove_child(child)
			child.free()
	set_active("")


func _column_key(side: String, row: String) -> String:
	var safe_side: String = side if side == "party" or side == "beast" else "beast"
	var safe_row: String = "back" if row == "back" else "front"
	return "%s_%s" % [safe_side, safe_row]


static func _sole_indices(count: int) -> Array[int]:
	if count <= 0:
		return []
	if count == 1:
		return [1]
	if count == 2:
		return [0, 2]
	return [0, 1, 2]


func _spawn_fighter_node(row: Dictionary, sole: Vector2) -> void:
	var fighter_id: String = str(row.get("id", ""))
	var side: String = str(row.get("side", ""))
	var root := Control.new()
	root.name = "Fighter_%s" % fighter_id
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.position = sole
	root.add_to_group("battle_fighter")
	root.set_meta("fighter_id", fighter_id)
	root.set_meta("side", side)
	var shadow_tex: Texture2D = load(SHADOW_M_PATH) as Texture2D
	if shadow_tex != null:
		var shadow := TextureRect.new()
		shadow.name = "Shadow"
		shadow.texture = shadow_tex
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.size = shadow_tex.get_size()
		shadow.position = -shadow_tex.get_size() * 0.5
		root.add_child(shadow)
	if side == "party":
		var member: String = str(row.get("member", fighter_id))
		root.set_meta("member", member)
		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.size = FIGHTER_FRAME
		sprite.position = -FIGHTER_SOLE
		root.add_child(sprite)
		_fighters.add_child(root)
		set_fighter_pose(fighter_id, "idle")
	else:
		var species: String = str(row.get("species", ""))
		root.set_meta("species", species)
		_build_beast_sprite(root, species)
		_fighters.add_child(root)
		_refresh_fighter_visual(row)


func _build_beast_sprite(root: Control, species: String) -> void:
	var base: String = _beast_base_species(species)
	var idle_path: String = ECHO_BEAST_IDLE % base
	if ResourceLoader.exists(idle_path):
		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture = load(idle_path) as Texture2D
		sprite.size = FIGHTER_FRAME
		sprite.position = -FIGHTER_SOLE
		if species != base:
			sprite.modulate = VARIANT_MODULATE
		root.add_child(sprite)
		return
	var block := ColorRect.new()
	block.name = "Sprite"
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.color = Color(0.35, 0.3, 0.22, 1.0)
	block.size = BEAST_PLACEHOLDER_SIZE
	block.position = Vector2(-BEAST_PLACEHOLDER_SIZE.x * 0.5, -BEAST_PLACEHOLDER_SIZE.y)
	root.add_child(block)
	var label := Label.new()
	label.name = "Label"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 10)
	label.text = _beast_short_name(species)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = BEAST_PLACEHOLDER_SIZE
	label.position = block.position
	root.add_child(label)


func _build_party_bar(rows: Array) -> void:
	var party_rows: Array[Dictionary] = []
	for row_v: Variant in rows:
		if row_v is Dictionary and str((row_v as Dictionary).get("side", "")) == "party":
			party_rows.append(row_v as Dictionary)
	party_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	if party_rows.is_empty():
		return
	_party_bar = PanelContainer.new()
	_party_bar.name = "PartyBar"
	_party_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_bar.position = Vector2(0.0, PARTY_BAR_TOP)
	_party_bar.size = Vector2(ARENA_SIZE.x, PARTY_BAR_HEIGHT)
	var row_box := HBoxContainer.new()
	row_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_box.add_theme_constant_override("separation", 12)
	_party_bar.add_child(row_box)
	for row: Dictionary in party_rows:
		row_box.add_child(_make_party_plate(row))
	_arena.add_child(_party_bar)


func _make_party_plate(row: Dictionary) -> Control:
	var fighter_id: String = str(row.get("id", ""))
	var plate := VBoxContainer.new()
	plate.name = "PartyPlate_%s" % fighter_id
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var member: String = str(row.get("member", fighter_id))
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = _party_display_name(member)
	plate.add_child(title)
	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HpBar"
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(80.0, 14.0)
	hp_bar.max_value = maxi(1, int(row.get("max_hp", 1)))
	hp_bar.value = int(row.get("hp", 0))
	hp_row.add_child(hp_bar)
	var hp_label := Label.new()
	hp_label.name = "HpLabel"
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_label.text = _hp_line(int(row.get("hp", 0)), int(row.get("max_hp", 1)))
	hp_row.add_child(hp_label)
	plate.add_child(hp_row)
	var weave := Label.new()
	weave.name = "WeaveLabel"
	weave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weave.text = _weave_line(int(row.get("weave", 0)))
	plate.add_child(weave)
	var status := Label.new()
	status.name = "StatusLabel"
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.text = _party_status_text(str(row.get("status", "active")))
	plate.add_child(status)
	var shield := Label.new()
	shield.name = "ShieldLabel"
	shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield.text = _shield_text(int(row.get("shield", 0)))
	plate.add_child(shield)
	return plate


func _build_beast_plate(row: Dictionary, sole: Vector2, suffix: String) -> void:
	var fighter_id: String = str(row.get("id", ""))
	var species: String = str(row.get("species", ""))
	var plate := Control.new()
	plate.name = "BeastPlate_%s" % fighter_id
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size = BEAST_PLATE_SIZE
	var center: Vector2 = sole + Vector2(0.0, -BEAST_PLATE_LIFT)
	plate.position = center - BEAST_PLATE_SIZE * 0.5
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = _beast_display_name(species) + suffix
	name_label.position = Vector2(0.0, 0.0)
	name_label.size = Vector2(BEAST_PLATE_SIZE.x - INTENT_MARKER_SIZE.x, 14.0)
	plate.add_child(name_label)
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HpBar"
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.position = Vector2(0.0, 14.0)
	hp_bar.size = Vector2(BEAST_PLATE_SIZE.x - INTENT_MARKER_SIZE.x, 12.0)
	hp_bar.max_value = maxi(1, int(row.get("max_hp", 1)))
	hp_bar.value = int(row.get("hp", 0))
	plate.add_child(hp_bar)
	var status := Label.new()
	status.name = "StatusLabel"
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.position = Vector2(0.0, 26.0)
	status.size = Vector2(BEAST_PLATE_SIZE.x - INTENT_MARKER_SIZE.x, 8.0)
	status.add_theme_font_size_override("font_size", 10)
	status.text = _beast_status_text(str(row.get("status", "active")))
	plate.add_child(status)
	var intent_root := Control.new()
	intent_root.name = "IntentMarker"
	intent_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_root.position = Vector2(BEAST_PLATE_SIZE.x - INTENT_MARKER_SIZE.x, 0.0)
	intent_root.size = INTENT_MARKER_SIZE
	plate.add_child(intent_root)
	_fill_intent_marker(intent_root, row)
	if bool(row.get("boss", false)):
		var boss := Label.new()
		boss.name = "BossLabel"
		boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss.text = _text("adv_boss_mark", "Boss")
		boss.position = Vector2(0.0, -14.0)
		boss.size = Vector2(BEAST_PLATE_SIZE.x, 12.0)
		boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plate.add_child(boss)
	_arena.add_child(plate)


func _fill_intent_marker(intent_root: Control, row: Dictionary) -> void:
	for child: Node in intent_root.get_children():
		child.queue_free()
	var intent_v: Variant = row.get("intent", {})
	var intent: Dictionary = intent_v as Dictionary if intent_v is Dictionary else {}
	var move: String = str(intent.get("move", ""))
	var mult: int = int(intent.get("mult", 1))
	var letter := Label.new()
	letter.name = "Letter"
	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter.text = _intent_letter(move)
	letter.size = INTENT_MARKER_SIZE
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.add_theme_font_size_override("font_size", 10)
	intent_root.add_child(letter)
	if mult != 1:
		var mult_label := Label.new()
		mult_label.name = "Mult"
		mult_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mult_label.text = "×%s" % _intent_mult_text(mult)
		mult_label.position = Vector2(INTENT_MARKER_SIZE.x, 0.0)
		mult_label.size = Vector2(28.0, INTENT_MARKER_SIZE.y)
		mult_label.add_theme_font_size_override("font_size", 9)
		intent_root.add_child(mult_label)


func _refresh_party_plate(row: Dictionary) -> void:
	if _party_bar == null:
		return
	var plate: Node = _party_bar.find_child("PartyPlate_%s" % str(row.get("id", "")), true, false)
	if plate == null:
		return
	var hp_bar: ProgressBar = plate.find_child("HpBar", true, false) as ProgressBar
	var hp_label: Label = plate.find_child("HpLabel", true, false) as Label
	var weave: Label = plate.find_child("WeaveLabel", true, false) as Label
	var status: Label = plate.find_child("StatusLabel", true, false) as Label
	var shield: Label = plate.find_child("ShieldLabel", true, false) as Label
	var hp: int = int(row.get("hp", 0))
	var max_hp: int = int(row.get("max_hp", 1))
	if hp_bar != null:
		hp_bar.max_value = maxi(1, max_hp)
		hp_bar.value = hp
	if hp_label != null:
		hp_label.text = _hp_line(hp, max_hp)
	if weave != null:
		weave.text = _weave_line(int(row.get("weave", 0)))
	if status != null:
		status.text = _party_status_text(str(row.get("status", "active")))
	if shield != null:
		shield.text = _shield_text(int(row.get("shield", 0)))


func _refresh_beast_plate(row: Dictionary) -> void:
	if _arena == null:
		return
	var plate: Control = _arena.get_node_or_null("BeastPlate_%s" % str(row.get("id", ""))) as Control
	if plate == null:
		return
	var hp_bar: ProgressBar = plate.get_node_or_null("HpBar") as ProgressBar
	var status: Label = plate.get_node_or_null("StatusLabel") as Label
	var intent: Control = plate.get_node_or_null("IntentMarker") as Control
	var hp: int = int(row.get("hp", 0))
	var max_hp: int = int(row.get("max_hp", 1))
	if hp_bar != null:
		hp_bar.max_value = maxi(1, max_hp)
		hp_bar.value = hp
	if status != null:
		status.text = _beast_status_text(str(row.get("status", "active")))
	if intent != null:
		_fill_intent_marker(intent, row)


func _refresh_fighter_visual(row: Dictionary) -> void:
	if _fighters == null:
		return
	var fighter_id: String = str(row.get("id", ""))
	var root: Control = _fighters.get_node_or_null("Fighter_%s" % fighter_id) as Control
	if root == null:
		return
	var side: String = str(row.get("side", ""))
	var status: String = str(row.get("status", "active"))
	if side == "party":
		if status == "ko":
			set_fighter_pose(fighter_id, "ko")
		return
	var sprite: CanvasItem = root.get_node_or_null("Sprite") as CanvasItem
	if sprite == null:
		return
	var alpha: float = 0.35 if status == "calmed" else 1.0
	var mod: Color = sprite.modulate
	mod.a = alpha
	sprite.modulate = mod


func _fighter_sole(fighter_id: String) -> Vector2:
	if _fighters == null:
		return Vector2.ZERO
	var root: Control = _fighters.get_node_or_null("Fighter_%s" % fighter_id) as Control
	if root == null:
		return Vector2.ZERO
	return root.position


static func _beast_base_species(species: String) -> String:
	if species.ends_with("_dark"):
		return species.substr(0, species.length() - 5)
	return species


func _beast_suffix_map(rows: Array) -> Dictionary:
	var totals: Dictionary = {}
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		if str(row.get("side", "")) != "beast":
			continue
		var species: String = str(row.get("species", ""))
		totals[species] = int(totals.get(species, 0)) + 1
	var seen: Dictionary = {}
	var suffixes: Dictionary = {}
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		if str(row.get("side", "")) != "beast":
			continue
		var fighter_id: String = str(row.get("id", ""))
		var species: String = str(row.get("species", ""))
		if int(totals.get(species, 0)) < 2:
			suffixes[fighter_id] = ""
			continue
		var n: int = int(seen.get(species, 0)) + 1
		seen[species] = n
		suffixes[fighter_id] = " %s" % char(64 + n)
	return suffixes


func _party_display_name(member: String) -> String:
	if member == "elaia":
		return _text("echo_elaia_name", "Elaia")
	if member == "keeper":
		return _text("keeper_select", "Keeper")
	return member.capitalize()


func _beast_display_name(species: String) -> String:
	var row: Dictionary = FightState.beast_row(species)
	if row.is_empty():
		return _beast_short_name(species)
	var key: String = str(row.get("name_key", ""))
	if key != "":
		var named: String = _text(key, str(row.get("name", species)))
		if named != "" and named != key:
			return named
	return str(row.get("name", _beast_short_name(species)))


func _beast_short_name(species: String) -> String:
	var row: Dictionary = FightState.beast_row(species)
	if not row.is_empty():
		return str(row.get("name", species))
	return species.replace("_", " ").capitalize()


func _hp_line(hp: int, max_hp: int) -> String:
	return _text("adv_plate_hp", "HP %d/%d" % [hp, max_hp], {"hp": hp, "max": max_hp})


func _weave_line(weave: int) -> String:
	return _text("adv_plate_weave", "Weave %d" % weave, {"weave": weave})


func _party_status_text(status: String) -> String:
	if status == "ko":
		return _text("adv_knocked_out", "Knocked out")
	return ""


func _beast_status_text(status: String) -> String:
	if status == "calmed":
		return _text("adv_calmed", "Calmed")
	return ""


func _shield_text(shield: int) -> String:
	return "+%d" % shield if shield > 0 else ""


func _intent_letter(move: String) -> String:
	var lowered: String = move.to_lower()
	if lowered == "" or lowered == "strike":
		return "S"
	if lowered.find("heavy") >= 0:
		return "H"
	if lowered.find("poison") >= 0:
		return "P"
	return "S"


func _intent_mult_text(mult: int) -> String:
	if mult == 3:
		return "1.5"
	return str(mult)


func _text(key: String, fallback: String, params: Dictionary = {}) -> String:
	var strings: Node = get_node_or_null("/root/ContentStrings")
	if strings == null:
		return fallback
	var line: String = str(strings.call("get_text", key, params))
	if line == "" or line == key:
		return fallback
	return line


func _ui_button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.add_to_group("battle_ui")
	parent.add_child(button)
	return button


func _build_test_fight_bar() -> void:
	if _arena == null:
		return
	_test_fight_bar = HBoxContainer.new()
	_test_fight_bar.name = "TestFightBar"
	_test_fight_bar.position = Vector2(16.0, 12.0)
	_test_fight_bar.add_theme_constant_override("separation", 8)
	var depth_label := Label.new()
	depth_label.text = "Depth"
	depth_label.add_to_group("battle_ui")
	_test_fight_bar.add_child(depth_label)
	_depth_spin = SpinBox.new()
	_depth_spin.name = "DepthSpin"
	_depth_spin.min_value = 1.0
	_depth_spin.max_value = 15.0
	_depth_spin.value = 1.0
	_depth_spin.add_to_group("battle_ui")
	_test_fight_bar.add_child(_depth_spin)
	_boss_check = CheckBox.new()
	_boss_check.name = "BossCheck"
	_boss_check.text = "Boss room"
	_boss_check.add_to_group("battle_ui")
	_test_fight_bar.add_child(_boss_check)
	_elaia_check = CheckBox.new()
	_elaia_check.name = "ElaiaCheck"
	_elaia_check.text = "With Elaia"
	_elaia_check.button_pressed = true
	_elaia_check.add_to_group("battle_ui")
	_test_fight_bar.add_child(_elaia_check)
	_start_fight_button = _ui_button("Start fight", _test_fight_bar)
	_start_fight_button.name = "StartFightButton"
	if not _start_fight_button.pressed.is_connected(_on_start_fight_pressed):
		_start_fight_button.pressed.connect(_on_start_fight_pressed)
	_arena.add_child(_test_fight_bar)


func _build_fight_hud() -> void:
	if _arena == null:
		return
	_result_label = Label.new()
	_result_label.name = "ResultLabel"
	_result_label.position = Vector2(400.0, 12.0)
	_result_label.size = Vector2(480.0, 28.0)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_to_group("battle_ui")
	_arena.add_child(_result_label)
	_log_panel = VBoxContainer.new()
	_log_panel.name = "LogPanel"
	_log_panel.position = LOG_PANEL_RECT.position
	_log_panel.size = LOG_PANEL_RECT.size
	_log_panel.add_to_group("battle_ui")
	_arena.add_child(_log_panel)
	for i: int in 6:
		var line := Label.new()
		line.name = "LogLine%d" % i
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_vertical = Control.SIZE_EXPAND_FILL
		line.add_to_group("battle_ui")
		_log_panel.add_child(line)
		_log_labels.append(line)
	_action_menu = VBoxContainer.new()
	_action_menu.name = "ActionMenu"
	_action_menu.position = ACTION_MENU_POS
	_action_menu.add_theme_constant_override("separation", 4)
	_action_menu.visible = false
	_arena.add_child(_action_menu)
	_strike_button = _ui_button(_text("adv_menu_strike", "Strike"), _action_menu)
	_strike_button.name = "StrikeButton"
	_strike_button.pressed.connect(_on_strike_pressed)
	var ability_row := HBoxContainer.new()
	ability_row.name = "AbilityRow"
	ability_row.add_theme_constant_override("separation", 4)
	_action_menu.add_child(ability_row)
	_ability_row = ability_row
	for n: int in 4:
		var ab := _ui_button("—", ability_row)
		ab.name = "AbilityButton%d" % (n + 1)
		ab.disabled = true
		ab.tooltip_text = _text("adv_ability_empty_tip", "Abilities draw on Weave. You have none yet.")
		_ability_buttons.append(ab)
	_salve_button = _ui_button("", _action_menu)
	_salve_button.name = "SalveButton"
	_salve_button.pressed.connect(_on_salve_pressed)
	_brace_button = _ui_button(_text("adv_menu_brace", "Brace"), _action_menu)
	_brace_button.name = "BraceButton"
	_brace_button.pressed.connect(_on_brace_pressed)
	_flee_button = _ui_button(_text("adv_menu_flee", "Flee"), _action_menu)
	_flee_button.name = "FleeButton"
	_flee_button.pressed.connect(_on_flee_pressed)
	_idle_button = _ui_button(_text("adv_menu_idle", "Idle"), _action_menu)
	_idle_button.name = "IdleButton"
	_idle_button.disabled = true
	_idle_button.tooltip_text = _text("adv_menu_idle_later", "Hands the fight to idle Auto. Not in the test fight yet.")
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8.0, 0.0)
	_action_menu.add_child(spacer)
	_cancel_target_button = _ui_button(_text("adv_menu_cancel", "Back"), _action_menu)
	_cancel_target_button.name = "CancelTargetButton"
	_cancel_target_button.visible = false
	_cancel_target_button.pressed.connect(_on_cancel_target_pressed)
	_strike_for_me_toggle = Button.new()
	_strike_for_me_toggle.name = "StrikeForMeToggle"
	_strike_for_me_toggle.toggle_mode = true
	_strike_for_me_toggle.text = _text("adv_strike_for_me", "Strike for me")
	_strike_for_me_toggle.tooltip_text = _text(
		"adv_strike_for_me_tip",
		"Your fighters only Strike: front row first, then slot order. Plays at 1×. Turn it off any time.",
	)
	_strike_for_me_toggle.add_to_group("battle_ui")
	_action_menu.add_child(_strike_for_me_toggle)
	if not _strike_for_me_toggle.toggled.is_connected(_on_strike_for_me_toggled):
		_strike_for_me_toggle.toggled.connect(_on_strike_for_me_toggled)
	_target_layer = Control.new()
	_target_layer.name = "TargetLayer"
	_target_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arena.add_child(_target_layer)
	_update_salve_button()


func _on_start_fight_pressed() -> void:
	var depth: int = int(_depth_spin.value) if _depth_spin != null else 1
	var boss: bool = _boss_check.button_pressed if _boss_check != null else false
	var with_elaia: bool = _elaia_check.button_pressed if _elaia_check != null else true
	var room_seed: int = BattleRng.mask_seed(Time.get_ticks_usec())
	start_test_fight(depth, boss, with_elaia, room_seed)


func start_test_fight(depth: int, boss: bool, with_elaia: bool, room_seed: int) -> void:
	if _start_fight_button != null:
		_start_fight_button.disabled = true
	if _result_label != null:
		_result_label.text = ""
	if _strike_for_me_toggle != null:
		_strike_for_me_toggle.button_pressed = false
	_exit_target_mode()
	var fight := FightState.new()
	var keeper_stats: Dictionary = {
		"might": 11, "arcana": 5, "resilience": 6, "ward": 5,
		"vitality": 6, "swiftness": 7, "fate": 7, "attack": "physical",
	}
	fight.add_member("keeper", keeper_stats, 0, "front", "keeper")
	if with_elaia:
		var elaia_stats: Dictionary = {
			"might": 4, "arcana": 7, "resilience": 5, "ward": 7,
			"vitality": 6, "swiftness": 6, "fate": 5, "attack": "magic",
		}
		fight.add_member("elaia", elaia_stats, 1, "back", "elaia")
	var spawn_rng: BattleRng = SpawnRoller.room_seed_rng(room_seed)
	var room: Array[Dictionary] = SpawnRoller.roll_room(depth, spawn_rng, boss)
	for entry: Dictionary in room:
		var beast_id: String = fight.add_beast(str(entry.get("beast", "")), int(entry.get("slot", 0)), str(entry.get("row", "front")))
		if bool(entry.get("boss", false)) and beast_id != "":
			fight.set_boss(beast_id)
	fight.set_combat_seed(BattleRng.mix_stream(room_seed, "combat"))
	fight.loadout = {"heart_salve": 2}
	fight.start_fight()
	_fight = fight
	show_fight(fight)
	_advance()


func strike_for_me_on() -> bool:
	return _strike_for_me_toggle != null and _strike_for_me_toggle.button_pressed


func _advance() -> void:
	if _fight == null:
		return
	while _fight.outcome() == "":
		var actor_id: String = _fight.current_actor()
		if actor_id == "":
			break
		var actor: Dictionary = _fight.fighter_dict(actor_id)
		if str(actor.get("side", "")) != "beast":
			if strike_for_me_on():
				_strike_for_me_party_step(actor_id)
				continue
			break
		_fight.step()
		if strike_for_me_on():
			_show_strike_for_me_toggle_only()
	_exit_target_mode()
	refresh_fight(_fight)
	_update_log_panel()
	if _fight.outcome() != "":
		_show_fight_result()
		_hide_action_menu()
		if _start_fight_button != null:
			_start_fight_button.disabled = false
		return
	var party_actor: String = _fight.current_actor()
	set_active(party_actor)
	_show_action_menu(party_actor)


func _show_fight_result() -> void:
	if _result_label == null or _fight == null:
		return
	var outcome: String = _fight.outcome()
	match outcome:
		"win":
			_result_label.text = _text("adv_log_victory", "All beasts are Calmed.")
		"overwhelmed":
			_result_label.text = _text("adv_overwhelmed_title", "Overwhelmed")
		"flee":
			_result_label.text = _text("adv_back_at_trailhead", "Back at the trailhead.")
		_:
			_result_label.text = outcome


func _update_log_panel() -> void:
	if _fight == null or _log_labels.is_empty():
		return
	var tail: Array = _fight.log_tail
	var start: int = maxi(0, tail.size() - _log_labels.size())
	var slice: Array = tail.slice(start, tail.size())
	for i: int in _log_labels.size():
		_log_labels[i].text = str(slice[i]) if i < slice.size() else ""


func _hide_action_menu() -> void:
	if _action_menu != null:
		_action_menu.visible = false


func _show_strike_for_me_toggle_only() -> void:
	if _action_menu == null or _strike_for_me_toggle == null:
		return
	_action_menu.visible = true
	for child: Node in _action_menu.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = child == _strike_for_me_toggle
	_place_action_menu()


func _show_action_menu(actor_id: String) -> void:
	if _action_menu == null or _fight == null:
		return
	if actor_id == "":
		_hide_action_menu()
		return
	var actor: Dictionary = _fight.fighter_dict(actor_id)
	if str(actor.get("side", "")) != "party":
		_hide_action_menu()
		return
	_action_menu.visible = true
	_update_salve_button()
	_cancel_target_button.visible = _target_mode != ""
	for button: Button in [_strike_button, _salve_button, _brace_button, _flee_button, _idle_button]:
		if button != null:
			button.visible = _target_mode == ""
	var show_abilities: bool = _target_mode == "" and _has_abilities()
	for ab: Button in _ability_buttons:
		ab.visible = show_abilities
	if _ability_row != null:
		_ability_row.visible = show_abilities
	if _strike_for_me_toggle != null:
		_strike_for_me_toggle.visible = true
	_place_action_menu()


func _has_abilities() -> bool:
	## No abilities exist yet: every slot is a disabled "—". Hide the row until one is real.
	for ab: Button in _ability_buttons:
		if not ab.disabled:
			return true
	return false


func _place_action_menu() -> void:
	## Bottom-anchor the menu so every visible button sits above the party bar.
	if _action_menu == null:
		return
	_action_menu.reset_size()
	var height: float = _action_menu.get_combined_minimum_size().y
	_action_menu.position = Vector2(ACTION_MENU_POS.x, PARTY_BAR_TOP - ACTION_MENU_GAP - height)


func _strike_for_me_party_step(actor_id: String) -> void:
	if _fight == null or actor_id == "":
		return
	var action: Dictionary = AutoPolicy.strike_for_me_action(_fight, actor_id)
	var packet: Dictionary = _fight.step(action)
	packet["strike_for_me_target"] = str(action.get("target", ""))
	_notify_strike_for_me_party(packet)


func _notify_strike_for_me_party(packet: Dictionary) -> void:
	if packet.is_empty():
		return
	var actor_id: String = str(packet.get("actor", ""))
	if actor_id == "" or _fight == null:
		return
	if str(_fight.fighter_dict(actor_id).get("side", "")) != "party":
		return
	strike_for_me_party_stepped.emit(packet)


func _on_strike_for_me_toggled(pressed: bool) -> void:
	if not pressed or _fight == null or _fight.outcome() != "":
		return
	var actor_id: String = _fight.current_actor()
	if actor_id == "":
		return
	var actor: Dictionary = _fight.fighter_dict(actor_id)
	if str(actor.get("side", "")) != "party":
		return
	_strike_for_me_party_step(actor_id)
	_advance()


func _update_salve_button() -> void:
	if _salve_button == null or _fight == null:
		return
	var salve_name: String = _text("item_heart_salve", "Heart Salve")
	var count: int = int(_fight.loadout.get("heart_salve", 0))
	_salve_button.text = _text("adv_item_count", "%s ×%d" % [salve_name, count], {"item": salve_name, "count": count})
	var cap_hit: bool = _fight.salves_used >= 2
	_salve_button.disabled = count < 1 or cap_hit
	if count < 1:
		_salve_button.tooltip_text = _text("adv_item_none_packed", "None packed")
	else:
		_salve_button.tooltip_text = ""


func _on_strike_pressed() -> void:
	_enter_target_mode("strike")


func _on_salve_pressed() -> void:
	_enter_target_mode("salve")


func _on_brace_pressed() -> void:
	if _fight == null:
		return
	_fight.step({"kind": "brace"})
	_advance()


func _on_flee_pressed() -> void:
	if _fight == null:
		return
	_fight.step({"kind": "flee"})
	_advance()


func _on_cancel_target_pressed() -> void:
	_exit_target_mode()
	var actor_id: String = _fight.current_actor() if _fight != null else ""
	_show_action_menu(actor_id)


func _enter_target_mode(mode: String) -> void:
	if _fight == null:
		return
	_exit_target_mode()
	_target_mode = mode
	var actor_id: String = _fight.current_actor()
	var ids: Array[String] = []
	if mode == "salve":
		ids = _active_party_ids()
	else:
		ids = _fight.legal_targets(actor_id)
	_build_target_buttons(ids)
	_show_action_menu(actor_id)


func _exit_target_mode() -> void:
	_target_mode = ""
	if _target_layer == null:
		return
	for child: Node in _target_layer.get_children():
		if is_instance_valid(child):
			child.queue_free()


func _active_party_ids() -> Array[String]:
	var found: Array[String] = []
	if _fight == null:
		return found
	for fighter_id: String in _fight.order:
		var row: Dictionary = _fight.fighter_dict(fighter_id)
		if str(row.get("side", "")) == "party" and str(row.get("status", "")) == "active":
			found.append(fighter_id)
	return found


func _build_target_buttons(target_ids: Array[String]) -> void:
	if _target_layer == null or _fighters == null:
		return
	var mark_tex: Texture2D = load(TARGET_MARK_PATH) as Texture2D
	for fighter_id: String in target_ids:
		var root: Control = _fighters.get_node_or_null("Fighter_%s" % fighter_id) as Control
		if root == null:
			continue
		var sole: Vector2 = root.position
		if mark_tex != null:
			var mark := TextureRect.new()
			mark.name = "TargetMark_%s" % fighter_id
			mark.texture = mark_tex
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.size = mark_tex.get_size()
			mark.position = sole - mark.size * 0.5
			_target_layer.add_child(mark)
		var button := Button.new()
		button.name = "TargetButton_%s" % fighter_id
		button.modulate = Color(1.0, 1.0, 1.0, 0.01)
		button.size = TARGET_BUTTON_SIZE
		button.position = sole - Vector2(TARGET_BUTTON_SIZE.x * 0.5, TARGET_BUTTON_SIZE.y - 16.0)
		button.add_to_group("battle_ui")
		button.pressed.connect(_on_target_pressed.bind(fighter_id))
		_target_layer.add_child(button)


func _on_target_pressed(target_id: String) -> void:
	if _fight == null or _target_mode == "":
		return
	var mode: String = _target_mode
	_exit_target_mode()
	if mode == "strike":
		_fight.step({"kind": "strike", "target": target_id})
	elif mode == "salve":
		_fight.step({"kind": "item", "item": "heart_salve", "target": target_id})
	_advance()


func _input(event: InputEvent) -> void:
	## Swallow world clicks even when the full-rect control is not the hovered
	## GUI (headless has no pointer). Escape closes this overlay before the
	## pause menu's unhandled key sees it. _input runs BEFORE GUI input, so a
	## pointer event over the Close button is let through to reach the button.
	if is_queued_for_deletion():
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if _over_arena_control(event as InputEventMouse):
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


func _over_arena_control(event: InputEventMouse) -> bool:
	if _close_button != null and _close_button.is_visible_in_tree():
		if _close_button.get_global_rect().has_point(event.position):
			return true
	for node: Node in get_tree().get_nodes_in_group("battle_ui"):
		var control: Control = node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		if control.get_global_rect().has_point(event.position):
			return true
	return false
