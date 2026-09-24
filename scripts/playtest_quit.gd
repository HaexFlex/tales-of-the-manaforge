extends SceneTree
## Confirms the title Quit button actually leaves the process.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_service: Node = root.get_node("SaveService")
	save_service.call("delete_save")
	change_scene_to_file("res://scenes/title_screen.tscn")
	for _i: int in range(30):
		await process_frame
	var title: Node = current_scene
	var quit_btn: Button = title.get_node("Menu/BtnQuit") as Button
	quit_btn.pressed.emit()
	await process_frame
	var yes: Button = title.get_node("ConfirmPanel/ConfirmYes") as Button
	if not (title.get_node("ConfirmPanel") as CanvasItem).visible:
		push_error("QUIT_CONFIRM_MISSING")
		quit(2)
		return
	yes.pressed.emit()
	# get_tree().quit() is deferred. If we are still here after several frames, it failed.
	for _j: int in range(10):
		await process_frame
	push_error("QUIT_DID_NOT_EXIT")
	quit(3)
