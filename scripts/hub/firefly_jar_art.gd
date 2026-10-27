class_name FireflyJarArt
extends RefCounted

const PATH_EMPTY: String = "res://assets/art/hub/bench_props/firefly_jar_empty_10x14.png"
const PATH_1: String = "res://assets/art/hub/bench_props/firefly_jar_1_10x14.png"
const PATH_10: String = "res://assets/art/hub/bench_props/firefly_jar_10_10x14.png"
const PATH_50: String = "res://assets/art/hub/bench_props/firefly_jar_50_10x14.png"


static func texture_for_count(count: int) -> Texture2D:
	var path: String = PATH_EMPTY
	if count >= 50:
		path = PATH_50
	elif count >= 10:
		path = PATH_10
	elif count >= 1:
		path = PATH_1
	return load(path) as Texture2D
