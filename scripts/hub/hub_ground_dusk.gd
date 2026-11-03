class_name HubGroundDusk
## Dusk/night ground texture twins (Art batch day_night_dusk_2026-10-27).

const TILESET_DAY: String = "res://assets/art/tiles/tileset_grass_64.png"
const TILESET_DUSK: String = "res://assets/art/tiles/tileset_grass_64_dusk.png"

const PHASE_SEGMENTS: int = 4


static func phase_index(phase01: float) -> int:
	var seg: float = fmod(phase01, 1.0) * float(PHASE_SEGMENTS)
	if seg < 0.0:
		seg += float(PHASE_SEGMENTS)
	return int(floor(seg)) % PHASE_SEGMENTS


## Dusk and night segments use `_dusk` twins; day and dawn use the normal atlas.
static func wants_dusk_textures(phase01: float) -> bool:
	var idx: int = phase_index(phase01)
	return idx == 1 or idx == 2


static func paired_dusk_path(day_path: String) -> String:
	if day_path.is_empty() or day_path.ends_with("_dusk.png"):
		return day_path
	if not day_path.ends_with(".png"):
		return day_path
	var dusk_path: String = day_path.get_base_dir().path_join(
		"%s_dusk.png" % day_path.get_file().get_basename()
	)
	if ResourceLoader.exists(dusk_path):
		return dusk_path
	return day_path


static func paired_day_path(tex_path: String) -> String:
	if not tex_path.ends_with("_dusk.png"):
		return tex_path
	var day_path: String = tex_path.replace("_dusk.png", ".png")
	if ResourceLoader.exists(day_path):
		return day_path
	return tex_path
