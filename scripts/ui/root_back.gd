extends Window
## Android back is delivered as NOTIFICATION_WM_GO_BACK_REQUEST on the root
## window. Godot does not emit go_back_requested for that call, and child nodes
## never see the notification. Forward it to GameInput.


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	var input: Node = get_node_or_null("GameInput")
	if input != null and input.has_method("on_android_back"):
		input.call("on_android_back")
