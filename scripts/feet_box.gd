class_name FeetBox
extends RefCounted
## Walk collision shared by the Keeper, companions, and props.
## The box is the sprite's width by about a third of its height, sitting on the
## feet and extending upward. Click shapes stay separate and can be larger.


const HEIGHT_RATIO: float = 1.0 / 3.0
## Opaque Keeper figure inside the 128×128 canvas. The empty margins are not solid.
const KEEPER_SPRITE: Vector2 = Vector2(48, 123)
## Opaque Elaia figure inside her 128×128 canvas.
const ELAIA_SPRITE: Vector2 = Vector2(44, 117)


static func size_for(sprite_size: Vector2) -> Vector2:
	var width: float = maxf(8.0, absf(sprite_size.x))
	var height: float = maxf(8.0, absf(sprite_size.y) * HEIGHT_RATIO)
	return Vector2(width, height)


static func apply(shape_node: CollisionShape2D, sprite_size: Vector2, feet_local: Vector2 = Vector2.ZERO) -> Vector2:
	return apply_size(shape_node, size_for(sprite_size), feet_local)


static func apply_size(shape_node: CollisionShape2D, box: Vector2, feet_local: Vector2 = Vector2.ZERO) -> Vector2:
	var rect := RectangleShape2D.new()
	rect.size = box
	shape_node.shape = rect
	## Center sits half a box above the feet, so the bottom edge is the ground contact.
	shape_node.position = feet_local + Vector2(0.0, -box.y * 0.5)
	return box


static func actor_sprite(actor_id: String) -> Vector2:
	if actor_id == "elaia":
		return ELAIA_SPRITE
	return KEEPER_SPRITE


static func actor_box(actor_id: String = "keeper") -> Vector2:
	return size_for(actor_sprite(actor_id))
