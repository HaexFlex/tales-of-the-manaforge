extends Companion
class_name Elaia
## Elaia's hub body. The walk, the work, and the join all live on Companion.
## This file only pins the roster id so older scenes that instance it keep working.


func _ready() -> void:
	if companion_id == "":
		companion_id = "elaia"
	super._ready()
