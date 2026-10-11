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
## v7 formation (Haex approved 2026-10-11; minigames_art scaffold battle_ui_scaffold_v7_layout.json).
## Sole points (feet on the ground) in the 1280x720 arena view. Each side has a front and a
## back column of three: 0 = top, 1 = middle (steps toward the enemy, feet at the head height
## of the fighter behind), 2 = bottom. Beast slots are wider apart and are not a mirror.
## Presentation only: the resolver's front/back rows and slots are unchanged.
const SLOT_SOLES: Dictionary = {
	"party_front": [Vector2(300, 360), Vector2(380, 424), Vector2(300, 536)],
	"party_back": [Vector2(80, 360), Vector2(160, 424), Vector2(80, 536)],
	"beast_front": [Vector2(920, 360), Vector2(792, 424), Vector2(920, 536)],
	"beast_back": [Vector2(1176, 360), Vector2(1048, 424), Vector2(1176, 536)],
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
	## Debug fight only (not a companion yet): static idle, breathe frames not wired.
	"bramble": {
		"idle": ART_DIR + "party/battle_bramble_idle_e.png",
		"attack": ART_DIR + "party/battle_bramble_attack.png",
		"brace": ART_DIR + "party/battle_bramble_brace.png",
		"hurt": ART_DIR + "party/battle_bramble_hurt.png",
		"ko": ART_DIR + "party/battle_bramble_ko.png",
	},
}
## West-facing beast idle + hurt frames (128×128, soles on row 123). Dark variants reuse the
## base sprite with VARIANT_MODULATE. acorn_imp / spore_moth / thorn_boar / vine_serpent idles are
## draft stand-ins (plain file replace later); briar_hulk idle is the briar_warden still.
const BEAST_IDLE: Dictionary = {
	"acorn_imp": ART_DIR + "beasts/battle_acorn_imp_idle.png",
	"briar_hulk": ART_DIR + "beasts/battle_briar_hulk_idle.png",
	"moss_brute": ART_DIR + "beasts/battle_moss_brute_idle.png",
	"root_snapper": ART_DIR + "beasts/battle_root_snapper_idle.png",
	"spore_moth": ART_DIR + "beasts/battle_spore_moth_idle.png",
	"thorn_boar": ART_DIR + "beasts/battle_thorn_boar_idle.png",
	"vine_serpent": ART_DIR + "beasts/battle_vine_serpent_idle.png",
	"wilt_wisp": ART_DIR + "beasts/battle_wilt_wisp_idle.png",
}
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
const TARGET_MARK_PATH: String = ART_DIR + "ui/slot_mark_target.png"
const TARGET_BUTTON_SIZE: Vector2 = Vector2(80.0, 110.0)
const SHADOW_PATHS: Dictionary = {
	"s": ART_DIR + "arena/shadow_s.png",
	"m": ART_DIR + "arena/shadow_m.png",
	"l": ART_DIR + "arena/shadow_l.png",
}
const SHADOW_M_PATH: String = ART_DIR + "arena/shadow_m.png"
const BACKDROP: Color = Color(0.05, 0.14, 0.08, 1.0)
## v7 UI final art (see docs/BATTLE_UI_README.md).
const UI_ART_DIR: String = ART_DIR + "ui/"
## Party 56×24; beasts 56×20. Top-left anchor under feet: (x − 28, y + 10).
const PLATE_PARTY_SIZE: Vector2 = Vector2(56.0, 24.0)
const PLATE_BEAST_SIZE: Vector2 = Vector2(56.0, 20.0)
const PLATE_OFFSET: Vector2 = Vector2(-28.0, 10.0)
const PLATE_INK: Color = Color(0.243137, 0.164706, 0.094118, 1.0)
const PLATE_LEVEL_INK: Color = Color(0.368627, 0.227451, 0.133333, 1.0)
const PLATE_BAR_EDGE: Color = Color(0.12, 0.08, 0.05, 1.0)
const PLATE_BAR_POS: Vector2 = Vector2(3.0, 12.0)
const PLATE_BAR_HP_SIZE: Vector2 = Vector2(50.0, 4.0)
const PLATE_BAR_WEAVE_SIZE: Vector2 = Vector2(50.0, 2.0)
const PLATE_WEAVE_Y: float = 17.0
const WOOD_TEXT: Color = Color(0.980392, 0.933333, 0.8, 1.0)
const WOOD_SHADOW: Color = Color(0.101961, 0.058824, 0.031373, 1.0)
const ICON_DISABLED: Color = Color(0.65, 0.6, 0.55, 1.0)
## Intent bubble above a beast's visible head: (visible centre x - 10, visible top - 28).
const INTENT_BUBBLE_SIZE: Vector2 = Vector2(22.0, 26.0)
const INTENT_BUBBLE_WIDE: Vector2 = Vector2(40.0, 26.0)
const INTENT_LIFT: float = 28.0
const INTENT_CENTRE_SHIFT: float = 10.0
const ACTIVE_ARROW_TOP: float = 15.0
const DEPTH_PLATE_POS: Vector2 = Vector2(16.0, 12.0)
const DEPTH_PLATE_SIZE: Vector2 = Vector2(120.0, 28.0)
const ROUND_BANNER_POS: Vector2 = Vector2(478.0, 8.0)
const ROUND_BANNER_SIZE: Vector2 = Vector2(324.0, 38.0)
const ROUND_TEXT_RECT: Rect2 = Rect2(490.0, 11.0, 300.0, 32.0)
## Three 32×32 speed buttons (36 px pitch) sit just left of the Close button (1140–1264).
const SPEED_BUTTON_SIZE: Vector2 = Vector2(32.0, 32.0)
const SPEED_BUTTON_PITCH: float = 36.0
const CLOSE_BUTTON_RECT: Rect2 = Rect2(1140.0, 16.0, 124.0, 36.0)
const SPEED_BUTTON_POS: Vector2 = Vector2(
	CLOSE_BUTTON_RECT.position.x - 4.0 - SPEED_BUTTON_SIZE.x - SPEED_BUTTON_PITCH * 2.0,
	12.0,
)
const TWIST_CHIP_POS: Vector2 = Vector2(142.0, 20.0)
const TWIST_CHIP_SIZE: Vector2 = Vector2(12.0, 12.0)
const TEST_FIGHT_BAR_GAP: float = 8.0
const STATUS_ICON_STEP: float = 13.0
const STATUS_ICON_SIZE: Vector2 = Vector2(12.0, 12.0)
const MAX_STATUS_ICONS: int = 3
const BOSS_CROWN_POS: Vector2 = Vector2(-15.0, 2.0)
const KEYCAP_POS: Vector2 = Vector2(141.0, 12.0)
const KEYCAP_PRESS_OFFSET: float = 2.0
## Bottom bar: the six action buttons (3 x 2) and the battle log. Nothing else.
const BOTTOM_BAR_RECT: Rect2 = Rect2(0.0, 584.0, 1280.0, 136.0)
const ACTION_MENU_POS: Vector2 = Vector2(24.0, 600.0)
const ACTION_BUTTON_SIZE: Vector2 = Vector2(160.0, 44.0)
const ACTION_BUTTON_PITCH: Vector2 = Vector2(168.0, 52.0)
const LOG_PANEL_RECT: Rect2 = Rect2(528.0, 600.0, 728.0, 104.0)
const LOG_LINE_COUNT: int = 5
const LOG_INK: Color = Color(0.243137, 0.164706, 0.094118, 1.0)
const LOG_MISS_INK: Color = Color(0.368627, 0.321569, 0.266667, 1.0)
const LOG_THREAT_INK: Color = Color(0.556863, 0.227451, 0.141176, 1.0)
const LOG_SYSTEM_INK: Color = Color(0.368627, 0.227451, 0.133333, 1.0)
const BUTTON_TEXT: Color = WOOD_TEXT
const BUTTON_TEXT_DISABLED: Color = Color(0.643137, 0.588235, 0.517647, 1.0)
const BEAST_PLACEHOLDER_SIZE: Vector2 = Vector2(40.0, 56.0)
const ACTIVE_OUTLINE_COLOR: Color = Color(1.0, 0.84, 0.3)
const ACTIVE_OUTLINE_WIDTH: float = 1.0
const VARIANT_MODULATE: Color = Color(0.62, 0.55, 0.7, 1.0)
const ECHO_BEAST_IDLE: String = "res://assets/art/echo/battle_%s_idle.png"

static var _current: Node = null
## Visible (non-transparent) rect of each fighter texture, by resource path.
static var _used_rect_cache: Dictionary = {}
static var _ui_font_cache: Font = null

@onready var _background: ColorRect = $Background
@onready var _placeholder: Label = $Arena/Placeholder
@onready var _close_button: Button = $Arena/CloseButton
@onready var _arena: Control = $Arena
@onready var _slots: Control = $Arena/Slots
@onready var _fighters: Control = $Arena/Fighters

var _plates: Control = null
var _bottom_bar: TextureRect = null
var _side_actions: VBoxContainer = null
var _ability_button: Button = null
var _active_fighter_id: String = ""
var _fight: FightState = null
var _target_mode: String = ""
var _test_fight_bar: HBoxContainer = null
var _depth_spin: SpinBox = null
var _boss_check: CheckBox = null
var _elaia_check: CheckBox = null
var _start_fight_button: Button = null
var _action_menu: Control = null
var _strike_button: Button = null
var _salve_button: Button = null
var _brace_button: Button = null
var _flee_button: Button = null
var _idle_button: Button = null
var _cancel_target_button: Button = null
var _ability_buttons: Array[Button] = []
var _ability_row: HBoxContainer = null
var _log_panel: Control = null
var _log_labels: Array[Label] = []
var _result_label: Label = null
var _target_layer: Control = null
var _strike_for_me_toggle: Button = null
var _playback: BattlePlayback = null
var _speed_bar: Control = null
var _speed_buttons: Dictionary = {}
var _speed_textures: Dictionary = {}
var _battle_speed: int = 1
var _depth_plate: Control = null
var _round_banner: Control = null
var _depth_hud_label: Label = null
var _round_hud_label: Label = null
var _fight_depth: int = 1
var _twist_chip: TextureRect = null
var _action_buttons: Array[Button] = []
var _log_reveal_count: int = 0
var _advance_after_playback: bool = false
var _reach_mode: bool = false
var _reach_outcome_applied: bool = false
var _end_panel: Panel = null
var _pack_counter: Label = null


static func is_open() -> bool:
	return _current != null and is_instance_valid(_current) and not _current.is_queued_for_deletion()


static func open_reach_fight(fight: FightState) -> bool:
	## Manual reach room. Skips the Reach.fight_active() refusal; Echo in_battle still refuses.
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var echo: Node = tree.root.get_node_or_null("EchoChamber")
		if echo != null and bool(echo.get("in_battle")):
			return false
	if not is_open():
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
	if not is_open():
		return false
	var reach_view: BattleView = _current as BattleView
	if reach_view == null:
		return false
	reach_view._hide_end_panel()
	reach_view.set_reach_mode(true)
	reach_view._reach_outcome_applied = false
	if reach_view._strike_for_me_toggle != null:
		reach_view._strike_for_me_toggle.button_pressed = false
	if reach_view._result_label != null:
		reach_view._result_label.text = ""
	reach_view._fight = fight
	reach_view._log_reveal_count = 0
	if reach_view._playback != null:
		reach_view._playback.bind_view(reach_view, fight)
		reach_view._playback.reset_for_fight()
	reach_view.show_fight(fight)
	if fight.outcome() != "":
		reach_view.call_deferred("_finish_turn_ui")
	else:
		reach_view._advance()
	return true


static func open_arena() -> bool:
	## The call the Experimental "Battle arena (test)" button makes.
	## A second call keeps the one overlay. Echo and a manual reach fight refuse it.
	## Refuse first: a manual reach fight already owns the overlay (job 26), so an
	## is_open() short-circuit would report the test arena as opened over it.
	if _refuses_open():
		return false
	if is_open():
		return true
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
	_build_plate_layer()
	_place_party()
	if _close_button and not _close_button.pressed.is_connected(close_overlay):
		_close_button.pressed.connect(close_overlay)
	if _close_button:
		_close_button.add_to_group("battle_ui")
	_build_test_fight_bar()
	_build_top_bar()
	_build_speed_bar()
	_build_fight_hud()
	_playback = BattlePlayback.new()
	_playback.name = "BattlePlayback"
	add_child(_playback)
	_playback.queue_empty.connect(_on_playback_queue_empty)
	_bind_load()
	_layout_top_chrome()


func _exit_tree() -> void:
	_unbind_load()
	if _current == self:
		_current = null


func close_overlay() -> void:
	_hide_end_panel()
	_reach_mode = false
	_reach_outcome_applied = false
	_unbind_load()
	if is_in_group("battle_overlay"):
		remove_from_group("battle_overlay")
	if _current == self:
		_current = null
	if is_inside_tree() and not is_queued_for_deletion():
		queue_free()


func set_reach_mode(on: bool) -> void:
	_reach_mode = on
	if on:
		_unbind_load()
	else:
		_bind_load()
	if _test_fight_bar != null:
		_test_fight_bar.visible = not on
	if _close_button != null:
		_close_button.visible = not on
	if on:
		_ensure_pack_counter()
		_refresh_pack_counter()
	elif _pack_counter != null and is_instance_valid(_pack_counter):
		_pack_counter.visible = false


func pack_counter_text() -> String:
	var reach: Node = get_node_or_null("/root/Reach")
	if reach == null:
		return ""
	var run_pack: Pack = reach.get("pack") as Pack
	var total: int = run_pack.total() if run_pack != null else 0
	return _text("adv_pack_counter", "Pack: %d" % total, {"n": total})


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
	## Reach end panels stay up until the player dismisses them.
	if ok and not _reach_mode:
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


func _build_plate_layer() -> void:
	## UI layer above every sprite and the arena foreground: plates, intent bubbles, active arrow.
	if _arena == null:
		return
	_plates = Control.new()
	_plates.name = "Plates"
	_plates.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plates.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arena.add_child(_plates)
	var foreground: Node = _arena.get_node_or_null("Foreground")
	if foreground != null:
		_arena.move_child(_plates, foreground.get_index() + 1)


func _place_party() -> void:
	## Keeper and Elaia idle poses on their placeholder slots before a fight starts.
	## set_fighter_pose swaps frames for later playback.
	if _fighters == null:
		return
	for member: String in ["elaia", "keeper"]:
		var spot: Array = PARTY_LINEUP[member]
		var sole: Vector2 = slot_sole(str(spot[0]), int(spot[1]))
		var root: Control = _new_fighter_root(member, "party", sole)
		root.set_meta("member", member)
		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.size = FIGHTER_FRAME
		sprite.position = -FIGHTER_SOLE
		root.add_child(sprite)
		_fighters.add_child(root)
		set_fighter_pose(member, "idle")
		_finish_fighter_root(root)
	_sort_fighters_by_feet()


func _new_fighter_root(fighter_id: String, side: String, sole: Vector2) -> Control:
	## Feet-anchored root: the 128x128 frame's top-left is (x - 64, y - 123) for every fighter.
	var root := Control.new()
	root.name = "Fighter_%s" % fighter_id
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.position = sole
	root.add_to_group("battle_fighter")
	root.set_meta("fighter_id", fighter_id)
	root.set_meta("side", side)
	root.set_meta("sole", sole)
	var shadow := TextureRect.new()
	shadow.name = "Shadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shadow)
	return root


func _finish_fighter_root(root: Control) -> void:
	## Records the idle sprite's visible rect (arena space) and sizes the shadow to it.
	var sprite: Control = root.get_node_or_null("Sprite") as Control
	var local := Rect2(-FIGHTER_SOLE, FIGHTER_FRAME)
	if sprite is TextureRect and (sprite as TextureRect).texture != null:
		var used: Rect2 = texture_used_rect((sprite as TextureRect).texture)
		local = Rect2(sprite.position + used.position, used.size)
	elif sprite != null:
		local = Rect2(sprite.position, sprite.size)
	root.set_meta("visible_rect", Rect2(root.position + local.position, local.size))
	var shadow: TextureRect = root.get_node_or_null("Shadow") as TextureRect
	if shadow == null:
		return
	var key: String = "s" if local.size.x <= 48.0 else ("m" if local.size.x <= 80.0 else "l")
	var tex: Texture2D = load(str(SHADOW_PATHS[key])) as Texture2D
	if tex == null:
		tex = load(SHADOW_M_PATH) as Texture2D
	if tex != null:
		shadow.texture = tex
		shadow.size = tex.get_size()
		shadow.position = -(tex.get_size() * 0.5).floor()


func _sort_fighters_by_feet() -> void:
	## Draw order: plain ascending feet y (ties: ascending x), so the middle fighter
	## (feet 424) is drawn behind the bottom fighter (feet 536).
	if _fighters == null:
		return
	var roots: Array[Control] = []
	for child: Node in _fighters.get_children():
		if child is Control:
			roots.append(child as Control)
	roots.sort_custom(func(a: Control, b: Control) -> bool:
		var sa: Vector2 = a.get_meta("sole", a.position) as Vector2
		var sb: Vector2 = b.get_meta("sole", b.position) as Vector2
		if not is_equal_approx(sa.y, sb.y):
			return sa.y < sb.y
		return sa.x < sb.x
	)
	for i: int in roots.size():
		_fighters.move_child(roots[i], i)


static func texture_used_rect(tex: Texture2D) -> Rect2:
	## Pixel bounds of a fighter frame's non-transparent part, cached by path.
	## Headless has no texture readback, so fall back to the source PNG.
	if tex == null:
		return Rect2()
	var key: String = tex.resource_path
	if key != "" and _used_rect_cache.has(key):
		return _used_rect_cache[key] as Rect2
	var rect := Rect2(Vector2.ZERO, tex.get_size())
	var image: Image = tex.get_image()
	if (image == null or image.is_empty()) and key != "" and FileAccess.file_exists(key):
		image = Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(key)) != OK:
			image = null
	if image != null and not image.is_empty():
		if image.is_compressed():
			image.decompress()
		var used: Rect2i = image.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			rect = Rect2(used)
	if key != "":
		_used_rect_cache[key] = rect
	return rect


func fighter_visible_rect(fighter_id: String) -> Rect2:
	## Arena-space rect of the fighter's visible idle pixels, taken at spawn.
	var root: Control = playback_fighter_root(fighter_id)
	if root == null:
		return Rect2()
	return root.get_meta("visible_rect", Rect2(root.position, Vector2.ZERO)) as Rect2


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


func get_playback() -> BattlePlayback:
	return _playback


func playback_fighter_root(fighter_id: String) -> Control:
	return _fighters.get_node_or_null("Fighter_%s" % fighter_id) as Control if _fighters != null else null


func playback_sprite_for(fighter_id: String) -> CanvasItem:
	var root: Control = playback_fighter_root(fighter_id)
	return root.get_node_or_null("Sprite") as CanvasItem if root != null else null


func playback_set_beast_hurt(fighter_id: String, species: String) -> bool:
	var sprite: TextureRect = playback_sprite_for(fighter_id) as TextureRect
	if sprite == null:
		return false
	var base: String = _beast_base_species(species)
	if not BEAST_HURT.has(base):
		return false
	var tex: Texture2D = load(str(BEAST_HURT[base])) as Texture2D
	if tex == null:
		return false
	sprite.texture = tex
	if species != base:
		sprite.modulate = VARIANT_MODULATE
	return true


func playback_set_beast_idle(fighter_id: String) -> void:
	if _fight == null:
		return
	var row: Dictionary = _fight.fighter_dict(fighter_id)
	var species: String = str(row.get("species", ""))
	var root: Control = playback_fighter_root(fighter_id)
	var sprite: TextureRect = root.get_node_or_null("Sprite") as TextureRect if root != null else null
	if sprite == null:
		return
	var base: String = _beast_base_species(species)
	var idle_path: String = str(BEAST_IDLE.get(base, ""))
	if idle_path == "" or not ResourceLoader.exists(idle_path):
		idle_path = ECHO_BEAST_IDLE % base
	if ResourceLoader.exists(idle_path):
		sprite.texture = load(idle_path) as Texture2D
		sprite.size = FIGHTER_FRAME
		sprite.position = -FIGHTER_SOLE
	var alpha: float = 0.35 if str(row.get("status", "")) == "calmed" else 1.0
	var mod: Color = sprite.modulate
	mod.a = alpha
	sprite.modulate = mod


func playback_refresh_intent(fighter_id: String) -> void:
	if _plates == null or _fight == null:
		return
	var plate: Control = _plates.get_node_or_null("BeastPlate_%s" % fighter_id) as Control
	var intent: Control = plate.get_node_or_null("IntentMarker") as Control if plate != null else null
	if intent != null:
		_fill_intent_marker(intent, _fight.fighter_dict(fighter_id))


func refresh_fighter_row(fighter_id: String) -> void:
	if _fight != null:
		refresh_fight(_fight)
		set_active(_active_fighter_id)


func playback_reveal_log(event: Dictionary) -> void:
	if _fight == null:
		return
	var line: String = BattleLog.line_for(event, _fight)
	if line != "":
		_log_reveal_count = mini(_log_reveal_count + 1, _fight.log_tail.size())
	_update_log_panel()


func playback_show_float(event: Dictionary) -> void:
	if _arena == null:
		return
	var target_id: String = str(event.get("target", ""))
	var root: Control = playback_fighter_root(target_id)
	if root == null:
		return
	var text: String = ""
	match str(event.get("kind", "")):
		"strike":
			text = "miss" if str(event.get("band", "")) == "miss" else str(int(event.get("damage", 0)))
		"item":
			text = "+%d" % int(event.get("healed", 0))
	if text == "":
		return
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_meta("battle_float", true)
	label.set_meta("base_y", -FIGHTER_SOLE.y - 8.0)
	label.set_meta("age", 0.0)
	label.set_meta("dur", 0.8)
	label.position = Vector2(-24.0, -FIGHTER_SOLE.y - 8.0)
	_arena.add_child(label)
	if _playback != null:
		_playback.register_float(label)


func show_fight(fight: FightState) -> void:
	if _fighters == null or _arena == null:
		return
	_clear_fight_ui()
	if _playback != null:
		# Any fight shown here gets playback bound, not just start_test_fight's.
		_playback.bind_view(self, fight)
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
	_sort_fighters_by_feet()
	var beast_suffixes: Dictionary = _beast_suffix_map(rows)
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		var fighter_id: String = str(row.get("id", ""))
		_build_plate(row, _fighter_sole(fighter_id), str(beast_suffixes.get(fighter_id, "")))
	set_active("")
	_refresh_fight_hud()


func refresh_fight(fight: FightState) -> void:
	_fight = fight
	var snapshot: Dictionary = fight.to_dict()
	var rows: Array = snapshot.get("fighters", []) as Array
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		var side: String = str(row.get("side", ""))
		if side == "party" or side == "beast":
			_refresh_plate(row)
		_refresh_fighter_visual(row)
	_refresh_twist_chip()


func set_active(fighter_id: String) -> void:
	_active_fighter_id = fighter_id
	for node: Node in get_tree().get_nodes_in_group("battle_plate_outline"):
		node.queue_free()
	for node: Node in get_tree().get_nodes_in_group("battle_active_arrow"):
		node.queue_free()
	if _plates != null:
		for plate_node: Node in _plates.get_children():
			if not plate_node.is_in_group("battle_plate"):
				continue
			var bg: TextureRect = plate_node.get_node_or_null("Bg") as TextureRect
			if bg != null:
				var side: String = str(plate_node.get_meta("side", "party"))
				var boss: bool = bool(plate_node.get_meta("boss", false))
				bg.texture = _load_ui_tex(_plate_bg_file(side, false, boss))
	if fighter_id == "" or _plates == null:
		return
	var plate: Control = _plate_for(fighter_id)
	if plate == null:
		return
	var active_bg: TextureRect = plate.get_node_or_null("Bg") as TextureRect
	if active_bg != null:
		var side: String = str(plate.get_meta("side", "party"))
		var boss: bool = bool(plate.get_meta("boss", false))
		active_bg.texture = _load_ui_tex(_plate_bg_file(side, true, boss))
	var arrow_tex: Texture2D = _load_ui_tex("active_arrow_13x9.png")
	var shown: Rect2 = fighter_visible_rect(fighter_id)
	if arrow_tex != null and shown.size.y > 0.0:
		var arrow := TextureRect.new()
		arrow.name = "ActiveArrow"
		arrow.texture = arrow_tex
		arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.size = arrow_tex.get_size()
		arrow.position = Vector2(floorf(shown.get_center().x) - 6.0, shown.position.y - ACTIVE_ARROW_TOP)
		arrow.add_to_group("battle_active_arrow")
		_plates.add_child(arrow)


func _clear_fight_ui() -> void:
	_exit_target_mode()
	if _result_label != null:
		_result_label.text = ""
	_log_reveal_count = 0
	if _playback != null:
		_playback.reset_for_fight()
	_hide_action_menu()
	if _fighters != null:
		for child: Node in _fighters.get_children():
			_fighters.remove_child(child)
			child.free()
	if _plates != null:
		for child: Node in _plates.get_children():
			_plates.remove_child(child)
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
	var root: Control = _new_fighter_root(fighter_id, side, sole)
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
		_finish_fighter_root(root)
	else:
		var species: String = str(row.get("species", ""))
		root.set_meta("species", species)
		_build_beast_sprite(root, species)
		_fighters.add_child(root)
		_finish_fighter_root(root)
		_refresh_fighter_visual(row)


func _build_beast_sprite(root: Control, species: String) -> void:
	var base: String = _beast_base_species(species)
	var idle_path: String = str(BEAST_IDLE.get(base, ""))
	if idle_path == "" or not ResourceLoader.exists(idle_path):
		## Fallback for the three Echo Chamber stills that predate battle/beasts/.
		idle_path = ECHO_BEAST_IDLE % base
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


func _plate_for(fighter_id: String) -> Control:
	if _plates == null:
		return null
	var plate: Control = _plates.get_node_or_null("PartyPlate_%s" % fighter_id) as Control
	if plate == null:
		plate = _plates.get_node_or_null("BeastPlate_%s" % fighter_id) as Control
	return plate


static func _plate_size_for(side: String) -> Vector2:
	return PLATE_BEAST_SIZE if side == "beast" else PLATE_PARTY_SIZE


static func _plate_bg_file(side: String, active: bool, boss: bool = false) -> String:
	if side == "beast" and boss:
		return "plate_beast_boss_active_56x20.png" if active else "plate_beast_boss_56x20.png"
	if side == "beast":
		return "plate_beast_active_56x20.png" if active else "plate_beast_56x20.png"
	return "plate_party_active_56x24.png" if active else "plate_party_56x24.png"


static func _test_fight_bar_pos() -> Vector2:
	## Right of the depth plate and the optional twist chip (12×12 at TWIST_CHIP_POS).
	var x: float = TWIST_CHIP_POS.x + TWIST_CHIP_SIZE.x + TEST_FIGHT_BAR_GAP
	return Vector2(x, DEPTH_PLATE_POS.y)


func _twist_chip_art(twist: String) -> Dictionary:
	var key: String = twist.strip_edges().to_lower()
	if key == "":
		return {}
	var file: String = ""
	var tip: String = key.replace("_", " ").capitalize()
	match key:
		"thicket":
			file = "status_slowed_12.png"
			tip = "Thicket"
		"fog":
			file = "status_fogged_12.png"
			tip = "Fog"
		"ambush":
			file = "twist_ambush_12.png"
			tip = "Ambush"
		"sap_spring":
			file = "status_shield_12.png"
			tip = "Sap Spring"
		"rich_hollow":
			file = "twist_rich_hollow_12.png"
			tip = "Rich Hollow"
		_:
			return {}
	return {"file": file, "tip": tip}


func _refresh_twist_chip() -> void:
	if _twist_chip == null:
		return
	var twist: String = _fight.twist if _fight != null else ""
	var spec: Dictionary = _twist_chip_art(twist)
	if spec.is_empty():
		_twist_chip.visible = false
		_twist_chip.texture = null
		_twist_chip.tooltip_text = ""
		return
	_twist_chip.texture = _load_ui_tex(str(spec.get("file", "")))
	_twist_chip.visible = _twist_chip.texture != null
	_twist_chip.tooltip_text = str(spec.get("tip", ""))


func _status_icon_files(row: Dictionary) -> Array[String]:
	var files: Array[String] = []
	var side: String = str(row.get("side", ""))
	var status_id: String = str(row.get("status", "active"))
	var poison_v: Variant = row.get("poison", {})
	var poison: Dictionary = poison_v as Dictionary if poison_v is Dictionary else {}
	var poison_left: int = int(poison.get("left", 0))
	if poison_left > 0:
		files.append("status_poisoned_12.png")
	if int(row.get("shield", 0)) > 0:
		files.append("status_shield_12.png")
	if bool(row.get("brace", false)):
		files.append("status_braced_12.png")
	if bool(row.get("rootbind", false)):
		files.append("status_rootbind_12.png")
	if side == "party" and status_id == "ko":
		files.append("status_ko_12.png")
	elif side == "beast" and status_id == "calmed":
		files.append("status_calmed_12.png")
	var capped: Array[String] = []
	for i: int in mini(files.size(), MAX_STATUS_ICONS):
		capped.append(files[i])
	return capped


func _status_icon_tooltip(row: Dictionary, files: Array[String]) -> String:
	var names: PackedStringArray = []
	for file: String in files:
		if file.begins_with("status_poisoned"):
			names.append(_text("adv_poisoned", "Poisoned"))
		elif file.begins_with("status_shield"):
			names.append(_text("adv_shielded", "Shield"))
		elif file.begins_with("status_braced"):
			names.append(_text("adv_braced", "Braced"))
		elif file.begins_with("status_rootbind"):
			names.append(_text("adv_rootbound", "Rootbound"))
		elif file.begins_with("status_ko"):
			names.append(_text("adv_knocked_out", "Knocked out"))
		elif file.begins_with("status_calmed"):
			names.append(_text("adv_calmed", "Calmed"))
	if names.is_empty():
		return ""
	return ", ".join(names)


func _refresh_status_row(plate: Control, row: Dictionary) -> void:
	var row_root: Control = plate.get_node_or_null("StatusRow") as Control
	if row_root == null:
		return
	for child: Node in row_root.get_children():
		row_root.remove_child(child)
		child.queue_free()
	var plate_h: float = plate.size.y
	var files: Array[String] = _status_icon_files(row)
	for i: int in files.size():
		var icon := TextureRect.new()
		icon.name = "Status%d" % i
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = _load_ui_tex(files[i])
		icon.position = Vector2(2.0 + float(i) * STATUS_ICON_STEP, plate_h + 1.0)
		icon.size = STATUS_ICON_SIZE
		row_root.add_child(icon)
	row_root.tooltip_text = _status_icon_tooltip(row, files)


func _bars_hidden_by_status(row: Dictionary) -> bool:
	var status_id: String = str(row.get("status", "active"))
	var side: String = str(row.get("side", ""))
	if side == "party" and status_id == "ko":
		return true
	if side == "beast" and status_id == "calmed":
		return true
	return false


func _load_ui_tex(file_name: String) -> Texture2D:
	return load(UI_ART_DIR + file_name) as Texture2D


func _nearest_tex_rect(tex: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func _battle_ui_font() -> Font:
	if _ui_font_cache == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Sans-Serif"])
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NONE
		_ui_font_cache = font
	return _ui_font_cache


func _wood_label(label_name: String, text: String, rect: Rect2) -> Label:
	var label := Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(floorf(rect.position.x), floorf(rect.position.y))
	label.size = rect.size
	_apply_wood_label_style(label)
	return label


func _apply_wood_label_style(label: Label) -> void:
	label.add_theme_font_override("font", _battle_ui_font())
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", WOOD_TEXT)
	label.add_theme_color_override("font_outline_color", WOOD_SHADOW)
	label.add_theme_constant_override("outline_size", 2)


func _plate_label(label_name: String, text: String, pos: Vector2, width: float, align: HorizontalAlignment, ink: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_plate_label_style(label, ink)
	label.position = Vector2(floorf(pos.x), floorf(pos.y))
	label.size = Vector2(floorf(width), 10.0)
	label.z_index = 10
	return label


func _apply_plate_label_style(label: Label, ink: Color) -> void:
	label.add_theme_font_override("font", _battle_ui_font())
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", ink)
	label.add_theme_constant_override("line_spacing", 0)


func _plate_fill_bar(bar_name: String, y: float, bar_size: Vector2, fill_file: String, max_value: int, value: int) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.name = bar_name
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.position = Vector2(PLATE_BAR_POS.x, y)
	bar.custom_minimum_size = Vector2.ZERO
	bar.size = bar_size
	bar.texture_progress = _load_ui_tex(fill_file)
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	bar.max_value = maxi(1, max_value)
	bar.value = value
	return bar


static func _hp_fill_file(hp: int, max_hp: int) -> String:
	var frac: float = float(hp) / float(maxi(1, max_hp))
	return "bar_hp_low_50x4.png" if frac <= 0.3 else "bar_hp_ok_50x4.png"


func _build_plate(row: Dictionary, sole: Vector2, suffix: String) -> void:
	## Parchment plate under every fighter's feet: name, level, HP (+ Weave on party only).
	if _plates == null:
		return
	var fighter_id: String = str(row.get("id", ""))
	var side: String = str(row.get("side", ""))
	var plate_size: Vector2 = _plate_size_for(side)
	var plate := Control.new()
	plate.name = ("PartyPlate_%s" if side == "party" else "BeastPlate_%s") % fighter_id
	plate.mouse_filter = Control.MOUSE_FILTER_PASS
	var anchor: Vector2 = sole + PLATE_OFFSET
	plate.position = Vector2(floorf(anchor.x), floorf(anchor.y))
	plate.size = plate_size
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plate.set_meta("fighter_id", fighter_id)
	plate.set_meta("side", side)
	var is_boss: bool = side == "beast" and bool(row.get("boss", false))
	plate.set_meta("boss", is_boss)
	plate.add_to_group("battle_plate")
	plate.add_to_group("battle_ui")
	var bg := TextureRect.new()
	bg.name = "Bg"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = _load_ui_tex(_plate_bg_file(side, false, is_boss))
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.size = plate_size
	plate.add_child(bg)
	var display: String = ""
	if side == "party":
		display = _party_display_name(str(row.get("member", fighter_id)))
	else:
		display = _beast_display_name(str(row.get("species", ""))) + suffix
	var hp: int = int(row.get("hp", 0))
	var max_hp: int = int(row.get("max_hp", 1))
	plate.add_child(_plate_fill_bar("HpBar", PLATE_BAR_POS.y, PLATE_BAR_HP_SIZE, _hp_fill_file(hp, max_hp), max_hp, hp))
	var shield_overlay := TextureRect.new()
	shield_overlay.name = "ShieldOverlay"
	shield_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shield_overlay.position = PLATE_BAR_POS
	shield_overlay.size = Vector2.ZERO
	plate.add_child(shield_overlay)
	if side == "party":
		var weave_max: int = maxi(1, int(row.get("max_weave", maxi(1, int(row.get("weave", 0))))))
		plate.add_child(_plate_fill_bar("WeaveBar", PLATE_WEAVE_Y, PLATE_BAR_WEAVE_SIZE, "bar_weave_50x2.png", weave_max, int(row.get("weave", 0))))
	if side == "beast":
		var intent_root := Control.new()
		intent_root.name = "IntentMarker"
		intent_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(intent_root)
	var level_text: String = _level_text(row)
	var name_width: float = 50.0 if level_text == "" else 38.0
	plate.add_child(_plate_label("NameLabel", display, Vector2(4.0, 5.0), name_width, HORIZONTAL_ALIGNMENT_LEFT, PLATE_INK))
	plate.add_child(_plate_label("LevelLabel", level_text, Vector2(44.0, 5.0), 12.0, HORIZONTAL_ALIGNMENT_RIGHT, PLATE_LEVEL_INK))
	var status_row := Control.new()
	status_row.name = "StatusRow"
	status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(status_row)
	var shield := _plate_label("ShieldLabel", "", Vector2(plate_size.x + 1.0, 5.0), 22.0, HORIZONTAL_ALIGNMENT_LEFT, PLATE_INK)
	shield.add_theme_color_override("font_outline_color", PLATE_BAR_EDGE)
	shield.add_theme_constant_override("outline_size", 1)
	plate.add_child(shield)
	if is_boss:
		var crown := TextureRect.new()
		crown.name = "BossCrown"
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		crown.texture = _load_ui_tex("boss_crown_16.png")
		crown.position = BOSS_CROWN_POS
		crown.size = Vector2(16.0, 16.0)
		plate.add_child(crown)
	_plates.add_child(plate)
	_refresh_plate(row)


func _level_text(row: Dictionary) -> String:
	## Fighters carry no level yet; the slot stays empty until one does.
	if row.has("level"):
		return str(int(row.get("level", 0)))
	return ""


func intent_bubble_rect(fighter_id: String, wide: bool) -> Rect2:
	## (visible centre x - 10, visible top - 28), 22x26 (40x26 with a multiplier).
	var shown: Rect2 = fighter_visible_rect(fighter_id)
	var bubble_size: Vector2 = INTENT_BUBBLE_WIDE if wide else INTENT_BUBBLE_SIZE
	var x: float = floorf(shown.position.x + shown.size.x * 0.5) - INTENT_CENTRE_SHIFT
	return Rect2(Vector2(x, shown.position.y - INTENT_LIFT), bubble_size)


func _fill_intent_marker(intent_root: Control, row: Dictionary) -> void:
	for child: Node in intent_root.get_children():
		intent_root.remove_child(child)
		child.queue_free()
	var intent_v: Variant = row.get("intent", {})
	var intent: Dictionary = intent_v as Dictionary if intent_v is Dictionary else {}
	var move: String = str(intent.get("move", ""))
	var mult: int = int(intent.get("mult", 1))
	var wide: bool = mult != 1
	var fighter_id: String = str(row.get("id", ""))
	var rect: Rect2 = intent_bubble_rect(fighter_id, wide)
	var plate: Control = intent_root.get_parent() as Control
	intent_root.position = rect.position - (plate.position if plate != null else Vector2.ZERO)
	intent_root.size = rect.size
	intent_root.visible = str(row.get("status", "active")) == "active"
	intent_root.set_meta("move", move)
	var bubble := TextureRect.new()
	bubble.name = "Bubble"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.texture = _load_ui_tex("intent_bubble_wide_40x26.png" if wide else "intent_bubble_22x26.png")
	bubble.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bubble.size = rect.size
	intent_root.add_child(bubble)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _load_ui_tex("intent_%s_16.png" % _intent_kind(move))
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(3.0, 2.0)
	icon.size = Vector2(16.0, 16.0)
	intent_root.add_child(icon)
	if wide:
		var mult_file: String = _intent_mult_file(mult)
		if mult_file != "":
			var mult_tag := TextureRect.new()
			mult_tag.name = "MultTag"
			mult_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mult_tag.texture = _load_ui_tex(mult_file)
			mult_tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			mult_tag.position = Vector2(21.0, 7.0)
			if mult_tag.texture != null:
				mult_tag.size = mult_tag.texture.get_size()
			intent_root.add_child(mult_tag)
		else:
			var mult_label := Label.new()
			mult_label.name = "Mult"
			mult_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mult_label.text = "×%s" % _intent_mult_text(mult)
			mult_label.position = Vector2(21.0, 0.0)
			mult_label.size = Vector2(20.0, 20.0)
			mult_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mult_label.add_theme_font_size_override("font_size", 10)
			mult_label.add_theme_color_override("font_color", LOG_THREAT_INK)
			intent_root.add_child(mult_label)


func _refresh_plate(row: Dictionary) -> void:
	var plate: Control = _plate_for(str(row.get("id", "")))
	if plate == null:
		return
	var side: String = str(row.get("side", ""))
	var hp: int = int(row.get("hp", 0))
	var max_hp: int = int(row.get("max_hp", 1))
	var status_id: String = str(row.get("status", "active"))
	var hp_bar: TextureProgressBar = plate.get_node_or_null("HpBar") as TextureProgressBar
	if hp_bar != null:
		hp_bar.texture_progress = _load_ui_tex(_hp_fill_file(hp, max_hp))
		hp_bar.max_value = maxi(1, max_hp)
		hp_bar.value = hp
	var shield_overlay: TextureRect = plate.get_node_or_null("ShieldOverlay") as TextureRect
	if shield_overlay != null:
		var shield_amt: int = int(row.get("shield", 0))
		if shield_amt > 0 and max_hp > 0:
			var shield_w: float = clampf(float(shield_amt) / float(max_hp) * PLATE_BAR_HP_SIZE.x, 0.0, PLATE_BAR_HP_SIZE.x)
			shield_overlay.texture = _load_ui_tex("bar_shield_50x4.png")
			shield_overlay.size = Vector2(shield_w, PLATE_BAR_HP_SIZE.y)
			shield_overlay.visible = true
		else:
			shield_overlay.visible = false
			shield_overlay.size = Vector2.ZERO
	var weave_bar: TextureProgressBar = plate.get_node_or_null("WeaveBar") as TextureProgressBar
	var weave: int = int(row.get("weave", 0))
	if weave_bar != null:
		weave_bar.max_value = maxi(weave_bar.max_value, weave)
		weave_bar.value = weave
	var hide_bars: bool = _bars_hidden_by_status(row)
	if hp_bar != null:
		hp_bar.visible = not hide_bars
	if weave_bar != null:
		weave_bar.visible = not hide_bars
	var shield: Label = plate.get_node_or_null("ShieldLabel") as Label
	if shield != null:
		shield.text = _shield_text(int(row.get("shield", 0)))
	var fighter_id: String = str(row.get("id", ""))
	var is_boss: bool = side == "beast" and bool(row.get("boss", false))
	plate.set_meta("boss", is_boss)
	var bg: TextureRect = plate.get_node_or_null("Bg") as TextureRect
	if bg != null:
		var active: bool = fighter_id == _active_fighter_id
		if not active:
			bg.texture = _load_ui_tex(_plate_bg_file(side, false, is_boss))
	var crown: TextureRect = plate.get_node_or_null("BossCrown") as TextureRect
	if is_boss and crown == null:
		crown = TextureRect.new()
		crown.name = "BossCrown"
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		crown.texture = _load_ui_tex("boss_crown_16.png")
		crown.position = BOSS_CROWN_POS
		crown.size = Vector2(16.0, 16.0)
		plate.add_child(crown)
	if crown != null:
		crown.visible = is_boss
	_refresh_status_row(plate, row)
	var name_label: Label = plate.get_node_or_null("NameLabel") as Label
	var tip: String = "%s · %s" % [name_label.text if name_label != null else "", _hp_line(hp, max_hp)]
	if side == "party":
		tip += " · " + _weave_line(weave)
	plate.tooltip_text = tip
	var intent: Control = plate.get_node_or_null("IntentMarker") as Control
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
	return root.get_meta("sole", root.position) as Vector2


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
	if member == "bramble":
		return _text("bramble_name", "Bramble")
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


func _beast_hp_pct(hp: int, max_hp: int) -> String:
	return "%d%%" % int(roundf(100.0 * float(hp) / float(maxi(1, max_hp))))


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


func _intent_kind(move: String) -> String:
	var lowered: String = move.to_lower()
	if lowered.find("heavy") >= 0:
		return "heavy"
	if lowered.find("poison") >= 0:
		return "poison"
	return "strike"


func _intent_mult_text(mult: int) -> String:
	if mult == 3:
		return "1.5"
	return str(mult)


func _intent_mult_file(mult: int) -> String:
	## FightState stores ×1.5 as mult 3 in the legacy int path (see `_intent_mult_text`).
	if mult == 3:
		return "intent_mult_x1_5.png"
	if mult == 2:
		return "intent_mult_x2.png"
	if mult >= 4:
		return "intent_mult_x3.png"
	return ""


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


func _action_button(slot: int, button_name: String, label: String, icon_path: String) -> Button:
	## One of the six bottom-bar slots (160x44 wood button, scaffold placeholder art).
	var button := Button.new()
	button.name = button_name
	button.text = label
	button.position = Vector2(float(slot % 3) * ACTION_BUTTON_PITCH.x, floorf(float(slot) / 3.0) * ACTION_BUTTON_PITCH.y)
	button.size = ACTION_BUTTON_SIZE
	button.custom_minimum_size = ACTION_BUTTON_SIZE
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	if ResourceLoader.exists(icon_path):
		button.icon = load(icon_path) as Texture2D
	button.add_theme_constant_override("h_separation", 6)
	button.add_theme_font_size_override("font_size", 14)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = _load_ui_tex("action_button_%s_160x44.png" % state)
		box.set_texture_margin_all(4.0)
		box.content_margin_left = 8.0
		box.content_margin_right = 8.0
		button.add_theme_stylebox_override(state, box)
	var toggled := StyleBoxTexture.new()
	toggled.texture = _load_ui_tex("action_button_toggled_160x44.png")
	toggled.set_texture_margin_all(4.0)
	toggled.content_margin_left = 8.0
	toggled.content_margin_right = 8.0
	button.set_meta("style_toggled", toggled)
	var hover_pressed := StyleBoxTexture.new()
	hover_pressed.texture = _load_ui_tex("action_button_pressed_160x44.png")
	hover_pressed.set_texture_margin_all(4.0)
	hover_pressed.content_margin_left = 8.0
	button.add_theme_stylebox_override("hover_pressed", hover_pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, BUTTON_TEXT)
	button.add_theme_color_override("font_disabled_color", BUTTON_TEXT_DISABLED)
	button.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.05, 1.0))
	button.add_theme_constant_override("outline_size", 3)
	button.add_to_group("battle_ui")
	button.set_meta("style_normal", button.get_theme_stylebox("normal"))
	button.set_meta("style_hover", button.get_theme_stylebox("hover"))
	var keycap := TextureRect.new()
	keycap.name = "Keycap"
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keycap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var keycap_file: String = "keycap_%d_14x15.png" % (slot + 1)
	keycap.texture = _load_ui_tex(keycap_file)
	keycap.position = KEYCAP_POS
	if keycap.texture != null:
		keycap.size = keycap.texture.get_size()
	button.add_child(keycap)
	button.set_meta("keycap", keycap)
	_action_menu.add_child(button)
	_sync_action_button_style(button)
	return button


func _sync_action_button_style(button: Button) -> void:
	if button == null:
		return
	var toggled_sb: StyleBox = button.get_meta("style_toggled") as StyleBox
	var use_toggled: bool = button.toggle_mode and button.button_pressed and toggled_sb != null
	if use_toggled:
		button.add_theme_stylebox_override("normal", toggled_sb)
		button.add_theme_stylebox_override("hover", toggled_sb)
	else:
		var normal_sb: StyleBox = button.get_meta("style_normal") as StyleBox
		var hover_sb: StyleBox = button.get_meta("style_hover") as StyleBox
		if normal_sb != null:
			button.add_theme_stylebox_override("normal", normal_sb)
		if hover_sb != null:
			button.add_theme_stylebox_override("hover", hover_sb)
	button.add_theme_color_override("icon_disabled_color", ICON_DISABLED)
	button.add_theme_color_override("icon_normal_color", Color.WHITE)
	var keycap: TextureRect = button.get_meta("keycap") as TextureRect if button.has_meta("keycap") else null
	if keycap != null:
		var press_y: float = KEYCAP_PRESS_OFFSET
		if button.toggle_mode and button.button_pressed:
			press_y = KEYCAP_PRESS_OFFSET
		elif button.is_pressed():
			press_y = KEYCAP_PRESS_OFFSET
		keycap.position = KEYCAP_POS + Vector2(0.0, press_y)


func _action_hotkey_buttons() -> Array[Button]:
	return [_strike_button, _ability_button, _salve_button, _brace_button, _flee_button, _strike_for_me_toggle]


func _action_hotkeys_blocked() -> bool:
	if _target_mode != "":
		return true
	if _ability_row != null and _ability_row.visible:
		return true
	return false


func _can_use_action_hotkeys() -> bool:
	if _fight == null or _fight.outcome() != "":
		return false
	if _action_menu == null or not _action_menu.visible:
		return false
	if _action_hotkeys_blocked():
		return false
	var actor_id: String = _fight.current_actor()
	if actor_id == "":
		return false
	return str(_fight.fighter_dict(actor_id).get("side", "")) == "party"


func _try_action_hotkey(slot: int) -> bool:
	if slot < 0 or slot > 5:
		return false
	if not _can_use_action_hotkeys():
		return false
	var buttons: Array[Button] = _action_hotkey_buttons()
	var button: Button = buttons[slot] if slot < buttons.size() else null
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	if slot == 5:
		button.button_pressed = not button.button_pressed
		button.emit_signal("toggled", button.button_pressed)
		return true
	button.emit_signal("pressed")
	return true


func _on_ability_pressed() -> void:
	if _ability_row != null and _has_abilities():
		_ability_row.visible = not _ability_row.visible


func _build_top_bar() -> void:
	if _arena == null:
		return
	_depth_plate = Control.new()
	_depth_plate.name = "DepthPlate"
	_depth_plate.position = DEPTH_PLATE_POS
	_depth_plate.size = DEPTH_PLATE_SIZE
	_depth_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_depth_plate.add_to_group("battle_ui")
	var depth_bg := TextureRect.new()
	depth_bg.name = "Bg"
	depth_bg.texture = _load_ui_tex("depth_plate_120x28.png")
	depth_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	depth_bg.size = DEPTH_PLATE_SIZE
	depth_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_depth_plate.add_child(depth_bg)
	_depth_hud_label = _wood_label("DepthText", "Depth 1", Rect2(Vector2.ZERO, DEPTH_PLATE_SIZE))
	_depth_plate.add_child(_depth_hud_label)
	_arena.add_child(_depth_plate)
	_twist_chip = TextureRect.new()
	_twist_chip.name = "TwistChip"
	_twist_chip.position = TWIST_CHIP_POS
	_twist_chip.size = TWIST_CHIP_SIZE
	_twist_chip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_twist_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	_twist_chip.visible = false
	_twist_chip.add_to_group("battle_ui")
	_arena.add_child(_twist_chip)
	_round_banner = Control.new()
	_round_banner.name = "RoundBanner"
	_round_banner.position = ROUND_BANNER_POS
	_round_banner.size = ROUND_BANNER_SIZE
	_round_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_banner.add_to_group("battle_ui")
	var round_bg := TextureRect.new()
	round_bg.name = "Bg"
	round_bg.texture = _load_ui_tex("round_banner_324x38.png")
	round_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	round_bg.size = ROUND_BANNER_SIZE
	round_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_banner.add_child(round_bg)
	_round_hud_label = _wood_label("RoundText", "", Rect2(Vector2(12.0, 3.0), Vector2(300.0, 32.0)))
	_round_banner.add_child(_round_hud_label)
	_arena.add_child(_round_banner)


func _refresh_fight_hud() -> void:
	if _depth_hud_label != null:
		_depth_hud_label.text = "Depth %d" % _fight_depth
	if _round_hud_label != null:
		var round_n: int = _fight.round if _fight != null else 0
		if round_n > 0:
			_round_hud_label.text = _text("adv_log_round", "Round %d" % round_n, {"round": round_n})
		else:
			_round_hud_label.text = ""
	_refresh_twist_chip()


func _layout_top_chrome() -> void:
	if _test_fight_bar != null:
		_test_fight_bar.position = _test_fight_bar_pos()
	if _close_button != null:
		_close_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_close_button.offset_left = CLOSE_BUTTON_RECT.position.x
		_close_button.offset_top = CLOSE_BUTTON_RECT.position.y
		_close_button.offset_right = CLOSE_BUTTON_RECT.position.x + CLOSE_BUTTON_RECT.size.x
		_close_button.offset_bottom = CLOSE_BUTTON_RECT.position.y + CLOSE_BUTTON_RECT.size.y
		_close_button.z_index = 20
		if _arena != null:
			_arena.move_child(_close_button, _arena.get_child_count() - 1)


func _build_test_fight_bar() -> void:
	if _arena == null:
		return
	_test_fight_bar = HBoxContainer.new()
	_test_fight_bar.name = "TestFightBar"
	_test_fight_bar.position = _test_fight_bar_pos()
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


func _build_speed_bar() -> void:
	if _arena == null:
		return
	_speed_bar = Control.new()
	_speed_bar.name = "SpeedBar"
	_speed_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_speed_bar)
	for i: int in 3:
		var label_speed: int = [1, 2, 4][i]
		var prefix: String = "speed_%dx" % label_speed
		_speed_textures[label_speed] = {
			"normal": _load_ui_tex("%s_normal.png" % prefix),
			"hover": _load_ui_tex("%s_hover.png" % prefix),
			"pressed": _load_ui_tex("%s_pressed.png" % prefix),
			"selected": _load_ui_tex("%s_selected.png" % prefix),
		}
		var btn := Button.new()
		btn.name = "Speed%dx" % label_speed
		btn.toggle_mode = true
		btn.text = ""
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = SPEED_BUTTON_SIZE
		btn.size = SPEED_BUTTON_SIZE
		btn.position = Vector2(
			floorf(SPEED_BUTTON_POS.x + float(i) * SPEED_BUTTON_PITCH),
			floorf(SPEED_BUTTON_POS.y),
		)
		btn.add_to_group("battle_ui")
		btn.button_pressed = label_speed == 1
		btn.pressed.connect(_on_speed_pressed.bind(label_speed))
		_speed_buttons[label_speed] = btn
		_speed_bar.add_child(btn)
	_refresh_speed_buttons()


func _speed_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = tex
	return box


func _on_speed_pressed(chosen: int) -> void:
	if not strike_for_me_on():
		_apply_battle_speed(chosen)


func _apply_battle_speed(chosen: int) -> void:
	_battle_speed = chosen
	if _playback != null:
		_playback.speed = chosen
	for speed_key: int in _speed_buttons.keys():
		var btn: Button = _speed_buttons[speed_key] as Button
		if btn != null:
			btn.button_pressed = speed_key == chosen
	_refresh_speed_buttons()


func _refresh_speed_buttons() -> void:
	var locked: bool = strike_for_me_on()
	for speed_key: int in _speed_buttons.keys():
		var btn: Button = _speed_buttons[speed_key] as Button
		if btn == null:
			continue
		if locked:
			btn.disabled = speed_key != 1
			btn.button_pressed = speed_key == 1
			if speed_key == 1:
				_battle_speed = 1
				if _playback != null:
					_playback.speed = 1
		else:
			btn.disabled = false
		var tex_map: Dictionary = _speed_textures.get(speed_key, {}) as Dictionary
		if tex_map.is_empty():
			continue
		var selected: bool = speed_key == _battle_speed and not btn.disabled
		var normal_tex: Texture2D = tex_map["selected"] as Texture2D if selected else tex_map["normal"] as Texture2D
		btn.add_theme_stylebox_override("normal", _speed_stylebox(normal_tex))
		btn.add_theme_stylebox_override("hover", _speed_stylebox(tex_map["hover"] as Texture2D))
		btn.add_theme_stylebox_override("pressed", _speed_stylebox(tex_map["pressed"] as Texture2D))
		btn.add_theme_stylebox_override("disabled", _speed_stylebox(tex_map["normal"] as Texture2D))
		btn.add_theme_stylebox_override("hover_pressed", _speed_stylebox(tex_map["pressed"] as Texture2D))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


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
	_bottom_bar = TextureRect.new()
	_bottom_bar.name = "BottomBar"
	_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_bar.texture = _load_ui_tex("bottom_panel_1280x136.png")
	_bottom_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bottom_bar.position = BOTTOM_BAR_RECT.position
	_bottom_bar.size = BOTTOM_BAR_RECT.size
	_arena.add_child(_bottom_bar)
	_log_panel = Control.new()
	_log_panel.name = "LogPanel"
	_log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_panel.position = LOG_PANEL_RECT.position
	_log_panel.size = LOG_PANEL_RECT.size
	_log_panel.add_to_group("battle_ui")
	_arena.add_child(_log_panel)
	var parchment := TextureRect.new()
	parchment.name = "Parchment"
	parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parchment.texture = _load_ui_tex("log_panel_732x108.png")
	parchment.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parchment.position = Vector2(-2.0, -2.0)
	parchment.size = LOG_PANEL_RECT.size + Vector2(4.0, 4.0)
	_log_panel.add_child(parchment)
	for i: int in LOG_LINE_COUNT:
		var line := Label.new()
		line.name = "LogLine%d" % i
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.clip_text = true
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.position = Vector2(10.0, 3.0 + 19.0 * float(i))
		line.size = Vector2(LOG_PANEL_RECT.size.x - 20.0, 19.0)
		line.add_theme_font_size_override("font_size", 12)
		line.add_theme_color_override("font_color", LOG_INK)
		_log_panel.add_child(line)
		_log_labels.append(line)
	_action_menu = Control.new()
	_action_menu.name = "ActionMenu"
	_action_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_menu.position = ACTION_MENU_POS
	_action_menu.size = Vector2(ACTION_BUTTON_PITCH.x * 2.0 + ACTION_BUTTON_SIZE.x, ACTION_BUTTON_PITCH.y + ACTION_BUTTON_SIZE.y)
	_action_menu.visible = false
	_arena.add_child(_action_menu)
	_action_buttons.clear()
	# Exactly six fixed slots, 3 x 2: Strike, Ability, Items / Brace, Flee, Strike for me.
	_strike_button = _action_button(0, "StrikeButton", _text("adv_menu_strike", "Strike"), "res://assets/art/ui/icon_stone_sword.png")
	_strike_button.pressed.connect(_on_strike_pressed)
	_ability_button = _action_button(1, "AbilityButton", _text("adv_menu_ability", "Ability"), UI_ART_DIR + "icon_ability_32.png")
	_ability_button.disabled = true
	_ability_button.tooltip_text = _text("adv_ability_empty_tip", "Abilities draw on Weave. You have none yet.")
	_ability_button.pressed.connect(_on_ability_pressed)
	_salve_button = _action_button(2, "SalveButton", "", "res://assets/art/ui/icon_heart_salve.png")
	_salve_button.pressed.connect(_on_salve_pressed)
	_brace_button = _action_button(3, "BraceButton", _text("adv_menu_brace", "Brace"), UI_ART_DIR + "icon_brace_32.png")
	_brace_button.pressed.connect(_on_brace_pressed)
	_flee_button = _action_button(4, "FleeButton", _text("adv_menu_flee", "Flee"), UI_ART_DIR + "icon_flee_32.png")
	_flee_button.pressed.connect(_on_flee_pressed)
	_strike_for_me_toggle = _action_button(5, "StrikeForMeToggle", _text("adv_strike_for_me", "Strike for me"), "res://assets/art/ui/icons/hud_character.png")
	_strike_for_me_toggle.toggle_mode = true
	_strike_for_me_toggle.tooltip_text = _text(
		"adv_strike_for_me_tip",
		"Your fighters only Strike: front row first, then slot order. Plays at 1×. Turn it off any time.",
	)
	if not _strike_for_me_toggle.toggled.is_connected(_on_strike_for_me_toggled):
		_strike_for_me_toggle.toggled.connect(_on_strike_for_me_toggled)
	for hotkey_btn: Button in _action_hotkey_buttons():
		if hotkey_btn != null:
			_action_buttons.append(hotkey_btn)
	# Not part of the bottom bar: the ability picker pops up over the arena above the
	# Ability button, and Idle / Back sit top-left under the test fight bar.
	var ability_row := HBoxContainer.new()
	ability_row.name = "AbilityRow"
	ability_row.add_theme_constant_override("separation", 4)
	ability_row.position = ACTION_MENU_POS + Vector2(ACTION_BUTTON_PITCH.x, -40.0)
	ability_row.visible = false
	_arena.add_child(ability_row)
	_ability_row = ability_row
	for n: int in 4:
		var ab := _ui_button("—", ability_row)
		ab.name = "AbilityButton%d" % (n + 1)
		ab.disabled = true
		ab.tooltip_text = _text("adv_ability_empty_tip", "Abilities draw on Weave. You have none yet.")
		_ability_buttons.append(ab)
	_side_actions = VBoxContainer.new()
	_side_actions.name = "SideActions"
	_side_actions.position = Vector2(16.0, 52.0)
	_side_actions.add_theme_constant_override("separation", 4)
	_side_actions.visible = false
	_arena.add_child(_side_actions)
	_idle_button = _ui_button(_text("adv_menu_idle", "Idle"), _side_actions)
	_idle_button.name = "IdleButton"
	_idle_button.disabled = true
	_idle_button.tooltip_text = _text("adv_menu_idle_later", "Hands the fight to idle Auto. Not in the test fight yet.")
	if not _idle_button.pressed.is_connected(_on_idle_pressed):
		_idle_button.pressed.connect(_on_idle_pressed)
	_cancel_target_button = _ui_button(_text("adv_menu_cancel", "Back"), _side_actions)
	_cancel_target_button.name = "CancelTargetButton"
	_cancel_target_button.visible = false
	_cancel_target_button.pressed.connect(_on_cancel_target_pressed)
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
	_fight_depth = depth
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
	fight.controller = "manual"
	_fight = fight
	_log_reveal_count = 0
	if _playback != null:
		_playback.bind_view(self, fight)
		_playback.reset_for_fight()
	show_fight(fight)
	_advance()


func strike_for_me_on() -> bool:
	return _strike_for_me_toggle != null and _strike_for_me_toggle.button_pressed


func _advance() -> void:
	if _fight == null:
		return
	if _playback != null and _playback.is_busy():
		_advance_after_playback = true
		return
	_advance_after_playback = false
	_advance_core()


func _advance_core() -> void:
	while _fight != null and _fight.outcome() == "":
		var actor_id: String = _fight.current_actor()
		if actor_id == "":
			break
		if str(_fight.fighter_dict(actor_id).get("side", "")) != "beast":
			if strike_for_me_on():
				_enqueue_step(_strike_for_me_party_step_packet(actor_id))
				if _playback != null and _playback.is_busy():
					_advance_after_playback = true
					_show_strike_for_me_toggle_only()
					return
				continue
			break
		var beast_packet: Dictionary = _fight.step()
		_note_reach_fight_action()
		_enqueue_step(beast_packet)
		if _playback != null and _playback.is_busy():
			# Resume when this beast's playback ends, or the fight stalls.
			_advance_after_playback = true
			if strike_for_me_on():
				_show_strike_for_me_toggle_only()
			return
		if strike_for_me_on():
			_show_strike_for_me_toggle_only()
	_finish_turn_ui()


func _enqueue_step(packet: Dictionary) -> void:
	if packet.is_empty():
		return
	var events: Array = packet.get("events", []) as Array
	if events.size() > 0 and _playback != null and not _playback.instant:
		_hide_action_menu()
	if _playback != null:
		_playback.enqueue_events(events)
		if _playback.instant and _fight != null:
			_log_reveal_count = _fight.log_tail.size()
	elif events.size() > 0:
		for entry: Variant in events:
			if entry is Dictionary:
				playback_reveal_log(entry as Dictionary)


func _finish_turn_ui() -> void:
	if _fight == null:
		return
	_exit_target_mode()
	refresh_fight(_fight)
	if _reach_mode:
		_refresh_pack_counter()
	_refresh_fight_hud()
	_update_log_panel()
	if _fight.outcome() != "":
		_show_fight_result()
		_hide_action_menu()
		if _start_fight_button != null:
			_start_fight_button.disabled = false
		return
	set_active(_fight.current_actor())
	_show_action_menu(_fight.current_actor())


func _on_playback_queue_empty() -> void:
	if _fight == null:
		return
	refresh_fight(_fight)
	_update_log_panel()
	if _advance_after_playback:
		_advance_after_playback = false
		call_deferred("_advance_core")


func _show_fight_result() -> void:
	if _fight == null:
		return
	if _reach_mode:
		if not _reach_outcome_applied:
			_reach_outcome_applied = true
			var reach: Node = get_node_or_null("/root/Reach")
			if reach != null:
				reach.call("on_manual_outcome", _fight.outcome())
			_show_end_panel(_fight.outcome())
		_hide_action_menu()
		return
	if _result_label == null:
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
	var visible: int = tail.size()
	if _playback != null and not _playback.instant:
		visible = mini(_log_reveal_count, tail.size())
	var start: int = maxi(0, visible - _log_labels.size())
	var slice: Array = tail.slice(start, visible)
	for i: int in _log_labels.size():
		if i < slice.size():
			var line_text: String = str(slice[i])
			_log_labels[i].text = line_text
			_log_labels[i].add_theme_color_override("font_color", _log_line_color(line_text))
		else:
			_log_labels[i].text = ""


func _log_line_color(line_text: String) -> Color:
	var lowered: String = line_text.to_lower()
	if lowered.find("miss") >= 0:
		return LOG_MISS_INK
	if lowered.find("heavy") >= 0 or lowered.find("wind") >= 0:
		return LOG_THREAT_INK
	if lowered.begins_with("round"):
		return LOG_SYSTEM_INK
	return LOG_INK


func _hide_action_menu() -> void:
	if _action_menu != null:
		_action_menu.visible = false
	if _side_actions != null:
		_side_actions.visible = false
	if _ability_row != null:
		_ability_row.visible = false


func _show_strike_for_me_toggle_only() -> void:
	if _action_menu == null or _strike_for_me_toggle == null:
		return
	_action_menu.visible = true
	for child: Node in _action_menu.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = child == _strike_for_me_toggle
	if _side_actions != null:
		_side_actions.visible = false
	if _ability_row != null:
		_ability_row.visible = false


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
	var choosing: bool = _target_mode == ""
	for button: Button in [_strike_button, _ability_button, _salve_button, _brace_button, _flee_button]:
		if button != null:
			button.visible = choosing
	var show_abilities: bool = choosing and _has_abilities()
	if _ability_button != null:
		_ability_button.disabled = not show_abilities
	if _ability_row != null and not show_abilities:
		_ability_row.visible = false
	if _side_actions != null:
		_side_actions.visible = true
	if _idle_button != null:
		_idle_button.visible = choosing
	_cancel_target_button.visible = not choosing
	_refresh_idle_button()
	if _strike_for_me_toggle != null:
		_strike_for_me_toggle.visible = true
		_sync_action_button_style(_strike_for_me_toggle)
	for menu_btn: Button in [_strike_button, _ability_button, _salve_button, _brace_button, _flee_button]:
		if menu_btn != null:
			_sync_action_button_style(menu_btn)
	if _playback != null:
		_playback.notify_party_turn()


func _has_abilities() -> bool:
	## No abilities exist yet: every slot is a disabled "—". The picker stays shut until one is real.
	for ab: Button in _ability_buttons:
		if not ab.disabled:
			return true
	return false


func _strike_for_me_party_step(actor_id: String) -> void:
	var packet: Dictionary = _strike_for_me_party_step_packet(actor_id)
	if not packet.is_empty():
		_notify_strike_for_me_party(packet)


func _strike_for_me_party_step_packet(actor_id: String) -> Dictionary:
	if _fight == null or actor_id == "":
		return {}
	var action: Dictionary = AutoPolicy.strike_for_me_action(_fight, actor_id)
	var packet: Dictionary = _fight.step(action)
	_note_reach_fight_action()
	packet["strike_for_me_target"] = str(action.get("target", ""))
	return packet


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
	_sync_action_button_style(_strike_for_me_toggle)
	_refresh_speed_buttons()
	if not pressed or _fight == null or _fight.outcome() != "":
		return
	var actor_id: String = _fight.current_actor()
	if actor_id == "" or str(_fight.fighter_dict(actor_id).get("side", "")) != "party":
		return
	var packet: Dictionary = _strike_for_me_party_step_packet(actor_id)
	_notify_strike_for_me_party(packet)
	_enqueue_step(packet)
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


func _refresh_idle_button() -> void:
	## Reach mode can hand the live fight to idle Auto. The test fight cannot.
	if _idle_button == null:
		return
	if _reach_mode and _target_mode == "":
		_idle_button.disabled = false
		_idle_button.tooltip_text = _text(
			"adv_menu_idle_tip",
			"Hand this fight to idle Auto. It finishes in 12 minutes. Join again before then to pick it back up.",
		)
	else:
		_idle_button.disabled = true
		_idle_button.tooltip_text = _text(
			"adv_menu_idle_later",
			"Hands the fight to idle Auto. Not in the test fight yet.",
		)


func _on_idle_pressed() -> void:
	if not _reach_mode or _idle_button == null or _idle_button.disabled:
		return
	var reach: Node = get_node_or_null("/root/Reach")
	if reach != null and reach.has_method("hand_to_idle"):
		reach.call("hand_to_idle")


func _on_strike_pressed() -> void:
	if _playback != null:
		_playback.play_battle_select()
	_enter_target_mode("strike")


func _on_salve_pressed() -> void:
	if _playback != null:
		_playback.play_battle_select()
	_enter_target_mode("salve")


func _on_brace_pressed() -> void:
	if _fight == null:
		return
	if _playback != null:
		_playback.play_battle_select()
	var brace_packet: Dictionary = _fight.step({"kind": "brace"})
	_note_reach_fight_action()
	_enqueue_step(brace_packet)
	_advance()


func _on_flee_pressed() -> void:
	if _fight == null:
		return
	if _playback != null:
		_playback.play_battle_select()
	var flee_packet: Dictionary = _fight.step({"kind": "flee"})
	_note_reach_fight_action()
	_enqueue_step(flee_packet)
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
			mark.position = Vector2(sole.x - 28.0, sole.y - 8.0)
			_target_layer.add_child(mark)
		var shown: Rect2 = fighter_visible_rect(fighter_id)
		if shown.size.x > 0.0:
			var corner_tex: Texture2D = _load_ui_tex("target_corner_6x6.png")
			if corner_tex != null:
				_add_target_corner(Vector2(shown.position.x - 4.0, shown.position.y - 4.0), corner_tex, false, false)
				_add_target_corner(Vector2(shown.end.x - 2.0, shown.position.y - 4.0), corner_tex, true, false)
				_add_target_corner(Vector2(shown.position.x - 4.0, shown.end.y - 2.0), corner_tex, false, true)
				_add_target_corner(Vector2(shown.end.x - 2.0, shown.end.y - 2.0), corner_tex, true, true)
		var button := Button.new()
		button.name = "TargetButton_%s" % fighter_id
		button.modulate = Color(1.0, 1.0, 1.0, 0.01)
		button.size = TARGET_BUTTON_SIZE
		button.position = sole - Vector2(TARGET_BUTTON_SIZE.x * 0.5, TARGET_BUTTON_SIZE.y - 16.0)
		button.add_to_group("battle_ui")
		button.pressed.connect(_on_target_pressed.bind(fighter_id))
		_target_layer.add_child(button)


func _add_target_corner(pos: Vector2, tex: Texture2D, flip_h: bool, flip_v: bool) -> void:
	var corner := TextureRect.new()
	corner.texture = tex
	corner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.size = tex.get_size()
	corner.position = pos
	corner.flip_h = flip_h
	corner.flip_v = flip_v
	_target_layer.add_child(corner)


func _on_target_pressed(target_id: String) -> void:
	if _fight == null or _target_mode == "":
		return
	var mode: String = _target_mode
	_exit_target_mode()
	if _playback != null:
		_playback.play_battle_confirm()
	var packet: Dictionary = {}
	var stepped: bool = false
	if mode == "strike":
		packet = _fight.step({"kind": "strike", "target": target_id})
		stepped = true
	elif mode == "salve":
		packet = _fight.step({"kind": "item", "item": "heart_salve", "target": target_id})
		stepped = true
	if stepped:
		_note_reach_fight_action()
	_enqueue_step(packet)
	_advance()


func _note_reach_fight_action() -> void:
	if not _reach_mode or _fight == null:
		return
	var reach: Node = get_node_or_null("/root/Reach")
	if reach != null and reach.has_method("note_fight_action"):
		reach.call("note_fight_action")


func _ensure_pack_counter() -> void:
	if _arena == null:
		return
	if _pack_counter != null and is_instance_valid(_pack_counter):
		_pack_counter.visible = true
		return
	_pack_counter = Label.new()
	_pack_counter.name = "PackCounter"
	_pack_counter.add_to_group("battle_ui")
	_pack_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pack_counter.position = Vector2(ARENA_SIZE.x - 280.0, 12.0)
	_pack_counter.size = Vector2(264.0, 24.0)
	_arena.add_child(_pack_counter)


func _refresh_pack_counter() -> void:
	if _pack_counter == null or not is_instance_valid(_pack_counter):
		return
	_pack_counter.text = pack_counter_text()
	var reach: Node = get_node_or_null("/root/Reach")
	var tip: String = ""
	if reach != null:
		var run_pack: Pack = reach.get("pack") as Pack
		if run_pack != null:
			if run_pack.is_empty():
				tip = _text("adv_pack_empty", "The pack is empty.")
			else:
				var lines: PackedStringArray = []
				for key_v: Variant in run_pack.items.keys():
					var item_id: String = str(key_v)
					var count: int = int(run_pack.items[item_id])
					var item_name: String = _text("item_%s" % item_id, item_id.replace("_", " ").capitalize())
					lines.append("%s ×%d" % [item_name, count])
				tip = "\n".join(lines)
	_pack_counter.tooltip_text = tip


func _hide_end_panel() -> void:
	if _end_panel != null and is_instance_valid(_end_panel):
		_end_panel.queue_free()
	_end_panel = null


func _show_end_panel(outcome: String) -> void:
	_hide_end_panel()
	if _arena == null:
		return
	var reach: Node = get_node_or_null("/root/Reach")
	if reach == null:
		return
	_refresh_pack_counter()
	var panel := Panel.new()
	panel.name = "EndPanel"
	panel.add_to_group("battle_ui")
	var panel_w: float = 520.0
	var panel_h: float = 280.0
	panel.position = Vector2((ARENA_SIZE.x - panel_w) * 0.5, BOTTOM_BAR_RECT.position.y - 8.0 - panel_h)
	panel.size = Vector2(panel_w, panel_h)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)
	var title := Label.new()
	title.name = "EndTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var detail := Label.new()
	detail.name = "EndDetail"
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(detail)
	var exp_line := Label.new()
	exp_line.name = "EndExp"
	body.add_child(exp_line)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(buttons)
	_end_panel = panel
	_arena.add_child(panel)
	match outcome:
		"win":
			title.text = _text("adv_end_victory_title", "Room cleared")
			detail.text = _pack_list_text(reach)
			var room_exp: int = int(reach.get("last_room_exp"))
			exp_line.text = _text("adv_end_exp", "+%d exp" % room_exp, {"n": room_exp})
			var slots_used: int = int(reach.get("slots_used"))
			var slots_total: int = int(reach.get("slots_total"))
			if slots_used >= slots_total:
				var home := _ui_button(_text("adv_end_last_room", "Last room. Head home"), buttons)
				home.name = "EndHome"
				home.pressed.connect(_on_end_home_pressed)
			else:
				var cont := _ui_button(_text("adv_end_continue", "Continue"), buttons)
				cont.name = "EndContinue"
				cont.pressed.connect(_on_end_continue_pressed)
				var deeper := _ui_button(_text("adv_end_deeper", "Go deeper"), buttons)
				deeper.name = "EndDeeper"
				deeper.pressed.connect(_on_end_deeper_pressed)
				var home := _ui_button(_text("adv_end_home", "Head home"), buttons)
				home.name = "EndHome"
				home.pressed.connect(_on_end_home_pressed)
		"flee":
			title.text = _text("adv_end_flee_title", "Fled")
			var summary: Dictionary = reach.get("last_summary") as Dictionary
			var banked: Dictionary = summary.get("banked", {}) as Dictionary
			detail.text = _text("adv_end_flee_body", "You fled to the trailhead. Half the pack came home.")
			if not banked.is_empty():
				detail.text += "\n" + _format_banked(banked)
			exp_line.text = ""
			var back := _ui_button(_text("adv_end_back", "Back to the clearing"), buttons)
			back.name = "EndBack"
			back.pressed.connect(_on_end_back_pressed)
		"overwhelmed":
			title.text = _text("adv_overwhelmed_title", "Overwhelmed")
			detail.text = _text("adv_overwhelmed_body", "The party was overwhelmed. The pack returns to the forest. Exp is kept.")
			exp_line.text = ""
			var back_o := _ui_button(_text("adv_end_back", "Back to the clearing"), buttons)
			back_o.name = "EndBack"
			back_o.pressed.connect(_on_end_back_pressed)
		_:
			detail.text = outcome


func _pack_list_text(reach: Node) -> String:
	var run_pack: Pack = reach.get("pack") as Pack
	if run_pack == null or run_pack.is_empty():
		return _text("adv_pack_empty", "The pack is empty.")
	return _format_banked(run_pack.items)


func _format_banked(items: Dictionary) -> String:
	var lines: PackedStringArray = []
	for key_v: Variant in items.keys():
		var item_id: String = str(key_v)
		var count: int = int(items[item_id])
		if count <= 0:
			continue
		var item_name: String = _text("item_%s" % item_id, item_id.replace("_", " ").capitalize())
		lines.append("%s ×%d" % [item_name, count])
	return "\n".join(lines) if lines.size() > 0 else _text("adv_pack_empty", "The pack is empty.")


func _on_end_continue_pressed() -> void:
	var reach: Node = get_node_or_null("/root/Reach")
	if reach != null:
		reach.call("manual_choice", "continue")


func _on_end_deeper_pressed() -> void:
	var reach: Node = get_node_or_null("/root/Reach")
	if reach != null:
		reach.call("manual_choice", "deeper")


func _on_end_home_pressed() -> void:
	var reach: Node = get_node_or_null("/root/Reach")
	if reach != null:
		reach.call("manual_choice", "home")
	close_overlay()


func _on_end_back_pressed() -> void:
	close_overlay()


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
	if not key.pressed or key.echo:
		return
	if key.keycode >= KEY_1 and key.keycode <= KEY_6:
		if _try_action_hotkey(int(key.keycode - KEY_1)):
			get_viewport().set_input_as_handled()
		return
	if key.keycode != KEY_ESCAPE:
		return
	if _reach_mode:
		get_viewport().set_input_as_handled()
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
