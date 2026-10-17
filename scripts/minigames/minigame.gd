class_name Minigame
extends Control
## One lend-a-hand game. The host owns the clock readout and the payout.

var playing: bool = false
## Play-local point of the latest success. The host pops +k there.
var feedback_at: Vector2 = Vector2(320, 120)


func game_id() -> String:
	return ""


func begin() -> void:
	playing = true


func bind_target(_target_id: String) -> void:
	pass


func shutdown() -> void:
	playing = false


func succeed(k_seconds: float, weight: float = 1.0, at: Vector2 = Vector2(-99999, -99999)) -> void:
	if not playing or k_seconds <= 0.0:
		return
	if at.x > -10000.0:
		feedback_at = at
	var host: Node = get_node_or_null("/root/MinigameHost")
	if host != null and host.has_method("note_success"):
		host.call("note_success", k_seconds, weight)


func miss() -> void:
	if not playing:
		return
	var host: Node = get_node_or_null("/root/MinigameHost")
	if host != null and host.has_method("note_miss"):
		host.call("note_miss")


func on_key(_event: InputEvent) -> void:
	pass


func on_pointer_up() -> void:
	pass
