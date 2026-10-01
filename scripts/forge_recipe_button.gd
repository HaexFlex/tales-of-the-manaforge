extends Button
## Recipe row. Hover builds a rich tooltip: owned / needed, shorts in rust.

var recipe_id: String = ""


func _make_custom_tooltip(_for_text: String) -> Object:
	var panel := PanelContainer.new()
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2(240, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("/root/ForgeJobs"):
		label.text = ForgeJobs.recipe_hover_bbcode(recipe_id)
	else:
		label.text = recipe_id
	panel.add_child(label)
	return panel
