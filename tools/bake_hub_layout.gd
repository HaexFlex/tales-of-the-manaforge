extends SceneTree
## Retired. The hub layout lives in scenes/main.tscn.
## Running this used to rebuild the forest and overwrite editor edits.
##   Do not set MANAFORGE_BAKE. Do not run this script.


func _initialize() -> void:
	push_error("bake: refused. The hub layout lives in scenes/main.tscn. tools/bake_hub_layout.gd would wipe editor edits. Do not set MANAFORGE_BAKE.")
	print("BAKE_REFUSED")
	quit(1)
