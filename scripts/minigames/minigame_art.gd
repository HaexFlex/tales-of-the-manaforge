class_name MinigameArt
extends RefCounted

const ROOT: String = "res://assets/ui/minigames/"


static func texture(file_name: String) -> Texture2D:
	var path: String = ROOT + file_name
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func add_sprite(parent: Node, file_name: String, pos: Vector2, frames: int = 1) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.name = file_name.get_basename()
	spr.texture = texture(file_name)
	spr.centered = true
	spr.position = pos
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if frames > 1:
		spr.hframes = frames
		spr.frame = 0
	parent.add_child(spr)
	return spr


static func herb_region(index: int) -> AtlasTexture:
	var sheet: Texture2D = texture("herbs_5.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var i: int = clampi(index, 0, 4)
	atlas.region = Rect2(i * 36, 0, 36, 36)
	return atlas
